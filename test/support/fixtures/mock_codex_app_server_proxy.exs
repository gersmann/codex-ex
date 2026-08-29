#!/usr/bin/env elixir

["app-server", "proxy", "--sock", socket_path] = System.argv()

{:ok, socket} =
  :gen_tcp.connect({:local, String.to_charlist(socket_path)}, 0, [:binary, active: false])

{:ok, stdout} = File.open("/dev/stdout", [:write, :binary])

pump_stdin = fn pump ->
  case IO.binread(:stdio, 1) do
    data when is_binary(data) ->
      :ok = :gen_tcp.send(socket, data)
      pump.(pump)

    _eof_or_error ->
      :gen_tcp.shutdown(socket, :write)
  end
end

spawn(fn -> pump_stdin.(pump_stdin) end)

pump_socket = fn pump ->
  case :gen_tcp.recv(socket, 0) do
    {:ok, data} ->
      :ok = IO.binwrite(stdout, data)
      pump.(pump)

    {:error, :closed} ->
      :ok
  end
end

pump_socket.(pump_socket)
