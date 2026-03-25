#!/usr/bin/env bash

set -euo pipefail

APPS_FILE="$HOME/.zapless/apps.json"
LAST_CHECK_FILE="$HOME/.zapless/.last_check"

escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

emit() {
  local content
  content=$(escape_for_json "$1")
  if [ -n "${CURSOR_PLUGIN_ROOT:-}" ]; then
    printf '{\n  "additional_context": "%s"\n}\n' "$content"
  else
    printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "Stop",\n    "additionalContext": "%s"\n  }\n}\n' "$content"
  fi
}

# Ensure ~/.zapless exists
mkdir -p "$HOME/.zapless"

# Throttle — only check every 60 seconds
now=$(date +%s)
last=$(cat "$LAST_CHECK_FILE" 2>/dev/null || echo 0)
if [ $((now - last)) -lt 60 ]; then
  exit 0
fi
echo "$now" > "$LAST_CHECK_FILE"

# Skip if not authenticated
if ! zapless auth status > /dev/null 2>&1; then
  exit 0
fi

# Fetch current apps
current=$(zapless apps list --json 2>/dev/null) || exit 0

# Compare with saved list
saved=$(cat "$APPS_FILE" 2>/dev/null || echo "[]")

if [ "$current" = "$saved" ]; then
  exit 0
fi

# Save updated list
echo "$current" > "$APPS_FILE"

# Find new apps (in current but not in saved)
new_apps=$(echo "$current" | tr -d '[]"' | tr ',' '\n' | while IFS= read -r app; do
  app=$(echo "$app" | tr -d ' ')
  [ -z "$app" ] && continue
  echo "$saved" | grep -q "\"$app\"" || echo "$app"
done | tr '\n' ',' | sed 's/,$//')

# Find removed apps (in saved but not in current)
removed_apps=$(echo "$saved" | tr -d '[]"' | tr ',' '\n' | while IFS= read -r app; do
  app=$(echo "$app" | tr -d ' ')
  [ -z "$app" ] && continue
  echo "$current" | grep -q "\"$app\"" || echo "$app"
done | tr '\n' ',' | sed 's/,$//')

message=""

if [ -n "$removed_apps" ]; then
  message="[Zapless] App(s) disconnected: $removed_apps\nDo not use commands for disconnected apps."
fi

if [ -n "$new_apps" ]; then
  new_skill=$(timeout 5 zapless skill --plugin 2>/dev/null || echo "")
  if [ -n "$new_skill" ]; then
    message="${message:+$message\n\n}[Zapless] New app(s) connected: $new_apps\n\n$new_skill"
  else
    message="${message:+$message\n\n}[Zapless] New app(s) connected: $new_apps. Run \`zapless skill --plugin\` to get updated commands."
  fi
fi

if [ -n "$message" ]; then
  emit "$message"
fi
