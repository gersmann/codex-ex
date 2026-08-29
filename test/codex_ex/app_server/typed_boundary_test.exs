defmodule CodexEx.AppServer.TypedBoundaryTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.Message
  alias CodexEx.AppServer.Protocol.Generated.Shared.ApplyPatchApprovalResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.CommandExecutionRequestApprovalResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.DynamicToolCallResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.ExecCommandApprovalResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.FileChangeRequestApprovalResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.McpServerElicitationRequestResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerNotification
  alias CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputResponse.ToolRequestUserInputAnswer
  alias CodexEx.AppServer.Protocol.GenericNotification
  alias CodexEx.AppServer.ThreadGoal
  alias CodexEx.AppServer.ThreadItem
  alias CodexEx.AppServer.ThreadSnapshot
  alias CodexEx.AppServer.TokenUsage
  alias CodexEx.AppServer.Turn

  test "message owns the supported server-request reply payload encoding" do
    payloads = [
      {%ToolRequestUserInputResponse{
         answers: %{"approve" => %ToolRequestUserInputAnswer{answers: ["yes"]}}
       }, %{"answers" => %{"approve" => %{"answers" => ["yes"]}}}},
      {%McpServerElicitationRequestResponse{action: "accept", content: %{"color" => "red"}},
       %{"action" => "accept", "content" => %{"color" => "red"}}},
      {%CommandExecutionRequestApprovalResponse{decision: "accept"}, %{"decision" => "accept"}},
      {%DynamicToolCallResponse{content_items: [], success: true}, %{"contentItems" => [], "success" => true}},
      {%ExecCommandApprovalResponse{decision: "accept"}, %{"decision" => "accept"}},
      {%FileChangeRequestApprovalResponse{decision: "accept"}, %{"decision" => "accept"}},
      {%ApplyPatchApprovalResponse{decision: "accept"}, %{"decision" => "accept"}}
    ]

    Enum.each(payloads, fn {payload, expected} ->
      assert Message.supported_reply_payload?(payload)
      assert Message.encode_reply_payload(payload) == {:ok, expected}
    end)

    refute Message.supported_reply_payload?(%{"answers" => %{}})

    assert Message.encode_reply_payload(%{"answers" => %{}}) ==
             {:error, {:unsupported_request_reply_payload, %{"answers" => %{}}}}

    raw_nested_answer = %ToolRequestUserInputResponse{
      answers: %{"approve" => %{"answers" => ["yes"]}}
    }

    refute Message.supported_reply_payload?(raw_nested_answer)

    assert Message.encode_reply_payload(raw_nested_answer) ==
             {:error, {:unsupported_request_reply_payload, raw_nested_answer}}
  end

  test "thread snapshots decode raw camelCase protocol maps into typed structs" do
    payload = %{
      "agentNickname" => "codex",
      "agentRole" => "assistant",
      "cliVersion" => "0.116.0",
      "createdAt" => 1_711_123_200,
      "cwd" => "/tmp/mock-codex",
      "ephemeral" => false,
      "gitInfo" => %{
        "branch" => "main",
        "originUrl" => "git@example.com/repo.git",
        "sha" => "abc123"
      },
      "historyMode" => "paginated",
      "id" => "thread-1",
      "modelProvider" => "openai",
      "name" => "Thread 1",
      "path" => nil,
      "preview" => "Preview",
      "source" => "appServer",
      "status" => "idle",
      "threadSource" => "subagent",
      "turns" => [
        %{
          "durationMs" => 123,
          "id" => "turn-1",
          "status" => "completed",
          "items" => [%{"id" => "item-1", "type" => "agentMessage", "text" => "OK"}]
        }
      ],
      "updatedAt" => 1_711_123_201
    }

    assert {:ok, %ThreadSnapshot{} = snapshot} = ThreadSnapshot.from_protocol(payload)
    assert snapshot.id == "thread-1"
    assert snapshot.history_mode == "paginated"
    assert snapshot.thread_source == "subagent"
    assert ThreadSnapshot.subagent?(snapshot)

    for source <- ~w(subAgent subAgentReview subAgentCompact subAgentThreadSpawn subAgentOther) do
      assert ThreadSnapshot.subagent?(%{snapshot | source: source, thread_source: nil})
    end

    assert snapshot.git_info.origin_url == "git@example.com/repo.git"

    assert [%Turn{duration_ms: 123, items: [%ThreadItem.AgentMessage{text: "OK"}]}] =
             snapshot.turns
  end

  test "thread snapshots normalize structured status payloads into a public string" do
    payload = %{
      "cliVersion" => "0.116.0",
      "createdAt" => 1_711_123_200,
      "cwd" => "/tmp/mock-codex",
      "ephemeral" => false,
      "gitInfo" => nil,
      "id" => "thread-1",
      "modelProvider" => "openai",
      "name" => "Thread 1",
      "path" => nil,
      "preview" => "Preview",
      "source" => "appServer",
      "status" => %{"type" => "idle"},
      "turns" => [],
      "updatedAt" => 1_711_123_201
    }

    assert {:ok, %ThreadSnapshot{history_mode: "legacy", status: "idle"}} =
             ThreadSnapshot.from_protocol(payload)
  end

  test "turn conversion returns an error tuple instead of raising on malformed payloads" do
    assert {:error, {:invalid_turn, {:missing_field, :id}}} =
             Turn.from_protocol(%{"status" => "completed", "items" => []}, "thread-1")
  end

  test "turn conversion skips malformed best-effort input payloads" do
    payload = %{
      "id" => "turn-1",
      "input" => %{"type" => "text", "text" => "not-a-list"},
      "items" => [%{"id" => "item-1", "type" => "agentMessage", "text" => "OK"}],
      "status" => "completed"
    }

    assert {:ok, %Turn{items: [%ThreadItem.AgentMessage{text: "OK"}]}} =
             Turn.from_protocol(payload, "thread-1")
  end

  test "message extractors return errors for malformed nested payloads and nil when absent" do
    malformed_turn_message = %GenericNotification{
      method: "turn/completed",
      params: %{"threadId" => "thread-1", "turn" => %{"status" => "completed", "items" => []}}
    }

    malformed_item_message = %GenericNotification{
      method: "item/completed",
      params: %{"threadId" => "thread-1", "turnId" => "turn-1", "item" => 123}
    }

    missing_item_message = %GenericNotification{
      method: "thread/started",
      params: %{"threadId" => "thread-1"}
    }

    assert {:error, {:invalid_turn, {:missing_field, :id}}} =
             Message.extract_turn(malformed_turn_message)

    assert {:error, {:invalid_thread_item, {:unexpected_payload, 123}}} =
             Message.extract_item(malformed_item_message)

    assert nil == Message.extract_item(missing_item_message)
  end

  test "message extracts turns from raw notification params so best-effort input survives there too" do
    message = %GenericNotification{
      method: "turn/started",
      params: %{
        "threadId" => "thread-1",
        "turn" => %{
          "id" => "turn-1",
          "input" => [%{"type" => "text", "text" => "Hello"}],
          "items" => [%{"id" => "item-1", "type" => "agentMessage", "text" => "OK"}],
          "status" => "completed"
        }
      }
    }

    assert {:ok,
            %Turn{
              items: [
                %ThreadItem.Generic{type: "userMessage", attrs: attrs},
                %ThreadItem.AgentMessage{text: "OK"}
              ]
            }} = Message.extract_turn(message)

    assert get_in(attrs, ["content", Access.at(0), "text"]) == "Hello"
  end

  test "thread items reject present payloads without a type and keep generic fallback for unknown typed items" do
    assert {:error, {:invalid_thread_item, {:missing_field, :type}}} =
             ThreadItem.from_protocol(%{"id" => "item-1"})

    assert {:error, {:invalid_thread_item, {:invalid_field, :type, 123}}} =
             ThreadItem.from_protocol(%{"id" => "item-1", "type" => 123})

    assert {:ok, %ThreadItem.Generic{id: "item-2", type: "toolResult", attrs: attrs}} =
             ThreadItem.from_protocol(%{"id" => "item-2", "type" => "toolResult", "foo" => "bar"})

    assert attrs["foo"] == "bar"
  end

  test "message extracts typed token-usage updates and preserves malformed ones as errors" do
    valid_message = %ServerNotification{
      method: "thread/tokenUsage/updated",
      params: %{
        thread_id: "thread-1",
        turn_id: "turn-1",
        token_usage: %{
          modelContextWindow: 200_000,
          last: %{
            cachedInputTokens: 1,
            inputTokens: 2,
            outputTokens: 3,
            reasoningOutputTokens: 4,
            totalTokens: 10
          },
          total: %{
            cachedInputTokens: 5,
            inputTokens: 6,
            outputTokens: 7,
            reasoningOutputTokens: 8,
            totalTokens: 26
          }
        }
      }
    }

    invalid_message = %ServerNotification{
      method: "thread/tokenUsage/updated",
      params: %{
        thread_id: "thread-1",
        turn_id: "turn-1",
        token_usage: %{
          last: %{
            cachedInputTokens: 1,
            inputTokens: 2,
            outputTokens: 3,
            reasoningOutputTokens: 4,
            totalTokens: 10
          },
          total: %{
            cachedInputTokens: 5,
            inputTokens: 6,
            outputTokens: 7,
            reasoningOutputTokens: 8,
            totalTokens: 26
          },
          modelContextWindow: "huge"
        }
      }
    }

    assert {:ok, %TokenUsage{} = usage} = Message.extract_token_usage(valid_message)
    assert usage.total.total_tokens == 26

    assert {:error, {:invalid_token_usage, {:invalid_field, :model_context_window, "huge"}}} =
             Message.extract_token_usage(invalid_message)
  end

  test "message extracts typed thread goal updates and reports malformed goal payloads" do
    valid_message = %ServerNotification{
      method: "thread/goal/updated",
      params: %{
        thread_id: "thread-1",
        goal: %{
          "createdAt" => 1_711_123_200,
          "objective" => "Keep the goal visible",
          "status" => "active",
          "threadId" => "thread-1",
          "timeUsedSeconds" => 0,
          "tokenBudget" => nil,
          "tokensUsed" => 0,
          "updatedAt" => 1_711_123_201
        }
      }
    }

    invalid_message = %ServerNotification{
      method: "thread/goal/updated",
      params: %{thread_id: "thread-1", goal: %{objective: "Missing fields"}}
    }

    assert {:ok, %ThreadGoal{objective: "Keep the goal visible", status: :active}} =
             Message.extract_thread_goal(valid_message)

    assert {:error, {:invalid_thread_goal, {:missing_field, :created_at}}} =
             Message.extract_thread_goal(invalid_message)
  end
end
