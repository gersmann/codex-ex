defmodule CodexEx.AppServer.Protocol.Generated.V2.AppsReadParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:app_ids, :include_tools, :thread_id]

  @field_specs [
    %{spec: {:array, :plain}, field: :app_ids, required: true, wire_key: "appIds"},
    %{spec: :plain, field: :include_tools, required: false, wire_key: "includeTools"},
    %{spec: {:nullable, :plain}, field: :thread_id, required: false, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
