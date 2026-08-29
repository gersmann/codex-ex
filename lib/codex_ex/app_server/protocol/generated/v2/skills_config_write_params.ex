defmodule CodexEx.AppServer.Protocol.Generated.V2.SkillsConfigWriteParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:enabled, :name, :path]

  @field_specs [
    %{spec: :plain, field: :enabled, required: true, wire_key: "enabled"},
    %{spec: {:nullable, :plain}, field: :name, required: false, wire_key: "name"},
    %{spec: {:nullable, :plain}, field: :path, required: false, wire_key: "path"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
