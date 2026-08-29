defmodule CodexEx.AppServer.Protocol.Generated.V2.ExperimentalFeatureListResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data, :next_cursor]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ExperimentalFeature")}},
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

  defmodule ExperimentalFeature do
    @moduledoc false

    defstruct [
      :announcement,
      :default_enabled,
      :description,
      :display_name,
      :enabled,
      :name,
      :stage
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :announcement,
        required: false,
        wire_key: "announcement"
      },
      %{spec: :plain, field: :default_enabled, required: true, wire_key: "defaultEnabled"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{
        spec: {:nullable, :plain},
        field: :display_name,
        required: false,
        wire_key: "displayName"
      },
      %{spec: :plain, field: :enabled, required: true, wire_key: "enabled"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :stage, required: true, wire_key: "stage"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
