defmodule CodexEx.AppServer.Protocol.Generated.Shared.DynamicToolCallResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:content_items, :success]

  @field_specs [
    %{spec: {:array, :plain}, field: :content_items, required: true, wire_key: "contentItems"},
    %{spec: :plain, field: :success, required: true, wire_key: "success"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
