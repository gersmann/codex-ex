defmodule CodexEx.AppServer.Protocol.Generated.V2.ConfigBatchWriteParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:edits, :expected_version, :file_path, :reload_user_config]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ConfigEdit")}},
      field: :edits,
      required: true,
      wire_key: "edits"
    },
    %{
      spec: {:nullable, :plain},
      field: :expected_version,
      required: false,
      wire_key: "expectedVersion"
    },
    %{spec: {:nullable, :plain}, field: :file_path, required: false, wire_key: "filePath"},
    %{spec: :plain, field: :reload_user_config, required: false, wire_key: "reloadUserConfig"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ConfigEdit do
    @moduledoc false

    defstruct [:key_path, :merge_strategy, :value]

    @field_specs [
      %{spec: :plain, field: :key_path, required: true, wire_key: "keyPath"},
      %{spec: :plain, field: :merge_strategy, required: true, wire_key: "mergeStrategy"},
      %{spec: :plain, field: :value, required: true, wire_key: "value"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
