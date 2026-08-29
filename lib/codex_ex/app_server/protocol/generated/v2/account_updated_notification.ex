defmodule CodexEx.AppServer.Protocol.Generated.V2.AccountUpdatedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:auth_mode, :plan_type]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :auth_mode, required: false, wire_key: "authMode"},
    %{spec: {:nullable, :plain}, field: :plan_type, required: false, wire_key: "planType"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
