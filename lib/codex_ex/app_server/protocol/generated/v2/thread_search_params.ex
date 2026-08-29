defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadSearchParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:archived, :cursor, :limit, :search_term, :sort_direction, :sort_key, :source_kinds]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :archived, required: false, wire_key: "archived"},
    %{spec: {:nullable, :plain}, field: :cursor, required: false, wire_key: "cursor"},
    %{spec: {:nullable, :plain}, field: :limit, required: false, wire_key: "limit"},
    %{spec: :plain, field: :search_term, required: true, wire_key: "searchTerm"},
    %{
      spec: {:nullable, :plain},
      field: :sort_direction,
      required: false,
      wire_key: "sortDirection"
    },
    %{spec: {:nullable, :plain}, field: :sort_key, required: false, wire_key: "sortKey"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :source_kinds,
      required: false,
      wire_key: "sourceKinds"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
