defmodule CodexEx.AppServer.Protocol.Generated.V2.AppsInstalledResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:apps]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "InstalledApp")}},
      field: :apps,
      required: true,
      wire_key: "apps"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule InstalledApp do
    @moduledoc false

    defstruct [:callable, :enabled, :id, :runtime_name]

    @field_specs [
      %{spec: :plain, field: :callable, required: true, wire_key: "callable"},
      %{spec: :plain, field: :enabled, required: true, wire_key: "enabled"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: {:nullable, :plain}, field: :runtime_name, required: false, wire_key: "runtimeName"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
