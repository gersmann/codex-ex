defmodule CodexEx.AppServer.Protocol.Generated.Shared.DynamicToolCallParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:arguments, :call_id, :namespace, :thread_id, :tool, :turn_id]

  @field_specs [
    %{spec: :plain, field: :arguments, required: true, wire_key: "arguments"},
    %{spec: :plain, field: :call_id, required: true, wire_key: "callId"},
    %{spec: {:nullable, :plain}, field: :namespace, required: false, wire_key: "namespace"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :tool, required: true, wire_key: "tool"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
