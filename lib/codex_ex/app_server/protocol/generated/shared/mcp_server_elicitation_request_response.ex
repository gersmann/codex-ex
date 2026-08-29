defmodule CodexEx.AppServer.Protocol.Generated.Shared.McpServerElicitationRequestResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:_meta, :action, :content]

  @field_specs [
    %{spec: :plain, field: :_meta, required: false, wire_key: "_meta"},
    %{spec: :plain, field: :action, required: true, wire_key: "action"},
    %{spec: :plain, field: :content, required: false, wire_key: "content"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
