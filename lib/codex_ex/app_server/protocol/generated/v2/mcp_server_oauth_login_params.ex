defmodule CodexEx.AppServer.Protocol.Generated.V2.McpServerOauthLoginParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:client_registration, :name, :scopes, :thread_id, :timeout_secs]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :client_registration,
      required: false,
      wire_key: "clientRegistration"
    },
    %{spec: :plain, field: :name, required: true, wire_key: "name"},
    %{spec: {:nullable, {:array, :plain}}, field: :scopes, required: false, wire_key: "scopes"},
    %{spec: {:nullable, :plain}, field: :thread_id, required: false, wire_key: "threadId"},
    %{spec: {:nullable, :plain}, field: :timeout_secs, required: false, wire_key: "timeoutSecs"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
