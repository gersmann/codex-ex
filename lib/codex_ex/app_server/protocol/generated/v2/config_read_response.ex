defmodule CodexEx.AppServer.Protocol.Generated.V2.ConfigReadResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.ConfigReadResponse

  defstruct [:config, :layers, :origins]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "Config")},
      field: :config,
      required: true,
      wire_key: "config"
    },
    %{
      spec: {:nullable, {:array, {:module, Module.concat(__MODULE__, "ConfigLayer")}}},
      field: :layers,
      required: false,
      wire_key: "layers"
    },
    %{spec: :plain, field: :origins, required: true, wire_key: "origins"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule AnalyticsConfig do
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

  defmodule AppConfig do
    @moduledoc false

    alias ConfigReadResponse, as: ParentModule

    defstruct [
      :approvals_reviewer,
      :default_tools_approval_mode,
      :default_tools_enabled,
      :destructive_enabled,
      :enabled,
      :open_world_enabled,
      :tools
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :approvals_reviewer,
        required: false,
        wire_key: "approvals_reviewer"
      },
      %{
        spec: {:nullable, :plain},
        field: :default_tools_approval_mode,
        required: false,
        wire_key: "default_tools_approval_mode"
      },
      %{
        spec: {:nullable, :plain},
        field: :default_tools_enabled,
        required: false,
        wire_key: "default_tools_enabled"
      },
      %{
        spec: {:nullable, :plain},
        field: :destructive_enabled,
        required: false,
        wire_key: "destructive_enabled"
      },
      %{spec: :plain, field: :enabled, required: false, wire_key: "enabled"},
      %{
        spec: {:nullable, :plain},
        field: :open_world_enabled,
        required: false,
        wire_key: "open_world_enabled"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "AppToolsConfig")}},
        field: :tools,
        required: false,
        wire_key: "tools"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule AppToolConfig do
    @moduledoc false

    defstruct [:approval_mode, :enabled]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :approval_mode,
        required: false,
        wire_key: "approval_mode"
      },
      %{spec: {:nullable, :plain}, field: :enabled, required: false, wire_key: "enabled"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule AppToolsConfig do
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

  defmodule AppsConfig do
    @moduledoc false

    alias ConfigReadResponse, as: ParentModule

    defstruct [:_default]

    @field_specs [
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "AppsDefaultConfig")}},
        field: :_default,
        required: false,
        wire_key: "_default"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule AppsDefaultConfig do
    @moduledoc false

    defstruct [
      :approvals_reviewer,
      :default_tools_approval_mode,
      :destructive_enabled,
      :enabled,
      :open_world_enabled
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :approvals_reviewer,
        required: false,
        wire_key: "approvals_reviewer"
      },
      %{
        spec: {:nullable, :plain},
        field: :default_tools_approval_mode,
        required: false,
        wire_key: "default_tools_approval_mode"
      },
      %{
        spec: :plain,
        field: :destructive_enabled,
        required: false,
        wire_key: "destructive_enabled"
      },
      %{spec: :plain, field: :enabled, required: false, wire_key: "enabled"},
      %{spec: :plain, field: :open_world_enabled, required: false, wire_key: "open_world_enabled"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule Config do
    @moduledoc false

    alias ConfigReadResponse, as: ParentModule

    defstruct [
      :analytics,
      :approval_policy,
      :approvals_reviewer,
      :apps,
      :compact_prompt,
      :desktop,
      :developer_instructions,
      :forced_chatgpt_workspace_id,
      :forced_login_method,
      :instructions,
      :model,
      :model_auto_compact_token_limit,
      :model_auto_compact_token_limit_scope,
      :model_context_window,
      :model_provider,
      :model_reasoning_effort,
      :model_reasoning_summary,
      :model_verbosity,
      :review_model,
      :sandbox_mode,
      :sandbox_workspace_write,
      :service_tier,
      :tools,
      :web_search
    ]

    @field_specs [
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "AnalyticsConfig")}},
        field: :analytics,
        required: false,
        wire_key: "analytics"
      },
      %{
        spec: {:nullable, :plain},
        field: :approval_policy,
        required: false,
        wire_key: "approval_policy"
      },
      %{
        spec: {:nullable, :plain},
        field: :approvals_reviewer,
        required: false,
        wire_key: "approvals_reviewer"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "AppsConfig")}},
        field: :apps,
        required: false,
        wire_key: "apps"
      },
      %{
        spec: {:nullable, :plain},
        field: :compact_prompt,
        required: false,
        wire_key: "compact_prompt"
      },
      %{spec: {:nullable, :plain}, field: :desktop, required: false, wire_key: "desktop"},
      %{
        spec: {:nullable, :plain},
        field: :developer_instructions,
        required: false,
        wire_key: "developer_instructions"
      },
      %{
        spec: {:nullable, :plain},
        field: :forced_chatgpt_workspace_id,
        required: false,
        wire_key: "forced_chatgpt_workspace_id"
      },
      %{
        spec: {:nullable, :plain},
        field: :forced_login_method,
        required: false,
        wire_key: "forced_login_method"
      },
      %{
        spec: {:nullable, :plain},
        field: :instructions,
        required: false,
        wire_key: "instructions"
      },
      %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
      %{
        spec: {:nullable, :plain},
        field: :model_auto_compact_token_limit,
        required: false,
        wire_key: "model_auto_compact_token_limit"
      },
      %{
        spec: {:nullable, :plain},
        field: :model_auto_compact_token_limit_scope,
        required: false,
        wire_key: "model_auto_compact_token_limit_scope"
      },
      %{
        spec: {:nullable, :plain},
        field: :model_context_window,
        required: false,
        wire_key: "model_context_window"
      },
      %{
        spec: {:nullable, :plain},
        field: :model_provider,
        required: false,
        wire_key: "model_provider"
      },
      %{
        spec: {:nullable, :plain},
        field: :model_reasoning_effort,
        required: false,
        wire_key: "model_reasoning_effort"
      },
      %{
        spec: {:nullable, :plain},
        field: :model_reasoning_summary,
        required: false,
        wire_key: "model_reasoning_summary"
      },
      %{
        spec: {:nullable, :plain},
        field: :model_verbosity,
        required: false,
        wire_key: "model_verbosity"
      },
      %{
        spec: {:nullable, :plain},
        field: :review_model,
        required: false,
        wire_key: "review_model"
      },
      %{
        spec: {:nullable, :plain},
        field: :sandbox_mode,
        required: false,
        wire_key: "sandbox_mode"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "SandboxWorkspaceWrite")}},
        field: :sandbox_workspace_write,
        required: false,
        wire_key: "sandbox_workspace_write"
      },
      %{
        spec: {:nullable, :plain},
        field: :service_tier,
        required: false,
        wire_key: "service_tier"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ToolsV2")}},
        field: :tools,
        required: false,
        wire_key: "tools"
      },
      %{spec: {:nullable, :plain}, field: :web_search, required: false, wire_key: "web_search"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ConfigLayer do
    @moduledoc false

    defstruct [:config, :disabled_reason, :name, :version]

    @field_specs [
      %{spec: :plain, field: :config, required: true, wire_key: "config"},
      %{
        spec: {:nullable, :plain},
        field: :disabled_reason,
        required: false,
        wire_key: "disabledReason"
      },
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :version, required: true, wire_key: "version"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ConfigLayerMetadata do
    @moduledoc false

    defstruct [:name, :version]

    @field_specs [
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :version, required: true, wire_key: "version"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule SandboxWorkspaceWrite do
    @moduledoc false

    defstruct [:exclude_slash_tmp, :exclude_tmpdir_env_var, :network_access, :writable_roots]

    @field_specs [
      %{spec: :plain, field: :exclude_slash_tmp, required: false, wire_key: "exclude_slash_tmp"},
      %{
        spec: :plain,
        field: :exclude_tmpdir_env_var,
        required: false,
        wire_key: "exclude_tmpdir_env_var"
      },
      %{spec: :plain, field: :network_access, required: false, wire_key: "network_access"},
      %{
        spec: {:array, :plain},
        field: :writable_roots,
        required: false,
        wire_key: "writable_roots"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ToolsV2 do
    @moduledoc false

    alias ConfigReadResponse, as: ParentModule

    defstruct [:web_search]

    @field_specs [
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "WebSearchToolConfig")}},
        field: :web_search,
        required: false,
        wire_key: "web_search"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule WebSearchLocation do
    @moduledoc false

    defstruct [:city, :country, :region, :timezone]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :city, required: false, wire_key: "city"},
      %{spec: {:nullable, :plain}, field: :country, required: false, wire_key: "country"},
      %{spec: {:nullable, :plain}, field: :region, required: false, wire_key: "region"},
      %{spec: {:nullable, :plain}, field: :timezone, required: false, wire_key: "timezone"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule WebSearchToolConfig do
    @moduledoc false

    alias ConfigReadResponse, as: ParentModule

    defstruct [:allowed_domains, :context_size, :location]

    @field_specs [
      %{
        spec: {:nullable, {:array, :plain}},
        field: :allowed_domains,
        required: false,
        wire_key: "allowed_domains"
      },
      %{
        spec: {:nullable, :plain},
        field: :context_size,
        required: false,
        wire_key: "context_size"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "WebSearchLocation")}},
        field: :location,
        required: false,
        wire_key: "location"
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
