defmodule CodexEx.ThreadActivityObserverTest do
  use ExUnit.Case, async: false

  alias CodexEx.AppServer.Client
  alias CodexEx.AppServer.ClientManager
  alias CodexEx.AppServer.MockTransport
  alias CodexEx.AppServer.ThreadSnapshot
  alias CodexEx.ThreadActivityObserver

  setup do
    mock = start_supervised!(MockTransport)

    client_opts = [
      transport: MockTransport,
      mock_pid: mock,
      args: ["observer-test", Integer.to_string(System.unique_integer([:positive]))]
    ]

    {:ok, mock: mock, client_opts: client_opts}
  end

  test "retries an already-active thread reconciliation after a transient failure", %{
    mock: mock,
    client_opts: client_opts
  } do
    assert {:ok, client} = ClientManager.get_client(client_opts)
    assert {:ok, thread} = Client.start_thread(client)
    thread_id = thread.id

    :sys.replace_state(mock, fn state ->
      update_in(state, [:threads, thread_id], &Map.put(&1, "status", "active"))
    end)

    assert :ok = Client.subscribe_thread_activity()
    assert :ok = MockTransport.configure(mock, notify: self(), list_threads_error: true)
    observer = start_observer(client_opts: client_opts)
    assert_receive {:mock_thread_list, _params}, 500

    retry_ref = await_state(observer, & &1.retry_ref)
    observed = :sys.get_state(observer).client
    refute_receive {:codex_thread_discovered, {^observed, nil, nil}, %ThreadSnapshot{id: ^thread_id}}, 50

    assert is_integer(Process.cancel_timer(retry_ref))
    send(observer, :retry)

    assert_receive {:mock_thread_list, _params}, 500
    assert_receive {:codex_thread_discovered, {^observed, nil, nil}, %ThreadSnapshot{id: ^thread_id}}, 500
  end

  test "coalesces reconciliation, follows a replaced client and retries a crashed task", %{
    client_opts: client_opts
  } do
    observer = start_observer(client_opts: client_opts, recover: {__MODULE__, :blocked_recovery, [self()]})
    assert_receive {:recovering, first}, 1_000
    first_client = :sys.get_state(observer).client

    for _ <- 1..10, do: ThreadActivityObserver.reconcile(observer)
    :ok = GenServer.stop(first_client)
    assert await_state(observer, &(&1.rerun? and is_nil(&1.client)))
    refute_receive {:recovering, _}, 50

    send(first, :release)
    assert_receive {:recovering, second}, 1_000
    refute first == second
    second_client = :sys.get_state(observer).client
    assert is_pid(second_client) and second_client != first_client

    Process.exit(second, :kill)
    retry_ref = await_state(observer, & &1.retry_ref)
    Process.cancel_timer(retry_ref)
    send(observer, :retry)
    assert_receive {:recovering, third}, 1_000
    send(third, :release)

    assert await_state(observer, &(is_nil(&1.task) and is_nil(&1.retry_ref)))
  end

  def blocked_recovery(test) do
    send(test, {:recovering, self()})

    receive do
      :release -> {:ok, :recovered}
    end
  end

  defp start_observer(opts) do
    name = :"observer_#{System.unique_integer([:positive])}"
    observer = start_supervised!({ThreadActivityObserver, Keyword.put(opts, :name, name)})

    args = opts |> Keyword.fetch!(:client_opts) |> Keyword.fetch!(:args)

    on_exit(fn ->
      for {key, pid} <- ClientManager.clients(),
          elem(key, 5) == {:ok, args},
          do: DynamicSupervisor.terminate_child(CodexEx.ClientSupervisor, pid)
    end)

    observer
  end

  defp await_state(server, check, attempts \\ 100)

  defp await_state(server, check, attempts) when attempts > 0 do
    case check.(:sys.get_state(server)) do
      result when result in [nil, false] ->
        Process.sleep(5)
        await_state(server, check, attempts - 1)

      result ->
        result
    end
  end

  defp await_state(_server, _check, 0), do: flunk("observer did not reach expected state")
end
