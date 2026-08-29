defmodule CodexEx.AppServer.Protocol.Generated.Shared.ChatgptAuthTokensRefreshParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:previous_account_id, :reason]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :previous_account_id,
      required: false,
      wire_key: "previousAccountId"
    },
    %{spec: :plain, field: :reason, required: true, wire_key: "reason"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
