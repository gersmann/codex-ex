defmodule CodexEx.AppServer.Protocol.Generated.V2.FsWatchParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:path, :watch_id]

  @field_specs [
    %{spec: :plain, field: :path, required: true, wire_key: "path"},
    %{spec: :plain, field: :watch_id, required: true, wire_key: "watchId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
