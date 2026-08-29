defmodule CodexEx.AppServer.Protocol.Generated.Shared.McpServerElicitationRequestParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.Shared.McpServerElicitationRequestParams

  defstruct [
    :_meta,
    :elicitation_id,
    :message,
    :mode,
    :requested_schema,
    :server_name,
    :thread_id,
    :turn_id,
    :url
  ]

  @field_specs [
    %{spec: :plain, field: :_meta, required: false, wire_key: "_meta"},
    %{spec: :plain, field: :elicitation_id, required: false, wire_key: "elicitationId"},
    %{spec: :plain, field: :message, required: false, wire_key: "message"},
    %{spec: :plain, field: :mode, required: false, wire_key: "mode"},
    %{spec: :plain, field: :requested_schema, required: false, wire_key: "requestedSchema"},
    %{spec: :plain, field: :server_name, required: true, wire_key: "serverName"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: {:nullable, :plain}, field: :turn_id, required: false, wire_key: "turnId"},
    %{spec: :plain, field: :url, required: false, wire_key: "url"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule McpElicitationBooleanSchema do
    @moduledoc false

    defstruct [:default, :description, :title, :type]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :default, required: false, wire_key: "default"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :type, required: true, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpElicitationConstOption do
    @moduledoc false

    defstruct [:const, :title]

    @field_specs [
      %{spec: :plain, field: :const, required: true, wire_key: "const"},
      %{spec: :plain, field: :title, required: true, wire_key: "title"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpElicitationLegacyTitledEnumSchema do
    @moduledoc false

    defstruct [:default, :description, :enum, :enum_names, :title, :type]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :default, required: false, wire_key: "default"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:array, :plain}, field: :enum, required: true, wire_key: "enum"},
      %{
        spec: {:nullable, {:array, :plain}},
        field: :enum_names,
        required: false,
        wire_key: "enumNames"
      },
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :type, required: true, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpElicitationNumberSchema do
    @moduledoc false

    defstruct [:default, :description, :maximum, :minimum, :title, :type]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :default, required: false, wire_key: "default"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:nullable, :plain}, field: :maximum, required: false, wire_key: "maximum"},
      %{spec: {:nullable, :plain}, field: :minimum, required: false, wire_key: "minimum"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :type, required: true, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpElicitationSchema do
    @moduledoc false

    defstruct [:"$schema", :properties, :required, :type]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :"$schema", required: false, wire_key: "$schema"},
      %{spec: :plain, field: :properties, required: true, wire_key: "properties"},
      %{
        spec: {:nullable, {:array, :plain}},
        field: :required,
        required: false,
        wire_key: "required"
      },
      %{spec: :plain, field: :type, required: true, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpElicitationStringSchema do
    @moduledoc false

    defstruct [:default, :description, :format, :max_length, :min_length, :title, :type]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :default, required: false, wire_key: "default"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:nullable, :plain}, field: :format, required: false, wire_key: "format"},
      %{spec: {:nullable, :plain}, field: :max_length, required: false, wire_key: "maxLength"},
      %{spec: {:nullable, :plain}, field: :min_length, required: false, wire_key: "minLength"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :type, required: true, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpElicitationTitledEnumItems do
    @moduledoc false

    alias McpServerElicitationRequestParams,
      as: ParentModule

    defstruct [:any_of]

    @field_specs [
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "McpElicitationConstOption")}},
        field: :any_of,
        required: true,
        wire_key: "anyOf"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpElicitationTitledMultiSelectEnumSchema do
    @moduledoc false

    alias McpServerElicitationRequestParams,
      as: ParentModule

    defstruct [:default, :description, :items, :max_items, :min_items, :title, :type]

    @field_specs [
      %{
        spec: {:nullable, {:array, :plain}},
        field: :default,
        required: false,
        wire_key: "default"
      },
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{
        spec: {:module, Module.concat(ParentModule, "McpElicitationTitledEnumItems")},
        field: :items,
        required: true,
        wire_key: "items"
      },
      %{spec: {:nullable, :plain}, field: :max_items, required: false, wire_key: "maxItems"},
      %{spec: {:nullable, :plain}, field: :min_items, required: false, wire_key: "minItems"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :type, required: true, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpElicitationTitledSingleSelectEnumSchema do
    @moduledoc false

    alias McpServerElicitationRequestParams,
      as: ParentModule

    defstruct [:default, :description, :one_of, :title, :type]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :default, required: false, wire_key: "default"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "McpElicitationConstOption")}},
        field: :one_of,
        required: true,
        wire_key: "oneOf"
      },
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :type, required: true, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpElicitationUntitledEnumItems do
    @moduledoc false

    defstruct [:enum, :type]

    @field_specs [
      %{spec: {:array, :plain}, field: :enum, required: true, wire_key: "enum"},
      %{spec: :plain, field: :type, required: true, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpElicitationUntitledMultiSelectEnumSchema do
    @moduledoc false

    alias McpServerElicitationRequestParams,
      as: ParentModule

    defstruct [:default, :description, :items, :max_items, :min_items, :title, :type]

    @field_specs [
      %{
        spec: {:nullable, {:array, :plain}},
        field: :default,
        required: false,
        wire_key: "default"
      },
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{
        spec: {:module, Module.concat(ParentModule, "McpElicitationUntitledEnumItems")},
        field: :items,
        required: true,
        wire_key: "items"
      },
      %{spec: {:nullable, :plain}, field: :max_items, required: false, wire_key: "maxItems"},
      %{spec: {:nullable, :plain}, field: :min_items, required: false, wire_key: "minItems"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :type, required: true, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule McpElicitationUntitledSingleSelectEnumSchema do
    @moduledoc false

    defstruct [:default, :description, :enum, :title, :type]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :default, required: false, wire_key: "default"},
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:array, :plain}, field: :enum, required: true, wire_key: "enum"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :type, required: true, wire_key: "type"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
