defmodule CodexEx.AppServer.Protocol.Generated.V2.ErrorNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:error, :thread_id, :turn_id, :will_retry]

  @field_specs [
    %{
      spec: {:module, Module.concat(__MODULE__, "TurnError")},
      field: :error,
      required: true,
      wire_key: "error"
    },
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"},
    %{spec: :plain, field: :turn_id, required: true, wire_key: "turnId"},
    %{spec: :plain, field: :will_retry, required: true, wire_key: "willRetry"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule TurnError do
    @moduledoc false

    defstruct [:additional_details, :codex_error_info, :message]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :additional_details,
        required: false,
        wire_key: "additionalDetails"
      },
      %{
        spec: {:nullable, :plain},
        field: :codex_error_info,
        required: false,
        wire_key: "codexErrorInfo"
      },
      %{spec: :plain, field: :message, required: true, wire_key: "message"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
