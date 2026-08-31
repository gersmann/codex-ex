defmodule CodexEx.AppServer.TurnStream do
  @moduledoc """
  Typed collector for a single app-server turn.

  The stream subscribes to the client, scopes notifications to one turn, and
  accumulates typed turn state until completion.
  """

  use GenServer

  alias CodexEx.AppServer.Client
  alias CodexEx.AppServer.Message
  alias CodexEx.AppServer.ThreadItem
  alias CodexEx.AppServer.TokenUsage
  alias CodexEx.AppServer.Turn

  @default_wait_timeout_ms 30 * 60 * 1_000

  defstruct [
    :final_text,
    :final_turn,
    :initial_turn,
    :items,
    :pid,
    :text_deltas,
    :thread_id,
    :turn_id,
    :usage
  ]

  @type t :: %__MODULE__{
          final_text: binary(),
          final_turn: Turn.t() | nil,
          initial_turn: Turn.t() | nil,
          items: [ThreadItem.t()],
          pid: pid(),
          text_deltas: [binary()],
          thread_id: binary(),
          turn_id: binary() | nil,
          usage: TokenUsage.t() | nil
        }

  @type state :: %{
          completion: :pending | :rpc_succeeded | {:error, term()},
          direct?: boolean(),
          client: Client.t(),
          event_final_turn: Turn.t() | nil,
          final_text: binary(),
          initial_turn: Turn.t() | nil,
          item_order_rev: [term()],
          item_ref_by_id: %{optional(binary()) => term()},
          items_by_ref: %{optional(term()) => ThreadItem.t()},
          next_item_ref: non_neg_integer(),
          pending_messages_rev: [Message.t()],
          rpc_final_turn: Turn.t() | nil,
          request_task: Task.t(),
          text_deltas_rev: [binary()],
          thread_id: binary(),
          turn_id: binary() | nil,
          usage: TokenUsage.t() | nil,
          waiters: [GenServer.from()],
          stop_when_done?: boolean(),
          subscribed?: boolean()
        }
  @dialyzer {:nowarn_function, [start: 4, start_request: 4]}

  @spec start(Client.t(), binary(), map(), boolean()) ::
          {:ok, %__MODULE__{}} | {:error, term()}
  def start(client, thread_id, params, direct? \\ true)
      when is_binary(thread_id) and is_map(params) and is_boolean(direct?) do
    start_request(
      client,
      thread_id,
      fn -> Client.start_turn_request(client, params) end,
      direct?
    )
  end

  @spec start_request(
          Client.t(),
          binary(),
          (-> {:ok, Turn.t()} | {:error, term()}),
          boolean()
        ) ::
          {:ok, %__MODULE__{}} | {:error, term()}
  def start_request(client, thread_id, request_fun, direct? \\ true)
      when is_binary(thread_id) and is_function(request_fun, 0) and is_boolean(direct?) do
    with {:ok, pid} <-
           GenServer.start_link(__MODULE__, {client, thread_id, request_fun, direct?}) do
      stream = snapshot(pid)
      if !direct?, do: GenServer.cast(pid, :stop_when_done)
      {:ok, stream}
    end
  end

  @spec snapshot(%__MODULE__{} | pid()) :: %__MODULE__{}
  def snapshot(%__MODULE__{pid: pid}), do: snapshot(pid)

  def snapshot(pid) when is_pid(pid) do
    (%__MODULE__{} = snapshot) = GenServer.call(pid, :snapshot)
    snapshot
  end

  @spec wait(term(), term()) :: {:ok, %__MODULE__{}} | {:error, term()}
  def wait(%__MODULE__{pid: pid}, timeout \\ @default_wait_timeout_ms) when is_integer(timeout) or timeout == :infinity do
    case GenServer.call(pid, :wait, bounded_wait_timeout(timeout)) do
      {:ok, %__MODULE__{} = stream} -> {:ok, stream}
      {:error, _reason} = error -> error
    end
  catch
    :exit, reason -> {:error, {:turn_stream_call_failed, reason}}
  end

  @spec ensure_success(t()) :: :ok | {:error, term()}
  def ensure_success(%__MODULE__{final_turn: nil}) do
    {:error, :turn_not_completed}
  end

  def ensure_success(%__MODULE__{final_turn: %Turn{status: "failed"} = turn}) do
    {:error, {:turn_failed, turn}}
  end

  def ensure_success(%__MODULE__{final_turn: %Turn{status: "interrupted"} = turn}) do
    {:error, {:turn_interrupted, turn}}
  end

  def ensure_success(%__MODULE__{}), do: :ok

  @spec final_json(t()) :: {:ok, term()} | {:error, term()}
  def final_json(%__MODULE__{final_text: final_text}) when is_binary(final_text) do
    case Jason.decode(final_text) do
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, {:invalid_json, reason}}
    end
  end

  @impl true
  def init({client, thread_id, request_fun, direct?}) when is_function(request_fun, 0) and is_boolean(direct?) do
    :ok = Client.subscribe(client, self(), thread_id: thread_id)

    request_task =
      Task.Supervisor.async_nolink(CodexEx.TaskSupervisor, fn ->
        request_fun.()
      end)

    {:ok,
     %{
       completion: :pending,
       direct?: direct?,
       client: client,
       event_final_turn: nil,
       final_text: "",
       initial_turn: nil,
       item_order_rev: [],
       item_ref_by_id: %{},
       items_by_ref: %{},
       next_item_ref: 0,
       pending_messages_rev: [],
       rpc_final_turn: nil,
       request_task: request_task,
       text_deltas_rev: [],
       thread_id: thread_id,
       turn_id: nil,
       usage: nil,
       waiters: [],
       stop_when_done?: false,
       subscribed?: true
     }}
  end

  @impl true
  def handle_cast(:stop_when_done, state) do
    if complete?(state) do
      {:stop, :normal, state}
    else
      {:noreply, %{state | stop_when_done?: true}}
    end
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, to_public(state), state}
  end

  def handle_call(:wait, from, state) do
    if complete?(state) do
      {:stop, :normal, wait_reply(state), state}
    else
      {:noreply, %{state | waiters: [from | state.waiters], stop_when_done?: true}}
    end
  end

  @impl true
  def handle_info({:codex_app_server_event, message}, state) do
    {:noreply, handle_event_message(state, message)}
  end

  def handle_info(
        {:codex_app_server_replay_gap, _client, %{"missing_through_sequence" => through_sequence} = payload},
        state
      )
      when is_integer(through_sequence) and through_sequence >= 0 do
    state =
      if state.direct? do
        state
        |> Map.put(:completion, {:error, {:transport_replay_gap, payload}})
        |> maybe_finish()
      else
        state
      end

    {:noreply, state}
  end

  def handle_info({ref, {:ok, %Turn{} = turn}}, %{request_task: %Task{ref: ref}} = state) do
    Process.demonitor(ref, [:flush])

    if complete?(state) do
      {:noreply, state}
    else
      state =
        state
        |> put_turn_items(turn)
        |> put_turn(turn)
        |> maybe_hydrate_final_text_from_turn(turn)
        |> put_rpc_final_turn(turn)
        |> Map.put(:completion, :rpc_succeeded)
        |> replay_pending_messages()

      {:noreply, maybe_finish(state)}
    end
  end

  def handle_info({ref, {:error, reason}}, %{request_task: %Task{ref: ref}} = state) do
    Process.demonitor(ref, [:flush])

    if complete?(state) do
      {:noreply, state}
    else
      {:noreply, state |> Map.put(:completion, {:error, reason}) |> maybe_finish()}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %{request_task: %Task{ref: ref}} = state) do
    if complete?(state) do
      {:noreply, state}
    else
      {:noreply,
       state
       |> Map.put(:completion, {:error, {:turn_stream_crash, reason}})
       |> maybe_finish()}
    end
  end

  def handle_info(:stop_completed_stream, %{stop_when_done?: true} = state) do
    if complete?(state), do: {:stop, :normal, state}, else: {:noreply, state}
  end

  def handle_info(:stop_completed_stream, state), do: {:noreply, state}

  def handle_info(_message, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, state) do
    _ = if state.subscribed?, do: Client.unsubscribe(state.client, self())
    _ = Task.shutdown(state.request_task, :brutal_kill)
    :ok
  end

  defp handle_event_message(state, message) do
    cond do
      complete?(state) -> state
      is_nil(state.turn_id) -> maybe_buffer_message(state, message)
      true -> state |> apply_message(message) |> maybe_finish()
    end
  end

  defp apply_message(state, message) do
    if scoped_message?(state, message) do
      state
      |> maybe_apply_turn(Message.extract_turn(message), message)
      |> maybe_apply_item(Message.extract_item(message), message)
      |> maybe_put_text_delta(Message.extract_text_delta(message))
      |> maybe_put_usage(Message.extract_token_usage(message), message)
    else
      state
    end
  end

  defp scoped_message?(state, message) do
    case Message.thread_id(message) do
      thread_id when thread_id == state.thread_id ->
        scoped_turn?(state, message)

      _other ->
        false
    end
  end

  defp scoped_turn?(%{turn_id: nil}, _message), do: false

  defp scoped_turn?(%{turn_id: turn_id}, message) do
    case Message.turn_id(message) do
      nil -> false
      ^turn_id -> true
      _other -> false
    end
  end

  defp maybe_apply_turn(state, nil, _message), do: state

  defp maybe_apply_turn(state, {:ok, %Turn{} = turn}, _message) do
    turn.items
    |> Enum.reduce(state, fn item, acc -> maybe_put_item(acc, item) end)
    |> put_turn(turn)
    |> maybe_put_event_final_turn(turn)
  end

  defp maybe_apply_turn(state, {:error, reason}, message), do: put_protocol_error(state, message, reason)

  defp put_turn(state, %Turn{} = turn) do
    %{
      state
      | initial_turn: state.initial_turn || turn,
        turn_id: state.turn_id || turn.id
    }
  end

  defp maybe_hydrate_final_text_from_turn(%{final_text: ""} = state, %Turn{} = turn) do
    case Enum.find_value(turn.items, &ThreadItem.text/1) do
      text when is_binary(text) -> %{state | final_text: text}
      _other -> state
    end
  end

  defp maybe_hydrate_final_text_from_turn(state, _turn), do: state

  defp maybe_put_event_final_turn(state, %Turn{status: status} = turn)
       when status in ["completed", "failed", "interrupted"] do
    %{state | event_final_turn: state.event_final_turn || turn}
  end

  defp maybe_put_event_final_turn(state, _turn), do: state

  defp maybe_put_item(state, nil), do: state

  defp maybe_put_item(state, item) do
    item_id = ThreadItem.id(item)

    {item_ref, state} =
      case item_id do
        id when is_binary(id) ->
          case Map.fetch(state.item_ref_by_id, id) do
            {:ok, ref} ->
              {ref, state}

            :error ->
              ref = {:id, id}

              {ref,
               %{
                 state
                 | item_order_rev: [ref | state.item_order_rev],
                   item_ref_by_id: Map.put(state.item_ref_by_id, id, ref)
               }}
          end

        _other ->
          ref = {:anon, state.next_item_ref}

          {ref,
           %{
             state
             | item_order_rev: [ref | state.item_order_rev],
               next_item_ref: state.next_item_ref + 1
           }}
      end

    merged_item = merge_item(Map.get(state.items_by_ref, item_ref), item)

    final_text =
      case ThreadItem.text(merged_item) do
        nil -> state.final_text
        text -> text
      end

    %{
      state
      | items_by_ref: Map.put(state.items_by_ref, item_ref, merged_item),
        final_text: final_text
    }
  end

  defp maybe_apply_item(state, nil, _message), do: state
  defp maybe_apply_item(state, {:ok, item}, _message), do: maybe_put_item(state, item)

  defp maybe_apply_item(state, {:error, reason}, message), do: put_protocol_error(state, message, reason)

  defp maybe_put_text_delta(state, nil), do: state

  defp maybe_put_text_delta(state, delta) when is_binary(delta) do
    if ignore_text_delta?(state) do
      state
    else
      %{
        state
        | text_deltas_rev: [delta | state.text_deltas_rev],
          final_text: state.final_text <> delta
      }
    end
  end

  defp maybe_put_usage(state, nil, _message), do: state
  defp maybe_put_usage(state, {:ok, usage}, _message), do: %{state | usage: usage}

  defp maybe_put_usage(state, {:error, reason}, message), do: put_protocol_error(state, message, reason)

  defp maybe_buffer_message(state, message) do
    if Message.thread_id(message) == state.thread_id do
      %{state | pending_messages_rev: [message | state.pending_messages_rev]}
    else
      state
    end
  end

  defp complete?(%{completion: {:error, _reason}}), do: true

  defp complete?(%{completion: :rpc_succeeded} = state), do: match?(%Turn{}, best_final_turn(state))

  defp complete?(_state), do: false

  defp maybe_finish(state) do
    if complete?(state) do
      Enum.each(state.waiters, fn from ->
        GenServer.reply(from, wait_reply(state))
      end)

      state = unsubscribe(state)
      if state.stop_when_done?, do: send(self(), :stop_completed_stream)

      %{state | waiters: []}
    else
      state
    end
  end

  defp unsubscribe(%{subscribed?: true} = state) do
    _ = Client.unsubscribe(state.client, self())
    %{state | subscribed?: false}
  end

  defp unsubscribe(state), do: state

  defp wait_reply(%{completion: {:error, reason}}), do: {:error, reason}
  defp wait_reply(state), do: {:ok, to_public(state)}

  defp bounded_wait_timeout(:infinity), do: @default_wait_timeout_ms
  defp bounded_wait_timeout(timeout) when is_integer(timeout), do: timeout

  defp to_public(state) do
    %__MODULE__{
      final_text: state.final_text,
      final_turn: best_final_turn(state),
      initial_turn: state.initial_turn,
      items: public_items(state),
      pid: self(),
      text_deltas: Enum.reverse(state.text_deltas_rev),
      thread_id: state.thread_id,
      turn_id: state.turn_id,
      usage: state.usage
    }
  end

  defp put_rpc_final_turn(state, %Turn{status: status} = turn) when status in ["completed", "failed", "interrupted"] do
    %{state | rpc_final_turn: turn}
  end

  defp put_rpc_final_turn(state, _turn), do: state

  defp best_final_turn(%{rpc_final_turn: %Turn{} = turn}), do: turn
  defp best_final_turn(%{event_final_turn: %Turn{} = turn}), do: turn
  defp best_final_turn(_state), do: nil

  defp public_items(state) do
    state.item_order_rev
    |> Enum.reverse()
    |> Enum.map(&Map.fetch!(state.items_by_ref, &1))
  end

  defp put_turn_items(state, %Turn{} = turn) do
    Enum.reduce(turn.items, state, fn item, acc -> maybe_put_item(acc, item) end)
  end

  defp replay_pending_messages(%{turn_id: nil} = state), do: state

  defp replay_pending_messages(state) do
    Enum.reduce(
      Enum.reverse(state.pending_messages_rev),
      %{state | pending_messages_rev: []},
      fn message, acc ->
        if Message.turn_id(message) == acc.turn_id do
          apply_message(acc, message)
        else
          acc
        end
      end
    )
  end

  defp merge_item(%ThreadItem.AgentMessage{} = existing, %ThreadItem.AgentMessage{} = incoming) do
    id = incoming.id || existing.id
    phase = incoming.phase || existing.phase
    status = merge_agent_message_status(existing.status, incoming.status)
    text = incoming.text || existing.text

    attrs =
      existing.attrs
      |> Map.merge(incoming.attrs)
      |> Map.merge(
        Map.reject(
          %{
            "id" => id,
            "phase" => phase,
            "status" => status,
            "text" => text,
            "type" => incoming.type
          },
          fn {_key, value} -> is_nil(value) end
        )
      )

    %ThreadItem.AgentMessage{
      attrs: attrs,
      id: id,
      phase: phase,
      status: status,
      text: text,
      type: incoming.type
    }
  end

  defp merge_item(_existing, incoming), do: incoming

  defp merge_agent_message_status(existing, incoming) do
    if agent_message_status_rank(incoming) >= agent_message_status_rank(existing) do
      incoming
    else
      existing
    end
  end

  defp agent_message_status_rank("completed"), do: 3
  defp agent_message_status_rank("failed"), do: 3
  defp agent_message_status_rank("interrupted"), do: 3
  defp agent_message_status_rank("inProgress"), do: 2
  defp agent_message_status_rank(status) when is_binary(status), do: 1
  defp agent_message_status_rank(_status), do: 0

  defp ignore_text_delta?(%{rpc_final_turn: %Turn{status: status}, final_text: final_text})
       when status in ["completed", "failed", "interrupted"] and is_binary(final_text) do
    final_text != ""
  end

  defp ignore_text_delta?(_state), do: false

  defp put_protocol_error(state, message, reason) do
    %{
      state
      | completion: {:error, {:protocol_error, {:invalid_event_payload, Message.method_name(message), reason}}}
    }
  end
end
