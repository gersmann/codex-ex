defmodule CodexEx.AppServer.Protocol.Generated.V2.FsGetMetadataParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:path]

  @field_specs [%{spec: :plain, field: :path, required: true, wire_key: "path"}]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
