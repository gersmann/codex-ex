defmodule CodexEx.AppServer.Protocol.Generated.V2.ConfigValueWriteParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:expected_version, :file_path, :key_path, :merge_strategy, :value]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :expected_version,
      required: false,
      wire_key: "expectedVersion"
    },
    %{spec: {:nullable, :plain}, field: :file_path, required: false, wire_key: "filePath"},
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
