defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeStartParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :client_managed_handoffs,
    :codex_response_handoff_channel_prefixes,
    :codex_response_handoff_mode,
    :codex_response_item_prefix,
    :codex_responses_as_items,
    :delegation_ack_filler,
    :flush_transcript_tail_on_session_end,
    :include_startup_context,
    :initial_items,
    :model,
    :output_modality,
    :prompt,
    :realtime_end_instructions,
    :realtime_session_id,
    :realtime_start_instructions,
    :thread_id,
    :transport,
    :version,
    :voice
  ]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :client_managed_handoffs,
      required: false,
      wire_key: "clientManagedHandoffs"
    },
    %{
      spec: {:nullable, :plain},
      field: :codex_response_handoff_channel_prefixes,
      required: false,
      wire_key: "codexResponseHandoffChannelPrefixes"
    },
    %{
      spec: {:nullable, :plain},
      field: :codex_response_handoff_mode,
      required: false,
      wire_key: "codexResponseHandoffMode"
    },
    %{
      spec: {:nullable, :plain},
      field: :codex_response_item_prefix,
      required: false,
      wire_key: "codexResponseItemPrefix"
    },
    %{
      spec: {:nullable, :plain},
      field: :codex_responses_as_items,
      required: false,
      wire_key: "codexResponsesAsItems"
    },
    %{
      spec: {:nullable, :plain},
      field: :delegation_ack_filler,
      required: false,
      wire_key: "delegationAckFiller"
    },
    %{
      spec: {:nullable, :plain},
      field: :flush_transcript_tail_on_session_end,
      required: false,
      wire_key: "flushTranscriptTailOnSessionEnd"
    },
    %{
      spec: {:nullable, :plain},
      field: :include_startup_context,
      required: false,
      wire_key: "includeStartupContext"
    },
    %{
      spec: {:nullable, {:array, {:module, Module.concat(__MODULE__, "ThreadRealtimeInitialItem")}}},
      field: :initial_items,
      required: false,
      wire_key: "initialItems"
    },
    %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
    %{spec: :plain, field: :output_modality, required: true, wire_key: "outputModality"},
    %{spec: {:nullable, :plain}, field: :prompt, required: false, wire_key: "prompt"},
    %{
      spec: {:nullable, :plain},
      field: :realtime_end_instructions,
      required: false,
      wire_key: "realtimeEndInstructions"
    },
    %{
      spec: {:nullable, :plain},
      field: :realtime_session_id,
      required: false,
      wire_key: "realtimeSessionId"
    },
    %{
      spec: {:nullable, :plain},
      field: :realtime_start_instructions,
      required: false,
      wire_key: "realtimeStartInstructions"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: {:nullable, :plain}, field: :transport, required: false, wire_key: "transport"},
    %{spec: {:nullable, :plain}, field: :version, required: false, wire_key: "version"},
    %{spec: {:nullable, :plain}, field: :voice, required: false, wire_key: "voice"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ThreadRealtimeInitialItem do
    @moduledoc false

    defstruct [:role, :text]

    @field_specs [
      %{spec: :plain, field: :role, required: true, wire_key: "role"},
      %{spec: :plain, field: :text, required: true, wire_key: "text"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
