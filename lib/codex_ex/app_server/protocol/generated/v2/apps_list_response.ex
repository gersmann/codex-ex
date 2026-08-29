defmodule CodexEx.AppServer.Protocol.Generated.V2.AppsListResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.AppsListResponse

  defstruct [:data, :next_cursor]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "AppInfo")}},
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

  defmodule AppBranding do
    @moduledoc false

    defstruct [
      :category,
      :developer,
      :is_discoverable_app,
      :privacy_policy,
      :terms_of_service,
      :website
    ]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :category, required: false, wire_key: "category"},
      %{spec: {:nullable, :plain}, field: :developer, required: false, wire_key: "developer"},
      %{spec: :plain, field: :is_discoverable_app, required: true, wire_key: "isDiscoverableApp"},
      %{
        spec: {:nullable, :plain},
        field: :privacy_policy,
        required: false,
        wire_key: "privacyPolicy"
      },
      %{
        spec: {:nullable, :plain},
        field: :terms_of_service,
        required: false,
        wire_key: "termsOfService"
      },
      %{spec: {:nullable, :plain}, field: :website, required: false, wire_key: "website"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule AppInfo do
    @moduledoc false

    alias AppsListResponse, as: ParentModule

    defstruct [
      :app_metadata,
      :branding,
      :description,
      :distribution_channel,
      :icon_assets,
      :icon_dark_assets,
      :id,
      :install_url,
      :is_accessible,
      :is_enabled,
      :labels,
      :logo_url,
      :logo_url_dark,
      :name,
      :plugin_display_names
    ]

    @field_specs [
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "AppMetadata")}},
        field: :app_metadata,
        required: false,
        wire_key: "appMetadata"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "AppBranding")}},
        field: :branding,
        required: false,
        wire_key: "branding"
      },
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{
        spec: {:nullable, :plain},
        field: :distribution_channel,
        required: false,
        wire_key: "distributionChannel"
      },
      %{spec: {:nullable, :plain}, field: :icon_assets, required: false, wire_key: "iconAssets"},
      %{
        spec: {:nullable, :plain},
        field: :icon_dark_assets,
        required: false,
        wire_key: "iconDarkAssets"
      },
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: {:nullable, :plain}, field: :install_url, required: false, wire_key: "installUrl"},
      %{spec: :plain, field: :is_accessible, required: false, wire_key: "isAccessible"},
      %{spec: :plain, field: :is_enabled, required: false, wire_key: "isEnabled"},
      %{spec: {:nullable, :plain}, field: :labels, required: false, wire_key: "labels"},
      %{spec: {:nullable, :plain}, field: :logo_url, required: false, wire_key: "logoUrl"},
      %{
        spec: {:nullable, :plain},
        field: :logo_url_dark,
        required: false,
        wire_key: "logoUrlDark"
      },
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{
        spec: {:array, :plain},
        field: :plugin_display_names,
        required: false,
        wire_key: "pluginDisplayNames"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule AppMetadata do
    @moduledoc false

    alias AppsListResponse, as: ParentModule

    defstruct [
      :categories,
      :developer,
      :first_party_requires_install,
      :review,
      :screenshots,
      :seo_description,
      :show_in_composer_when_unlinked,
      :sub_categories,
      :version,
      :version_id,
      :version_notes
    ]

    @field_specs [
      %{
        spec: {:nullable, {:array, :plain}},
        field: :categories,
        required: false,
        wire_key: "categories"
      },
      %{spec: {:nullable, :plain}, field: :developer, required: false, wire_key: "developer"},
      %{
        spec: {:nullable, :plain},
        field: :first_party_requires_install,
        required: false,
        wire_key: "firstPartyRequiresInstall"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "AppReview")}},
        field: :review,
        required: false,
        wire_key: "review"
      },
      %{
        spec: {:nullable, {:array, {:module, Module.concat(ParentModule, "AppScreenshot")}}},
        field: :screenshots,
        required: false,
        wire_key: "screenshots"
      },
      %{
        spec: {:nullable, :plain},
        field: :seo_description,
        required: false,
        wire_key: "seoDescription"
      },
      %{
        spec: {:nullable, :plain},
        field: :show_in_composer_when_unlinked,
        required: false,
        wire_key: "showInComposerWhenUnlinked"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :sub_categories,
        required: false,
        wire_key: "subCategories"
      },
      %{spec: {:nullable, :plain}, field: :version, required: false, wire_key: "version"},
      %{spec: {:nullable, :plain}, field: :version_id, required: false, wire_key: "versionId"},
      %{
        spec: {:nullable, :plain},
        field: :version_notes,
        required: false,
        wire_key: "versionNotes"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule AppReview do
    @moduledoc false

    defstruct [:status]

    @field_specs [%{spec: :plain, field: :status, required: true, wire_key: "status"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule AppScreenshot do
    @moduledoc false

    defstruct [:file_id, :url, :user_prompt]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :file_id, required: false, wire_key: "fileId"},
      %{spec: {:nullable, :plain}, field: :url, required: false, wire_key: "url"},
      %{spec: :plain, field: :user_prompt, required: true, wire_key: "userPrompt"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
