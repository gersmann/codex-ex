defmodule CodexEx.AppServer.Protocol.Generated.Shared.FileChangeRequestApprovalParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:grant_root, :item_id, :reason, :started_at_ms, :thread_id, :turn_id]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :grant_root, required: false, wire_key: "grantRoot"},
    %{spec: :plain, field: :item_id, required: true, wire_key: "itemId"},
    %{spec: {:nullable, :plain}, field: :reason, required: false, wire_key: "reason"},
    %{spec: :plain, field: :started_at_ms, required: true, wire_key: "startedAtMs"},
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
