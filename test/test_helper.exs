max_cases = String.to_integer(System.get_env("EXUNIT_MAX_CASES", "6"))

{:ok, _pubsub} =
  Supervisor.start_link([{Phoenix.PubSub, name: CodexEx.TestPubSub}], strategy: :one_for_one)

Application.put_env(:codex_ex, :pubsub, CodexEx.TestPubSub)

ExUnit.start(capture_log: true, max_cases: max_cases)
