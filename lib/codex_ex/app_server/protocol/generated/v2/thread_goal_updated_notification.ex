defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalUpdatedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:goal, :thread_id, :turn_id]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "ThreadGoal")},
      field: :goal,
      required: true,
      wire_key: "goal"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: {:nullable, :plain}, field: :turn_id, required: false, wire_key: "turnId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ThreadGoal do
    @moduledoc false

    defstruct [
      :created_at,
      :objective,
      :status,
      :thread_id,
      :time_used_seconds,
      :token_budget,
      :tokens_used,
      :updated_at
    ]

    @field_specs [
      %{spec: :plain, field: :created_at, required: true, wire_key: "createdAt"},
      %{spec: :plain, field: :objective, required: true, wire_key: "objective"},
      %{spec: :plain, field: :status, required: true, wire_key: "status"},
      %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
      %{spec: :plain, field: :time_used_seconds, required: true, wire_key: "timeUsedSeconds"},
      %{
        spec: {:nullable, :plain},
        field: :token_budget,
        required: false,
        wire_key: "tokenBudget"
      },
      %{spec: :plain, field: :tokens_used, required: true, wire_key: "tokensUsed"},
      %{spec: :plain, field: :updated_at, required: true, wire_key: "updatedAt"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
