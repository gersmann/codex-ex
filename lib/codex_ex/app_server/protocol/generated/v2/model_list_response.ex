defmodule CodexEx.AppServer.Protocol.Generated.V2.ModelListResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data, :next_cursor]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "Model")}},
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

  defmodule Model do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.ModelListResponse, as: ParentModule

    defstruct [
      :additional_speed_tiers,
      :availability_nux,
      :default_reasoning_effort,
      :default_service_tier,
      :description,
      :display_name,
      :hidden,
      :id,
      :input_modalities,
      :is_default,
      :model,
      :model_specialty,
      :multi_agent_version,
      :service_tiers,
      :supported_reasoning_efforts,
      :supports_personality,
      :upgrade,
      :upgrade_info
    ]

    @field_specs [
      %{
        spec: {:array, :plain},
        field: :additional_speed_tiers,
        required: false,
        wire_key: "additionalSpeedTiers"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ModelAvailabilityNux")}},
        field: :availability_nux,
        required: false,
        wire_key: "availabilityNux"
      },
      %{
        spec: :plain,
        field: :default_reasoning_effort,
        required: true,
        wire_key: "defaultReasoningEffort"
      },
      %{
        spec: {:nullable, :plain},
        field: :default_service_tier,
        required: false,
        wire_key: "defaultServiceTier"
      },
      %{spec: :plain, field: :description, required: true, wire_key: "description"},
      %{spec: :plain, field: :display_name, required: true, wire_key: "displayName"},
      %{spec: :plain, field: :hidden, required: true, wire_key: "hidden"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{
        spec: {:array, :plain},
        field: :input_modalities,
        required: false,
        wire_key: "inputModalities"
      },
      %{spec: :plain, field: :is_default, required: true, wire_key: "isDefault"},
      %{spec: :plain, field: :model, required: true, wire_key: "model"},
      %{
        spec: {:nullable, :plain},
        field: :model_specialty,
        required: false,
        wire_key: "modelSpecialty"
      },
      %{
        spec: {:nullable, :plain},
        field: :multi_agent_version,
        required: false,
        wire_key: "multiAgentVersion"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ModelServiceTier")}},
        field: :service_tiers,
        required: false,
        wire_key: "serviceTiers"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ReasoningEffortOption")}},
        field: :supported_reasoning_efforts,
        required: true,
        wire_key: "supportedReasoningEfforts"
      },
      %{
        spec: :plain,
        field: :supports_personality,
        required: false,
        wire_key: "supportsPersonality"
      },
      %{spec: {:nullable, :plain}, field: :upgrade, required: false, wire_key: "upgrade"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ModelUpgradeInfo")}},
        field: :upgrade_info,
        required: false,
        wire_key: "upgradeInfo"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ModelAvailabilityNux do
    @moduledoc false

    defstruct [:message]

    @field_specs [%{spec: :plain, field: :message, required: true, wire_key: "message"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ModelServiceTier do
    @moduledoc false

    defstruct [:description, :id, :name]

    @field_specs [
      %{spec: :plain, field: :description, required: true, wire_key: "description"},
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

  defmodule ModelUpgradeInfo do
    @moduledoc false

    defstruct [:migration_markdown, :model, :model_link, :retirement_at, :upgrade_copy]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :migration_markdown,
        required: false,
        wire_key: "migrationMarkdown"
      },
      %{spec: :plain, field: :model, required: true, wire_key: "model"},
      %{spec: {:nullable, :plain}, field: :model_link, required: false, wire_key: "modelLink"},
      %{
        spec: {:nullable, :plain},
        field: :retirement_at,
        required: false,
        wire_key: "retirementAt"
      },
      %{spec: {:nullable, :plain}, field: :upgrade_copy, required: false, wire_key: "upgradeCopy"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ReasoningEffortOption do
    @moduledoc false

    defstruct [:description, :reasoning_effort]

    @field_specs [
      %{spec: :plain, field: :description, required: true, wire_key: "description"},
      %{spec: :plain, field: :reasoning_effort, required: true, wire_key: "reasoningEffort"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
