defmodule CodexEx.AppServer.Protocol.Generated.V2.RawResponseCompletedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:response_id, :thread_id, :turn_id, :usage, :usage_metadata]

  @field_specs [
    %{spec: :plain, field: :response_id, required: true, wire_key: "responseId"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"},
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "TokenUsageBreakdown")}},
      field: :usage,
      required: false,
      wire_key: "usage"
    },
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "ResponseUsageMetadata")}},
      field: :usage_metadata,
      required: false,
      wire_key: "usageMetadata"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ResponseUsageMetadata do
    @moduledoc false

    defstruct [:amount, :metadata]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :amount, required: false, wire_key: "amount"},
      %{spec: :plain, field: :metadata, required: false, wire_key: "metadata"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule TokenUsageBreakdown do
    @moduledoc false

    defstruct [
      :cache_write_input_tokens,
      :cached_input_tokens,
      :input_tokens,
      :output_tokens,
      :reasoning_output_tokens,
      :total_tokens
    ]

    @field_specs [
      %{
        spec: :plain,
        field: :cache_write_input_tokens,
        required: false,
        wire_key: "cacheWriteInputTokens"
      },
      %{spec: :plain, field: :cached_input_tokens, required: true, wire_key: "cachedInputTokens"},
      %{spec: :plain, field: :input_tokens, required: true, wire_key: "inputTokens"},
      %{spec: :plain, field: :output_tokens, required: true, wire_key: "outputTokens"},
      %{
        spec: :plain,
        field: :reasoning_output_tokens,
        required: true,
        wire_key: "reasoningOutputTokens"
      },
      %{spec: :plain, field: :total_tokens, required: true, wire_key: "totalTokens"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
