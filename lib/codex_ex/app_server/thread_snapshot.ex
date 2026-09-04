defmodule CodexEx.AppServer.ThreadSnapshot do
  @moduledoc """
  Stable typed snapshot of an app-server thread.
  """

  alias CodexEx.AppServer.ProtocolValue
  alias CodexEx.AppServer.Turn
  alias CodexEx.AppServer.Types

  @subagent_sources ~w(subAgent subAgentReview subAgentCompact subAgentThreadSpawn subAgentOther)

  # Protocol snapshots are validated before this predicate; Dialyzer widens struct patterns.
  @dialyzer {:nowarn_function, subagent?: 1}

  defmodule GitInfo do
    @moduledoc false

    defstruct [:branch, :origin_url, :sha]

    @type t :: %__MODULE__{
            branch: binary() | nil,
            origin_url: binary() | nil,
            sha: binary() | nil
          }
  end

  defstruct [
    :agent_nickname,
    :agent_role,
    :cli_version,
    :created_at,
    :cwd,
    :ephemeral,
    :git_info,
    :id,
    :model_provider,
    :name,
    :path,
    :preview,
    :source,
    :status,
    :thread_source,
    :turns,
    :updated_at,
    history_mode: "legacy"
  ]

  @type t :: %__MODULE__{
          agent_nickname: binary() | nil,
          agent_role: binary() | nil,
          cli_version: binary(),
          created_at: Types.timestamp(),
          cwd: binary(),
          ephemeral: boolean(),
          git_info: GitInfo.t() | nil,
          history_mode: binary(),
          id: binary(),
          model_provider: binary(),
          name: binary() | nil,
          path: binary() | nil,
          preview: binary(),
          source: binary(),
          status: binary(),
          thread_source: binary() | nil,
          turns: [Turn.t()],
          updated_at: Types.timestamp()
        }

  @type result :: {:ok, t()} | {:error, {:invalid_thread_snapshot, term()}}

  @spec from_protocol(map()) ::
          {:ok, %__MODULE__{}} | {:error, {:invalid_thread_snapshot, term()}}
  def from_protocol(%module{} = thread) when is_atom(module) do
    thread
    |> Map.from_struct()
    |> from_map()
  end

  def from_protocol(%{} = thread), do: from_map(thread)

  defp from_map(%{} = thread) do
    thread = ProtocolValue.normalize_map(thread)

    with {:ok, id} <- fetch_required_binary(thread, :id),
         {:ok, cli_version} <- fetch_required_binary(thread, :cli_version),
         {:ok, created_at} <- fetch_required_timestamp(thread, :created_at),
         {:ok, cwd} <- fetch_required_binary(thread, :cwd),
         {:ok, ephemeral} <- fetch_required_boolean(thread, :ephemeral),
         {:ok, git_info} <- normalize_git_info(ProtocolValue.get(thread, :git_info)),
         {:ok, history_mode} <- normalize_history_mode(ProtocolValue.get(thread, :history_mode)),
         {:ok, model_provider} <- fetch_required_binary(thread, :model_provider),
         {:ok, preview} <- fetch_required_binary(thread, :preview),
         {:ok, source} <- normalize_source(ProtocolValue.get(thread, :source)),
         {:ok, status} <- normalize_status(ProtocolValue.get(thread, :status)),
         {:ok, thread_source} <- fetch_optional_binary(thread, :thread_source),
         {:ok, updated_at} <- fetch_required_timestamp(thread, :updated_at),
         {:ok, turns} <- normalize_turns(ProtocolValue.get(thread, :turns), id),
         {:ok, agent_nickname} <- fetch_optional_binary(thread, :agent_nickname),
         {:ok, agent_role} <- fetch_optional_binary(thread, :agent_role),
         {:ok, name} <- fetch_optional_binary(thread, :name),
         {:ok, path} <- fetch_optional_binary(thread, :path) do
      {:ok,
       %__MODULE__{
         agent_nickname: agent_nickname,
         agent_role: agent_role,
         cli_version: cli_version,
         created_at: created_at,
         cwd: cwd,
         ephemeral: ephemeral,
         git_info: git_info,
         history_mode: history_mode,
         id: id,
         model_provider: model_provider,
         name: name,
         path: path,
         preview: preview,
         source: source,
         status: status,
         thread_source: thread_source,
         turns: turns,
         updated_at: updated_at
       }}
    end
  end

  @spec subagent?(t()) :: boolean()
  def subagent?(%__MODULE__{thread_source: "subagent"}), do: true
  def subagent?(%__MODULE__{source: source}) when source in @subagent_sources, do: true
  def subagent?(%__MODULE__{}), do: false

  # Persisted App snapshots use the thread/list source classification strings.
  # Decode the wire union here so local and remote observation share that contract.
  defp normalize_source(source) when is_binary(source), do: {:ok, source}

  defp normalize_source(%{"custom" => name} = source)
       when is_binary(name) and map_size(source) == 1, do: {:ok, "custom"}

  defp normalize_source(%{"subAgent" => source} = value) when map_size(value) == 1 do
    case source do
      "review" ->
        {:ok, "subAgentReview"}

      "compact" ->
        {:ok, "subAgentCompact"}

      "memory_consolidation" ->
        {:ok, "subAgentOther"}

      %{"other" => name} when is_binary(name) ->
        {:ok, "subAgentOther"}

      %{"thread_spawn" => %{"depth" => depth, "parent_thread_id" => parent_id}}
      when is_integer(depth) and is_binary(parent_id) ->
        {:ok, "subAgentThreadSpawn"}

      _other ->
        {:error, {:invalid_thread_snapshot, {:invalid_field, :source, value}}}
    end
  end

  defp normalize_source(source),
    do: {:error, {:invalid_thread_snapshot, {:invalid_field, :source, source}}}

  defp normalize_git_info(nil), do: {:ok, nil}

  defp normalize_git_info(%module{} = git_info) when is_atom(module) do
    git_info
    |> Map.from_struct()
    |> normalize_git_info()
  end

  defp normalize_git_info(%{} = git_info) do
    git_info = ProtocolValue.normalize_map(git_info)

    with {:ok, branch} <- fetch_optional_binary(git_info, :branch),
         {:ok, origin_url} <- fetch_optional_binary(git_info, :origin_url),
         {:ok, sha} <- fetch_optional_binary(git_info, :sha) do
      {:ok,
       %GitInfo{
         branch: branch,
         origin_url: origin_url,
         sha: sha
       }}
    end
  end

  defp normalize_git_info(other),
    do: {:error, {:invalid_thread_snapshot, {:invalid_git_info, other}}}

  defp normalize_history_mode(nil), do: {:ok, "legacy"}
  defp normalize_history_mode(mode) when mode in ["legacy", "paginated"], do: {:ok, mode}

  defp normalize_history_mode(other),
    do: {:error, {:invalid_thread_snapshot, {:invalid_field, :history_mode, other}}}

  defp normalize_status(status) when is_binary(status), do: {:ok, status}

  defp normalize_status(%module{} = status) when is_atom(module) do
    status
    |> Map.from_struct()
    |> normalize_status()
  end

  defp normalize_status(%{} = status) do
    status = ProtocolValue.normalize_map(status)

    case ProtocolValue.fetch(status, :type) do
      {:ok, type} when is_binary(type) -> {:ok, type}
      {:ok, value} -> {:error, {:invalid_thread_snapshot, {:invalid_field, :status, value}}}
      :error -> {:error, {:invalid_thread_snapshot, {:missing_field, :status}}}
    end
  end

  defp normalize_status(nil), do: {:error, {:invalid_thread_snapshot, {:missing_field, :status}}}

  defp normalize_status(other),
    do: {:error, {:invalid_thread_snapshot, {:invalid_field, :status, other}}}

  defp normalize_turns(turns, thread_id) when is_list(turns) do
    turns
    |> Enum.reduce_while({:ok, []}, fn turn, {:ok, acc} ->
      case Turn.from_protocol(turn, thread_id) do
        {:ok, parsed_turn} -> {:cont, {:ok, [parsed_turn | acc]}}
        {:error, reason} -> {:halt, {:error, {:invalid_thread_snapshot, {:invalid_turn, reason}}}}
      end
    end)
    |> case do
      {:ok, parsed_turns} -> {:ok, Enum.reverse(parsed_turns)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_turns(nil, _thread_id),
    do: {:error, {:invalid_thread_snapshot, {:missing_field, :turns}}}

  defp normalize_turns(other, _thread_id),
    do: {:error, {:invalid_thread_snapshot, {:invalid_field, :turns, other}}}

  defp fetch_required_binary(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      {:ok, value} -> {:error, {:invalid_thread_snapshot, {:invalid_field, field, value}}}
      :error -> {:error, {:invalid_thread_snapshot, {:missing_field, field}}}
    end
  end

  defp fetch_optional_binary(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      {:ok, nil} -> {:ok, nil}
      {:ok, value} -> {:error, {:invalid_thread_snapshot, {:invalid_field, field, value}}}
      :error -> {:ok, nil}
    end
  end

  defp fetch_required_boolean(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_boolean(value) -> {:ok, value}
      {:ok, value} -> {:error, {:invalid_thread_snapshot, {:invalid_field, field, value}}}
      :error -> {:error, {:invalid_thread_snapshot, {:missing_field, field}}}
    end
  end

  defp fetch_required_timestamp(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_integer(value) or is_float(value) -> {:ok, value}
      {:ok, value} -> {:error, {:invalid_thread_snapshot, {:invalid_field, field, value}}}
      :error -> {:error, {:invalid_thread_snapshot, {:missing_field, field}}}
    end
  end
end
