defmodule CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigImportCompletedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:import_id, :item_type_results]

  @field_specs [
    %{spec: :plain, field: :import_id, required: true, wire_key: "importId"},
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ExternalAgentConfigImportTypeResult")}},
      field: :item_type_results,
      required: true,
      wire_key: "itemTypeResults"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ExternalAgentConfigImportItemTypeFailure do
    @moduledoc false

    defstruct [:cwd, :error_type, :failure_stage, :item_type, :message, :source, :sub_error_type]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
      %{spec: {:nullable, :plain}, field: :error_type, required: false, wire_key: "errorType"},
      %{spec: :plain, field: :failure_stage, required: true, wire_key: "failureStage"},
      %{spec: :plain, field: :item_type, required: true, wire_key: "itemType"},
      %{spec: :plain, field: :message, required: true, wire_key: "message"},
      %{spec: {:nullable, :plain}, field: :source, required: false, wire_key: "source"},
      %{
        spec: {:nullable, :plain},
        field: :sub_error_type,
        required: false,
        wire_key: "subErrorType"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ExternalAgentConfigImportItemTypeSuccess do
    @moduledoc false

    defstruct [:cwd, :item_type, :source, :target, :title]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
      %{spec: :plain, field: :item_type, required: true, wire_key: "itemType"},
      %{spec: {:nullable, :plain}, field: :source, required: false, wire_key: "source"},
      %{spec: {:nullable, :plain}, field: :target, required: false, wire_key: "target"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ExternalAgentConfigImportTypeResult do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigImportCompletedNotification,
      as: ParentModule

    defstruct [:failures, :item_type, :successes]

    @field_specs [
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ExternalAgentConfigImportItemTypeFailure")}},
        field: :failures,
        required: true,
        wire_key: "failures"
      },
      %{spec: :plain, field: :item_type, required: true, wire_key: "itemType"},
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ExternalAgentConfigImportItemTypeSuccess")}},
        field: :successes,
        required: true,
        wire_key: "successes"
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
