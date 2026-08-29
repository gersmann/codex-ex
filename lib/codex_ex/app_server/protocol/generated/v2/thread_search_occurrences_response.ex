defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadSearchOccurrencesResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data, :next_cursor]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ThreadSearchOccurrence")}},
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

  defmodule ThreadSearchOccurrence do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.ThreadSearchOccurrencesResponse,
      as: ParentModule

    defstruct [:item_id, :snippet, :snippet_match_range, :turn_cursor, :turn_id]

    @field_specs [
      %{spec: :plain, field: :item_id, required: true, wire_key: "itemId"},
      %{spec: :plain, field: :snippet, required: true, wire_key: "snippet"},
      %{
        spec: {:module, Module.concat(ParentModule, "ThreadSearchTextRange")},
        field: :snippet_match_range,
        required: true,
        wire_key: "snippetMatchRange"
      },
      %{spec: :plain, field: :turn_cursor, required: true, wire_key: "turnCursor"},
      %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ThreadSearchTextRange do
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
end
