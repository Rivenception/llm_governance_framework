#!/bin/bash
# SessionEnd hook: fires on real session termination (/exit, /clear, logout,
# or other exit). Cannot block anything -- SessionEnd is advisory-only in
# Claude Code, so this just logs the boundary rather than enforcing it.
# Reliability note: some Claude Code versions have had SessionEnd not fire
# on every exit path (e.g. /clear). Treat this log as best-effort, not
# a guaranteed complete record -- Stop-hook enforcement on PROJECT_STATE.md
# is still the actual safety net.

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"')
NOW=$(date "+%Y-%m-%dT%H:%M:%S")

LOG_FILE="llm/SESSIONS.jsonl"
mkdir -p llm
echo "{\"date\":\"${NOW}\",\"session\":\"${SESSION_ID}\",\"reason\":\"${REASON}\"}" >> "$LOG_FILE"

exit 0
