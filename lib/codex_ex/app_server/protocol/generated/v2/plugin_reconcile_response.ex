defmodule CodexEx.AppServer.Protocol.Generated.V2.PluginReconcileResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :changed_plugins,
    :failed_materialization_remote_plugin_ids,
    :failed_remote_plugin_ids
  ]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "PluginReconcileChangedPlugin")}},
      field: :changed_plugins,
      required: true,
      wire_key: "changedPlugins"
    },
    %{
      spec: {:array, :plain},
      field: :failed_materialization_remote_plugin_ids,
      required: true,
      wire_key: "failedMaterializationRemotePluginIds"
    },
    %{
      spec: {:array, :plain},
      field: :failed_remote_plugin_ids,
      required: true,
      wire_key: "failedRemotePluginIds"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule PluginReconcileChangedPlugin do
    @moduledoc false

    defstruct [:has_apps, :has_hooks, :has_mcps, :has_skills, :id]

    @field_specs [
      %{spec: :plain, field: :has_apps, required: true, wire_key: "hasApps"},
      %{spec: :plain, field: :has_hooks, required: true, wire_key: "hasHooks"},
      %{spec: :plain, field: :has_mcps, required: true, wire_key: "hasMcps"},
      %{spec: :plain, field: :has_skills, required: true, wire_key: "hasSkills"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
