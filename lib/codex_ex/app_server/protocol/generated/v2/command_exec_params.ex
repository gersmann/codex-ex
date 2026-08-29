defmodule CodexEx.AppServer.Protocol.Generated.V2.CommandExecParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :command,
    :cwd,
    :disable_output_cap,
    :disable_timeout,
    :env,
    :output_bytes_cap,
    :permission_profile,
    :process_id,
    :sandbox_policy,
    :size,
    :stream_stdin,
    :stream_stdout_stderr,
    :timeout_ms,
    :tty
  ]

  @field_specs [
    %{spec: {:array, :plain}, field: :command, required: true, wire_key: "command"},
    %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
    %{spec: :plain, field: :disable_output_cap, required: false, wire_key: "disableOutputCap"},
    %{spec: :plain, field: :disable_timeout, required: false, wire_key: "disableTimeout"},
    %{spec: {:nullable, :plain}, field: :env, required: false, wire_key: "env"},
    %{
      spec: {:nullable, :plain},
      field: :output_bytes_cap,
      required: false,
      wire_key: "outputBytesCap"
    },
    %{
      spec: {:nullable, :plain},
      field: :permission_profile,
      required: false,
      wire_key: "permissionProfile"
    },
    %{spec: {:nullable, :plain}, field: :process_id, required: false, wire_key: "processId"},
    %{
      spec: {:nullable, :plain},
      field: :sandbox_policy,
      required: false,
      wire_key: "sandboxPolicy"
    },
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "CommandExecTerminalSize")}},
      field: :size,
      required: false,
      wire_key: "size"
    },
    %{spec: :plain, field: :stream_stdin, required: false, wire_key: "streamStdin"},
    %{
      spec: :plain,
      field: :stream_stdout_stderr,
      required: false,
      wire_key: "streamStdoutStderr"
    },
    %{spec: {:nullable, :plain}, field: :timeout_ms, required: false, wire_key: "timeoutMs"},
    %{spec: :plain, field: :tty, required: false, wire_key: "tty"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule CommandExecTerminalSize do
    @moduledoc false

    defstruct [:cols, :rows]

    @field_specs [
      %{spec: :plain, field: :cols, required: true, wire_key: "cols"},
      %{spec: :plain, field: :rows, required: true, wire_key: "rows"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
