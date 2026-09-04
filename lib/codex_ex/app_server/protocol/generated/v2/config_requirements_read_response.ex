defmodule CodexEx.AppServer.Protocol.Generated.V2.ConfigRequirementsReadResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.ConfigRequirementsReadResponse

  defstruct [:requirements]

  @field_specs [
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "ConfigRequirements")}},
      field: :requirements,
      required: false,
      wire_key: "requirements"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule AutoReviewRequirements do
    @moduledoc false

    defstruct [:ignore_rules, :required_on_models]

    @field_specs [
      %{
        spec: {:nullable, {:array, :plain}},
        field: :ignore_rules,
        required: false,
        wire_key: "ignoreRules"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :required_on_models,
        required: false,
        wire_key: "requiredOnModels"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule BrowserUseOriginPolicy do
    @moduledoc false

    defstruct [
      :access,
      :access_approval_lifetime,
      :auto_review,
      :downloads,
      :full_cdp_access,
      :persistent_approval,
      :uploads
    ]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :access, required: false, wire_key: "access"},
      %{
        spec: {:nullable, :plain},
        field: :access_approval_lifetime,
        required: false,
        wire_key: "accessApprovalLifetime"
      },
      %{spec: {:nullable, :plain}, field: :auto_review, required: false, wire_key: "autoReview"},
      %{spec: {:nullable, :plain}, field: :downloads, required: false, wire_key: "downloads"},
      %{
        spec: {:nullable, :plain},
        field: :full_cdp_access,
        required: false,
        wire_key: "fullCdpAccess"
      },
      %{
        spec: {:nullable, :plain},
        field: :persistent_approval,
        required: false,
        wire_key: "persistentApproval"
      },
      %{spec: {:nullable, :plain}, field: :uploads, required: false, wire_key: "uploads"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule BrowserUseRequirements do
    @moduledoc false

    alias ConfigRequirementsReadResponse, as: ParentModule

    defstruct [
      :allow_global_persistent_approval,
      :allow_history_access,
      :default_origin_policy,
      :disable_auto_review,
      :origins
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :allow_global_persistent_approval,
        required: false,
        wire_key: "allowGlobalPersistentApproval"
      },
      %{
        spec: {:nullable, :plain},
        field: :allow_history_access,
        required: false,
        wire_key: "allowHistoryAccess"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "BrowserUseOriginPolicy")}},
        field: :default_origin_policy,
        required: false,
        wire_key: "defaultOriginPolicy"
      },
      %{
        spec: {:nullable, :plain},
        field: :disable_auto_review,
        required: false,
        wire_key: "disableAutoReview"
      },
      %{spec: {:nullable, :plain}, field: :origins, required: false, wire_key: "origins"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ComputerUseMacosRequirements do
    @moduledoc false

    defstruct [:bundle_ids]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :bundle_ids, required: false, wire_key: "bundleIds"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ComputerUseRequirements do
    @moduledoc false

    alias ConfigRequirementsReadResponse, as: ParentModule

    defstruct [
      :allow_locked_computer_use,
      :allow_persistent_approval,
      :default_app_access,
      :macos,
      :windows
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :allow_locked_computer_use,
        required: false,
        wire_key: "allowLockedComputerUse"
      },
      %{
        spec: {:nullable, :plain},
        field: :allow_persistent_approval,
        required: false,
        wire_key: "allowPersistentApproval"
      },
      %{
        spec: {:nullable, :plain},
        field: :default_app_access,
        required: false,
        wire_key: "defaultAppAccess"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ComputerUseMacosRequirements")}},
        field: :macos,
        required: false,
        wire_key: "macos"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ComputerUseWindowsRequirements")}},
        field: :windows,
        required: false,
        wire_key: "windows"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ComputerUseWindowsExeRequirement do
    @moduledoc false

    defstruct [:access, :binary_name, :product_name, :publisher_name]

    @field_specs [
      %{spec: :plain, field: :access, required: true, wire_key: "access"},
      %{spec: {:nullable, :plain}, field: :binary_name, required: false, wire_key: "binaryName"},
      %{spec: :plain, field: :product_name, required: true, wire_key: "productName"},
      %{spec: :plain, field: :publisher_name, required: true, wire_key: "publisherName"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ComputerUseWindowsRequirements do
    @moduledoc false

    alias ConfigRequirementsReadResponse, as: ParentModule

    defstruct [:aumids, :exes]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :aumids, required: false, wire_key: "aumids"},
      %{
        spec: {:nullable, {:array, {:module, Module.concat(ParentModule, "ComputerUseWindowsExeRequirement")}}},
        field: :exes,
        required: false,
        wire_key: "exes"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ConfigRequirements do
    @moduledoc false

    alias ConfigRequirementsReadResponse, as: ParentModule

    defstruct [
      :additional_developer_instructions,
      :allow_appshots,
      :allow_browser_and_computer_use,
      :allow_login_shell,
      :allow_managed_hooks_only,
      :allow_remote_control,
      :allowed_approval_policies,
      :allowed_approvals_reviewers,
      :allowed_permission_profiles,
      :allowed_sandbox_modes,
      :allowed_web_search_modes,
      :allowed_windows_sandbox_implementations,
      :auto_review,
      :browser_use,
      :chatgpt_base_url,
      :check_for_update_on_startup,
      :cli_auth_credentials_store,
      :computer_use,
      :default_permissions,
      :enforce_residency,
      :feature_requirements,
      :feedback,
      :hooks,
      :in_app_browser,
      :log_dir,
      :model_catalog_json,
      :models,
      :network,
      :sqlite_home,
      :windows_sandbox_private_desktop
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :additional_developer_instructions,
        required: false,
        wire_key: "additionalDeveloperInstructions"
      },
      %{
        spec: {:nullable, :plain},
        field: :allow_appshots,
        required: false,
        wire_key: "allowAppshots"
      },
      %{
        spec: {:nullable, :plain},
        field: :allow_browser_and_computer_use,
        required: false,
        wire_key: "allowBrowserAndComputerUse"
      },
      %{
        spec: {:nullable, :plain},
        field: :allow_login_shell,
        required: false,
        wire_key: "allowLoginShell"
      },
      %{
        spec: {:nullable, :plain},
        field: :allow_managed_hooks_only,
        required: false,
        wire_key: "allowManagedHooksOnly"
      },
      %{
        spec: {:nullable, :plain},
        field: :allow_remote_control,
        required: false,
        wire_key: "allowRemoteControl"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :allowed_approval_policies,
        required: false,
        wire_key: "allowedApprovalPolicies"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :allowed_approvals_reviewers,
        required: false,
        wire_key: "allowedApprovalsReviewers"
      },
      %{
        spec: {:nullable, :plain},
        field: :allowed_permission_profiles,
        required: false,
        wire_key: "allowedPermissionProfiles"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :allowed_sandbox_modes,
        required: false,
        wire_key: "allowedSandboxModes"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :allowed_web_search_modes,
        required: false,
        wire_key: "allowedWebSearchModes"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :allowed_windows_sandbox_implementations,
        required: false,
        wire_key: "allowedWindowsSandboxImplementations"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "AutoReviewRequirements")}},
        field: :auto_review,
        required: false,
        wire_key: "autoReview"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "BrowserUseRequirements")}},
        field: :browser_use,
        required: false,
        wire_key: "browserUse"
      },
      %{
        spec: {:nullable, :plain},
        field: :chatgpt_base_url,
        required: false,
        wire_key: "chatgptBaseUrl"
      },
      %{
        spec: {:nullable, :plain},
        field: :check_for_update_on_startup,
        required: false,
        wire_key: "checkForUpdateOnStartup"
      },
      %{
        spec: {:nullable, :plain},
        field: :cli_auth_credentials_store,
        required: false,
        wire_key: "cliAuthCredentialsStore"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ComputerUseRequirements")}},
        field: :computer_use,
        required: false,
        wire_key: "computerUse"
      },
      %{
        spec: {:nullable, :plain},
        field: :default_permissions,
        required: false,
        wire_key: "defaultPermissions"
      },
      %{
        spec: {:nullable, :plain},
        field: :enforce_residency,
        required: false,
        wire_key: "enforceResidency"
      },
      %{
        spec: {:nullable, :plain},
        field: :feature_requirements,
        required: false,
        wire_key: "featureRequirements"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "FeedbackRequirements")}},
        field: :feedback,
        required: false,
        wire_key: "feedback"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ManagedHooksRequirements")}},
        field: :hooks,
        required: false,
        wire_key: "hooks"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "InAppBrowserRequirements")}},
        field: :in_app_browser,
        required: false,
        wire_key: "inAppBrowser"
      },
      %{spec: {:nullable, :plain}, field: :log_dir, required: false, wire_key: "logDir"},
      %{
        spec: {:nullable, :plain},
        field: :model_catalog_json,
        required: false,
        wire_key: "modelCatalogJson"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "ModelsRequirements")}},
        field: :models,
        required: false,
        wire_key: "models"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "NetworkRequirements")}},
        field: :network,
        required: false,
        wire_key: "network"
      },
      %{spec: {:nullable, :plain}, field: :sqlite_home, required: false, wire_key: "sqliteHome"},
      %{
        spec: {:nullable, :plain},
        field: :windows_sandbox_private_desktop,
        required: false,
        wire_key: "windowsSandboxPrivateDesktop"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ConfiguredHookMatcherGroup do
    @moduledoc false

    defstruct [:hooks, :matcher]

    @field_specs [
      %{spec: {:array, :plain}, field: :hooks, required: true, wire_key: "hooks"},
      %{spec: {:nullable, :plain}, field: :matcher, required: false, wire_key: "matcher"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule FeedbackRequirements do
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

  defmodule InAppBrowserRequirements do
    @moduledoc false

    defstruct [:allow_external_browser_settings_import]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :allow_external_browser_settings_import,
        required: false,
        wire_key: "allowExternalBrowserSettingsImport"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ManagedHooksRequirements do
    @moduledoc false

    alias ConfigRequirementsReadResponse, as: ParentModule

    defstruct [
      :interrupt,
      :permission_request,
      :post_compact,
      :post_tool_use,
      :pre_compact,
      :pre_tool_use,
      :session_end,
      :session_start,
      :stop,
      :subagent_start,
      :subagent_stop,
      :user_prompt_submit,
      :managed_dir,
      :windows_managed_dir
    ]

    @field_specs [
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :interrupt,
        required: false,
        wire_key: "Interrupt"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :permission_request,
        required: true,
        wire_key: "PermissionRequest"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :post_compact,
        required: true,
        wire_key: "PostCompact"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :post_tool_use,
        required: true,
        wire_key: "PostToolUse"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :pre_compact,
        required: true,
        wire_key: "PreCompact"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :pre_tool_use,
        required: true,
        wire_key: "PreToolUse"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :session_end,
        required: false,
        wire_key: "SessionEnd"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :session_start,
        required: true,
        wire_key: "SessionStart"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :stop,
        required: true,
        wire_key: "Stop"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :subagent_start,
        required: true,
        wire_key: "SubagentStart"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :subagent_stop,
        required: true,
        wire_key: "SubagentStop"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ConfiguredHookMatcherGroup")}},
        field: :user_prompt_submit,
        required: true,
        wire_key: "UserPromptSubmit"
      },
      %{spec: {:nullable, :plain}, field: :managed_dir, required: false, wire_key: "managedDir"},
      %{
        spec: {:nullable, :plain},
        field: :windows_managed_dir,
        required: false,
        wire_key: "windowsManagedDir"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ModelsRequirements do
    @moduledoc false

    alias ConfigRequirementsReadResponse, as: ParentModule

    defstruct [:new_thread]

    @field_specs [
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "NewThreadModelDefaults")}},
        field: :new_thread,
        required: false,
        wire_key: "newThread"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule NetworkRequirements do
    @moduledoc false

    defstruct [
      :allow_local_binding,
      :allow_unix_sockets,
      :allow_upstream_proxy,
      :allowed_domains,
      :dangerously_allow_all_unix_sockets,
      :dangerously_allow_non_loopback_proxy,
      :denied_domains,
      :domains,
      :enabled,
      :http_port,
      :managed_allowed_domains_only,
      :socks_port,
      :unix_sockets
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :allow_local_binding,
        required: false,
        wire_key: "allowLocalBinding"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :allow_unix_sockets,
        required: false,
        wire_key: "allowUnixSockets"
      },
      %{
        spec: {:nullable, :plain},
        field: :allow_upstream_proxy,
        required: false,
        wire_key: "allowUpstreamProxy"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :allowed_domains,
        required: false,
        wire_key: "allowedDomains"
      },
      %{
        spec: {:nullable, :plain},
        field: :dangerously_allow_all_unix_sockets,
        required: false,
        wire_key: "dangerouslyAllowAllUnixSockets"
      },
      %{
        spec: {:nullable, :plain},
        field: :dangerously_allow_non_loopback_proxy,
        required: false,
        wire_key: "dangerouslyAllowNonLoopbackProxy"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :denied_domains,
        required: false,
        wire_key: "deniedDomains"
      },
      %{spec: {:nullable, :plain}, field: :domains, required: false, wire_key: "domains"},
      %{spec: {:nullable, :plain}, field: :enabled, required: false, wire_key: "enabled"},
      %{spec: {:nullable, :plain}, field: :http_port, required: false, wire_key: "httpPort"},
      %{
        spec: {:nullable, :plain},
        field: :managed_allowed_domains_only,
        required: false,
        wire_key: "managedAllowedDomainsOnly"
      },
      %{spec: {:nullable, :plain}, field: :socks_port, required: false, wire_key: "socksPort"},
      %{spec: {:nullable, :plain}, field: :unix_sockets, required: false, wire_key: "unixSockets"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule NewThreadModelDefaults do
    @moduledoc false

    defstruct [:model, :model_reasoning_effort, :service_tier]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
      %{
        spec: {:nullable, :plain},
        field: :model_reasoning_effort,
        required: false,
        wire_key: "modelReasoningEffort"
      },
      %{spec: {:nullable, :plain}, field: :service_tier, required: false, wire_key: "serviceTier"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
