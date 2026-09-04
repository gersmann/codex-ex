defmodule CodexEx.AppServer.Protocol.Generated.V2.ItemCompletedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.ItemCompletedNotification

  defstruct [:completed_at_ms, :item, :thread_id, :turn_id]

  @field_specs [
    %{spec: :plain, field: :completed_at_ms, required: true, wire_key: "completedAtMs"},
    %{spec: :plain, field: :item, required: true, wire_key: "item"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"}
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

    alias ItemCompletedNotification, as: ParentModule

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

  defmodule TextElement do
    @moduledoc false

    alias ItemCompletedNotification, as: ParentModule

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
end
