defmodule CodexEx.AppServer.Protocol.Generated.V2.ConfigWriteResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:file_path, :overridden_metadata, :status, :version]

  @field_specs [
    %{spec: :plain, field: :file_path, required: true, wire_key: "filePath"},
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "OverriddenMetadata")}},
      field: :overridden_metadata,
      required: false,
      wire_key: "overriddenMetadata"
    },
    %{spec: :plain, field: :status, required: true, wire_key: "status"},
    %{spec: :plain, field: :version, required: true, wire_key: "version"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ConfigLayerMetadata do
    @moduledoc false

    defstruct [:name, :version]

    @field_specs [
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :version, required: true, wire_key: "version"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule OverriddenMetadata do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.ConfigWriteResponse, as: ParentModule

    defstruct [:effective_value, :message, :overriding_layer]

    @field_specs [
      %{spec: :plain, field: :effective_value, required: true, wire_key: "effectiveValue"},
      %{spec: :plain, field: :message, required: true, wire_key: "message"},
      %{
        spec: {:module, Module.concat(ParentModule, "ConfigLayerMetadata")},
        field: :overriding_layer,
        required: true,
        wire_key: "overridingLayer"
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
