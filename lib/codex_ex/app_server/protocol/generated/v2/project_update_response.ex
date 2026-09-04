defmodule CodexEx.AppServer.Protocol.Generated.V2.ProjectUpdateResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:project]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "Project")},
      field: :project,
      required: true,
      wire_key: "project"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule Project do
    @moduledoc false

    alias CodexEx.AppServer.Protocol.Generated.V2.ProjectUpdateResponse, as: ParentModule

    defstruct [:created_at, :id, :metadata, :name, :position, :recency_at, :roots, :updated_at]

    @field_specs [
      %{spec: :plain, field: :created_at, required: true, wire_key: "createdAt"},
      %{spec: :plain, field: :id, required: true, wire_key: "id"},
      %{spec: :plain, field: :metadata, required: true, wire_key: "metadata"},
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: :plain, field: :position, required: true, wire_key: "position"},
      %{spec: {:nullable, :plain}, field: :recency_at, required: false, wire_key: "recencyAt"},
      %{
        spec: {:array, {:module, Module.concat(ParentModule, "ProjectRoot")}},
        field: :roots,
        required: true,
        wire_key: "roots"
      },
      %{spec: :plain, field: :updated_at, required: true, wire_key: "updatedAt"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

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
