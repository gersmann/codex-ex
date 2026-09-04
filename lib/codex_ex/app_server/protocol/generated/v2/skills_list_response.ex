defmodule CodexEx.AppServer.Protocol.Generated.V2.SkillsListResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.SkillsListResponse

  defstruct [:data]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "SkillsListEntry")}},
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

  defmodule SkillDependencies do
    @moduledoc false

    alias SkillsListResponse, as: ParentModule

    defstruct [:tools]

    @field_specs [
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "SkillToolDependency")}},
        field: :tools,
        required: true,
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

  defmodule SkillErrorInfo do
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

  defmodule SkillMetadata do
    @moduledoc false

    alias SkillsListResponse, as: ParentModule

    defstruct [
      :dependencies,
      :description,
      :enabled,
      :interface,
      :name,
      :path,
      :plugin_id,
      :scope,
      :short_description
    ]

    @field_specs [
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "SkillDependencies")}},
        field: :dependencies,
        required: false,
        wire_key: "dependencies"
      },
      %{spec: :plain, field: :description, required: true, wire_key: "description"},
      %{spec: :plain, field: :enabled, required: true, wire_key: "enabled"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "SkillInterface")}},
        field: :interface,
        required: false,
        wire_key: "interface"
      },
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :path, required: true, wire_key: "path"},
      %{spec: {:nullable, :plain}, field: :plugin_id, required: false, wire_key: "pluginId"},
      %{spec: :plain, field: :scope, required: true, wire_key: "scope"},
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

  defmodule SkillToolDependency do
    @moduledoc false

    defstruct [:command, :description, :transport, :type, :url, :value]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :command, required: false, wire_key: "command"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:nullable, :plain}, field: :transport, required: false, wire_key: "transport"},
      %{spec: :plain, field: :type, required: true, wire_key: "type"},
      %{spec: {:nullable, :plain}, field: :url, required: false, wire_key: "url"},
      %{spec: :plain, field: :value, required: true, wire_key: "value"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule SkillsListEntry do
    @moduledoc false

    alias SkillsListResponse, as: ParentModule

    defstruct [:cwd, :errors, :skills]

    @field_specs [
      %{spec: :plain, field: :cwd, required: true, wire_key: "cwd"},
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "SkillErrorInfo")}},
        field: :errors,
        required: true,
        wire_key: "errors"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "SkillMetadata")}},
        field: :skills,
        required: true,
        wire_key: "skills"
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
