defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadStartParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :allow_provider_model_fallback,
    :approval_policy,
    :approvals_reviewer,
    :base_instructions,
    :config,
    :cwd,
    :developer_instructions,
    :dynamic_tools,
    :environments,
    :ephemeral,
    :experimental_raw_events,
    :history_mode,
    :mock_experimental_field,
    :model,
    :model_provider,
    :multi_agent_mode,
    :permissions,
    :personality,
    :runtime_workspace_roots,
    :sandbox,
    :selected_capability_roots,
    :service_name,
    :service_tier,
    :session_start_source,
    :thread_source
  ]

  @field_specs [
    %{
      spec: :plain,
      field: :allow_provider_model_fallback,
      required: false,
      wire_key: "allowProviderModelFallback"
    },
    %{
      spec: {:nullable, :plain},
      field: :approval_policy,
      required: false,
      wire_key: "approvalPolicy"
    },
    %{
      spec: {:nullable, :plain},
      field: :approvals_reviewer,
      required: false,
      wire_key: "approvalsReviewer"
    },
    %{
      spec: {:nullable, :plain},
      field: :base_instructions,
      required: false,
      wire_key: "baseInstructions"
    },
    %{spec: {:nullable, :plain}, field: :config, required: false, wire_key: "config"},
    %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
    %{
      spec: {:nullable, :plain},
      field: :developer_instructions,
      required: false,
      wire_key: "developerInstructions"
    },
    %{
      spec: {:nullable, {:array, :plain}},
      field: :dynamic_tools,
      required: false,
      wire_key: "dynamicTools"
    },
    %{
      spec: {:nullable, {:array, {:module, Module.concat(__MODULE__, "TurnEnvironmentParams")}}},
      field: :environments,
      required: false,
      wire_key: "environments"
    },
    %{spec: {:nullable, :plain}, field: :ephemeral, required: false, wire_key: "ephemeral"},
    %{
      spec: :plain,
      field: :experimental_raw_events,
      required: false,
      wire_key: "experimentalRawEvents"
    },
    %{spec: {:nullable, :plain}, field: :history_mode, required: false, wire_key: "historyMode"},
    %{
      spec: {:nullable, :plain},
      field: :mock_experimental_field,
      required: false,
      wire_key: "mockExperimentalField"
    },
    %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
    %{
      spec: {:nullable, :plain},
      field: :model_provider,
      required: false,
      wire_key: "modelProvider"
    },
    %{
      spec: {:nullable, :plain},
      field: :multi_agent_mode,
      required: false,
      wire_key: "multiAgentMode"
    },
    %{spec: {:nullable, :plain}, field: :permissions, required: false, wire_key: "permissions"},
    %{spec: {:nullable, :plain}, field: :personality, required: false, wire_key: "personality"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :runtime_workspace_roots,
      required: false,
      wire_key: "runtimeWorkspaceRoots"
    },
    %{spec: {:nullable, :plain}, field: :sandbox, required: false, wire_key: "sandbox"},
    %{
      spec: {:nullable, {:array, {:module, Module.concat(__MODULE__, "SelectedCapabilityRoot")}}},
      field: :selected_capability_roots,
      required: false,
      wire_key: "selectedCapabilityRoots"
    },
    %{spec: {:nullable, :plain}, field: :service_name, required: false, wire_key: "serviceName"},
    %{spec: {:nullable, :plain}, field: :service_tier, required: false, wire_key: "serviceTier"},
    %{
      spec: {:nullable, :plain},
      field: :session_start_source,
      required: false,
      wire_key: "sessionStartSource"
    },
    %{spec: {:nullable, :plain}, field: :thread_source, required: false, wire_key: "threadSource"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule SelectedCapabilityRoot do
    @moduledoc false

    defstruct [:id, :location]

    @field_specs [
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: :plain, field: :location, required: true, wire_key: "location"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule TurnEnvironmentParams do
    @moduledoc false

    defstruct [:cwd, :environment_id, :runtime_workspace_roots]

    @field_specs [
      %{spec: :plain, field: :cwd, required: true, wire_key: "cwd"},
      %{spec: :plain, field: :environment_id, required: true, wire_key: "environmentId"},
      %{
        spec: {:nullable, {:array, :plain}},
        field: :runtime_workspace_roots,
        required: false,
        wire_key: "runtimeWorkspaceRoots"
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
