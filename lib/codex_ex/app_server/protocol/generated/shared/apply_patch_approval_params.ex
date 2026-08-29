defmodule CodexEx.AppServer.Protocol.Generated.Shared.ApplyPatchApprovalParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:call_id, :conversation_id, :file_changes, :grant_root, :reason]

  @field_specs [
    %{spec: :plain, field: :call_id, required: true, wire_key: "callId"},
    %{spec: :plain, field: :conversation_id, required: true, wire_key: "conversationId"},
    %{spec: :plain, field: :file_changes, required: true, wire_key: "fileChanges"},
    %{spec: {:nullable, :plain}, field: :grant_root, required: false, wire_key: "grantRoot"},
    %{spec: {:nullable, :plain}, field: :reason, required: false, wire_key: "reason"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
