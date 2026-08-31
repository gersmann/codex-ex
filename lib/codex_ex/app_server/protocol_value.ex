defmodule CodexEx.AppServer.ProtocolValue do
  @moduledoc false
  @dialyzer {:nowarn_function, [fetch: 2, get: 3, to_json_value: 1]}

  @spec normalize_map(struct() | map()) :: map()
  def normalize_map(%module{} = value) when is_atom(module), do: Map.from_struct(value)
  def normalize_map(%{} = value), do: value

  @spec fetch(term(), atom() | binary()) :: {:ok, term()} | :error
  def fetch(map, key) when is_map(map) do
    map = normalize_map(map)

    key
    |> direct_candidates_for()
    |> Enum.find_value(:error, fn candidate ->
      case Map.fetch(map, candidate) do
        {:ok, value} -> {:ok, value}
        :error -> nil
      end
    end)
  end

  def fetch(_map, _key), do: :error

  @spec get(map(), atom() | binary(), term()) :: term()
  def get(map, key, default \\ nil) when is_map(map) do
    case fetch(map, key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @spec to_json_value(term()) :: {:ok, term()} | {:error, term()}
  def to_json_value(nil), do: {:ok, nil}
  def to_json_value(value) when is_boolean(value), do: {:ok, value}
  def to_json_value(value) when is_integer(value), do: {:ok, value}
  def to_json_value(value) when is_float(value), do: {:ok, value}
  def to_json_value(value) when is_binary(value), do: {:ok, value}

  def to_json_value(%module{} = value) when is_atom(module) do
    value
    |> Map.from_struct()
    |> to_json_value()
  end

  def to_json_value(value) when is_list(value) do
    value
    |> Enum.reduce_while({:ok, []}, fn item, {:ok, acc} ->
      case to_json_value(item) do
        {:ok, json_value} -> {:cont, {:ok, [json_value | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, values} -> {:ok, Enum.reverse(values)}
      {:error, reason} -> {:error, reason}
    end
  end

  def to_json_value(value) when is_map(value) do
    Enum.reduce_while(value, {:ok, %{}}, fn {key, nested_value}, {:ok, acc} ->
      with {:ok, normalized_key} <- normalize_json_key(key),
           {:ok, normalized_value} <- to_json_value(nested_value) do
        {:cont, {:ok, Map.put(acc, normalized_key, normalized_value)}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  def to_json_value(other), do: {:error, {:invalid_json_value, other}}

  defp direct_candidates_for(key) when is_atom(key) do
    string_key = Atom.to_string(key)

    [key, string_key, camelize(string_key)]
  end

  defp direct_candidates_for(key) when is_binary(key), do: [key]

  defp camelize(string_key) do
    camelized =
      string_key
      |> Macro.underscore()
      |> Macro.camelize()

    {first, rest} = String.split_at(camelized, 1)
    String.downcase(first) <> rest
  end

  defp normalize_json_key(key) when is_binary(key), do: {:ok, key}
  defp normalize_json_key(key) when is_atom(key), do: {:ok, Atom.to_string(key)}
  defp normalize_json_key(other), do: {:error, {:invalid_json_key, other}}
end
