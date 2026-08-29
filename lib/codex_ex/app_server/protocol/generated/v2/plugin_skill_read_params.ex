defmodule CodexEx.AppServer.Protocol.Generated.V2.PluginSkillReadParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:remote_marketplace_name, :remote_plugin_id, :skill_name]

  @field_specs [
    %{
      spec: :plain,
      field: :remote_marketplace_name,
      required: true,
      wire_key: "remoteMarketplaceName"
    },
    %{spec: :plain, field: :remote_plugin_id, required: true, wire_key: "remotePluginId"},
    %{spec: :plain, field: :skill_name, required: true, wire_key: "skillName"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
