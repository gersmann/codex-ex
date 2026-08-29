defmodule CodexEx.AppServer.ThreadGoal do
  @moduledoc """
  Stable app-server thread goal value.
  """

  alias CodexEx.AppServer.ProtocolValue
  alias CodexEx.AppServer.Types

  defstruct [
    :created_at,
    :objective,
    :status,
    :thread_id,
    :time_used_seconds,
    :token_budget,
    :tokens_used,
    :updated_at
  ]

  @type status :: :active | :paused | :budget_limited | :complete

  @type t :: %__MODULE__{
          created_at: Types.timestamp(),
          objective: binary(),
          status: status(),
          thread_id: binary(),
          time_used_seconds: non_neg_integer(),
          token_budget: non_neg_integer() | nil,
          tokens_used: non_neg_integer(),
          updated_at: Types.timestamp()
        }

  @type result :: {:ok, t()} | {:error, {:invalid_thread_goal, term()}}

  @spec from_protocol(map() | struct()) :: result()
  def from_protocol(%module{} = goal) when is_atom(module) do
    goal
    |> Map.from_struct()
    |> from_map()
  end

  def from_protocol(%{} = goal), do: from_map(goal)
  def from_protocol(other), do: {:error, {:invalid_thread_goal, {:invalid_goal, other}}}

  defp from_map(%{} = goal) do
    goal = ProtocolValue.normalize_map(goal)

    with {:ok, created_at} <- fetch_required_timestamp(goal, :created_at),
         {:ok, objective} <- fetch_required_binary(goal, :objective),
         {:ok, status} <- normalize_status(ProtocolValue.get(goal, :status)),
         {:ok, thread_id} <- fetch_required_binary(goal, :thread_id),
         {:ok, time_used_seconds} <- fetch_required_non_neg_integer(goal, :time_used_seconds),
         {:ok, token_budget} <- fetch_optional_non_neg_integer(goal, :token_budget),
         {:ok, tokens_used} <- fetch_required_non_neg_integer(goal, :tokens_used),
         {:ok, updated_at} <- fetch_required_timestamp(goal, :updated_at) do
      {:ok,
       %__MODULE__{
         created_at: created_at,
         objective: objective,
         status: status,
         thread_id: thread_id,
         time_used_seconds: time_used_seconds,
         token_budget: token_budget,
         tokens_used: tokens_used,
         updated_at: updated_at
       }}
    end
  end

  defp normalize_status("active"), do: {:ok, :active}
  defp normalize_status("paused"), do: {:ok, :paused}
  defp normalize_status("budgetLimited"), do: {:ok, :budget_limited}
  defp normalize_status("complete"), do: {:ok, :complete}
  defp normalize_status(:active), do: {:ok, :active}
  defp normalize_status(:paused), do: {:ok, :paused}
  defp normalize_status(:budget_limited), do: {:ok, :budget_limited}
  defp normalize_status(:complete), do: {:ok, :complete}

  defp normalize_status(other), do: {:error, {:invalid_thread_goal, {:invalid_field, :status, other}}}

  defp fetch_required_binary(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      {:ok, value} -> {:error, {:invalid_thread_goal, {:invalid_field, field, value}}}
      :error -> {:error, {:invalid_thread_goal, {:missing_field, field}}}
    end
  end

  defp fetch_required_timestamp(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_integer(value) or is_float(value) -> {:ok, value}
      {:ok, value} -> {:error, {:invalid_thread_goal, {:invalid_field, field, value}}}
      :error -> {:error, {:invalid_thread_goal, {:missing_field, field}}}
    end
  end

  defp fetch_required_non_neg_integer(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_integer(value) and value >= 0 -> {:ok, value}
      {:ok, value} -> {:error, {:invalid_thread_goal, {:invalid_field, field, value}}}
      :error -> {:error, {:invalid_thread_goal, {:missing_field, field}}}
    end
  end

  defp fetch_optional_non_neg_integer(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_integer(value) and value >= 0 -> {:ok, value}
      {:ok, nil} -> {:ok, nil}
      {:ok, value} -> {:error, {:invalid_thread_goal, {:invalid_field, field, value}}}
      :error -> {:ok, nil}
    end
  end
end
