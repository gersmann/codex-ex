defmodule CodexEx.AppServer.Session do
  @moduledoc false

  use GenServer

  alias CodexEx.AppServer.Message
  alias CodexEx.AppServer.Protocol.Generated.Shared.ClientRequest
  alias CodexEx.AppServer.StdioTransport
  alias CodexEx.AppServer.Transport
  alias CodexEx.AppServer.WebSocketTransport

  @default_timeout 15_000
  @max_request_timeout_ms 30 * 60 * 1_000
  @request_call_grace_ms 1_000
  @transport_ack_delay_ms 50
  @jsonrpc_version "2.0"

  @type request_timeout :: timeout()
  @type remote_error :: %{required(binary()) => term()}
  @type request_result :: {:ok, term()} | {:error, {:remote_error, remote_error()}}
  @type t :: GenServer.server()
  @type session_error ::
          {:encode_failed, term()}
          | {:send_failed, :closed}
          | :request_timeout
          | :session_closed
          | {:protocol_error, term()}
          | {:transport_closed, term()}
  @type pending_request :: %{from: GenServer.from(), timer_ref: reference() | nil}
  @type initialize_bootstrap :: :fresh | {:reattached, map(), boolean()}
  @type terminal_close :: {term(), non_neg_integer()} | nil
  @type state :: %{
          buffer: binary(),
          initialize_bootstrap: initialize_bootstrap(),
          next_id: pos_integer(),
          notification_target: pid(),
          pending: %{optional(term()) => pending_request()},
          pending_transport_ack: non_neg_integer() | nil,
          terminal_close: terminal_close(),
          last_acknowledged_transport_sequence: non_neg_integer(),
          last_transport_sequence: non_neg_integer(),
          transport: Transport.handle(),
          transport_module: module()
        }
  @dialyzer {:nowarn_function, [initialize: 3]}

  @type result :: request_result() | {:error, session_error()}

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  @spec request(t(), binary(), map() | list(), request_timeout()) ::
          {:ok, term()} | {:error, term()}
  def request(server, method, params \\ %{}, timeout \\ @default_timeout)
      when is_binary(method) and (is_map(params) or is_list(params)) and (is_integer(timeout) or timeout == :infinity) do
    timeout = bounded_request_timeout(timeout)

    server
    |> GenServer.call({:request, method, params, timeout}, call_timeout(timeout))
    |> normalize_request_response()
  catch
    :exit, reason -> {:error, {:session_call_failed, reason}}
  end

  @spec notify(t(), binary(), map() | list()) :: :ok | {:error, term()}
  def notify(server, method, params \\ %{}) when is_binary(method) and (is_map(params) or is_list(params)) do
    server
    |> GenServer.call({:notify, method, params})
    |> normalize_notify_response()
  end

  @spec respond(
          t(),
          term(),
          {:ok, Message.supported_reply_payload()} | {:error, term()},
          request_timeout()
        ) :: :ok | {:error, term()}
  def respond(server, id, reply, timeout \\ @default_timeout)

  def respond(server, id, {:ok, result}, timeout) when is_integer(timeout) or timeout == :infinity do
    with {:ok, encoded_result} <- Message.encode_reply_payload(result) do
      payload = %{"jsonrpc" => @jsonrpc_version, "id" => id, "result" => encoded_result}

      server
      |> GenServer.call({:respond, payload}, timeout)
      |> normalize_notify_response()
    end
  end

  def respond(server, id, {:error, error}, timeout) when is_integer(timeout) or timeout == :infinity do
    payload = %{"jsonrpc" => @jsonrpc_version, "id" => id, "error" => error}

    server
    |> GenServer.call({:respond, payload}, timeout)
    |> normalize_notify_response()
  end

  @spec initialize(t(), map() | list(), request_timeout()) :: {:ok, term()} | {:error, term()}
  def initialize(server, params \\ %{}, timeout \\ @default_timeout)
      when (is_map(params) or is_list(params)) and (is_integer(timeout) or timeout == :infinity) do
    case fetch_initialize_bootstrap(server, timeout) do
      {:ok, :fresh} ->
        with {:ok, result} <- request(server, "initialize", params, timeout),
             :ok <- notify(server, "initialized", %{}) do
          {:ok, result}
        end

      {:ok, {:reattached, result, true}} ->
        {:ok, result}

      {:ok, {:reattached, result, false}} ->
        with :ok <- notify(server, "initialized", %{}) do
          {:ok, result}
        end

      {:error, _reason} = error ->
        error
    end
  end

  @spec stop(t(), term(), request_timeout()) :: :ok
  def stop(server, reason \\ :normal, timeout \\ @default_timeout) do
    :ok = GenServer.call(server, {:stop, reason}, timeout)
    :ok
  end

  @doc "Acknowledges that persisted history has reconciled a daemon replay gap."
  @spec acknowledge_replay_gap(t(), non_neg_integer()) :: :ok | {:error, term()}
  def acknowledge_replay_gap(server, through_sequence) when is_integer(through_sequence) and through_sequence >= 0 do
    server
    |> GenServer.call({:acknowledge_replay_gap, through_sequence}, @default_timeout)
    |> normalize_notify_response()
  catch
    :exit, reason -> {:error, {:session_call_failed, reason}}
  end

  @doc "Acknowledges ordered downstream handling through the given transport sequence."
  @spec acknowledge_transport_sequence(t(), non_neg_integer()) :: :ok | {:error, term()}
  def acknowledge_transport_sequence(server, sequence) when is_integer(sequence) and sequence >= 0 do
    server
    |> GenServer.call({:acknowledge_transport_sequence, sequence}, @default_timeout)
    |> normalize_notify_response()
  catch
    :exit, reason -> {:error, {:session_call_failed, reason}}
  end

  @impl true
  @spec init(keyword()) ::
          {:ok, state()} | {:ok, state(), {:continue, term()}} | {:stop, term()}
  def init(opts) do
    notification_target = Keyword.get(opts, :notification_target, self())
    transport_module = transport_module(Keyword.get(opts, :transport, :stdio))
    transport_opts = Keyword.put(opts, :owner, self())

    case transport_module.open(transport_opts) do
      {:ok, transport} ->
        {transport, bootstrap} =
          transport_session_bootstrap(transport_module, transport)

        replay_gap = bootstrap.replay_gap
        last_transport_sequence = max(bootstrap.acknowledged_through, replay_gap || 0)

        state = %{
          transport: transport,
          transport_module: transport_module,
          next_id: bootstrap.next_request_id,
          initialize_bootstrap: bootstrap.initialize_bootstrap,
          pending: %{},
          pending_transport_ack: nil,
          terminal_close: nil,
          last_acknowledged_transport_sequence: bootstrap.acknowledged_through,
          last_transport_sequence: last_transport_sequence,
          buffer: "",
          notification_target: notification_target
        }

        if replay_gap || bootstrap.replay != [] || bootstrap.pending_requests != [] ||
             bootstrap.terminal_close do
          {:ok, state, {:continue, {:replay, bootstrap}}}
        else
          {:ok, state}
        end

      {:error, reason} ->
        {:stop, {:transport_start_failed, reason}}
    end
  end

  @impl true
  def handle_continue({:replay, bootstrap}, state) do
    if is_integer(bootstrap.replay_gap) do
      send_replay_gap(state, bootstrap.replay_gap)
    end

    case consume_bootstrap_replay(state, bootstrap.replay, bootstrap.pending_requests) do
      {:ok, state} ->
        mark_terminal_close(state, bootstrap.terminal_close)

      {:error, reason, state} ->
        :ok = state.transport_module.close(state.transport)
        state = reply_all_pending(state, {:error, {:protocol_error, reason}})
        {:stop, {:protocol_error, reason}, state}
    end
  end

  @impl true
  def handle_call(
        :initialize_bootstrap,
        _from,
        %{initialize_bootstrap: {:reattached, result, _initialized?}, terminal_close: {_reason, _sequence}} = state
      ) do
    # The app-server is already gone, so it cannot accept `initialized`. Let the
    # Client finish booting so it can drain and acknowledge the terminal replay.
    {:reply, {:reattached, result, true}, state}
  end

  def handle_call(:initialize_bootstrap, _from, state) do
    {:reply, state.initialize_bootstrap, state}
  end

  @impl true
  def handle_call({:acknowledge_replay_gap, through_sequence}, _from, state)
      when is_integer(through_sequence) and through_sequence >= 0 do
    reply =
      acknowledge_transport_replay_gap(
        state.transport_module,
        state.transport,
        through_sequence
      )

    {:reply, reply, state}
  end

  @impl true
  def handle_call({:acknowledge_transport_sequence, sequence}, _from, state)
      when is_integer(sequence) and sequence >= 0 do
    if sequence <= state.last_transport_sequence do
      state =
        Map.put(
          state,
          :last_acknowledged_transport_sequence,
          max(state.last_acknowledged_transport_sequence, sequence)
        )

      acknowledge_or_schedule_transport_sequence(state, sequence)
    else
      {:reply,
       {:error,
        {:protocol_error, {:acknowledging_undelivered_transport_sequence, sequence, state.last_transport_sequence}}},
       state}
    end
  end

  def handle_call({:request, _method, _params, _timeout}, _from, %{terminal_close: {reason, _sequence}} = state) do
    {:reply, {:error, {:transport_closed, reason}}, state}
  end

  @impl true
  def handle_call({:request, method, params, timeout}, from, state) do
    id = state.next_id

    payload = %{
      "jsonrpc" => @jsonrpc_version,
      "id" => id,
      "method" => method,
      "params" => params
    }

    case send_payload(state, payload) do
      :ok ->
        pending = Map.put(state.pending, id, pending_request(from, id, timeout))
        {:noreply, %{state | next_id: id + 1, pending: pending}}

      {:error, {:encode_failed, reason}} ->
        {:reply, {:error, {:encode_failed, reason}}, state}

      {:error, :closed} ->
        {:reply, {:error, {:send_failed, :closed}}, %{state | next_id: id + 1}}
    end
  end

  def handle_call({:notify, _method, _params}, _from, %{terminal_close: {reason, _sequence}} = state) do
    {:reply, {:error, {:transport_closed, reason}}, state}
  end

  @impl true
  def handle_call({:notify, method, params}, _from, state) do
    payload = %{"jsonrpc" => @jsonrpc_version, "method" => method, "params" => params}

    case send_payload(state, payload) do
      :ok -> {:reply, :ok, state}
      {:error, {:encode_failed, reason}} -> {:reply, {:error, {:encode_failed, reason}}, state}
      {:error, :closed} -> {:reply, {:error, {:send_failed, :closed}}, state}
    end
  end

  def handle_call({:respond, _payload}, _from, %{terminal_close: {reason, _sequence}} = state) do
    {:reply, {:error, {:transport_closed, reason}}, state}
  end

  @impl true
  def handle_call({:respond, payload}, _from, state) do
    case send_payload(state, payload) do
      :ok -> {:reply, :ok, state}
      {:error, {:encode_failed, reason}} -> {:reply, {:error, {:encode_failed, reason}}, state}
      {:error, :closed} -> {:reply, {:error, {:send_failed, :closed}}, state}
    end
  end

  @impl true
  def handle_call({:stop, reason}, _from, state) do
    :ok = state.transport_module.close(state.transport)
    state = reply_all_pending(state, {:error, :session_closed})
    {:stop, reason, :ok, state}
  end

  @impl true
  def handle_info(:flush_transport_ack, state) do
    if is_integer(state.pending_transport_ack) do
      acknowledge_transport_sequence(
        state.transport_module,
        state.transport,
        state.pending_transport_ack
      )
    end

    {:noreply, %{state | pending_transport_ack: nil}}
  end

  def handle_info(message, state) do
    message
    |> state.transport_module.normalize_message(state.transport)
    |> handle_normalized_message(message, state)
  end

  defp handle_normalized_message({:data, data}, _message, state), do: handle_transport_data(state, data, nil)

  defp handle_normalized_message({:data, _data, sequence}, _message, state)
       when is_integer(sequence) and sequence >= 0 and sequence <= state.last_acknowledged_transport_sequence,
       do: {:noreply, schedule_transport_ack(state, sequence)}

  defp handle_normalized_message({:data, data, sequence}, _message, state)
       when is_integer(sequence) and sequence >= 0 and
              (sequence <= state.last_transport_sequence or sequence == state.last_transport_sequence + 1),
       do: handle_transport_data(state, data, sequence)

  defp handle_normalized_message({:data, _data, sequence}, _message, state) when is_integer(sequence) and sequence >= 0,
    do: stop_for_transport_sequence_gap(state, sequence)

  defp handle_normalized_message(
         {:replay_gap, %{"missing_through_sequence" => through_sequence} = payload},
         _message,
         state
       )
       when is_integer(through_sequence) and through_sequence >= 0 do
    send_notification_target(
      state.notification_target,
      {:codex_app_server_replay_gap, payload}
    )

    {:noreply, %{state | last_transport_sequence: max(state.last_transport_sequence, through_sequence)}}
  end

  defp handle_normalized_message({:replay_gap, payload}, _message, state) when is_map(payload) do
    send_notification_target(
      state.notification_target,
      {:codex_app_server_replay_gap, payload}
    )

    {:noreply, state}
  end

  defp handle_normalized_message({:closed, reason, sequence}, _message, state)
       when is_integer(sequence) and sequence >= 0 and
              (sequence <= state.last_transport_sequence or sequence == state.last_transport_sequence + 1) do
    mark_terminal_close(state, {reason, sequence})
  end

  defp handle_normalized_message({:closed, _reason, sequence}, _message, state)
       when is_integer(sequence) and sequence >= 0, do: stop_for_transport_sequence_gap(state, sequence)

  defp handle_normalized_message({:closed, reason}, _message, state) do
    close_for_transport_reason(state, reason)
  end

  defp handle_normalized_message(:ignore, message, state) do
    case timeout_pending_request(state, message) do
      {:handled, next_state} -> {:noreply, next_state}
      :unhandled -> {:noreply, state}
    end
  end

  defp close_for_transport_reason(state, reason) do
    state = reply_all_pending(state, {:error, {:transport_closed, reason}})
    {:stop, session_close_reason(reason), state}
  end

  defp mark_terminal_close(state, nil), do: {:noreply, state}

  defp mark_terminal_close(state, {reason, sequence}) when is_integer(sequence) and sequence >= 0 do
    state =
      state
      |> reply_all_pending({:error, {:transport_closed, reason}})
      |> Map.put(:terminal_close, {reason, sequence})
      |> record_transport_sequence(sequence)

    send_notification_target(
      state.notification_target,
      {:codex_app_server_transport_closed, reason, sequence}
    )

    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{transport: transport, transport_module: transport_module}) do
    :ok = transport_module.close(transport)
    :ok
  end

  def terminate(_reason, _state), do: :ok

  defp send_payload(state, payload) do
    case Jason.encode(normalize_outgoing_payload(payload)) do
      {:ok, json} -> state.transport_module.send(state.transport, json <> "\n")
      {:error, reason} -> {:error, {:encode_failed, reason}}
    end
  end

  defp handle_transport_data(state, data, sequence) do
    case consume_data(state, data, sequence) do
      {:ok, new_state} ->
        {:noreply, record_transport_sequence(new_state, sequence)}

      {:error, reason, new_state} ->
        :ok = new_state.transport_module.close(new_state.transport)
        new_state = reply_all_pending(new_state, {:error, {:protocol_error, reason}})
        {:stop, {:protocol_error, reason}, new_state}
    end
  end

  defp record_transport_sequence(state, nil), do: state

  defp record_transport_sequence(state, sequence) when is_integer(sequence) and sequence >= 0 do
    %{state | last_transport_sequence: max(state.last_transport_sequence, sequence)}
  end

  defp stop_for_transport_sequence_gap(state, sequence) do
    reason =
      {:non_contiguous_transport_sequence, %{expected: state.last_transport_sequence + 1, received: sequence}}

    :ok = state.transport_module.close(state.transport)
    state = reply_all_pending(state, {:error, {:protocol_error, reason}})
    {:stop, {:protocol_error, reason}, state}
  end

  defp schedule_transport_ack(%{pending_transport_ack: nil} = state, sequence)
       when is_integer(sequence) and sequence >= 0 do
    Process.send_after(self(), :flush_transport_ack, @transport_ack_delay_ms)
    %{state | pending_transport_ack: sequence}
  end

  defp schedule_transport_ack(state, sequence) when is_integer(sequence) and sequence >= 0 do
    %{state | pending_transport_ack: max(state.pending_transport_ack, sequence)}
  end

  defp acknowledge_or_schedule_transport_sequence(%{terminal_close: {reason, terminal_sequence}} = state, sequence)
       when sequence >= terminal_sequence do
    :ok = acknowledge_transport_sequence(state.transport_module, state.transport, sequence)
    {:stop, session_close_reason(reason), :ok, %{state | pending_transport_ack: nil}}
  end

  defp acknowledge_or_schedule_transport_sequence(state, sequence) do
    {:reply, :ok, schedule_transport_ack(state, sequence)}
  end

  defp acknowledge_transport_sequence(transport_module, transport, sequence) do
    if transport_exports?(transport_module, :acknowledge, 2),
      do: transport_module.acknowledge(transport, sequence),
      else: :ok
  end

  defp acknowledge_transport_replay_gap(transport_module, transport, through_sequence) do
    if transport_exports?(transport_module, :acknowledge_replay_gap, 2),
      do: transport_module.acknowledge_replay_gap(transport, through_sequence),
      else: :ok
  end

  defp transport_exports?(transport_module, function, arity) do
    is_atom(transport_module) and Code.ensure_loaded?(transport_module) and
      function_exported?(transport_module, function, arity)
  end

  defp normalize_outgoing_payload(%{"jsonrpc" => @jsonrpc_version, "method" => method} = payload)
       when is_binary(method) do
    request =
      %ClientRequest{
        id: Map.get(payload, "id"),
        method: method,
        params: Map.get(payload, "params")
      }

    encoded = ClientRequest.encode(request)

    Map.merge(%{"jsonrpc" => @jsonrpc_version}, encoded)
  end

  defp normalize_outgoing_payload(payload), do: payload

  defp consume_data(state, data, sequence) do
    {lines, buffer} = split_complete_lines(state.buffer <> data)
    state = %{state | buffer: buffer}

    Enum.reduce_while(lines, {:ok, state}, fn line, {:ok, acc_state} ->
      case handle_line(acc_state, line, sequence) do
        {:ok, next_state} ->
          {:cont, {:ok, next_state}}

        {:error, reason, next_state} ->
          {:halt, {:error, reason, next_state}}
      end
    end)
  end

  defp split_complete_lines(buffer) do
    {rest, lines} = buffer |> String.split("\n") |> List.pop_at(-1)
    {lines, rest}
  end

  defp handle_line(state, raw_line, sequence) do
    line = String.trim_trailing(raw_line, "\r")

    if line == "" do
      {:ok, state}
    else
      decode_and_handle_line(state, line, sequence)
    end
  end

  defp decode_and_handle_line(state, line, sequence) do
    with {:ok, payload} when is_map(payload) <- Jason.decode(line),
         :ok <- validate_jsonrpc(payload) do
      handle_rpc_payload(state, payload, sequence)
    else
      {:error, reason} -> {:error, reason, state}
      error -> {:error, {:invalid_payload, error}, state}
    end
  end

  defp validate_jsonrpc(%{"jsonrpc" => @jsonrpc_version}), do: :ok
  defp validate_jsonrpc(%{} = payload) when not is_map_key(payload, "jsonrpc"), do: :ok
  defp validate_jsonrpc(_), do: {:error, :invalid_jsonrpc_version}

  defp handle_rpc_payload(state, %{"id" => _id, "result" => result} = payload, sequence) do
    handle_rpc_response(state, payload, {:ok, result}, sequence)
  end

  defp handle_rpc_payload(state, %{"id" => _id, "error" => error} = payload, sequence) do
    handle_rpc_response(state, payload, {:error, {:remote_error, error}}, sequence)
  end

  defp handle_rpc_payload(state, %{"method" => method} = payload, sequence) when is_binary(method) do
    params = Map.get(payload, "params", %{})

    message_type =
      if Map.has_key?(payload, "id") do
        :codex_app_server_request
      else
        :codex_app_server_notification
      end

    send_notification_target(
      state.notification_target,
      sequenced_message(
        message_type,
        payload |> Map.take(["id"]) |> Map.put("method", method) |> Map.put("params", params),
        sequence
      )
    )

    {:ok, state}
  end

  defp handle_rpc_payload(state, payload, _sequence), do: {:error, {:unexpected_payload, payload}, state}

  defp handle_rpc_response(state, %{"id" => id} = payload, reply, sequence) do
    case Map.pop(state.pending, id) do
      {nil, pending} ->
        send_notification_target(
          state.notification_target,
          sequenced_message(:codex_app_server_unmatched_response, payload, sequence)
        )

        {:ok, %{state | pending: pending}}

      {from, pending} ->
        reply_pending_request(from, reply)
        send_sequence_handled(state.notification_target, sequence)
        {:ok, %{state | pending: pending}}
    end
  end

  defp sequenced_message(type, payload, nil), do: {type, payload}

  defp sequenced_message(type, payload, sequence) when is_integer(sequence) and sequence >= 0,
    do: {type, payload, sequence}

  defp send_sequence_handled(_target, nil), do: :ok

  defp send_sequence_handled(target, sequence) when is_integer(sequence) and sequence >= 0 do
    send_notification_target(target, {:codex_app_server_sequence_handled, sequence})
  end

  defp send_replay_gap(state, through_sequence) when is_integer(through_sequence) and through_sequence >= 0 do
    send_notification_target(
      state.notification_target,
      {:codex_app_server_replay_gap,
       %{
         "transport_id" => state.transport.transport_id,
         "missing_through_sequence" => through_sequence
       }}
    )
  end

  defp consume_bootstrap_replay(state, replay, pending_requests) do
    with {:ok, state} <- consume_replay_entries(state, replay) do
      consume_pending_requests(state, pending_requests)
    end
  end

  defp consume_replay_entries(state, replay) do
    Enum.reduce_while(replay, {:ok, state}, fn {sequence, message}, {:ok, state} ->
      cond do
        sequence <= state.last_acknowledged_transport_sequence ->
          {:cont, {:ok, schedule_transport_ack(state, sequence)}}

        sequence <= state.last_transport_sequence or
            sequence == state.last_transport_sequence + 1 ->
          case consume_data(state, Jason.encode!(message) <> "\n", sequence) do
            {:ok, state} -> {:cont, {:ok, record_transport_sequence(state, sequence)}}
            {:error, reason, state} -> {:halt, {:error, reason, state}}
          end

        true ->
          reason =
            {:non_contiguous_transport_sequence, %{expected: state.last_transport_sequence + 1, received: sequence}}

          {:halt, {:error, reason, state}}
      end
    end)
  end

  defp consume_pending_requests(state, pending_requests) do
    Enum.reduce_while(pending_requests, {:ok, state}, fn {_sequence, message}, {:ok, state} ->
      case consume_data(state, Jason.encode!(message) <> "\n", nil) do
        {:ok, state} -> {:cont, {:ok, state}}
        {:error, reason, state} -> {:halt, {:error, reason, state}}
      end
    end)
  end

  defp reply_all_pending(state, reply) do
    Enum.each(state.pending, fn {_id, from} ->
      reply_pending_request(from, reply)
    end)

    %{state | pending: %{}}
  end

  defp send_notification_target(target, message) when is_pid(target) do
    send(target, message)
    :ok
  end

  defp send_notification_target(_target, _message), do: :ok

  defp normalize_request_response({:ok, _result} = result), do: result
  defp normalize_request_response({:error, {:remote_error, _error}} = error), do: error
  defp normalize_request_response({:error, {:encode_failed, _reason}} = error), do: error
  defp normalize_request_response({:error, {:send_failed, :closed}} = error), do: error
  defp normalize_request_response({:error, :request_timeout} = error), do: error
  defp normalize_request_response({:error, :session_closed} = error), do: error
  defp normalize_request_response({:error, {:protocol_error, _reason}} = error), do: error
  defp normalize_request_response({:error, {:transport_closed, _exit_status}} = error), do: error

  defp normalize_request_response(other), do: {:error, {:protocol_error, {:unexpected_reply, other}}}

  defp normalize_notify_response(:ok), do: :ok
  defp normalize_notify_response({:error, {:encode_failed, _reason}} = error), do: error
  defp normalize_notify_response({:error, {:send_failed, :closed}} = error), do: error
  defp normalize_notify_response({:error, :session_closed} = error), do: error
  defp normalize_notify_response({:error, {:protocol_error, _reason}} = error), do: error
  defp normalize_notify_response({:error, {:transport_closed, _exit_status}} = error), do: error

  defp normalize_notify_response(other), do: {:error, {:protocol_error, {:unexpected_reply, other}}}

  defp transport_module(:stdio), do: StdioTransport
  defp transport_module(:websocket), do: WebSocketTransport
  defp transport_module(:mock), do: CodexEx.AppServer.MockTransport
  defp transport_module(module) when is_atom(module), do: module

  defp transport_session_bootstrap(transport_module, transport) do
    if transport_exports?(transport_module, :session_bootstrap, 1) do
      transport_module.session_bootstrap(transport)
    else
      default_transport_session_bootstrap(transport)
    end
  end

  defp default_transport_session_bootstrap(transport) do
    {transport,
     %{
       acknowledged_through: 0,
       initialize_bootstrap: :fresh,
       next_request_id: 1,
       pending_requests: [],
       replay: [],
       replay_gap: nil,
       terminal_close: nil
     }}
  end

  defp fetch_initialize_bootstrap(server, timeout) do
    timeout = timeout |> bounded_request_timeout() |> call_timeout()
    {:ok, GenServer.call(server, :initialize_bootstrap, timeout)}
  catch
    :exit, reason -> {:error, {:session_call_failed, reason}}
  end

  defp session_close_reason(:remote_client_disconnected), do: :normal
  defp session_close_reason({:remote_session_closed, _reason}), do: :normal
  defp session_close_reason({:send_failed, %Mint.TransportError{reason: :closed}}), do: :normal
  defp session_close_reason(reason), do: {:transport_closed, reason}

  defp pending_request(from, id, timeout) when is_integer(timeout) and timeout >= 0 do
    %{from: from, timer_ref: Process.send_after(self(), {:request_timeout, id}, timeout)}
  end

  defp bounded_request_timeout(:infinity), do: @max_request_timeout_ms
  defp bounded_request_timeout(timeout) when is_integer(timeout), do: timeout

  defp call_timeout(timeout) when is_integer(timeout) do
    timeout + @request_call_grace_ms
  end

  defp reply_pending_request(%{from: from, timer_ref: timer_ref}, reply) do
    cancel_pending_timer(timer_ref)
    GenServer.reply(from, reply)
  end

  defp timeout_pending_request(state, {:request_timeout, id}) do
    case Map.pop(state.pending, id) do
      {nil, _pending} ->
        :unhandled

      {request, pending} ->
        reply_pending_request(request, {:error, :request_timeout})
        {:handled, %{state | pending: pending}}
    end
  end

  defp timeout_pending_request(_state, _message), do: :unhandled

  defp cancel_pending_timer(nil), do: :ok

  defp cancel_pending_timer(timer_ref) do
    _ = Process.cancel_timer(timer_ref, async: true, info: false)
    :ok
  end
end
