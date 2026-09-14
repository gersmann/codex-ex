defmodule CodexEx.AppServer.Protocol.Generated.V2.NullableGetAccountRateLimitsParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:exclude_reset_credit_details, :supports_luna_reserve]

  @field_specs [
    %{
      spec: :plain,
      field: :exclude_reset_credit_details,
      required: false,
      wire_key: "excludeResetCreditDetails"
    },
    %{
      spec: :plain,
      field: :supports_luna_reserve,
      required: false,
      wire_key: "supportsLunaReserve"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
