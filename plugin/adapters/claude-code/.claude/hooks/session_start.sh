#!/bin/bash
# SessionStart hook: injects the session ID and current datetime into Claude's
# context. Claude can't see either on its own, and CLAUDE.md asks it to record
# both in CHANGELOG / CHANGES / DECISIONS entries -- without this it would
# guess. Fires on startup, resume, clear, and compact.

source "$(dirname "$0")/lib.sh"
require_jq "session_start.sh"

# First session in this project: record the current PROJECT_STATE.md as the
# baseline, so the Stop hook blocks if it is left unchanged after real work
# (otherwise a blank template would pass on its first check).
if [ ! -f "$HASH_FILE" ] && [ -f "$STATE_FILE" ]; then
  mkdir -p "$STATE_DIR"
  state_hash > "$HASH_FILE" 2>/dev/null
fi

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
NOW=$(date "+%Y-%m-%d %H:%M")

MSG="Session ID: ${SESSION_ID}. Session started: ${NOW}. Use this session ID in llm/ entries. For entry timestamps, run date \"+%Y-%m-%d %H:%M\" rather than estimating."

jq -n --arg msg "$MSG" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $msg}}'

exit 0
