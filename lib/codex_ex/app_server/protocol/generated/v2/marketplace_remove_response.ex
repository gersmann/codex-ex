defmodule CodexEx.AppServer.Protocol.Generated.V2.MarketplaceRemoveResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:installed_root, :marketplace_name]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :installed_root,
      required: false,
      wire_key: "installedRoot"
    },
    %{spec: :plain, field: :marketplace_name, required: true, wire_key: "marketplaceName"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
