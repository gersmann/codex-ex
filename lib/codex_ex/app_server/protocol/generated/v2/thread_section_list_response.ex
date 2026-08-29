defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadSectionListResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data, :next_cursor]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ThreadSection")}},
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

  defmodule ThreadSection do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.ThreadSectionListResponse, as: ParentModule

    defstruct [:appearance, :id, :name]

    @field_specs [
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ThreadSectionAppearance")}},
        field: :appearance,
        required: false,
        wire_key: "appearance"
      },
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ThreadSectionAppearance do
    @moduledoc false

    defstruct [:color, :icon]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :color, required: false, wire_key: "color"},
      %{spec: {:nullable, :plain}, field: :icon, required: false, wire_key: "icon"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
