defmodule CodexEx.MapHelpers do
  @moduledoc """
  Shallow key normalisation for maps entering from external sources.
  """

  @doc """
  Converts atom keys to string keys (one level deep).

      iex> CodexEx.MapHelpers.stringify_keys(%{"bar" => 2, foo: 1})
      %{"foo" => 1, "bar" => 2}
  """
  @spec stringify_keys(term()) :: term()
  def stringify_keys(%_{} = struct), do: struct

  def stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      pair -> pair
    end)
  end

  def stringify_keys(other), do: other

  @doc """
  Recursively converts atom keys to string keys across nested maps/lists.
  """
  @spec deep_stringify_keys(term()) :: term()
  def deep_stringify_keys(%_{} = struct), do: struct

  def deep_stringify_keys(map) when is_map(map) do
    map
    |> stringify_keys()
    |> Map.new(fn {key, value} -> {key, deep_stringify_keys(value)} end)
  end

  def deep_stringify_keys(list) when is_list(list), do: Enum.map(list, &deep_stringify_keys/1)
  def deep_stringify_keys(other), do: other
end
