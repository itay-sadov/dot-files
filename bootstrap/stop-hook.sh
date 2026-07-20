#!/usr/bin/env bash
# Claude Code Stop hook. Runs the drift checker when a session finishes and, if it
# finds drift, blocks the stop and feeds the report back to the agent so it fixes
# the docs/scripts before ending. Wired in .claude/settings.json.
#
# Reads the hook payload on stdin. Honors `stop_hook_active` to avoid loops.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
payload="$(cat)"

# If we already blocked once this stop, don't block again — let the session end.
case "$payload" in *'"stop_hook_active":true'*) exit 0;; esac

# Only police sessions that actually wrote to this repo. A session that just
# answered a question (or only read files) must not be hijacked into fixing
# pre-existing drift it didn't cause — the checker is still runnable by hand and
# the pre-commit hook remains the hard gate.
transcript="$(printf '%s' "$payload" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
if [ -n "$transcript" ] && [ -r "$transcript" ]; then
    if command -v jq >/dev/null 2>&1; then
        wrote="$(jq -r '
            .. | objects
            | select(.type? == "tool_use")
            | select(.name == "Write" or .name == "Edit" or .name == "NotebookEdit")
            | .input.file_path // empty
        ' "$transcript" 2>/dev/null | grep -c "^$REPO_DIR/")"
    else
        wrote="$(grep -c '"name":"\(Write\|Edit\|NotebookEdit\)"' "$transcript" 2>/dev/null)"
    fi
    [ "${wrote:-0}" -gt 0 ] || exit 0
fi

report="$("$REPO_DIR/bootstrap/check-drift.sh" 2>&1)"
status=$?
[ "$status" -eq 0 ] && exit 0   # clean (or warnings only) — allow stop.

# Drift found: emit a block decision with the report as the reason (JSON-escaped).
reason="$(printf '%s' "Repo maintenance contract: drift detected, fix before finishing.
$report" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')"
printf '{"decision":"block","reason":"%s"}\n' "$reason"
exit 0
