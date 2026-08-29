defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadQueueStartParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:queued_submission_id, :thread_id]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :queued_submission_id,
      required: false,
      wire_key: "queuedSubmissionId"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
