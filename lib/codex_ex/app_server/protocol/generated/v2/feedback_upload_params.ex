defmodule CodexEx.AppServer.Protocol.Generated.V2.FeedbackUploadParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:classification, :extra_log_files, :include_logs, :reason, :tags, :thread_id]

  @field_specs [
    %{spec: :plain, field: :classification, required: true, wire_key: "classification"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :extra_log_files,
      required: false,
      wire_key: "extraLogFiles"
    },
    %{spec: :plain, field: :include_logs, required: false, wire_key: "includeLogs"},
    %{spec: {:nullable, :plain}, field: :reason, required: false, wire_key: "reason"},
    %{spec: {:nullable, :plain}, field: :tags, required: false, wire_key: "tags"},
    %{spec: {:nullable, :plain}, field: :thread_id, required: false, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
