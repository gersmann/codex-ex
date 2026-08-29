defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadTokenUsageUpdatedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:thread_id, :token_usage, :turn_id]

  @field_specs [
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{
      spec: {:module, Module.concat(__MODULE__, "ThreadTokenUsage")},
      field: :token_usage,
      required: true,
      wire_key: "tokenUsage"
    },
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ThreadTokenUsage do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.ThreadTokenUsageUpdatedNotification,
      as: ParentModule

    defstruct [:last, :model_context_window, :total]

    @field_specs [
      %{
        spec: {:module, Module.concat(ParentModule, "TokenUsageBreakdown")},
        field: :last,
        required: true,
        wire_key: "last"
      },
      %{
        spec: {:nullable, :plain},
        field: :model_context_window,
        required: false,
        wire_key: "modelContextWindow"
      },
      %{
        spec: {:module, Module.concat(ParentModule, "TokenUsageBreakdown")},
        field: :total,
        required: true,
        wire_key: "total"
      }
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
