defmodule CodexEx.AppServer.Turn do
  @moduledoc """
  Stable typed snapshot of an app-server turn.
  """

  alias CodexEx.AppServer.ProtocolValue
  alias CodexEx.AppServer.ThreadItem
  alias CodexEx.AppServer.Types

  defmodule Error do
    @moduledoc false

    defstruct [:additional_details, :codex_error_info, :message]

    @type t :: %__MODULE__{
            additional_details: Types.json_value() | nil,
            codex_error_info: Types.json_value() | nil,
            message: binary()
          }
  end

  defstruct [:diff, :duration_ms, :error, :id, :items, :status, :thread_id]

  @type t :: %__MODULE__{
          diff: binary() | nil,
          duration_ms: non_neg_integer() | nil,
          error: Error.t() | nil,
          id: binary(),
          items: [ThreadItem.t()],
          status: binary(),
          thread_id: binary()
        }

  @type result :: {:ok, t()} | {:error, {:invalid_turn, term()}}

  @spec from_protocol(map(), binary()) :: {:ok, %__MODULE__{}} | {:error, {:invalid_turn, term()}}
  def from_protocol(%module{} = turn, thread_id) when is_atom(module) and is_binary(thread_id) do
    turn
    |> Map.from_struct()
    |> from_map(thread_id)
  end

  def from_protocol(%{} = turn, thread_id) when is_binary(thread_id) do
    from_map(turn, thread_id)
  end

  @spec completed?(term()) :: boolean()
  def completed?(%__MODULE__{status: "completed"}), do: true
  def completed?(_turn), do: false

  @spec failed?(term()) :: boolean()
  def failed?(%__MODULE__{status: "failed"}), do: true
  def failed?(_turn), do: false

  @spec interrupted?(term()) :: boolean()
  def interrupted?(%__MODULE__{status: "interrupted"}), do: true
  def interrupted?(_turn), do: false

  defp from_map(%{} = turn, thread_id) do
    turn = ProtocolValue.normalize_map(turn)

    with {:ok, id} <- fetch_required_binary(turn, :id),
         {:ok, status} <- fetch_required_binary(turn, :status),
         {:ok, duration_ms} <- fetch_optional_non_neg_integer(turn, :duration_ms),
         {:ok, items} <- normalize_items(ProtocolValue.get(turn, :items)),
         {:ok, items} <- maybe_prepend_input_item(items, ProtocolValue.get(turn, :input), id),
         {:ok, error} <- normalize_error(ProtocolValue.get(turn, :error)) do
      {:ok,
       %__MODULE__{
         duration_ms: duration_ms,
         error: error,
         id: id,
         items: items,
         status: status,
         thread_id: thread_id
       }}
    end
  end

  defp normalize_error(nil), do: {:ok, nil}

  defp normalize_error(%module{} = error) when is_atom(module) do
    error
    |> Map.from_struct()
    |> normalize_error()
  end

  defp normalize_error(%{} = error) do
    error = ProtocolValue.normalize_map(error)

    with {:ok, message} <- fetch_required_binary(error, :message),
         {:ok, additional_details} <- fetch_optional_json(error, :additional_details),
         {:ok, codex_error_info} <- fetch_optional_json(error, :codex_error_info) do
      {:ok,
       %Error{
         additional_details: additional_details,
         codex_error_info: codex_error_info,
         message: message
       }}
    end
  end

  defp normalize_error(other), do: {:error, {:invalid_turn, {:invalid_error, other}}}

  defp normalize_items(items) when is_list(items) do
    items
    |> Enum.reduce_while({:ok, []}, fn item, {:ok, acc} ->
      case ThreadItem.from_protocol(item) do
        {:ok, parsed_item} -> {:cont, {:ok, [parsed_item | acc]}}
        {:error, reason} -> {:halt, {:error, {:invalid_turn, {:invalid_item, reason}}}}
      end
    end)
    |> case do
      {:ok, parsed_items} -> {:ok, Enum.reverse(parsed_items)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_items(nil), do: {:error, {:invalid_turn, {:missing_field, :items}}}
  defp normalize_items(other), do: {:error, {:invalid_turn, {:invalid_field, :items, other}}}

  defp maybe_prepend_input_item(items, nil, _turn_id) when is_list(items), do: {:ok, items}

  defp maybe_prepend_input_item(items, input, turn_id) when is_list(items) and is_binary(turn_id) do
    if input_user_message_present?(items) do
      {:ok, items}
    else
      case normalize_input_content(input) do
        {:ok, content} ->
          with {:ok, input_item} <- build_input_user_message(turn_id, content) do
            {:ok, maybe_prepend_synthesized_input(items, input_item)}
          end

        :skip ->
          {:ok, items}
      end
    end
  end

  defp maybe_prepend_input_item(items, _input, _turn_id), do: {:ok, items}

  defp input_user_message_present?(items) when is_list(items) do
    Enum.any?(items, &(ThreadItem.type(&1) == "userMessage"))
  end

  defp normalize_input_content(input) do
    case ProtocolValue.to_json_value(input) do
      {:ok, []} -> {:ok, []}
      {:ok, content} when is_list(content) -> {:ok, content}
      {:ok, _other} -> :skip
      {:error, _reason} -> :skip
    end
  end

  defp build_input_user_message(_turn_id, []), do: {:ok, nil}

  defp build_input_user_message(turn_id, content) when is_binary(turn_id) and is_list(content) do
    ThreadItem.from_protocol(%{
      "content" => content,
      "id" => "input-#{turn_id}",
      "type" => "userMessage"
    })
  end

  defp maybe_prepend_synthesized_input(items, nil) when is_list(items), do: items

  defp maybe_prepend_synthesized_input(items, input_item) when is_list(items), do: [input_item | items]

  defp fetch_required_binary(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      {:ok, value} -> {:error, {:invalid_turn, {:invalid_field, field, value}}}
      :error -> {:error, {:invalid_turn, {:missing_field, field}}}
    end
  end

  defp fetch_optional_json(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} ->
        case ProtocolValue.to_json_value(value) do
          {:ok, json_value} -> {:ok, json_value}
          {:error, reason} -> {:error, {:invalid_turn, reason}}
        end

      :error ->
        {:ok, nil}
    end
  end

  defp fetch_optional_non_neg_integer(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_integer(value) and value >= 0 -> {:ok, value}
      {:ok, nil} -> {:ok, nil}
      {:ok, value} -> {:error, {:invalid_turn, {:invalid_field, field, value}}}
      :error -> {:ok, nil}
    end
  end
end
