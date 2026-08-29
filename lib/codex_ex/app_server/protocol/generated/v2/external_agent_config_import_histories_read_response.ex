defmodule CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigImportHistoriesReadResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:connectors, :data]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ExternalAgentImportedConnectorCandidate")}},
      field: :connectors,
      required: true,
      wire_key: "connectors"
    },
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ExternalAgentConfigImportHistory")}},
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

  defmodule ExternalAgentConfigImportHistory do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigImportHistoriesReadResponse,
      as: ParentModule

    defstruct [:completed_at_ms, :failures, :import_id, :provider_id, :successes]

    @field_specs [
      %{spec: :plain, field: :completed_at_ms, required: true, wire_key: "completedAtMs"},
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ExternalAgentConfigImportItemTypeFailure")}},
        field: :failures,
        required: true,
        wire_key: "failures"
      },
      %{spec: :plain, field: :import_id, required: true, wire_key: "importId"},
      %{spec: {:nullable, :plain}, field: :provider_id, required: false, wire_key: "providerId"},
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

  defmodule ExternalAgentImportedConnectorCandidate do
    @moduledoc false

    defstruct [:name, :session_count, :source]

    @field_specs [
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :session_count, required: true, wire_key: "sessionCount"},
      %{spec: :plain, field: :source, required: true, wire_key: "source"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
