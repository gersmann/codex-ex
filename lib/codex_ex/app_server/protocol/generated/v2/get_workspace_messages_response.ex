defmodule CodexEx.AppServer.Protocol.Generated.V2.GetWorkspaceMessagesResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:feature_enabled, :messages]

  @field_specs [
    %{spec: :plain, field: :feature_enabled, required: true, wire_key: "featureEnabled"},
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "WorkspaceMessage")}},
      field: :messages,
      required: true,
      wire_key: "messages"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule WorkspaceMessage do
    @moduledoc false

    defstruct [:archived_at, :created_at, :message_body, :message_id, :message_type]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :archived_at, required: false, wire_key: "archivedAt"},
      %{spec: {:nullable, :plain}, field: :created_at, required: false, wire_key: "createdAt"},
      %{spec: :plain, field: :message_body, required: true, wire_key: "messageBody"},
      %{spec: :plain, field: :message_id, required: true, wire_key: "messageId"},
      %{spec: :plain, field: :message_type, required: true, wire_key: "messageType"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
