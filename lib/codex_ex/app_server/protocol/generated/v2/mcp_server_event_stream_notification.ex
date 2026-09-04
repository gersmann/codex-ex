defmodule CodexEx.AppServer.Protocol.Generated.V2.McpServerEventStreamNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:notification, :subscription_id]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "McpServerEventNotification")},
      field: :notification,
      required: true,
      wire_key: "notification"
    },
    %{spec: :plain, field: :subscription_id, required: true, wire_key: "subscriptionId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule McpServerEventNotification do
    @moduledoc false

    defstruct [:method, :params]

    @field_specs [
      %{spec: :plain, field: :method, required: true, wire_key: "method"},
      %{spec: :plain, field: :params, required: true, wire_key: "params"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
