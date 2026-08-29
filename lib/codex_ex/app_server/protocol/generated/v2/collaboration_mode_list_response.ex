defmodule CodexEx.AppServer.Protocol.Generated.V2.CollaborationModeListResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "CollaborationModeMask")}},
      field: :data,
      required: true,
      wire_key: "data"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule CollaborationModeMask do
    @moduledoc false

    defstruct [:mode, :model, :name, :reasoning_effort]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :mode, required: false, wire_key: "mode"},
      %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{
        spec: {:nullable, {:nullable, :plain}},
        field: :reasoning_effort,
        required: false,
        wire_key: "reasoning_effort"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
