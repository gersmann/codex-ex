defmodule CodexEx.AppServer.Protocol.Generated.V2.McpServerToolCallParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:_meta, :arguments, :server, :thread_id, :tool]

  @field_specs [
    %{spec: :plain, field: :_meta, required: false, wire_key: "_meta"},
    %{spec: :plain, field: :arguments, required: false, wire_key: "arguments"},
    %{spec: :plain, field: :server, required: true, wire_key: "server"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :tool, required: true, wire_key: "tool"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
