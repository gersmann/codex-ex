defmodule CodexEx.AppServer.Protocol.Generated.V2.FsReadDirectoryResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:entries]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "FsReadDirectoryEntry")}},
      field: :entries,
      required: true,
      wire_key: "entries"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule FsReadDirectoryEntry do
    @moduledoc false

    defstruct [:file_name, :is_directory, :is_file]

    @field_specs [
      %{spec: :plain, field: :file_name, required: true, wire_key: "fileName"},
      %{spec: :plain, field: :is_directory, required: true, wire_key: "isDirectory"},
      %{spec: :plain, field: :is_file, required: true, wire_key: "isFile"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
