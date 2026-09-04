defmodule CodexEx.AppServer.Protocol.Generated.V2.ProjectMoveParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:before_project_id, :project_id]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :before_project_id,
      required: false,
      wire_key: "beforeProjectId"
    },
    %{spec: :plain, field: :project_id, required: true, wire_key: "projectId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
