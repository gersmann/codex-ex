defmodule CodexEx.AppServer.Protocol.Generated.V2.FileChangePatchUpdatedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:changes, :item_id, :thread_id, :turn_id]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "FileUpdateChange")}},
      field: :changes,
      required: true,
      wire_key: "changes"
    },
    %{spec: :plain, field: :item_id, required: true, wire_key: "itemId"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule FileUpdateChange do
    @moduledoc false

    defstruct [:diff, :kind, :path]

    @field_specs [
      %{spec: :plain, field: :diff, required: true, wire_key: "diff"},
      %{spec: :plain, field: :kind, required: true, wire_key: "kind"},
      %{spec: :plain, field: :path, required: true, wire_key: "path"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
