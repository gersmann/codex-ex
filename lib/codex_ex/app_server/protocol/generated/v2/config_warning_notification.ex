defmodule CodexEx.AppServer.Protocol.Generated.V2.ConfigWarningNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:details, :path, :range, :summary]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :details, required: false, wire_key: "details"},
    %{spec: {:nullable, :plain}, field: :path, required: false, wire_key: "path"},
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "TextRange")}},
      field: :range,
      required: false,
      wire_key: "range"
    },
    %{spec: :plain, field: :summary, required: true, wire_key: "summary"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule TextPosition do
    @moduledoc false

    defstruct [:column, :line]

    @field_specs [
      %{spec: :plain, field: :column, required: true, wire_key: "column"},
      %{spec: :plain, field: :line, required: true, wire_key: "line"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule TextRange do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.ConfigWarningNotification, as: ParentModule

    defstruct [:end, :start]

    @field_specs [
      %{
        spec: {:module, Module.concat(ParentModule, "TextPosition")},
        field: :end,
        required: true,
        wire_key: "end"
      },
      %{
        spec: {:module, Module.concat(ParentModule, "TextPosition")},
        field: :start,
        required: true,
        wire_key: "start"
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
