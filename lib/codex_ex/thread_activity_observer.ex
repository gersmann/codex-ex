defmodule CodexEx.ThreadActivityObserver do
  @moduledoc """
  Keeps a shared local proxy client open and publishes its already-active threads.

  The observer broadcasts on the host PubSub and runs a host recovery hook, so the
  host owns its lifecycle: add it to your supervision tree after the PubSub and
  anything `:recover` depends on.

      {CodexEx.ThreadActivityObserver, recover: {MyApp.SessionRecovery, :recover, []}}

  Options:

    * `:recover` - optional `{module, function, args}` run after each reconciliation;
      must return `{:ok, term()}` or `{:error, term()}`. Errors are retried.
    * `:client_opts` - extra `ClientManager.get_client/1` options for the observed
      client (e.g. `:executable`); defaults to the local stdio app server.
    * `:name` - defaults to `CodexEx.ThreadActivityObserver`.
  """

  use GenServer

  alias CodexEx.AppServer.Client
  alias CodexEx.AppServer.ClientManager

  @client_opts [proxy_only?: true, broadcasts_thread_activity?: true]
  @retry_ms 5_000

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Re-publishes already-active threads. A no-op when the observer is not running."
  @spec reconcile(GenServer.server()) :: :ok
  def reconcile(server \\ __MODULE__), do: GenServer.cast(server, :reconcile)

  @impl true
  def init(opts) do
    state = %{
      recover: Keyword.get(opts, :recover),
      client_opts: Keyword.get(opts, :client_opts, []) ++ @client_opts,
      client: nil,
      task: nil,
      rerun?: false,
      retry_ref: nil
    }

    {:ok, state, {:continue, :reconcile}}
  end

  @impl true
  def handle_continue(:reconcile, state), do: {:noreply, reconcile_now(state)}

  @impl true
  def handle_cast(:reconcile, state), do: {:noreply, reconcile_now(state)}

  @impl true
  def handle_info(:retry, state), do: {:noreply, reconcile_now(%{state | retry_ref: nil})}

  def handle_info({ref, result}, %{task: %{ref: ref}} = state) do
    Process.demonitor(ref, [:flush])
    {:noreply, finish(%{state | task: nil}, result)}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %{task: %{ref: ref}} = state) do
    {:noreply, finish(%{state | task: nil}, {:error, reason})}
  end

  # The shared client died: reconnect and re-publish through its replacement.
  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{client: pid} = state) do
    {:noreply, reconcile_now(%{state | client: nil})}
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp reconcile_now(%{task: %Task{}} = state), do: %{state | rerun?: true}

  defp reconcile_now(state) do
    state = cancel_retry(state)

    case ensure_client(state) do
      {:ok, state} ->
        task = Task.Supervisor.async_nolink(CodexEx.TaskSupervisor, fn -> run(state.client, state.recover) end)
        %{state | task: task, rerun?: false}

      {:error, _reason} ->
        schedule_retry(state)
    end
  end

  defp finish(%{rerun?: true} = state, _result), do: reconcile_now(state)
  defp finish(state, :ok), do: state
  defp finish(state, _error), do: schedule_retry(state)

  defp ensure_client(%{client: pid} = state) when is_pid(pid), do: {:ok, state}

  defp ensure_client(state) do
    with {:ok, pid} <- ClientManager.get_client(state.client_opts) do
      Process.monitor(pid)
      {:ok, %{state | client: pid}}
    end
  end

  defp schedule_retry(%{retry_ref: ref} = state) when is_reference(ref), do: state
  defp schedule_retry(state), do: %{state | retry_ref: Process.send_after(self(), :retry, @retry_ms)}

  defp cancel_retry(%{retry_ref: nil} = state), do: state

  defp cancel_retry(%{retry_ref: ref} = state) do
    Process.cancel_timer(ref)
    %{state | retry_ref: nil}
  end

  # Recovery runs even when the broadcast fails, so one side's outage does not
  # starve the other; either error schedules a retry of both.
  defp run(client, recover) do
    case {Client.broadcast_active_threads(client), run_recover(recover)} do
      {:ok, {:ok, _summary}} -> :ok
      {{:error, _reason} = error, _recovered} -> error
      {_broadcast, {:error, _reason} = error} -> error
    end
  end

  defp run_recover(nil), do: {:ok, :no_recovery_hook}
  defp run_recover({module, function, args}), do: apply(module, function, args)
end
