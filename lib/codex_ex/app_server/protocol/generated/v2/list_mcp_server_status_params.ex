defmodule CodexEx.AppServer.Protocol.Generated.V2.ListMcpServerStatusParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:cursor, :detail, :limit, :thread_id]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :cursor, required: false, wire_key: "cursor"},
    %{spec: {:nullable, :plain}, field: :detail, required: false, wire_key: "detail"},
    %{spec: {:nullable, :plain}, field: :limit, required: false, wire_key: "limit"},
    %{spec: {:nullable, :plain}, field: :thread_id, required: false, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
