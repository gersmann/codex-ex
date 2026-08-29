defmodule CodexEx.AppServer.Protocol.Generated.Shared.ClientNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:id, :method, :params]

  @method_specs %{
    "initialized" => %{params_module: nil}
  }

  def methods, do: Map.keys(@method_specs)
  def known_method?(method) when is_binary(method), do: Map.has_key?(@method_specs, method)

  def decode(%{"method" => method} = payload) when is_binary(method) do
    spec = Map.get(@method_specs, method, %{})
    params_module = Map.get(spec, :params_module)
    params = Map.get(payload, "params")

    %__MODULE__{
      id: Map.get(payload, "id"),
      method: method,
      params: decode_params(params_module, params)
    }
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = message) do
    spec = Map.get(@method_specs, message.method, %{})

    %{"method" => message.method}
    |> maybe_put_id(message.id)
    |> maybe_put_params(Map.get(spec, :params_module), message.params)
  end

  def encode(other), do: Codec.encode_value(:plain, other)

  defp decode_params(nil, nil), do: nil
  defp decode_params(nil, params), do: params

  defp maybe_put_params(payload, nil, nil), do: payload
  defp maybe_put_params(payload, nil, %{} = params) when map_size(params) == 0, do: payload
  defp maybe_put_params(payload, nil, params), do: Map.put(payload, "params", params)

  defp maybe_put_id(payload, nil), do: payload
  defp maybe_put_id(payload, id), do: Map.put(payload, "id", id)
end
