#!/bin/bash
# PostToolUse hook (Edit|Write|MultiEdit|NotebookEdit): marks the project
# "dirty" when a file OUTSIDE llm/ and .claude/ was modified. The Stop hook
# only enforces PROJECT_STATE.md updates on dirty turns, so pure Q&A turns
# and llm/-only turns don't force a filler edit.
#
# Known gap: file changes made through the Bash tool (sed -i, scripts, git
# operations) are not detected here. Those turns won't be marked dirty.

source "$(dirname "$0")/lib.sh"
require_jq "mark_dirty.sh"

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -z "$FILE" ] && exit 0

REL=$(norm_path "$FILE")
BASE=$(norm_path "$(cd "$ROOT" 2>/dev/null && pwd)")/
case "$REL" in
  "$BASE"llm/*|"$BASE".claude/*) exit 0 ;;   # record-keeping, not project work
  "$BASE"*) ;;                                 # inside the project: counts
  *) exit 0 ;;                                 # outside the project: ignore
esac

mkdir -p "$STATE_DIR"
touch "$DIRTY_FILE"
exit 0
