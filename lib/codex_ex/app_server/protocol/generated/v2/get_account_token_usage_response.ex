defmodule CodexEx.AppServer.Protocol.Generated.V2.GetAccountTokenUsageResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:daily_usage_buckets, :summary, :thread_usage]

  @field_specs [
    %{
      spec: {:nullable, {:array, {:module, Module.concat(__MODULE__, "AccountTokenUsageDailyBucket")}}},
      field: :daily_usage_buckets,
      required: false,
      wire_key: "dailyUsageBuckets"
    },
    %{
      spec: {:module, Module.concat(__MODULE__, "AccountTokenUsageSummary")},
      field: :summary,
      required: true,
      wire_key: "summary"
    },
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "ThreadUsage")}},
      field: :thread_usage,
      required: false,
      wire_key: "threadUsage"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule AccountTokenUsageDailyBucket do
    @moduledoc false

    defstruct [:start_date, :tokens]

    @field_specs [
      %{spec: :plain, field: :start_date, required: true, wire_key: "startDate"},
      %{spec: :plain, field: :tokens, required: true, wire_key: "tokens"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule AccountTokenUsageSummary do
    @moduledoc false

    defstruct [
      :current_streak_days,
      :lifetime_tokens,
      :longest_running_turn_sec,
      :longest_streak_days,
      :peak_daily_tokens
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :current_streak_days,
        required: false,
        wire_key: "currentStreakDays"
      },
      %{
        spec: {:nullable, :plain},
        field: :lifetime_tokens,
        required: false,
        wire_key: "lifetimeTokens"
      },
      %{
        spec: {:nullable, :plain},
        field: :longest_running_turn_sec,
        required: false,
        wire_key: "longestRunningTurnSec"
      },
      %{
        spec: {:nullable, :plain},
        field: :longest_streak_days,
        required: false,
        wire_key: "longestStreakDays"
      },
      %{
        spec: {:nullable, :plain},
        field: :peak_daily_tokens,
        required: false,
        wire_key: "peakDailyTokens"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ThreadUsage do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.GetAccountTokenUsageResponse, as: ParentModule

    defstruct [:estimated_usage_credits_micros, :estimated_usage_usd_micros, :groups, :thread_id]

    @field_specs [
      %{
        spec: :plain,
        field: :estimated_usage_credits_micros,
        required: true,
        wire_key: "estimatedUsageCreditsMicros"
      },
      %{
        spec: {:nullable, :plain},
        field: :estimated_usage_usd_micros,
        required: false,
        wire_key: "estimatedUsageUsdMicros"
      },
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ThreadUsageBreakdownGroup")}},
        field: :groups,
        required: true,
        wire_key: "groups"
      },
      %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ThreadUsageBreakdownGroup do
    @moduledoc false

    defstruct [
      :cached_input_tokens,
      :estimated_usage_credits_micros,
      :input_tokens,
      :model,
      :net_new_input_tokens,
      :output_tokens,
      :reasoning_effort,
      :speed,
      :total_tokens
    ]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :cached_input_tokens,
        required: false,
        wire_key: "cachedInputTokens"
      },
      %{
        spec: :plain,
        field: :estimated_usage_credits_micros,
        required: true,
        wire_key: "estimatedUsageCreditsMicros"
      },
      %{
        spec: {:nullable, :plain},
        field: :input_tokens,
        required: false,
        wire_key: "inputTokens"
      },
      %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
      %{
        spec: {:nullable, :plain},
        field: :net_new_input_tokens,
        required: false,
        wire_key: "netNewInputTokens"
      },
      %{
        spec: {:nullable, :plain},
        field: :output_tokens,
        required: false,
        wire_key: "outputTokens"
      },
      %{
        spec: {:nullable, :plain},
        field: :reasoning_effort,
        required: false,
        wire_key: "reasoningEffort"
      },
      %{spec: {:nullable, :plain}, field: :speed, required: false, wire_key: "speed"},
      %{spec: {:nullable, :plain}, field: :total_tokens, required: false, wire_key: "totalTokens"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
