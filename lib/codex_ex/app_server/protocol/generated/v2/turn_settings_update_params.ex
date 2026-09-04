defmodule CodexEx.AppServer.Protocol.Generated.V2.TurnSettingsUpdateParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:approvals_reviewer, :effort, :model, :service_tier, :summary, :thread_id, :turn_id]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :approvals_reviewer,
      required: false,
      wire_key: "approvalsReviewer"
    },
    %{spec: {:nullable, :plain}, field: :effort, required: false, wire_key: "effort"},
    %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
    %{spec: {:nullable, :plain}, field: :service_tier, required: false, wire_key: "serviceTier"},
    %{spec: {:nullable, :plain}, field: :summary, required: false, wire_key: "summary"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
