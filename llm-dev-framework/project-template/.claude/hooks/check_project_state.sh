#!/bin/bash
# Stop hook: fires at the end of every response turn (not just session end).
# Blocks if llm/PROJECT_STATE.md's BODY content hasn't actually changed
# since the last time this check passed. Uses a content hash rather than
# file mtime, because mtime gets refreshed by this hook's own auto-stamp
# step below -- an mtime check would pass forever after the first real edit.
#
# Exit 2 = block, feed stderr back to Claude as the reason to keep working.
# Exit 1 = non-blocking error, shown to the user (used for missing tooling).
# Exit 0 = allow.

# jq is required to read the hook input. Fail visibly rather than silently
# losing the loop guard below.
if ! command -v jq >/dev/null 2>&1; then
  echo "check_project_state.sh: jq is not installed, so PROJECT_STATE enforcement is NOT running. Install jq (see setup guide)." >&2
  exit 1
fi

# Portable sha256: sha256sum (Linux, Git Bash) or shasum (macOS).
if command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 | awk '{print $1}'; }
else
  echo "check_project_state.sh: neither sha256sum nor shasum found, so PROJECT_STATE enforcement is NOT running." >&2
  exit 1
fi

INPUT=$(cat)

# Avoid infinite loop: if this hook already fired once and blocked on this
# turn, don't block again on the retry.
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Resolve paths from the project root so this works regardless of cwd.
ROOT="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE="$ROOT/llm/PROJECT_STATE.md"
HASH_FILE="$ROOT/.claude/hooks/.last_verified_hash"

if [ ! -f "$STATE_FILE" ]; then
  echo "llm/PROJECT_STATE.md does not exist. Create it before ending the session." >&2
  exit 2
fi

# Hash everything EXCEPT the auto-stamped "Last updated: ... | Session: ..."
# line, so re-stamping never counts as a "real" change on its own. Match by
# pattern, not line number: the stamp sits on line 2, under the title.
CURRENT_HASH=$(grep -v '^Last updated:' "$STATE_FILE" | sha256)
LAST_HASH=$(cat "$HASH_FILE" 2>/dev/null || echo "")

if [ "$CURRENT_HASH" = "$LAST_HASH" ]; then
  echo "llm/PROJECT_STATE.md's content hasn't changed since the last check. Update the status, what-just-happened, next-task, and risks sections with real content before ending." >&2
  exit 2
fi

# Real change confirmed. Record the new hash, then auto-stamp the header
# with the session ID and timestamp (this stamp itself doesn't affect the
# hash next time, since the stamp line is excluded from it).
echo "$CURRENT_HASH" > "$HASH_FILE"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
NOW=$(date "+%Y-%m-%d %H:%M")
sed -i.bak "1,3 s/^Last updated:.*/Last updated: ${NOW} | Session: ${SESSION_ID}/" "$STATE_FILE" 2>/dev/null
rm -f "${STATE_FILE}.bak"

exit 0
