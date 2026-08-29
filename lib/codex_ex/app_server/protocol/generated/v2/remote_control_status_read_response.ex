defmodule CodexEx.AppServer.Protocol.Generated.V2.RemoteControlStatusReadResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:environment_id, :installation_id, :server_name, :status]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :environment_id,
      required: false,
      wire_key: "environmentId"
    },
    %{spec: :plain, field: :installation_id, required: true, wire_key: "installationId"},
    %{spec: :plain, field: :server_name, required: true, wire_key: "serverName"},
    %{spec: :plain, field: :status, required: true, wire_key: "status"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
