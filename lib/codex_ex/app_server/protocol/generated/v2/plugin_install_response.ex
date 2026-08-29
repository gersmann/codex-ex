defmodule CodexEx.AppServer.Protocol.Generated.V2.PluginInstallResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:apps_needing_auth, :auth_policy]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "AppSummary")}},
      field: :apps_needing_auth,
      required: true,
      wire_key: "appsNeedingAuth"
    },
    %{spec: :plain, field: :auth_policy, required: true, wire_key: "authPolicy"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule AppSummary do
    @moduledoc false

    defstruct [:category, :description, :id, :install_url, :name]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :category, required: false, wire_key: "category"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: {:nullable, :plain}, field: :install_url, required: false, wire_key: "installUrl"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
