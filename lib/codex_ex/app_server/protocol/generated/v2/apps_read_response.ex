defmodule CodexEx.AppServer.Protocol.Generated.V2.AppsReadResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:apps, :missing_app_ids]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ConnectorMetadata")}},
      field: :apps,
      required: true,
      wire_key: "apps"
    },
    %{spec: {:array, :plain}, field: :missing_app_ids, required: true, wire_key: "missingAppIds"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule AppToolSummary do
    @moduledoc false

    defstruct [:description, :disabled_reason, :is_enabled, :is_read_only, :name, :title]

    @field_specs [
      %{spec: :plain, field: :description, required: true, wire_key: "description"},
      %{
        spec: {:nullable, :plain},
        field: :disabled_reason,
        required: false,
        wire_key: "disabledReason"
      },
      %{spec: :plain, field: :is_enabled, required: false, wire_key: "isEnabled"},
      %{spec: :plain, field: :is_read_only, required: false, wire_key: "isReadOnly"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ConnectorMetadata do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.AppsReadResponse, as: ParentModule

    defstruct [
      :description,
      :distribution_channel,
      :icon_url,
      :icon_url_dark,
      :id,
      :install_url,
      :name,
      :plugin_display_names,
      :tool_summaries
    ]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{
        spec: {:nullable, :plain},
        field: :distribution_channel,
        required: false,
        wire_key: "distributionChannel"
      },
      %{spec: {:nullable, :plain}, field: :icon_url, required: false, wire_key: "iconUrl"},
      %{
        spec: {:nullable, :plain},
        field: :icon_url_dark,
        required: false,
        wire_key: "iconUrlDark"
      },
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: {:nullable, :plain}, field: :install_url, required: false, wire_key: "installUrl"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{
        spec: {:array, :plain},
        field: :plugin_display_names,
        required: false,
        wire_key: "pluginDisplayNames"
      },
      %{
        spec: {:nullable, {:array, {:module, Module.concat(ParentModule, "AppToolSummary")}}},
        field: :tool_summaries,
        required: false,
        wire_key: "toolSummaries"
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
