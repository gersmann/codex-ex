defmodule CodexEx.AppServer.Protocol.Codec do
  @moduledoc false

  alias CodexEx.MapHelpers

  @type value_spec ::
          :plain
          | {:array, value_spec()}
          | {:module, module()}
          | {:nullable, value_spec()}

  @type field_spec :: %{
          required(:field) => atom(),
          required(:required) => boolean(),
          required(:spec) => value_spec(),
          required(:wire_key) => binary()
        }
  @dialyzer {:nowarn_function, [decode_value: 2, encode_value: 2]}

  @spec decode_object(term(), term(), term()) :: term()
  def decode_object(module, field_specs, payload) when is_atom(module) and is_list(field_specs) do
    payload = MapHelpers.stringify_keys(payload)

    attrs =
      Enum.reduce(field_specs, %{}, fn %{field: field, spec: spec, wire_key: wire_key}, acc ->
        Map.put(acc, field, decode_value(spec, Map.get(payload, wire_key)))
      end)

    struct(module, attrs)
  end

  def decode_object(_module, _field_specs, payload), do: payload

  @spec decode_value(term(), term()) :: term()
  def decode_value({:nullable, _spec}, nil), do: nil
  def decode_value({:nullable, spec}, value), do: decode_value(spec, value)

  def decode_value({:array, spec}, values) when is_list(values) do
    Enum.map(values, &decode_value(spec, &1))
  end

  def decode_value({:array, _spec}, value), do: value

  def decode_value({:module, module}, value) when is_map(value) do
    module.decode(value)
  end

  def decode_value({:module, _module}, value), do: value
  def decode_value(:plain, value), do: value

  @spec encode_object(term(), term()) :: term()
  def encode_object(struct, field_specs) when is_struct(struct) and is_list(field_specs) do
    values = Map.from_struct(struct)

    Enum.reduce(field_specs, %{}, fn %{
                                       field: field,
                                       required: required?,
                                       spec: spec,
                                       wire_key: wire_key
                                     },
                                     acc ->
      value = Map.get(values, field)

      if required? or not is_nil(value) do
        Map.put(acc, wire_key, encode_value(spec, value))
      else
        acc
      end
    end)
  end

  def encode_object(value, _field_specs), do: value

  @spec encode_value(term(), term()) :: term()
  def encode_value({:nullable, _spec}, nil), do: nil
  def encode_value({:nullable, spec}, value), do: encode_value(spec, value)

  def encode_value({:array, spec}, values) when is_list(values) do
    Enum.map(values, &encode_value(spec, &1))
  end

  def encode_value({:array, _spec}, value), do: value

  def encode_value({:module, module}, value), do: module.encode(value)

  def encode_value(:plain, %_{} = struct) do
    struct
    |> Map.from_struct()
    |> MapHelpers.deep_stringify_keys()
  end

  def encode_value(:plain, value), do: MapHelpers.deep_stringify_keys(value)
end
