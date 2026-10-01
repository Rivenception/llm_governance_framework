#!/bin/bash
# SessionStart hook: injects the session ID and current datetime into Claude's
# context. Claude can't see either on its own, and CLAUDE.md asks it to record
# both in CHANGELOG / CHANGES / DECISIONS entries -- without this it would
# guess. Fires on startup, resume, clear, and compact.

if ! command -v jq >/dev/null 2>&1; then
  echo "session_start.sh: jq is not installed; session ID and datetime cannot be injected. Install jq (see setup guide)." >&2
  exit 1
fi

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
NOW=$(date "+%Y-%m-%d %H:%M")

MSG="Session ID: ${SESSION_ID}. Session started: ${NOW}. Use this session ID in llm/ entries. For entry timestamps, run date \"+%Y-%m-%d %H:%M\" rather than estimating."

jq -n --arg msg "$MSG" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $msg}}'

exit 0
