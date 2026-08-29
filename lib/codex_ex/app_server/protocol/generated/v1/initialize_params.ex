defmodule CodexEx.AppServer.Protocol.Generated.V1.InitializeParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:capabilities, :client_info]

  @field_specs [
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "InitializeCapabilities")}},
      field: :capabilities,
      required: false,
      wire_key: "capabilities"
    },
    %{
      spec: {:module, Module.concat(__MODULE__, "ClientInfo")},
      field: :client_info,
      required: true,
      wire_key: "clientInfo"
    }
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule ClientInfo do
    @moduledoc false

    defstruct [:name, :title, :version]

    @field_specs [
      %{spec: :plain, field: :name, required: true, wire_key: "name"},
      %{spec: {:nullable, :plain}, field: :title, required: false, wire_key: "title"},
      %{spec: :plain, field: :version, required: true, wire_key: "version"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule InitializeCapabilities do
    @moduledoc false

    defstruct [
      :experimental_api,
      :extensions,
      :mcp_server_openai_form_elicitation,
      :opt_out_notification_methods,
      :request_attestation
    ]

    @field_specs [
      %{spec: :plain, field: :experimental_api, required: false, wire_key: "experimentalApi"},
      %{spec: {:nullable, :plain}, field: :extensions, required: false, wire_key: "extensions"},
      %{
        spec: :plain,
        field: :mcp_server_openai_form_elicitation,
        required: false,
        wire_key: "mcpServerOpenaiFormElicitation"
      },
      %{
        spec: {:nullable, {:array, :plain}},
        field: :opt_out_notification_methods,
        required: false,
        wire_key: "optOutNotificationMethods"
      },
      %{
        spec: :plain,
        field: :request_attestation,
        required: false,
        wire_key: "requestAttestation"
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
