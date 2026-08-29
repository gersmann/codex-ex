defmodule CodexEx.AppServer.Protocol.Generated.Shared.JSONRPCResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:id, :result]

  @field_specs [
    %{spec: :plain, field: :id, required: true, wire_key: "id"},
    %{spec: :plain, field: :result, required: true, wire_key: "result"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
