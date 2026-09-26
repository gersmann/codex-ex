defmodule CodexEx.AppServer.ClientManager do
  @moduledoc """
  Shares long-lived Codex app-server clients across callers with the same launcher config.

  The stdio transport spawns an OS `codex app-server` process, so reusing clients by
  launcher config prevents one subprocess per session page or sync call.

  Clients register under their launcher key in `CodexEx.ClientRegistry`, so the
  registry — not this process — is the source of truth for which clients exist.
  This process only monitors clients to reconcile remote thread activity when one
  dies, and rebuilds its monitors from the registry when it restarts.
  """

  use GenServer

  alias CodexEx.AppServer.Client

  @registry CodexEx.ClientRegistry

  @type client_key ::
          {:client, transport :: term(), runner_id :: term(), url :: term(), executable :: term(), args :: term(),
           workspace_id :: term(), workspace_root :: term(), initialize_params :: term(), legacy_strict_protocol :: false,
           proxy_only :: boolean(), broadcasts_thread_activity :: boolean()}
  @type get_client_result :: {:ok, Client.t()} | {:error, term()}

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
  end

  @spec get_client(keyword()) :: get_client_result()
  def get_client(opts) when is_list(opts) do
    opts = normalize_client_opts(opts)
    key = shared_client_key(opts)

    case Registry.lookup(@registry, key) do
      [{pid, _value}] -> if Process.alive?(pid), do: {:ok, pid}, else: start_client(key, opts)
      [] -> start_client(key, opts)
    end
  end

  @doc "Lists registered shared clients as `{key, pid}` pairs."
  @spec clients() :: [{client_key(), pid()}]
  def clients do
    Registry.select(@registry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

  @spec remote_thread_activity_client?(pid(), binary(), binary()) :: boolean()
  def remote_thread_activity_client?(client, runner_id, workspace_id)
      when is_pid(client) and is_binary(runner_id) and is_binary(workspace_id) do
    @registry
    |> Registry.keys(client)
    |> Enum.any?(fn
      {:client, transport, ^runner_id, _url, _executable, _args, ^workspace_id, _workspace_root, _initialize_params,
       _strict_protocol, _proxy_only, true} ->
        remote_transport?(transport)

      _other ->
        false
    end)
  end

  @impl true
  def init(:ok) do
    {:ok, Enum.reduce(clients(), %{}, fn {key, pid}, monitored -> monitor(monitored, key, pid) end)}
  end

  @impl true
  def handle_cast({:monitor, key, pid}, monitored), do: {:noreply, monitor(monitored, key, pid)}

  @impl true
  def handle_info(
        {:DOWN, _ref, :process, pid,
         {:shutdown, {:transport_closed, {:remote_session_closed, "encoded codex session event is " <> _}}}},
        monitored
      ) do
    # Automatically reopening after an oversized response can reproduce the same error.
    # Explicit reconciliation or a new connection can retry after the cause changes.
    {:noreply, Map.delete(monitored, pid)}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, monitored) do
    case Map.pop(monitored, pid) do
      {nil, monitored} ->
        {:noreply, monitored}

      {key, monitored} ->
        _ = reconcile_remote_thread_activity(key)
        {:noreply, monitored}
    end
  end

  def handle_info(_message, monitored), do: {:noreply, monitored}

  # Concurrent starts for one key race on the registry name: the loser exits before
  # `init`, so no duplicate app-server is spawned, and its caller gets the winner.
  defp start_client(key, opts) do
    case DynamicSupervisor.start_child(CodexEx.ClientSupervisor, shared_client_child_spec(key, opts)) do
      {:ok, pid} ->
        # A cast dropped while this process restarts is covered by `init/1`'s registry scan.
        GenServer.cast(__MODULE__, {:monitor, key, pid})
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:error, reason} ->
        {:error, reason}

      other ->
        {:error, {:shared_client_start_failed, other}}
    end
  end

  defp monitor(monitored, key, pid) do
    if Map.has_key?(monitored, pid) do
      monitored
    else
      Process.monitor(pid)
      Map.put(monitored, pid, key)
    end
  end

  defp normalize_client_opts(opts) do
    if remote_transport?(Keyword.get(opts, :transport)) do
      Keyword.put(opts, :broadcasts_thread_activity?, true)
    else
      opts
    end
  end

  # A transport is "remote" when its client sessions outlive this node —
  # signalled by the optional `Transport.remote_transport?/0` callback.
  defp remote_transport?(transport) when is_atom(transport) and not is_nil(transport) do
    Code.ensure_loaded?(transport) and function_exported?(transport, :remote_transport?, 0) and
      transport.remote_transport?()
  end

  defp remote_transport?(_transport), do: false

  defp reconcile_remote_thread_activity(
         {:client, transport, runner_id, _url, _executable, _args, workspace_id, _workspace_root, _initialize_params,
          _strict_protocol, _proxy_only, _broadcasts_thread_activity}
       )
       when is_binary(runner_id) and is_binary(workspace_id) do
    if remote_transport?(transport) and
         function_exported?(transport, :reconcile_thread_activity, 2) do
      transport.reconcile_thread_activity(runner_id, workspace_id)
    else
      :ok
    end
  end

  defp reconcile_remote_thread_activity(_key), do: :ok

  defp shared_client_child_spec(key, opts) do
    %{
      id: {Client, key},
      start: {Client, :start_link, [shared_client_opts(key, opts)]},
      restart: :temporary,
      type: :worker
    }
  end

  defp shared_client_opts(key, opts) do
    opts
    |> Keyword.put_new(:transport, :stdio)
    |> Keyword.put(:name, {:via, Registry, {@registry, key}})
    |> maybe_put_remote_transport_id(key)
  end

  defp maybe_put_remote_transport_id(opts, key) do
    if remote_transport?(Keyword.get(opts, :transport)) do
      digest =
        key
        |> remote_transport_identity()
        |> :erlang.term_to_binary([:deterministic])
        |> then(&:crypto.hash(:sha256, &1))
        |> Base.url_encode64(padding: false)

      Keyword.put(opts, :transport_id, "client-#{digest}")
    else
      opts
    end
  end

  # Transport ids outlive deploys on remote daemons. Keep local capability
  # flags out of the identity so adding or changing them cannot orphan a
  # daemon's retained app-server session.
  defp remote_transport_identity(
         {:client, transport, runner_id, url, executable, args, workspace_id, workspace_root, initialize_params, false,
          _proxy_only, _broadcasts_thread_activity}
       ) do
    {:client, stable_transport_identity(transport), runner_id, url, executable, args, workspace_id, workspace_root,
     initialize_params, false}
  end

  defp stable_transport_identity(transport) do
    if function_exported?(transport, :stable_identity, 0), do: transport.stable_identity(), else: transport
  end

  defp shared_client_key(opts) when is_list(opts) do
    transport = Keyword.get(opts, :transport, :stdio)

    {:client, transport, Keyword.get(opts, :runner_id), Keyword.get(opts, :url), Keyword.get(opts, :executable),
     shared_args_identity(opts, transport), Keyword.get(opts, :workspace_id), Keyword.get(opts, :workspace_root),
     Client.build_initialize_params(Keyword.get(opts, :initialize_params, %{})), false,
     Keyword.get(opts, :proxy_only?, false), Keyword.get(opts, :broadcasts_thread_activity?, false)}
  end

  # Keep remote daemon transport ids stable across this local-only identity change.
  defp shared_args_identity(opts, transport) do
    if remote_transport?(transport) do
      Keyword.get(opts, :args, ["app-server", "--enable", "realtime_conversation"])
    else
      Keyword.fetch(opts, :args)
    end
  end
end
