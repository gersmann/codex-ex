defmodule CodexEx.AppServer.Protocol.Generated.V2.ModelReroutedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:from_model, :reason, :thread_id, :to_model, :turn_id]

  @field_specs [
    %{spec: :plain, field: :from_model, required: true, wire_key: "fromModel"},
    %{spec: :plain, field: :reason, required: true, wire_key: "reason"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :to_model, required: true, wire_key: "toModel"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
