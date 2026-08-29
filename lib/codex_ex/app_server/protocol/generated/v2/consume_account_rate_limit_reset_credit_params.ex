defmodule CodexEx.AppServer.Protocol.Generated.V2.ConsumeAccountRateLimitResetCreditParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:credit_id, :idempotency_key]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :credit_id, required: false, wire_key: "creditId"},
    %{spec: :plain, field: :idempotency_key, required: true, wire_key: "idempotencyKey"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
