defmodule CodexEx.AppServer.Protocol.Generated.V2.TurnStartedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.TurnStartedNotification

  defstruct [:thread_id, :turn]

  @field_specs [
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{
      spec: {:module, Module.concat(__MODULE__, "Turn")},
      field: :turn,
      required: true,
      wire_key: "turn"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule AsyncUserInputQuestion do
    @moduledoc false

    defstruct [:options, :title]

    @field_specs [
      %{
        spec: {:nullable, {:array, :plain}},
        field: :options,
        required: false,
        wire_key: "options"
      },
      %{spec: :plain, field: :title, required: true, wire_key: "title"}
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

  defmodule CollabAgentState do
    @moduledoc false

    defstruct [:message, :status]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :message, required: false, wire_key: "message"},
      %{spec: :plain, field: :status, required: true, wire_key: "status"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule FileUpdateChange do
    @moduledoc false

    defstruct [:diff, :kind, :path]

    @field_specs [
      %{spec: :plain, field: :diff, required: true, wire_key: "diff"},
      %{spec: :plain, field: :kind, required: true, wire_key: "kind"},
      %{spec: :plain, field: :path, required: true, wire_key: "path"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule HookPromptFragment do
    @moduledoc false

    defstruct [:hook_run_id, :text]

    @field_specs [
      %{spec: :plain, field: :hook_run_id, required: true, wire_key: "hookRunId"},
      %{spec: :plain, field: :text, required: true, wire_key: "text"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpToolCallAppContext do
    @moduledoc false

    defstruct [:action_name, :app_name, :connector_id, :link_id, :resource_uri]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :action_name, required: false, wire_key: "actionName"},
      %{spec: {:nullable, :plain}, field: :app_name, required: false, wire_key: "appName"},
      %{spec: :plain, field: :connector_id, required: true, wire_key: "connectorId"},
      %{spec: {:nullable, :plain}, field: :link_id, required: false, wire_key: "linkId"},
      %{spec: {:nullable, :plain}, field: :resource_uri, required: false, wire_key: "resourceUri"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpToolCallError do
    @moduledoc false

    defstruct [:message]

    @field_specs [%{spec: :plain, field: :message, required: true, wire_key: "message"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpToolCallResult do
    @moduledoc false

    defstruct [:_meta, :content, :structured_content]

    @field_specs [
      %{spec: :plain, field: :_meta, required: false, wire_key: "_meta"},
      %{spec: {:array, :plain}, field: :content, required: true, wire_key: "content"},
      %{spec: :plain, field: :structured_content, required: false, wire_key: "structuredContent"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule MemoryCitation do
    @moduledoc false

    alias TurnStartedNotification, as: ParentModule

    defstruct [:entries, :thread_ids]

    @field_specs [
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "MemoryCitationEntry")}},
        field: :entries,
        required: true,
        wire_key: "entries"
      },
      %{spec: {:array, :plain}, field: :thread_ids, required: true, wire_key: "threadIds"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule MemoryCitationEntry do
    @moduledoc false

    defstruct [:line_end, :line_start, :note, :path]

    @field_specs [
      %{spec: :plain, field: :line_end, required: true, wire_key: "lineEnd"},
      %{spec: :plain, field: :line_start, required: true, wire_key: "lineStart"},
      %{spec: :plain, field: :note, required: true, wire_key: "note"},
      %{spec: :plain, field: :path, required: true, wire_key: "path"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule MisalignmentErrorDetails do
    @moduledoc false

    alias TurnStartedNotification, as: ParentModule

    defstruct [:detailed_explanation, :error_type, :steer]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :detailed_explanation,
        required: false,
        wire_key: "detailedExplanation"
      },
      %{spec: {:nullable, :plain}, field: :error_type, required: false, wire_key: "errorType"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "MisalignmentSteer")}},
        field: :steer,
        required: false,
        wire_key: "steer"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule MisalignmentSteer do
    @moduledoc false

    defstruct [:message]

    @field_specs [%{spec: :plain, field: :message, required: true, wire_key: "message"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule TextElement do
    @moduledoc false

    alias TurnStartedNotification, as: ParentModule

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

  defmodule Turn do
    @moduledoc false

    alias TurnStartedNotification, as: ParentModule

    defstruct [
      :completed_at,
      :duration_ms,
      :error,
      :id,
      :items,
      :items_view,
      :started_at,
      :status
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :completed_at,
        required: false,
        wire_key: "completedAt"
      },
      %{spec: {:nullable, :plain}, field: :duration_ms, required: false, wire_key: "durationMs"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "TurnError")}},
        field: :error,
        required: false,
        wire_key: "error"
      },
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: {:array, :plain}, field: :items, required: true, wire_key: "items"},
      %{spec: :plain, field: :items_view, required: false, wire_key: "itemsView"},
      %{spec: {:nullable, :plain}, field: :started_at, required: false, wire_key: "startedAt"},
      %{spec: :plain, field: :status, required: true, wire_key: "status"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule TurnError do
    @moduledoc false

    alias TurnStartedNotification, as: ParentModule

    defstruct [:additional_details, :codex_error_info, :message, :misalignment]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :additional_details,
        required: false,
        wire_key: "additionalDetails"
      },
      %{
        spec: {:nullable, :plain},
        field: :codex_error_info,
        required: false,
        wire_key: "codexErrorInfo"
      },
      %{spec: :plain, field: :message, required: true, wire_key: "message"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "MisalignmentErrorDetails")}},
        field: :misalignment,
        required: false,
        wire_key: "misalignment"
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
