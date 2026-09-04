defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeItemStartedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:item, :thread_id]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "ThreadRealtimeItem")},
      field: :item,
      required: true,
      wire_key: "item"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ThreadRealtimeItem do
    @moduledoc false

    defstruct [
      :id,
      :item_id,
      :outcome,
      :presentation,
      :realtime_session_id,
      :role,
      :text,
      :turn_id,
      :type
    ]

    @field_specs [
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: :plain, field: :item_id, required: false, wire_key: "item_id"},
      %{spec: :plain, field: :outcome, required: false, wire_key: "outcome"},
      %{spec: :plain, field: :presentation, required: false, wire_key: "presentation"},
      %{spec: :plain, field: :realtime_session_id, required: true, wire_key: "realtimeSessionId"},
      %{spec: :plain, field: :role, required: false, wire_key: "role"},
      %{spec: :plain, field: :text, required: false, wire_key: "text"},
      %{spec: :plain, field: :turn_id, required: false, wire_key: "turn_id"},
      %{spec: :plain, field: :type, required: false, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
