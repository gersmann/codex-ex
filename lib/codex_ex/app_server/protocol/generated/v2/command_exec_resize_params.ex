defmodule CodexEx.AppServer.Protocol.Generated.V2.CommandExecResizeParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:process_id, :size]

  @field_specs [
    %{spec: :plain, field: :process_id, required: true, wire_key: "processId"},
    %{
      spec: {:module, Module.concat(__MODULE__, "CommandExecTerminalSize")},
      field: :size,
      required: true,
      wire_key: "size"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule CommandExecTerminalSize do
    @moduledoc false

    defstruct [:cols, :rows]

    @field_specs [
      %{spec: :plain, field: :cols, required: true, wire_key: "cols"},
      %{spec: :plain, field: :rows, required: true, wire_key: "rows"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
