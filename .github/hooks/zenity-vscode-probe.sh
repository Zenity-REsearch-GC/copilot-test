#!/usr/bin/env bash
# ST-0 spike (IN-2278): liveness-probe-first hook. Logs every VS Code Copilot
# agent-hook lifecycle event that actually fires, with its raw payload, to
# hook-probe.log — mirrors docs/evidence/hook-blind-test/*/hook-probe.log
# (the Codex hook-blind spike) so the two data sets stay comparable.
#
# Always allows. This phase answers BU-2 (which tool classes reach
# PreToolUse) and captures the real VS Code payload shape for ST-5 — it does
# not enforce anything yet (that's ST-3/ST-4).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_FILE="$REPO_ROOT/hook-probe.log"

PAYLOAD="$(cat)"
TS="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

{
  echo "=== $TS ==="
  echo "$PAYLOAD"
  echo
} >> "$LOG_FILE"

# Hedge on output schema until BU-1/BU-2 confirm which one VS Code honors:
# VS Code Agent Hooks docs -> nested hookSpecificOutput.permissionDecision;
# GitHub Copilot hooks reference -> flat permissionDecision. Emitting both
# costs nothing here and unblocks the retest regardless of which is real.
cat <<'EOF'
{
  "permissionDecision": "allow",
  "hookSpecificOutput": {
    "permissionDecision": "allow"
  }
}
EOF
exit 0
