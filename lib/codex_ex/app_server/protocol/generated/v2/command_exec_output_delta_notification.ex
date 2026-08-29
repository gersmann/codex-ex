defmodule CodexEx.AppServer.Protocol.Generated.V2.CommandExecOutputDeltaNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:cap_reached, :delta_base64, :process_id, :stream]

  @field_specs [
    %{spec: :plain, field: :cap_reached, required: true, wire_key: "capReached"},
    %{spec: :plain, field: :delta_base64, required: true, wire_key: "deltaBase64"},
    %{spec: :plain, field: :process_id, required: true, wire_key: "processId"},
    %{spec: :plain, field: :stream, required: true, wire_key: "stream"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
