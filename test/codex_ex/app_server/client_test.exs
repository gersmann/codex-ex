defmodule CodexEx.AppServer.ClientTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.Client
  alias CodexEx.AppServer.Message
  alias CodexEx.AppServer.MockTransport
  alias CodexEx.AppServer.Protocol.Generated.Shared.ApplyPatchApprovalParams
  alias CodexEx.AppServer.Protocol.Generated.Shared.ExecCommandApprovalParams
  alias CodexEx.AppServer.Protocol.Generated.Shared.McpServerElicitationRequestResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerNotification
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerRequest
  alias CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputParams
  alias CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputResponse
  alias CodexEx.AppServer.Protocol.Generated.V1.InitializeResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ConfigReadResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ConfigWriteResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.HooksListResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.McpResourceReadResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.McpServerToolCallResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.SkillsListResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadUnsubscribeResponse
  alias CodexEx.AppServer.Protocol.GenericNotification
  alias CodexEx.AppServer.Thread
  alias CodexEx.AppServer.ThreadGoal
  alias CodexEx.AppServer.ThreadItem
  alias CodexEx.AppServer.ThreadSettings
  alias CodexEx.AppServer.ThreadSnapshot
  alias CodexEx.AppServer.Turn
  alias CodexEx.AppServer.TurnStream
  alias CodexEx.AppServer.WebSocketFixturePlug

  setup do
    mock = start_supervised!(MockTransport)

    {:ok, mock: mock}
  end

  test "connect initializes the app-server session", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok,
            %InitializeResponse{
              platform_family: "unix",
              platform_os: "linux",
              user_agent: "mock-codex-app-server/1.0"
            }} = Client.initialize_result(client)
  end

  test "MCP resource and tool calls preserve server and thread scope", %{mock: mock} do
    MockTransport.configure(mock, notify: self())
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %McpResourceReadResponse{contents: [content]}} =
             Client.read_mcp_resource(
               client,
               "thread-1",
               "inventory",
               "ui://inventory/widget"
             )

    assert content["text"] == "<main>Mock MCP App</main>"

    assert_receive {:mock_mcp_resource_read,
                    %{
                      "server" => "inventory",
                      "threadId" => "thread-1",
                      "uri" => "ui://inventory/widget"
                    }}

    assert {:ok,
            %McpServerToolCallResponse{
              is_error: false,
              structured_content: %{"ok" => true}
            }} =
             Client.call_mcp_tool(
               client,
               "thread-1",
               "inventory",
               "reserve",
               %{"sku" => "A-1"}
             )

    assert_receive {:mock_mcp_tool_call,
                    %{
                      "arguments" => %{"sku" => "A-1"},
                      "server" => "inventory",
                      "threadId" => "thread-1",
                      "tool" => "reserve"
                    }}
  end

  test "registers an initial subscriber before startup events are handled", %{mock: mock} do
    client =
      start_supervised!({Client, [transport: MockTransport, mock_pid: mock, subscriber: self()]})

    assert Map.has_key?(:sys.get_state(client).subscribers, self())

    assert_receive {:codex_app_server_event,
                    %GenericNotification{
                      method: "session/initialized"
                    }}
  end

  test "disconnect stops the owned session", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    session = :sys.get_state(client).session
    session_ref = Process.monitor(session)

    assert :ok = Client.disconnect(client)
    assert_receive {:DOWN, ^session_ref, :process, ^session, :normal}
  end

  test "sequenced notifications are routed without exposing transport sequence", %{mock: mock} do
    client =
      start_supervised!({Client, [transport: MockTransport, mock_pid: mock, subscriber: self()]})

    assert_receive {:codex_app_server_event, %GenericNotification{method: "session/initialized"}}

    assert :ok = Client.subscribe(client, self(), thread_id: "thread-1")
    session = :sys.get_state(client).session

    :sys.replace_state(session, &%{&1 | last_transport_sequence: 2})

    for sequence <- 1..2 do
      send(
        client,
        {:codex_app_server_notification,
         %{
           "method" => "test/notification",
           "params" => %{"threadId" => "thread-1", "sequence" => sequence}
         }, sequence}
      )
    end

    assert_receive {:codex_app_server_event, %GenericNotification{}}
    assert_receive {:codex_app_server_event, %GenericNotification{}}
    _ = :sys.get_state(client)
    assert :sys.get_state(session).last_acknowledged_transport_sequence == 2
  end

  test "active thread status is published without a thread subscriber", %{mock: mock} do
    thread_id = "thread-external-active-#{System.unique_integer([:positive])}"

    client =
      start_supervised!(
        {Client,
         [
           transport: MockTransport,
           mock_pid: mock,
           broadcasts_thread_activity?: true,
           workspace_id: "workspace-activity"
         ]}
      )

    assert :ok = Client.subscribe_thread_activity()

    send(
      client,
      {:codex_app_server_notification,
       %{
         "method" => "thread/status/changed",
         "params" => %{
           "threadId" => thread_id,
           "status" => %{"activeFlags" => [], "type" => "active"}
         }
       }}
    )

    assert_receive {:codex_thread_active, {^client, nil, "workspace-activity"}, ^thread_id}

    send(
      client,
      {:codex_app_server_notification,
       %{
         "method" => "thread/status/changed",
         "params" => %{"threadId" => thread_id, "status" => %{"type" => "idle"}}
       }}
    )

    refute_receive {:codex_thread_active, {^client, nil, "workspace-activity"}, ^thread_id}, 50
  end

  test "external root thread starts are published without observing app threads or subagents", %{
    mock: mock
  } do
    MockTransport.configure(mock, notify: self())

    client =
      start_supervised!({Client, [transport: MockTransport, mock_pid: mock, broadcasts_thread_activity?: true]})

    assert :ok = Client.subscribe_thread_activity()
    assert {:ok, thread} = Client.start_thread(client, %{"threadSource" => "user"})
    assert_receive {:mock_thread_start, %{"threadSource" => "appServer"}}
    refute_receive {:codex_thread_discovered, {^client, _agent_id, _workspace_id}, _snapshot}, 50

    external_thread =
      mock
      |> :sys.get_state()
      |> Map.fetch!(:threads)
      |> Map.fetch!(thread.id)
      |> Map.put("source", "vscode")
      |> Map.put("threadSource", "user")

    send(
      client,
      {:codex_app_server_notification, %{"method" => "thread/started", "params" => %{"thread" => external_thread}}}
    )

    assert_receive {:codex_thread_discovered, {^client, nil, nil}, %ThreadSnapshot{id: thread_id, thread_source: "user"}}

    send(
      client,
      {:codex_app_server_notification,
       %{
         "method" => "thread/started",
         "params" => %{"thread" => Map.put(external_thread, "threadSource", "appServer")}
       }}
    )

    refute_receive {:codex_thread_discovered, {^client, _agent_id, _workspace_id}, _snapshot}, 50

    send(
      client,
      {:codex_app_server_notification,
       %{
         "method" => "thread/started",
         "params" => %{"thread" => Map.put(external_thread, "threadSource", "subagent")}
       }}
    )

    refute_receive {:codex_thread_discovered, {^client, _agent_id, _workspace_id}, _snapshot}, 50
    assert thread_id == thread.id
  end

  test "reconciliation publishes a thread that was already active", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, thread} = Client.start_thread(client)
    MockTransport.configure(mock, notify: self())

    :sys.replace_state(mock, fn state ->
      update_in(state, [:threads, thread.id], &Map.put(&1, "status", "active"))
    end)

    thread_id = thread.id
    assert :ok = Client.subscribe_thread_activity()
    assert :ok = Client.broadcast_active_threads(client)
    assert_receive {:mock_thread_list, %{"sourceKinds" => source_kinds}}
    assert "exec" in source_kinds
    assert "unknown" in source_kinds
    assert_receive {:codex_thread_active, {^client, nil, nil}, ^thread_id}
  end

  test "sequenced notifications are routed before their transport acknowledgement", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    subscriber =
      start_supervised!(
        {Task,
         fn ->
           receive do
             :stop -> :ok
           end
         end}
      )

    assert :ok = Client.subscribe(client, subscriber, thread_id: "thread-1")
    session = :sys.get_state(client).session
    :sys.replace_state(session, &%{&1 | last_transport_sequence: 1})
    assert 1 = :erlang.trace(client, true, [:send, {:tracer, self()}])

    try do
      send(
        client,
        {:codex_app_server_notification, %{"method" => "test/notification", "params" => %{"threadId" => "thread-1"}}, 1}
      )

      assert_receive {:trace, ^client, :send, {:codex_app_server_event, %GenericNotification{}}, ^subscriber}

      assert_receive {:trace, ^client, :send, {:"$gen_call", {^client, _tag}, {:acknowledge_transport_sequence, 1}},
                      ^session}
    after
      :erlang.trace(client, false, [:send])
      send(subscriber, :stop)
    end
  end

  test "dead subscribers do not block transport acknowledgements", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    subscriber =
      start_supervised!(
        {Task,
         fn ->
           receive do
             :stop -> :ok
           end
         end}
      )

    assert :ok = Client.subscribe(client, subscriber, thread_id: "thread-1")
    session = :sys.get_state(client).session
    :sys.replace_state(session, &%{&1 | last_transport_sequence: 2})
    subscriber_ref = Process.monitor(subscriber)

    :sys.suspend(client)

    try do
      for sequence <- 1..2 do
        send(
          client,
          {:codex_app_server_notification,
           %{
             "method" => "test/notification",
             "params" => %{"threadId" => "thread-1", "sequence" => sequence}
           }, sequence}
        )
      end

      assert {:messages, [_, _]} = Process.info(client, :messages)
      Process.exit(subscriber, :kill)
      assert_receive {:DOWN, ^subscriber_ref, :process, ^subscriber, :killed}
    after
      :sys.resume(client)
    end

    _ = :sys.get_state(client)
    assert :sys.get_state(session).last_acknowledged_transport_sequence == 2
  end

  test "thread-scoped subscribers ignore detached threads without blocking later events", %{
    mock: mock
  } do
    client =
      start_supervised!({Client, [transport: MockTransport, mock_pid: mock, subscriber: self()]})

    assert_receive {:codex_app_server_event, %GenericNotification{method: "session/initialized"}}

    assert :ok = Client.subscribe(client, self(), thread_id: "thread-current")
    session = :sys.get_state(client).session

    :sys.replace_state(session, &%{&1 | last_transport_sequence: 2})

    send(
      client,
      {:codex_app_server_notification, %{"method" => "test/notification", "params" => %{"threadId" => "thread-detached"}},
       1}
    )

    send(
      client,
      {:codex_app_server_notification, %{"method" => "test/notification", "params" => %{"threadId" => "thread-current"}},
       2}
    )

    assert_receive {:codex_app_server_event, %GenericNotification{}}
    refute_receive {:codex_app_server_event, _event}
    _ = :sys.get_state(client)
    assert :sys.get_state(session).last_acknowledged_transport_sequence == 2
  end

  test "nil thread scope receives global events without observing other threads", %{mock: mock} do
    client =
      start_supervised!({Client, [transport: MockTransport, mock_pid: mock, subscriber: self()]})

    assert_receive {:codex_app_server_event, %GenericNotification{method: "session/initialized"}}

    assert :ok = Client.subscribe(client, self(), thread_id: nil)
    session = :sys.get_state(client).session

    :sys.replace_state(session, &%{&1 | last_transport_sequence: 2})

    send(
      client,
      {:codex_app_server_notification, %{"method" => "test/notification", "params" => %{"threadId" => "thread-other"}}, 1}
    )

    send(
      client,
      {:codex_app_server_notification, %{"method" => "test/notification", "params" => %{"global" => true}}, 2}
    )

    assert_receive {:codex_app_server_event, %GenericNotification{}}
    refute_receive {:codex_app_server_event, _event}
  end

  test "replay gaps wait for every current reconciler and reject stale watermarks", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    second_owner = protocol_subscriber(self())

    assert :ok =
             Client.subscribe(client, self(),
               thread_id: "thread-1",
               reconciles_replay_gap?: true
             )

    assert :ok =
             Client.subscribe(client, second_owner,
               thread_id: "thread-2",
               reconciles_replay_gap?: true
             )

    send(client, {:codex_app_server_replay_gap, %{"missing_through_sequence" => 10}})
    assert_receive {:codex_app_server_replay_gap, ^client, %{"missing_through_sequence" => 10}}
    assert_receive {:protocol_subscriber_replay_gap, ^second_owner, ^client, 10}

    Client.acknowledge_replay_gap_async(client, self(), 10)
    assert :sys.get_state(client).replay_gap_owners == MapSet.new([second_owner])

    send(client, {:codex_app_server_replay_gap, %{"missing_through_sequence" => 20}})
    _ = :sys.get_state(client)
    assert_receive {:protocol_subscriber_replay_gap, ^second_owner, ^client, 20}
    send(second_owner, {:acknowledge_replay_gap, client, 10})
    assert_receive {:protocol_subscriber_acknowledged_replay_gap, ^second_owner, 10}

    state = :sys.get_state(client)
    assert state.replay_gap == %{"missing_through_sequence" => 20}
    assert state.replay_gap_owners == MapSet.new([self(), second_owner])

    Client.acknowledge_replay_gap_async(client, self(), 20)
    send(second_owner, {:acknowledge_replay_gap, client, 20})
    assert_receive {:protocol_subscriber_acknowledged_replay_gap, ^second_owner, 20}

    state = :sys.get_state(client)
    assert state.replay_gap == nil
    assert state.replay_gap_owners == MapSet.new()
  end

  test "ordinary events continue while a replay gap awaits another reconciler", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    parent = self()

    remaining_owner =
      start_supervised!(
        Supervisor.child_spec(
          {Task,
           fn ->
             receive do
               {:codex_app_server_replay_gap, delivered_by, payload} ->
                 send(parent, {:remaining_owner_received_gap, self(), delivered_by, payload})

                 receive do
                   :stop -> :ok
                 end
             end
           end},
          id: :remaining_replay_gap_owner
        )
      )

    assert :ok =
             Client.subscribe(client, self(),
               thread_id: "thread-1",
               reconciles_replay_gap?: true
             )

    assert :ok =
             Client.subscribe(client, remaining_owner,
               thread_id: "thread-2",
               reconciles_replay_gap?: true
             )

    session = :sys.get_state(client).session
    :sys.replace_state(session, &%{&1 | last_transport_sequence: 11})

    send(client, {:codex_app_server_replay_gap, %{"missing_through_sequence" => 10}})
    assert_receive {:codex_app_server_replay_gap, ^client, %{"missing_through_sequence" => 10}}

    assert_receive {:remaining_owner_received_gap, ^remaining_owner, ^client, %{"missing_through_sequence" => 10}}

    send(
      client,
      {:codex_app_server_notification, %{"method" => "test/notification", "params" => %{"threadId" => "thread-1"}}, 11}
    )

    assert_receive {:codex_app_server_event, %GenericNotification{}}
    _ = :sys.get_state(client)
    assert :sys.get_state(session).last_acknowledged_transport_sequence == 11

    Client.acknowledge_replay_gap_async(client, self(), 10)
    assert :sys.get_state(client).replay_gap_owners == MapSet.new([remaining_owner])

    owner_ref = Process.monitor(remaining_owner)
    send(remaining_owner, :stop)
    assert_receive {:DOWN, ^owner_ref, :process, ^remaining_owner, :normal}

    state = :sys.get_state(client)
    assert state.replay_gap == nil
    assert state.replay_gap_owners == MapSet.new()
  end

  test "legacy approval conversation ids are routed as thread ids" do
    for params <- [
          %ExecCommandApprovalParams{conversation_id: "thread-1"},
          %ApplyPatchApprovalParams{conversation_id: "thread-1"}
        ] do
      assert Message.thread_id(%ServerRequest{params: params}) == "thread-1"
    end
  end

  test "detached-thread server requests remain replayable after immediate ACK", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    session = :sys.get_state(client).session
    :sys.replace_state(session, &%{&1 | last_transport_sequence: 1})

    send(
      client,
      {:codex_app_server_request,
       %{
         "id" => "request-detached",
         "method" => "item/tool/requestUserInput",
         "params" => %{
           "itemId" => "item-1",
           "questions" => [],
           "threadId" => "thread-detached",
           "turnId" => "turn-1"
         }
       }, 1}
    )

    _ = :sys.get_state(client)
    assert :sys.get_state(session).last_acknowledged_transport_sequence == 1
    assert Map.has_key?(:sys.get_state(client).pending_requests, "request-detached")

    assert :ok = Client.subscribe(client, self(), thread_id: "thread-detached")
    assert_receive {:codex_app_server_event, %ServerRequest{id: "request-detached"}}
  end

  test "terminal transport sequence is acknowledged immediately", %{mock: mock} do
    client =
      start_supervised!({Client, [transport: MockTransport, mock_pid: mock, subscriber: self()]})

    session = :sys.get_state(client).session
    close_reason = {:remote_session_closed, "exited"}

    :sys.replace_state(session, fn state ->
      %{state | last_transport_sequence: 1, terminal_close: {close_reason, 1}}
    end)

    client_ref = Process.monitor(client)
    send(client, {:codex_app_server_transport_closed, close_reason, 1})
    assert_receive {:DOWN, ^client_ref, :process, ^client, :normal}, 500
  end

  test "replying removes a pending request from subscriber replay", %{mock: mock} do
    client =
      start_supervised!({Client, [transport: MockTransport, mock_pid: mock, subscriber: self()]})

    session = :sys.get_state(client).session
    :sys.replace_state(session, &%{&1 | last_transport_sequence: 1})

    send(
      client,
      {:codex_app_server_request,
       %{
         "id" => "request-1",
         "method" => "item/tool/requestUserInput",
         "params" => %{
           "itemId" => "item-1",
           "questions" => [],
           "threadId" => "thread-1",
           "turnId" => "turn-1"
         }
       }, 1}
    )

    assert_receive {:codex_app_server_event, %ServerRequest{id: "request-1"}}
    assert Map.has_key?(:sys.get_state(client).pending_requests, "request-1")

    assert :ok =
             Client.reply_request(
               client,
               "request-1",
               {:ok, %ToolRequestUserInputResponse{answers: %{}}}
             )

    refute Map.has_key?(:sys.get_state(client).pending_requests, "request-1")
  end

  test "connect initializes over websocket transport" do
    retry_counter = start_supervised!({Agent, fn -> 0 end})

    server =
      start_supervised!({Bandit, plug: {WebSocketFixturePlug, [retry_counter: retry_counter]}, ip: :loopback, port: 0})

    {:ok, {_address, port}} = ThousandIsland.listener_info(server)

    client =
      start_supervised!({Client, [transport: :websocket, url: "ws://127.0.0.1:#{port}/ws"]})

    assert {:ok,
            %InitializeResponse{
              platform_family: "unix",
              platform_os: "linux",
              user_agent: "mock-codex-app-server-websocket/1.0"
            }} = Client.initialize_result(client)
  end

  test "start_thread returns a typed thread wrapper and emits typed notifications", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert :ok = Client.subscribe(client)

    assert {:ok, %Thread{id: thread_id, snapshot: %ThreadSnapshot{} = snapshot} = thread} =
             Client.start_thread(client, %{"cwd" => "/tmp/project"})

    assert is_binary(thread_id)
    assert thread.client == client
    assert thread.settings.model == "gpt-5.4"
    assert thread.settings.active_permission_profile_id == nil
    assert thread.settings.developer_instructions == "Mock root developer instructions."
    assert thread.settings.replayable?

    assert thread.settings.sandbox_policy == %{
             "excludeSlashTmp" => false,
             "excludeTmpdirEnvVar" => false,
             "networkAccess" => false,
             "type" => "workspaceWrite",
             "writableRoots" => []
           }

    assert thread.settings.service_tier == nil
    assert snapshot.id == thread_id
    assert snapshot.cwd == "/tmp/project"
    assert snapshot.history_mode == "paginated"

    assert_receive {:codex_app_server_event, %ServerNotification{method: "thread/started"} = message}

    assert Message.thread_id(message) == thread_id
  end

  test "start_thread retains configured personality unless explicitly overridden", %{mock: mock} do
    MockTransport.configure(mock, personality: "friendly")
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %ConfigReadResponse{config: %ConfigReadResponse.Config{}}} =
             Client.read_config(client, nil)

    assert {:ok, %Thread{settings: %{personality: "friendly"}}} = Client.start_thread(client)

    assert {:ok, %Thread{settings: %{personality: "precise"}}} =
             Client.start_thread(client, %{"personality" => "precise"})
  end

  test "thread helpers expose typed snapshots and wrappers", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %Thread{id: thread_id} = thread} = Client.start_thread(client)

    assert {:ok, %Thread{id: ^thread_id, snapshot: %ThreadSnapshot{} = snapshot}} =
             Thread.refresh(thread, include_turns: true)

    assert snapshot.id == thread_id

    assert {:ok, %Thread{id: forked_id, snapshot: %ThreadSnapshot{id: forked_snapshot_id}}} =
             Thread.fork(thread, %{"ephemeral" => true})

    assert forked_snapshot_id == forked_id
    assert forked_id != thread_id

    assert :ok = Thread.archive(thread)

    assert {:ok, %Thread{id: ^thread_id, snapshot: %ThreadSnapshot{id: ^thread_id}}} =
             Thread.unarchive(thread)
  end

  test "side fork overrides replay a legacy workspace sandbox exactly", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{settings: settings}} = Client.start_thread(client)

    settings = %{
      settings
      | active_permission_profile_id: nil,
        sandbox_policy: %{
          "excludeSlashTmp" => true,
          "excludeTmpdirEnvVar" => false,
          "networkAccess" => true,
          "type" => "workspaceWrite",
          "writableRoots" => ["/tmp/project", "/tmp/shared"]
        }
    }

    assert {:ok, overrides} = ThreadSettings.side_fork_overrides(settings)
    assert overrides["sandbox"] == "workspace-write"
    refute Map.has_key?(overrides, "permissions")

    assert Map.take(overrides["config"], [
             "sandbox_workspace_write.exclude_slash_tmp",
             "sandbox_workspace_write.exclude_tmpdir_env_var",
             "sandbox_workspace_write.network_access",
             "sandbox_workspace_write.writable_roots"
           ]) == %{
             "sandbox_workspace_write.exclude_slash_tmp" => true,
             "sandbox_workspace_write.exclude_tmpdir_env_var" => false,
             "sandbox_workspace_write.network_access" => true,
             "sandbox_workspace_write.writable_roots" => ["/tmp/project", "/tmp/shared"]
           }

    named_settings = %{settings | active_permission_profile_id: ":workspace"}
    assert {:ok, named_overrides} = ThreadSettings.side_fork_overrides(named_settings)
    assert named_overrides["permissions"] == ":workspace"
    refute Map.has_key?(named_overrides, "sandbox")
  end

  test "simple request helpers preserve typed and empty response contracts", %{mock: mock} do
    MockTransport.configure(mock, notify: self())
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %SkillsListResponse{data: [entry]}} = Client.list_skills(client)
    assert Enum.map(entry.skills, & &1.name) == ["brainstorming", "testing"]

    assert :ok = Client.set_thread_name(client, "thread-title", "Shared title")

    assert_receive {:mock_thread_name_set, %{"threadId" => "thread-title", "name" => "Shared title"}}
  end

  test "resume can return one active turn while excluding thread history", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{id: thread_id}} = Client.start_thread(client)

    :sys.replace_state(mock, fn state ->
      completed_turn = %{
        "id" => "turn-completed",
        "items" => [],
        "status" => "completed"
      }

      active_turn = %{
        "id" => "turn-active",
        "items" => [
          %{
            "id" => "item-active",
            "status" => "inProgress",
            "text" => "Still working",
            "type" => "agentMessage"
          }
        ],
        "status" => "inProgress"
      }

      thread =
        state.threads
        |> Map.fetch!(thread_id)
        |> Map.put("status", "running")
        |> Map.put("turns", [completed_turn, active_turn])

      %{state | threads: Map.put(state.threads, thread_id, thread)}
    end)

    MockTransport.configure(mock, notify: self())

    assert {:ok,
            %Thread{
              settings: %ThreadSettings{} = settings,
              snapshot: %ThreadSnapshot{
                turns: [
                  %Turn{id: "turn-active", status: "inProgress", items: [active_item]}
                ]
              }
            }} =
             Client.resume_thread(client, thread_id, %{
               "excludeTurns" => true,
               "initialTurnsPage" => %{
                 "itemsView" => "full",
                 "limit" => 1,
                 "sortDirection" => "desc"
               }
             })

    assert %ThreadItem.AgentMessage{text: "Still working"} = active_item
    assert settings.model == "gpt-5.4"
    assert settings.reasoning_effort == "medium"
    refute settings.replayable?
    assert ThreadSettings.persisted_seed(settings) == nil
    assert {:ok, overrides} = ThreadSettings.side_fork_overrides(settings)
    refute Map.has_key?(overrides, "developerInstructions")
    assert overrides["model"] == settings.model
    assert overrides["approvalPolicy"] == settings.approval_policy

    assert_receive {:mock_thread_resume,
                    %{
                      "config" => %{"features.realtime_conversation" => true},
                      "excludeTurns" => true,
                      "initialTurnsPage" => %{"limit" => 1}
                    }}
  end

  test "resume fails when a requested initial turns page is omitted", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{id: thread_id}} = Client.start_thread(client)
    MockTransport.configure(mock, omit_initial_turns_page: true)

    assert {:error, {:protocol_error, :missing_initial_turns_page}} =
             Client.resume_thread(client, thread_id, %{
               "excludeTurns" => true,
               "initialTurnsPage" => %{
                 "itemsView" => "full",
                 "limit" => 1,
                 "sortDirection" => "desc"
               }
             })
  end

  test "legacy thread history fails instead of using thread/read includeTurns", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %Thread{} = thread} =
             Client.start_thread(client, %{"historyMode" => "legacy"})

    assert {:error, {:unsupported_thread_history_mode, "legacy"}} =
             Thread.refresh(thread, include_turns: true)
  end

  test "fresh legacy metadata overrides a stale paginated history hint", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %Thread{id: thread_id}} =
             Client.start_thread(client, %{"historyMode" => "legacy"})

    assert {:error, {:unsupported_thread_history_mode, "legacy"}} =
             Client.read_thread(client, thread_id,
               include_turns: true,
               history_mode: "paginated"
             )
  end

  test "fork preflights fresh history mode before mutating", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %Thread{} = thread} =
             Client.start_thread(client, %{"historyMode" => "legacy"})

    stale_thread = %{thread | snapshot: %{thread.snapshot | history_mode: "paginated"}}
    MockTransport.configure(mock, notify: self())

    assert {:error, {:unsupported_thread_history_mode, "legacy"}} = Thread.fork(stale_thread)
    refute_receive {:mock_thread_fork, _params}, 0
    assert :sys.get_state(mock).thread_counter == 1
  end

  test "fork forces excludeTurns and paginates copied history afterwards", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %Thread{} = thread} = Client.start_thread(client)
    assert {:ok, "OK"} = Thread.run_text(thread, "Reply")
    assert {:ok, "OK"} = Thread.run_text(thread, "Reply again")
    MockTransport.configure(mock, notify: self())

    assert {:ok, %Thread{snapshot: %ThreadSnapshot{turns: []}} = forked_thread} =
             Thread.fork(thread, %{
               "beforeTurnId" => "turn-2",
               "ephemeral" => true,
               "excludeTurns" => false
             })

    assert_receive {:mock_thread_fork,
                    %{
                      "beforeTurnId" => "turn-2",
                      "ephemeral" => true,
                      "excludeTurns" => true,
                      "threadSource" => "appServer"
                    }}

    assert forked_thread.snapshot.ephemeral == true

    assert {:ok, %Thread{snapshot: %ThreadSnapshot{turns: [%Turn{id: "turn-1"}]}}} =
             Thread.refresh(forked_thread, include_turns: true)
  end

  test "ephemeral thread controls use the generated wire contract", %{mock: mock} do
    MockTransport.configure(mock, notify: self())
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    items = [
      %{
        role: "user",
        type: "message",
        content: [%{text: "Side conversation boundary.", type: "input_text"}]
      }
    ]

    assert :ok = Client.inject_thread_items(client, "thread-side", items)

    assert_receive {:mock_thread_inject_items,
                    %{
                      "threadId" => "thread-side",
                      "items" => [
                        %{
                          "role" => "user",
                          "type" => "message",
                          "content" => [
                            %{
                              "text" => "Side conversation boundary.",
                              "type" => "input_text"
                            }
                          ]
                        }
                      ]
                    }}

    assert {:ok, %ThreadUnsubscribeResponse{status: "unsubscribed"}} =
             Client.unsubscribe_thread(client, "thread-side")

    assert_receive {:mock_thread_unsubscribe, %{"threadId" => "thread-side"}}
  end

  test "revert removes the target and later turns without changing thread identity", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %Thread{id: thread_id}} = Client.start_thread(client)
    assert {:ok, "OK"} = Client.run_text(client, thread_id, "Reply")
    assert {:ok, "OK"} = Client.run_text(client, thread_id, "Reply again")
    MockTransport.configure(mock, notify: self())

    assert {:ok, %Thread{id: ^thread_id, snapshot: %ThreadSnapshot{turns: []}} = reverted} =
             Client.revert_thread(client, thread_id, "turn-2")

    assert_receive {:mock_thread_revert, %{"beforeTurnId" => "turn-2", "threadId" => ^thread_id}}

    assert {:ok, %Thread{snapshot: %ThreadSnapshot{turns: [%Turn{id: "turn-1"}]}}} =
             Thread.refresh(reverted, include_turns: true)
  end

  test "legacy rollback fails before mutating remote history", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %Thread{id: thread_id} = thread} =
             Client.start_thread(client, %{"historyMode" => "legacy"})

    assert {:ok, "OK"} = Thread.run_text(thread, "Reply")

    assert {:error, {:unsupported_thread_history_mode, "legacy"}} =
             Client.rollback_thread(client, thread_id, 1)

    state = :sys.get_state(mock)

    assert [%{"id" => "turn-1"}] =
             Enum.map(state.threads[thread_id]["turns"], &Map.take(&1, ["id"]))
  end

  test "paginated rollback is rejected without mutating remote history", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %Thread{id: thread_id} = thread} = Client.start_thread(client)
    assert {:ok, "OK"} = Thread.run_text(thread, "Reply")

    assert {:error,
            {:remote_error,
             %{
               "code" => -32_600,
               "message" => "paginated threads do not support thread/rollback"
             }}} =
             Client.rollback_thread(client, thread_id, 1)

    assert [%{"id" => "turn-1"}] =
             Enum.map(:sys.get_state(mock).threads[thread_id]["turns"], &Map.take(&1, ["id"]))
  end

  test "authoritative pagination rejects a repeated cursor without a third request", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %Thread{} = thread} = Client.start_thread(client)
    assert {:ok, "OK"} = Thread.run_text(thread, "Reply")
    MockTransport.configure(mock, notify: self(), thread_turns_cursor_mode: :repeat)

    assert {:error, {:protocol_error, {:repeated_thread_turns_cursor, "same"}}} =
             Thread.refresh(thread, include_turns: true)

    assert_receive {:mock_thread_turns_list, %{"threadId" => "thread-1"} = first_params}
    assert first_params["limit"] == 10
    refute Map.has_key?(first_params, "cursor")
    assert_receive {:mock_thread_turns_list, %{"cursor" => "same"}}
    refute_receive {:mock_thread_turns_list, _params}, 0
  end

  test "authoritative pagination rejects an empty page with a cursor", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %Thread{} = thread} = Client.start_thread(client)
    assert {:ok, "OK"} = Thread.run_text(thread, "Reply")
    MockTransport.configure(mock, notify: self(), thread_turns_cursor_mode: :empty_with_cursor)

    assert {:error, {:protocol_error, :empty_thread_turns_page_with_cursor}} =
             Thread.refresh(thread, include_turns: true)

    assert_receive {:mock_thread_turns_list, %{"threadId" => "thread-1"} = first_params}
    refute Map.has_key?(first_params, "cursor")
    refute_receive {:mock_thread_turns_list, _params}, 0
  end

  test "realtime helpers send a v3 WebRTC offer and parse the answer notification", %{
    mock: mock
  } do
    MockTransport.configure(mock, notify: self())
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert :ok = Client.subscribe(client)

    assert :ok = Client.start_realtime(client, "thread-voice", "v=0\r\nbrowser-offer")

    assert_receive {:mock_realtime_start,
                    %{
                      "threadId" => "thread-voice",
                      "outputModality" => "audio",
                      "transport" => %{
                        "type" => "webrtc",
                        "sdp" => "v=0\r\nbrowser-offer"
                      },
                      "version" => "v3"
                    }}

    assert_receive {:codex_app_server_event,
                    %ServerNotification{
                      method: "thread/realtime/sdp",
                      params: %{thread_id: "thread-voice", sdp: "v=0\r\nmock-answer"}
                    }}

    assert :ok = Client.stop_realtime(client, "thread-voice")
    assert_receive {:mock_realtime_stop, %{"threadId" => "thread-voice"}}
  end

  test "paginated refresh loads full stable items across pages in transcript order", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    MockTransport.configure(mock, thread_turns_page_size: 1)

    assert {:ok, %Thread{} = thread} = Client.start_thread(client)
    assert {:ok, _response} = Thread.run_text(thread, "First")
    assert {:ok, _response} = Thread.run_text(thread, "Second")

    assert {:ok, %Thread{snapshot: %ThreadSnapshot{turns: turns}}} =
             Thread.refresh(thread, include_turns: true)

    assert Enum.map(turns, & &1.id) == ["turn-1", "turn-2"]

    assert [first, second] = turns

    assert Enum.map(first.items, &ThreadItem.id/1) == [
             "item-user-turn-1",
             "item-agent-turn-1"
           ]

    assert Enum.map(second.items, &ThreadItem.id/1) == [
             "item-user-turn-2",
             "item-agent-turn-2"
           ]
  end

  test "paginated turn listing returns one backwards page", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %Thread{id: thread_id} = thread} = Client.start_thread(client)
    assert {:ok, _response} = Thread.run_text(thread, "First")
    assert {:ok, _response} = Thread.run_text(thread, "Second")

    assert {:ok, %{turns: [%Turn{id: "turn-2"}], next_cursor: "1"}} =
             Client.list_thread_turns(client, thread_id, limit: 1)
  end

  test "thread goal helpers use generated protocol and typed values", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert :ok = Client.subscribe(client)
    assert {:ok, %Thread{id: thread_id} = thread} = Client.start_thread(client)

    assert {:ok,
            %ThreadGoal{
              thread_id: ^thread_id,
              objective: "Keep the goal focused",
              status: :active,
              token_budget: 1200
            }} =
             Thread.set_goal(thread, %{
               "objective" => "Keep the goal focused",
               "status" => "active",
               "tokenBudget" => 1200
             })

    assert_receive {:codex_app_server_event, %ServerNotification{method: "thread/goal/updated"} = updated}

    assert Message.thread_id(updated) == thread_id

    assert {:ok, %ThreadGoal{thread_id: ^thread_id, objective: "Keep the goal focused"}} =
             Thread.get_goal(thread)

    assert :ok = Thread.clear_goal(thread)

    assert_receive {:codex_app_server_event, %ServerNotification{method: "thread/goal/cleared"} = cleared}

    assert Message.thread_id(cleared) == thread_id
    assert {:ok, nil} = Thread.get_goal(thread)
  end

  test "experimental feature helpers use generated protocol", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

    assert {:ok, %{enablement: %{"goals" => true}}} =
             Client.set_experimental_feature_enablement(client, %{"goals" => true})

    assert {:ok, %{data: [feature]}} = Client.list_experimental_features(client)
    assert feature.name == "goals"
    assert feature.enabled == true
  end

  test "hook helpers list configured hooks and trust the current hook hash", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    cwd = "/tmp/mock-codex"

    assert {:ok, %HooksListResponse{data: [%{cwd: ^cwd, hooks: [hook]}]}} =
             Client.list_hooks(client, [cwd])

    assert hook.key == "/tmp/mock-codex/.codex/hooks.json:preToolUse:0:0"
    assert hook.current_hash == "sha256:mock-hook"
    assert hook.trust_status == "untrusted"

    assert {:ok, %ConfigWriteResponse{status: "ok"}} =
             Client.trust_hook(client, hook.key, hook.current_hash)

    assert {:ok, %HooksListResponse{data: [%{hooks: [trusted_hook]}]}} =
             Client.list_hooks(client, [cwd])

    assert trusted_hook.key == hook.key
    assert trusted_hook.current_hash == hook.current_hash
    assert trusted_hook.trust_status == "trusted"

    assert {:ok, %ConfigWriteResponse{status: "ok"}} =
             Client.set_hook_enabled(client, hook.key, false)

    assert {:ok, %HooksListResponse{data: [%{hooks: [disabled_hook]}]}} =
             Client.list_hooks(client, [cwd])

    assert disabled_hook.key == hook.key
    assert disabled_hook.enabled == false

    assert {:ok, %ConfigWriteResponse{status: "ok"}} =
             Client.set_hook_enabled(client, hook.key, true)

    assert {:ok, %HooksListResponse{data: [%{hooks: [enabled_hook]}]}} =
             Client.list_hooks(client, [cwd])

    assert enabled_hook.key == hook.key
    assert enabled_hook.enabled == true
  end

  test "fuzzy file search session wrappers use the generated protocol", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert :ok = Client.subscribe(client)

    assert {:ok, :started} =
             Client.start_fuzzy_file_search_session(client, "search-1", ["/tmp/mock-codex"])

    assert {:ok, :updated} =
             Client.update_fuzzy_file_search_session(client, "search-1", "lib/ap")

    assert_receive {:codex_app_server_event, %ServerNotification{method: "fuzzyFileSearch/sessionUpdated"}}

    assert :ok = Client.stop_fuzzy_file_search_session(client, "search-1")
  end

  test "run returns a typed turn stream and publishes typed notifications", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{id: thread_id} = thread} = Client.start_thread(client)
    assert :ok = Client.subscribe(client)

    MockTransport.configure(mock, delay_ms: 200)

    assert {:ok, %TurnStream{} = stream} =
             Thread.run(
               thread,
               [%{"type" => "text", "text" => "Reply with the single word OK."}],
               %{"clientUserMessageId" => "client-run-1"}
             )

    assert stream.thread_id == thread_id

    assert_receive {:codex_app_server_event, %ServerNotification{method: "turn/started"} = started}

    assert Message.thread_id(started) == thread_id
    assert is_binary(Message.turn_id(started))

    assert {:ok, %TurnStream{final_turn: %Turn{status: "completed"} = final_turn} = completed} =
             TurnStream.wait(stream, 5_000)

    assert final_turn.thread_id == thread_id
    assert completed.final_text == "OK"

    assert [
             %CodexEx.AppServer.ThreadItem.Generic{type: "userMessage", attrs: attrs},
             %CodexEx.AppServer.ThreadItem.AgentMessage{text: "OK"}
           ] = completed.items

    assert get_in(attrs, ["content", Access.at(0), "text"]) == "Reply with the single word OK."
    assert attrs["clientId"] == "client-run-1"

    assert_receive {:codex_app_server_event, %ServerNotification{method: "turn/completed"} = completed_message}

    assert Message.thread_id(completed_message) == thread_id

    assert {:ok, %Turn{status: "completed"}} =
             Message.extract_turn(completed_message)
  end

  test "start_turn returns a typed turn while subscribers receive its events", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{id: thread_id}} = Client.start_thread(client)
    assert :ok = Client.subscribe(client, self(), thread_id: thread_id)

    assert {:ok, %Turn{id: turn_id, thread_id: ^thread_id, status: "inProgress", items: []}} =
             Client.start_turn(
               client,
               thread_id,
               [%{"type" => "text", "text" => "Reply with OK."}],
               %{"clientUserMessageId" => "client-side-1"}
             )

    assert_receive {:codex_app_server_event, %ServerNotification{method: "turn/started"} = started}

    assert Message.thread_id(started) == thread_id
    assert Message.turn_id(started) == turn_id

    assert_receive {:codex_app_server_event, %ServerNotification{method: "turn/completed"} = completed}

    assert Message.thread_id(completed) == thread_id
    assert Message.turn_id(completed) == turn_id
    assert Map.keys(:sys.get_state(client).subscribers) == [self()]
  end

  test "run_text returns final assistant text for completed turns", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    assert {:ok, "OK"} = Thread.run_text(thread, "Reply with the single word OK.")
  end

  test "run_text survives turns longer than the default GenServer.call timeout", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    MockTransport.configure(mock, delay_ms: 5_200)

    assert {:ok, "OK"} =
             Thread.run_text(thread, "Reply with the single word OK.", %{})
  end

  test "run supports collaborationMode when the client advertises experimentalApi", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    assert {:ok, "OK"} =
             Thread.run_text(thread, "Reply with the single word OK.", %{
               "collaborationMode" => %{
                 "mode" => "plan",
                 "settings" => %{"model" => "gpt-5.4"}
               }
             })
  end

  test "run can reset a sticky collaborationMode back to default explicitly", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    assert {:ok, "plan"} =
             Thread.run_text(thread, "Reply with the current collaboration mode.", %{
               "collaborationMode" => %{
                 "mode" => "plan",
                 "settings" => %{"model" => "gpt-5.4"}
               }
             })

    assert {:ok, "default"} =
             Thread.run_text(thread, "Reply with the current collaboration mode.", %{
               "collaborationMode" => %{
                 "mode" => "default",
                 "settings" => %{"model" => "gpt-5.4"}
               }
             })
  end

  test "run returns a protocol error when the server sends an unexpected result shape", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    MockTransport.configure(mock, malformed_result: true)

    assert {:ok, %TurnStream{} = stream} =
             Thread.run(thread, [%{"type" => "text", "text" => "Break the shape"}], %{})

    assert {:error, {:protocol_error, {:unexpected_turn_result, %{"unexpected" => true}}}} =
             TurnStream.wait(stream, 5_000)
  end

  test "named clients work through the public API", %{mock: mock} do
    name = {:global, {:codex_named_client, self()}}

    _client = start_supervised!({Client, [name: name, transport: MockTransport, mock_pid: mock]})

    assert {:ok, %InitializeResponse{user_agent: "mock-codex-app-server/1.0"}} =
             Client.initialize_result(name)

    assert {:ok, %Thread{id: thread_id}} = Client.start_thread(name)
    assert {:ok, %ThreadSnapshot{id: ^thread_id}} = Client.read_thread(name, thread_id)
  end

  test "run_json parses the final assistant message as JSON", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{id: thread_id}} = Client.start_thread(client)

    schema = %{
      "type" => "object",
      "properties" => %{
        "summary" => %{"type" => "string"}
      },
      "required" => ["summary"]
    }

    assert {:ok, %{"summary" => "OK"}} =
             Client.run_json(client, thread_id, "Return JSON", schema)
  end

  test "reply_request answers server-initiated requests during a turn", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)
    assert :ok = Client.subscribe(client)

    MockTransport.configure(mock, server_request: true)

    task =
      Task.async(fn ->
        Thread.run_text(thread, "Need approval", %{})
      end)

    assert_receive {:codex_app_server_event,
                    %ServerRequest{
                      method: "item/tool/requestUserInput",
                      id: request_id
                    }}

    assert :ok =
             Client.reply_request(
               client,
               request_id,
               {:ok,
                %ToolRequestUserInputResponse{
                  answers: %{
                    "approve" => %ToolRequestUserInputResponse.ToolRequestUserInputAnswer{
                      answers: ["yes"]
                    }
                  }
                }}
             )

    assert {:ok, "OK"} = Task.await(task)
  end

  test "pending_requests exposes unresolved server requests and clears them on reply", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)
    assert :ok = Client.subscribe(client)

    MockTransport.configure(mock, server_request: true)

    task =
      Task.async(fn ->
        Thread.run_text(thread, "Need approval", %{})
      end)

    assert_receive {:codex_app_server_event,
                    %ServerRequest{
                      method: "item/tool/requestUserInput",
                      id: request_id
                    }}

    assert {:ok, [%ServerRequest{id: ^request_id}]} = Client.pending_requests(client)

    parent = self()

    late_subscriber =
      spawn_link(fn ->
        assert :ok = Client.subscribe(client)
        send(parent, {:late_subscriber_ready, self()})

        receive do
          message -> send(parent, {:late_subscriber_event, self(), message})
        end
      end)

    assert_receive {:late_subscriber_ready, ^late_subscriber}

    assert_receive {:late_subscriber_event, ^late_subscriber,
                    {:codex_app_server_event, %ServerRequest{id: ^request_id, method: "item/tool/requestUserInput"}}}

    assert :ok =
             Client.reply_request(
               client,
               request_id,
               {:ok,
                %ToolRequestUserInputResponse{
                  answers: %{
                    "approve" => %ToolRequestUserInputResponse.ToolRequestUserInputAnswer{
                      answers: ["yes"]
                    }
                  }
                }}
             )

    assert {:ok, []} = Client.pending_requests(client)
    assert {:ok, "OK"} = Task.await(task)
  end

  test "registered request handlers auto-reply to typed server requests", %{
    mock: mock
  } do
    test_pid = self()
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{id: thread_id} = thread} = Client.start_thread(client)
    assert :ok = Client.subscribe(client)

    assert :ok =
             Client.register_request_handler(client, fn request ->
               send(test_pid, {:request_handled, request})

               {:ok,
                %ToolRequestUserInputResponse{
                  answers: %{
                    "approve" => %ToolRequestUserInputResponse.ToolRequestUserInputAnswer{
                      answers: ["yes"]
                    }
                  }
                }}
             end)

    MockTransport.configure(mock, server_request: true)

    assert {:ok, "OK"} =
             Thread.run_text(thread, "Need approval", %{})

    assert_receive {:request_handled,
                    %ServerRequest{
                      method: "item/tool/requestUserInput",
                      id: "server-request-1",
                      params: %ToolRequestUserInputParams{
                        item_id: "item-1",
                        thread_id: ^thread_id,
                        turn_id: _turn_id,
                        questions: [
                          %ToolRequestUserInputParams.ToolRequestUserInputQuestion{
                            header: "Approve",
                            id: "approve",
                            question: "Continue?"
                          }
                        ]
                      }
                    }}

    assert {:ok, []} = Client.pending_requests(client)
  end

  test "reply_request rejects malformed raw request_user_input payloads", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)
    assert :ok = Client.subscribe(client)

    MockTransport.configure(mock, server_request: true)

    task =
      Task.async(fn ->
        Thread.run_text(thread, "Need approval", %{})
      end)

    assert_receive {:codex_app_server_event,
                    %ServerRequest{
                      method: "item/tool/requestUserInput",
                      id: request_id
                    }}

    assert {:error, {:unsupported_request_reply_payload, %{"answers" => [%{"id" => "approve"}]}}} =
             Client.reply_request(
               client,
               request_id,
               {:ok, %{"answers" => [%{"id" => "approve"}]}}
             )

    assert nil == Task.yield(task, 100)
    Task.shutdown(task, :brutal_kill)
  end

  test "reply_request accepts typed MCP elicitation responses", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)
    assert :ok = Client.subscribe(client)

    MockTransport.configure(mock, elicitation_request: true)

    task =
      Task.async(fn ->
        Thread.run_text(thread, "elicit me", %{})
      end)

    assert_receive {:codex_app_server_event,
                    %ServerRequest{
                      method: "mcpServer/elicitation/request",
                      id: request_id
                    }}

    assert :ok =
             Client.reply_request(
               client,
               request_id,
               {:ok,
                %McpServerElicitationRequestResponse{
                  action: "accept",
                  content: %{"color" => "red", "name" => "Alice"}
                }}
             )

    assert {:ok, "OK"} = Task.await(task)
  end

  defp protocol_subscriber(parent) do
    start_supervised!(
      Supervisor.child_spec(
        {Task, fn -> protocol_subscriber_loop(parent) end},
        id: {:protocol_subscriber, make_ref()}
      )
    )
  end

  defp protocol_subscriber_loop(parent) do
    receive do
      {:codex_app_server_replay_gap, client, %{"missing_through_sequence" => through_sequence}} ->
        send(parent, {:protocol_subscriber_replay_gap, self(), client, through_sequence})

      {:acknowledge_replay_gap, client, through_sequence} ->
        Client.acknowledge_replay_gap_async(client, self(), through_sequence)
        _ = :sys.get_state(client)
        send(parent, {:protocol_subscriber_acknowledged_replay_gap, self(), through_sequence})
    end

    protocol_subscriber_loop(parent)
  end
end
