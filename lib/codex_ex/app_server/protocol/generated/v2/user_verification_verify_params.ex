defmodule CodexEx.AppServer.Protocol.Generated.V2.UserVerificationVerifyParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:challenge, :description, :title]

  @field_specs [
    %{spec: :plain, field: :challenge, required: true, wire_key: "challenge"},
    %{spec: :plain, field: :description, required: true, wire_key: "description"},
    %{spec: :plain, field: :title, required: true, wire_key: "title"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
