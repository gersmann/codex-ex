defmodule CodexEx.AppServer.Protocol.Generated.V2.ServerDiagnosticsResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:gauges, :process]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ServerDiagnosticsGauge")}},
      field: :gauges,
      required: true,
      wire_key: "gauges"
    },
    %{
      spec: {:module, Module.concat(__MODULE__, "ServerDiagnosticsProcess")},
      field: :process,
      required: true,
      wire_key: "process"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ServerDiagnosticsGauge do
    @moduledoc false

    defstruct [:name, :value]

    @field_specs [
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :value, required: true, wire_key: "value"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ServerDiagnosticsProcess do
    @moduledoc false

    defstruct [:id, :physical_footprint_bytes, :resident_memory_bytes]

    @field_specs [
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{
        spec: {:nullable, :plain},
        field: :physical_footprint_bytes,
        required: false,
        wire_key: "physicalFootprintBytes"
      },
      %{
        spec: {:nullable, :plain},
        field: :resident_memory_bytes,
        required: false,
        wire_key: "residentMemoryBytes"
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
