defmodule CodexEx.AppServer.Protocol.Generated.V2.McpServerStatusUpdatedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:error, :failure_reason, :name, :status, :thread_id]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :error, required: false, wire_key: "error"},
    %{
      spec: {:nullable, :plain},
      field: :failure_reason,
      required: false,
      wire_key: "failureReason"
    },
    %{spec: :plain, field: :name, required: true, wire_key: "name"},
    %{spec: :plain, field: :status, required: true, wire_key: "status"},
    %{spec: {:nullable, :plain}, field: :thread_id, required: false, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
