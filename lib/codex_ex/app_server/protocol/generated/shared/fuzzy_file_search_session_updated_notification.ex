defmodule CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionUpdatedNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:files, :query, :session_id]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "FuzzyFileSearchResult")}},
      field: :files,
      required: true,
      wire_key: "files"
    },
    %{spec: :plain, field: :query, required: true, wire_key: "query"},
    %{spec: :plain, field: :session_id, required: true, wire_key: "sessionId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule FuzzyFileSearchResult do
    @moduledoc false

    defstruct [:file_name, :indices, :match_type, :path, :root, :score]

    @field_specs [
      %{spec: :plain, field: :file_name, required: true, wire_key: "file_name"},
      %{
        spec: {:nullable, {:array, :plain}},
        field: :indices,
        required: false,
        wire_key: "indices"
      },
      %{spec: :plain, field: :match_type, required: true, wire_key: "match_type"},
      %{spec: :plain, field: :path, required: true, wire_key: "path"},
      %{spec: :plain, field: :root, required: true, wire_key: "root"},
      %{spec: :plain, field: :score, required: true, wire_key: "score"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
