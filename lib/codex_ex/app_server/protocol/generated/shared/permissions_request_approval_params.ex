defmodule CodexEx.AppServer.Protocol.Generated.Shared.PermissionsRequestApprovalParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.Shared.PermissionsRequestApprovalParams

  defstruct [
    :cwd,
    :environment_id,
    :item_id,
    :permissions,
    :reason,
    :started_at_ms,
    :thread_id,
    :turn_id
  ]

  @field_specs [
    %{spec: :plain, field: :cwd, required: true, wire_key: "cwd"},
    %{
      spec: {:nullable, :plain},
      field: :environment_id,
      required: false,
      wire_key: "environmentId"
    },
    %{spec: :plain, field: :item_id, required: true, wire_key: "itemId"},
    %{
      spec: {:module, Module.concat(__MODULE__, "RequestPermissionProfile")},
      field: :permissions,
      required: true,
      wire_key: "permissions"
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

    alias PermissionsRequestApprovalParams,
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

  defmodule RequestPermissionProfile do
    @moduledoc false

    alias PermissionsRequestApprovalParams,
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
