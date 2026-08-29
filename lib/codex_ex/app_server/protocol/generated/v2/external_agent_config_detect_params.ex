defmodule CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigDetectParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :cwds,
    :include_home,
    :max_session_age_days,
    :max_sessions,
    :migration_source,
    :source
  ]

  @field_specs [
    %{spec: {:nullable, {:array, :plain}}, field: :cwds, required: false, wire_key: "cwds"},
    %{spec: :plain, field: :include_home, required: false, wire_key: "includeHome"},
    %{
      spec: {:nullable, :plain},
      field: :max_session_age_days,
      required: false,
      wire_key: "maxSessionAgeDays"
    },
    %{spec: {:nullable, :plain}, field: :max_sessions, required: false, wire_key: "maxSessions"},
    %{
      spec: {:nullable, :plain},
      field: :migration_source,
      required: false,
      wire_key: "migrationSource"
    },
    %{spec: {:nullable, :plain}, field: :source, required: false, wire_key: "source"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
