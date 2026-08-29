defmodule CodexEx.AppServer.Protocol.Generated.V2.McpServerToolCallResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:_meta, :content, :is_error, :structured_content]

  @field_specs [
    %{spec: :plain, field: :_meta, required: false, wire_key: "_meta"},
    %{spec: {:array, :plain}, field: :content, required: true, wire_key: "content"},
    %{spec: {:nullable, :plain}, field: :is_error, required: false, wire_key: "isError"},
    %{spec: :plain, field: :structured_content, required: false, wire_key: "structuredContent"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
