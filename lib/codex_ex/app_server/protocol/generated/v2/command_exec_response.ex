defmodule CodexEx.AppServer.Protocol.Generated.V2.CommandExecResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:exit_code, :stderr, :stdout]

  @field_specs [
    %{spec: :plain, field: :exit_code, required: true, wire_key: "exitCode"},
    %{spec: :plain, field: :stderr, required: true, wire_key: "stderr"},
    %{spec: :plain, field: :stdout, required: true, wire_key: "stdout"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
