defmodule CodexEx.AppServer.StdioProxyTransport do
  @moduledoc false

  @behaviour CodexEx.AppServer.Transport

  use GenServer

  import Kernel, except: [send: 2]

  alias CodexEx.AppServer.WebSocketFrames

  @handshake_timeout_ms 5_000
  @websocket_guid "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  @type state :: %{
          owner: pid(),
          owner_ref: reference(),
          port: port(),
          websocket: Mint.WebSocket.t()
        }

  # Mint does not expose a constructor for a bare, extension-free frame codec.
  @dialyzer {:nowarn_function, [open: 1, finish_init: 2]}

  @impl true
  @spec open(keyword()) :: GenServer.on_start()
  def open(opts), do: GenServer.start(__MODULE__, opts)

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
  catch
    :exit, _reason -> :ok
  end

  @impl true
  def normalize_message({transport, {:transport_data, data}}, transport) when is_pid(transport) and is_binary(data),
    do: {:data, data}

  def normalize_message({transport, {:transport_closed, reason}}, transport) when is_pid(transport), do: {:closed, reason}

  def normalize_message(_message, _transport), do: :ignore

  @impl true
  def init(opts) do
    with owner when is_pid(owner) <- Keyword.get(opts, :owner),
         executable when is_binary(executable) <- Keyword.get(opts, :executable),
         socket_path when is_binary(socket_path) <- Keyword.get(opts, :socket_path),
         {:ok, port} <- open_port(executable, socket_path),
         {:ok, websocket, pending_data} <- handshake(port) do
      state = %{
        owner: owner,
        owner_ref: Process.monitor(owner),
        port: port,
        websocket: websocket
      }

      finish_init(state, pending_data)
    else
      {:error, reason} -> {:stop, reason}
      _invalid_option -> {:stop, :invalid_proxy_option}
    end
  end

  @impl true
  def handle_call({:send, payload}, _from, state) do
    case send_frame(state, WebSocketFrames.text(payload)) do
      {:ok, state} -> {:reply, :ok, state}
      {:error, state} -> {:stop, :normal, {:error, :closed}, state}
    end
  end

  def handle_call(:close, _from, state) do
    {_status, state} = send_frame(state, :close)

    {:stop, :normal, :ok, close_port(state)}
  end

  @impl true
  def handle_info({:DOWN, owner_ref, :process, _pid, _reason}, %{owner_ref: owner_ref} = state),
    do: {:stop, :normal, close_port(state)}

  def handle_info({port, {:data, data}}, %{port: port} = state) when is_binary(data) do
    case decode_frames(state, data) do
      {:ok, state} -> {:noreply, state}
      {:stop, state} -> {:stop, :normal, state}
    end
  end

  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    notify_closed(state, {:proxy_exit, status})
    {:stop, :normal, state}
  end

  def handle_info(_message, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, state), do: close_port(state)

  defp finish_init(state, ""), do: {:ok, state}

  defp finish_init(state, pending_data) do
    case decode_frames(state, pending_data) do
      {:ok, state} ->
        {:ok, state}

      {:stop, _state} ->
        {:stop, :proxy_closed_during_handshake}
    end
  end

  defp open_port(executable, socket_path) do
    args = Enum.map(["app-server", "proxy", "--sock", socket_path], &String.to_charlist/1)

    {:ok,
     Port.open(
       {:spawn_executable, executable},
       [:binary, :exit_status, :use_stdio, :hide, {:args, args}]
     )}
  rescue
    error in ArgumentError -> {:error, {:proxy_open_failed, Exception.message(error)}}
  end

  defp handshake(port) do
    key = 16 |> :crypto.strong_rand_bytes() |> Base.encode64()

    request =
      "GET / HTTP/1.1\r\n" <>
        "Host: localhost\r\n" <>
        "Upgrade: websocket\r\n" <>
        "Connection: Upgrade\r\n" <>
        "Sec-WebSocket-Key: #{key}\r\n" <>
        "Sec-WebSocket-Version: 13\r\n\r\n"

    true = Port.command(port, request)
    await_handshake(port, key, "", System.monotonic_time(:millisecond) + @handshake_timeout_ms)
  rescue
    ArgumentError -> {:error, :proxy_closed_during_handshake}
  end

  defp await_handshake(port, key, buffer, deadline) do
    case :binary.match(buffer, "\r\n\r\n") do
      {header_end, 4} ->
        <<headers::binary-size(^header_end), _separator::binary-size(4), rest::binary>> = buffer

        with :ok <- validate_handshake(headers, key) do
          {:ok, struct(Mint.WebSocket), rest}
        end

      :nomatch ->
        receive do
          {^port, {:data, data}} ->
            await_handshake(port, key, buffer <> data, deadline)

          {^port, {:exit_status, status}} ->
            {:error, {:proxy_exit_during_handshake, status}}
        after
          max(deadline - System.monotonic_time(:millisecond), 0) ->
            {:error, :proxy_handshake_timeout}
        end
    end
  end

  defp validate_handshake(headers, key) do
    [status_line | header_lines] = String.split(headers, "\r\n")

    expected_accept =
      :sha
      |> :crypto.hash(key <> @websocket_guid)
      |> Base.encode64()

    accept =
      Enum.find_value(header_lines, fn line ->
        case String.split(line, ":", parts: 2) do
          [name, value] ->
            if String.downcase(name) == "sec-websocket-accept", do: String.trim(value)

          _other ->
            nil
        end
      end)

    if status_line == "HTTP/1.1 101 Switching Protocols" and accept == expected_accept,
      do: :ok,
      else: {:error, {:proxy_handshake_failed, status_line}}
  end

  defp decode_frames(state, data) do
    {websocket, actions} = WebSocketFrames.decode(state.websocket, data)
    handle_frame_actions(%{state | websocket: websocket}, actions)
  end

  defp handle_frame_actions(state, []), do: {:ok, state}

  defp handle_frame_actions(state, [{:data, payload} | actions]) do
    Kernel.send(state.owner, {self(), {:transport_data, payload}})
    handle_frame_actions(state, actions)
  end

  defp handle_frame_actions(state, [{:pong, payload} | actions]) do
    case send_frame(state, {:pong, payload}) do
      {:ok, state} -> handle_frame_actions(state, actions)
      {:error, state} -> {:stop, state}
    end
  end

  defp handle_frame_actions(state, [{:remote_close, code, reason} | _actions]) do
    {_status, state} = send_frame(state, :close)
    notify_closed(state, {:remote_close, code, reason})
    {:stop, close_port(state)}
  end

  defp handle_frame_actions(state, [{:decode_failed, reason} | _actions]) do
    notify_closed(state, {:decode_failed, reason})
    {:stop, close_port(state)}
  end

  defp send_frame(state, frame) do
    with {:ok, websocket, data} <- Mint.WebSocket.encode(state.websocket, frame),
         true <- Port.command(state.port, data) do
      {:ok, %{state | websocket: websocket}}
    else
      _error -> {:error, close_port(state)}
    end
  rescue
    ArgumentError -> {:error, close_port(state)}
  end

  defp notify_closed(state, reason), do: Kernel.send(state.owner, {self(), {:transport_closed, reason}})

  defp close_port(%{port: port} = state) do
    if Port.info(port), do: Port.close(port)
    state
  rescue
    ArgumentError -> state
  end
end
