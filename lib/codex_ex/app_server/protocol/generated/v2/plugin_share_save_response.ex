defmodule CodexEx.AppServer.Protocol.Generated.V2.PluginShareSaveResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:can_publish_to_workspace, :remote_plugin_id, :share_url]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :can_publish_to_workspace,
      required: false,
      wire_key: "canPublishToWorkspace"
    },
    %{spec: :plain, field: :remote_plugin_id, required: true, wire_key: "remotePluginId"},
    %{spec: :plain, field: :share_url, required: true, wire_key: "shareUrl"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
