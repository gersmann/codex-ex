defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadShellCommandParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:command, :thread_id]

  @field_specs [
    %{spec: :plain, field: :command, required: true, wire_key: "command"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
