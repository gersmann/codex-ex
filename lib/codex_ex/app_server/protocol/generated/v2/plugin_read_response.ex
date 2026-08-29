defmodule CodexEx.AppServer.Protocol.Generated.V2.PluginReadResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.PluginReadResponse

  defstruct [:plugin]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "PluginDetail")},
      field: :plugin,
      required: true,
      wire_key: "plugin"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule AppSummary do
    @moduledoc false

    defstruct [:category, :description, :id, :install_url, :name]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :category, required: false, wire_key: "category"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: {:nullable, :plain}, field: :install_url, required: false, wire_key: "installUrl"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule AppTemplateSummary do
    @moduledoc false

    defstruct [
      :canonical_connector_id,
      :category,
      :description,
      :logo_url,
      :logo_url_dark,
      :materialized_app_ids,
      :name,
      :reason,
      :template_id
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :canonical_connector_id,
        required: false,
        wire_key: "canonicalConnectorId"
      },
      %{spec: {:nullable, :plain}, field: :category, required: false, wire_key: "category"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:nullable, :plain}, field: :logo_url, required: false, wire_key: "logoUrl"},
      %{
        spec: {:nullable, :plain},
        field: :logo_url_dark,
        required: false,
        wire_key: "logoUrlDark"
      },
      %{
        spec: {:array, :plain},
        field: :materialized_app_ids,
        required: true,
        wire_key: "materializedAppIds"
      },
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: {:nullable, :plain}, field: :reason, required: false, wire_key: "reason"},
      %{spec: :plain, field: :template_id, required: true, wire_key: "templateId"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule PluginDetail do
    @moduledoc false

    alias PluginReadResponse, as: ParentModule

    defstruct [
      :app_templates,
      :apps,
      :description,
      :hooks,
      :marketplace_name,
      :marketplace_path,
      :mcp_servers,
      :scheduled_tasks,
      :share_url,
      :skills,
      :summary
    ]

    @field_specs [
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "AppTemplateSummary")}},
        field: :app_templates,
        required: true,
        wire_key: "appTemplates"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "AppSummary")}},
        field: :apps,
        required: true,
        wire_key: "apps"
      },
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "PluginHookSummary")}},
        field: :hooks,
        required: true,
        wire_key: "hooks"
      },
      %{spec: :plain, field: :marketplace_name, required: true, wire_key: "marketplaceName"},
      %{
        spec: {:nullable, :plain},
        field: :marketplace_path,
        required: false,
        wire_key: "marketplacePath"
      },
      %{spec: {:array, :plain}, field: :mcp_servers, required: true, wire_key: "mcpServers"},
      %{
        spec: {:nullable, {:array, {:module, Module.concat(ParentModule, "ScheduledTaskSummary")}}},
        field: :scheduled_tasks,
        required: false,
        wire_key: "scheduledTasks"
      },
      %{spec: {:nullable, :plain}, field: :share_url, required: false, wire_key: "shareUrl"},
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "SkillSummary")}},
        field: :skills,
        required: true,
        wire_key: "skills"
      },
      %{
        spec: {:module, Module.concat(ParentModule, "PluginSummary")},
        field: :summary,
        required: true,
        wire_key: "summary"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule PluginHookSummary do
    @moduledoc false

    defstruct [:event_name, :key]

    @field_specs [
      %{spec: :plain, field: :event_name, required: true, wire_key: "eventName"},
      %{spec: :plain, field: :key, required: true, wire_key: "key"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule PluginInterface do
    @moduledoc false

    defstruct [
      :brand_color,
      :capabilities,
      :category,
      :composer_icon,
      :composer_icon_url,
      :default_prompt,
      :developer_name,
      :display_name,
      :logo,
      :logo_dark,
      :logo_url,
      :logo_url_dark,
      :long_description,
      :privacy_policy_url,
      :screenshot_urls,
      :screenshots,
      :short_description,
      :terms_of_service_url,
      :website_url
    ]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :brand_color, required: false, wire_key: "brandColor"},
      %{spec: {:array, :plain}, field: :capabilities, required: true, wire_key: "capabilities"},
      %{spec: {:nullable, :plain}, field: :category, required: false, wire_key: "category"},
      %{
        spec: {:nullable, :plain},
        field: :composer_icon,
        required: false,
        wire_key: "composerIcon"
      },
      %{
        spec: {:nullable, :plain},
        field: :composer_icon_url,
        required: false,
        wire_key: "composerIconUrl"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :default_prompt,
        required: false,
        wire_key: "defaultPrompt"
      },
      %{
        spec: {:nullable, :plain},
        field: :developer_name,
        required: false,
        wire_key: "developerName"
      },
      %{
        spec: {:nullable, :plain},
        field: :display_name,
        required: false,
        wire_key: "displayName"
      },
      %{spec: {:nullable, :plain}, field: :logo, required: false, wire_key: "logo"},
      %{spec: {:nullable, :plain}, field: :logo_dark, required: false, wire_key: "logoDark"},
      %{spec: {:nullable, :plain}, field: :logo_url, required: false, wire_key: "logoUrl"},
      %{
        spec: {:nullable, :plain},
        field: :logo_url_dark,
        required: false,
        wire_key: "logoUrlDark"
      },
      %{
        spec: {:nullable, :plain},
        field: :long_description,
        required: false,
        wire_key: "longDescription"
      },
      %{
        spec: {:nullable, :plain},
        field: :privacy_policy_url,
        required: false,
        wire_key: "privacyPolicyUrl"
      },
      %{
        spec: {:array, :plain},
        field: :screenshot_urls,
        required: true,
        wire_key: "screenshotUrls"
      },
      %{spec: {:array, :plain}, field: :screenshots, required: true, wire_key: "screenshots"},
      %{
        spec: {:nullable, :plain},
        field: :short_description,
        required: false,
        wire_key: "shortDescription"
      },
      %{
        spec: {:nullable, :plain},
        field: :terms_of_service_url,
        required: false,
        wire_key: "termsOfServiceUrl"
      },
      %{spec: {:nullable, :plain}, field: :website_url, required: false, wire_key: "websiteUrl"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule PluginShareContext do
    @moduledoc false

    alias PluginReadResponse, as: ParentModule

    defstruct [
      :can_publish_to_workspace,
      :creator_account_user_id,
      :creator_name,
      :discoverability,
      :remote_plugin_id,
      :remote_version,
      :share_principals,
      :share_url
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :can_publish_to_workspace,
        required: false,
        wire_key: "canPublishToWorkspace"
      },
      %{
        spec: {:nullable, :plain},
        field: :creator_account_user_id,
        required: false,
        wire_key: "creatorAccountUserId"
      },
      %{
        spec: {:nullable, :plain},
        field: :creator_name,
        required: false,
        wire_key: "creatorName"
      },
      %{
        spec: {:nullable, :plain},
        field: :discoverability,
        required: false,
        wire_key: "discoverability"
      },
      %{spec: :plain, field: :remote_plugin_id, required: true, wire_key: "remotePluginId"},
      %{
        spec: {:nullable, :plain},
        field: :remote_version,
        required: false,
        wire_key: "remoteVersion"
      },
      %{
        spec: {:nullable, {:array, {:module, Module.concat(ParentModule, "PluginSharePrincipal")}}},
        field: :share_principals,
        required: false,
        wire_key: "sharePrincipals"
      },
      %{spec: {:nullable, :plain}, field: :share_url, required: false, wire_key: "shareUrl"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule PluginSharePrincipal do
    @moduledoc false

    defstruct [:name, :principal_id, :principal_type, :role]

    @field_specs [
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :principal_id, required: true, wire_key: "principalId"},
      %{spec: :plain, field: :principal_type, required: true, wire_key: "principalType"},
      %{spec: :plain, field: :role, required: true, wire_key: "role"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule PluginSummary do
    @moduledoc false

    alias PluginReadResponse, as: ParentModule

    defstruct [
      :auth_policy,
      :availability,
      :disabled_reason,
      :eligible_plan_types,
      :enabled,
      :id,
      :install_policy,
      :install_policy_source,
      :installed,
      :installed_at,
      :interface,
      :keywords,
      :local_version,
      :must_show_installation_interstitial,
      :name,
      :remote_plugin_id,
      :share_context,
      :source,
      :version
    ]

    @field_specs [
      %{spec: :plain, field: :auth_policy, required: true, wire_key: "authPolicy"},
      %{spec: :plain, field: :availability, required: false, wire_key: "availability"},
      %{
        spec: {:nullable, :plain},
        field: :disabled_reason,
        required: false,
        wire_key: "disabledReason"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :eligible_plan_types,
        required: false,
        wire_key: "eligiblePlanTypes"
      },
      %{spec: :plain, field: :enabled, required: true, wire_key: "enabled"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: :plain, field: :install_policy, required: true, wire_key: "installPolicy"},
      %{
        spec: {:nullable, :plain},
        field: :install_policy_source,
        required: false,
        wire_key: "installPolicySource"
      },
      %{spec: :plain, field: :installed, required: true, wire_key: "installed"},
      %{
        spec: {:nullable, :plain},
        field: :installed_at,
        required: false,
        wire_key: "installedAt"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "PluginInterface")}},
        field: :interface,
        required: false,
        wire_key: "interface"
      },
      %{spec: {:array, :plain}, field: :keywords, required: false, wire_key: "keywords"},
      %{
        spec: {:nullable, :plain},
        field: :local_version,
        required: false,
        wire_key: "localVersion"
      },
      %{
        spec: {:nullable, :plain},
        field: :must_show_installation_interstitial,
        required: false,
        wire_key: "mustShowInstallationInterstitial"
      },
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{
        spec: {:nullable, :plain},
        field: :remote_plugin_id,
        required: false,
        wire_key: "remotePluginId"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "PluginShareContext")}},
        field: :share_context,
        required: false,
        wire_key: "shareContext"
      },
      %{spec: :plain, field: :source, required: true, wire_key: "source"},
      %{spec: {:nullable, :plain}, field: :version, required: false, wire_key: "version"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ScheduledTaskSummary do
    @moduledoc false

    defstruct [:key, :name, :prompt, :schedule]

    @field_specs [
      %{spec: :plain, field: :key, required: true, wire_key: "key"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :prompt, required: true, wire_key: "prompt"},
      %{spec: :plain, field: :schedule, required: true, wire_key: "schedule"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule SkillInterface do
    @moduledoc false

    defstruct [
      :brand_color,
      :default_prompt,
      :display_name,
      :icon_large,
      :icon_large_url,
      :icon_small,
      :icon_small_url,
      :short_description
    ]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :brand_color, required: false, wire_key: "brandColor"},
      %{
        spec: {:nullable, :plain},
        field: :default_prompt,
        required: false,
        wire_key: "defaultPrompt"
      },
      %{
        spec: {:nullable, :plain},
        field: :display_name,
        required: false,
        wire_key: "displayName"
      },
      %{spec: {:nullable, :plain}, field: :icon_large, required: false, wire_key: "iconLarge"},
      %{
        spec: {:nullable, :plain},
        field: :icon_large_url,
        required: false,
        wire_key: "iconLargeUrl"
      },
      %{spec: {:nullable, :plain}, field: :icon_small, required: false, wire_key: "iconSmall"},
      %{
        spec: {:nullable, :plain},
        field: :icon_small_url,
        required: false,
        wire_key: "iconSmallUrl"
      },
      %{
        spec: {:nullable, :plain},
        field: :short_description,
        required: false,
        wire_key: "shortDescription"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule SkillSummary do
    @moduledoc false

    alias PluginReadResponse, as: ParentModule

    defstruct [:description, :enabled, :interface, :name, :path, :short_description]

    @field_specs [
      %{spec: :plain, field: :description, required: true, wire_key: "description"},
      %{spec: :plain, field: :enabled, required: true, wire_key: "enabled"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "SkillInterface")}},
        field: :interface,
        required: false,
        wire_key: "interface"
      },
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: {:nullable, :plain}, field: :path, required: false, wire_key: "path"},
      %{
        spec: {:nullable, :plain},
        field: :short_description,
        required: false,
        wire_key: "shortDescription"
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
