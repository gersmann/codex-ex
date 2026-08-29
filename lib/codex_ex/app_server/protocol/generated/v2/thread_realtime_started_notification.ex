defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeStartedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:realtime_session_id, :thread_id, :version]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :realtime_session_id,
      required: false,
      wire_key: "realtimeSessionId"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :version, required: true, wire_key: "version"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
