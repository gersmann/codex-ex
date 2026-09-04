defmodule CodexEx.AppServer.Protocol.Generated.V2.ErrorNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.ErrorNotification

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

  defmodule MisalignmentErrorDetails do
    @moduledoc false

    alias ErrorNotification, as: ParentModule

    defstruct [:detailed_explanation, :error_type, :steer]

    @field_specs [
      %{
        spec: {:nullable, :plain},
        field: :detailed_explanation,
        required: false,
        wire_key: "detailedExplanation"
      },
      %{spec: {:nullable, :plain}, field: :error_type, required: false, wire_key: "errorType"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "MisalignmentSteer")}},
        field: :steer,
        required: false,
        wire_key: "steer"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule MisalignmentSteer do
    @moduledoc false

    defstruct [:message]

    @field_specs [%{spec: :plain, field: :message, required: true, wire_key: "message"}]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule TurnError do
    @moduledoc false

    alias ErrorNotification, as: ParentModule

    defstruct [:additional_details, :codex_error_info, :message, :misalignment]

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
      %{spec: :plain, field: :message, required: true, wire_key: "message"},
      %{
        spec: {:nullable, {:module, Module.concat(ParentModule, "MisalignmentErrorDetails")}},
        field: :misalignment,
        required: false,
        wire_key: "misalignment"
      }
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
