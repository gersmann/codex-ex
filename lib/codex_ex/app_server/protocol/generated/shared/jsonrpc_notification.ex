defmodule CodexEx.AppServer.Protocol.Generated.Shared.JSONRPCNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:method, :params]

  @field_specs [
    %{spec: :plain, field: :method, required: true, wire_key: "method"},
    %{spec: :plain, field: :params, required: false, wire_key: "params"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
