defmodule CodexEx.AppServer.Protocol.GeneratedTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerNotification
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerRequest
  alias CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputParams
  alias CodexEx.AppServer.Protocol.Generated.V1.InitializeParams
  alias CodexEx.AppServer.Protocol.Generated.V2.SkillsChangedNotification

  test "decode and encode round-trip nested initialize params" do
    payload = %{
      "clientInfo" => %{
        "name" => "app",
        "title" => "Automation",
        "version" => "1.0.0"
      },
      "capabilities" => %{
        "experimentalApi" => true,
        "optOutNotificationMethods" => ["turn/started"]
      }
    }

    assert %InitializeParams{
             capabilities: %InitializeParams.InitializeCapabilities{
               experimental_api: true,
               opt_out_notification_methods: ["turn/started"]
             },
             client_info: %InitializeParams.ClientInfo{
               name: "app",
               title: "Automation",
               version: "1.0.0"
             }
           } = decoded = InitializeParams.decode(payload)

    assert InitializeParams.encode(decoded) == payload
  end

  test "server request envelopes decode into typed params structs" do
    payload = %{
      "id" => "request-1",
      "method" => "item/tool/requestUserInput",
      "params" => %{
        "autoResolutionMs" => 60_000,
        "isBlocking" => true,
        "itemId" => "item-1",
        "questions" => [
          %{
            "header" => "Approve",
            "id" => "approve",
            "question" => "Continue?",
            "options" => [
              %{
                "description" => "Continue execution",
                "label" => "Yes"
              }
            ]
          }
        ],
        "threadId" => "thread-1",
        "turnId" => "turn-1"
      }
    }

    assert %ServerRequest{
             id: "request-1",
             method: "item/tool/requestUserInput",
             params: %ToolRequestUserInputParams{
               auto_resolution_ms: 60_000,
               is_blocking: true,
               item_id: "item-1",
               thread_id: "thread-1",
               turn_id: "turn-1",
               questions: [
                 %ToolRequestUserInputParams.ToolRequestUserInputQuestion{
                   header: "Approve",
                   id: "approve",
                   question: "Continue?",
                   options: [
                     %ToolRequestUserInputParams.ToolRequestUserInputOption{
                       description: "Continue execution",
                       label: "Yes"
                     }
                   ]
                 }
               ]
             }
           } = decoded = ServerRequest.decode(payload)

    assert ServerRequest.encode(decoded) == payload
  end

  test "server notification envelopes decode into typed notification structs" do
    payload = %{
      "method" => "skills/changed",
      "params" => %{}
    }

    assert %ServerNotification{
             id: nil,
             method: "skills/changed",
             params: %SkillsChangedNotification{}
           } = decoded = ServerNotification.decode(payload)

    assert ServerNotification.encode(decoded) == payload
  end
end
