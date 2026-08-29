defmodule CodexEx.AppServer.Protocol.Generated.V2.RemoteControlPairingStartResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:environment_id, :expires_at, :manual_pairing_code, :pairing_code]

  @field_specs [
    %{spec: :plain, field: :environment_id, required: true, wire_key: "environmentId"},
    %{spec: :plain, field: :expires_at, required: true, wire_key: "expiresAt"},
    %{
      spec: {:nullable, :plain},
      field: :manual_pairing_code,
      required: false,
      wire_key: "manualPairingCode"
    },
    %{spec: :plain, field: :pairing_code, required: true, wire_key: "pairingCode"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
