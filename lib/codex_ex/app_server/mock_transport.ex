defmodule CodexEx.AppServer.MockTransport do
  @moduledoc """
  In-process mock of the Codex app-server protocol for testing.

  Implements the `Transport` behaviour as a GenServer. Each test starts its own
  isolated instance — no shared state, no Python dependency, async-safe.

  ## Usage modes

  **Explicit (unit tests):**

      {:ok, mock} = MockTransport.start_link()
      MockTransport.configure(mock, server_request: true)
      client = start_supervised!({Client, [transport: MockTransport, mock_pid: mock]})

  **Auto-start (LiveView tests via launcher settings):**

      # Runner settings: %{"launcher" => %{"transport" => "mock"}}
      # MockTransport.open/1 starts its own GenServer when no mock_pid is provided.
  """

  @behaviour CodexEx.AppServer.Transport

  use GenServer

  alias CodexEx.AppServer.Transport

  @mock_fuzzy_file_paths [
    "lib/app/runtime/agents/codex_session_adapter.ex",
    "test/app/runtime/agents/codex_session_adapter_test.exs",
    "_build_codex_test/lib/app/consolidated/Elixir.Ash.Scope.ToOpts.beam"
  ]

  @default_collaboration_mode %{
    "mode" => "default",
    "settings" => %{"model" => "gpt-5.4"}
  }
  @mock_hook_hash "sha256:mock-hook"

  # ---------------------------------------------------------------------------
  # Transport behaviour
  # ---------------------------------------------------------------------------

  @impl Transport
  def open(opts) do
    owner = Keyword.fetch!(opts, :owner)

    mock_pid =
      case Keyword.get(opts, :mock_pid) do
        pid when is_pid(pid) ->
          pid

        nil ->
          {:ok, pid} = GenServer.start_link(__MODULE__, [])
          pid
      end

    case GenServer.call(mock_pid, {:register_owner, owner}) do
      :ok -> {:ok, mock_pid}
      {:error, _reason} = error -> error
    end
  end

  @impl Transport
  def send(mock_pid, payload) when is_pid(mock_pid) and is_binary(payload) do
    GenServer.cast(mock_pid, {:incoming, payload})
    :ok
  end

  @impl Transport
  def close(_mock_pid), do: :ok

  @impl Transport
  def normalize_message({:mock_data, data}, _handle) when is_binary(data), do: {:data, data}
  def normalize_message({:mock_closed, reason}, _handle), do: {:closed, reason}
  def normalize_message(_message, _handle), do: :ignore

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts)

  @doc "Configure mock behavior for the next operation. Turn-specific flags are one-shot."
  def configure(mock, opts) when is_pid(mock) and is_list(opts) do
    GenServer.call(mock, {:configure, Map.new(opts)})
  end

  # ---------------------------------------------------------------------------
  # GenServer
  # ---------------------------------------------------------------------------

  @impl GenServer
  def init(_opts) do
    {:ok,
     %{
       owner: nil,
       threads: %{},
       goals: %{},
       experimental_feature_enablement: %{"goals" => true},
       thread_counter: 0,
       turn_counter: 0,
       pending_turns: %{},
       fuzzy_sessions: %{},
       config: %{},
       client_capabilities: %{},
       pending_server_request: nil
     }}
  end

  @impl GenServer
  def handle_call({:register_owner, owner}, _from, state) do
    case Map.pop(state.config, :open_error) do
      {nil, config} ->
        {:reply, :ok, %{state | owner: owner, config: config}}

      {reason, config} ->
        if notify = Map.get(config, :notify),
          do: Kernel.send(notify, {:mock_transport_open_failed, reason})

        {:reply, {:error, reason}, %{state | config: config}}
    end
  end

  def handle_call({:configure, opts}, _from, state) do
    {:reply, :ok, %{state | config: Map.merge(state.config, opts)}}
  end

  @impl GenServer
  def handle_cast({:incoming, payload}, state) do
    case payload |> String.trim() |> Jason.decode() do
      {:ok, %{"id" => _id, "method" => _method} = message} ->
        {:noreply, handle_request(message, state)}

      {:ok, %{"method" => "initialized"} = _message} ->
        emit(state, notification("session/initialized", %{}))

        if Map.get(state.config, :config_warning) do
          emit(state, notification("configWarning", state.config.config_warning))
        end

        {:noreply, state}

      {:ok, %{"id" => _id} = message} ->
        # This is a response to a server-initiated request (e.g., user input reply)
        if notify = Map.get(state.config, :notify) do
          Kernel.send(notify, {:mock_server_request_reply, message})
        end

        {:noreply, handle_server_request_reply(message, state)}

      {:ok, _other} ->
        {:noreply, state}

      {:error, _reason} ->
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info({:complete_delayed_turn, turn_id, request_id, thread_id, turn, opts}, state) do
    case Map.pop(state.pending_turns, turn_id) do
      {nil, _pending_turns} ->
        {:noreply, state}

      {pending, pending_turns} ->
        final_turn =
          if pending.interrupted do
            Map.put(turn, "status", "interrupted")
          else
            turn
          end

        state = %{state | pending_turns: pending_turns}

        # Update thread with final turn status
        state = update_thread_turn(state, thread_id, turn_id, final_turn)

        finalize_turn(state, request_id, thread_id, turn_id, final_turn, opts)
        {:noreply, state}
    end
  end

  def handle_info(_message, state), do: {:noreply, state}

  # ---------------------------------------------------------------------------
  # Request dispatch
  # ---------------------------------------------------------------------------

  defp handle_request(%{"id" => id, "method" => method, "params" => params}, state) do
    handle_method(method, id, params || %{}, state)
  end

  defp handle_request(%{"id" => id, "method" => method}, state) do
    handle_method(method, id, %{}, state)
  end

  # ---------------------------------------------------------------------------
  # Method handlers
  # ---------------------------------------------------------------------------

  defp handle_method("initialize", id, params, state) do
    capabilities = if is_map(params), do: Map.get(params, "capabilities", %{}), else: %{}
    user_agent = Map.get(state.config, :user_agent, "mock-codex-app-server/1.0")

    emit(
      state,
      result(id, %{
        "platformFamily" => "unix",
        "platformOs" => "linux",
        "userAgent" => user_agent
      })
    )

    %{state | client_capabilities: capabilities || %{}}
  end

  defp handle_method("thread/start", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_thread_start, params})
    end

    if Map.get(state.config, :start_thread_error) || Map.get(params, "mockStartThreadError") do
      emit(state, error(id, -32_020, "thread start rejected", %{"source" => "mock"}))
      consume_turn_config(state)
    else
      {thread_id, state} = next_thread_id(state)

      cwd = Map.get(params, "cwd", "/tmp/mock-codex")
      name = Map.get(state.config, :thread_name) || Map.get(params, "mockThreadName")

      preview =
        Map.get(state.config, :thread_preview) ||
          Map.get(params, "mockThreadPreview", "Mock preview")

      updated_at =
        Map.get(state.config, :thread_updated_at) ||
          Map.get(params, "mockThreadUpdatedAt", 1_711_123_200)

      thread =
        make_thread(thread_id,
          cwd: cwd,
          history_mode: Map.get(params, "historyMode", "legacy"),
          name: name,
          preview: preview,
          updated_at: updated_at
        )

      thread =
        if Map.get(state.config, :read_error) || Map.get(params, "mockReadError") do
          Map.put(thread, "mockReadError", true)
        else
          thread
        end

      state = put_thread(state, thread_id, thread)
      emit(state, notification("thread/started", %{"thread" => thread}))
      emit(state, result(id, make_thread_response(thread, params)))
      consume_turn_config(state)
    end
  end

  defp handle_method("config/read", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_config_read, params})
    end

    emit(
      state,
      result(id, %{
        "config" => %{
          "developer_instructions" => Map.get(state.config, :developer_instructions, "Mock root developer instructions."),
          "model_reasoning_summary" => Map.get(state.config, :model_reasoning_summary),
          "personality" => Map.get(state.config, :personality)
        },
        "origins" => %{}
      })
    )

    state
  end

  defp handle_method("thread/list", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_thread_list, params})
    end

    if Map.get(state.config, :list_threads_error) do
      emit(state, error(id, -32_600, "thread list failed"))
      update_in(state.config, &Map.delete(&1, :list_threads_error))
    else
      archived_filter = Map.get(params, "archived")
      cwd_filter = Map.get(params, "cwd")
      limit = Map.get(params, "limit") || 20

      threads =
        state.threads
        |> Map.values()
        |> maybe_filter_cwd(cwd_filter)
        |> maybe_filter_archived(archived_filter)
        |> Enum.sort_by(&Map.get(&1, "updatedAt", 0), :desc)
        |> Enum.take(limit)

      emit(state, result(id, %{"data" => threads, "nextCursor" => nil}))
      state
    end
  end

  defp handle_method("model/list", id, _params, state) do
    emit(
      state,
      result(id, %{
        "data" => [
          %{
            "defaultReasoningEffort" => "medium",
            "description" => "Flagship reasoning model",
            "displayName" => "gpt-5.4",
            "hidden" => false,
            "id" => "gpt-5.4",
            "isDefault" => true,
            "model" => "gpt-5.4",
            "supportedReasoningEfforts" => [
              %{"description" => "Fastest", "reasoningEffort" => "low"},
              %{"description" => "Balanced", "reasoningEffort" => "medium"},
              %{"description" => "Deep", "reasoningEffort" => "high"}
            ]
          }
        ]
      })
    )

    state
  end

  defp handle_method("skills/list", id, _params, state) do
    emit(state, result(id, skill_list_response()))
    state
  end

  defp handle_method("mcpServer/resource/read", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_mcp_resource_read, params})
    end

    emit(
      state,
      result(id, %{
        "contents" => [
          %{
            "mimeType" => "text/html;profile=mcp-app",
            "text" => "<main>Mock MCP App</main>",
            "uri" => Map.fetch!(params, "uri")
          }
        ]
      })
    )

    state
  end

  defp handle_method("mcpServer/tool/call", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_mcp_tool_call, params})
    end

    emit(
      state,
      result(id, %{
        "content" => [%{"text" => "called", "type" => "text"}],
        "isError" => false,
        "structuredContent" => %{"ok" => true}
      })
    )

    state
  end

  defp handle_method("hooks/list", id, params, state) do
    entries =
      params
      |> hook_list_cwds()
      |> Enum.map(&hook_list_entry(&1, state))

    emit(state, result(id, %{"data" => entries}))
    state
  end

  defp handle_method("config/batchWrite", id, %{"edits" => [%{"keyPath" => "hooks.state", "value" => value}]}, state)
       when is_map(value) do
    state =
      update_in(state, [:config, :hooks_state], fn existing ->
        merge_hooks_state(if(is_map(existing), do: existing, else: %{}), value)
      end)

    emit_config_write_result(state, id)
    state
  end

  defp handle_method("config/batchWrite", id, _params, state) do
    emit_config_write_result(state, id)
    state
  end

  defp handle_method("thread/resume", id, params, state) do
    thread_id = Map.get(params, "threadId")

    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_thread_resume, params})
    end

    case Map.pop(state.config, :thread_resume_transport_error) do
      {reason, config} when not is_nil(reason) ->
        if notify = Map.get(config, :notify),
          do: Kernel.send(notify, {:mock_thread_resume_transport_failed, reason})

        Kernel.send(state.owner, {:mock_closed, reason})
        %{state | config: config}

      {nil, config} ->
        handle_thread_resume(id, params, thread_id, %{state | config: config})
    end
  end

  defp handle_method("thread/read", id, params, state) do
    thread_id = Map.get(params, "threadId")
    include_turns = Map.get(params, "includeTurns", false)

    cond do
      MapSet.member?(unloaded_ids(state), thread_id) ->
        emit(state, error(id, -32_600, "thread not loaded: #{thread_id}"))
        state

      Map.get(state.config, :thread_not_found_on_read) || Map.get(params, "mockThreadNotFound") ->
        emit(state, error(id, -32_600, "thread not found: #{thread_id}"))
        consume_turn_config(state)

      true ->
        thread = Map.get(state.threads, thread_id, make_thread(thread_id))
        handle_thread_read(state, id, thread_id, thread, include_turns)
    end
  end

  defp handle_method("thread/turns/list", id, params, state) do
    thread_id = Map.fetch!(params, "threadId")
    thread = Map.get(state.threads, thread_id, make_thread(thread_id))
    turns = Map.get(thread, "turns", [])

    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_thread_turns_list, params})
    end

    if turns == [] and Map.get(thread, "historyMode") == "paginated" do
      emit(
        state,
        error(
          id,
          -32_600,
          "thread #{thread_id} is not materialized yet; thread/turns/list is unavailable before first user message"
        )
      )
    else
      turns =
        if Map.get(params, "sortDirection", "desc") == "desc",
          do: Enum.reverse(turns),
          else: turns

      {page, next_cursor} = mock_thread_turns_page(state, params, turns)

      emit(
        state,
        result(id, %{
          "backwardsCursor" => nil,
          "data" => page,
          "nextCursor" => next_cursor
        })
      )
    end

    state
  end

  defp handle_method("thread/fork", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_thread_fork, params})
    end

    source_thread_id = Map.get(params, "threadId")
    source_thread = Map.get(state.threads, source_thread_id, make_thread(source_thread_id))
    {thread_id, state} = next_thread_id(state)

    thread =
      make_thread(thread_id,
        cwd: Map.get(params, "cwd", Map.get(source_thread, "cwd", "/tmp/mock-codex")),
        ephemeral: Map.get(params, "ephemeral", false),
        history_mode: Map.get(source_thread, "historyMode", "legacy"),
        turns: forked_turns(Map.get(source_thread, "turns", []), params)
      )

    state = put_thread(state, thread_id, thread)

    response_thread =
      if Map.get(params, "excludeTurns"), do: Map.put(thread, "turns", []), else: thread

    emit(state, result(id, make_thread_response(response_thread, params)))
    state
  end

  defp handle_method("thread/inject_items", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_thread_inject_items, params})
    end

    emit(state, result(id, %{}))
    state
  end

  defp handle_method("thread/unsubscribe", id, params, %{config: %{unsubscribe_error_once: true}} = state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_thread_unsubscribe, params})
    end

    emit(state, error(id, -32_603, "mock thread unsubscribe failed"))
    %{state | config: Map.delete(state.config, :unsubscribe_error_once)}
  end

  defp handle_method("thread/unsubscribe", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_thread_unsubscribe, params})
    end

    emit(state, result(id, %{"status" => "unsubscribed"}))
    state
  end

  defp handle_method("thread/revert", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_thread_revert, params})
    end

    thread_id = Map.fetch!(params, "threadId")
    thread = Map.get(state.threads, thread_id, make_thread(thread_id))
    reverted_thread = Map.put(thread, "turns", forked_turns(Map.get(thread, "turns", []), params))
    state = put_thread(state, thread_id, reverted_thread)

    emit(
      state,
      result(id, %{
        "itemsBackwardsCursor" => nil,
        "thread" => Map.put(reverted_thread, "turns", []),
        "turnsBackwardsCursor" => nil
      })
    )

    state
  end

  defp handle_method("thread/archive", id, params, state) do
    thread_id = Map.get(params, "threadId")
    thread = Map.get(state.threads, thread_id, make_thread(thread_id))

    archived_thread =
      make_thread(thread_id,
        turns: Map.get(thread, "turns", []),
        archived: true,
        cwd: Map.get(thread, "cwd", "/tmp/mock-codex"),
        history_mode: Map.get(thread, "historyMode", "legacy"),
        name: Map.get(thread, "name"),
        preview: Map.get(thread, "preview", "Mock preview"),
        updated_at: Map.get(thread, "updatedAt", 1_711_123_200)
      )

    state = put_thread(state, thread_id, archived_thread)
    emit(state, notification("thread/archived", %{"thread" => archived_thread}))
    emit(state, result(id, %{}))
    state
  end

  defp handle_method("thread/name/set", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_thread_name_set, params})
    end

    emit(state, result(id, %{}))
    state
  end

  defp handle_method("thread/unarchive", id, params, state) do
    thread_id = Map.get(params, "threadId")
    thread = Map.get(state.threads, thread_id, make_thread(thread_id))

    if Map.get(thread, "status") == "archived" do
      unarchived_thread =
        make_thread(thread_id,
          turns: Map.get(thread, "turns", []),
          archived: false,
          cwd: Map.get(thread, "cwd", "/tmp/mock-codex"),
          history_mode: Map.get(thread, "historyMode", "legacy"),
          name: Map.get(thread, "name"),
          preview: Map.get(thread, "preview", "Mock preview"),
          updated_at: Map.get(thread, "updatedAt", 1_711_123_200)
        )

      state = put_thread(state, thread_id, unarchived_thread)
      emit(state, notification("thread/unarchived", %{"thread" => unarchived_thread}))
      emit(state, result(id, %{"thread" => unarchived_thread}))
      state
    else
      emit(state, error(id, -32_600, "thread is not archived: #{thread_id}"))
      state
    end
  end

  defp handle_method("thread/realtime/start", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_realtime_start, params})
    end

    emit(state, result(id, %{}))

    emit(
      state,
      notification("thread/realtime/sdp", %{
        "threadId" => Map.fetch!(params, "threadId"),
        "sdp" => "v=0\r\nmock-answer"
      })
    )

    state
  end

  defp handle_method("thread/realtime/stop", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_realtime_stop, params})
    end

    emit(state, result(id, %{}))
    state
  end

  defp handle_method("thread/compact/start", id, params, state) do
    thread_id = Map.get(params, "threadId")
    {compacted_turn_id, state} = next_turn_id(state)

    compacted_turn =
      make_turn(compacted_turn_id, [], [
        agent_message_item(compacted_turn_id, "Compacted transcript")
      ])

    thread = Map.get(state.threads, thread_id, make_thread(thread_id))
    thread = Map.put(thread, "turns", [compacted_turn])
    state = put_thread(state, thread_id, thread)
    emit(state, result(id, %{}))

    emit(
      state,
      notification("thread/compacted", %{
        "threadId" => thread_id,
        "turnId" => compacted_turn_id
      })
    )

    state
  end

  defp handle_method("thread/rollback", id, params, state) do
    thread_id = Map.get(params, "threadId")
    num_turns = Map.get(params, "numTurns", 1)
    thread = Map.get(state.threads, thread_id, make_thread(thread_id))
    turns = Map.get(thread, "turns", [])

    cond do
      Map.get(thread, "historyMode") == "paginated" ->
        emit(state, error(id, -32_600, "paginated threads do not support thread/rollback"))
        state

      not is_integer(num_turns) or num_turns < 1 ->
        emit(state, error(id, -32_600, "invalid rollback count: #{inspect(num_turns)}"))
        state

      length(turns) < num_turns ->
        emit(state, error(id, -32_600, "cannot rollback #{num_turns} turns from #{thread_id}"))
        state

      true ->
        kept_turns = Enum.drop(turns, -num_turns)
        rolled_back_thread = Map.put(thread, "turns", kept_turns)
        state = put_thread(state, thread_id, rolled_back_thread)

        payload =
          if Map.get(state.config, :malformed_rollback_result),
            do: %{},
            else: %{"thread" => rolled_back_thread}

        emit(state, result(id, payload))
        state
    end
  end

  defp handle_method("thread/goal/set", id, params, state) do
    if goals_feature_enabled?(state) do
      thread_id = Map.get(params, "threadId")

      existing_goal = Map.get(state.goals, thread_id, make_goal(thread_id))

      goal =
        Map.merge(existing_goal, %{
          "objective" => Map.get(params, "objective", Map.get(existing_goal, "objective")),
          "status" => Map.get(params, "status", Map.get(existing_goal, "status")),
          "tokenBudget" => Map.get(params, "tokenBudget", Map.get(existing_goal, "tokenBudget"))
        })

      state = put_in(state, [:goals, thread_id], goal)

      emit(
        state,
        notification("thread/goal/updated", %{
          "threadId" => thread_id,
          "goal" => goal
        })
      )

      emit(state, result(id, %{"goal" => goal}))
      state
    else
      emit(state, error(id, -32_600, "goals feature is disabled"))
      state
    end
  end

  defp handle_method("experimentalFeature/enablement/set", id, params, state) do
    enablement = Map.get(params, "enablement", %{})

    state = %{
      state
      | experimental_feature_enablement: Map.merge(state.experimental_feature_enablement, enablement)
    }

    emit(state, result(id, %{"enablement" => state.experimental_feature_enablement}))
    state
  end

  defp handle_method("experimentalFeature/list", id, _params, state) do
    emit(
      state,
      result(id, %{
        "data" => [
          %{
            "defaultEnabled" => false,
            "enabled" => Map.get(state.experimental_feature_enablement, "goals", false),
            "name" => "goals",
            "stage" => "beta"
          }
        ]
      })
    )

    state
  end

  defp handle_method("thread/goal/get", id, params, state) do
    if goals_feature_enabled?(state) do
      thread_id = Map.get(params, "threadId")
      emit(state, result(id, %{"goal" => Map.get(state.goals, thread_id)}))
    else
      emit(state, error(id, -32_600, "goals feature is disabled"))
    end

    state
  end

  defp handle_method("thread/goal/clear", id, params, state) do
    if goals_feature_enabled?(state) do
      thread_id = Map.get(params, "threadId")
      state = update_in(state, [:goals], &Map.delete(&1, thread_id))
      emit(state, notification("thread/goal/cleared", %{"threadId" => thread_id}))
      emit(state, result(id, %{}))
      state
    else
      emit(state, error(id, -32_600, "goals feature is disabled"))
      state
    end
  end

  defp handle_method("review/start", id, params, state) do
    thread_id = Map.get(params, "threadId")
    target = Map.get(params, "target", %{})
    {turn_id, state} = next_turn_id(state)

    review_text =
      if Map.get(target, "type") == "uncommittedChanges",
        do: "Review of current changes",
        else: "Review completed"

    items = [agent_message_item(turn_id, review_text)]
    turn = make_turn(turn_id, [], items)

    thread = Map.get(state.threads, thread_id, make_thread(thread_id))
    thread = Map.put(thread, "turns", Map.get(thread, "turns", []) ++ [turn])
    state = put_thread(state, thread_id, thread)

    emit(state, notification("turn/started", %{"threadId" => thread_id, "turn" => turn}))

    for item <- items do
      emit_item_notifications(state, thread_id, turn_id, item)
    end

    completed_turn = Map.put(turn, "status", "completed")

    emit(
      state,
      notification("turn/completed", %{"threadId" => thread_id, "turn" => completed_turn})
    )

    emit(
      state,
      result(id, %{"reviewThreadId" => thread_id, "turn" => completed_turn})
    )

    state
  end

  defp handle_method("turn/start", id, params, state) do
    thread_id = Map.get(params, "threadId")
    input_items = Map.get(params, "input", [])
    output_schema = Map.get(params, "outputSchema")
    collaboration_mode = Map.get(params, "collaborationMode")
    turn_start = turn_start_options(state, params)

    case validate_turn_start(state, id, collaboration_mode, turn_start.immediate_error) do
      {:error, state} ->
        state

      :ok ->
        thread = turn_start_thread(state, thread_id, collaboration_mode)
        collab_settings = Map.get(thread, "collaborationMode", @default_collaboration_mode)
        collab_mode = Map.get(collab_settings, "mode", "default")
        reasoning_effort = current_reasoning_effort(params, collab_settings)

        assistant_text =
          assistant_text_for_turn(input_items, output_schema, collab_mode, reasoning_effort)

        {turn_id, state} = next_turn_id(state)
        agent_items = turn_items(turn_id, assistant_text, turn_start)

        # The user message rides on the turn object (echoed input) rather than as a
        # standalone item event — matching codex and letting the preview userMessage
        # be deduped at the turn level instead of duplicated via item upsert.
        items =
          maybe_prepend_user_message_item(
            agent_items,
            turn_id,
            input_items,
            turn_start.client_message_id
          )

        turn = make_turn(turn_id, input_items, items)
        thread = Map.put(thread, "turns", Map.get(thread, "turns", []) ++ [turn])
        state = put_thread(state, thread_id, thread)

        turn_start =
          Map.put(turn_start, :sparse_notifications, Map.get(thread, "ephemeral", false))

        _ = emit_turn_started(state, thread_id, turn_id, turn, turn_start)

        event_items = if turn_start.sparse_notifications, do: items, else: agent_items
        _ = emit_turn_item_notifications(state, thread_id, turn_id, event_items)

        turn_opts = turn_result_options(turn_start)
        emit_turn_start_result(state, id, turn, turn_opts)
        state = consume_turn_config(state)
        handle_turn_start_completion(state, id, thread_id, turn_id, turn, turn_opts, turn_start)
    end
  end

  defp handle_method("turn/interrupt", id, params, %{config: %{interrupt_error_once: true}} = state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_turn_interrupt, params})
    end

    emit(state, error(id, -32_603, "mock turn interrupt failed"))
    %{state | config: Map.delete(state.config, :interrupt_error_once)}
  end

  defp handle_method(
         "turn/interrupt",
         id,
         %{"turnId" => turn_id} = params,
         %{config: %{interrupt_mismatch_once: true}} = state
       ) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_turn_interrupt, params})
    end

    emit(
      state,
      error(id, -32_602, "expected active turn id stale-turn but found #{turn_id}")
    )

    %{state | config: Map.delete(state.config, :interrupt_mismatch_once)}
  end

  defp handle_method("turn/interrupt", id, params, state) do
    if notify = Map.get(state.config, :notify) do
      Kernel.send(notify, {:mock_turn_interrupt, params})
    end

    turn_id = Map.get(params, "turnId")
    thread_id = Map.get(params, "threadId")

    pending = Map.get(state.pending_turns, turn_id)

    state =
      if pending && pending.thread_id == thread_id do
        # Mark as interrupted and complete immediately (don't wait for the timer)
        interrupted_turn = Map.put(pending.turn, "status", "interrupted")
        state = update_thread_turn(state, thread_id, turn_id, interrupted_turn)

        finalize_turn(
          state,
          pending.request_id,
          thread_id,
          turn_id,
          interrupted_turn,
          pending.opts
        )

        %{state | pending_turns: Map.delete(state.pending_turns, turn_id)}
      else
        state
      end

    emit(state, result(id, %{}))
    state
  end

  defp handle_method("turn/steer", id, params, state) do
    thread_id = Map.get(params, "threadId")
    expected_turn_id = Map.get(params, "expectedTurnId")
    thread = Map.get(state.threads, thread_id, make_thread(thread_id))

    matching =
      thread
      |> Map.get("turns", [])
      |> Enum.reverse()
      |> Enum.find(&(Map.get(&1, "id") == expected_turn_id))

    if matching do
      emit(state, result(id, %{"turnId" => expected_turn_id}))
    else
      emit(
        state,
        error(id, -32_600, "turn not found: #{expected_turn_id}", %{"threadId" => thread_id})
      )
    end

    state
  end

  defp handle_method("fuzzyFileSearch/sessionStart", id, params, state) do
    session_id = Map.get(params, "sessionId")
    roots = Map.get(params, "roots", [])

    state = %{
      state
      | fuzzy_sessions: Map.put(state.fuzzy_sessions, session_id, %{roots: roots, query: ""})
    }

    emit(state, result(id, %{}))
    state
  end

  defp handle_method("fuzzyFileSearch/sessionUpdate", id, params, state) do
    session_id = Map.get(params, "sessionId")
    query = Map.get(params, "query", "")
    session = Map.get(state.fuzzy_sessions, session_id)

    if is_nil(session) do
      emit(state, error(id, -32_600, "unknown fuzzy file search session: #{session_id}"))
      state
    else
      state = %{
        state
        | fuzzy_sessions: Map.put(state.fuzzy_sessions, session_id, %{session | query: query})
      }

      ranked_paths = fuzzy_file_search_results(query)

      files =
        ranked_paths
        |> Enum.with_index()
        |> Enum.map(fn {path, index} ->
          root = List.first(session.roots) || "/tmp/mock-codex"

          %{
            "root" => root,
            "path" => path,
            "file_name" => Path.basename(path),
            "score" => length(ranked_paths) - index,
            "indices" => nil
          }
        end)

      emit(state, result(id, %{}))

      emit(
        state,
        notification("fuzzyFileSearch/sessionUpdated", %{
          "sessionId" => session_id,
          "query" => query,
          "files" => files
        })
      )

      emit(
        state,
        notification("fuzzyFileSearch/sessionCompleted", %{"sessionId" => session_id})
      )

      state
    end
  end

  defp handle_method("fuzzyFileSearch/sessionStop", id, params, state) do
    session_id = Map.get(params, "sessionId")
    state = %{state | fuzzy_sessions: Map.delete(state.fuzzy_sessions, session_id)}
    emit(state, result(id, %{}))
    state
  end

  # Test-specific methods (mirror Python mock's test helpers)

  defp handle_method("fail", id, _params, state) do
    emit(state, error(id, -32_000, "boom", %{"source" => "mock"}))
    state
  end

  defp handle_method("emit_notification", id, _params, state) do
    emit(state, notification("thread/updated", %{"thread_id" => "thread-1"}))
    emit(state, result(id, %{"emitted" => true}))
    state
  end

  defp handle_method("slow", id, _params, state) do
    owner = state.owner
    delay_ms = Map.get(state.config, :slow_delay_ms, 1_500)

    emit(state, notification("slow/started", %{}))

    spawn(fn ->
      Process.sleep(delay_ms)
      json = Jason.encode!(result(id, %{"slow" => true}))
      if is_pid(owner), do: Kernel.send(owner, {:mock_data, json <> "\n"})
    end)

    state
  end

  defp handle_method("emit_invalid_json", _id, _params, state) do
    if is_pid(state.owner), do: Kernel.send(state.owner, {:mock_data, "{not-json}\n"})
    state
  end

  # Catch-all: echo params
  defp handle_method(_method, id, params, state) do
    emit(state, result(id, %{"echo" => params}))
    state
  end

  defp forked_turns(turns, %{"beforeTurnId" => turn_id}) when is_list(turns) and is_binary(turn_id) do
    Enum.take_while(turns, &(Map.get(&1, "id") != turn_id))
  end

  defp forked_turns(turns, %{"lastTurnId" => turn_id}) when is_list(turns) and is_binary(turn_id) do
    Enum.reduce_while(turns, [], fn turn, kept ->
      kept = [turn | kept]

      if Map.get(turn, "id") == turn_id,
        do: {:halt, Enum.reverse(kept)},
        else: {:cont, kept}
    end)
  end

  defp forked_turns(turns, _params) when is_list(turns), do: turns

  # Unknown resumed threads get seeded remote history ("Resumed OK") so
  # import/family tests can render it — except threads owned by
  # FakeSessionTransport sessions ("thread-fake-*"): their turns never went
  # over the wire, and fabricating history here would corrupt persisted
  # transcripts during lifecycle syncs (e.g. session refresh).
  defp resume_seed_turns("thread-fake-" <> _rest, _turn_id), do: []

  defp resume_seed_turns(_thread_id, turn_id), do: [make_turn(turn_id, [], [agent_message_item(turn_id, "Resumed OK")])]

  defp hook_list_cwds(%{"cwds" => cwds}) when is_list(cwds) and cwds != [], do: cwds
  defp hook_list_cwds(_params), do: ["/tmp/mock-codex"]

  defp hook_list_entry(cwd, state) when is_binary(cwd) do
    hooks =
      cond do
        String.contains?(cwd, "no-hooks") ->
          []

        String.contains?(cwd, "/tmp/runner-") ->
          [
            mock_hook("/home/mock/.codex/hooks.json", state),
            mock_hook(cwd <> "/.codex/hooks.json", state)
          ]

        true ->
          [mock_hook(cwd <> "/.codex/hooks.json", state)]
      end

    %{
      "cwd" => cwd,
      "errors" => [],
      "hooks" => hooks,
      "warnings" => []
    }
  end

  defp mock_hook(source_path, state) when is_binary(source_path) do
    key = mock_hook_key(source_path)

    %{
      "command" => "echo mock hook",
      "currentHash" => @mock_hook_hash,
      "displayOrder" => 0,
      "enabled" => hook_enabled?(state, key),
      "eventName" => "preToolUse",
      "handlerType" => "command",
      "isManaged" => false,
      "key" => key,
      "matcher" => "shell",
      "pluginId" => nil,
      "source" => "user",
      "sourcePath" => source_path,
      "statusMessage" => "Mock hook",
      "timeoutSec" => 30,
      "trustStatus" => hook_trust_status(state, key)
    }
  end

  defp mock_hook_key(source_path), do: "#{source_path}:preToolUse:0:0"

  defp merge_hooks_state(existing, value) when is_map(existing) and is_map(value) do
    Map.merge(existing, value, fn _hook_key, old_value, new_value ->
      if is_map(old_value) and is_map(new_value) do
        Map.merge(old_value, new_value)
      else
        new_value
      end
    end)
  end

  defp hook_enabled?(state, key) when is_binary(key) do
    hooks_state = Map.get(state.config, :hooks_state, %{})

    case get_in(hooks_state, [key, "enabled"]) do
      enabled? when is_boolean(enabled?) -> enabled?
      _other -> true
    end
  end

  defp hook_trust_status(state, key) when is_binary(key) do
    hooks_state = Map.get(state.config, :hooks_state, %{})

    case get_in(hooks_state, [key, "trusted_hash"]) do
      @mock_hook_hash -> "trusted"
      _other -> "untrusted"
    end
  end

  defp emit_config_write_result(state, id) do
    emit(
      state,
      result(id, %{
        "filePath" => "/tmp/mock-codex-home/config.toml",
        "status" => "ok",
        "version" => "mock-config-version"
      })
    )
  end

  # ---------------------------------------------------------------------------
  # Server request reply handling
  # ---------------------------------------------------------------------------

  defp handle_server_request_reply(
         %{"result" => %{"decision" => decision}},
         %{pending_server_request: %{kind: :command_execution_approval} = pending} = state
       )
       when decision in ["accept", "acceptForSession", "decline", "cancel"] do
    %{request_id: id, thread_id: thread_id, turn_id: turn_id, turn: turn, opts: turn_opts} =
      pending

    finalize_turn(state, id, thread_id, turn_id, turn, turn_opts)
    %{state | pending_server_request: nil}
  end

  defp handle_server_request_reply(
         _reply_message,
         %{pending_server_request: %{kind: :command_execution_approval}} = state
       ) do
    # Keep waiting; malformed approval payload should not unblock the pending turn.
    state
  end

  defp handle_server_request_reply(_reply_message, %{pending_server_request: pending} = state) when is_map(pending) do
    %{request_id: id, thread_id: thread_id, turn_id: turn_id, turn: turn, opts: turn_opts} =
      pending

    finalize_turn(state, id, thread_id, turn_id, turn, turn_opts)
    %{state | pending_server_request: nil}
  end

  defp handle_server_request_reply(_reply, state), do: state

  defp handle_thread_resume(id, params, thread_id, state) do
    case thread_resume_error(state, params, thread_id) do
      {:error, message, state} ->
        emit(state, error(id, -32_600, message))
        consume_turn_config(state)

      nil ->
        {turn_id, state} = next_turn_id(state)

        default_thread =
          make_thread(thread_id,
            history_mode: "paginated",
            turns: resume_seed_turns(thread_id, turn_id)
          )

        thread = Map.get(state.threads, thread_id, default_thread)
        state = put_thread(state, thread_id, thread)

        response_thread =
          if Map.get(params, "excludeTurns"), do: Map.put(thread, "turns", []), else: thread

        response =
          response_thread
          |> make_thread_response(params)
          |> maybe_put_initial_turns_page(thread, params)

        response =
          if Map.get(state.config, :omit_initial_turns_page),
            do: Map.delete(response, "initialTurnsPage"),
            else: response

        maybe_emit_resume_completion(state, thread_id, thread)

        emit(state, result(id, response))
        state
    end
  end

  defp thread_resume_error(state, params, thread_id) do
    cond do
      Map.get(state.config, :no_rollout) || Map.get(params, "mockNoRollout") ->
        {:error, "no rollout found for thread id #{thread_id}", state}

      Map.get(state.config, :thread_not_found) || Map.get(params, "mockThreadNotFound") ->
        {:error, "thread not found: #{thread_id}", state}

      Map.get(state.config, :thread_not_loaded) || Map.get(params, "mockThreadNotLoaded") ->
        {:error, "thread not loaded: #{thread_id}", maybe_mark_thread_unloaded(state, params, thread_id)}

      true ->
        nil
    end
  end

  defp maybe_mark_thread_unloaded(state, params, thread_id) do
    if Map.get(state.config, :thread_not_loaded_on_read) ||
         Map.get(params, "mockThreadNotLoadedOnRead") do
      %{
        state
        | config:
            Map.put(
              state.config,
              :unloaded_thread_ids,
              MapSet.put(unloaded_ids(state), thread_id)
            )
      }
    else
      state
    end
  end

  # ---------------------------------------------------------------------------
  # Turn finalization
  # ---------------------------------------------------------------------------

  defp turn_start_options(state, params) do
    %{
      server_request: config_or_param?(state, params, :server_request, "mockServerRequest"),
      elicitation_request: config_or_param?(state, params, :elicitation_request, "mockElicitationRequest"),
      tool_approval_elicitation_request:
        config_or_param?(
          state,
          params,
          :tool_approval_elicitation_request,
          "mockToolApprovalElicitationRequest"
        ),
      command_execution_approval_request:
        config_or_param?(
          state,
          params,
          :command_execution_approval_request,
          "mockCommandExecutionApprovalRequest"
        ),
      plan_item_requested: config_or_param?(state, params, :plan_item, "mockPlanItem"),
      malformed_result: config_or_param?(state, params, :malformed_result, "mockMalformedTurnResult"),
      omit_turn_thread_id: config_or_param?(state, params, :omit_turn_thread_id, "mockOmitTurnThreadId"),
      immediate_error: config_or_param?(state, params, :immediate_error, "mockImmediateTurnError"),
      partial_turn_notifications:
        config_or_param?(
          state,
          params,
          :partial_turn_notifications,
          "mockPartialTurnNotifications"
        ),
      delay_ms: Map.get(state.config, :delay_ms) || Map.get(params, "mockDelayMs", 0),
      active_summary: Map.get(params, "summary"),
      client_message_id: Map.get(params, "clientUserMessageId")
    }
  end

  defp validate_turn_start(state, id, collaboration_mode, immediate_error) do
    cond do
      collaboration_mode && !Map.get(state.client_capabilities, "experimentalApi") ->
        emit(
          state,
          error(id, -32_600, "turn/start.collaborationMode requires experimentalApi capability")
        )

        {:error, consume_turn_config(state)}

      immediate_error ->
        emit(state, error(id, -32_010, "turn start rejected", %{"source" => "mock"}))
        {:error, consume_turn_config(state)}

      true ->
        :ok
    end
  end

  defp turn_start_thread(state, thread_id, nil) do
    Map.get(state.threads, thread_id, make_thread(thread_id))
  end

  defp turn_start_thread(state, thread_id, collaboration_mode) do
    state
    |> Map.get(:threads)
    |> Map.get(thread_id, make_thread(thread_id))
    |> Map.put("collaborationMode", collaboration_mode)
  end

  defp turn_items(turn_id, _assistant_text, %{plan_item_requested: true}) do
    [plan_item(turn_id)]
  end

  defp turn_items(turn_id, assistant_text, %{active_summary: active_summary}) do
    reasoning_items =
      if active_summary in ["auto", "detailed"], do: [reasoning_item(turn_id)], else: []

    reasoning_items ++ [agent_message_item(turn_id, assistant_text)]
  end

  # Real codex echoes the submitted input back as a userMessage item at the start
  # of the turn; mirror that so the user prompt is persisted as a turn item rather
  # than relying on input-based synthesis.
  defp maybe_prepend_user_message_item(items, _turn_id, [], _client_id), do: items

  defp maybe_prepend_user_message_item(items, turn_id, input_items, client_id) when is_list(input_items),
    do: [user_message_item(turn_id, input_items, client_id) | items]

  defp user_message_item(turn_id, input_items, client_id) do
    item = %{
      "id" => "item-user-#{turn_id}",
      "type" => "userMessage",
      "status" => "completed",
      "content" => input_items
    }

    if is_binary(client_id), do: Map.put(item, "clientId", client_id), else: item
  end

  defp emit_turn_started(state, thread_id, turn_id, _turn, opts)
       when opts.partial_turn_notifications or opts.sparse_notifications do
    emit(
      state,
      notification("turn/started", %{
        "threadId" => thread_id,
        "turn" => %{"id" => turn_id, "status" => "inProgress", "items" => []}
      })
    )
  end

  defp emit_turn_started(state, thread_id, _turn_id, turn, _opts) do
    user_items = Enum.filter(Map.get(turn, "items", []), &(Map.get(&1, "type") == "userMessage"))

    emit(
      state,
      notification("turn/started", %{
        "threadId" => thread_id,
        "turn" => %{turn | "items" => user_items, "status" => "inProgress"}
      })
    )
  end

  defp emit_turn_item_notifications(state, thread_id, turn_id, items) do
    for item <- items do
      emit_item_notifications(state, thread_id, turn_id, item)
    end
  end

  defp turn_result_options(turn_start) do
    %{
      malformed_result: turn_start.malformed_result,
      omit_turn_thread_id: turn_start.omit_turn_thread_id,
      partial_turn_notifications: turn_start.partial_turn_notifications,
      sparse_notifications: turn_start.sparse_notifications
    }
  end

  defp handle_turn_start_completion(state, request_id, thread_id, turn_id, turn, turn_opts, %{
         command_execution_approval_request: true
       }) do
    emit_command_execution_approval_request(state, thread_id, turn_id)

    put_pending_server_request(state, request_id, thread_id, turn_id, turn, turn_opts, kind: :command_execution_approval)
  end

  defp handle_turn_start_completion(state, request_id, thread_id, turn_id, turn, turn_opts, %{
         tool_approval_elicitation_request: true
       }) do
    emit_tool_approval_elicitation_request(state, thread_id, turn_id)

    put_pending_server_request(state, request_id, thread_id, turn_id, turn, turn_opts, kind: :elicitation)
  end

  defp handle_turn_start_completion(state, request_id, thread_id, turn_id, turn, turn_opts, %{server_request: true}) do
    emit_server_request(state, thread_id, turn_id)
    put_pending_server_request(state, request_id, thread_id, turn_id, turn, turn_opts)
  end

  defp handle_turn_start_completion(state, request_id, thread_id, turn_id, turn, turn_opts, %{elicitation_request: true}) do
    emit_elicitation_request(state, thread_id, turn_id)

    put_pending_server_request(state, request_id, thread_id, turn_id, turn, turn_opts, kind: :elicitation)
  end

  defp handle_turn_start_completion(state, request_id, thread_id, turn_id, turn, turn_opts, %{delay_ms: delay_ms})
       when delay_ms > 0 do
    state = put_pending_turn(state, request_id, thread_id, turn_id, turn, turn_opts)

    Process.send_after(
      self(),
      {:complete_delayed_turn, turn_id, request_id, thread_id, turn, turn_opts},
      delay_ms
    )

    state
  end

  defp handle_turn_start_completion(state, request_id, thread_id, turn_id, turn, turn_opts, _opts) do
    finalize_turn(state, request_id, thread_id, turn_id, turn, turn_opts)
    state
  end

  defp put_pending_server_request(state, request_id, thread_id, turn_id, turn, turn_opts, extra \\ []) do
    pending_server_request =
      Enum.into(extra, %{
        request_id: request_id,
        thread_id: thread_id,
        turn_id: turn_id,
        turn: turn,
        opts: turn_opts
      })

    %{state | pending_server_request: pending_server_request}
  end

  defp put_pending_turn(state, request_id, thread_id, turn_id, turn, turn_opts) do
    pending_turn = %{
      thread_id: thread_id,
      interrupted: false,
      turn: turn,
      request_id: request_id,
      opts: turn_opts
    }

    %{state | pending_turns: Map.put(state.pending_turns, turn_id, pending_turn)}
  end

  defp finalize_turn(state, request_id, thread_id, turn_id, turn, opts) do
    completed_turn = terminal_notification_turn(turn, turn_id, opts)

    emit(
      state,
      notification("turn/completed", %{"threadId" => thread_id, "turn" => completed_turn})
    )

    if opts.partial_turn_notifications and not opts.malformed_result do
      emit(state, result(request_id, %{"turn" => turn_start_result_turn(turn, opts)}))
    end
  end

  defp emit_turn_start_result(state, request_id, _turn, %{malformed_result: true}) do
    emit(state, result(request_id, %{"unexpected" => true}))
  end

  defp emit_turn_start_result(_state, _request_id, _turn, %{partial_turn_notifications: true}), do: :ok

  defp emit_turn_start_result(state, request_id, turn, opts) do
    initial_turn =
      turn
      |> Map.put("items", [])
      |> Map.put("status", "inProgress")
      |> Map.delete("input")

    result_turn =
      if opts.omit_turn_thread_id do
        Map.delete(initial_turn, "threadId")
      else
        initial_turn
      end

    emit(state, result(request_id, %{"turn" => result_turn}))
  end

  defp turn_start_result_turn(turn, %{omit_turn_thread_id: true}), do: Map.delete(turn, "threadId")

  defp turn_start_result_turn(turn, _opts), do: turn

  defp terminal_notification_turn(turn, turn_id, %{partial_turn_notifications: true}) do
    %{"id" => turn_id, "status" => Map.get(turn, "status", "completed"), "items" => []}
  end

  defp terminal_notification_turn(turn, turn_id, %{sparse_notifications: true}) do
    items =
      turn
      |> Map.get("items", [])
      |> Enum.filter(&(Map.get(&1, "type") == "agentMessage"))
      |> Enum.take(-1)

    %{"id" => turn_id, "status" => Map.get(turn, "status", "completed"), "items" => items}
  end

  defp terminal_notification_turn(turn, _turn_id, _opts), do: turn

  # ---------------------------------------------------------------------------
  # Server request emission
  # ---------------------------------------------------------------------------

  defp emit_server_request(state, thread_id, turn_id) do
    emit(state, %{
      "jsonrpc" => "2.0",
      "id" => "server-request-1",
      "method" => "item/tool/requestUserInput",
      "params" => %{
        "itemId" => "item-1",
        "questions" => [
          %{"header" => "Approve", "id" => "approve", "question" => "Continue?"}
        ],
        "threadId" => thread_id,
        "turnId" => turn_id
      }
    })
  end

  defp emit_elicitation_request(state, thread_id, turn_id) do
    emit(state, %{
      "jsonrpc" => "2.0",
      "id" => "elicitation-request-1",
      "method" => "mcpServer/elicitation/request",
      "params" => %{
        "serverName" => "test-mcp-server",
        "threadId" => thread_id,
        "turnId" => turn_id,
        "message" => "Configure settings",
        "mode" => "form",
        "requestedSchema" => %{
          "type" => "object",
          "properties" => %{
            "color" => %{
              "type" => "string",
              "title" => "Color",
              "description" => "Pick a color",
              "enum" => ["red", "green", "blue"]
            },
            "name" => %{
              "type" => "string",
              "title" => "Name",
              "description" => "Enter your name"
            }
          },
          "required" => ["color"]
        }
      }
    })
  end

  defp emit_tool_approval_elicitation_request(state, thread_id, turn_id) do
    emit(state, %{
      "jsonrpc" => "2.0",
      "id" => "tool-approval-request-1",
      "method" => "mcpServer/elicitation/request",
      "params" => %{
        "serverName" => "shopify",
        "threadId" => thread_id,
        "turnId" => turn_id,
        "message" => "Allow shopify / learn_shopify_api to continue?",
        "mode" => "form",
        "_meta" => %{
          "codex_approval_kind" => "mcp_tool_call",
          "persist" => ["session", "always"],
          "tool_params_display" => [
            %{"name" => "api", "display_name" => "API", "value" => "admin"},
            %{"name" => "tool", "display_name" => "Tool", "value" => "learn_shopify_api"}
          ]
        },
        "requestedSchema" => %{
          "type" => "object",
          "properties" => %{},
          "required" => []
        }
      }
    })
  end

  defp emit_command_execution_approval_request(state, thread_id, turn_id) do
    emit(state, %{
      "jsonrpc" => "2.0",
      "id" => "command-approval-request-1",
      "method" => "item/commandExecution/requestApproval",
      "params" => %{
        "itemId" => "item-command-approval-1",
        "threadId" => thread_id,
        "turnId" => turn_id,
        "command" => "shopify store execute",
        "cwd" => "/workspace",
        "reason" => "Allow the shopify MCP server to run tool \"learn_shopify_api\"?",
        "availableDecisions" => ["accept", "acceptForSession", "decline", "cancel"]
      }
    })
  end

  # ---------------------------------------------------------------------------
  # Item notifications
  # ---------------------------------------------------------------------------

  defp emit_item_notifications(state, thread_id, turn_id, item) do
    emit(
      state,
      notification("item/started", %{
        "threadId" => thread_id,
        "turnId" => turn_id,
        "item" => %{
          "id" => Map.get(item, "id"),
          "type" => Map.get(item, "type"),
          "status" => "inProgress"
        }
      })
    )

    item_type = Map.get(item, "type")

    if item_type == "plan" do
      emit(
        state,
        notification("item/plan/delta", %{
          "threadId" => thread_id,
          "turnId" => turn_id,
          "itemId" => Map.get(item, "id"),
          "delta" => Map.get(item, "text")
        })
      )
    end

    if item_type == "agentMessage" do
      emit(
        state,
        notification("item/agentMessage/delta", %{
          "threadId" => thread_id,
          "turnId" => turn_id,
          "itemId" => Map.get(item, "id"),
          "delta" => Map.get(item, "text")
        })
      )
    end

    emit(
      state,
      notification("item/completed", %{
        "threadId" => thread_id,
        "turnId" => turn_id,
        "item" => item
      })
    )
  end

  # ---------------------------------------------------------------------------
  # Data builders
  # ---------------------------------------------------------------------------

  defp make_thread(thread_id, opts \\ []) do
    %{
      "collaborationMode" => @default_collaboration_mode,
      "agentNickname" => nil,
      "agentRole" => nil,
      "cliVersion" => "0.116.0",
      "createdAt" => 1_711_123_200,
      "cwd" => Keyword.get(opts, :cwd, "/tmp/mock-codex"),
      "ephemeral" => Keyword.get(opts, :ephemeral, false),
      "gitInfo" => nil,
      "historyMode" => Keyword.get(opts, :history_mode, "legacy"),
      "id" => thread_id,
      "modelProvider" => "openai",
      "name" => Keyword.get(opts, :name) || "Mock #{thread_id}",
      "path" => nil,
      "preview" => Keyword.get(opts, :preview, "Mock preview"),
      "source" => "appServer",
      "status" => if(Keyword.get(opts, :archived, false), do: "archived", else: "idle"),
      "turns" => Keyword.get(opts, :turns, []),
      "updatedAt" => Keyword.get(opts, :updated_at, 1_711_123_200)
    }
  end

  defp mock_cursor_offset(nil), do: 0

  defp mock_cursor_offset(cursor) when is_binary(cursor) do
    {offset, ""} = Integer.parse(cursor)
    offset
  end

  defp mock_thread_turns_page(%{config: %{thread_turns_cursor_mode: :repeat}}, _params, turns),
    do: {Enum.take(turns, 1), "same"}

  defp mock_thread_turns_page(%{config: %{thread_turns_cursor_mode: :empty_with_cursor}}, _params, _turns),
    do: {[], "next"}

  defp mock_thread_turns_page(state, params, turns) do
    offset = mock_cursor_offset(Map.get(params, "cursor"))
    page_size = Map.get(state.config, :thread_turns_page_size) || Map.get(params, "limit", 50)
    page = Enum.slice(turns, offset, page_size)
    next_offset = offset + length(page)
    next_cursor = if next_offset < length(turns), do: Integer.to_string(next_offset)
    {page, next_cursor}
  end

  defp handle_thread_read(state, id, thread_id, %{"mockReadError" => true}, _include_turns) do
    emit(state, error(id, -32_021, "thread read failed: #{thread_id}", %{"source" => "mock"}))
    state
  end

  defp handle_thread_read(state, id, _thread_id, %{"historyMode" => "paginated"}, true) do
    emit(
      state,
      error(id, -32_600, "paginated threads do not support thread/read(includeTurns=true)")
    )

    state
  end

  defp handle_thread_read(state, id, _thread_id, thread, include_turns) do
    thread = if include_turns, do: thread, else: Map.put(thread, "turns", [])
    emit(state, result(id, %{"thread" => thread}))
    state
  end

  defp make_thread_response(thread, params) do
    config = Map.get(params, "config", %{})

    %{
      "activePermissionProfile" => active_permission_profile(params),
      "approvalPolicy" => Map.get(params, "approvalPolicy", default_approval_policy()),
      "approvalsReviewer" => Map.get(params, "approvalsReviewer", "user"),
      "cwd" => Map.get(thread, "cwd", "/tmp/mock-codex"),
      "model" => Map.get(params, "model", "gpt-5.4"),
      "modelProvider" => Map.get(params, "modelProvider", "openai"),
      "reasoningEffort" => Map.get(config, "model_reasoning_effort", "medium"),
      "runtimeWorkspaceRoots" => Map.get(params, "runtimeWorkspaceRoots", []),
      "sandbox" => %{
        "excludeSlashTmp" => false,
        "excludeTmpdirEnvVar" => false,
        "networkAccess" => false,
        "type" => "workspaceWrite",
        "writableRoots" => []
      },
      "serviceTier" => Map.get(params, "serviceTier"),
      "thread" => thread
    }
  end

  defp active_permission_profile(%{"permissions" => profile_id}) when is_binary(profile_id) and profile_id != "",
    do: %{"extends" => nil, "id" => profile_id}

  defp active_permission_profile(_params), do: nil

  defp default_approval_policy do
    %{
      "granular" => %{
        "mcp_elicitations" => false,
        "request_permissions" => true,
        "rules" => false,
        "sandbox_approval" => true,
        "skill_approval" => false
      }
    }
  end

  defp maybe_put_initial_turns_page(response, thread, %{"initialTurnsPage" => page_params}) when is_map(page_params) do
    turns =
      thread
      |> Map.get("turns", [])
      |> Enum.reverse()
      |> Enum.take(Map.get(page_params, "limit", 1))

    Map.put(response, "initialTurnsPage", %{
      "backwardsCursor" => nil,
      "data" => turns,
      "nextCursor" => nil
    })
  end

  defp maybe_put_initial_turns_page(response, _thread, _params), do: response

  defp maybe_emit_resume_completion(state, thread_id, thread) do
    if Map.get(state.config, :complete_active_turn_before_resume_response) do
      case List.last(Map.get(thread, "turns", [])) do
        %{"id" => _turn_id} = turn ->
          emit(
            state,
            notification("turn/completed", %{
              "threadId" => thread_id,
              "turn" => Map.put(turn, "status", "completed")
            })
          )

        _other ->
          :ok
      end
    end
  end

  defp make_goal(thread_id) do
    %{
      "createdAt" => 1_711_123_200,
      "objective" => "Ship the feature",
      "status" => "active",
      "threadId" => thread_id,
      "timeUsedSeconds" => 0,
      "tokenBudget" => nil,
      "tokensUsed" => 0,
      "updatedAt" => 1_711_123_200
    }
  end

  defp goals_feature_enabled?(state) do
    Map.get(state.experimental_feature_enablement, "goals", false)
  end

  defp make_turn(turn_id, input_items, items) do
    %{
      "id" => turn_id,
      "status" => "completed",
      "items" => items,
      "input" => input_items
    }
  end

  defp agent_message_item(turn_id, text) do
    %{
      "id" => "item-agent-#{turn_id}",
      "type" => "agentMessage",
      "status" => "completed",
      "text" => text
    }
  end

  defp reasoning_item(turn_id) do
    %{
      "id" => "item-reasoning-#{turn_id}",
      "type" => "reasoning",
      "status" => "completed",
      "summary" => ["Inspecting the prompt and composing an answer"],
      "content" => ["Reading the request", "Preparing the response"]
    }
  end

  defp plan_item(turn_id) do
    %{
      "id" => "item-plan-#{turn_id}",
      "type" => "plan",
      "text" =>
        "# Plan\\n\\n- inspect the transcript support layer\\n- render a dedicated markdown card\\n- keep generic fallback for non-plan items"
    }
  end

  # ---------------------------------------------------------------------------
  # Turn text generation
  # ---------------------------------------------------------------------------

  defp assistant_text_for_turn(input_items, output_schema, collaboration_mode, reasoning_effort) do
    if output_schema do
      Jason.encode!(%{"summary" => "OK"})
    else
      Enum.find_value(input_items, fn
        %{"type" => "text", "text" => text} when is_binary(text) ->
          parse_collaboration_mode_reply(text, collaboration_mode) ||
            parse_reasoning_effort_reply(text, reasoning_effort) ||
            parse_accept_plan_reply(text, collaboration_mode) ||
            parse_single_word_reply(text)

        _ ->
          nil
      end) || "OK"
    end
  end

  defp parse_single_word_reply("Reply with the single word " <> rest) do
    rest |> String.trim_trailing(".") |> String.trim()
  end

  defp parse_single_word_reply(_), do: nil

  defp parse_collaboration_mode_reply("Reply with the current collaboration mode.", mode), do: mode

  defp parse_collaboration_mode_reply(_, _), do: nil

  defp parse_reasoning_effort_reply("Reply with the current reasoning effort.", effort), do: effort

  defp parse_reasoning_effort_reply(_, _), do: nil

  defp parse_accept_plan_reply("[[cm_plan_ready:accept]] Implement this plan.", mode), do: "accepted:#{mode}"

  defp parse_accept_plan_reply(_, _), do: nil

  defp current_reasoning_effort(params, collab_settings) do
    settings = Map.get(collab_settings, "settings", %{})
    settings_effort = Map.get(settings, "reasoning_effort")

    if is_binary(settings_effort) && settings_effort != "" do
      settings_effort
    else
      effort = Map.get(params, "effort")

      if is_binary(effort) && effort != "" do
        effort
      else
        "medium"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Fuzzy file search
  # ---------------------------------------------------------------------------

  defp fuzzy_file_search_results(query) do
    normalized = query |> to_string() |> String.trim() |> String.downcase()

    if normalized == "" do
      []
    else
      @mock_fuzzy_file_paths
      |> Enum.filter(&String.contains?(String.downcase(&1), normalized))
      |> Enum.sort_by(fn path ->
        lowered = String.downcase(path)

        cond do
          String.starts_with?(lowered, normalized) -> {0, String.length(path)}
          String.contains?(lowered, "/#{normalized}") -> {1, String.length(path)}
          true -> {2, String.length(path)}
        end
      end)
      |> Enum.take(40)
    end
  end

  # ---------------------------------------------------------------------------
  # Skill list
  # ---------------------------------------------------------------------------

  defp skill_list_response do
    %{
      "data" => [
        %{
          "cwd" => "/tmp/mock-codex",
          "errors" => [],
          "skills" => [
            %{
              "description" => "Explore user intent before building",
              "enabled" => true,
              "name" => "brainstorming",
              "path" => "/tmp/mock-codex/.agents/skills/brainstorming/SKILL.md",
              "scope" => "project",
              "shortDescription" => "Explore intent before building"
            },
            %{
              "description" => "Testing helpers and patterns",
              "enabled" => true,
              "name" => "testing",
              "path" => "/tmp/mock-codex/.agents/skills/testing/SKILL.md",
              "scope" => "project",
              "shortDescription" => "Test helpers and assertions"
            }
          ]
        }
      ]
    }
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp emit(%{owner: owner, config: config}, message) when is_pid(owner) do
    message =
      if Map.get(config, :versionless),
        do: Map.delete(message, "jsonrpc"),
        else: message

    json = Jason.encode!(message)
    Kernel.send(owner, {:mock_data, json <> "\n"})
    :ok
  end

  defp emit(_state, _message), do: :ok

  defp result(id, payload) do
    %{"jsonrpc" => "2.0", "id" => id, "result" => payload}
  end

  defp error(id, code, message, data \\ nil) do
    error_body = %{"code" => code, "message" => message}
    error_body = if data, do: Map.put(error_body, "data", data), else: error_body
    %{"jsonrpc" => "2.0", "id" => id, "error" => error_body}
  end

  defp notification(method, params) do
    %{"jsonrpc" => "2.0", "method" => method, "params" => params}
  end

  defp next_thread_id(state) do
    counter = state.thread_counter + 1
    {"thread-#{counter}", %{state | thread_counter: counter}}
  end

  defp next_turn_id(state) do
    counter = state.turn_counter + 1
    {"turn-#{counter}", %{state | turn_counter: counter}}
  end

  defp put_thread(state, thread_id, thread) do
    %{state | threads: Map.put(state.threads, thread_id, thread)}
  end

  defp unloaded_ids(state) do
    Map.get(state.config, :unloaded_thread_ids, MapSet.new())
  end

  defp config_or_param?(state, params, config_key, param_key) do
    Map.get(state.config, config_key, false) || Map.get(params, param_key, false)
  end

  defp consume_turn_config(state) do
    turn_keys = [
      :server_request,
      :elicitation_request,
      :tool_approval_elicitation_request,
      :command_execution_approval_request,
      :plan_item,
      :malformed_result,
      :omit_turn_thread_id,
      :immediate_error,
      :partial_turn_notifications,
      :delay_ms,
      :start_thread_error,
      :no_rollout,
      :thread_not_found,
      :thread_not_loaded,
      :thread_not_loaded_on_read,
      :read_error,
      :thread_not_found_on_read,
      :thread_name,
      :thread_preview,
      :thread_updated_at
    ]

    %{state | config: Map.drop(state.config, turn_keys)}
  end

  defp update_thread_turn(state, thread_id, turn_id, updated_turn) do
    case Map.get(state.threads, thread_id) do
      nil ->
        state

      thread ->
        turns =
          Enum.map(Map.get(thread, "turns", []), fn turn ->
            if Map.get(turn, "id") == turn_id, do: updated_turn, else: turn
          end)

        put_thread(state, thread_id, Map.put(thread, "turns", turns))
    end
  end

  defp maybe_filter_cwd(threads, nil), do: threads

  defp maybe_filter_cwd(threads, cwd) do
    Enum.filter(threads, &(Map.get(&1, "cwd") == cwd))
  end

  defp maybe_filter_archived(threads, true) do
    Enum.filter(threads, &(Map.get(&1, "status") == "archived"))
  end

  defp maybe_filter_archived(threads, false) do
    Enum.filter(threads, &(Map.get(&1, "status") != "archived"))
  end

  defp maybe_filter_archived(threads, _), do: threads
end
