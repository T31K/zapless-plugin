#!/usr/bin/env bash

set -euo pipefail

# Read hook input JSON from stdin
input=$(cat)

# Extract the bash command using jq
cmd=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

# Only act on zapless commands
case "$cmd" in
  zapless*) ;;
  *) exit 0 ;;
esac

# Check auth is still valid (reads local session file — fast, no network call)
if ! zapless auth status > /dev/null 2>&1; then
  printf '{"reason": "Zapless session expired or not found. Run: zapless auth login --token <your-token>. Get your token at: https://zapless.app/dashboard"}'
  exit 2
fi

exit 0
