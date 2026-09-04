defmodule CodexEx.AppServer.Protocol.Generated.V2.BedrockDiscoverResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:environment_credentials, :profiles]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "BedrockEnvironmentCredential")}},
      field: :environment_credentials,
      required: true,
      wire_key: "environmentCredentials"
    },
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "BedrockAwsProfile")}},
      field: :profiles,
      required: true,
      wire_key: "profiles"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule BedrockAwsProfile do
    @moduledoc false

    defstruct [:name, :region]

    @field_specs [
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: {:nullable, :plain}, field: :region, required: false, wire_key: "region"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule BedrockEnvironmentCredential do
    @moduledoc false

    defstruct [:region, :type]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :region, required: false, wire_key: "region"},
      %{spec: :plain, field: :type, required: true, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
