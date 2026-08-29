defmodule CodexEx.AppServer.Protocol.Generated.V2.GetAccountResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:account, :requires_openai_auth]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :account, required: false, wire_key: "account"},
    %{spec: :plain, field: :requires_openai_auth, required: true, wire_key: "requiresOpenaiAuth"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
