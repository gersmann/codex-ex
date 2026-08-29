defmodule CodexEx.AppServer.StdioTransportTest do
  use ExUnit.Case, async: false

  alias CodexEx.AppServer.StdioTransport
  alias Mint.WebSocket.Frame, as: WebSocketFrame

  @transport_timeout_ms 5_000

  setup do
    previous_codex_home = System.get_env("CODEX_HOME")

    on_exit(fn ->
      if previous_codex_home do
        System.put_env("CODEX_HOME", previous_codex_home)
      else
        System.delete_env("CODEX_HOME")
      end
    end)

    :ok
  end

  test "prefers the managed app-server proxy when its socket is reachable" do
    {codex_home, socket_path} = codex_home()
    System.put_env("CODEX_HOME", codex_home)
    parent = self()

    {:ok, listener} =
      :gen_tcp.listen(0, [
        :binary,
        {:active, false},
        {:ifaddr, {:local, String.to_charlist(socket_path)}}
      ])

    proxy =
      start_supervised!({
        Task,
        fn -> serve_proxy_connection(listener, parent) end
      })

    proxy_ref = Process.monitor(proxy)

    on_exit(fn ->
      :ok = :gen_tcp.close(listener)
      File.rm(socket_path)
    end)

    executable =
      Path.join([File.cwd!(), "test", "support", "fixtures", "mock_codex_app_server_proxy.exs"])

    assert {:ok, transport} = StdioTransport.open(executable: executable, owner: self())
    assert is_pid(transport)
    transport_ref = Process.monitor(transport)
    assert_receive :proxy_handshake_complete, @transport_timeout_ms
    assert_receive {^transport, {:transport_data, "early\n"}}, @transport_timeout_ms

    assert :ok = StdioTransport.send(transport, "request\n")
    assert_receive {:proxy_received, "request"}, @transport_timeout_ms
    assert_receive {^transport, {:transport_data, "response\n"}}, @transport_timeout_ms
    assert :ok = StdioTransport.close(transport)

    assert_receive {:DOWN, ^transport_ref, :process, ^transport, :normal},
                   @transport_timeout_ms

    assert_receive {:DOWN, ^proxy_ref, :process, ^proxy, :normal}, @transport_timeout_ms
  end

  test "falls back to a standalone app-server when the managed socket is unavailable" do
    {codex_home, _socket_path} = codex_home()
    System.put_env("CODEX_HOME", codex_home)

    assert {:ok, port} = StdioTransport.open(executable: "echo")
    assert_receive {^port, {:data, output}}, @transport_timeout_ms
    assert output == "app-server --enable realtime_conversation\n"
    assert_receive {^port, {:exit_status, 0}}, @transport_timeout_ms
  end

  test "proxy-only transport never starts a standalone app-server" do
    {codex_home, _socket_path} = codex_home()
    System.put_env("CODEX_HOME", codex_home)

    assert {:error, :proxy_unavailable} =
             StdioTransport.open(executable: "echo", proxy_only?: true)
  end

  defp codex_home do
    codex_home =
      Path.join(
        System.tmp_dir!(),
        "stdio-transport-#{System.unique_integer([:positive, :monotonic])}"
      )

    socket_dir = Path.join(codex_home, "app-server-control")
    File.mkdir_p!(socket_dir)

    on_exit(fn ->
      File.rmdir(socket_dir)
      File.rmdir(codex_home)
    end)

    {codex_home, Path.join(socket_dir, "app-server-control.sock")}
  end

  defp serve_proxy_connection(listener, parent) do
    {:ok, socket} = :gen_tcp.accept(listener)
    request = recv_until(socket, "\r\n\r\n", "")
    [_, key] = Regex.run(~r/Sec-WebSocket-Key: ([^\r]+)/, request)

    accept =
      :sha
      |> :crypto.hash(key <> "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
      |> Base.encode64()

    :ok =
      :gen_tcp.send(
        socket,
        "HTTP/1.1 101 Switching Protocols\r\n" <>
          "Upgrade: websocket\r\n" <>
          "Connection: Upgrade\r\n" <>
          "Sec-WebSocket-Accept: #{accept}\r\n\r\n" <>
          websocket_text_frame("early")
      )

    send(parent, :proxy_handshake_complete)
    payload = recv_text_frame(socket)
    send(parent, {:proxy_received, payload})
    :ok = :gen_tcp.send(socket, websocket_text_frame("response"))
    {:ok, _close_frame} = :gen_tcp.recv(socket, 0, 5_000)
  end

  defp websocket_text_frame(payload) when byte_size(payload) <= 125, do: <<0x81, byte_size(payload), payload::binary>>

  defp recv_until(socket, marker, buffer) do
    if String.contains?(buffer, marker) do
      buffer
    else
      {:ok, data} = :gen_tcp.recv(socket, 0, 5_000)
      recv_until(socket, marker, buffer <> data)
    end
  end

  defp recv_text_frame(socket) do
    <<0x81, masked_length>> = recv_exact(socket, 2, "")
    length = Bitwise.band(masked_length, 0x7F)
    mask = recv_exact(socket, 4, "")
    payload = recv_exact(socket, length, "")
    WebSocketFrame.apply_mask(payload, mask)
  end

  defp recv_exact(_socket, size, buffer) when byte_size(buffer) == size, do: buffer

  defp recv_exact(socket, size, buffer) do
    {:ok, data} = :gen_tcp.recv(socket, size - byte_size(buffer), 5_000)
    recv_exact(socket, size, buffer <> data)
  end
end
