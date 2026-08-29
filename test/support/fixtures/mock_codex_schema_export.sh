#!/usr/bin/env sh

set -eu

if [ "$#" -ne 5 ]; then
  echo "unexpected argument count: $#">&2
  exit 64
fi

if [ "$1" != "app-server" ] || [ "$2" != "generate-json-schema" ] || [ "$3" != "--experimental" ] || [ "$4" != "--out" ]; then
  echo "unexpected arguments: $*">&2
  exit 64
fi

out_dir="$5"

mkdir -p "$out_dir/v1" "$out_dir/v2"

cat > "$out_dir/v1/InitializeParams.json" <<'EOF'
{"title":"InitializeParams"}
EOF

cat > "$out_dir/v2/ThreadStartedNotification.json" <<'EOF'
{"title":"ThreadStartedNotification"}
EOF
