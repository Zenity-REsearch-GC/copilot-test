#!/usr/bin/env bash
# ST-0 spike (IN-2278): liveness probe + selective DENY test.
# Logs every VS Code Copilot agent-hook lifecycle event to hook-probe.log,
# and BLOCKS any PreToolUse whose payload mentions the marker "zenity-blocked".
# Everything else is allowed, so normal agent operation continues and only the
# marked action is a clean block/allow signal. Answers: does deny actually
# PREVENT the action in the Agents window, or is it observe-only?

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_FILE="$REPO_ROOT/hook-probe.log"

PAYLOAD="$(cat)"
TS="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

# Decide: block only if the marker appears (e.g. a file named zenity-blocked.txt
# or a command mentioning zenity-blocked), and only on PreToolUse.
DECISION="allow"
if printf '%s' "$PAYLOAD" | grep -qi "zenity-blocked" \
   && printf '%s' "$PAYLOAD" | grep -q '"hook_event_name":"PreToolUse"'; then
  DECISION="deny"
fi

{
  echo "=== $TS  DECISION=$DECISION ==="
  echo "$PAYLOAD"
  echo
} >> "$LOG_FILE"

if [ "$DECISION" = "deny" ]; then
  # Hedge every documented block shape: flat + nested permissionDecision,
  # a reason on stderr, and exit code 2 (the exit-2-blocks contract).
  cat <<'EOF'
{
  "permissionDecision": "deny",
  "permissionDecisionReason": "Blocked by Zenity policy (deny test)",
  "hookSpecificOutput": {
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked by Zenity policy (deny test)"
  },
  "continue": false,
  "stopReason": "Blocked by Zenity policy (deny test)"
}
EOF
  echo "Blocked by Zenity policy (deny test)" 1>&2
  exit 2
fi

cat <<'EOF'
{
  "permissionDecision": "allow",
  "hookSpecificOutput": { "permissionDecision": "allow" }
}
EOF
exit 0
