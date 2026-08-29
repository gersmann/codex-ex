defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadSectionMoveParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:before_thread_id, :section_id, :thread_id]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :before_thread_id,
      required: false,
      wire_key: "beforeThreadId"
    },
    %{spec: {:nullable, :plain}, field: :section_id, required: true, wire_key: "sectionId"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
