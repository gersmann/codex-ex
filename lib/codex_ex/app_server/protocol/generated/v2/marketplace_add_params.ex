defmodule CodexEx.AppServer.Protocol.Generated.V2.MarketplaceAddParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:ref_name, :source, :sparse_paths]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :ref_name, required: false, wire_key: "refName"},
    %{spec: :plain, field: :source, required: true, wire_key: "source"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :sparse_paths,
      required: false,
      wire_key: "sparsePaths"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
