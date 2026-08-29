defmodule CodexEx.AppServer.Protocol.Generated.V2.EnvironmentAddParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:connect_timeout_ms, :environment_id, :exec_server_url]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :connect_timeout_ms,
      required: false,
      wire_key: "connectTimeoutMs"
    },
    %{spec: :plain, field: :environment_id, required: true, wire_key: "environmentId"},
    %{spec: :plain, field: :exec_server_url, required: true, wire_key: "execServerUrl"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
