defmodule CodexEx.AppServer.ClientManagerTest do
  use ExUnit.Case, async: false

  alias CodexEx.AppServer.ClientManager
  alias CodexEx.AppServer.MockTransport

  defmodule RemoteTransport do
    @moduledoc false

    @spec remote_transport?() :: true
    def remote_transport?, do: true

    @spec reconcile_thread_activity(binary(), binary()) :: :ok
    def reconcile_thread_activity(runner_id, workspace_id) do
      Kernel.send(self(), {:reconcile_thread_activity, runner_id, workspace_id})
      :ok
    end
  end

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
    :ok = GenServer.stop(first_client)

    assert {:ok, second_client} = ClientManager.get_client(opts)
    on_exit(fn -> stop_if_alive(second_client) end)
    refute first_client == second_client

    send(ClientManager, {:DOWN, make_ref(), :process, first_client, :normal})
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

  test "client death repairs only its runner and workspace" do
    key = {:client, RemoteTransport, "runner", nil, nil, nil, "workspace", nil, nil, false, false, true}
    monitored = %{self() => key}
    down = {:DOWN, make_ref(), :process, self(), :normal}

    assert {:noreply, %{}} = ClientManager.handle_info(down, monitored)
    assert_received {:reconcile_thread_activity, "runner", "workspace"}
    assert {:noreply, %{}} = ClientManager.handle_info(down, %{})
    refute_received {:reconcile_thread_activity, _, _}
  end

  test "oversized terminal does not automatically reopen the failed client" do
    key = {:client, RemoteTransport, "runner", nil, nil, nil, "workspace", nil, nil, false, false, true}
    reason = {:remote_session_closed, "encoded codex session event is 16777217 bytes; limit is 16777216"}
    down = {:DOWN, make_ref(), :process, self(), {:shutdown, {:transport_closed, reason}}}

    assert {:noreply, %{}} = ClientManager.handle_info(down, %{self() => key})
    refute_received {:reconcile_thread_activity, _, _}
  end

  test "concurrent requests for one key share a single client", %{opts: opts} do
    results =
      1..10
      |> Enum.map(fn _ -> Task.async(fn -> ClientManager.get_client(opts) end) end)
      |> Task.await_many()

    assert [{:ok, client}] = Enum.uniq(results)
    on_exit(fn -> stop_if_alive(client) end)
  end

  test "a restarted manager rebuilds its monitors from the registry", %{opts: opts} do
    assert {:ok, client} = ClientManager.get_client(opts)
    on_exit(fn -> stop_if_alive(client) end)

    # Killing the real singleton would count against the application's restart
    # intensity, so exercise the restart path through `init/1` directly.
    assert {:ok, monitored} = ClientManager.init(:ok)
    assert {:client, MockTransport, _, _, _, _, _, _, _, _, _, _} = monitored[client]
    assert {:ok, ^client} = ClientManager.get_client(opts)
  end

  defp stop_if_alive(pid) do
    if Process.alive?(pid), do: GenServer.stop(pid)
  end
end
