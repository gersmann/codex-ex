defmodule CodexEx.AppServer.Protocol.Generated.V2.EnvironmentInfoResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:cwd, :shell]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
    %{
      spec: {:module, Module.concat(__MODULE__, "EnvironmentShellInfo")},
      field: :shell,
      required: true,
      wire_key: "shell"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule EnvironmentShellInfo do
    @moduledoc false

    defstruct [:name, :path]

    @field_specs [
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :path, required: true, wire_key: "path"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
