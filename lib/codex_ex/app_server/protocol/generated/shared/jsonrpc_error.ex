defmodule CodexEx.AppServer.Protocol.Generated.Shared.JSONRPCError do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:error, :id]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "JSONRPCErrorError")},
      field: :error,
      required: true,
      wire_key: "error"
    },
    %{spec: :plain, field: :id, required: true, wire_key: "id"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule JSONRPCErrorError do
    @moduledoc false

    defstruct [:code, :data, :message]

    @field_specs [
      %{spec: :plain, field: :code, required: true, wire_key: "code"},
      %{spec: :plain, field: :data, required: false, wire_key: "data"},
      %{spec: :plain, field: :message, required: true, wire_key: "message"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
