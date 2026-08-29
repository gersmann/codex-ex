defmodule CodexEx.AppServer.Protocol.Generated.Shared.ExecCommandApprovalParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:approval_id, :call_id, :command, :conversation_id, :cwd, :parsed_cmd, :reason]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :approval_id, required: false, wire_key: "approvalId"},
    %{spec: :plain, field: :call_id, required: true, wire_key: "callId"},
    %{spec: {:array, :plain}, field: :command, required: true, wire_key: "command"},
    %{spec: :plain, field: :conversation_id, required: true, wire_key: "conversationId"},
    %{spec: :plain, field: :cwd, required: true, wire_key: "cwd"},
    %{spec: {:array, :plain}, field: :parsed_cmd, required: true, wire_key: "parsedCmd"},
    %{spec: {:nullable, :plain}, field: :reason, required: false, wire_key: "reason"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
