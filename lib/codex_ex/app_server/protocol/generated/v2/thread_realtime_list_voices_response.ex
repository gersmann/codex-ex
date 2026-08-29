defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeListVoicesResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:voices]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "RealtimeVoicesList")},
      field: :voices,
      required: true,
      wire_key: "voices"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule RealtimeVoicesList do
    @moduledoc false

    defstruct [:default_v1, :default_v2, :v1, :v2]

    @field_specs [
      %{spec: :plain, field: :default_v1, required: true, wire_key: "defaultV1"},
      %{spec: :plain, field: :default_v2, required: true, wire_key: "defaultV2"},
      %{spec: {:array, :plain}, field: :v1, required: true, wire_key: "v1"},
      %{spec: {:array, :plain}, field: :v2, required: true, wire_key: "v2"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
