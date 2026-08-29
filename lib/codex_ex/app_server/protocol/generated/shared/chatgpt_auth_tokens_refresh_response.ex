defmodule CodexEx.AppServer.Protocol.Generated.Shared.ChatgptAuthTokensRefreshResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:access_token, :chatgpt_account_id, :chatgpt_plan_type]

  @field_specs [
    %{spec: :plain, field: :access_token, required: true, wire_key: "accessToken"},
    %{spec: :plain, field: :chatgpt_account_id, required: true, wire_key: "chatgptAccountId"},
    %{
      spec: {:nullable, :plain},
      field: :chatgpt_plan_type,
      required: false,
      wire_key: "chatgptPlanType"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
