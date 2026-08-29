defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadMetadataUpdateParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:git_info, :thread_id]

  @field_specs [
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "ThreadMetadataGitInfoUpdateParams")}},
      field: :git_info,
      required: false,
      wire_key: "gitInfo"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ThreadMetadataGitInfoUpdateParams do
    @moduledoc false

    defstruct [:branch, :origin_url, :sha]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :branch, required: false, wire_key: "branch"},
      %{spec: {:nullable, :plain}, field: :origin_url, required: false, wire_key: "originUrl"},
      %{spec: {:nullable, :plain}, field: :sha, required: false, wire_key: "sha"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
