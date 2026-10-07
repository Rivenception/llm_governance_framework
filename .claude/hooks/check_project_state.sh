#!/bin/bash
# Stop hook: fires at the end of every response turn (not just session end).
# If this session modified project files (marked by mark_dirty.sh), blocks
# until llm/PROJECT_STATE.md's BODY content has actually changed since the
# last verified hash. Turns with no project edits (Q&A, llm/-only) pass.
# Content hash, not mtime: the auto-stamp below refreshes mtime, so an mtime
# check would pass forever after the first edit.
#
# Exit 2 = block, feed stderr back to Claude as the reason to keep working.
# Exit 1 = non-blocking error, shown to the user (used for missing tooling).
# Exit 0 = allow.

source "$(dirname "$0")/lib.sh"
require_jq "check_project_state.sh"
sha256 </dev/null >/dev/null || { echo "check_project_state.sh: PROJECT_STATE enforcement is NOT running." >&2; exit 1; }

INPUT=$(cat)

# True when this hook already blocked once on this turn (the retry). The
# retry is still verified below: if Claude complied, we record it and clear
# the marker. If it did not, we don't block a second time (avoids an
# infinite loop) and leave the marker, so the next turn blocks again.
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Nothing changed outside llm/ and .claude/ -> nothing to record.
if [ ! -f "$DIRTY_FILE" ]; then
  exit 0
fi

if [ ! -f "$STATE_FILE" ]; then
  [ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0
  echo "Project files were modified, but llm/PROJECT_STATE.md does not exist. Create it before ending the turn." >&2
  exit 2
fi

CURRENT_HASH=$(state_hash)
LAST_HASH=$(cat "$HASH_FILE" 2>/dev/null || echo "")

if [ "$CURRENT_HASH" = "$LAST_HASH" ]; then
  [ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0
  echo "Project files were modified this session, but llm/PROJECT_STATE.md's content hasn't changed since the last check. Update the status, what-just-happened, next-task, and risks sections with real content before ending." >&2
  exit 2
fi

# Real change confirmed. Record the new hash and clear the dirty marker, then
# auto-stamp the header with the session ID and timestamp (the stamp line is
# excluded from the hash, so stamping never counts as a change).
mkdir -p "$STATE_DIR"
echo "$CURRENT_HASH" > "$HASH_FILE"
rm -f "$DIRTY_FILE"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
NOW=$(date "+%Y-%m-%d %H:%M")
sed -i.bak "1,3 s/^Last updated:.*/Last updated: ${NOW} | Session: ${SESSION_ID}/" "$STATE_FILE" 2>/dev/null
rm -f "${STATE_FILE}.bak"

exit 0
