defmodule CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:answers]

  @field_specs [%{spec: :plain, field: :answers, required: true, wire_key: "answers"}]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ToolRequestUserInputAnswer do
    @moduledoc false

    defstruct [:answers]

    @field_specs [%{spec: {:array, :plain}, field: :answers, required: true, wire_key: "answers"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
