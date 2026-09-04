defmodule CodexEx.AppServer.Protocol.Generated.V2.ProjectImportParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:idempotency_key, :metadata, :name, :roots, :threads]

  @field_specs [
    %{spec: :plain, field: :idempotency_key, required: true, wire_key: "idempotencyKey"},
    %{spec: {:nullable, :plain}, field: :metadata, required: false, wire_key: "metadata"},
    %{spec: :plain, field: :name, required: true, wire_key: "name"},
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ProjectRoot")}},
      field: :roots,
      required: true,
      wire_key: "roots"
    },
    %{spec: {:nullable, {:array, :plain}}, field: :threads, required: false, wire_key: "threads"}
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
