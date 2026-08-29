#!/usr/bin/env bash
# Minimal Codex app-server mock for StdioTransport integration tests and the
# documented binding smoke script. It handles the happy-path methods needed by
# priv/scripts/test_app_server_binding.exs --fixture.
#
# Used with mock_codex_app_server_stderr_wrapper.sh to test that
# StdioTransport ignores child stderr output during initialization.

while IFS= read -r line; do
  [ -z "$line" ] && continue

  method=$(printf '%s' "$line" | grep -o '"method"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\(.*\)"/\1/')
  id=$(printf '%s' "$line" | grep -o '"id"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/.*:[[:space:]]*//')

  case "$method" in
    initialize)
      printf '{"jsonrpc":"2.0","id":%s,"result":{"platformFamily":"unix","platformOs":"linux","userAgent":"mock-codex-app-server/1.0"}}\n' "$id"
      ;;
    initialized)
      printf '{"jsonrpc":"2.0","method":"session/initialized","params":{}}\n'
      ;;
    thread/start)
      printf '{"jsonrpc":"2.0","method":"thread/started","params":{"thread":{"id":"thread-1","cliVersion":"mock-codex-app-server/1.0","createdAt":1711123200,"cwd":"/tmp/mock-codex","ephemeral":false,"gitInfo":null,"modelProvider":"openai","preview":"Mock preview","source":"local","status":"idle","turns":[],"updatedAt":1711123200}}}\n'
      printf '{"jsonrpc":"2.0","id":%s,"result":{"thread":{"id":"thread-1","cliVersion":"mock-codex-app-server/1.0","createdAt":1711123200,"cwd":"/tmp/mock-codex","ephemeral":false,"gitInfo":null,"modelProvider":"openai","preview":"Mock preview","source":"local","status":"idle","turns":[],"updatedAt":1711123200}}}\n' "$id"
      ;;
    turn/start)
      printf '{"jsonrpc":"2.0","id":"server-request-1","method":"item/tool/requestUserInput","params":{"itemId":"item-1","questions":[{"header":"Approve","id":"approve","question":"Continue?"}],"threadId":"thread-1","turnId":"turn-1"}}\n'
      printf '{"jsonrpc":"2.0","method":"turn/started","params":{"threadId":"thread-1","turn":{"id":"turn-1","status":"inProgress","items":[]}}}\n'
      printf '{"jsonrpc":"2.0","method":"item/agentMessage/delta","params":{"threadId":"thread-1","turnId":"turn-1","itemId":"item-1","delta":"OK"}}\n'
      printf '{"jsonrpc":"2.0","method":"turn/completed","params":{"threadId":"thread-1","turn":{"id":"turn-1","status":"completed","items":[{"id":"item-1","type":"agentMessage","text":"OK"}]}}}\n'
      printf '{"jsonrpc":"2.0","id":%s,"result":{"turn":{"id":"turn-1","status":"completed","items":[{"id":"item-1","type":"agentMessage","text":"OK"}]}}}\n' "$id"
      ;;
    thread/read)
      printf '{"jsonrpc":"2.0","id":%s,"result":{"thread":{"id":"thread-1","cliVersion":"mock-codex-app-server/1.0","createdAt":1711123200,"cwd":"/tmp/mock-codex","ephemeral":false,"gitInfo":null,"modelProvider":"openai","preview":"OK","source":"local","status":"idle","turns":[{"id":"turn-1","status":"completed","items":[{"id":"item-1","type":"agentMessage","text":"OK"}]}],"updatedAt":1711123201}}}\n' "$id"
      ;;
  esac
done
