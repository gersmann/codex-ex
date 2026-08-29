defmodule CodexEx.AppServer.ProtocolValue do
  @moduledoc false
  @dialyzer {:nowarn_function, [fetch: 3, get: 4, to_json_value: 1]}

  @spec normalize_map(struct() | map()) :: map()
  def normalize_map(%module{} = value) when is_atom(module), do: Map.from_struct(value)
  def normalize_map(%{} = value), do: value

  @spec fetch(term(), term(), term()) :: {:ok, term()} | :error
  def fetch(map, key, extra_keys \\ [])

  def fetch(map, key, extra_keys) when is_map(map) do
    map = normalize_map(map)

    direct_candidates = direct_candidates_for(key, extra_keys)

    case fetch_direct(map, direct_candidates) do
      {:ok, _value} = result ->
        result

      :error ->
        lookup_forms = lookup_forms_for(key, extra_keys)

        Enum.find_value(map, :error, fn {candidate, value} ->
          if candidate_matches_lookup_forms?(candidate, lookup_forms) do
            {:ok, value}
          end
        end)
    end
  end

  def fetch(_map, _key, _extra_keys), do: :error

  @spec get(map(), atom() | binary(), term(), list()) :: term()
  def get(map, key, default \\ nil, extra_keys \\ []) when is_map(map) do
    case fetch(map, key, extra_keys) do
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

  defp direct_candidates_for(key, extra_keys) when is_atom(key) do
    string_key = Atom.to_string(key)

    Enum.uniq([key, string_key, camelize(string_key) | extra_keys])
  end

  defp direct_candidates_for(key, extra_keys) when is_binary(key) do
    Enum.uniq([key | extra_keys])
  end

  defp lookup_forms_for(key, extra_keys) when is_atom(key) do
    key
    |> Atom.to_string()
    |> lookup_forms_for(extra_keys)
  end

  defp lookup_forms_for(key, extra_keys) when is_binary(key) do
    extras =
      Enum.flat_map(extra_keys, fn extra_key ->
        case extra_key do
          value when is_binary(value) -> [value, Macro.underscore(value), camelize(value)]
          value when is_atom(value) -> [Atom.to_string(value)]
        end
      end)

    Enum.uniq([key, Macro.underscore(key), camelize(key) | extras])
  end

  defp fetch_direct(map, candidates) do
    Enum.find_value(candidates, :error, fn candidate ->
      case Map.fetch(map, candidate) do
        {:ok, value} -> {:ok, value}
        :error -> nil
      end
    end)
  end

  defp candidate_matches_lookup_forms?(candidate, lookup_forms) when is_atom(candidate) do
    Atom.to_string(candidate) in lookup_forms
  end

  defp candidate_matches_lookup_forms?(candidate, lookup_forms) when is_binary(candidate) do
    candidate in lookup_forms
  end

  defp candidate_matches_lookup_forms?(_candidate, _lookup_forms), do: false

  defp camelize(string_key) do
    camelized =
      string_key
      |> Macro.underscore()
      |> Macro.camelize()

    first = String.first(camelized) || ""
    String.replace_prefix(camelized, first, String.downcase(first))
  end

  defp normalize_json_key(key) when is_binary(key), do: {:ok, key}
  defp normalize_json_key(key) when is_atom(key), do: {:ok, Atom.to_string(key)}
  defp normalize_json_key(other), do: {:error, {:invalid_json_key, other}}
end
