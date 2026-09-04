defmodule CodexEx.AppServer.Protocol.Generated.V2.ThreadListParams do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [
    :ancestor_thread_id,
    :archived,
    :cursor,
    :cwd,
    :limit,
    :model_providers,
    :parent_thread_id,
    :project_id,
    :search_term,
    :section_id,
    :sort_direction,
    :sort_key,
    :source_kinds,
    :use_state_db_only
  ]

  @field_specs [
    %{
      spec: {:nullable, :plain},
      field: :ancestor_thread_id,
      required: false,
      wire_key: "ancestorThreadId"
    },
    %{spec: {:nullable, :plain}, field: :archived, required: false, wire_key: "archived"},
    %{spec: {:nullable, :plain}, field: :cursor, required: false, wire_key: "cursor"},
    %{spec: {:nullable, :plain}, field: :cwd, required: false, wire_key: "cwd"},
    %{spec: {:nullable, :plain}, field: :limit, required: false, wire_key: "limit"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :model_providers,
      required: false,
      wire_key: "modelProviders"
    },
    %{
      spec: {:nullable, :plain},
      field: :parent_thread_id,
      required: false,
      wire_key: "parentThreadId"
    },
    %{spec: {:nullable, :plain}, field: :project_id, required: false, wire_key: "projectId"},
    %{spec: {:nullable, :plain}, field: :search_term, required: false, wire_key: "searchTerm"},
    %{spec: {:nullable, :plain}, field: :section_id, required: false, wire_key: "sectionId"},
    %{
      spec: {:nullable, :plain},
      field: :sort_direction,
      required: false,
      wire_key: "sortDirection"
    },
    %{spec: {:nullable, :plain}, field: :sort_key, required: false, wire_key: "sortKey"},
    %{
      spec: {:nullable, {:array, :plain}},
      field: :source_kinds,
      required: false,
      wire_key: "sourceKinds"
    },
    %{spec: :plain, field: :use_state_db_only, required: false, wire_key: "useStateDbOnly"}
  ]

  def decode(payload) when is_map(payload) do
    Codec.decode_object(__MODULE__, @field_specs, payload)
  end

  def decode(other), do: other

  def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)

  def encode(other), do: Codec.encode_value(:plain, other)
end
