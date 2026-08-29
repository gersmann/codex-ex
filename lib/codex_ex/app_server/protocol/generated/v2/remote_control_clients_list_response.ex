defmodule CodexEx.AppServer.Protocol.Generated.V2.RemoteControlClientsListResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data, :next_cursor]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "RemoteControlClient")}},
      field: :data,
      required: true,
      wire_key: "data"
    },
    %{spec: {:nullable, :plain}, field: :next_cursor, required: false, wire_key: "nextCursor"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule RemoteControlClient do
    @moduledoc false

    defstruct [
      :app_version,
      :client_id,
      :device_model,
      :device_type,
      :display_name,
      :last_seen_at,
      :os_version,
      :platform
    ]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :app_version, required: false, wire_key: "appVersion"},
      %{spec: :plain, field: :client_id, required: true, wire_key: "clientId"},
      %{
        spec: {:nullable, :plain},
        field: :device_model,
        required: false,
        wire_key: "deviceModel"
      },
      %{spec: {:nullable, :plain}, field: :device_type, required: false, wire_key: "deviceType"},
      %{
        spec: {:nullable, :plain},
        field: :display_name,
        required: false,
        wire_key: "displayName"
      },
      %{spec: {:nullable, :plain}, field: :last_seen_at, required: false, wire_key: "lastSeenAt"},
      %{spec: {:nullable, :plain}, field: :os_version, required: false, wire_key: "osVersion"},
      %{spec: {:nullable, :plain}, field: :platform, required: false, wire_key: "platform"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
