defmodule CodexEx.AppServer.Protocol.Generated.V2.DeprecationNoticeNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:details, :summary]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :details, required: false, wire_key: "details"},
    %{spec: :plain, field: :summary, required: true, wire_key: "summary"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
