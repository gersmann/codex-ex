defmodule CodexEx.AppServer.Protocol.Generated.V2.PluginShareUpdateTargetsParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:discoverability, :remote_plugin_id, :share_targets]

  @field_specs [
    %{spec: :plain, field: :discoverability, required: true, wire_key: "discoverability"},
    %{spec: :plain, field: :remote_plugin_id, required: true, wire_key: "remotePluginId"},
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "PluginShareTarget")}},
      field: :share_targets,
      required: true,
      wire_key: "shareTargets"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule PluginShareTarget do
    @moduledoc false

    defstruct [:principal_id, :principal_type, :role]

    @field_specs [
      %{spec: :plain, field: :principal_id, required: true, wire_key: "principalId"},
      %{spec: :plain, field: :principal_type, required: true, wire_key: "principalType"},
      %{spec: :plain, field: :role, required: true, wire_key: "role"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
