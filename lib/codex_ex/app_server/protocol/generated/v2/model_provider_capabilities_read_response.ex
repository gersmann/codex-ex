defmodule CodexEx.AppServer.Protocol.Generated.V2.ModelProviderCapabilitiesReadResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:image_generation, :namespace_tools, :web_search]

  @field_specs [
    %{spec: :plain, field: :image_generation, required: true, wire_key: "imageGeneration"},
    %{spec: :plain, field: :namespace_tools, required: true, wire_key: "namespaceTools"},
    %{spec: :plain, field: :web_search, required: true, wire_key: "webSearch"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
