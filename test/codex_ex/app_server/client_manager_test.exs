defmodule CodexEx.AppServer.ClientManagerTest do
  use ExUnit.Case, async: false

  alias CodexEx.AppServer.Client
  alias CodexEx.AppServer.ClientManager
  alias CodexEx.AppServer.MockTransport

  @task_shutdown_timeout_ms 5_000

  setup do
    mock = start_supervised!(MockTransport)

    opts = [
      transport: MockTransport,
      mock_pid: mock,
      args: ["client-manager-test", Integer.to_string(System.unique_integer([:positive]))]
    ]

    {:ok, mock: mock, opts: opts}
  end

  test "reuses a live client while it is unresponsive", %{opts: opts} do
    assert {:ok, client} = ClientManager.get_client(opts)
    on_exit(fn -> stop_if_alive(client) end)
    :ok = :sys.suspend(client)

    try do
      assert {:ok, ^client} = ClientManager.get_client(opts)
    after
      :ok = :sys.resume(client)
    end
  end

  test "replaces a dead client and ignores its stale monitor", %{opts: opts} do
    assert {:ok, first_client} = ClientManager.get_client(opts)

    manager_state = :sys.get_state(ClientManager)

    {first_ref, _key} =
      Enum.find(manager_state.refs, fn {_ref, key} ->
        manager_state.clients[key] == first_client
      end)

    :ok = GenServer.stop(first_client)

    assert {:ok, second_client} = ClientManager.get_client(opts)
    on_exit(fn -> stop_if_alive(second_client) end)
    refute first_client == second_client

    send(ClientManager, {:DOWN, first_ref, :process, first_client, :normal})
    _ = :sys.get_state(ClientManager)

    assert {:ok, ^second_client} = ClientManager.get_client(opts)
  end

  test "does not reuse an implicit launcher for explicit direct args", %{opts: opts} do
    implicit_opts = Keyword.delete(opts, :args)

    assert {:ok, implicit_client} = ClientManager.get_client(implicit_opts)

    assert {:ok, explicit_nil_client} =
             ClientManager.get_client(Keyword.put(implicit_opts, :args, nil))

    assert {:ok, explicit_client} =
             ClientManager.get_client(
               Keyword.put(implicit_opts, :args, [
                 "app-server",
                 "--enable",
                 "realtime_conversation"
               ])
             )

    refute implicit_client == explicit_nil_client
    refute implicit_client == explicit_client
  end

  test "retries an already-active thread reconciliation after a transient failure", %{
    mock: mock,
    opts: opts
  } do
    assert {:ok, client} = ClientManager.get_client(opts)
    assert {:ok, thread} = Client.start_thread(client)
    thread_id = thread.id

    :sys.replace_state(mock, fn state ->
      update_in(state, [:threads, thread_id], &Map.put(&1, "status", "active"))
    end)

    observer_key = client_key(client)
    previous_observer_key = :sys.get_state(ClientManager).thread_activity_observer_key

    on_exit(fn ->
      reset_manager(previous_observer_key)
      await_codex_tasks()
      _ = :sys.get_state(ClientManager)
      reset_manager(previous_observer_key)
    end)

    :sys.replace_state(ClientManager, fn state ->
      %{state | thread_activity_observer_key: observer_key}
    end)

    assert :ok = Client.subscribe_thread_activity()
    assert :ok = MockTransport.configure(mock, notify: self(), list_threads_error: true)
    assert :ok = ClientManager.reconcile_thread_activity()
    assert_receive {:mock_thread_list, _params}, 500

    retry_ref =
      await_manager_state(fn state ->
        if is_reference(state.thread_activity_retry_ref),
          do: state.thread_activity_retry_ref
      end)

    refute_receive {:codex_thread_active, {^client, nil, nil}, ^thread_id}, 50

    assert is_integer(Process.cancel_timer(retry_ref))
    send(ClientManager, :retry_thread_activity_observer)

    assert_receive {:mock_thread_list, _params}, 500
    assert_receive {:codex_thread_active, {^client, nil, nil}, ^thread_id}, 500
  end

  defp client_key(client) when is_pid(client) do
    ClientManager
    |> :sys.get_state()
    |> Map.fetch!(:clients)
    |> Enum.find_value(fn {key, pid} -> if pid == client, do: key end)
  end

  defp await_manager_state(check, attempts \\ 100)

  defp await_manager_state(check, attempts) when attempts > 0 do
    case check.(:sys.get_state(ClientManager)) do
      nil ->
        receive do
        after
          5 -> await_manager_state(check, attempts - 1)
        end

      result ->
        result
    end
  end

  defp await_manager_state(_check, 0), do: flunk("ClientManager did not reach expected state")

  defp stop_if_alive(pid) do
    if Process.alive?(pid), do: GenServer.stop(pid)
  end

  defp reset_manager(observer_key) do
    :sys.replace_state(ClientManager, fn state ->
      if is_reference(state.thread_activity_retry_ref) do
        Process.cancel_timer(state.thread_activity_retry_ref)
      end

      %{
        state
        | thread_activity_observer_key: observer_key,
          thread_activity_retry_ref: nil
      }
    end)
  end

  defp await_codex_tasks do
    CodexEx.TaskSupervisor
    |> Task.Supervisor.children()
    |> Enum.each(fn task ->
      ref = Process.monitor(task)

      assert_receive {:DOWN, ^ref, :process, ^task, _reason}, @task_shutdown_timeout_ms
    end)
  end
end
