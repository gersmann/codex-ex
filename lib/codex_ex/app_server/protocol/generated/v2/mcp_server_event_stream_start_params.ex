defmodule CodexEx.AppServer.Protocol.Generated.V2.McpServerEventStreamStartParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:_meta, :arguments, :name, :server, :subscription_id, :thread_id]

  @field_specs [
    %{spec: :plain, field: :_meta, required: false, wire_key: "_meta"},
    %{spec: :plain, field: :arguments, required: true, wire_key: "arguments"},
    %{spec: :plain, field: :name, required: true, wire_key: "name"},
    %{spec: :plain, field: :server, required: true, wire_key: "server"},
    %{spec: :plain, field: :subscription_id, required: true, wire_key: "subscriptionId"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
