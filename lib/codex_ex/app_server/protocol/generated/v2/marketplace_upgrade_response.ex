defmodule CodexEx.AppServer.Protocol.Generated.V2.MarketplaceUpgradeResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:errors, :selected_marketplaces, :upgraded_roots]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "MarketplaceUpgradeErrorInfo")}},
      field: :errors,
      required: true,
      wire_key: "errors"
    },
    %{
      spec: {:array, :plain},
      field: :selected_marketplaces,
      required: true,
      wire_key: "selectedMarketplaces"
    },
    %{spec: {:array, :plain}, field: :upgraded_roots, required: true, wire_key: "upgradedRoots"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule MarketplaceUpgradeErrorInfo do
    @moduledoc false

    defstruct [:marketplace_name, :message]

    @field_specs [
      %{spec: :plain, field: :marketplace_name, required: true, wire_key: "marketplaceName"},
      %{spec: :plain, field: :message, required: true, wire_key: "message"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
