defmodule CodexEx.AppServer.Protocol.Generated.V2.PluginInstallParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:install_attempt_id, :marketplace_path, :plugin_name, :remote_marketplace_name]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :install_attempt_id,
      required: false,
      wire_key: "installAttemptId"
    },
    %{
      spec: {:nullable, :plain},
      field: :marketplace_path,
      required: false,
      wire_key: "marketplacePath"
    },
    %{spec: :plain, field: :plugin_name, required: true, wire_key: "pluginName"},
    %{
      spec: {:nullable, :plain},
      field: :remote_marketplace_name,
      required: false,
      wire_key: "remoteMarketplaceName"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
