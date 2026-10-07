#!/bin/bash
# Shared helpers, sourced by the other hooks. Not registered as a hook itself.

ROOT="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE="$ROOT/llm/PROJECT_STATE.md"
# Machine-local hook state (gitignored): last verified hash + dirty marker.
STATE_DIR="$ROOT/.claude/hooks/.state"
HASH_FILE="$STATE_DIR/last_verified_hash"
DIRTY_FILE="$STATE_DIR/dirty"

# Fail visibly (exit 1 = non-blocking error shown to the user) rather than
# silently skipping enforcement.
require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "$1: jq is not installed, so this hook is NOT running. Install jq (see setup guide)." >&2
    exit 1
  fi
}

# Portable sha256 of stdin: sha256sum (Linux, Git Bash) or shasum (macOS).
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    echo "no sha256 tool (sha256sum/shasum) found" >&2
    return 1
  fi
}

# Hash of PROJECT_STATE.md excluding the auto-stamped "Last updated:" line,
# so re-stamping never counts as a real change. Matched by pattern, not line
# number: the stamp sits on line 2, under the title.
state_hash() {
  grep -v '^Last updated:' "$STATE_FILE" | sha256
}

# Normalize a path for comparison: forward slashes, C:/x -> /c/x, lowercase.
norm_path() {
  echo "$1" | tr '\\' '/' | sed -E 's|^([A-Za-z]):|/\1|' | tr 'A-Z' 'a-z'
}
