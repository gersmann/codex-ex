defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadSettingsUpdatedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadSettingsUpdatedNotification

  defstruct [:thread_id, :thread_settings]

  @field_specs [
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{
      spec: {:module, Module.concat(__MODULE__, "ThreadSettings")},
      field: :thread_settings,
      required: true,
      wire_key: "threadSettings"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ActivePermissionProfile do
    @moduledoc false

    defstruct [:extends, :id]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :extends, required: false, wire_key: "extends"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"}
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

    alias ThreadSettingsUpdatedNotification,
      as: ParentModule

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

  defmodule ThreadSettings do
    @moduledoc false

    alias ThreadSettingsUpdatedNotification,
      as: ParentModule

    defstruct [
      :active_permission_profile,
      :approval_policy,
      :approvals_reviewer,
      :collaboration_mode,
      :cwd,
      :effort,
      :model,
      :model_provider,
      :multi_agent_mode,
      :personality,
      :sandbox_policy,
      :service_tier,
      :summary
    ]

    @field_specs [
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ActivePermissionProfile")}},
        field: :active_permission_profile,
        required: false,
        wire_key: "activePermissionProfile"
      },
      %{spec: :plain, field: :approval_policy, required: true, wire_key: "approvalPolicy"},
      %{spec: :plain, field: :approvals_reviewer, required: true, wire_key: "approvalsReviewer"},
      %{
        spec: {:module, Module.concat(ParentModule, "CollaborationMode")},
        field: :collaboration_mode,
        required: true,
        wire_key: "collaborationMode"
      },
      %{spec: :plain, field: :cwd, required: true, wire_key: "cwd"},
      %{spec: {:nullable, :plain}, field: :effort, required: false, wire_key: "effort"},
      %{spec: :plain, field: :model, required: true, wire_key: "model"},
      %{spec: :plain, field: :model_provider, required: true, wire_key: "modelProvider"},
      %{spec: :plain, field: :multi_agent_mode, required: false, wire_key: "multiAgentMode"},
      %{spec: {:nullable, :plain}, field: :personality, required: false, wire_key: "personality"},
      %{spec: :plain, field: :sandbox_policy, required: true, wire_key: "sandboxPolicy"},
      %{
        spec: {:nullable, :plain},
        field: :service_tier,
        required: false,
        wire_key: "serviceTier"
      },
      %{spec: {:nullable, :plain}, field: :summary, required: false, wire_key: "summary"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
