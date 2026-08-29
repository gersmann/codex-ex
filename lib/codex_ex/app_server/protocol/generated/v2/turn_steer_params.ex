defmodule CodexEx.AppServer.Protocol.Generated.V2.TurnSteerParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :additional_context,
    :client_user_message_id,
    :expected_turn_id,
    :input,
    :responsesapi_client_metadata,
    :thread_id
  ]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :additional_context,
      required: false,
      wire_key: "additionalContext"
    },
    %{
      spec: {:nullable, :plain},
      field: :client_user_message_id,
      required: false,
      wire_key: "clientUserMessageId"
    },
    %{spec: :plain, field: :expected_turn_id, required: true, wire_key: "expectedTurnId"},
    %{spec: {:array, :plain}, field: :input, required: true, wire_key: "input"},
    %{
      spec: {:nullable, :plain},
      field: :responsesapi_client_metadata,
      required: false,
      wire_key: "responsesapiClientMetadata"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule AdditionalContextEntry do
    @moduledoc false

    defstruct [:kind, :value]

    @field_specs [
      %{spec: :plain, field: :kind, required: true, wire_key: "kind"},
      %{spec: :plain, field: :value, required: true, wire_key: "value"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ByteRange do
    @moduledoc false

    defstruct [:end, :start]

    @field_specs [
      %{spec: :plain, field: :end, required: true, wire_key: "end"},
      %{spec: :plain, field: :start, required: true, wire_key: "start"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule TextElement do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.TurnSteerParams, as: ParentModule

    defstruct [:byte_range, :placeholder]

    @field_specs [
      %{
        spec: {:module, Module.concat(ParentModule, "ByteRange")},
        field: :byte_range,
        required: true,
        wire_key: "byteRange"
      },
      %{spec: {:nullable, :plain}, field: :placeholder, required: false, wire_key: "placeholder"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
