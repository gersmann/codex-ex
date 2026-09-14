defmodule CodexEx.AppServer.Protocol.Generated.V2.UserVerificationVerifyResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:proof]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "UserVerificationProof")},
      field: :proof,
      required: true,
      wire_key: "proof"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule UserVerificationProof do
    @moduledoc false

    defstruct [:credential_id, :signature]

    @field_specs [
      %{spec: :plain, field: :credential_id, required: true, wire_key: "credentialId"},
      %{spec: :plain, field: :signature, required: true, wire_key: "signature"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
