defmodule CodexEx.AppServer.Protocol.Generated.V2.PluginShareCheckoutResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :marketplace_name,
    :marketplace_path,
    :plugin_id,
    :plugin_name,
    :plugin_path,
    :remote_plugin_id,
    :remote_version
  ]

  @field_specs [
    %{spec: :plain, field: :marketplace_name, required: true, wire_key: "marketplaceName"},
    %{spec: :plain, field: :marketplace_path, required: true, wire_key: "marketplacePath"},
    %{spec: :plain, field: :plugin_id, required: true, wire_key: "pluginId"},
    %{spec: :plain, field: :plugin_name, required: true, wire_key: "pluginName"},
    %{spec: :plain, field: :plugin_path, required: true, wire_key: "pluginPath"},
    %{spec: :plain, field: :remote_plugin_id, required: true, wire_key: "remotePluginId"},
    %{
      spec: {:nullable, :plain},
      field: :remote_version,
      required: false,
      wire_key: "remoteVersion"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
