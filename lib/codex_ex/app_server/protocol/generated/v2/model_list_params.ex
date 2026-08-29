defmodule CodexEx.AppServer.Protocol.Generated.V2.ModelListParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:cursor, :include_hidden, :limit]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :cursor, required: false, wire_key: "cursor"},
    %{
      spec: {:nullable, :plain},
      field: :include_hidden,
      required: false,
      wire_key: "includeHidden"
    },
    %{spec: {:nullable, :plain}, field: :limit, required: false, wire_key: "limit"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
