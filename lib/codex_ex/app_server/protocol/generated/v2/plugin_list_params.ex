defmodule CodexEx.AppServer.Protocol.Generated.V2.PluginListParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:cwds, :force_refetch, :marketplace_kinds]

  @field_specs [
    %{spec: {:nullable, {:array, :plain}}, field: :cwds, required: false, wire_key: "cwds"},
    %{spec: :plain, field: :force_refetch, required: false, wire_key: "forceRefetch"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :marketplace_kinds,
      required: false,
      wire_key: "marketplaceKinds"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
