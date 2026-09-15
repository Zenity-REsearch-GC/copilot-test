# copilot-test — IN-2278 ST-0 spike: VS Code Copilot Agent Hooks retest

Retest of BU-2 (do file-edit / terminal / MCP tool calls route through `PreToolUse`
in VS Code Copilot Chat?) and, if it fires, a first read on BU-3 (latency). The
2026-07-06 test in this same repo found **0/5 hook events fired in VS Code**
(CLI-only) — but that predates VS Code's "Agent Hooks (Preview)" feature, so this
retest checks whether that's changed.

## Setup (one-time)

1. Open this repo in VS Code (current version — hooks are Preview, behavior may
   differ by build).
2. Make sure you're signed in to GitHub in VS Code under an account with a
   Copilot Business seat in `Zenity-REsearch-GC`.
3. `chmod +x .github/hooks/zenity-vscode-probe.sh` if it isn't already executable.
4. Reload the VS Code window (`Developer: Reload Window`) so the hook config
   and MCP server are picked up.
5. Open Copilot Chat in **agent mode** (not ask/edit mode — hooks are an
   agent-mode concept).

## Test scenarios (run each, then check `hook-probe.log`)

1. **File edit** — prompt: `create a file called probe-edit.txt with the text "hook test"`
2. **Terminal command** — prompt: `run ls -la in the terminal`
3. **MCP tool call** — prompt: `use the filesystem MCP tool to list the contents of this directory`
   (needs `npx` on PATH; the `zenity-probe-fs` server is wired in `.vscode/mcp.json`)

## Reading results

`hook-probe.log` (gitignored, local only) gets one block per fired event:
`=== <ISO8601 timestamp> ===` followed by the raw JSON payload.

- **If the file never appears / stays empty after all 3 scenarios**: hooks still
  don't fire in VS code on this build — BU-2 stays unresolved, matches the July
  finding, note the VS Code/Copilot extension version tested.
- **If it has entries but no `PreToolUse` for one of the 3 scenarios**: that tool
  class is hook-blind in VS Code — same failure mode the Codex spike found for
  `tool_search` (`docs/evidence/hook-blind-test/FINDINGS.md`). Note which class.
- **If `PreToolUse` fires for all 3**: BU-2 resolved positive. Capture the exact
  payload shape (confirm `tool_name`/`tool_input` snake_case vs the CLI's
  `toolName`/`toolArgs`) and roughly time the gap between the hook firing and
  the tool actually executing, as a first BU-3 signal (not a real round-trip
  measurement yet — that needs ST-3's actual ai-edge POST).

Report back: VS Code version, Copilot extension version, and the contents of
`hook-probe.log` after all 3 scenarios.
