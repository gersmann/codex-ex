defmodule CodexAppServerBindingSmoke do
  @moduledoc false

  alias CodexEx.AppServer.Client
  alias CodexEx.AppServer.Message
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerRequest
  alias CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputResponse

  alias CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputResponse.ToolRequestUserInputAnswer

  alias CodexEx.AppServer.Protocol.Generated.V1.InitializeResponse
  alias CodexEx.AppServer.Thread
  alias CodexEx.AppServer.ThreadItem
  alias CodexEx.AppServer.Turn

  @default_timeout 30_000
  @default_prompt "Reply with the single word OK."

  def default_prompt, do: @default_prompt

  def default_expected_assistant_text(mode, prompt, explicit_expected_text \\ nil)

  def default_expected_assistant_text(_mode, _prompt, explicit_expected_text)
      when is_binary(explicit_expected_text) do
    explicit_expected_text
  end

  def default_expected_assistant_text("fixture", _prompt, nil), do: nil
  def default_expected_assistant_text(_mode, @default_prompt, nil), do: "OK"
  def default_expected_assistant_text(_mode, _prompt, nil), do: nil

  def run(opts \\ []) do
    ctx = build_run_context(opts)

    case Client.connect(ctx.client_opts) do
      {:ok, client} ->
        try do
          run_connected(client, ctx)
        after
          _ = Client.disconnect(client)
        end

      {:error, reason} ->
        failure(:connect, reason, ctx.report)
    end
  end

  defp build_run_context(opts) do
    fixture_mode? = Keyword.get(opts, :fixture_mode, false)

    %{
      client_opts: build_client_opts(opts),
      expected_assistant_text: Keyword.get(opts, :expected_assistant_text),
      fixture_mode?: fixture_mode?,
      prompt: Keyword.get(opts, :prompt, @default_prompt),
      report: base_report(fixture_mode?),
      thread_params: build_thread_params(opts),
      timeout: Keyword.get(opts, :timeout, @default_timeout),
      turn_opts: build_turn_opts(opts, fixture_mode?)
    }
  end

  defp run_connected(client, ctx) do
    with {:ok, initialize_result} <- fetch_initialize_result(client, ctx.report),
         :ok <- subscribe(client, ctx.report),
         :ok <- maybe_register_request_handler(client, ctx.fixture_mode?, ctx.report),
         {:ok, %Thread{id: thread_id} = thread} <-
           start_thread(client, ctx.thread_params, ctx.report),
         {:ok, thread_started, pre_thread_messages} <-
           await_thread_started(thread_id, ctx.timeout, ctx.report),
         {:ok, turn_started, run_result, pre_turn_messages} <-
           start_turn(thread, ctx.prompt, ctx.turn_opts, ctx.timeout, ctx.report),
         {:ok, turn_completed, pre_completed_messages} <-
           await_turn_completed(thread_id, turn_started, ctx.timeout, ctx.report),
         {:ok, assistant_text_from_run} <- await_run_text(run_result, ctx.timeout, ctx.report),
         {:ok, refreshed_turn_count, assistant_text} <-
           refresh_thread(thread, Message.turn_id(turn_started), ctx.report),
         {:ok, request_method} <-
           request_method_from_messages(
             ctx.fixture_mode?,
             pre_turn_messages ++ pre_completed_messages,
             ctx.report
           ),
         :ok <-
           maybe_assert_assistant_text(
             ctx.expected_assistant_text,
             assistant_text || assistant_text_from_run,
             ctx.report
           ) do
      success_report(ctx, %{
        assistant_text: assistant_text || assistant_text_from_run,
        initialize_result: initialize_result,
        pre_completed_messages: pre_completed_messages,
        pre_thread_messages: pre_thread_messages,
        pre_turn_messages: pre_turn_messages,
        refreshed_turn_count: refreshed_turn_count,
        request_method: request_method,
        thread_id: thread_id,
        thread_started: thread_started,
        turn_completed: turn_completed,
        turn_started: turn_started
      })
    else
      {:error, %{step: _step} = failure} ->
        {:error, failure}
    end
  end

  defp await_thread_started(thread_id, timeout, report) do
    await_message(
      fn message ->
        if Message.method_name(message) == "thread/started" and
             Message.thread_id(message) == thread_id do
          {:ok, message}
        else
          :skip
        end
      end,
      timeout,
      :thread_started_event,
      report
    )
  end

  defp await_turn_completed(thread_id, turn_started, timeout, report) do
    turn_id = Message.turn_id(turn_started)

    await_message(
      fn message ->
        if Message.method_name(message) == "turn/completed" and
             Message.thread_id(message) == thread_id and
             Message.turn_id(message) == turn_id do
          {:ok, message}
        else
          :skip
        end
      end,
      timeout,
      :turn_completed_event,
      report
    )
  end

  defp success_report(ctx, %{
         assistant_text: assistant_text,
         initialize_result: initialize_result,
         pre_completed_messages: pre_completed_messages,
         pre_thread_messages: pre_thread_messages,
         pre_turn_messages: pre_turn_messages,
         refreshed_turn_count: refreshed_turn_count,
         request_method: request_method,
         thread_id: thread_id,
         thread_started: thread_started,
         turn_completed: turn_completed,
         turn_started: turn_started
       }) do
    streamed_messages =
      pre_thread_messages ++
        [thread_started] ++
        pre_turn_messages ++
        [turn_started] ++
        pre_completed_messages ++
        [turn_completed]

    final_turn =
      case Message.extract_turn(turn_completed) do
        {:ok, turn} -> turn
        %Turn{} = turn -> turn
        _other -> nil
      end

    {:ok,
     %{
       initialize_result: initialize_result_report(initialize_result),
       thread_id: thread_id,
       turn_id: Message.turn_id(turn_started),
       turn_status: final_turn && final_turn.status,
       refreshed_turn_count: refreshed_turn_count,
       events: [
         Message.method_name(thread_started),
         Message.method_name(turn_started),
         Message.method_name(turn_completed)
       ],
       assistant_text: assistant_text,
       logs:
         build_logs(%{
           fixture_mode?: ctx.fixture_mode?,
           initialize_result: initialize_result,
           prompt: ctx.prompt,
           refreshed_turn_count: refreshed_turn_count,
           request_method: request_method,
           streamed_messages: streamed_messages,
           thread_id: thread_id,
           thread_params: ctx.thread_params,
           turn_opts: ctx.turn_opts,
           turn_id: Message.turn_id(turn_started),
           turn_status: final_turn && final_turn.status,
           assistant_text: assistant_text
         }),
       fixture_mode?: ctx.fixture_mode?,
       request_method: request_method
     }}
  end

  defp initialize_result_report(%InitializeResponse{} = result) do
    %{
      codex_home: result.codex_home,
      platform_family: result.platform_family,
      platform_os: result.platform_os,
      user_agent: result.user_agent
    }
  end

  defp fetch_initialize_result(client, report) do
    case Client.initialize_result(client) do
      {:ok, %InitializeResponse{} = result} -> {:ok, result}
      {:error, reason} -> failure(:initialize_result, reason, report)
    end
  end

  defp subscribe(client, report) do
    case Client.subscribe(client) do
      :ok -> :ok
      {:error, reason} -> failure(:subscribe, reason, report)
    end
  end

  defp maybe_register_request_handler(_client, false, _report), do: :ok

  defp maybe_register_request_handler(client, true, report) do
    case Client.register_request_handler(client, fn _request ->
           {:ok,
            %ToolRequestUserInputResponse{
              answers: %{"approve" => %ToolRequestUserInputAnswer{answers: ["yes"]}}
            }}
         end) do
      :ok -> :ok
      {:error, reason} -> failure(:register_request_handler, reason, report)
    end
  end

  defp start_thread(client, thread_params, report) do
    case Client.start_thread(client, thread_params) do
      {:ok, %Thread{} = thread} -> {:ok, thread}
      {:error, reason} -> failure(:thread_start, reason, report)
    end
  end

  defp start_turn(thread, prompt, turn_opts, timeout, report) do
    task = Task.async(fn -> Thread.run_text(thread, prompt, turn_opts) end)
    await_turn_started_or_result(task, thread.id, timeout, report, [])
  end

  defp await_turn_started_or_result(task, thread_id, timeout, report, skipped_messages) do
    receive do
      {:codex_app_server_event, message} ->
        if Message.method_name(message) == "turn/started" and
             Message.thread_id(message) == thread_id do
          {:ok, message, task, Enum.reverse(skipped_messages)}
        else
          await_turn_started_or_result(task, thread_id, timeout, report, [
            message | skipped_messages
          ])
        end

      {ref, {:error, reason}} when ref == task.ref ->
        Process.demonitor(ref, [:flush])
        failure(:turn_result, reason, report)

      {ref, {:ok, assistant_text}} when ref == task.ref ->
        Process.demonitor(ref, [:flush])

        await_turn_started_after_run_result(
          thread_id,
          timeout,
          report,
          Enum.reverse(skipped_messages),
          assistant_text
        )

      {:DOWN, ref, :process, _pid, reason} when ref == task.ref ->
        failure(:turn_result, reason, report)
    after
      timeout ->
        _ = Task.shutdown(task, :brutal_kill)
        failure(:turn_started_event, :timeout, report)
    end
  end

  defp await_turn_started_after_run_result(
         thread_id,
         timeout,
         report,
         skipped_messages,
         assistant_text
       ) do
    case await_message(
           fn message ->
             if Message.method_name(message) == "turn/started" and
                  Message.thread_id(message) == thread_id do
               {:ok, message}
             else
               :skip
             end
           end,
           timeout,
           :turn_started_event,
           report,
           []
         ) do
      {:ok, turn_started, post_result_messages} ->
        {:ok, turn_started, {:ready, assistant_text}, skipped_messages ++ post_result_messages}

      {:error, %{step: _step} = failure} ->
        {:error, failure}
    end
  end

  defp await_run_text({:ready, assistant_text}, _timeout, _report), do: {:ok, assistant_text}

  defp await_run_text(task, timeout, report) do
    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, {:ok, assistant_text}} -> {:ok, assistant_text}
      {:ok, {:error, reason}} -> failure(:turn_result, reason, report)
      nil -> failure(:turn_result, :timeout, report)
    end
  end

  defp refresh_thread(thread, turn_id, report) when is_binary(turn_id) do
    case Thread.refresh(thread, include_turns: true) do
      {:ok, %Thread{snapshot: snapshot}} ->
        case Enum.find(snapshot.turns, &(&1.id == turn_id)) do
          %Turn{} = turn ->
            {:ok, length(snapshot.turns), assistant_text_from_turn(turn)}

          nil ->
            failure(:thread_refresh, {:turn_missing, turn_id}, report)
        end

      {:error, reason} ->
        failure(:thread_refresh, reason, report)
    end
  end

  defp await_message(matcher, timeout, step, report, skipped \\ [])
       when is_function(matcher, 1) do
    receive do
      {:codex_app_server_event, message} ->
        case matcher.(message) do
          {:ok, matched} -> {:ok, matched, Enum.reverse(skipped)}
          :skip -> await_message(matcher, timeout, step, report, [message | skipped])
        end

      {:codex_app_server_protocol_error, reason, payload} ->
        failure(step, {:protocol_error, reason, payload}, report)
    after
      timeout ->
        failure(step, :timeout, report)
    end
  end

  defp build_thread_params(opts) do
    opts
    |> Keyword.get(:thread_params, %{})
    |> Map.new()
    |> Map.put_new("cwd", Keyword.get(opts, :cwd, File.cwd!()))
  end

  defp build_turn_opts(opts, fixture_mode?) do
    opts
    |> Keyword.get(:turn_opts, %{})
    |> Map.new()
    |> maybe_put_fixture_request(fixture_mode?)
  end

  defp maybe_put_fixture_request(turn_opts, true) do
    Map.put_new(turn_opts, "mockServerRequest", true)
  end

  defp maybe_put_fixture_request(turn_opts, false), do: turn_opts

  defp build_client_opts(opts) do
    explicit_client_opts = Keyword.get(opts, :client_opts, [])

    top_level_client_opts =
      Keyword.take(opts, [
        :name,
        :initialize_params,
        :strict_protocol,
        :transport,
        :url,
        :websocket_url,
        :bearer_token,
        :headers,
        :retry_attempts,
        :retry_delay_ms,
        :connect_opts,
        :handshake_timeout,
        :executable,
        :args
      ])

    Keyword.merge(top_level_client_opts, explicit_client_opts)
  end

  defp base_report(fixture_mode?) do
    %{
      initialize_result: nil,
      thread_id: nil,
      turn_id: nil,
      turn_status: nil,
      refreshed_turn_count: 0,
      events: [],
      assistant_text: nil,
      logs: [],
      fixture_mode?: fixture_mode?,
      request_method: nil
    }
  end

  defp failure(step, reason, report) do
    {:error, %{step: step, reason: reason, report: report}}
  end

  defp build_logs(%{
         fixture_mode?: fixture_mode?,
         initialize_result: initialize_result,
         prompt: prompt,
         refreshed_turn_count: refreshed_turn_count,
         assistant_text: assistant_text,
         streamed_messages: streamed_messages,
         thread_id: thread_id,
         thread_params: thread_params,
         turn_id: turn_id,
         turn_opts: turn_opts,
         turn_status: turn_status
       }) do
    [
      %{direction: "input", fixture_mode?: fixture_mode?, type: "initialize"},
      %{
        direction: "output",
        type: "initialize",
        platform_family: initialize_result.platform_family,
        platform_os: initialize_result.platform_os,
        user_agent: initialize_result.user_agent
      },
      %{direction: "input", cwd: thread_params["cwd"], type: "thread/start"},
      %{
        direction: "input",
        prompt: prompt,
        turn_option_keys: turn_opts |> Map.keys() |> Enum.sort(),
        type: "turn/start"
      },
      Enum.map(streamed_messages, &message_log/1),
      %{
        assistant_text: assistant_text,
        direction: "output",
        thread_id: thread_id,
        turn_id: turn_id,
        turn_status: turn_status,
        type: "turn/result"
      },
      %{
        direction: "output",
        refreshed_turn_count: refreshed_turn_count,
        thread_id: thread_id,
        type: "thread/read"
      }
    ]
    |> Enum.reject(&is_nil/1)
    |> List.flatten()
  end

  defp message_log(message) do
    item =
      case Message.extract_item(message) do
        {:ok, parsed_item} -> parsed_item
        %ThreadItem.AgentMessage{} = parsed_item -> parsed_item
        %ThreadItem.Generic{} = parsed_item -> parsed_item
        _other -> nil
      end

    turn =
      case Message.extract_turn(message) do
        {:ok, parsed_turn} -> parsed_turn
        %Turn{} = parsed_turn -> parsed_turn
        _other -> nil
      end

    %{
      delta: Message.extract_text_delta(message),
      direction: "output",
      item_type: item && ThreadItem.type(item),
      status: turn && turn.status,
      text: item && ThreadItem.text(item),
      thread_id: Message.thread_id(message),
      turn_id: Message.turn_id(message),
      type: Message.method_name(message)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp request_method_from_messages(false, _messages, _report), do: {:ok, nil}

  defp request_method_from_messages(true, messages, report) do
    case Enum.find(messages, &match?(%ServerRequest{}, &1)) do
      %ServerRequest{method: method} -> {:ok, method}
      nil -> failure(:server_request_event, :missing, report)
    end
  end

  defp maybe_assert_assistant_text(nil, _assistant_text, _report), do: :ok
  defp maybe_assert_assistant_text(expected, expected, _report), do: :ok

  defp maybe_assert_assistant_text(expected_assistant_text, assistant_text, report) do
    failure(
      :assistant_text,
      {:unexpected_assistant_text, %{expected: expected_assistant_text, actual: assistant_text}},
      report
    )
  end

  defp assistant_text_from_turn(%Turn{items: items}) do
    items
    |> Enum.reverse()
    |> Enum.find_value(&ThreadItem.text/1)
  end
end
