defmodule CodexEx.AppServer.Protocol.Generated.V2.RemoteControlPairingStatusParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:manual_pairing_code, :pairing_code]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :manual_pairing_code,
      required: false,
      wire_key: "manualPairingCode"
    },
    %{spec: {:nullable, :plain}, field: :pairing_code, required: false, wire_key: "pairingCode"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
