defmodule CodexEx.AppServer.Protocol.Generated.V2.PluginInstalledParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:cwds, :install_suggestion_plugin_names]

  @field_specs [
    %{spec: {:nullable, {:array, :plain}}, field: :cwds, required: false, wire_key: "cwds"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :install_suggestion_plugin_names,
      required: false,
      wire_key: "installSuggestionPluginNames"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
