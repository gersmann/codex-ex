defmodule CodexEx.AppServer.Protocol.Generated.V2.WindowsSandboxSetupStartParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:cwd, :mode]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
    %{spec: :plain, field: :mode, required: true, wire_key: "mode"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
