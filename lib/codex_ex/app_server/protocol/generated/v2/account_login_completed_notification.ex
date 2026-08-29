defmodule CodexEx.AppServer.Protocol.Generated.V2.AccountLoginCompletedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:error, :login_id, :onboarding_entrypoint, :success]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :error, required: false, wire_key: "error"},
    %{spec: {:nullable, :plain}, field: :login_id, required: false, wire_key: "loginId"},
    %{
      spec: {:nullable, :plain},
      field: :onboarding_entrypoint,
      required: false,
      wire_key: "onboardingEntrypoint"
    },
    %{spec: :plain, field: :success, required: true, wire_key: "success"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
