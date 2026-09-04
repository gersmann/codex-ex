defmodule CodexEx.AppServer.Protocol.Generated.V2.ProjectUpdateParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:metadata, :name, :project_id, :roots]

  @field_specs [
    %{spec: {:nullable, :plain}, field: :metadata, required: false, wire_key: "metadata"},
    %{spec: {:nullable, :plain}, field: :name, required: false, wire_key: "name"},
    %{spec: :plain, field: :project_id, required: true, wire_key: "projectId"},
    %{
      spec: {:nullable, {:array, {:module, Module.concat(__MODULE__, "ProjectRoot")}}},
      field: :roots,
      required: false,
      wire_key: "roots"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ProjectRoot do
    @moduledoc false

    defstruct [:path]

    @field_specs [%{spec: :plain, field: :path, required: true, wire_key: "path"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
