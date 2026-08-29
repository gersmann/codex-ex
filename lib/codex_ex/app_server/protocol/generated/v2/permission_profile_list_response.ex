defmodule CodexEx.AppServer.Protocol.Generated.V2.PermissionProfileListResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data, :next_cursor]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "PermissionProfileSummary")}},
      field: :data,
      required: true,
      wire_key: "data"
    },
    %{spec: {:nullable, :plain}, field: :next_cursor, required: false, wire_key: "nextCursor"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule PermissionProfileSummary do
    @moduledoc false

    defstruct [:allowed, :description, :id]

    @field_specs [
      %{spec: :plain, field: :allowed, required: true, wire_key: "allowed"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
