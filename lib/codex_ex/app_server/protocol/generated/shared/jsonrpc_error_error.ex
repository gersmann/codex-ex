defmodule CodexEx.AppServer.Protocol.Generated.Shared.JSONRPCErrorError do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:code, :data, :message]

  @field_specs [
    %{spec: :plain, field: :code, required: true, wire_key: "code"},
    %{spec: :plain, field: :data, required: false, wire_key: "data"},
    %{spec: :plain, field: :message, required: true, wire_key: "message"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
