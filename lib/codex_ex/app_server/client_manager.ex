defmodule CodexEx.AppServer.ClientManager do
  @moduledoc """
  Shares long-lived Codex app-server clients across callers with the same launcher config.

  The stdio transport spawns an OS `codex app-server` process, so reusing clients by
  launcher config prevents one subprocess per session page or sync call.
  """

  use GenServer

  alias CodexEx.AppServer.Client

  @manager_call_timeout_ms 30_000
  @thread_activity_observer_opts [proxy_only?: true, broadcasts_thread_activity?: true]
  @thread_activity_retry_ms 5_000

  @type client_key ::
          {:client, transport :: term(), runner_id :: term(), url :: term(), executable :: term(), args :: term(),
           workspace_id :: term(), workspace_root :: term(), initialize_params :: term(), strict_protocol :: boolean(),
           proxy_only :: boolean(), broadcasts_thread_activity :: boolean()}
  @type get_client_result :: {:ok, Client.t()} | {:error, term()}

  @type state :: %{
          clients: %{client_key() => pid()},
          refs: %{reference() => client_key()},
          thread_activity_observer_key: client_key() | nil,
          thread_activity_retry_ref: reference() | nil
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
  end

  @spec get_client(keyword()) :: get_client_result()
  def get_client(opts) when is_list(opts) do
    __MODULE__
    |> safe_manager_call({:get_client, opts})
    |> normalize_get_client_reply()
  end

  @spec remote_thread_activity_client?(pid(), binary(), binary()) :: boolean()
  def remote_thread_activity_client?(client, runner_id, workspace_id)
      when is_pid(client) and is_binary(runner_id) and is_binary(workspace_id) do
    case safe_manager_call(
           __MODULE__,
           {:remote_thread_activity_client?, client, runner_id, workspace_id}
         ) do
      true -> true
      _other -> false
    end
  end

  @doc "Publishes already-active threads through the shared local observer."
  @spec reconcile_thread_activity() :: :ok
  def reconcile_thread_activity do
    GenServer.cast(__MODULE__, :reconcile_thread_activity)
  end

  @impl true
  def init(:ok) do
    observer_key =
      if Application.get_env(:codex_ex, :thread_activity_observer_enabled, false),
        do: shared_client_key(@thread_activity_observer_opts)

    state = %{
      clients: %{},
      refs: %{},
      thread_activity_observer_key: observer_key,
      thread_activity_retry_ref: nil
    }

    if observer_key,
      do: {:ok, state, {:continue, :start_thread_activity_observer}},
      else: {:ok, state}
  end

  @impl true
  def handle_continue(:start_thread_activity_observer, state) do
    state = ensure_thread_activity_observer(state)
    _ = start_thread_activity_reconciliation(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:reconcile_thread_activity, state) do
    state = ensure_thread_activity_observer(state)
    _ = start_thread_activity_reconciliation(state)
    {:noreply, state}
  end

  @impl true
  def handle_call({:get_client, opts}, _from, state) do
    opts = normalize_client_opts(opts)

    case normalize_key(opts) do
      {:ok, key} ->
        case Map.fetch(state.clients, key) do
          {:ok, pid} when is_pid(pid) ->
            if Process.alive?(pid) do
              {:reply, {:ok, pid}, state}
            else
              start_shared_client(state, key, opts)
            end

          _other ->
            start_shared_client(state, key, opts)
        end

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:remote_thread_activity_client?, client, runner_id, workspace_id}, _from, state) do
    matched? =
      Enum.any?(state.clients, fn
        {{:client, transport, ^runner_id, _url, _executable, _args, ^workspace_id, _workspace_root, _initialize_params,
          _strict_protocol, _proxy_only, true}, ^client} ->
          remote_transport?(transport)

        _other ->
          false
      end)

    {:reply, matched?, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    case Map.pop(state.refs, ref) do
      {nil, refs} ->
        {:noreply, %{state | refs: refs}}

      {key, refs} ->
        state = %{state | refs: refs, clients: Map.delete(state.clients, key)}
        _ = reconcile_remote_thread_activity(key)

        {:noreply, maybe_schedule_thread_activity_retry(state, key)}
    end
  end

  def handle_info(:retry_thread_activity_observer, state) do
    state = cancel_thread_activity_retry(state)
    state = ensure_thread_activity_observer(state)
    _ = start_thread_activity_reconciliation(state)
    {:noreply, state}
  end

  def handle_info({:thread_activity_reconciliation_finished, :ok}, state), do: {:noreply, state}

  def handle_info({:thread_activity_reconciliation_finished, {:error, _reason}}, state),
    do: {:noreply, schedule_thread_activity_retry(state)}

  def handle_info(_message, state), do: {:noreply, state}

  defp start_shared_client(state, key, opts) do
    case do_start_shared_client(state, key, opts) do
      {:ok, pid, state} -> {:reply, {:ok, pid}, state}
      {:error, reason, state} -> {:reply, {:error, reason}, state}
    end
  end

  defp do_start_shared_client(state, key, opts) do
    state = drop_key(state, key)

    case DynamicSupervisor.start_child(
           CodexEx.ClientSupervisor,
           shared_client_child_spec(key, opts)
         ) do
      {:ok, pid} when is_pid(pid) ->
        ref = Process.monitor(pid)

        state = %{
          state
          | clients: Map.put(state.clients, key, pid),
            refs: Map.put(state.refs, ref, key)
        }

        {:ok, pid, state}

      {:error, reason} ->
        {:error, reason, state}

      other ->
        {:error, {:shared_client_start_failed, other}, state}
    end
  end

  defp ensure_thread_activity_observer(%{thread_activity_observer_key: nil} = state), do: state

  defp ensure_thread_activity_observer(state) do
    key = state.thread_activity_observer_key

    case Map.get(state.clients, key) do
      pid when is_pid(pid) ->
        state

      _missing ->
        case do_start_shared_client(state, key, @thread_activity_observer_opts) do
          {:ok, _pid, state} -> state
          {:error, _reason, state} -> maybe_schedule_thread_activity_retry(state, key)
        end
    end
  end

  defp maybe_schedule_thread_activity_retry(%{thread_activity_observer_key: key} = state, key) when not is_nil(key) do
    schedule_thread_activity_retry(state)
  end

  defp maybe_schedule_thread_activity_retry(state, _key), do: state

  defp schedule_thread_activity_retry(%{thread_activity_retry_ref: ref} = state) when is_reference(ref), do: state

  defp schedule_thread_activity_retry(state) do
    ref = Process.send_after(self(), :retry_thread_activity_observer, @thread_activity_retry_ms)
    %{state | thread_activity_retry_ref: ref}
  end

  defp cancel_thread_activity_retry(%{thread_activity_retry_ref: nil} = state), do: state

  defp cancel_thread_activity_retry(%{thread_activity_retry_ref: ref} = state) do
    _ = Process.cancel_timer(ref)
    %{state | thread_activity_retry_ref: nil}
  end

  defp start_thread_activity_reconciliation(%{thread_activity_observer_key: key} = state) when not is_nil(key) do
    case Map.get(state.clients, key) do
      client when is_pid(client) ->
        manager = self()

        case Task.Supervisor.start_child(CodexEx.TaskSupervisor, fn ->
               send(
                 manager,
                 {:thread_activity_reconciliation_finished, reconcile_local_thread_activity(client)}
               )
             end) do
          {:ok, _pid} ->
            :ok

          {:error, reason} ->
            send(manager, {:thread_activity_reconciliation_finished, {:error, reason}})
        end

      _missing ->
        :ok
    end
  end

  defp start_thread_activity_reconciliation(_state), do: :ok

  defp reconcile_local_thread_activity(client) do
    case {
      Client.broadcast_active_threads(client),
      run_thread_activity_recovery()
    } do
      {:ok, {:ok, _summary}} -> :ok
      {{:error, _reason} = error, _recovery_result} -> error
      {_thread_result, {:error, _reason} = error} -> error
    end
  end

  # Host applications can hook local thread-activity reconciliation (for
  # example to recover persisted sessions) via
  # `config :codex_ex, thread_activity_recovery: {module, function, args}`.
  # The hook must return `{:ok, term()}` or `{:error, term()}`.
  defp run_thread_activity_recovery do
    case Application.get_env(:codex_ex, :thread_activity_recovery) do
      {module, function, args} ->
        # The hook lives in the host application, which may still be booting;
        # surface failures as errors so reconciliation retries instead of dying.
        try do
          apply(module, function, args)
        rescue
          error -> {:error, error}
        catch
          :exit, reason -> {:error, {:exit, reason}}
        end

      nil ->
        {:ok, :no_recovery_hook}
    end
  end

  defp drop_key(state, key) do
    refs =
      state.refs
      |> Enum.reject(fn {_ref, ref_key} -> ref_key == key end)
      |> Map.new()

    %{state | clients: Map.delete(state.clients, key), refs: refs}
  end

  defp normalize_key(opts) when is_list(opts) do
    if Keyword.get(opts, :request_handler) do
      {:error, {:unsupported_shared_client_option, :request_handler}}
    else
      {:ok, shared_client_key(opts)}
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
         {:client, transport, runner_id, _url, _executable, _args, _workspace_id, _workspace_root, _initialize_params,
          _strict_protocol, _proxy_only, _broadcasts_thread_activity}
       )
       when is_binary(runner_id) do
    if remote_transport?(transport) and
         function_exported?(transport, :reconcile_thread_activity, 1) do
      transport.reconcile_thread_activity(runner_id)
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
    |> Keyword.drop([:name, :request_handler])
    |> Keyword.put_new(:transport, :stdio)
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
         {:client, transport, runner_id, url, executable, args, workspace_id, workspace_root, initialize_params,
          strict_protocol, _proxy_only, _broadcasts_thread_activity}
       ) do
    {:client, transport, runner_id, url, executable, args, workspace_id, workspace_root, initialize_params,
     strict_protocol}
  end

  defp shared_client_key(opts) when is_list(opts) do
    transport = Keyword.get(opts, :transport, :stdio)

    {:client, transport, Keyword.get(opts, :runner_id), Keyword.get(opts, :url), Keyword.get(opts, :executable),
     shared_args_identity(opts, transport), Keyword.get(opts, :workspace_id), Keyword.get(opts, :workspace_root),
     Client.build_initialize_params(Keyword.get(opts, :initialize_params, %{})),
     Keyword.get(opts, :strict_protocol, false), Keyword.get(opts, :proxy_only?, false),
     Keyword.get(opts, :broadcasts_thread_activity?, false)}
  end

  # Keep remote daemon transport ids stable across this local-only identity change.
  defp shared_args_identity(opts, transport) do
    if remote_transport?(transport) do
      Keyword.get(opts, :args, ["app-server", "--enable", "realtime_conversation"])
    else
      Keyword.fetch(opts, :args)
    end
  end

  defp normalize_get_client_reply({:ok, pid}) when is_pid(pid), do: {:ok, pid}
  defp normalize_get_client_reply({:error, _reason} = error), do: error
  defp normalize_get_client_reply(other), do: {:error, {:unexpected_client_manager_reply, other}}

  defp safe_manager_call(server, message) do
    GenServer.call(server, message, @manager_call_timeout_ms)
  catch
    :exit, reason -> {:error, {:shared_client_manager_call_failed, reason}}
  end
end
