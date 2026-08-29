defmodule CodexEx.AppServer.Protocol.Generated.V2.TurnStartParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.TurnStartParams

  defstruct [
    :additional_context,
    :approval_policy,
    :approvals_reviewer,
    :client_user_message_id,
    :collaboration_mode,
    :cwd,
    :effort,
    :environments,
    :input,
    :model,
    :multi_agent_mode,
    :output_schema,
    :permissions,
    :personality,
    :responsesapi_client_metadata,
    :runtime_workspace_roots,
    :sandbox_policy,
    :service_tier,
    :summary,
    :thread_id
  ]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :additional_context,
      required: false,
      wire_key: "additionalContext"
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
      field: :client_user_message_id,
      required: false,
      wire_key: "clientUserMessageId"
    },
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "CollaborationMode")}},
      field: :collaboration_mode,
      required: false,
      wire_key: "collaborationMode"
    },
    %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
    %{spec: {:nullable, :plain}, field: :effort, required: false, wire_key: "effort"},
    %{
      spec: {:nullable, {:array, {:module, Module.concat(__MODULE__, "TurnEnvironmentParams")}}},
      field: :environments,
      required: false,
      wire_key: "environments"
    },
    %{spec: {:array, :plain}, field: :input, required: true, wire_key: "input"},
    %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
    %{
      spec: {:nullable, :plain},
      field: :multi_agent_mode,
      required: false,
      wire_key: "multiAgentMode"
    },
    %{spec: :plain, field: :output_schema, required: false, wire_key: "outputSchema"},
    %{spec: {:nullable, :plain}, field: :permissions, required: false, wire_key: "permissions"},
    %{spec: {:nullable, :plain}, field: :personality, required: false, wire_key: "personality"},
    %{
      spec: {:nullable, :plain},
      field: :responsesapi_client_metadata,
      required: false,
      wire_key: "responsesapiClientMetadata"
    },
    %{
      spec: {:nullable, {:array, :plain}},
      field: :runtime_workspace_roots,
      required: false,
      wire_key: "runtimeWorkspaceRoots"
    },
    %{
      spec: {:nullable, :plain},
      field: :sandbox_policy,
      required: false,
      wire_key: "sandboxPolicy"
    },
    %{spec: {:nullable, :plain}, field: :service_tier, required: false, wire_key: "serviceTier"},
    %{spec: {:nullable, :plain}, field: :summary, required: false, wire_key: "summary"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule AdditionalContextEntry do
    @moduledoc false

    defstruct [:kind, :value]

    @field_specs [
      %{spec: :plain, field: :kind, required: true, wire_key: "kind"},
      %{spec: :plain, field: :value, required: true, wire_key: "value"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ByteRange do
    @moduledoc false

    defstruct [:end, :start]

    @field_specs [
      %{spec: :plain, field: :end, required: true, wire_key: "end"},
      %{spec: :plain, field: :start, required: true, wire_key: "start"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule CollaborationMode do
    @moduledoc false

    alias TurnStartParams, as: ParentModule

    defstruct [:mode, :settings]

    @field_specs [
      %{spec: :plain, field: :mode, required: true, wire_key: "mode"},
      %{
        spec: {:module, Module.concat(ParentModule, "Settings")},
        field: :settings,
        required: true,
        wire_key: "settings"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule Settings do
    @moduledoc false

    defstruct [:developer_instructions, :model, :reasoning_effort]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :developer_instructions,
        required: false,
        wire_key: "developer_instructions"
      },
      %{spec: :plain, field: :model, required: true, wire_key: "model"},
      %{
        spec: {:nullable, :plain},
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

  defmodule TextElement do
    @moduledoc false

    alias TurnStartParams, as: ParentModule

    defstruct [:byte_range, :placeholder]

    @field_specs [
      %{
        spec: {:module, Module.concat(ParentModule, "ByteRange")},
        field: :byte_range,
        required: true,
        wire_key: "byteRange"
      },
      %{spec: {:nullable, :plain}, field: :placeholder, required: false, wire_key: "placeholder"}
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
