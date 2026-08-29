defmodule CodexEx.AppServer.Protocol.Generated.V2.ModelSafetyBufferingUpdatedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :faster_model,
    :model,
    :reasons,
    :show_buffering_ui,
    :thread_id,
    :turn_id,
    :use_cases
  ]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :faster_model, required: false, wire_key: "fasterModel"},
    %{spec: :plain, field: :model, required: true, wire_key: "model"},
    %{spec: {:array, :plain}, field: :reasons, required: true, wire_key: "reasons"},
    %{spec: :plain, field: :show_buffering_ui, required: true, wire_key: "showBufferingUi"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"},
    %{spec: {:array, :plain}, field: :use_cases, required: true, wire_key: "useCases"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
