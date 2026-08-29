defmodule CodexEx.AppServer.Protocol.Generated.V2.McpResourceReadResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:contents]

  @field_specs [%{spec: {:array, :plain}, field: :contents, required: true, wire_key: "contents"}]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
