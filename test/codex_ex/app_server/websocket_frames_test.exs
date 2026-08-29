defmodule CodexEx.AppServer.WebSocketFramesTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.WebSocketFrames

  test "decodes transport actions in order and stops at close" do
    data =
      frame(0x1, "text") <>
        frame(0x2, "binary") <>
        frame(0x9, "ping") <>
        frame(0xA, "ignored") <>
        frame(0x8, <<1_000::16, "done">>) <>
        frame(0x1, "after-close")

    {_websocket, actions} = WebSocketFrames.decode(struct(Mint.WebSocket), data)

    assert actions == [
             {:data, "text\n"},
             {:data, "binary\n"},
             {:pong, "ping"},
             {:remote_close, 1_000, "done"}
           ]
  end

  test "turns invalid frames into one terminal decode action" do
    {_websocket, actions} = WebSocketFrames.decode(struct(Mint.WebSocket), frame(0x3, ""))

    assert [{:decode_failed, _reason}] = actions
  end

  defp frame(opcode, payload) when byte_size(payload) <= 125 do
    <<1::1, 0::3, opcode::4, 0::1, byte_size(payload)::7, payload::binary>>
  end
end
