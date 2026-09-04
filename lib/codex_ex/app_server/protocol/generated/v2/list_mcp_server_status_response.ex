defmodule CodexEx.AppServer.Protocol.Generated.V2.ListMcpServerStatusResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data, :next_cursor]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "McpServerStatus")}},
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

  defmodule McpServerInfo do
    @moduledoc false

    defstruct [:description, :icons, :name, :title, :version, :website_url]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:nullable, {:array, :plain}}, field: :icons, required: false, wire_key: "icons"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :version, required: true, wire_key: "version"},
      %{spec: {:nullable, :plain}, field: :website_url, required: false, wire_key: "websiteUrl"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpServerStatus do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.ListMcpServerStatusResponse, as: ParentModule

    defstruct [
      :auth_status,
      :name,
      :plugin_id,
      :resource_templates,
      :resources,
      :runtime_status,
      :server_info,
      :tools
    ]

    @field_specs [
      %{spec: :plain, field: :auth_status, required: true, wire_key: "authStatus"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: {:nullable, :plain}, field: :plugin_id, required: false, wire_key: "pluginId"},
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ResourceTemplate")}},
        field: :resource_templates,
        required: true,
        wire_key: "resourceTemplates"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "Resource")}},
        field: :resources,
        required: true,
        wire_key: "resources"
      },
      %{
        spec: {:nullable, :plain},
        field: :runtime_status,
        required: false,
        wire_key: "runtimeStatus"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "McpServerInfo")}},
        field: :server_info,
        required: false,
        wire_key: "serverInfo"
      },
      %{spec: :plain, field: :tools, required: true, wire_key: "tools"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule Resource do
    @moduledoc false

    defstruct [:_meta, :annotations, :description, :icons, :mime_type, :name, :size, :title, :uri]

    @field_specs [
      %{spec: :plain, field: :_meta, required: false, wire_key: "_meta"},
      %{spec: :plain, field: :annotations, required: false, wire_key: "annotations"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:nullable, {:array, :plain}}, field: :icons, required: false, wire_key: "icons"},
      %{spec: {:nullable, :plain}, field: :mime_type, required: false, wire_key: "mimeType"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: {:nullable, :plain}, field: :size, required: false, wire_key: "size"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :uri, required: true, wire_key: "uri"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ResourceTemplate do
    @moduledoc false

    defstruct [:annotations, :description, :mime_type, :name, :title, :uri_template]

    @field_specs [
      %{spec: :plain, field: :annotations, required: false, wire_key: "annotations"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:nullable, :plain}, field: :mime_type, required: false, wire_key: "mimeType"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :uri_template, required: true, wire_key: "uriTemplate"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule Tool do
    @moduledoc false

    defstruct [
      :_meta,
      :annotations,
      :description,
      :icons,
      :input_schema,
      :name,
      :output_schema,
      :title
    ]

    @field_specs [
      %{spec: :plain, field: :_meta, required: false, wire_key: "_meta"},
      %{spec: :plain, field: :annotations, required: false, wire_key: "annotations"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:nullable, {:array, :plain}}, field: :icons, required: false, wire_key: "icons"},
      %{spec: :plain, field: :input_schema, required: true, wire_key: "inputSchema"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :output_schema, required: false, wire_key: "outputSchema"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
