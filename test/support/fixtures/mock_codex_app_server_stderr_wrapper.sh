#!/usr/bin/env sh

if [ -n "${MOCK_CODEX_APP_SERVER_STDERR_FILE:-}" ]; then
  printf '%s\n' "mock-codex-app-server stderr noise" \
    >>"$MOCK_CODEX_APP_SERVER_STDERR_FILE"
else
  printf '%s\n' "mock-codex-app-server stderr noise" >&2
fi

exec "$@"
