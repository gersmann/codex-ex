defmodule CodexEx.AppServer.Protocol.Generated.Shared.JSONRPCRequest do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:id, :method, :params, :trace]

  @field_specs [
    %{spec: :plain, field: :id, required: true, wire_key: "id"},
    %{spec: :plain, field: :method, required: true, wire_key: "method"},
    %{spec: :plain, field: :params, required: false, wire_key: "params"},
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "W3cTraceContext")}},
      field: :trace,
      required: false,
      wire_key: "trace"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule W3cTraceContext do
    @moduledoc false

    defstruct [:traceparent, :tracestate]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :traceparent, required: false, wire_key: "traceparent"},
      %{spec: {:nullable, :plain}, field: :tracestate, required: false, wire_key: "tracestate"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
