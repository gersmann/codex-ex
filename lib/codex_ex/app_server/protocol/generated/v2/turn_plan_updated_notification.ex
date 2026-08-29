defmodule CodexEx.AppServer.Protocol.Generated.V2.TurnPlanUpdatedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:explanation, :plan, :thread_id, :turn_id]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :explanation, required: false, wire_key: "explanation"},
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "TurnPlanStep")}},
      field: :plan,
      required: true,
      wire_key: "plan"
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

  defmodule TurnPlanStep do
    @moduledoc false

    defstruct [:status, :step]

    @field_specs [
      %{spec: :plain, field: :status, required: true, wire_key: "status"},
      %{spec: :plain, field: :step, required: true, wire_key: "step"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
