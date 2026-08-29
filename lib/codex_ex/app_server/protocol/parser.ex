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

  @type parse_error ::
          {:unsupported_message_kind, atom()}
          | {:unknown_method, :notification | :request, binary() | nil}

  @spec parse(atom(), map(), keyword()) :: {:ok, parsed_message()} | {:error, parse_error()}
  def parse(kind, payload, opts \\ []) when is_map(payload) and is_list(opts) do
    strict? = Keyword.get(opts, :strict_protocol, false)

    case kind do
      :notification -> parse_notification(payload, strict?)
      :request -> parse_request(payload, strict?)
      other -> {:error, {:unsupported_message_kind, other}}
    end
  end

  @spec parse_notification(map(), boolean()) :: {:ok, parsed_message()} | {:error, parse_error()}
  def parse_notification(%{"method" => method} = payload, strict?) when is_binary(method) do
    cond do
      ServerNotification.known_method?(method) ->
        {:ok, ServerNotification.decode(payload)}

      strict? ->
        {:error, {:unknown_method, :notification, method}}

      true ->
        {:ok,
         %GenericNotification{
           method: method,
           params: Map.get(payload, "params")
         }}
    end
  end

  def parse_notification(payload, _strict?) do
    {:ok, %GenericNotification{method: Map.get(payload, "method"), params: Map.get(payload, "params")}}
  end

  @spec parse_request(map(), boolean()) :: {:ok, parsed_message()} | {:error, parse_error()}
  def parse_request(%{"method" => method} = payload, strict?) when is_binary(method) do
    cond do
      ServerRequest.known_method?(method) ->
        {:ok, ServerRequest.decode(payload)}

      strict? ->
        {:error, {:unknown_method, :request, method}}

      true ->
        {:ok,
         %GenericServerRequest{
           id: Map.get(payload, "id"),
           method: method,
           params: Map.get(payload, "params")
         }}
    end
  end

  def parse_request(payload, _strict?) do
    {:ok,
     %GenericServerRequest{
       id: Map.get(payload, "id"),
       method: Map.get(payload, "method"),
       params: Map.get(payload, "params")
     }}
  end
end
