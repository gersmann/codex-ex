defmodule CodexEx.AppServer.Protocol.Generated.V2.McpResourceReadParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:connector_id, :origin_call_id, :server, :thread_id, :uri]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :connector_id, required: false, wire_key: "connectorId"},
    %{
      spec: {:nullable, :plain},
      field: :origin_call_id,
      required: false,
      wire_key: "originCallId"
    },
    %{spec: :plain, field: :server, required: true, wire_key: "server"},
    %{spec: {:nullable, :plain}, field: :thread_id, required: false, wire_key: "threadId"},
    %{spec: :plain, field: :uri, required: true, wire_key: "uri"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
