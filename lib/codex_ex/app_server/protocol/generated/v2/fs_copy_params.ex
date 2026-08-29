defmodule CodexEx.AppServer.Protocol.Generated.V2.FsCopyParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:destination_path, :recursive, :source_path]

  @field_specs [
    %{spec: :plain, field: :destination_path, required: true, wire_key: "destinationPath"},
    %{spec: :plain, field: :recursive, required: false, wire_key: "recursive"},
    %{spec: :plain, field: :source_path, required: true, wire_key: "sourcePath"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
