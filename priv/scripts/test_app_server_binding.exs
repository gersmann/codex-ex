alias CodexAppServerBindingSmoke, as: BindingSmokeTest

Code.require_file(Path.join([File.cwd!(), "priv", "scripts", "support", "app_server_binding_smoke.exs"]))

{parsed, remaining, invalid} =
  OptionParser.parse(
    System.argv(),
    strict: [
      real: :boolean,
      fixture: :boolean,
      transport: :string,
      url: :string,
      executable: :string,
      arg: :keep,
      cwd: :string,
      prompt: :string,
      expected_text: :string,
      timeout: :integer,
      json: :boolean
    ]
  )

if invalid != [] or remaining != [] do
  IO.puts(:stderr, """
  Usage:
    mix run priv/scripts/test_app_server_binding.exs [options]

  Options:
    --fixture            Use the bundled bash fixture over stdio
    --real               Force the real stdio app-server path
    --transport TYPE     stdio (default) or websocket
    --url URL            Required for websocket transport
    --executable PATH    Override the stdio executable
    --arg VALUE          Repeatable stdio argument
    --cwd PATH           Thread cwd passed to thread/start
    --prompt TEXT        Prompt used for the smoke turn
    --expected-text TXT  Assert the final assistant text exactly matches TXT
    --timeout MS         Per-step timeout in milliseconds
    --json               Emit the final result as JSON
  """)

  System.halt(1)
end

if Keyword.get(parsed, :fixture, false) and Keyword.get(parsed, :real, false) do
  IO.puts(:stderr, "--fixture and --real are mutually exclusive")
  System.halt(1)
end

transport = Keyword.get(parsed, :transport, "stdio")
use_fixture? = transport == "stdio" and Keyword.get(parsed, :fixture, false)
json? = Keyword.get(parsed, :json, false)
default_prompt = BindingSmokeTest.default_prompt()
prompt = Keyword.get(parsed, :prompt, default_prompt)

mode =
  cond do
    transport == "websocket" -> "websocket"
    use_fixture? -> "fixture"
    true -> "real"
  end

client_opts =
  case transport do
    "stdio" ->
      fixture_client_opts =
        if use_fixture? do
          fixture =
            Path.join([
              File.cwd!(),
              "test",
              "support",
              "fixtures",
              "mock_codex_minimal_stdio.sh"
            ])

          [executable: "bash", args: [fixture]]
        else
          []
        end

      executable_override =
        case Keyword.get(parsed, :executable) do
          nil -> []
          executable -> [executable: executable]
        end

      arg_values = Keyword.get_values(parsed, :arg)
      arg_override = if arg_values == [], do: [], else: [args: arg_values]

      fixture_client_opts
      |> Keyword.merge(executable_override)
      |> Keyword.merge(arg_override)

    "websocket" ->
      case Keyword.get(parsed, :url) do
        nil ->
          IO.puts(:stderr, "--url is required when --transport websocket is used")
          System.halt(1)

        url ->
          [transport: :websocket, url: url]
      end

    other ->
      IO.puts(:stderr, "unsupported transport: #{other}")
      System.halt(1)
  end

base_run_opts = [
  client_opts: client_opts,
  fixture_mode: use_fixture?,
  expected_assistant_text:
    BindingSmokeTest.default_expected_assistant_text(
      mode,
      prompt,
      Keyword.get(parsed, :expected_text)
    ),
  cwd: Keyword.get(parsed, :cwd, File.cwd!()),
  prompt: prompt
]

run_opts =
  if timeout = Keyword.get(parsed, :timeout) do
    Keyword.put(base_run_opts, :timeout, timeout)
  else
    base_run_opts
  end

result = BindingSmokeTest.run(run_opts)

case {json?, result} do
  {true, {:ok, report}} ->
    IO.puts(Jason.encode!(%{status: "ok", report: report}))
    System.halt(0)

  {true, {:error, failure}} ->
    IO.puts(Jason.encode!(%{status: "error", failure: failure}))
    System.halt(1)

  {false, {:ok, report}} ->
    IO.puts("binding smoke test passed")
    IO.puts("mode=#{mode}")
    IO.puts("thread_id=#{report.thread_id}")
    IO.puts("turn_id=#{report.turn_id}")
    if is_binary(report.assistant_text), do: IO.puts("assistant_text=#{report.assistant_text}")
    IO.puts("events=#{Enum.join(report.events, ",")}")
    Enum.each(report.logs, &IO.puts("log=#{Jason.encode!(&1)}"))

    if is_binary(report.request_method) do
      IO.puts("request_method=#{report.request_method}")
    end

    System.halt(0)

  {false, {:error, failure}} ->
    IO.puts(:stderr, "binding smoke test failed")
    IO.puts(:stderr, "step=#{failure.step}")
    IO.puts(:stderr, "reason=#{inspect(failure.reason, pretty: true, limit: :infinity)}")
    System.halt(1)
end
