defmodule CodexEx.AppServer.Protocol.Generated.V2.GetAccountRateLimitsResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.GetAccountRateLimitsResponse

  defstruct [:rate_limit_reset_credits, :rate_limits, :rate_limits_by_limit_id]

  @field_specs [
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "RateLimitResetCreditsSummary")}},
      field: :rate_limit_reset_credits,
      required: false,
      wire_key: "rateLimitResetCredits"
    },
    %{
      spec: {:module, Module.concat(__MODULE__, "RateLimitSnapshot")},
      field: :rate_limits,
      required: true,
      wire_key: "rateLimits"
    },
    %{
      spec: {:nullable, :plain},
      field: :rate_limits_by_limit_id,
      required: false,
      wire_key: "rateLimitsByLimitId"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule CreditsSnapshot do
    @moduledoc false

    defstruct [:balance, :has_credits, :unlimited]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :balance, required: false, wire_key: "balance"},
      %{spec: :plain, field: :has_credits, required: true, wire_key: "hasCredits"},
      %{spec: :plain, field: :unlimited, required: true, wire_key: "unlimited"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule RateLimitResetCredit do
    @moduledoc false

    defstruct [:description, :expires_at, :granted_at, :id, :reset_type, :status, :title]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :description, required: false, wire_key: "description"},
      %{spec: {:nullable, :plain}, field: :expires_at, required: false, wire_key: "expiresAt"},
      %{spec: :plain, field: :granted_at, required: true, wire_key: "grantedAt"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: :plain, field: :reset_type, required: true, wire_key: "resetType"},
      %{spec: :plain, field: :status, required: true, wire_key: "status"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule RateLimitResetCreditsSummary do
    @moduledoc false

    alias GetAccountRateLimitsResponse, as: ParentModule

    defstruct [:available_count, :credits]

    @field_specs [
      %{spec: :plain, field: :available_count, required: true, wire_key: "availableCount"},
      %{
        spec: {:nullable, {:array, {:module, Module.concat(ParentModule, "RateLimitResetCredit")}}},
        field: :credits,
        required: false,
        wire_key: "credits"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule RateLimitSnapshot do
    @moduledoc false

    alias GetAccountRateLimitsResponse, as: ParentModule

    defstruct [
      :credits,
      :individual_limit,
      :limit_id,
      :limit_name,
      :plan_type,
      :primary,
      :rate_limit_reached_type,
      :secondary,
      :spend_control_reached
    ]

    @field_specs [
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "CreditsSnapshot")}},
        field: :credits,
        required: false,
        wire_key: "credits"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "SpendControlLimitSnapshot")}},
        field: :individual_limit,
        required: false,
        wire_key: "individualLimit"
      },
      %{spec: {:nullable, :plain}, field: :limit_id, required: false, wire_key: "limitId"},
      %{spec: {:nullable, :plain}, field: :limit_name, required: false, wire_key: "limitName"},
      %{spec: {:nullable, :plain}, field: :plan_type, required: false, wire_key: "planType"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "RateLimitWindow")}},
        field: :primary,
        required: false,
        wire_key: "primary"
      },
      %{
        spec: {:nullable, :plain},
        field: :rate_limit_reached_type,
        required: false,
        wire_key: "rateLimitReachedType"
      },
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "RateLimitWindow")}},
        field: :secondary,
        required: false,
        wire_key: "secondary"
      },
      %{
        spec: {:nullable, :plain},
        field: :spend_control_reached,
        required: false,
        wire_key: "spendControlReached"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule RateLimitWindow do
    @moduledoc false

    defstruct [:resets_at, :used_percent, :window_duration_mins]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :resets_at, required: false, wire_key: "resetsAt"},
      %{spec: :plain, field: :used_percent, required: true, wire_key: "usedPercent"},
      %{
        spec: {:nullable, :plain},
        field: :window_duration_mins,
        required: false,
        wire_key: "windowDurationMins"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule SpendControlLimitSnapshot do
    @moduledoc false

    defstruct [:limit, :remaining_percent, :resets_at, :used]

    @field_specs [
      %{spec: :plain, field: :limit, required: true, wire_key: "limit"},
      %{spec: :plain, field: :remaining_percent, required: true, wire_key: "remainingPercent"},
      %{spec: :plain, field: :resets_at, required: true, wire_key: "resetsAt"},
      %{spec: :plain, field: :used, required: true, wire_key: "used"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
