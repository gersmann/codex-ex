defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadForkParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :approval_policy,
    :approvals_reviewer,
    :base_instructions,
    :before_turn_id,
    :config,
    :cwd,
    :defer_goal_continuation,
    :developer_instructions,
    :ephemeral,
    :exclude_turns,
    :last_turn_id,
    :model,
    :model_provider,
    :path,
    :permissions,
    :runtime_workspace_roots,
    :sandbox,
    :service_tier,
    :thread_id,
    :thread_source
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
      spec: {:nullable, :plain},
      field: :base_instructions,
      required: false,
      wire_key: "baseInstructions"
    },
    %{
      spec: {:nullable, :plain},
      field: :before_turn_id,
      required: false,
      wire_key: "beforeTurnId"
    },
    %{spec: {:nullable, :plain}, field: :config, required: false, wire_key: "config"},
    %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
    %{
      spec: :plain,
      field: :defer_goal_continuation,
      required: false,
      wire_key: "deferGoalContinuation"
    },
    %{
      spec: {:nullable, :plain},
      field: :developer_instructions,
      required: false,
      wire_key: "developerInstructions"
    },
    %{spec: :plain, field: :ephemeral, required: false, wire_key: "ephemeral"},
    %{spec: :plain, field: :exclude_turns, required: false, wire_key: "excludeTurns"},
    %{spec: {:nullable, :plain}, field: :last_turn_id, required: false, wire_key: "lastTurnId"},
    %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
    %{
      spec: {:nullable, :plain},
      field: :model_provider,
      required: false,
      wire_key: "modelProvider"
    },
    %{spec: {:nullable, :plain}, field: :path, required: false, wire_key: "path"},
    %{spec: {:nullable, :plain}, field: :permissions, required: false, wire_key: "permissions"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :runtime_workspace_roots,
      required: false,
      wire_key: "runtimeWorkspaceRoots"
    },
    %{spec: {:nullable, :plain}, field: :sandbox, required: false, wire_key: "sandbox"},
    %{spec: {:nullable, :plain}, field: :service_tier, required: false, wire_key: "serviceTier"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: {:nullable, :plain}, field: :thread_source, required: false, wire_key: "threadSource"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
