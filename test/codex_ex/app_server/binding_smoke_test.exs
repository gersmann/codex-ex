Code.require_file(Path.join([File.cwd!(), "priv", "scripts", "support", "app_server_binding_smoke.exs"]))

defmodule CodexEx.AppServer.BindingSmokeTestTest do
  use ExUnit.Case, async: true

  alias CodexAppServerBindingSmoke, as: BindingSmokeTest
  alias CodexEx.AppServer.MockTransport
  alias CodexEx.AppServer.WebSocketFixturePlug

  setup do
    mock = start_supervised!(MockTransport)

    {:ok, mock: mock}
  end

  test "runs the smoke flow against the stdio fixture", %{mock: mock} do
    assert {:ok, report} =
             BindingSmokeTest.run(
               client_opts: [transport: MockTransport, mock_pid: mock],
               fixture_mode: true,
               timeout: 5_000
             )

    assert report.fixture_mode? == true
    assert report.thread_id == "thread-1"
    assert report.turn_id == "turn-1"
    assert report.events == ["thread/started", "turn/started", "turn/completed"]
    assert report.request_method == "item/tool/requestUserInput"
    assert report.refreshed_turn_count == 1
    assert {:ok, _json} = Jason.encode(report)
    assert Enum.any?(report.logs, &(&1["type"] == "turn/start" || &1[:type] == "turn/start"))
    assert Enum.any?(report.logs, &(&1["type"] == "turn/result" || &1[:type] == "turn/result"))
  end

  test "runs the smoke flow against a websocket app-server" do
    retry_counter = start_supervised!({Agent, fn -> 0 end})

    server =
      start_supervised!({Bandit, plug: {WebSocketFixturePlug, [retry_counter: retry_counter]}, ip: :loopback, port: 0})

    {:ok, {_address, port}} = ThousandIsland.listener_info(server)

    assert {:ok, report} =
             BindingSmokeTest.run(
               client_opts: [transport: :websocket, url: "ws://127.0.0.1:#{port}/ws"],
               timeout: 5_000
             )

    assert report.fixture_mode? == false
    assert is_binary(report.thread_id)
    assert is_binary(report.turn_id)
    assert report.assistant_text == "OK"
    assert report.events == ["thread/started", "turn/started", "turn/completed"]
    assert report.request_method == nil
    assert report.refreshed_turn_count >= 1

    assert Enum.any?(
             report.logs,
             &(&1[:type] == "item/agentMessage/delta" and &1[:delta] == "OK")
           )

    assert Enum.any?(report.logs, &(&1[:type] == "item/completed" and &1[:text] == "OK"))
  end

  test "CLI honors an explicit timeout while its default tolerates the same delayed fixture" do
    server = start_supervised!({Bandit, plug: {WebSocketFixturePlug, [push_delay_ms: 150]}, ip: :loopback, port: 0})
    {:ok, {_address, port}} = ThousandIsland.listener_info(server)
    paths = Enum.flat_map(:code.get_path(), &["-pa", List.to_string(&1)])

    args =
      paths ++
        [
          "-e",
          "Application.ensure_all_started(:codex_ex); Code.require_file(\"priv/scripts/test_app_server_binding.exs\")",
          "--",
          "--transport",
          "websocket",
          "--url",
          "ws://127.0.0.1:#{port}/ws",
          "--json"
        ]

    executable = System.find_executable("elixir")
    {short, exit_code} = System.cmd(executable, args ++ ["--timeout", "10"], stderr_to_stdout: true)
    assert exit_code != 0
    assert short =~ "timeout"
    {normal, 0} = System.cmd(executable, args, stderr_to_stdout: true)
    assert normal =~ ~s("status":"ok")
  end

  test "custom prompts only assert assistant text when explicitly configured" do
    assert BindingSmokeTest.default_expected_assistant_text(
             "real",
             "Reply with the single word YES."
           ) == nil

    assert BindingSmokeTest.default_expected_assistant_text(
             "real",
             "Reply with the single word YES.",
             "YES"
           ) == "YES"
  end

  test "reports immediate turn/start failures as turn_result errors", %{
    mock: mock
  } do
    assert {:error, %{step: :turn_result, reason: {:remote_error, %{"code" => -32_010}}}} =
             BindingSmokeTest.run(
               client_opts: [transport: MockTransport, mock_pid: mock],
               prompt: "Reply with the single word OK.",
               turn_opts: %{"mockImmediateTurnError" => true},
               timeout: 1_000
             )
  end

  test "supports semantic assertions for custom websocket prompts" do
    retry_counter = start_supervised!({Agent, fn -> 0 end})

    server =
      start_supervised!({Bandit, plug: {WebSocketFixturePlug, [retry_counter: retry_counter]}, ip: :loopback, port: 0})

    {:ok, {_address, port}} = ThousandIsland.listener_info(server)

    assert {:ok, report} =
             BindingSmokeTest.run(
               client_opts: [transport: :websocket, url: "ws://127.0.0.1:#{port}/ws"],
               prompt: "Reply with the single word YES.",
               expected_assistant_text: "YES",
               timeout: 5_000
             )

    assert report.assistant_text == "YES"
  end
end
