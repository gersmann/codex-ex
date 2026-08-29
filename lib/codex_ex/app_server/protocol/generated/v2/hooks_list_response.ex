defmodule CodexEx.AppServer.Protocol.Generated.V2.HooksListResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "HooksListEntry")}},
      field: :data,
      required: true,
      wire_key: "data"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule HookErrorInfo do
    @moduledoc false

    defstruct [:message, :path]

    @field_specs [
      %{spec: :plain, field: :message, required: true, wire_key: "message"},
      %{spec: :plain, field: :path, required: true, wire_key: "path"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule HookMetadata do
    @moduledoc false

    defstruct [
      :additional_context_limit,
      :async,
      :command,
      :current_hash,
      :display_order,
      :enabled,
      :event_name,
      :handler_type,
      :is_managed,
      :key,
      :matcher,
      :plugin_id,
      :server,
      :source,
      :source_path,
      :status_message,
      :timeout_sec,
      :tool,
      :trust_status
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :additional_context_limit,
        required: false,
        wire_key: "additionalContextLimit"
      },
      %{spec: :plain, field: :async, required: false, wire_key: "async"},
      %{spec: :plain, field: :command, required: false, wire_key: "command"},
      %{spec: :plain, field: :current_hash, required: true, wire_key: "currentHash"},
      %{spec: :plain, field: :display_order, required: true, wire_key: "displayOrder"},
      %{spec: :plain, field: :enabled, required: true, wire_key: "enabled"},
      %{spec: :plain, field: :event_name, required: true, wire_key: "eventName"},
      %{spec: :plain, field: :handler_type, required: false, wire_key: "handlerType"},
      %{spec: :plain, field: :is_managed, required: true, wire_key: "isManaged"},
      %{spec: :plain, field: :key, required: true, wire_key: "key"},
      %{spec: {:nullable, :plain}, field: :matcher, required: false, wire_key: "matcher"},
      %{spec: {:nullable, :plain}, field: :plugin_id, required: false, wire_key: "pluginId"},
      %{spec: :plain, field: :server, required: false, wire_key: "server"},
      %{spec: :plain, field: :source, required: true, wire_key: "source"},
      %{spec: :plain, field: :source_path, required: true, wire_key: "sourcePath"},
      %{
        spec: {:nullable, :plain},
        field: :status_message,
        required: false,
        wire_key: "statusMessage"
      },
      %{spec: :plain, field: :timeout_sec, required: true, wire_key: "timeoutSec"},
      %{spec: :plain, field: :tool, required: false, wire_key: "tool"},
      %{spec: :plain, field: :trust_status, required: true, wire_key: "trustStatus"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule HooksListEntry do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.HooksListResponse, as: ParentModule

    defstruct [:cwd, :errors, :hooks, :warnings]

    @field_specs [
      %{spec: :plain, field: :cwd, required: true, wire_key: "cwd"},
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "HookErrorInfo")}},
        field: :errors,
        required: true,
        wire_key: "errors"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "HookMetadata")}},
        field: :hooks,
        required: true,
        wire_key: "hooks"
      },
      %{spec: {:array, :plain}, field: :warnings, required: true, wire_key: "warnings"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
