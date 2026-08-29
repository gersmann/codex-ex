defmodule CodexEx.AppServer.WebSocketTransport do
  @moduledoc false

  @behaviour CodexEx.AppServer.Transport

  use GenServer

  alias CodexEx.AppServer.WebSocketFrames

  @default_handshake_timeout 5_000
  @default_retry_attempts 2
  @default_retry_delay_ms 250
  @overload_statuses MapSet.new([429, 503])

  @type open_error ::
          :missing_url
          | {:invalid_url, term()}
          | {:unsupported_scheme, binary()}
          | {:connect_failed, term()}
          | {:upgrade_failed, term()}
          | {:handshake_failed, term()}

  @type close_reason ::
          {:remote_close, non_neg_integer() | nil, binary() | nil}
          | {:upgrade_failed, non_neg_integer(), [{binary(), binary()}]}
          | {:transport_error, term()}
          | {:decode_failed, term()}
          | {:send_failed, term()}
  @type state :: %{
          conn: Mint.HTTP.t(),
          owner: pid(),
          owner_ref: reference(),
          request_ref: reference(),
          websocket: Mint.WebSocket.t()
        }
  @dialyzer {:nowarn_function, [open: 1]}

  @impl true
  @spec open(keyword()) :: GenServer.on_start()
  def open(opts) do
    GenServer.start(__MODULE__, opts)
  end

  @impl true
  @spec send(pid(), binary()) :: :ok | {:error, :closed}
  def send(transport, payload) when is_pid(transport) and is_binary(payload) do
    case GenServer.call(transport, {:send, payload}) do
      :ok -> :ok
      {:error, :closed} = error -> error
    end
  catch
    :exit, _reason -> {:error, :closed}
  end

  @impl true
  @spec close(pid()) :: :ok
  def close(transport) when is_pid(transport) do
    :ok = GenServer.call(transport, :close)
    :ok
  catch
    :exit, _reason -> :ok
  end

  @impl true
  @spec normalize_message(term(), term()) ::
          CodexEx.AppServer.Transport.normalized_message()
  def normalize_message({transport, {:transport_data, data}}, transport) when is_pid(transport) and is_binary(data) do
    {:data, data}
  end

  def normalize_message({transport, {:transport_closed, reason}}, transport) when is_pid(transport) do
    {:closed, reason}
  end

  def normalize_message(_message, _transport), do: :ignore

  @impl true
  @spec init(keyword()) :: {:ok, state()} | {:stop, term()}
  def init(opts) do
    owner = Keyword.get(opts, :owner)

    if is_pid(owner) do
      owner_ref = Process.monitor(owner)

      case connect_with_retry(opts) do
        {:ok, transport_state} ->
          {:ok, Map.merge(transport_state, %{owner: owner, owner_ref: owner_ref})}

        {:error, reason} ->
          {:stop, reason}
      end
    else
      {:stop, {:invalid_url, :missing_owner}}
    end
  end

  @impl true
  def handle_call({:send, payload}, _from, state) do
    case encode_and_send_text(state, payload) do
      {:ok, next_state} -> {:reply, :ok, next_state}
      {:error, next_state, _reason} -> {:stop, :normal, {:error, :closed}, next_state}
    end
  end

  @impl true
  def handle_call(:close, _from, state) do
    next_state = close_connection(state)
    {:stop, :normal, :ok, next_state}
  end

  @impl true
  def handle_info({:DOWN, owner_ref, :process, _pid, _reason}, %{owner_ref: owner_ref} = state) do
    {:stop, :normal, close_connection(state)}
  end

  @impl true
  def handle_info(message, state) do
    case Mint.WebSocket.stream(state.conn, message) do
      :unknown ->
        {:noreply, state}

      {:ok, conn, responses} ->
        case handle_responses(%{state | conn: conn}, responses) do
          {:ok, next_state} -> {:noreply, next_state}
          {:stop, next_state} -> {:stop, :normal, next_state}
        end

      {:error, conn, reason, responses} ->
        case handle_responses(%{state | conn: conn}, responses) do
          {:ok, next_state} ->
            notify_owner(next_state, {:transport_error, reason})
            {:stop, :normal, close_connection(next_state)}

          {:stop, next_state} ->
            {:stop, :normal, next_state}
        end
    end
  end

  defp connect_with_retry(opts) do
    url = Keyword.get(opts, :url) || Keyword.get(opts, :websocket_url)

    with {:ok, uri} <- parse_url(url),
         {:ok, headers} <- build_headers(opts) do
      do_connect(
        %{
          uri: uri,
          headers: headers,
          opts: opts,
          retry_attempts: Keyword.get(opts, :retry_attempts, @default_retry_attempts),
          retry_delay_ms: Keyword.get(opts, :retry_delay_ms, @default_retry_delay_ms)
        },
        0
      )
    end
  end

  defp do_connect(ctx, attempt) do
    handshake_timeout = Keyword.get(ctx.opts, :handshake_timeout, @default_handshake_timeout)
    connect_opts = connect_opts_for(ctx.uri, Keyword.get(ctx.opts, :connect_opts, []))
    http_scheme = mint_scheme(ctx.uri.scheme)
    websocket_scheme = websocket_scheme(ctx.uri.scheme)
    path = request_path(ctx.uri)

    with {:ok, conn} <- connect_socket(http_scheme, ctx.uri.host, ctx.uri.port, connect_opts),
         {:ok, conn, request_ref} <- upgrade_socket(websocket_scheme, conn, path, ctx.headers),
         {:ok, conn, status, response_headers} <-
           await_upgrade_response(conn, request_ref, handshake_timeout),
         {:ok, conn, websocket} <-
           finalize_websocket_upgrade(conn, request_ref, status, response_headers) do
      {:ok, %{conn: conn, request_ref: request_ref, websocket: websocket}}
    else
      {:error, conn, %Mint.WebSocket.UpgradeFailureError{} = error} ->
        retry_upgrade_failure(conn, error.status_code, error.headers, ctx, attempt)

      {:error, reason} ->
        {:error, reason}

      {:error, conn, reason} ->
        _ = Mint.HTTP.close(conn)
        {:error, wrap_transport_error(reason)}
    end
  end

  defp retry_upgrade_failure(conn, status, headers, ctx, attempt) do
    _ = Mint.HTTP.close(conn)

    if attempt < ctx.retry_attempts and MapSet.member?(@overload_statuses, status) do
      Process.sleep(retry_after_ms(headers, ctx.retry_delay_ms, attempt))
      do_connect(ctx, attempt + 1)
    else
      {:error, {:upgrade_failed, status, headers}}
    end
  end

  defp connect_socket(scheme, host, port, connect_opts) do
    case Mint.HTTP.connect(scheme, host, port, connect_opts) do
      {:ok, conn} -> {:ok, conn}
      {:error, reason} -> {:error, {:connect_failed, reason}}
    end
  end

  defp upgrade_socket(scheme, conn, path, headers) do
    case Mint.WebSocket.upgrade(scheme, conn, path, headers) do
      {:ok, next_conn, request_ref} -> {:ok, next_conn, request_ref}
      {:error, next_conn, reason} -> {:error, next_conn, {:upgrade_failed, reason}}
    end
  end

  defp await_upgrade_response(conn, request_ref, timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout

    do_await_upgrade_response(conn, request_ref, deadline, %{
      status: nil,
      headers: nil,
      done: false
    })
  end

  defp do_await_upgrade_response(conn, request_ref, deadline, acc) do
    timeout = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      message ->
        case stream_upgrade_message(conn, request_ref, acc, message) do
          {:retry, next_conn, next_acc} ->
            do_await_upgrade_response(next_conn, request_ref, deadline, next_acc)

          {:ok, next_conn, status, headers} ->
            {:ok, next_conn, status, headers}

          {:error, next_conn, reason} ->
            {:error, next_conn, reason}
        end
    after
      timeout ->
        _ = Mint.HTTP.close(conn)
        {:error, {:handshake_failed, :timeout}}
    end
  end

  defp reduce_upgrade_responses(request_ref, acc, responses) do
    Enum.reduce(responses, acc, fn
      {:status, ^request_ref, status}, response_acc -> %{response_acc | status: status}
      {:headers, ^request_ref, headers}, response_acc -> %{response_acc | headers: headers}
      {:done, ^request_ref}, response_acc -> %{response_acc | done: true}
      _response, response_acc -> response_acc
    end)
  end

  defp stream_upgrade_message(conn, request_ref, acc, message) do
    case Mint.WebSocket.stream(conn, message) do
      :unknown ->
        {:retry, conn, acc}

      {:ok, next_conn, responses} ->
        next_acc = reduce_upgrade_responses(request_ref, acc, responses)
        maybe_finish_upgrade(next_conn, next_acc)

      {:error, next_conn, reason, responses} ->
        next_acc = reduce_upgrade_responses(request_ref, acc, responses)

        case maybe_finish_upgrade(next_conn, next_acc) do
          {:retry, _conn, _acc} -> {:error, next_conn, {:handshake_failed, reason}}
          result -> result
        end
    end
  end

  defp maybe_finish_upgrade(conn, %{status: status, headers: headers, done: true})
       when not is_nil(status) and not is_nil(headers) do
    {:ok, conn, status, headers}
  end

  defp maybe_finish_upgrade(conn, acc), do: {:retry, conn, acc}

  @spec finalize_websocket_upgrade(Mint.HTTP.t(), term(), non_neg_integer(), [
          {binary(), binary()}
        ]) ::
          {:ok, Mint.HTTP.t(), Mint.WebSocket.t()}
          | {:error, Mint.HTTP.t(), term()}
  defp finalize_websocket_upgrade(conn, request_ref, status, response_headers) do
    # credo:disable-for-next-line Credo.Check.Refactor.Apply
    apply(Mint.WebSocket, :new, [conn, request_ref, status, response_headers])
  end

  defp handle_responses(state, responses) do
    Enum.reduce_while(responses, {:ok, state}, fn
      {:data, request_ref, data}, {:ok, %{request_ref: request_ref} = acc_state} ->
        case decode_frames(acc_state, data) do
          {:ok, next_state} -> {:cont, {:ok, next_state}}
          {:stop, next_state} -> {:halt, {:stop, next_state}}
        end

      _response, {:ok, acc_state} ->
        {:cont, {:ok, acc_state}}
    end)
  end

  defp decode_frames(state, data) do
    {websocket, actions} = WebSocketFrames.decode(state.websocket, data)
    handle_frame_actions(%{state | websocket: websocket}, actions)
  end

  defp encode_and_send_text(state, payload) do
    send_frame(state, WebSocketFrames.text(payload))
  end

  defp handle_frame_actions(state, []), do: {:ok, state}

  defp handle_frame_actions(state, [{:data, payload} | actions]) do
    notify_data(state, payload)
    handle_frame_actions(state, actions)
  end

  defp handle_frame_actions(state, [{:pong, payload} | actions]) do
    case send_frame(state, {:pong, payload}) do
      {:ok, next_state} -> handle_frame_actions(next_state, actions)
      {:error, next_state, _reason} -> {:stop, next_state}
    end
  end

  defp handle_frame_actions(state, [{:remote_close, code, reason} | _actions]) do
    {:stop, acknowledge_remote_close(state, code, reason)}
  end

  defp handle_frame_actions(state, [{:decode_failed, reason} | _actions]) do
    notify_owner(state, {:decode_failed, reason})
    {:stop, close_connection(state)}
  end

  defp send_frame(state, frame) do
    case Mint.WebSocket.encode(state.websocket, frame) do
      {:ok, websocket, data} ->
        case Mint.WebSocket.stream_request_body(state.conn, state.request_ref, data) do
          {:ok, conn} ->
            {:ok, %{state | websocket: websocket, conn: conn}}

          {:error, conn, reason} ->
            next_state = %{state | websocket: websocket, conn: conn}
            notify_owner(next_state, {:send_failed, reason})
            {:error, close_connection(next_state), reason}
        end

      {:error, websocket, reason} ->
        next_state = %{state | websocket: websocket}
        notify_owner(next_state, {:send_failed, reason})
        {:error, close_connection(next_state), reason}
    end
  end

  defp acknowledge_remote_close(state, code, reason) do
    next_state =
      case send_frame(state, :close) do
        {:ok, updated_state} -> updated_state
        {:error, updated_state, _reason} -> updated_state
      end

    notify_owner(next_state, {:remote_close, code, reason})
    close_connection(next_state)
  end

  defp close_connection(state) do
    _ = Mint.HTTP.close(state.conn)
    state
  rescue
    _error -> state
  end

  defp notify_data(state, payload) when is_binary(payload) do
    Kernel.send(state.owner, {self(), {:transport_data, payload}})
  end

  defp notify_owner(state, reason) do
    Kernel.send(state.owner, {self(), {:transport_closed, reason}})
  end

  defp parse_url(nil), do: {:error, :missing_url}

  defp parse_url(url) when is_binary(url) do
    uri = URI.parse(url)

    cond do
      uri.scheme not in ["ws", "wss"] ->
        {:error, {:unsupported_scheme, inspect(uri.scheme)}}

      !is_binary(uri.host) ->
        {:error, {:invalid_url, url}}

      true ->
        {:ok, %{uri | port: uri.port || default_port(uri.scheme)}}
    end
  end

  defp parse_url(other), do: {:error, {:invalid_url, other}}

  defp build_headers(opts) do
    headers = Keyword.get(opts, :headers, [])
    bearer_token = Keyword.get(opts, :bearer_token) || Keyword.get(opts, :auth_token)

    with {:ok, normalized_headers} <- normalize_headers(headers) do
      {:ok, maybe_put_bearer_token(normalized_headers, bearer_token)}
    end
  end

  defp normalize_headers(headers) when is_list(headers) do
    if Enum.all?(headers, &(is_tuple(&1) and tuple_size(&1) == 2)) do
      {:ok,
       Enum.map(headers, fn {key, value} ->
         {to_string(key), to_string(value)}
       end)}
    else
      {:error, {:invalid_url, {:headers, headers}}}
    end
  end

  defp normalize_headers(headers) when is_map(headers) do
    headers
    |> Enum.map(fn {key, value} -> {to_string(key), to_string(value)} end)
    |> then(&{:ok, &1})
  end

  defp normalize_headers(headers), do: {:error, {:invalid_url, {:headers, headers}}}

  defp maybe_put_bearer_token(headers, nil), do: headers

  defp maybe_put_bearer_token(headers, token) do
    auth_present? =
      Enum.any?(headers, fn {key, _value} -> String.downcase(key) == "authorization" end)

    if auth_present?, do: headers, else: [{"authorization", "Bearer #{token}"} | headers]
  end

  defp connect_opts_for(uri, connect_opts) do
    if uri.scheme == "wss" do
      transport_opts = Keyword.get(connect_opts, :transport_opts, [])

      if Keyword.has_key?(transport_opts, :cacerts) or
           Keyword.has_key?(transport_opts, :cacertfile) do
        connect_opts
      else
        Keyword.put(connect_opts, :transport_opts, [
          {:cacerts, :public_key.cacerts_get()} | transport_opts
        ])
      end
    else
      connect_opts
    end
  end

  defp retry_after_ms(headers, retry_delay_ms, attempt) do
    case List.keyfind(headers, "retry-after", 0) do
      {_, value} ->
        case Integer.parse(value) do
          {seconds, ""} -> max(seconds, 0) * 1_000
          _ -> backoff_ms(retry_delay_ms, attempt)
        end

      nil ->
        backoff_ms(retry_delay_ms, attempt)
    end
  end

  defp backoff_ms(retry_delay_ms, attempt) do
    retry_delay_ms * trunc(:math.pow(2, attempt))
  end

  defp request_path(uri) do
    path = if uri.path in [nil, ""], do: "/", else: uri.path
    if is_binary(uri.query), do: path <> "?" <> uri.query, else: path
  end

  defp wrap_transport_error({connect_stage, _reason} = reason)
       when connect_stage in [:connect_failed, :upgrade_failed, :handshake_failed] do
    reason
  end

  defp wrap_transport_error(reason), do: {:transport_error, reason}

  defp mint_scheme("ws"), do: :http
  defp mint_scheme("wss"), do: :https

  defp websocket_scheme("ws"), do: :ws
  defp websocket_scheme("wss"), do: :wss

  defp default_port("ws"), do: 80
  defp default_port("wss"), do: 443
end
