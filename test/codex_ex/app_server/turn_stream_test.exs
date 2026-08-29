defmodule CodexEx.AppServer.TurnStreamTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.Client
  alias CodexEx.AppServer.Message
  alias CodexEx.AppServer.MockTransport
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerNotification
  alias CodexEx.AppServer.Protocol.GenericNotification
  alias CodexEx.AppServer.Thread
  alias CodexEx.AppServer.ThreadItem
  alias CodexEx.AppServer.TokenUsage
  alias CodexEx.AppServer.Turn
  alias CodexEx.AppServer.TurnStream
  alias CodexEx.AppServer.WebSocketFixturePlug

  setup do
    mock = start_supervised!(MockTransport)

    {:ok, mock: mock}
  end

  test "malformed scoped turn notifications surface protocol errors instead of crashing", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert :ok = Client.subscribe(client)
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    MockTransport.configure(mock, delay_ms: 300)

    assert {:ok, %TurnStream{} = stream} =
             Thread.run(
               thread,
               [%{"type" => "text", "text" => "Reply with the single word OK."}],
               %{}
             )

    started_message = receive_event("turn/started")
    assert Message.turn_id(started_message) == "turn-1"

    send(
      stream.pid,
      {:codex_app_server_event,
       %GenericNotification{
         method: "turn/completed",
         params: %{
           "threadId" => thread.id,
           "turnId" => "turn-1",
           "turn" => %{"id" => "turn-1"}
         }
       }}
    )

    assert {:error,
            {:protocol_error, {:invalid_event_payload, "turn/completed", {:invalid_turn, {:missing_field, :status}}}}} =
             TurnStream.wait(stream, 5_000)
  end

  test "malformed scoped item notifications surface protocol errors instead of crashing", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    MockTransport.configure(mock, delay_ms: 300)

    assert {:ok, %TurnStream{} = stream} =
             Thread.run(
               thread,
               [%{"type" => "text", "text" => "Reply with the single word OK."}],
               %{}
             )

    send(
      stream.pid,
      {:codex_app_server_event,
       %GenericNotification{
         method: "item/completed",
         params: %{"threadId" => thread.id, "turnId" => "turn-1", "item" => 123}
       }}
    )

    assert {:error,
            {:protocol_error,
             {:invalid_event_payload, "item/completed", {:invalid_thread_item, {:unexpected_payload, 123}}}}} =
             TurnStream.wait(stream, 5_000)
  end

  test "present scoped item notifications without type surface protocol errors", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    MockTransport.configure(mock, delay_ms: 300)

    assert {:ok, %TurnStream{} = stream} =
             Thread.run(
               thread,
               [%{"type" => "text", "text" => "Reply with the single word OK."}],
               %{}
             )

    send(
      stream.pid,
      {:codex_app_server_event,
       %GenericNotification{
         method: "item/completed",
         params: %{"threadId" => thread.id, "turnId" => "turn-1", "item" => %{"id" => "item-1"}}
       }}
    )

    assert {:error,
            {:protocol_error, {:invalid_event_payload, "item/completed", {:invalid_thread_item, {:missing_field, :type}}}}} =
             TurnStream.wait(stream, 5_000)
  end

  test "turn streams isolate overlapping turns on the same thread over websocket" do
    retry_counter = start_supervised!({Agent, fn -> 0 end})

    server =
      start_supervised!({Bandit, plug: {WebSocketFixturePlug, [retry_counter: retry_counter]}, ip: :loopback, port: 0})

    {:ok, {_address, port}} = ThousandIsland.listener_info(server)

    client =
      start_supervised!({Client, [transport: :websocket, url: "ws://127.0.0.1:#{port}/ws"]})

    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    assert {:ok, %TurnStream{} = delayed_stream} =
             Thread.run(
               thread,
               [%{"type" => "text", "text" => "Reply with the single word FIRST."}],
               %{"mockPushDelayMs" => 250}
             )

    assert {:ok, %TurnStream{} = immediate_stream} =
             Thread.run(
               thread,
               [%{"type" => "text", "text" => "Reply with the single word SECOND."}]
             )

    assert {:ok,
            %TurnStream{
              turn_id: immediate_turn_id,
              final_turn: %Turn{id: immediate_final_turn_id} = final_turn,
              final_text: "SECOND"
            }} = TurnStream.wait(immediate_stream, 5_000)

    assert immediate_final_turn_id == immediate_turn_id

    assert_turn_items_include_prompt_and_reply(
      final_turn.items,
      "Reply with the single word SECOND.",
      "SECOND"
    )

    assert {:ok,
            %TurnStream{
              turn_id: delayed_turn_id,
              final_turn: %Turn{id: delayed_final_turn_id} = delayed_final_turn,
              final_text: "FIRST"
            }} = TurnStream.wait(delayed_stream, 5_000)

    assert delayed_final_turn_id == delayed_turn_id
    refute delayed_turn_id == immediate_turn_id

    assert_turn_items_include_prompt_and_reply(
      delayed_final_turn.items,
      "Reply with the single word FIRST.",
      "FIRST"
    )
  end

  test "turn stream snapshots expose typed token-usage updates", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    MockTransport.configure(mock, delay_ms: 300)

    assert {:ok, %TurnStream{} = stream} =
             Thread.run(
               thread,
               [%{"type" => "text", "text" => "Reply with the single word OK."}],
               %{}
             )

    send(
      stream.pid,
      {:codex_app_server_event,
       %ServerNotification{
         method: "thread/tokenUsage/updated",
         params: %{
           thread_id: thread.id,
           turn_id: "turn-1",
           token_usage: %{
             model_context_window: 200_000,
             last: %{
               cached_input_tokens: 1,
               input_tokens: 2,
               output_tokens: 3,
               reasoning_output_tokens: 4,
               total_tokens: 10
             },
             total: %{
               cached_input_tokens: 5,
               input_tokens: 6,
               output_tokens: 7,
               reasoning_output_tokens: 8,
               total_tokens: 26
             }
           }
         }
       }}
    )

    assert {:ok, %TurnStream{usage: %TokenUsage{} = usage}} = TurnStream.wait(stream, 5_000)
    assert usage.total.total_tokens == 26
  end

  test "turn streams prefer the richer rpc result over partial terminal notification turns", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert :ok = Client.subscribe(client)
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    MockTransport.configure(mock, delay_ms: 300, partial_turn_notifications: true)

    assert {:ok, %TurnStream{} = stream} =
             Thread.run(
               thread,
               [%{"type" => "text", "text" => "Reply with the single word OK."}],
               %{}
             )

    started_message = receive_event("turn/started")
    turn_id = Message.turn_id(started_message)
    assert is_binary(turn_id)

    assert {:ok, %TurnStream{final_turn: %Turn{} = final_turn, items: items, final_text: "OK"}} =
             TurnStream.wait(stream, 5_000)

    assert final_turn.id == turn_id
    assert final_turn.status == "completed"

    assert_turn_items_include_prompt_and_reply(
      final_turn.items,
      "Reply with the single word OK.",
      "OK"
    )

    assert_turn_items_include_prompt_and_reply(items, "Reply with the single word OK.", "OK")
  end

  test "turn streams prefer the richer rpc turn over buffered partial item updates", %{
    mock: mock
  } do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)

    test_pid = self()
    turn_id = "turn-buffered-rpc-1"
    item_id = "item-agent-#{turn_id}"

    agent_attrs = %{
      "id" => item_id,
      "metadata" => %{"source" => "rpc"},
      "status" => "completed",
      "text" => "FIRST",
      "type" => "agentMessage"
    }

    completed_turn = %Turn{
      error: nil,
      id: turn_id,
      items: [
        %ThreadItem.Generic{
          id: "input-#{turn_id}",
          type: "userMessage",
          attrs: %{
            "content" => [%{"text" => "Reply with the single word FIRST.", "type" => "text"}],
            "id" => "input-#{turn_id}",
            "type" => "userMessage"
          }
        },
        %ThreadItem.AgentMessage{
          attrs: agent_attrs,
          id: item_id,
          status: "completed",
          text: "FIRST",
          type: "agentMessage"
        }
      ],
      status: "completed",
      thread_id: thread.id
    }

    assert {:ok, %TurnStream{} = stream} =
             TurnStream.start_request(client, thread.id, fn ->
               send(test_pid, {:request_task, self()})

               receive do
                 :continue -> {:ok, completed_turn}
               end
             end)

    assert_receive {:request_task, task_pid}

    send(
      stream.pid,
      {:codex_app_server_event,
       %GenericNotification{
         method: "item/started",
         params: %{
           "threadId" => thread.id,
           "turnId" => turn_id,
           "item" => %{"id" => item_id, "type" => "agentMessage", "status" => "inProgress"}
         }
       }}
    )

    send(
      stream.pid,
      {:codex_app_server_event,
       %GenericNotification{
         method: "item/agentMessage/delta",
         params: %{
           "threadId" => thread.id,
           "turnId" => turn_id,
           "itemId" => item_id,
           "delta" => "FIRST"
         }
       }}
    )

    send(task_pid, :continue)

    assert {:ok,
            %TurnStream{
              turn_id: ^turn_id,
              final_turn: %Turn{id: ^turn_id} = final_turn,
              final_text: "FIRST",
              items: items
            }} = TurnStream.wait(stream, 5_000)

    assert_turn_items_include_prompt_and_reply(
      final_turn.items,
      "Reply with the single word FIRST.",
      "FIRST"
    )

    assert_turn_items_include_prompt_and_reply(
      items,
      "Reply with the single word FIRST.",
      "FIRST"
    )

    assert %ThreadItem.AgentMessage{attrs: ^agent_attrs} =
             Enum.find(items, &(ThreadItem.type(&1) == "agentMessage"))
  end

  test "direct turn streams fail explicitly on replay gaps", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)
    test_pid = self()

    assert {:ok, %TurnStream{} = stream} =
             TurnStream.start_request(client, thread.id, fn ->
               send(test_pid, {:request_task, self()})

               receive do
                 :continue -> {:error, :stopped}
               end
             end)

    assert_receive {:request_task, _task_pid}

    send(client, {:codex_app_server_replay_gap, %{"missing_through_sequence" => 1}})

    assert {:error, {:transport_replay_gap, %{"missing_through_sequence" => 1}}} =
             TurnStream.wait(stream, 5_000)
  end

  test "observer turn streams stop and unsubscribe when their request completes", %{mock: mock} do
    client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})
    assert {:ok, %Thread{} = thread} = Client.start_thread(client)
    test_pid = self()

    turn = %Turn{
      error: nil,
      id: "turn-observer",
      items: [],
      status: "completed",
      thread_id: thread.id
    }

    assert {:ok, %TurnStream{} = stream} =
             TurnStream.start_request(
               client,
               thread.id,
               fn ->
                 send(test_pid, {:request_task, self()})

                 receive do
                   :continue -> {:ok, turn}
                 end
               end,
               false
             )

    assert_receive {:request_task, task_pid}
    stream_ref = Process.monitor(stream.pid)
    send(task_pid, :continue)

    assert_receive {:DOWN, ^stream_ref, :process, _pid, :normal}
    refute Map.has_key?(:sys.get_state(client).subscribers, stream.pid)
  end

  defp assert_turn_items_include_prompt_and_reply(items, prompt, reply) when is_list(items) do
    assert [
             %ThreadItem.Generic{type: "userMessage", attrs: attrs},
             %ThreadItem.AgentMessage{text: ^reply}
           ] = items

    assert get_in(attrs, ["content", Access.at(0), "text"]) == prompt
  end

  defp receive_event(expected_method, timeout \\ 1_000) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_receive_event(expected_method, deadline)
  end

  defp do_receive_event(expected_method, deadline) do
    remaining = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {:codex_app_server_event, message} ->
        if Message.method_name(message) == expected_method do
          message
        else
          do_receive_event(expected_method, deadline)
        end
    after
      remaining ->
        flunk("expected #{inspect(expected_method)} event")
    end
  end
end
