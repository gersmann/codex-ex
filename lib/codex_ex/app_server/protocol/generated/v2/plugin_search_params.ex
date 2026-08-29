defmodule CodexEx.AppServer.Protocol.Generated.V2.PluginSearchParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:cursor, :cwds, :limit, :scope, :search_term]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :cursor, required: false, wire_key: "cursor"},
    %{spec: {:nullable, {:array, :plain}}, field: :cwds, required: false, wire_key: "cwds"},
    %{spec: {:nullable, :plain}, field: :limit, required: false, wire_key: "limit"},
    %{spec: {:nullable, :plain}, field: :scope, required: false, wire_key: "scope"},
    %{spec: :plain, field: :search_term, required: true, wire_key: "searchTerm"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
