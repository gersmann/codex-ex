defmodule CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigDetectResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigDetectResponse

  defstruct [:connectors, :items]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ExternalAgentDetectedConnectorCandidate")}},
      field: :connectors,
      required: false,
      wire_key: "connectors"
    },
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ExternalAgentConfigMigrationItem")}},
      field: :items,
      required: true,
      wire_key: "items"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule CommandMigration do
    @moduledoc false

    defstruct [:name]

    @field_specs [%{spec: :plain, field: :name, required: true, wire_key: "name"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ExternalAgentConfigMigrationItem do
    @moduledoc false

    alias ExternalAgentConfigDetectResponse,
      as: ParentModule

    defstruct [:cwd, :description, :details, :item_type]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
      %{spec: :plain, field: :description, required: true, wire_key: "description"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "MigrationDetails")}},
        field: :details,
        required: false,
        wire_key: "details"
      },
      %{spec: :plain, field: :item_type, required: true, wire_key: "itemType"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ExternalAgentDetectedConnectorCandidate do
    @moduledoc false

    defstruct [:name, :session_count, :source]

    @field_specs [
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :session_count, required: true, wire_key: "sessionCount"},
      %{spec: :plain, field: :source, required: true, wire_key: "source"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule HookMigration do
    @moduledoc false

    defstruct [:name]

    @field_specs [%{spec: :plain, field: :name, required: true, wire_key: "name"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpServerMigration do
    @moduledoc false

    defstruct [:name]

    @field_specs [%{spec: :plain, field: :name, required: true, wire_key: "name"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule MigrationDetails do
    @moduledoc false

    alias ExternalAgentConfigDetectResponse,
      as: ParentModule

    defstruct [:commands, :hooks, :mcp_servers, :memory, :plugins, :sessions, :skills, :subagents]

    @field_specs [
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "CommandMigration")}},
        field: :commands,
        required: false,
        wire_key: "commands"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "HookMigration")}},
        field: :hooks,
        required: false,
        wire_key: "hooks"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "McpServerMigration")}},
        field: :mcp_servers,
        required: false,
        wire_key: "mcpServers"
      },
      %{spec: {:array, :plain}, field: :memory, required: false, wire_key: "memory"},
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "PluginsMigration")}},
        field: :plugins,
        required: false,
        wire_key: "plugins"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "SessionMigration")}},
        field: :sessions,
        required: false,
        wire_key: "sessions"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "SkillMigration")}},
        field: :skills,
        required: false,
        wire_key: "skills"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "SubagentMigration")}},
        field: :subagents,
        required: false,
        wire_key: "subagents"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule PluginsMigration do
    @moduledoc false

    defstruct [:marketplace_name, :plugin_names]

    @field_specs [
      %{spec: :plain, field: :marketplace_name, required: true, wire_key: "marketplaceName"},
      %{spec: {:array, :plain}, field: :plugin_names, required: true, wire_key: "pluginNames"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule SessionMigration do
    @moduledoc false

    defstruct [:cwd, :path, :title]

    @field_specs [
      %{spec: :plain, field: :cwd, required: true, wire_key: "cwd"},
      %{spec: :plain, field: :path, required: true, wire_key: "path"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule SkillMigration do
    @moduledoc false

    defstruct [:name]

    @field_specs [%{spec: :plain, field: :name, required: true, wire_key: "name"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule SubagentMigration do
    @moduledoc false

    defstruct [:name]

    @field_specs [%{spec: :plain, field: :name, required: true, wire_key: "name"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
