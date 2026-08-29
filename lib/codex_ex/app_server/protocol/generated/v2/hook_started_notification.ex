defmodule CodexEx.AppServer.Protocol.Generated.V2.HookStartedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:run, :thread_id, :turn_id]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "HookRunSummary")},
      field: :run,
      required: true,
      wire_key: "run"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: {:nullable, :plain}, field: :turn_id, required: false, wire_key: "turnId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule HookOutputEntry do
    @moduledoc false

    defstruct [:kind, :text]

    @field_specs [
      %{spec: :plain, field: :kind, required: true, wire_key: "kind"},
      %{spec: :plain, field: :text, required: true, wire_key: "text"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule HookRunSummary do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.HookStartedNotification, as: ParentModule

    defstruct [
      :completed_at,
      :display_order,
      :duration_ms,
      :entries,
      :event_name,
      :execution_mode,
      :handler_type,
      :id,
      :scope,
      :source,
      :source_path,
      :started_at,
      :status,
      :status_message
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :completed_at,
        required: false,
        wire_key: "completedAt"
      },
      %{spec: :plain, field: :display_order, required: true, wire_key: "displayOrder"},
      %{spec: {:nullable, :plain}, field: :duration_ms, required: false, wire_key: "durationMs"},
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "HookOutputEntry")}},
        field: :entries,
        required: true,
        wire_key: "entries"
      },
      %{spec: :plain, field: :event_name, required: true, wire_key: "eventName"},
      %{spec: :plain, field: :execution_mode, required: true, wire_key: "executionMode"},
      %{spec: :plain, field: :handler_type, required: true, wire_key: "handlerType"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: :plain, field: :scope, required: true, wire_key: "scope"},
      %{spec: :plain, field: :source, required: false, wire_key: "source"},
      %{spec: :plain, field: :source_path, required: true, wire_key: "sourcePath"},
      %{spec: :plain, field: :started_at, required: true, wire_key: "startedAt"},
      %{spec: :plain, field: :status, required: true, wire_key: "status"},
      %{
        spec: {:nullable, :plain},
        field: :status_message,
        required: false,
        wire_key: "statusMessage"
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
