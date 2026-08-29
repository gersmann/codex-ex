defmodule CodexEx.AppServer.Protocol.Generated.V2.FsWriteFileParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data_base64, :path]

  @field_specs [
    %{spec: :plain, field: :data_base64, required: true, wire_key: "dataBase64"},
    %{spec: :plain, field: :path, required: true, wire_key: "path"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
