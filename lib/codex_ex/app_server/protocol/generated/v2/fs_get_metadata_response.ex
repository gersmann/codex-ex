defmodule CodexEx.AppServer.Protocol.Generated.V2.FsGetMetadataResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:created_at_ms, :is_directory, :is_file, :is_symlink, :modified_at_ms]

  @field_specs [
    %{spec: :plain, field: :created_at_ms, required: true, wire_key: "createdAtMs"},
    %{spec: :plain, field: :is_directory, required: true, wire_key: "isDirectory"},
    %{spec: :plain, field: :is_file, required: true, wire_key: "isFile"},
    %{spec: :plain, field: :is_symlink, required: true, wire_key: "isSymlink"},
    %{spec: :plain, field: :modified_at_ms, required: true, wire_key: "modifiedAtMs"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
