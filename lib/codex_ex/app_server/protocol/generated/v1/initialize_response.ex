defmodule CodexEx.AppServer.Protocol.Generated.V1.InitializeResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:codex_home, :platform_family, :platform_os, :user_agent]

  @field_specs [
    %{spec: :plain, field: :codex_home, required: true, wire_key: "codexHome"},
    %{spec: :plain, field: :platform_family, required: true, wire_key: "platformFamily"},
    %{spec: :plain, field: :platform_os, required: true, wire_key: "platformOs"},
    %{spec: :plain, field: :user_agent, required: true, wire_key: "userAgent"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
