defmodule CodexEx.AppServer.Protocol.Generated.V2.CommandExecWriteParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:close_stdin, :delta_base64, :process_id]

  @field_specs [
    %{spec: :plain, field: :close_stdin, required: false, wire_key: "closeStdin"},
    %{spec: {:nullable, :plain}, field: :delta_base64, required: false, wire_key: "deltaBase64"},
    %{spec: :plain, field: :process_id, required: true, wire_key: "processId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
