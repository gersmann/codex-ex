defmodule CodexEx.AppServer.SessionTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.MockTransport
  alias CodexEx.AppServer.Session
  alias CodexEx.AppServer.StdioTransport
  alias CodexEx.AppServer.WebSocketFixturePlug

  @initialize_result %{
    "platformFamily" => "unix",
    "platformOs" => "linux",
    "userAgent" => "mock-codex-app-server-websocket/1.0"
  }

  setup do
    mock = start_supervised!(MockTransport)
    {:ok, mock: mock}
  end

  test "initialize performs request and initialized notification", %{mock: mock} do
    session =
      start_supervised!({
        Session,
        [transport: MockTransport, mock_pid: mock, notification_target: self()]
      })

    assert {:ok,
            %{
              "platformFamily" => "unix",
              "platformOs" => "linux",
              "userAgent" => "mock-codex-app-server/1.0"
            }} =
             Session.initialize(
               session,
               %{"clientInfo" => %{"name" => "app-test", "version" => "1.0.0"}}
             )

    assert_receive {:codex_app_server_notification, %{"method" => "session/initialized", "params" => %{}}}
  end

  test "returns results and remote errors for requests", %{mock: mock} do
    session =
      start_supervised!({
        Session,
        [transport: MockTransport, mock_pid: mock, notification_target: self()]
      })

    assert {:ok, %{"echo" => %{"value" => "ok"}}} =
             Session.request(session, "echo", %{"value" => "ok"})

    assert {:error, {:remote_error, %{"code" => -32_000, "data" => %{"source" => "mock"}, "message" => "boom"}}} =
             Session.request(session, "fail", %{})
  end

  test "consumes the request id when transport delivery is ambiguous", %{mock: mock} do
    session =
      start_supervised!({
        Session,
        [transport: MockTransport, mock_pid: mock, notification_target: self()]
      })

    cat_path =
      case System.find_executable("cat") do
        path when is_binary(path) -> path
        nil -> flunk("cat executable is required for this test")
      end

    closed_port = Port.open({:spawn_executable, cat_path}, [:binary])
    Port.close(closed_port)

    :sys.replace_state(session, fn state ->
      %{state | transport_module: StdioTransport, transport: closed_port}
    end)

    assert {:error, {:send_failed, :closed}} = Session.request(session, "echo", %{})

    :sys.replace_state(session, fn state ->
      %{state | transport_module: MockTransport, transport: mock}
    end)

    MockTransport.configure(mock, slow_delay_ms: 5_000)
    task = Task.async(fn -> Session.request(session, "slow", %{}, 10_000) end)

    assert_receive {:codex_app_server_notification, %{"method" => "slow/started", "params" => %{}}}

    assert Map.has_key?(:sys.get_state(session).pending, 2)

    assert :ok = Session.stop(session)
    assert {:error, :session_closed} = Task.await(task)
  end

  test "forwards server notifications to the configured process", %{mock: mock} do
    session =
      start_supervised!({
        Session,
        [transport: MockTransport, mock_pid: mock, notification_target: self()]
      })

    assert {:ok, %{"emitted" => true}} = Session.request(session, "emit_notification", %{})

    assert_receive {:codex_app_server_notification,
                    %{"method" => "thread/updated", "params" => %{"thread_id" => "thread-1"}}}
  end

  test "flushes pending requests when stopping the session", %{mock: mock} do
    session =
      start_supervised!({
        Session,
        [transport: MockTransport, mock_pid: mock, notification_target: self()]
      })

    task = Task.async(fn -> Session.request(session, "slow", %{}, 5_000) end)

    assert_receive {:codex_app_server_notification, %{"method" => "slow/started", "params" => %{}}},
                   2_000

    assert :ok = Session.stop(session)
    assert {:error, :session_closed} = Task.await(task)
  end

  test "times out requests inside the session and clears pending state", %{mock: mock} do
    MockTransport.configure(mock, slow_delay_ms: 75)

    session =
      start_supervised!({
        Session,
        [transport: MockTransport, mock_pid: mock, notification_target: self()]
      })

    assert {:error, :request_timeout} = Session.request(session, "slow", %{}, 50)

    assert_receive {:codex_app_server_notification, %{"method" => "slow/started", "params" => %{}}}

    assert :sys.get_state(session).pending == %{}

    assert_receive {:codex_app_server_unmatched_response, %{"result" => %{"slow" => true}}},
                   2_000

    assert :sys.get_state(session).pending == %{}
  end

  test "fails fast on invalid json-rpc payloads from transport", %{mock: mock} do
    session =
      start_supervised!({
        Session,
        [transport: MockTransport, mock_pid: mock, notification_target: self()]
      })

    assert {:error, {:protocol_error, _reason}} =
             Session.request(session, "emit_invalid_json", %{}, 5_000)
  end

  test "returns a clear startup error for missing executable" do
    previous = Process.flag(:trap_exit, true)

    on_exit(fn ->
      Process.flag(:trap_exit, previous)
    end)

    assert {:error, {:transport_start_failed, {:executable_not_found, "missing-codex-app-server"}}} =
             Session.start_link(executable: "missing-codex-app-server")
  end

  test "request accepts a named session server", %{mock: mock} do
    name = {:global, {:codex_named_session, self()}}

    _session =
      start_supervised!({
        Session,
        [name: name, transport: MockTransport, mock_pid: mock, notification_target: self()]
      })

    assert {:ok, %{"echo" => %{"value" => "named"}}} =
             Session.request(name, "echo", %{"value" => "named"})
  end

  test "stdio transport ignores child stderr output during initialization" do
    stderr_path =
      Path.join(
        System.tmp_dir!(),
        "codex_app_server_stderr_wrapper_#{System.unique_integer([:positive])}.log"
      )

    on_exit(fn -> File.rm(stderr_path) end)

    fixtures_dir = Path.join([File.cwd!(), "test", "support", "fixtures"])

    session =
      start_supervised!({
        Session,
        [
          executable: "env",
          args: [
            "MOCK_CODEX_APP_SERVER_STDERR_FILE=#{stderr_path}",
            "sh",
            Path.join(fixtures_dir, "mock_codex_app_server_stderr_wrapper.sh"),
            "bash",
            Path.join(fixtures_dir, "mock_codex_minimal_stdio.sh")
          ],
          notification_target: self()
        ]
      })

    assert {:ok,
            %{
              "platformFamily" => "unix",
              "platformOs" => "linux",
              "userAgent" => "mock-codex-app-server/1.0"
            }} =
             Session.initialize(
               session,
               %{"clientInfo" => %{"name" => "app-test", "version" => "1.0.0"}}
             )

    assert File.read!(stderr_path) =~ "mock-codex-app-server stderr noise"
  end

  test "accepts versionless app-server response envelopes", %{mock: mock} do
    MockTransport.configure(mock,
      versionless: true,
      user_agent: "mock-codex-app-server-versionless/1.0",
      config_warning: %{"summary" => "versionless warning", "details" => nil}
    )

    session =
      start_supervised!({
        Session,
        [transport: MockTransport, mock_pid: mock, notification_target: self()]
      })

    assert {:ok,
            %{
              "platformFamily" => "unix",
              "platformOs" => "linux",
              "userAgent" => "mock-codex-app-server-versionless/1.0"
            }} =
             Session.initialize(
               session,
               %{"clientInfo" => %{"name" => "app-test", "version" => "1.0.0"}}
             )

    assert_receive {:codex_app_server_notification,
                    %{
                      "method" => "configWarning",
                      "params" => %{"summary" => "versionless warning", "details" => nil}
                    }}
  end

  test "supports websocket transport requests, notifications, and remote errors" do
    retry_counter = start_supervised!({Agent, fn -> 0 end})

    server =
      start_supervised!({Bandit, plug: {WebSocketFixturePlug, [retry_counter: retry_counter]}, ip: :loopback, port: 0})

    {:ok, {_address, port}} = ThousandIsland.listener_info(server)

    session =
      start_supervised!({
        Session,
        [
          transport: :websocket,
          url: "ws://127.0.0.1:#{port}/ws",
          notification_target: self()
        ]
      })

    assert {:ok, @initialize_result} =
             Session.initialize(
               session,
               %{"clientInfo" => %{"name" => "app-test", "version" => "1.0.0"}}
             )

    assert {:ok, %{"echo" => %{"value" => "ok"}}} =
             Session.request(session, "echo", %{"value" => "ok"})

    assert {:error,
            {:remote_error,
             %{
               "code" => -32_000,
               "data" => %{"source" => "websocket"},
               "message" => "boom"
             }}} = Session.request(session, "fail", %{})

    assert {:ok, %{"emitted" => true}} = Session.request(session, "emit_notification", %{})

    assert_receive {:codex_app_server_notification,
                    %{"method" => "thread/updated", "params" => %{"thread_id" => "thread-ws-1"}}}
  end

  test "retries websocket upgrades when the endpoint is overloaded" do
    retry_counter = start_supervised!({Agent, fn -> 0 end})

    server =
      start_supervised!({Bandit, plug: {WebSocketFixturePlug, [retry_counter: retry_counter]}, ip: :loopback, port: 0})

    {:ok, {_address, port}} = ThousandIsland.listener_info(server)

    session =
      start_supervised!({
        Session,
        [
          transport: :websocket,
          url: "ws://127.0.0.1:#{port}/retry",
          retry_attempts: 1,
          retry_delay_ms: 0,
          notification_target: self()
        ]
      })

    assert {:ok, @initialize_result} =
             Session.initialize(
               session,
               %{"clientInfo" => %{"name" => "app-test", "version" => "1.0.0"}}
             )

    assert Agent.get(retry_counter, & &1) == 2
  end
end
