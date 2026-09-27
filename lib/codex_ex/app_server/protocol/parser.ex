defmodule CodexEx.AppServer.Protocol.Parser do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerNotification
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerRequest
  alias CodexEx.AppServer.Protocol.GenericNotification
  alias CodexEx.AppServer.Protocol.GenericServerRequest

  @type parsed_message ::
          %ServerNotification{}
          | %ServerRequest{}
          | %GenericNotification{}
          | %GenericServerRequest{}

  @type parse_error :: {:unsupported_message_kind, atom()}

  @spec parse(atom(), map()) :: {:ok, parsed_message()} | {:error, parse_error()}
  def parse(kind, payload) when is_map(payload) do
    case kind do
      :notification -> parse_notification(payload)
      :request -> parse_request(payload)
      other -> {:error, {:unsupported_message_kind, other}}
    end
  end

  @spec parse_notification(map()) :: {:ok, parsed_message()}
  def parse_notification(%{"method" => method} = payload) when is_binary(method) do
    if ServerNotification.known_method?(method) do
      {:ok, ServerNotification.decode(payload)}
    else
      {:ok,
       %GenericNotification{
         method: method,
         params: Map.get(payload, "params")
       }}
    end
  end

  def parse_notification(payload) do
    {:ok, %GenericNotification{method: Map.get(payload, "method"), params: Map.get(payload, "params")}}
  end

  @spec parse_request(map()) :: {:ok, parsed_message()}
  def parse_request(%{"method" => method} = payload) when is_binary(method) do
    if ServerRequest.known_method?(method) do
      {:ok, ServerRequest.decode(payload)}
    else
      {:ok,
       %GenericServerRequest{
         id: Map.get(payload, "id"),
         method: method,
         params: Map.get(payload, "params")
       }}
    end
  end

  def parse_request(payload) do
    {:ok,
     %GenericServerRequest{
       id: Map.get(payload, "id"),
       method: Map.get(payload, "method"),
       params: Map.get(payload, "params")
     }}
  end
end
