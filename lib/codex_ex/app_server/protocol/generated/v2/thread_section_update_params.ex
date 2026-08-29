defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadSectionUpdateParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:appearance, :name, :section_id]

  @field_specs [
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "ThreadSectionAppearance")}},
      field: :appearance,
      required: false,
      wire_key: "appearance"
    },
    %{spec: :plain, field: :name, required: true, wire_key: "name"},
    %{spec: :plain, field: :section_id, required: true, wire_key: "sectionId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

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
