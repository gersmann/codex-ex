defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadTurnsListParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:cursor, :items_view, :limit, :sort_direction, :thread_id]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :cursor, required: false, wire_key: "cursor"},
    %{spec: {:nullable, :plain}, field: :items_view, required: false, wire_key: "itemsView"},
    %{spec: {:nullable, :plain}, field: :limit, required: false, wire_key: "limit"},
    %{
      spec: {:nullable, :plain},
      field: :sort_direction,
      required: false,
      wire_key: "sortDirection"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
