defmodule CodexEx.AppServer.Transport do
  @moduledoc false

  @type handle :: term()
  @type open_error :: term()
  @type close_reason :: term()
  @type normalized_message ::
          {:data, binary()}
          | {:data, binary(), non_neg_integer()}
          | {:closed, close_reason()}
          | {:closed, close_reason(), non_neg_integer()}
          | {:replay_gap, map()}
          | :ignore

  @callback open(keyword()) :: {:ok, handle()} | {:error, open_error()}
  @callback send(handle(), binary()) :: :ok | {:error, term()}
  @callback close(handle()) :: :ok
  @callback normalize_message(term(), handle()) :: normalized_message()

  # Remote transports bridge to app-server sessions that outlive this node.
  # `ClientManager` uses `remote_transport?/0` to pick stable transport ids and
  # calls `reconcile_thread_activity/1` with the runner id when such a client
  # goes down. `Session` calls the acknowledgement callbacks for sequenced
  # transports and `session_bootstrap/1` to reattach retained sessions.
  @callback remote_transport?() :: boolean()
  @callback reconcile_thread_activity(runner_id :: binary()) :: :ok
  @callback acknowledge(handle(), sequence :: non_neg_integer()) :: :ok
  @callback acknowledge_replay_gap(handle(), through_sequence :: non_neg_integer()) :: :ok
  @callback session_bootstrap(handle()) :: {handle(), map()}

  @optional_callbacks remote_transport?: 0,
                      reconcile_thread_activity: 1,
                      acknowledge: 2,
                      acknowledge_replay_gap: 2,
                      session_bootstrap: 1
end
