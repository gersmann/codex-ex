defmodule CodexEx.AppServer.Protocol.Generated.V2.ProcessSpawnParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :command,
    :cwd,
    :env,
    :output_bytes_cap,
    :process_handle,
    :size,
    :stream_stdin,
    :stream_stdout_stderr,
    :timeout_ms,
    :tty
  ]

  @field_specs [
    %{spec: {:array, :plain}, field: :command, required: true, wire_key: "command"},
    %{spec: :plain, field: :cwd, required: true, wire_key: "cwd"},
    %{spec: {:nullable, :plain}, field: :env, required: false, wire_key: "env"},
    %{
      spec: {:nullable, :plain},
      field: :output_bytes_cap,
      required: false,
      wire_key: "outputBytesCap"
    },
    %{spec: :plain, field: :process_handle, required: true, wire_key: "processHandle"},
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "ProcessTerminalSize")}},
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

  defmodule ProcessTerminalSize do
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
