defmodule CodexEx.AppServer.Protocol.Generated.V2.AgentMessageDeltaNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:delta, :item_id, :thread_id, :turn_id]

  @field_specs [
    %{spec: :plain, field: :delta, required: true, wire_key: "delta"},
    %{spec: :plain, field: :item_id, required: true, wire_key: "itemId"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
