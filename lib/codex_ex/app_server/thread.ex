defmodule CodexEx.AppServer.Thread do
  @moduledoc """
  Public thread service object for the app-server client.

  The struct keeps the owning client plus the latest typed thread snapshot.
  Refreshing returns a fresh `%Thread{}` with the latest snapshot.
  """

  alias CodexEx.AppServer.Client
  alias CodexEx.AppServer.ThreadSettings
  alias CodexEx.AppServer.ThreadSnapshot

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
end
