defmodule CodexEx.AppServer.WebSocketFrames do
  @moduledoc false

  @type action ::
          {:data, nonempty_binary()}
          | {:pong, binary()}
          | {:remote_close, non_neg_integer() | nil, binary() | nil}
          | {:decode_failed, term()}

  # Mint's opaque websocket type yields an identical inferred contract that Dialyzer
  # nevertheless reports as a subtype at this external boundary.
  @dialyzer {:nowarn_function, decode: 2}

  @spec text(binary()) :: {:text, binary()}
  def text(payload) when is_binary(payload), do: {:text, String.trim_trailing(payload, "\n")}

  @spec decode(Mint.WebSocket.t(), binary()) ::
          {Mint.WebSocket.t(),
           [
             {:data, nonempty_binary()}
             | {:decode_failed, term()}
             | {:pong, binary()}
             | {:remote_close, non_neg_integer() | nil, binary() | nil}
           ]}
  def decode(websocket, data) when is_binary(data) do
    case Mint.WebSocket.decode(websocket, data) do
      {:ok, websocket, frames} -> {websocket, actions(frames)}
      {:error, websocket, reason} -> {websocket, [{:decode_failed, reason}]}
    end
  end

  @spec actions([Mint.WebSocket.frame() | {:error, term()}]) :: [action()]
  defp actions([]), do: []

  defp actions([{kind, payload} | frames]) when kind in [:text, :binary] and is_binary(payload),
    do: [{:data, payload <> "\n"} | actions(frames)]

  defp actions([{:ping, payload} | frames]) when is_binary(payload), do: [{:pong, payload} | actions(frames)]

  defp actions([{:pong, _payload} | frames]), do: actions(frames)

  defp actions([{:close, code, reason} | _frames])
       when (is_integer(code) or is_nil(code)) and (is_binary(reason) or is_nil(reason)),
       do: [{:remote_close, code, reason}]

  defp actions([{:error, reason} | _frames]), do: [{:decode_failed, reason}]
end
