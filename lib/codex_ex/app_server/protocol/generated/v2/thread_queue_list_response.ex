defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadQueueListResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data, :next_cursor]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "QueuedSubmission")}},
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

  defmodule QueuedSubmission do
    @moduledoc false

    defstruct [:client_user_message_id, :id, :input]

    @field_specs [
      %{
        spec: :plain,
        field: :client_user_message_id,
        required: true,
        wire_key: "clientUserMessageId"
      },
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: {:array, :plain}, field: :input, required: true, wire_key: "input"}
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

    alias CodexEx.AppServer.Protocol.Generated.V2.ThreadQueueListResponse, as: ParentModule

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
