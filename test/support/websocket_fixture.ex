defmodule CodexEx.AppServer.WebSocketFixturePlug do
  @moduledoc false

  import Plug.Conn

  alias CodexEx.AppServer.WebSocketFixtureServer

  def init(opts), do: opts

  def call(conn, opts) do
    case conn.request_path do
      "/ws" ->
        upgrade(conn, opts)

      "/retry" ->
        if Agent.get_and_update(opts[:retry_counter], fn count -> {count, count + 1} end) == 0 do
          conn
          |> put_resp_header("retry-after", "0")
          |> send_resp(503, "busy")
        else
          upgrade(conn, opts)
        end

      _other ->
        send_resp(conn, 404, "not found")
    end
  end

  defp upgrade(conn, opts) do
    conn
    |> WebSockAdapter.upgrade(WebSocketFixtureServer, %{push_delay_ms: Keyword.get(opts, :push_delay_ms, 0)},
      timeout: Keyword.get(opts, :timeout, 60_000)
    )
    |> halt()
  end
end

defmodule CodexEx.AppServer.WebSocketFixtureServer do
  @moduledoc false

  @behaviour WebSock

  @initialize_result %{
    "platformFamily" => "unix",
    "platformOs" => "linux",
    "userAgent" => "mock-codex-app-server-websocket/1.0"
  }

  @impl true
  def init(state) do
    {:ok,
     state
     |> Map.put(:pending_pushes, %{})
     |> Map.put(:slow_timer, nil)
     |> Map.put(:threads, %{})
     |> Map.put(:thread_counter, 0)
     |> Map.put(:turn_counter, 0)}
  end

  @impl true
  def handle_in({payload, opcode: :text}, state) do
    case Jason.decode(payload) do
      {:ok, message} ->
        route_message(message, state)

      {:error, reason} ->
        {:stop, {:invalid_json, reason}, {1002, "invalid json"}, state}
    end
  end

  @impl true
  def handle_info({:push_frames, push_id}, state) do
    case Map.pop(state.pending_pushes, push_id) do
      {nil, pending_pushes} ->
        {:ok, %{state | pending_pushes: pending_pushes}}

      {frames, pending_pushes} ->
        {:push, Enum.map(frames, &{:text, Jason.encode!(&1)}), %{state | pending_pushes: pending_pushes}}
    end
  end

  def handle_info({:complete_slow, id}, %{slow_timer: {id, response}} = state) do
    {:push, {:text, Jason.encode!(response)}, %{state | slow_timer: nil}}
  end

  def handle_info(_message, state), do: {:ok, state}

  defp route_message(%{"id" => id, "method" => "initialize"}, state) do
    response = %{"jsonrpc" => "2.0", "id" => id, "result" => @initialize_result}
    {:push, {:text, Jason.encode!(response)}, state}
  end

  defp route_message(%{"id" => id, "method" => "echo", "params" => params}, state) do
    response = %{"jsonrpc" => "2.0", "id" => id, "result" => %{"echo" => params}}
    {:push, {:text, Jason.encode!(response)}, state}
  end

  defp route_message(%{"id" => id, "method" => "config/read"}, state) do
    response = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "result" => %{
        "config" => %{
          "developer_instructions" => "WebSocket fixture developer instructions.",
          "model_reasoning_summary" => nil
        },
        "origins" => %{}
      }
    }

    {:push, {:text, Jason.encode!(response)}, state}
  end

  defp route_message(%{"id" => id, "method" => "thread/start"}, state) do
    {thread_id, state} = next_thread_id(state)
    thread = make_thread(thread_id)
    response = %{"jsonrpc" => "2.0", "id" => id, "result" => make_thread_response(thread)}

    notification = %{
      "jsonrpc" => "2.0",
      "method" => "thread/started",
      "params" => %{"thread" => thread}
    }

    {:push, [{:text, Jason.encode!(notification)}, {:text, Jason.encode!(response)}],
     put_in(state.threads[thread_id], thread)}
  end

  defp route_message(%{"id" => id, "method" => "thread/read", "params" => params}, state) do
    thread_id = params["threadId"]
    include_turns = params["includeTurns"] == true
    thread = Map.get(state.threads, thread_id, make_thread(thread_id))

    thread =
      if include_turns do
        thread
      else
        Map.put(thread, "turns", [])
      end

    response = %{"jsonrpc" => "2.0", "id" => id, "result" => %{"thread" => thread}}
    {:push, {:text, Jason.encode!(response)}, state}
  end

  defp route_message(%{"id" => id, "method" => "thread/turns/list", "params" => params}, state) do
    thread_id = params["threadId"]
    turns = state.threads |> Map.get(thread_id, make_thread(thread_id)) |> Map.fetch!("turns")

    response = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "result" => %{
        "backwardsCursor" => nil,
        "data" => Enum.reverse(turns),
        "nextCursor" => nil
      }
    }

    {:push, {:text, Jason.encode!(response)}, state}
  end

  defp route_message(%{"id" => id, "method" => "turn/start", "params" => params}, state) do
    thread_id = params["threadId"]
    input = Map.get(params, "input", [])
    output_schema = Map.get(params, "outputSchema")
    push_delay_ms = Map.get(params, "mockPushDelayMs", state.push_delay_ms)
    assistant_text = assistant_text_for_turn(input, output_schema)
    thread = Map.get(state.threads, thread_id, make_thread(thread_id))
    {turn_id, state} = next_turn_id(state)
    turn = make_turn(turn_id, input, assistant_text)
    updated_thread = Map.update!(thread, "turns", &(&1 ++ [turn]))
    state = put_in(state.threads[thread_id], updated_thread)
    agent_message_item = agent_message_item(turn_id, assistant_text)

    started_notification = %{
      "jsonrpc" => "2.0",
      "method" => "turn/started",
      "params" => %{"threadId" => thread_id, "turn" => turn}
    }

    completed_notification = %{
      "jsonrpc" => "2.0",
      "method" => "turn/completed",
      "params" => %{"threadId" => thread_id, "turn" => turn}
    }

    item_started_notification = %{
      "jsonrpc" => "2.0",
      "method" => "item/started",
      "params" => %{
        "threadId" => thread_id,
        "turnId" => turn_id,
        "item" => %{
          "id" => agent_message_item["id"],
          "type" => agent_message_item["type"],
          "status" => "inProgress"
        }
      }
    }

    delta_notification = %{
      "jsonrpc" => "2.0",
      "method" => "item/agentMessage/delta",
      "params" => %{
        "threadId" => thread_id,
        "turnId" => turn_id,
        "itemId" => agent_message_item["id"],
        "delta" => assistant_text
      }
    }

    item_completed_notification = %{
      "jsonrpc" => "2.0",
      "method" => "item/completed",
      "params" => %{
        "threadId" => thread_id,
        "turnId" => turn_id,
        "item" => agent_message_item
      }
    }

    response = %{"jsonrpc" => "2.0", "id" => id, "result" => %{"turn" => turn}}

    frames = [
      started_notification,
      item_started_notification,
      delta_notification,
      item_completed_notification,
      completed_notification,
      response
    ]

    if is_integer(push_delay_ms) and push_delay_ms > 0 do
      push_id = make_ref()
      Process.send_after(self(), {:push_frames, push_id}, push_delay_ms)
      {:ok, put_in(state.pending_pushes[push_id], frames)}
    else
      {:push, Enum.map(frames, &{:text, Jason.encode!(&1)}), state}
    end
  end

  defp route_message(%{"id" => id, "method" => "fail"}, state) do
    response = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "error" => %{"code" => -32_000, "message" => "boom", "data" => %{"source" => "websocket"}}
    }

    {:push, {:text, Jason.encode!(response)}, state}
  end

  defp route_message(%{"id" => id, "method" => "emit_notification"}, state) do
    response = %{"jsonrpc" => "2.0", "id" => id, "result" => %{"emitted" => true}}

    notification = %{
      "jsonrpc" => "2.0",
      "method" => "thread/updated",
      "params" => %{"thread_id" => "thread-ws-1"}
    }

    {:push, [{:text, Jason.encode!(response)}, {:text, Jason.encode!(notification)}], state}
  end

  defp route_message(%{"id" => id, "method" => "slow"}, state) do
    response = %{"jsonrpc" => "2.0", "id" => id, "result" => %{"slow" => true}}
    timer_id = make_ref()
    Process.send_after(self(), {:complete_slow, timer_id}, 200)
    {:ok, %{state | slow_timer: {timer_id, response}}}
  end

  defp route_message(%{"method" => "initialized"}, state), do: {:ok, state}

  defp route_message(%{"id" => id}, state) do
    response = %{"jsonrpc" => "2.0", "id" => id, "result" => %{}}
    {:push, {:text, Jason.encode!(response)}, state}
  end

  defp route_message(_message, state), do: {:ok, state}

  defp next_thread_id(state) do
    next_counter = state.thread_counter + 1
    {"thread-ws-#{next_counter}", %{state | thread_counter: next_counter}}
  end

  defp next_turn_id(state) do
    next_counter = state.turn_counter + 1
    {"turn-ws-#{next_counter}", %{state | turn_counter: next_counter}}
  end

  defp make_thread(thread_id) do
    %{
      "agentNickname" => nil,
      "agentRole" => nil,
      "cliVersion" => "0.116.0",
      "createdAt" => 1_711_123_200,
      "cwd" => "/tmp/mock-codex",
      "ephemeral" => false,
      "gitInfo" => nil,
      "historyMode" => "paginated",
      "id" => thread_id,
      "modelProvider" => "openai",
      "name" => "Mock #{thread_id}",
      "path" => nil,
      "preview" => "Mock preview",
      "source" => "appServer",
      "status" => "idle",
      "turns" => [],
      "updatedAt" => 1_711_123_200
    }
  end

  defp make_thread_response(thread) do
    %{
      "activePermissionProfile" => %{"extends" => nil, "id" => ":workspace"},
      "approvalPolicy" => "never",
      "approvalsReviewer" => "user",
      "cwd" => "/tmp/mock-codex",
      "model" => "gpt-5.4",
      "modelProvider" => "openai",
      "reasoningEffort" => "medium",
      "runtimeWorkspaceRoots" => [],
      "sandbox" => %{
        "mode" => "workspace-write",
        "networkAccess" => false,
        "excludeTmpdirEnvVar" => false,
        "excludeSlurmEnvVar" => false
      },
      "serviceTier" => nil,
      "thread" => thread
    }
  end

  defp make_turn(turn_id, input, assistant_text) do
    %{
      "id" => turn_id,
      "status" => "completed",
      "items" => [agent_message_item(turn_id, assistant_text)],
      "input" => input
    }
  end

  defp agent_message_item(turn_id, assistant_text) do
    %{
      "id" => "item-agent-#{turn_id}",
      "type" => "agentMessage",
      "status" => "completed",
      "text" => assistant_text
    }
  end

  defp assistant_text_for_turn(input, output_schema)
       when is_list(input) and (is_map(output_schema) or is_nil(output_schema)) do
    if is_map(output_schema) do
      Jason.encode!(%{"summary" => "OK"})
    else
      assistant_text_for_input(input)
    end
  end

  defp assistant_text_for_input(input) when is_list(input) do
    Enum.find_value(input, "OK", fn
      %{"type" => "text", "text" => text} when is_binary(text) ->
        parse_single_word_reply(text)

      _item ->
        nil
    end)
  end

  defp parse_single_word_reply(text) do
    case Regex.run(~r/\AReply with the single word ([^\s.]+)\.?\z/, text) do
      [_match, reply] -> reply
      _other -> "OK"
    end
  end
end
