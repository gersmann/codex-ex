defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalSetParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:objective, :status, :thread_id, :token_budget]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :objective, required: false, wire_key: "objective"},
    %{spec: {:nullable, :plain}, field: :status, required: false, wire_key: "status"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: {:nullable, :plain}, field: :token_budget, required: false, wire_key: "tokenBudget"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
