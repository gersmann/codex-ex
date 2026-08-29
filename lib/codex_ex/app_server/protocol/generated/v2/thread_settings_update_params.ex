defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadSettingsUpdateParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :approval_policy,
    :approvals_reviewer,
    :collaboration_mode,
    :cwd,
    :effort,
    :model,
    :multi_agent_mode,
    :permissions,
    :personality,
    :sandbox_policy,
    :service_tier,
    :summary,
    :thread_id
  ]

  @field_specs [
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
      spec: {:nullable, {:module, Module.concat(__MODULE__, "CollaborationMode")}},
      field: :collaboration_mode,
      required: false,
      wire_key: "collaborationMode"
    },
    %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
    %{spec: {:nullable, :plain}, field: :effort, required: false, wire_key: "effort"},
    %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
    %{
      spec: {:nullable, :plain},
      field: :multi_agent_mode,
      required: false,
      wire_key: "multiAgentMode"
    },
    %{spec: {:nullable, :plain}, field: :permissions, required: false, wire_key: "permissions"},
    %{spec: {:nullable, :plain}, field: :personality, required: false, wire_key: "personality"},
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

  defmodule CollaborationMode do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.ThreadSettingsUpdateParams, as: ParentModule

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
end
