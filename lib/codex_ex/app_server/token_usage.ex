defmodule CodexEx.AppServer.TokenUsage do
  @moduledoc """
  Stable typed token-usage model for turn streams.
  """

  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadTokenUsageUpdatedNotification
  alias CodexEx.AppServer.ProtocolValue

  defmodule Breakdown do
    @moduledoc false

    defstruct [
      :cached_input_tokens,
      :input_tokens,
      :output_tokens,
      :reasoning_output_tokens,
      :total_tokens
    ]

    @type t :: %__MODULE__{
            cached_input_tokens: non_neg_integer(),
            input_tokens: non_neg_integer(),
            output_tokens: non_neg_integer(),
            reasoning_output_tokens: non_neg_integer(),
            total_tokens: non_neg_integer()
          }

    @type result :: {:ok, t()} | {:error, {:invalid_token_usage, term()}}

    @spec from_protocol(struct() | map()) :: result()
    def from_protocol(%__MODULE__{} = breakdown), do: {:ok, breakdown}

    def from_protocol(%ThreadTokenUsageUpdatedNotification.TokenUsageBreakdown{} = breakdown) do
      breakdown
      |> Map.from_struct()
      |> from_map()
    end

    def from_protocol(%{} = breakdown), do: from_map(ProtocolValue.normalize_map(breakdown))

    def from_protocol(other), do: {:error, {:invalid_token_usage, {:unexpected_payload, other}}}

    defp from_map(%{} = breakdown) do
      with {:ok, cached_input_tokens} <- fetch_required_integer(breakdown, :cached_input_tokens),
           {:ok, input_tokens} <- fetch_required_integer(breakdown, :input_tokens),
           {:ok, output_tokens} <- fetch_required_integer(breakdown, :output_tokens),
           {:ok, reasoning_output_tokens} <-
             fetch_required_integer(breakdown, :reasoning_output_tokens),
           {:ok, total_tokens} <- fetch_required_integer(breakdown, :total_tokens) do
        {:ok,
         %__MODULE__{
           cached_input_tokens: cached_input_tokens,
           input_tokens: input_tokens,
           output_tokens: output_tokens,
           reasoning_output_tokens: reasoning_output_tokens,
           total_tokens: total_tokens
         }}
      end
    end

    defp fetch_required_integer(map, field) do
      case ProtocolValue.fetch(map, field) do
        {:ok, value} when is_integer(value) and value >= 0 ->
          {:ok, value}

        {:ok, value} ->
          {:error, {:invalid_token_usage, {:invalid_field, field, value}}}

        :error ->
          {:error, {:invalid_token_usage, {:missing_field, field}}}
      end
    end
  end

  defstruct [:last, :model_context_window, :total]

  @type t :: %__MODULE__{
          last: Breakdown.t(),
          model_context_window: non_neg_integer() | nil,
          total: Breakdown.t()
        }

  @type result :: {:ok, t()} | {:error, {:invalid_token_usage, term()}}

  @spec from_protocol(struct() | map()) :: result()
  def from_protocol(%__MODULE__{} = usage), do: {:ok, usage}

  def from_protocol(%ThreadTokenUsageUpdatedNotification.ThreadTokenUsage{} = usage) do
    usage
    |> Map.from_struct()
    |> from_map()
  end

  def from_protocol(%{} = usage), do: from_map(ProtocolValue.normalize_map(usage))
  def from_protocol(other), do: {:error, {:invalid_token_usage, {:unexpected_payload, other}}}

  defp from_map(%{} = usage) do
    with {:ok, last} <- normalize_breakdown(ProtocolValue.get(usage, :last), :last),
         {:ok, total} <- normalize_breakdown(ProtocolValue.get(usage, :total), :total),
         {:ok, model_context_window} <- fetch_optional_integer(usage, :model_context_window) do
      {:ok,
       %__MODULE__{
         last: last,
         model_context_window: model_context_window,
         total: total
       }}
    end
  end

  defp normalize_breakdown(nil, field) do
    {:error, {:invalid_token_usage, {:missing_field, field}}}
  end

  defp normalize_breakdown(value, _field), do: Breakdown.from_protocol(value)

  defp fetch_optional_integer(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_integer(value) and value >= 0 ->
        {:ok, value}

      {:ok, nil} ->
        {:ok, nil}

      {:ok, value} ->
        {:error, {:invalid_token_usage, {:invalid_field, field, value}}}

      :error ->
        {:ok, nil}
    end
  end
end
