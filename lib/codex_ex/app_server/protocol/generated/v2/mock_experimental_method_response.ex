defmodule CodexEx.AppServer.Protocol.Generated.V2.MockExperimentalMethodResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:echoed]

  @field_specs [%{spec: {:nullable, :plain}, field: :echoed, required: false, wire_key: "echoed"}]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
