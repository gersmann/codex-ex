defmodule CodexEx.AppServer.Protocol.Generated.V2.MarketplaceRemoveParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:marketplace_name]

  @field_specs [
    %{spec: :plain, field: :marketplace_name, required: true, wire_key: "marketplaceName"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
