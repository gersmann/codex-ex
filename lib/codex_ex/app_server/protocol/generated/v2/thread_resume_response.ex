defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadResumeResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadResumeResponse

  defstruct [
    :active_permission_profile,
    :approval_policy,
    :approvals_reviewer,
    :cwd,
    :initial_turns_page,
    :instruction_sources,
    :items_backwards_cursor,
    :model,
    :model_provider,
    :multi_agent_mode,
    :reasoning_effort,
    :runtime_workspace_roots,
    :sandbox,
    :service_tier,
    :thread,
    :turns_backwards_cursor
  ]

  @field_specs [
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "ActivePermissionProfile")}},
      field: :active_permission_profile,
      required: false,
      wire_key: "activePermissionProfile"
    },
    %{spec: :plain, field: :approval_policy, required: true, wire_key: "approvalPolicy"},
    %{spec: :plain, field: :approvals_reviewer, required: true, wire_key: "approvalsReviewer"},
    %{spec: :plain, field: :cwd, required: true, wire_key: "cwd"},
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "TurnsPage")}},
      field: :initial_turns_page,
      required: false,
      wire_key: "initialTurnsPage"
    },
    %{
      spec: {:array, :plain},
      field: :instruction_sources,
      required: false,
      wire_key: "instructionSources"
    },
    %{
      spec: {:nullable, :plain},
      field: :items_backwards_cursor,
      required: false,
      wire_key: "itemsBackwardsCursor"
    },
    %{spec: :plain, field: :model, required: true, wire_key: "model"},
    %{spec: :plain, field: :model_provider, required: true, wire_key: "modelProvider"},
    %{spec: :plain, field: :multi_agent_mode, required: false, wire_key: "multiAgentMode"},
    %{
      spec: {:nullable, :plain},
      field: :reasoning_effort,
      required: false,
      wire_key: "reasoningEffort"
    },
    %{
      spec: {:array, :plain},
      field: :runtime_workspace_roots,
      required: false,
      wire_key: "runtimeWorkspaceRoots"
    },
    %{spec: :plain, field: :sandbox, required: true, wire_key: "sandbox"},
    %{spec: {:nullable, :plain}, field: :service_tier, required: false, wire_key: "serviceTier"},
    %{
      spec: {:module, Module.concat(__MODULE__, "Thread")},
      field: :thread,
      required: true,
      wire_key: "thread"
    },
    %{
      spec: {:nullable, :plain},
      field: :turns_backwards_cursor,
      required: false,
      wire_key: "turnsBackwardsCursor"
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

  defmodule GitInfo do
    @moduledoc false

    defstruct [:branch, :origin_url, :sha]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :branch, required: false, wire_key: "branch"},
      %{spec: {:nullable, :plain}, field: :origin_url, required: false, wire_key: "originUrl"},
      %{spec: {:nullable, :plain}, field: :sha, required: false, wire_key: "sha"}
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

    alias ThreadResumeResponse, as: ParentModule

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

    alias ThreadResumeResponse, as: ParentModule

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

    alias ThreadResumeResponse, as: ParentModule

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

  defmodule Thread do
    @moduledoc false

    alias ThreadResumeResponse, as: ParentModule

    defstruct [
      :agent_nickname,
      :agent_role,
      :can_accept_direct_input,
      :cli_version,
      :created_at,
      :cwd,
      :ephemeral,
      :extra,
      :forked_from_id,
      :git_info,
      :history_mode,
      :id,
      :model,
      :model_provider,
      :name,
      :parent_thread_id,
      :path,
      :preview,
      :project_id,
      :reasoning_effort,
      :recency_at,
      :section,
      :section_entered_at,
      :session_id,
      :source,
      :status,
      :thread_source,
      :turns,
      :updated_at
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :agent_nickname,
        required: false,
        wire_key: "agentNickname"
      },
      %{spec: {:nullable, :plain}, field: :agent_role, required: false, wire_key: "agentRole"},
      %{
        spec: {:nullable, :plain},
        field: :can_accept_direct_input,
        required: false,
        wire_key: "canAcceptDirectInput"
      },
      %{spec: :plain, field: :cli_version, required: true, wire_key: "cliVersion"},
      %{spec: :plain, field: :created_at, required: true, wire_key: "createdAt"},
      %{spec: :plain, field: :cwd, required: true, wire_key: "cwd"},
      %{spec: :plain, field: :ephemeral, required: true, wire_key: "ephemeral"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ThreadExtra")}},
        field: :extra,
        required: false,
        wire_key: "extra"
      },
      %{
        spec: {:nullable, :plain},
        field: :forked_from_id,
        required: false,
        wire_key: "forkedFromId"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "GitInfo")}},
        field: :git_info,
        required: false,
        wire_key: "gitInfo"
      },
      %{spec: :plain, field: :history_mode, required: false, wire_key: "historyMode"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
      %{spec: :plain, field: :model_provider, required: true, wire_key: "modelProvider"},
      %{spec: {:nullable, :plain}, field: :name, required: false, wire_key: "name"},
      %{
        spec: {:nullable, :plain},
        field: :parent_thread_id,
        required: false,
        wire_key: "parentThreadId"
      },
      %{spec: {:nullable, :plain}, field: :path, required: false, wire_key: "path"},
      %{spec: :plain, field: :preview, required: true, wire_key: "preview"},
      %{spec: {:nullable, :plain}, field: :project_id, required: true, wire_key: "projectId"},
      %{
        spec: {:nullable, :plain},
        field: :reasoning_effort,
        required: false,
        wire_key: "reasoningEffort"
      },
      %{spec: {:nullable, :plain}, field: :recency_at, required: false, wire_key: "recencyAt"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ThreadSection")}},
        field: :section,
        required: false,
        wire_key: "section"
      },
      %{
        spec: {:nullable, :plain},
        field: :section_entered_at,
        required: false,
        wire_key: "sectionEnteredAt"
      },
      %{spec: :plain, field: :session_id, required: true, wire_key: "sessionId"},
      %{spec: :plain, field: :source, required: true, wire_key: "source"},
      %{spec: :plain, field: :status, required: true, wire_key: "status"},
      %{
        spec: {:nullable, :plain},
        field: :thread_source,
        required: false,
        wire_key: "threadSource"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "Turn")}},
        field: :turns,
        required: true,
        wire_key: "turns"
      },
      %{spec: :plain, field: :updated_at, required: true, wire_key: "updatedAt"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ThreadExtra do
    @moduledoc false

    defstruct []

    @field_specs []

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ThreadSection do
    @moduledoc false

    alias ThreadResumeResponse, as: ParentModule

    defstruct [:appearance, :id, :name]

    @field_specs [
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ThreadSectionAppearance")}},
        field: :appearance,
        required: false,
        wire_key: "appearance"
      },
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ThreadSectionAppearance do
    @moduledoc false

    defstruct [:color, :icon]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :color, required: false, wire_key: "color"},
      %{spec: {:nullable, :plain}, field: :icon, required: false, wire_key: "icon"}
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

    alias ThreadResumeResponse, as: ParentModule

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

    alias ThreadResumeResponse, as: ParentModule

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

  defmodule TurnsPage do
    @moduledoc false

    alias ThreadResumeResponse, as: ParentModule

    defstruct [:backwards_cursor, :data, :next_cursor]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :backwards_cursor,
        required: false,
        wire_key: "backwardsCursor"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "Turn")}},
        field: :data,
        required: true,
        wire_key: "data"
      },
      %{spec: {:nullable, :plain}, field: :next_cursor, required: false, wire_key: "nextCursor"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
