defmodule CodexEx.AppServer.Thread do
  @moduledoc """
  Public thread service object for the app-server client.

  The struct keeps the owning client plus the latest typed thread snapshot.
  Operations that mutate server state return a fresh `%Thread{}` with an updated
  snapshot when the server returns one.
  """

  alias CodexEx.AppServer.Client
  alias CodexEx.AppServer.ThreadGoal
  alias CodexEx.AppServer.ThreadSettings
  alias CodexEx.AppServer.ThreadSnapshot
  alias CodexEx.AppServer.TurnStream

  defstruct [
    :client,
    :id,
    :settings,
    :snapshot
  ]

  @type t :: %__MODULE__{
          client: Client.t(),
          id: binary(),
          settings: ThreadSettings.t() | nil,
          snapshot: ThreadSnapshot.t()
        }

  @spec new(Client.t(), ThreadSnapshot.t(), ThreadSettings.t() | nil) :: %__MODULE__{}
  def new(client, %ThreadSnapshot{id: id} = snapshot, settings \\ nil) when is_binary(id) do
    %__MODULE__{
      client: client,
      id: id,
      settings: settings,
      snapshot: snapshot
    }
  end

  @spec refresh(%__MODULE__{}, keyword()) :: {:ok, %__MODULE__{}} | {:error, term()}
  def refresh(%__MODULE__{client: client, id: id, snapshot: %ThreadSnapshot{} = snapshot} = thread, opts \\ [])
      when is_binary(id) and is_list(opts) do
    opts = Keyword.put_new(opts, :history_mode, snapshot.history_mode)

    case Client.read_thread(client, id, opts) do
      {:ok, %ThreadSnapshot{id: refreshed_id} = snapshot} ->
        {:ok, %{thread | id: refreshed_id, snapshot: snapshot}}

      {:error, _reason} = error ->
        error
    end
  end

  @doc "Lists one backwards page of full turns for a paginated thread."
  @spec list_turns_page(%__MODULE__{}, keyword()) ::
          {:ok, Client.thread_turns_page()} | {:error, term()}
  def list_turns_page(thread, opts \\ [])

  def list_turns_page(%__MODULE__{client: client, id: id, snapshot: %ThreadSnapshot{history_mode: "paginated"}}, opts)
      when is_binary(id) and is_list(opts) do
    Client.list_thread_turns(client, id, opts)
  end

  def list_turns_page(%__MODULE__{snapshot: %ThreadSnapshot{history_mode: history_mode}}, opts) when is_list(opts),
    do: {:error, {:unsupported_thread_history_mode, history_mode}}

  @spec fork(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, term()}
  def fork(%__MODULE__{client: client, id: id}, overrides \\ %{}) when is_binary(id) and is_map(overrides) do
    case Client.fork_thread(client, id, overrides) do
      {:ok, %__MODULE__{} = thread} -> {:ok, thread}
      {:error, _reason} = error -> error
    end
  end

  @spec archive(%__MODULE__{}) :: :ok | {:error, term()}
  def archive(%__MODULE__{client: client, id: id}) when is_binary(id) do
    case Client.archive_thread(client, id) do
      :ok -> :ok
      {:error, _reason} = error -> error
    end
  end

  @spec unarchive(%__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, term()}
  def unarchive(%__MODULE__{client: client, id: id}) when is_binary(id) do
    case Client.unarchive_thread(client, id) do
      {:ok, %__MODULE__{} = thread} -> {:ok, thread}
      {:error, _reason} = error -> error
    end
  end

  @spec set_goal(%__MODULE__{}, map()) :: {:ok, ThreadGoal.t()} | {:error, term()}
  def set_goal(%__MODULE__{client: client, id: id}, attrs) when is_binary(id) and is_map(attrs) do
    Client.set_thread_goal(client, id, attrs)
  end

  @spec get_goal(%__MODULE__{}) :: {:ok, ThreadGoal.t() | nil} | {:error, term()}
  def get_goal(%__MODULE__{client: client, id: id}) when is_binary(id) do
    Client.get_thread_goal(client, id)
  end

  @spec clear_goal(%__MODULE__{}) :: :ok | {:error, term()}
  def clear_goal(%__MODULE__{client: client, id: id}) when is_binary(id) do
    Client.clear_thread_goal(client, id)
  end

  @spec run(%__MODULE__{}, list(), map()) ::
          {:ok, TurnStream.t()} | {:error, term()}
  def run(%__MODULE__{client: client, id: id}, input, opts \\ %{})
      when is_binary(id) and is_list(input) and is_map(opts) do
    case Client.run(client, id, input, opts) do
      {:ok, %TurnStream{} = stream} -> {:ok, stream}
      {:error, _reason} = error -> error
    end
  end

  @spec run_text(%__MODULE__{}, binary(), map()) :: {:ok, binary()} | {:error, term()}
  def run_text(%__MODULE__{client: client, id: id}, text, opts \\ %{})
      when is_binary(id) and is_binary(text) and is_map(opts) do
    case Client.run_text(client, id, text, opts) do
      {:ok, response} when is_binary(response) -> {:ok, response}
      {:error, _reason} = error -> error
    end
  end

  @spec run_json(%__MODULE__{}, binary(), map(), map()) :: {:ok, term()} | {:error, term()}
  def run_json(%__MODULE__{client: client, id: id}, text, output_schema, opts \\ %{})
      when is_binary(id) and is_binary(text) and is_map(output_schema) and is_map(opts) do
    case Client.run_json(client, id, text, output_schema, opts) do
      {:ok, response} -> {:ok, response}
      {:error, _reason} = error -> error
    end
  end
end
