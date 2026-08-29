defmodule CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:auto_resolution_ms, :is_blocking, :item_id, :questions, :thread_id, :turn_id]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :auto_resolution_ms,
      required: false,
      wire_key: "autoResolutionMs"
    },
    %{spec: :plain, field: :is_blocking, required: true, wire_key: "isBlocking"},
    %{spec: :plain, field: :item_id, required: true, wire_key: "itemId"},
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ToolRequestUserInputQuestion")}},
      field: :questions,
      required: true,
      wire_key: "questions"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ToolRequestUserInputOption do
    @moduledoc false

    defstruct [:description, :label]

    @field_specs [
      %{spec: :plain, field: :description, required: true, wire_key: "description"},
      %{spec: :plain, field: :label, required: true, wire_key: "label"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ToolRequestUserInputQuestion do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputParams, as: ParentModule

    defstruct [:header, :id, :is_other, :is_secret, :options, :question]

    @field_specs [
      %{spec: :plain, field: :header, required: true, wire_key: "header"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: :plain, field: :is_other, required: false, wire_key: "isOther"},
      %{spec: :plain, field: :is_secret, required: false, wire_key: "isSecret"},
      %{
        spec: {:nullable, {:array, {:module, Module.concat(ParentModule, "ToolRequestUserInputOption")}}},
        field: :options,
        required: false,
        wire_key: "options"
      },
      %{spec: :plain, field: :question, required: true, wire_key: "question"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
