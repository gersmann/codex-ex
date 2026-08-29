defmodule CodexEx.AppServer.Protocol.Generated.V2.RawResponseItemCompletedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:item, :thread_id, :turn_id]

  @field_specs [
    %{spec: :plain, field: :item, required: true, wire_key: "item"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule InternalChatMessageMetadataPassthrough do
    @moduledoc false

    defstruct [:turn_id]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :turn_id, required: false, wire_key: "turn_id"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
