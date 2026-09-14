defmodule CodexEx.AppServer.Protocol.GeneratedTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.Protocol.Generated.Shared.ClientRequest
  alias CodexEx.AppServer.Protocol.Generated.Shared.McpServerElicitationRequestParams
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerNotification
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerRequest
  alias CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputParams
  alias CodexEx.AppServer.Protocol.Generated.V1.InitializeParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ConfigRequirementsReadResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.GetAccountRateLimitsResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ListMcpServerStatusResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.NullableGetAccountRateLimitsParams
  alias CodexEx.AppServer.Protocol.Generated.V2.NullableGetAccountTokenUsageParams
  alias CodexEx.AppServer.Protocol.Generated.V2.SkillsChangedNotification
  alias CodexEx.AppServer.Protocol.Generated.V2.UserVerificationDeleteParams
  alias CodexEx.AppServer.Protocol.Generated.V2.UserVerificationEnrollParams
  alias CodexEx.AppServer.Protocol.Generated.V2.UserVerificationStatusParams
  alias CodexEx.AppServer.Protocol.Generated.V2.UserVerificationVerifyParams

  test "nullable quota requests retain typed capabilities including false" do
    for supports_reserve? <- [true, false] do
      payload = %{
        "id" => 1,
        "method" => "account/rateLimits/read",
        "params" => %{
          "supportsLunaReserve" => supports_reserve?,
          "excludeResetCreditDetails" => false
        }
      }

      assert %ClientRequest{
               params: %NullableGetAccountRateLimitsParams{
                 supports_luna_reserve: ^supports_reserve?,
                 exclude_reset_credit_details: false
               }
             } = decoded = ClientRequest.decode(payload)

      assert ClientRequest.encode(decoded) == payload
    end
  end

  test "nullable params accept empty objects, explicit null, and omitted values" do
    payload = %{"id" => 1, "method" => "account/rateLimits/read", "params" => %{}}
    assert %ClientRequest{params: %NullableGetAccountRateLimitsParams{}} = decoded = ClientRequest.decode(payload)
    assert ClientRequest.encode(decoded) == payload

    for nullable_payload <- [Map.put(payload, "params", nil), Map.delete(payload, "params")] do
      assert %ClientRequest{params: nil} = decoded = ClientRequest.decode(nullable_payload)
      assert ClientRequest.encode(decoded) == Map.put(payload, "params", nil)
    end

    assert NullableGetAccountRateLimitsParams.decode(nil) == nil
    assert NullableGetAccountRateLimitsParams.encode(nil) == nil
  end

  test "nullable typing applies to existing token usage params too" do
    payload = %{
      "id" => 2,
      "method" => "account/usage/read",
      "params" => %{"threadId" => "thread-1"}
    }

    assert %ClientRequest{params: %NullableGetAccountTokenUsageParams{thread_id: "thread-1"}} =
             decoded = ClientRequest.decode(payload)

    assert ClientRequest.encode(decoded) == payload
  end

  test "direct-reference and parameterless client requests keep their behavior" do
    payload = %{
      "id" => 3,
      "method" => "initialize",
      "params" => %{"clientInfo" => %{"name" => "app", "version" => "1"}}
    }

    assert %ClientRequest{params: %InitializeParams{}} = decoded = ClientRequest.decode(payload)
    assert ClientRequest.encode(decoded) == payload

    logout = %{"id" => 4, "method" => "account/logout"}
    assert %ClientRequest{params: nil} = decoded = ClientRequest.decode(logout)
    assert ClientRequest.encode(decoded) == logout
  end

  test "quota responses preserve ordinary usage and normal model metadata" do
    payload = %{
      "ordinaryUsageAllowed" => false,
      "rateLimits" => %{"normalModelSlug" => "gpt-6-astra"}
    }

    assert %GetAccountRateLimitsResponse{
             ordinary_usage_allowed: false,
             rate_limits: %GetAccountRateLimitsResponse.RateLimitSnapshot{normal_model_slug: "gpt-6-astra"}
           } = decoded = GetAccountRateLimitsResponse.decode(payload)

    assert GetAccountRateLimitsResponse.encode(decoded) == payload
  end

  test "verification RPC dispatch and elicitation retain their protocol fields" do
    verify_params = %{"challenge" => "audit-challenge", "title" => "Verify", "description" => "Confirm identity"}

    for {method, params, module} <- [
          {"userVerification/enroll", %{}, UserVerificationEnrollParams},
          {"userVerification/status", %{}, UserVerificationStatusParams},
          {"userVerification/delete", %{}, UserVerificationDeleteParams},
          {"userVerification/verify", verify_params, UserVerificationVerifyParams}
        ] do
      payload = %{"id" => 5, "method" => method, "params" => params}
      assert ClientRequest.known_method?(method)
      assert %ClientRequest{params: %{__struct__: ^module}} = decoded = ClientRequest.decode(payload)
      assert ClientRequest.encode(decoded) == payload
    end

    elicitation = %{
      "id" => 6,
      "method" => "mcpServer/elicitation/request",
      "params" =>
        Map.merge(verify_params, %{
          "mode" => "openai/userVerification",
          "serverName" => "test-server",
          "threadId" => "thread-1"
        })
    }

    assert %ServerRequest{
             params: %McpServerElicitationRequestParams{
               mode: "openai/userVerification",
               challenge: "audit-challenge",
               title: "Verify",
               description: "Confirm identity"
             }
           } = decoded = ServerRequest.decode(elicitation)

    assert ServerRequest.encode(decoded) == elicitation
  end

  test "MCP diagnostics and application/browser requirements survive typed decoding" do
    status = %{
      "data" => [
        %{
          "name" => "test-server",
          "authStatus" => "unsupported",
          "resourceTemplates" => [],
          "resources" => [],
          "tools" => %{},
          "toolsError" => "Tool discovery failed"
        }
      ]
    }

    assert %ListMcpServerStatusResponse{
             data: [%ListMcpServerStatusResponse.McpServerStatus{tools_error: "Tool discovery failed"}]
           } = decoded_status = ListMcpServerStatusResponse.decode(status)

    assert ListMcpServerStatusResponse.encode(decoded_status) == status

    requirements = %{
      "requirements" => %{
        "application" => %{"network" => %{"domains" => %{}, "enabled" => false}},
        "browserUse" => %{"allowWebmcp" => false}
      }
    }

    assert %ConfigRequirementsReadResponse{
             requirements: %ConfigRequirementsReadResponse.ConfigRequirements{
               application: %ConfigRequirementsReadResponse.ApplicationRequirements{
                 network: %ConfigRequirementsReadResponse.ApplicationNetworkRequirements{enabled: false}
               },
               browser_use: %ConfigRequirementsReadResponse.BrowserUseRequirements{allow_webmcp: false}
             }
           } = decoded_requirements = ConfigRequirementsReadResponse.decode(requirements)

    assert ConfigRequirementsReadResponse.encode(decoded_requirements) == requirements
  end

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
