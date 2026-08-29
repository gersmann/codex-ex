defmodule CodexEx.AppServer.Protocol.Generated.V2.ItemGuardianApprovalReviewCompletedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.ItemGuardianApprovalReviewCompletedNotification

  defstruct [
    :action,
    :completed_at_ms,
    :decision_source,
    :review,
    :review_id,
    :started_at_ms,
    :target_item_id,
    :thread_id,
    :turn_id
  ]

  @field_specs [
    %{spec: :plain, field: :action, required: true, wire_key: "action"},
    %{spec: :plain, field: :completed_at_ms, required: true, wire_key: "completedAtMs"},
    %{spec: :plain, field: :decision_source, required: true, wire_key: "decisionSource"},
    %{
      spec: {:module, Module.concat(__MODULE__, "GuardianApprovalReview")},
      field: :review,
      required: true,
      wire_key: "review"
    },
    %{spec: :plain, field: :review_id, required: true, wire_key: "reviewId"},
    %{spec: :plain, field: :started_at_ms, required: true, wire_key: "startedAtMs"},
    %{
      spec: {:nullable, :plain},
      field: :target_item_id,
      required: false,
      wire_key: "targetItemId"
    },
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

    alias ItemGuardianApprovalReviewCompletedNotification,
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

  defmodule GuardianApprovalReview do
    @moduledoc false

    defstruct [:rationale, :risk_level, :status, :user_authorization]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :rationale, required: false, wire_key: "rationale"},
      %{spec: {:nullable, :plain}, field: :risk_level, required: false, wire_key: "riskLevel"},
      %{spec: :plain, field: :status, required: true, wire_key: "status"},
      %{
        spec: {:nullable, :plain},
        field: :user_authorization,
        required: false,
        wire_key: "userAuthorization"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule RequestPermissionProfile do
    @moduledoc false

    alias ItemGuardianApprovalReviewCompletedNotification,
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
end
