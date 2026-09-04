defmodule CodexEx.AppServer.Protocol.Generated.Shared.CommandExecutionRequestApprovalParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.Shared.CommandExecutionRequestApprovalParams

  defstruct [
    :additional_permissions,
    :approval_id,
    :available_decisions,
    :command,
    :command_actions,
    :cwd,
    :environment_id,
    :item_id,
    :kind,
    :network_approval_context,
    :proposed_execpolicy_amendment,
    :proposed_network_policy_amendments,
    :reason,
    :started_at_ms,
    :thread_id,
    :turn_id
  ]

  @field_specs [
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "AdditionalPermissionProfile")}},
      field: :additional_permissions,
      required: false,
      wire_key: "additionalPermissions"
    },
    %{spec: {:nullable, :plain}, field: :approval_id, required: false, wire_key: "approvalId"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :available_decisions,
      required: false,
      wire_key: "availableDecisions"
    },
    %{spec: {:nullable, :plain}, field: :command, required: false, wire_key: "command"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :command_actions,
      required: false,
      wire_key: "commandActions"
    },
    %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
    %{
      spec: {:nullable, :plain},
      field: :environment_id,
      required: false,
      wire_key: "environmentId"
    },
    %{spec: :plain, field: :item_id, required: true, wire_key: "itemId"},
    %{spec: :plain, field: :kind, required: false, wire_key: "kind"},
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "NetworkApprovalContext")}},
      field: :network_approval_context,
      required: false,
      wire_key: "networkApprovalContext"
    },
    %{
      spec: {:nullable, {:array, :plain}},
      field: :proposed_execpolicy_amendment,
      required: false,
      wire_key: "proposedExecpolicyAmendment"
    },
    %{
      spec: {:nullable, {:array, {:module, Module.concat(__MODULE__, "NetworkPolicyAmendment")}}},
      field: :proposed_network_policy_amendments,
      required: false,
      wire_key: "proposedNetworkPolicyAmendments"
    },
    %{spec: {:nullable, :plain}, field: :reason, required: false, wire_key: "reason"},
    %{spec: :plain, field: :started_at_ms, required: true, wire_key: "startedAtMs"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule AdditionalFileSystemPermissions do
    @moduledoc false

    alias CommandExecutionRequestApprovalParams,
      as: ParentModule

    defstruct [:entries, :glob_scan_max_depth, :read, :write]

    @field_specs [
      %{
        spec: {:nullable, {:array, {:module, Module.concat(ParentModule, "FileSystemSandboxEntry")}}},
        field: :entries,
        required: false,
        wire_key: "entries"
      },
      %{
        spec: {:nullable, :plain},
        field: :glob_scan_max_depth,
        required: false,
        wire_key: "globScanMaxDepth"
      },
      %{spec: {:nullable, {:array, :plain}}, field: :read, required: false, wire_key: "read"},
      %{spec: {:nullable, {:array, :plain}}, field: :write, required: false, wire_key: "write"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule AdditionalNetworkPermissions do
    @moduledoc false

    defstruct [:enabled]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :enabled, required: false, wire_key: "enabled"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule AdditionalPermissionProfile do
    @moduledoc false

    alias CommandExecutionRequestApprovalParams,
      as: ParentModule

    defstruct [:file_system, :network]

    @field_specs [
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "AdditionalFileSystemPermissions")}},
        field: :file_system,
        required: false,
        wire_key: "fileSystem"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "AdditionalNetworkPermissions")}},
        field: :network,
        required: false,
        wire_key: "network"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule FileSystemSandboxEntry do
    @moduledoc false

    defstruct [:access, :path]

    @field_specs [
      %{spec: :plain, field: :access, required: true, wire_key: "access"},
      %{spec: :plain, field: :path, required: true, wire_key: "path"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule NetworkApprovalContext do
    @moduledoc false

    defstruct [:host, :protocol]

    @field_specs [
      %{spec: :plain, field: :host, required: true, wire_key: "host"},
      %{spec: :plain, field: :protocol, required: true, wire_key: "protocol"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule NetworkPolicyAmendment do
    @moduledoc false

    defstruct [:action, :host]

    @field_specs [
      %{spec: :plain, field: :action, required: true, wire_key: "action"},
      %{spec: :plain, field: :host, required: true, wire_key: "host"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
