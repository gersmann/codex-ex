defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeOutputAudioDeltaNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:audio, :thread_id]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "ThreadRealtimeAudioChunk")},
      field: :audio,
      required: true,
      wire_key: "audio"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ThreadRealtimeAudioChunk do
    @moduledoc false

    defstruct [:data, :item_id, :num_channels, :sample_rate, :samples_per_channel]

    @field_specs [
      %{spec: :plain, field: :data, required: true, wire_key: "data"},
      %{spec: {:nullable, :plain}, field: :item_id, required: false, wire_key: "itemId"},
      %{spec: :plain, field: :num_channels, required: true, wire_key: "numChannels"},
      %{spec: :plain, field: :sample_rate, required: true, wire_key: "sampleRate"},
      %{
        spec: {:nullable, :plain},
        field: :samples_per_channel,
        required: false,
        wire_key: "samplesPerChannel"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
