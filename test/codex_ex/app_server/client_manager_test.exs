defmodule CodexEx.AppServer.ClientManagerTest do
  use ExUnit.Case, async: false

  alias CodexEx.AppServer.ClientManager
  alias CodexEx.AppServer.MockTransport

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
