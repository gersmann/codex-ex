defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadBackgroundTerminalsListResponse do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:data, :next_cursor]

  @field_specs [
    %{
      spec: {:array, {:module, Module.concat(__MODULE__, "ThreadBackgroundTerminal")}},
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

  defmodule ThreadBackgroundTerminal do
    @moduledoc false

    defstruct [:command, :cpu_percent, :cwd, :item_id, :os_pid, :process_id, :rss_kb]

    @field_specs [
      %{spec: :plain, field: :command, required: true, wire_key: "command"},
      %{spec: {:nullable, :plain}, field: :cpu_percent, required: false, wire_key: "cpuPercent"},
      %{spec: :plain, field: :cwd, required: true, wire_key: "cwd"},
      %{spec: :plain, field: :item_id, required: true, wire_key: "itemId"},
      %{spec: {:nullable, :plain}, field: :os_pid, required: false, wire_key: "osPid"},
      %{spec: :plain, field: :process_id, required: true, wire_key: "processId"},
      %{spec: {:nullable, :plain}, field: :rss_kb, required: false, wire_key: "rssKb"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end
end
