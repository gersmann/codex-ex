defmodule CodexEx.AppServer.Protocol.ParserTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerNotification
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerRequest
  alias CodexEx.AppServer.Protocol.Generated.V2.TurnStartedNotification
  alias CodexEx.AppServer.Protocol.GenericNotification
  alias CodexEx.AppServer.Protocol.GenericServerRequest
  alias CodexEx.AppServer.Protocol.Parser

  test "parses known server notifications into typed envelopes" do
    payload = %{
      "method" => "turn/started",
      "params" => %{
        "threadId" => "thread-1",
        "turn" => %{
          "id" => "turn-1",
          "input" => [%{"type" => "text", "text" => "hello"}],
          "items" => [],
          "status" => "in_progress"
        }
      }
    }

    assert {:ok,
            %ServerNotification{
              method: "turn/started",
              params: %TurnStartedNotification{
                thread_id: "thread-1",
                turn: %TurnStartedNotification.Turn{id: "turn-1"}
              }
            }} =
             Parser.parse(:notification, payload)
  end

  test "falls back to generic envelopes for unknown methods when strict mode is off" do
    payload = %{"id" => "request-1", "method" => "custom/request", "params" => %{"value" => 1}}

    assert {:ok,
            %GenericServerRequest{
              id: "request-1",
              method: "custom/request",
              params: %{"value" => 1}
            }} =
             Parser.parse(:request, payload, strict_protocol: false)
  end

  test "returns an error for unknown methods when strict mode is on" do
    payload = %{"method" => "custom/notification", "params" => %{}}

    assert {:error, {:unknown_method, :notification, "custom/notification"}} =
             Parser.parse(:notification, payload, strict_protocol: true)
  end

  test "parses known server requests into typed envelopes" do
    payload = %{
      "id" => "request-1",
      "method" => "item/tool/requestUserInput",
      "params" => %{
        "itemId" => "item-1",
        "questions" => [],
        "threadId" => "thread-1",
        "turnId" => "turn-1"
      }
    }

    assert {:ok, %ServerRequest{id: "request-1", method: "item/tool/requestUserInput"}} =
             Parser.parse(:request, payload)
  end

  test "falls back to generic notifications for unknown methods when strict mode is off" do
    payload = %{"method" => "custom/notification", "params" => %{"value" => 1}}

    assert {:ok, %GenericNotification{method: "custom/notification", params: %{"value" => 1}}} =
             Parser.parse(:notification, payload, strict_protocol: false)
  end
end
