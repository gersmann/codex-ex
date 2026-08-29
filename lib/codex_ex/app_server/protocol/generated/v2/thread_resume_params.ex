defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadResumeParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :approval_policy,
    :approvals_reviewer,
    :base_instructions,
    :config,
    :cwd,
    :developer_instructions,
    :exclude_turns,
    :history,
    :initial_turns_page,
    :model,
    :model_provider,
    :path,
    :permissions,
    :personality,
    :runtime_workspace_roots,
    :sandbox,
    :service_tier,
    :thread_id
  ]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :approval_policy,
      required: false,
      wire_key: "approvalPolicy"
    },
    %{
      spec: {:nullable, :plain},
      field: :approvals_reviewer,
      required: false,
      wire_key: "approvalsReviewer"
    },
    %{
      spec: {:nullable, :plain},
      field: :base_instructions,
      required: false,
      wire_key: "baseInstructions"
    },
    %{spec: {:nullable, :plain}, field: :config, required: false, wire_key: "config"},
    %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
    %{
      spec: {:nullable, :plain},
      field: :developer_instructions,
      required: false,
      wire_key: "developerInstructions"
    },
    %{spec: :plain, field: :exclude_turns, required: false, wire_key: "excludeTurns"},
    %{spec: {:nullable, {:array, :plain}}, field: :history, required: false, wire_key: "history"},
    %{
      spec: {:nullable, {:module, Module.concat(__MODULE__, "ThreadResumeInitialTurnsPageParams")}},
      field: :initial_turns_page,
      required: false,
      wire_key: "initialTurnsPage"
    },
    %{spec: {:nullable, :plain}, field: :model, required: false, wire_key: "model"},
    %{
      spec: {:nullable, :plain},
      field: :model_provider,
      required: false,
      wire_key: "modelProvider"
    },
    %{spec: {:nullable, :plain}, field: :path, required: false, wire_key: "path"},
    %{spec: {:nullable, :plain}, field: :permissions, required: false, wire_key: "permissions"},
    %{spec: {:nullable, :plain}, field: :personality, required: false, wire_key: "personality"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :runtime_workspace_roots,
      required: false,
      wire_key: "runtimeWorkspaceRoots"
    },
    %{spec: {:nullable, :plain}, field: :sandbox, required: false, wire_key: "sandbox"},
    %{spec: {:nullable, :plain}, field: :service_tier, required: false, wire_key: "serviceTier"},
    %{spec: :plain, field: :thread_id, required: true, wire_key: "threadId"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)

  defmodule InternalChatMessageMetadataPassthrough do
    @moduledoc false

    defstruct [:turn_id]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :turn_id, required: false, wire_key: "turn_id"}
    ]

    def decode(payload) when is_map(payload) do
      Codec.decode_object(__MODULE__, @field_specs, payload)
    end

    def decode(other), do: other

    def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

    def encode(other), do: Codec.encode_value(:plain, other)
  end

  defmodule ThreadResumeInitialTurnsPageParams do
    @moduledoc false

    defstruct [:items_view, :limit, :sort_direction]

    @field_specs [
      %{spec: {:nullable, :plain}, field: :items_view, required: false, wire_key: "itemsView"},
      %{spec: {:nullable, :plain}, field: :limit, required: false, wire_key: "limit"},
      %{
        spec: {:nullable, :plain},
        field: :sort_direction,
        required: false,
        wire_key: "sortDirection"
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
