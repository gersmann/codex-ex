defmodule CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:cancellation_token, :query, :roots]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :cancellation_token,
      required: false,
      wire_key: "cancellationToken"
    },
    %{spec: :plain, field: :query, required: true, wire_key: "query"},
    %{spec: {:array, :plain}, field: :roots, required: true, wire_key: "roots"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
