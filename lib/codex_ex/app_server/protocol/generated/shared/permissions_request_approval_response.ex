defmodule CodexEx.AppServer.Protocol.Generated.Shared.PermissionsRequestApprovalResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.Shared.PermissionsRequestApprovalResponse

  defstruct [:permissions, :scope, :strict_auto_review]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "GrantedPermissionProfile")},
      field: :permissions,
      required: true,
      wire_key: "permissions"
    },
    %{spec: :plain, field: :scope, required: false, wire_key: "scope"},
    %{
      spec: {:nullable, :plain},
      field: :strict_auto_review,
      required: false,
      wire_key: "strictAutoReview"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule AdditionalFileSystemPermissions do
    @moduledoc false

    alias PermissionsRequestApprovalResponse,
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

  defmodule GrantedPermissionProfile do
    @moduledoc false

    alias PermissionsRequestApprovalResponse,
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
