defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadQueueReorderParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:queued_submission_ids, :thread_id]

  @field_specs [
    %{
      spec: {:array, :plain},
      field: :queued_submission_ids,
      required: true,
      wire_key: "queuedSubmissionIds"
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
