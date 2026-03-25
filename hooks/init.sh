#!/usr/bin/env bash

set -euo pipefail

DASHBOARD_URL="https://zapless.app/dashboard"
INSTALL_URL="https://api.t31k.cloud/api/zapless/install.sh"
APPS_FILE="$HOME/.zapless/apps.json"

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
    printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$content"
  fi
}

# 1. Check CLI installed
if ! command -v zapless > /dev/null 2>&1; then
  emit "[Zapless] CLI not installed.\n\nRun this to install:\n\`\`\`bash\ncurl -fsSL $INSTALL_URL | sh\n\`\`\`\nThen authenticate:\n\`\`\`bash\nzapless auth login --token <your-token>\n\`\`\`\nGet your token at: $DASHBOARD_URL"
  exit 0
fi

# 2. Check authenticated
if ! zapless auth status > /dev/null 2>&1; then
  emit "[Zapless] Not authenticated.\n\nVisit https://zapless.app/connect — it will give you the exact command to run in your terminal."
  exit 0
fi

# 3. Fetch connected apps, save for pulse.sh to diff against
if ! apps=$(zapless apps list --json 2>/dev/null); then
  emit "[Zapless] Could not fetch connected apps. Server may be unreachable. Commands are still available — run \`zapless doctor\` to diagnose."
  exit 0
fi
echo "$apps" > "$APPS_FILE"

# 4. Fetch dynamic skill (no Setup section)
skill_content=""
if skill_content=$(timeout 5 zapless skill --plugin 2>/dev/null); then
  emit "$skill_content"
else
  emit "[Zapless] Connected. Could not fetch full skill instructions (server timeout). Run \`zapless doctor\` to diagnose."
fi
