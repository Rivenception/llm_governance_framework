#!/bin/bash
# Stop hook: fires at the end of every response turn (not just session end).
# Blocks if llm/PROJECT_STATE.md's BODY content hasn't actually changed
# since the last time this check passed. Uses a content hash rather than
# file mtime, because mtime gets refreshed by this hook's own auto-stamp
# step below -- an mtime check would pass forever after the first real edit.
#
# Exit 2 = block, feed stderr back to Claude as the reason to keep working.
# Exit 0 = allow.

INPUT=$(cat)

# Avoid infinite loop: if this hook already fired once and blocked on this
# turn, don't block again on the retry.
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

STATE_FILE="llm/PROJECT_STATE.md"
HASH_FILE=".claude/hooks/.last_verified_hash"

if [ ! -f "$STATE_FILE" ]; then
  echo "llm/PROJECT_STATE.md does not exist. Create it before ending the session." >&2
  exit 2
fi

# Hash everything EXCEPT line 1 (the auto-stamped "Last updated: ... |
# Session: ..." header), so re-stamping the header never counts as a
# "real" change on its own.
CURRENT_HASH=$(tail -n +2 "$STATE_FILE" | shasum -a 256 | awk '{print $1}')
LAST_HASH=$(cat "$HASH_FILE" 2>/dev/null || echo "")

if [ "$CURRENT_HASH" = "$LAST_HASH" ]; then
  echo "llm/PROJECT_STATE.md's content hasn't changed since the last check. Update the status, what-just-happened, next-task, and risks sections with real content before ending." >&2
  exit 2
fi

# Real change confirmed. Record the new hash, then auto-stamp the header
# with the session ID and timestamp (this stamp itself doesn't affect the
# hash next time, since we hash from line 2 onward).
echo "$CURRENT_HASH" > "$HASH_FILE"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
NOW=$(date "+%Y-%m-%d %H:%M")
sed -i.bak "1,3 s/^Last updated:.*/Last updated: ${NOW} | Session: ${SESSION_ID}/" "$STATE_FILE" 2>/dev/null
rm -f "${STATE_FILE}.bak"

exit 0
