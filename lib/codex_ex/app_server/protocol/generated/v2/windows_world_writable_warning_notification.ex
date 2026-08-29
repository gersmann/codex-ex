defmodule CodexEx.AppServer.Protocol.Generated.V2.WindowsWorldWritableWarningNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:extra_count, :failed_scan, :sample_paths]

  @field_specs [
    %{spec: :plain, field: :extra_count, required: true, wire_key: "extraCount"},
    %{spec: :plain, field: :failed_scan, required: true, wire_key: "failedScan"},
    %{spec: {:array, :plain}, field: :sample_paths, required: true, wire_key: "samplePaths"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
