defmodule CodexEx.AppServer.StdioTransport do
  @moduledoc false

  @behaviour CodexEx.AppServer.Transport

  alias CodexEx.AppServer.StdioProxyTransport

  require Logger

  @direct_args ["app-server", "--enable", "realtime_conversation"]

  @type open_error ::
          {:executable_not_found, binary()}
          | {:invalid_args, term()}
          | {:port_open_failed, binary()}
          | :proxy_unavailable
          | {:proxy_unavailable, term()}

  @spec open(keyword()) :: {:ok, port() | pid()} | {:error, open_error()}
  def open(opts \\ []) do
    with {:ok, executable} <- resolve_executable(Keyword.get(opts, :executable)) do
      open_transport(executable, opts)
    end
  end

  def send(transport, payload) when is_pid(transport) and is_binary(payload),
    do: StdioProxyTransport.send(transport, payload)

  @spec send(port() | pid(), binary()) :: :ok | {:error, :closed}
  def send(port, payload) when is_port(port) and is_binary(payload) do
    true = Port.command(port, payload)
    :ok
  rescue
    ArgumentError -> {:error, :closed}
  end

  def close(transport) when is_pid(transport), do: StdioProxyTransport.close(transport)

  @spec close(port() | pid()) :: :ok
  def close(port) when is_port(port) do
    _ = Port.close(port)
    :ok
  rescue
    ArgumentError -> :ok
  end

  @spec normalize_message(term(), term()) ::
          CodexEx.AppServer.Transport.normalized_message()
  def normalize_message({port, {:data, data}}, port) when is_binary(data), do: {:data, data}
  def normalize_message({port, {:exit_status, exit_status}}, port), do: {:closed, exit_status}

  def normalize_message(message, transport) when is_pid(transport),
    do: StdioProxyTransport.normalize_message(message, transport)

  def normalize_message(_message, _port), do: :ignore

  defp open_transport(executable, opts) do
    case Keyword.fetch(opts, :args) do
      {:ok, args} ->
        with {:ok, args} <- normalize_args(args), do: open_port(executable, args)

      :error ->
        open_default_transport(executable, opts)
    end
  end

  defp open_default_transport(executable, opts) do
    socket_path = app_server_socket_path()
    proxy_only? = Keyword.get(opts, :proxy_only?, false)

    if File.exists?(socket_path) do
      proxy_opts =
        opts
        |> Keyword.put(:executable, executable)
        |> Keyword.put(:socket_path, socket_path)

      case StdioProxyTransport.open(proxy_opts) do
        {:ok, _transport} = ok ->
          ok

        {:error, reason} ->
          if proxy_only? do
            {:error, {:proxy_unavailable, reason}}
          else
            Logger.warning("Codex app-server proxy unavailable; starting standalone: #{inspect(reason)}")

            open_direct(executable)
          end
      end
    else
      if proxy_only?, do: {:error, :proxy_unavailable}, else: open_direct(executable)
    end
  end

  defp open_direct(executable) do
    with {:ok, args} <- normalize_args(@direct_args), do: open_port(executable, args)
  end

  defp app_server_socket_path do
    codex_home = System.get_env("CODEX_HOME") || Path.join(System.user_home!(), ".codex")
    Path.join([codex_home, "app-server-control", "app-server-control.sock"])
  end

  defp resolve_executable(nil) do
    case System.find_executable("codex") do
      nil -> {:error, {:executable_not_found, "codex"}}
      path -> {:ok, path}
    end
  end

  defp resolve_executable(executable) when is_binary(executable) and executable != "" do
    case System.find_executable(executable) do
      nil ->
        if File.regular?(executable) do
          {:ok, executable}
        else
          {:error, {:executable_not_found, executable}}
        end

      path ->
        {:ok, path}
    end
  end

  defp resolve_executable(executable), do: {:error, {:executable_not_found, inspect(executable)}}

  defp normalize_args(args) when is_list(args) do
    if Enum.all?(args, &is_binary/1) do
      {:ok, Enum.map(args, &String.to_charlist/1)}
    else
      {:error, {:invalid_args, args}}
    end
  end

  defp normalize_args(args), do: {:error, {:invalid_args, args}}

  defp open_port(executable, args) do
    port_options = [
      :binary,
      :exit_status,
      :use_stdio,
      :hide,
      {:args, args}
    ]

    case Port.open({:spawn_executable, executable}, port_options) do
      port when is_port(port) ->
        {:ok, port}
    end
  rescue
    error in ArgumentError ->
      {:error, {:port_open_failed, Exception.message(error)}}
  end
end
