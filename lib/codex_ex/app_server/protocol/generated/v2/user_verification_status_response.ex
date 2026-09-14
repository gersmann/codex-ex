defmodule CodexEx.AppServer.Protocol.Generated.V2.UserVerificationStatusResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:credential_id, :unavailable_message, :unavailable_reason]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :credential_id,
      required: false,
      wire_key: "credentialId"
    },
    %{
      spec: {:nullable, :plain},
      field: :unavailable_message,
      required: false,
      wire_key: "unavailableMessage"
    },
    %{
      spec: {:nullable, :plain},
      field: :unavailable_reason,
      required: false,
      wire_key: "unavailableReason"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
