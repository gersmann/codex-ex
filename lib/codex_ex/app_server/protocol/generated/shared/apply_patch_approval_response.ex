defmodule CodexEx.AppServer.Protocol.Generated.Shared.ApplyPatchApprovalResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:decision]

  @field_specs [%{spec: :plain, field: :decision, required: true, wire_key: "decision"}]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule NetworkPolicyAmendment do
    @moduledoc false

    defstruct [:action, :host]

    @field_specs [
      %{spec: :plain, field: :action, required: true, wire_key: "action"},
      %{spec: :plain, field: :host, required: true, wire_key: "host"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
