#!/bin/bash
# audit.sh -- read-only health check of the framework in a project.
#
# Usage: audit.sh [--json] [--no-deep] <project-dir>
#
#   PASS   check is fine
#   WARN   worth a look; the framework still works
#   FAIL   the framework is broken or unsafe until fixed
#   INFO   context
#
# Never modifies the project. The functional ("deep") check copies the
# project's own hook scripts into a temporary directory and exercises them
# there. --no-deep skips it.
#
# Exit codes: 0 no FAIL, 1 usage/environment error, 2 at least one FAIL.

set -u

JSON=0
DEEP=1
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --json) JSON=1 ;;
    --no-deep) DEEP=0 ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    -*) echo "audit.sh: unknown option: $arg" >&2; exit 1 ;;
    *) if [ -n "$TARGET" ]; then echo "audit.sh: only one project directory allowed" >&2; exit 1; fi
       TARGET="$arg" ;;
  esac
done
if [ -z "$TARGET" ]; then echo "usage: audit.sh [--json] [--no-deep] <project-dir>" >&2; exit 1; fi
if [ ! -d "$TARGET" ]; then echo "audit.sh: not a directory: $TARGET" >&2; exit 1; fi

# Plugin / repo root = three levels above this script (skills/audit/scripts).
SRC="$(cd "$(dirname "$0")/../../.." && pwd)"
TARGET="$(cd "$TARGET" && pwd)"
source "$SRC/skills/init/scripts/lib.sh"

if [ ! -d "$TARGET/llm/framework" ] && [ ! -d "$TARGET/.claude/hooks" ] && ! grep -qF '@llm/framework' "$TARGET/CLAUDE.md" 2>/dev/null; then
  echo "audit.sh: the framework does not appear to be installed in $TARGET. Use the init or adopt skill first." >&2
  exit 1
fi

RES="$(mktemp)"
DEEPDIR=""
cleanup() { rm -f "$RES"; [ -n "$DEEPDIR" ] && rm -rf "$DEEPDIR"; }
trap cleanup EXIT

add()  { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$RES"; }
pass() { add PASS "$1" "$2"; }
warn() { add WARN "$1" "$2"; }
fail() { add FAIL "$1" "$2"; }
info() { add INFO "$1" "$2"; }

HAVE_JQ=0; command -v jq >/dev/null 2>&1 && HAVE_JQ=1
IS_GIT=0; git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1 && IS_GIT=1
T() { printf '%s/%s' "$TARGET" "$1"; }
# True if the file contains carriage returns. Byte-exact on purpose: grep on
# Windows Git Bash strips CRs before matching, so grep cannot be trusted here.
has_cr() { ! tr -d '\r' < "$1" 2>/dev/null | cmp -s - "$1"; }

# ---------------------------------------------------------------- tooling
if [ "$HAVE_JQ" = 1 ]; then pass tooling "jq found"
else fail tooling "jq is not installed; the hooks cannot run (Windows: winget install jqlang.jq, macOS: brew install jq, Debian/Ubuntu: apt install jq)"; fi
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then pass tooling "sha256 tool found"
else fail tooling "neither sha256sum nor shasum found; the Stop hook cannot compare PROJECT_STATE"; fi

# ---------------------------------------------------------------- records
MISSING=""; N=0
for f in "$SRC"/templates/llm/*; do
  N=$((N+1)); [ -f "$(T "llm/$(basename "$f")")" ] || MISSING="$MISSING llm/$(basename "$f")"
done
if [ -z "$MISSING" ]; then pass records "all $N llm/ records present"
else fail records "missing:$MISSING (the update skill recreates missing records)"; fi

# ---------------------------------------------------------------- framework dir
for f in RULES.md llm-records.md; do
  if [ -f "$(T "llm/framework/$f")" ]; then pass framework "llm/framework/$f present"
  else fail framework "llm/framework/$f missing (run the update skill)"; fi
done
INSTALLED_VERSION=""
if [ -f "$(T llm/framework/VERSION)" ]; then
  INSTALLED_VERSION="$(tr -d '[:space:]' < "$(T llm/framework/VERSION)")"
  pass framework "llm/framework/VERSION = $INSTALLED_VERSION"
else
  fail framework "llm/framework/VERSION missing (not installed by init/adopt?)"
fi
if [ -f "$(T "$MANIFEST_REL")" ]; then pass framework "install record (MANIFEST) present"
else warn framework "no llm/framework/MANIFEST: the update skill cannot tell edited files from old ones (run the update skill once to create it)"; fi

# ---------------------------------------------------------------- CLAUDE.md
CM="$(T CLAUDE.md)"
if [ ! -f "$CM" ]; then
  fail claude-md "CLAUDE.md missing"
else
  OKIMP=1
  for imp in '@llm/framework/RULES.md' '@llm/framework/llm-records.md'; do
    if tr -d '\r' < "$CM" | grep -qxF "$imp"; then   # tolerate a CRLF checkout
      [ -f "$(T "${imp#@}")" ] || { fail claude-md "imports $imp but that file does not exist"; OKIMP=0; }
    else
      fail claude-md "does not import $imp (the rules would not be loaded)"; OKIMP=0
    fi
  done
  [ "$OKIMP" = 1 ] && pass claude-md "imports the framework rules and they resolve"
  if has_markers; then
    pass claude-md "framework block has its markers"
  else
    warn claude-md "framework block has no markers, so the update skill cannot refresh it (run the update skill)"
  fi
  PH="$(grep -cE '\[\.\.\.\]|\[One paragraph|\[e\.g\.' "$CM")"
  if [ "$PH" -gt 0 ]; then warn claude-md "$PH unfilled [placeholder] line(s): project overview, commands and scope/stack are not set yet (scope/stack is yours to define)"
  else pass claude-md "no unfilled placeholders"; fi
  if ! grep -qiE '^#{1,3} .*(scope|stack)' "$CM"; then warn claude-md "no scope/stack section; the rules refer to one (the adopt skill can propose it)"; fi
fi

# ---------------------------------------------------------------- hooks
EXPECTED_HOOKS="$(managed_list | cut -d'|' -f1 | grep '^\.claude/hooks/')"
BADHOOK=0
while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  p="$(T "$rel")"
  if [ ! -f "$p" ]; then fail hooks "$rel missing (run the update skill)"; BADHOOK=1; continue; fi
  if has_cr "$p"; then
    # Git Bash tolerates CRLF, but Linux, WSL and dev containers do not.
    fail hooks "$rel has Windows (CRLF) line endings, which break bash under Linux, WSL and dev containers. Fix: sed -i 's/\\r\$//' $rel, and make sure .gitattributes pins it to LF (the update skill adds the rules)"
    BADHOOK=1; continue
  fi
  if ! bash -n "$p" 2>/dev/null; then fail hooks "$rel has a shell syntax error"; BADHOOK=1; fi
  if [ ! -x "$p" ]; then
    if [ "$IS_GIT" = 1 ] && git -C "$TARGET" ls-files -s -- "$rel" | grep -q '^100644'; then
      warn hooks "$rel is not executable (hooks run via bash so it works; chmod +x and commit the mode for other checkouts)"
    else warn hooks "$rel is not executable (hooks run via bash so it works; chmod +x recommended)"; fi
  fi
done <<< "$EXPECTED_HOOKS"
[ "$BADHOOK" = 0 ] && pass hooks "all $(printf '%s\n' "$EXPECTED_HOOKS" | grep -c .) hook scripts present and valid bash"

# ---------------------------------------------------------------- settings.json
SJ="$(T .claude/settings.json)"
if [ ! -f "$SJ" ]; then
  fail settings ".claude/settings.json missing: no hooks are registered (run the update skill)"
elif [ "$HAVE_JQ" = 0 ]; then
  info settings "skipped (needs jq)"
elif ! jq -e . "$SJ" >/dev/null 2>&1; then
  fail settings ".claude/settings.json is not valid JSON; Claude Code will ignore it"
else
  BADREG=0
  while IFS=$'\t' read -r ev cmd; do
    [ -z "$ev" ] && continue
    if ! jq -e --arg e "$ev" --arg c "$cmd" '(.hooks[$e] // []) | any(.[]; (.hooks // []) | any(.[]; .command == $c))' "$SJ" >/dev/null 2>&1; then
      fail settings "hook for $ev is not registered ($cmd); run the update skill"; BADREG=1
    fi
  # tr -d '\r': jq.exe on Windows ends lines with CRLF, and `read` would keep the CR
  done < <(jq -r '.hooks | to_entries[] | .key as $e | .value[] | .hooks[] | "\($e)\t\(.command)"' "$ADAPTER/.claude/settings.json" | tr -d '\r')
  [ "$BADREG" = 0 ] && pass settings "valid JSON; all framework hook events registered"
  STALE=0
  for ref in $(grep -o '\.claude/hooks/[A-Za-z0-9_.-]*\.sh' "$SJ" | sort -u); do
    [ -f "$(T "$ref")" ] || { fail settings "settings.json references $ref, which does not exist (the hook would error every time)"; STALE=1; }
  done
  [ "$STALE" = 0 ] && pass settings "every hook script it references exists"
fi

# ---------------------------------------------------------------- secrets / gitignore
ignored() { # relpath
  if [ "$IS_GIT" = 1 ]; then git -C "$TARGET" check-ignore -q -- "$1" 2>/dev/null
  else grep -qxF "$1" "$(T .gitignore)" 2>/dev/null; fi
}
if [ -f "$(T .claude/settings.local.json)" ]; then
  if ignored .claude/settings.local.json; then pass secrets ".claude/settings.local.json exists and is git-ignored"
  else fail secrets ".claude/settings.local.json exists but is NOT git-ignored; it may hold secrets (add it to .gitignore now)"; fi
else
  if ignored .claude/settings.local.json; then pass secrets ".claude/settings.local.json is git-ignored"
  else warn secrets ".claude/settings.local.json is not in .gitignore; add it before anyone stores a secret there"; fi
fi
if ignored .claude/hooks/.state/dirty || ignored .claude/hooks/.state/; then pass secrets "hook state dir is git-ignored"
else warn secrets ".claude/hooks/.state/ is not git-ignored; machine-local hook state could get committed"; fi
if [ "$IS_GIT" = 1 ] && git -C "$TARGET" ls-files -- .claude/hooks/.state | grep -q .; then
  fail secrets "hook state files are tracked in git (.claude/hooks/.state); untrack them"
fi

# ---------------------------------------------------------------- line endings
if [ "$IS_GIT" = 1 ]; then
  UNPINNED=""
  for f in .claude/hooks/lib.sh llm/framework/RULES.md; do
    git -C "$TARGET" check-attr eol -- "$f" 2>/dev/null | grep -q 'eol: lf' || UNPINNED="$UNPINNED $f"
  done
  if [ -z "$UNPINNED" ]; then pass line-endings "framework scripts and rules are pinned to LF by .gitattributes"
  else warn line-endings "not pinned to LF:$UNPINNED. With core.autocrlf=true on Windows they can be checked out as CRLF, which breaks the hook scripts under Linux, WSL and dev containers (the update skill adds the .gitattributes rules)"; fi
fi

# ---------------------------------------------------------------- version / integrity
PLUGIN_VERSION="$(jq -r '.version' "$SRC/.claude-plugin/plugin.json" 2>/dev/null)"
if [ -n "$INSTALLED_VERSION" ] && [ -n "$PLUGIN_VERSION" ] && [ "$PLUGIN_VERSION" != null ]; then
  if [ "$INSTALLED_VERSION" = "$PLUGIN_VERSION" ]; then pass version "framework $INSTALLED_VERSION matches the plugin"
  else
    lowest="$(printf '%s\n%s\n' "$INSTALLED_VERSION" "$PLUGIN_VERSION" | sort -V | head -1)"
    if [ "$lowest" = "$INSTALLED_VERSION" ]; then warn version "framework $INSTALLED_VERSION is behind the plugin ($PLUGIN_VERSION); run the update skill"
    else warn version "framework $INSTALLED_VERSION is newer than this plugin ($PLUGIN_VERSION); update the plugin"; fi
  fi
fi
if [ -f "$(T "$MANIFEST_REL")" ]; then
  EDITED=""
  while IFS='|' read -r rel src exe; do
    base="$(manifest_get "$rel")"; [ -z "$base" ] && continue
    [ -f "$(T "$rel")" ] || continue
    if [ "$(sha256_file "$(T "$rel")")" != "$base" ]; then
      if has_cr "$(T "$rel")"; then EDITED="$EDITED $rel(CRLF)"; else EDITED="$EDITED $rel"; fi
    fi
  done < <(managed_list)
  if [ -n "$EDITED" ]; then warn integrity "framework file(s) edited since install:$EDITED (the update skill will report them as conflicts; (CRLF) means the file has Windows line endings, which is the likely cause)"
  else pass integrity "framework files match the install record"; fi
  if [ -f "$CM" ] && has_markers; then
    base="$(manifest_get "CLAUDE.md#block")"
    if [ -n "$base" ] && [ "$(printf '%s\n' "$(target_block)" | sha256_text)" != "$base" ]; then
      warn integrity "the CLAUDE.md framework block was edited since install"
    fi
  fi
fi

# ---------------------------------------------------------------- record health
PS="$(T llm/PROJECT_STATE.md)"
if [ -f "$PS" ]; then
  if head -3 "$PS" | grep -q '^Last updated:'; then
    if head -3 "$PS" | grep -q 'auto-stamped'; then warn health "PROJECT_STATE.md has never been stamped (the Stop hook has not completed a pass yet)"
    else pass health "PROJECT_STATE.md has a Last updated stamp in its first three lines"; fi
  else
    warn health "PROJECT_STATE.md has no 'Last updated:' line in its first three lines, so the Stop hook cannot stamp it"
  fi
  if [ -f "$SRC/templates/llm/PROJECT_STATE.md" ] && cmp -s "$PS" "$SRC/templates/llm/PROJECT_STATE.md"; then
    warn health "PROJECT_STATE.md is still the blank template"
  fi
fi
DRAFTS="$(grep -l 'DRAFT, unconfirmed' "$TARGET"/llm/*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | tr '\n' ' ')"
if [ -n "$DRAFTS" ]; then warn health "unconfirmed draft(s) still marked: $DRAFTS(review, then delete the DRAFT line)"
else pass health "no unconfirmed DRAFT markers"; fi

if [ -f "$(T llm/CHANGELOG.md)" ]; then
  DATES="$(grep -oE '^## \[[0-9]{4}-[0-9]{2}-[0-9]{2}( [0-9]{2}:[0-9]{2})?\]' "$(T llm/CHANGELOG.md)" | tr -d '#[] ')"
  if [ "$(printf '%s\n' "$DATES" | sort -r)" = "$DATES" ]; then pass health "CHANGELOG entries are newest-first"
  else warn health "CHANGELOG.md entries are not newest-first (new entries go at the top)"; fi
fi
if [ "$HAVE_JQ" = 1 ]; then
  for jf in CHANGES.jsonl SESSIONS.jsonl; do
    p="$(T "llm/$jf")"; [ -f "$p" ] || continue
    BAD="$(jq -Rn '[inputs | select(length>0) | (fromjson? // "BAD")] | map(select(. == "BAD")) | length' "$p" 2>/dev/null)"
    if [ "${BAD:-0}" -gt 0 ]; then fail health "llm/$jf has $BAD line(s) that are not valid JSON"; else pass health "llm/$jf lines are valid JSON"; fi
  done
  if [ -f "$(T llm/CHANGES.jsonl)" ]; then
    NOKEYS="$(jq -Rn '[inputs | select(length>0) | fromjson? | select(type=="object") | select((has("date") and has("session") and has("file") and has("type") and has("summary")) | not)] | length' "$(T llm/CHANGES.jsonl)" 2>/dev/null)"
    [ "${NOKEYS:-0}" -gt 0 ] && warn health "llm/CHANGES.jsonl: $NOKEYS line(s) missing a required key (date, session, file, type, summary)"
    BADTYPE="$(jq -Rn '[inputs | select(length>0) | fromjson? | select(type=="object" and has("type")) | select(.type | IN("logic-change","bugfix","refactor","config","docs","test") | not)] | length' "$(T llm/CHANGES.jsonl)" 2>/dev/null)"
    [ "${BADTYPE:-0}" -gt 0 ] && warn health "llm/CHANGES.jsonl: $BADTYPE line(s) with a type outside logic-change/bugfix/refactor/config/docs/test"
  fi
fi
if [ -f "$(T llm/KNOWN_ISSUES.md)" ]; then
  BADST="$(grep -E '^Status:' "$(T llm/KNOWN_ISSUES.md)" | grep -cvE '^Status: (open|in-progress|resolved|accepted)$')"
  if [ "$BADST" -gt 0 ]; then warn health "KNOWN_ISSUES.md: $BADST Status line(s) outside open/in-progress/resolved/accepted"; fi
fi

# ---------------------------------------------------------------- git
if [ "$IS_GIT" = 1 ]; then
  for f in CHANGELOG.md DECISIONS.md CHANGES.jsonl; do
    [ -f "$(T "llm/$f")" ] || continue
    DEL="$(git -C "$TARGET" log --numstat --format= -- "llm/$f" 2>/dev/null | awk '$2 ~ /^[0-9]+$/ {d += $2} END {print d + 0}')"
    if [ "$DEL" -gt 0 ]; then warn git "llm/$f had $DEL line(s) deleted or rewritten in history (it should be add-only)"; fi
  done
  pass git "project is a git repository"
else
  warn git "not a git repository: changes are not reviewable or revertible, and add-only history cannot be checked"
fi

# ---------------------------------------------------------------- deep: do the hooks actually work here?
if [ "$DEEP" = 1 ]; then
  if [ "$HAVE_JQ" = 0 ] || [ "$BADHOOK" = 1 ]; then
    info deep "functional hook check skipped (needs jq and all hook scripts present and valid)"
  else
    DEEPDIR="$(mktemp -d)"
    mkdir -p "$DEEPDIR/.claude" "$DEEPDIR/llm"
    cp -r "$(T .claude/hooks)" "$DEEPDIR/.claude/hooks"
    rm -rf "$DEEPDIR/.claude/hooks/.state"
    if [ -f "$PS" ]; then cp "$PS" "$DEEPDIR/llm/PROJECT_STATE.md"; else printf '# Project State\nLast updated: x\n' > "$DEEPDIR/llm/PROJECT_STATE.md"; fi
    H="$DEEPDIR/.claude/hooks"
    export CLAUDE_PROJECT_DIR="$DEEPDIR"
    ok=1
    sctx="$(echo '{"session_id":"audit-probe"}' | bash "$H/session_start.sh" 2>/dev/null)"; rc=$?
    if [ "$rc" = 0 ] && printf '%s' "$sctx" | jq -e '.hookSpecificOutput.additionalContext | test("audit-probe")' >/dev/null 2>&1; then
      pass deep "SessionStart injects the session ID"
    else fail deep "SessionStart hook did not produce session context (exit $rc)"; ok=0; fi
    [ -f "$DEEPDIR/.claude/hooks/.state/last_verified_hash" ] || { fail deep "SessionStart did not record the PROJECT_STATE baseline"; ok=0; }
    echo "{\"tool_input\":{\"file_path\":\"$DEEPDIR/llm/TODO.md\"}}" | bash "$H/mark_dirty.sh" >/dev/null 2>&1
    if [ -f "$DEEPDIR/.claude/hooks/.state/dirty" ]; then fail deep "editing a file under llm/ wrongly marked the project dirty"; ok=0; fi
    echo "{\"tool_input\":{\"file_path\":\"$DEEPDIR/src/app.js\"}}" | bash "$H/mark_dirty.sh" >/dev/null 2>&1
    if [ -f "$DEEPDIR/.claude/hooks/.state/dirty" ]; then pass deep "editing a project file marks the turn dirty"
    else fail deep "editing a project file did not mark the turn dirty"; ok=0; fi
    echo '{"session_id":"audit-probe"}' | bash "$H/check_project_state.sh" >/dev/null 2>&1; rc=$?
    if [ "$rc" = 2 ]; then pass deep "Stop blocks when project files changed but PROJECT_STATE did not"
    else fail deep "Stop did not block an unrecorded change (exit $rc, expected 2)"; ok=0; fi
    echo "- audit probe" >> "$DEEPDIR/llm/PROJECT_STATE.md"
    echo '{"session_id":"audit-probe"}' | bash "$H/check_project_state.sh" >/dev/null 2>&1; rc=$?
    if [ "$rc" = 0 ] && [ ! -f "$DEEPDIR/.claude/hooks/.state/dirty" ]; then pass deep "Stop passes once PROJECT_STATE changes, and clears the flag"
    else fail deep "Stop did not release after PROJECT_STATE changed (exit $rc)"; ok=0; fi
    echo '{"session_id":"audit-probe"}' | bash "$H/check_project_state.sh" >/dev/null 2>&1; rc=$?
    if [ "$rc" = 0 ]; then pass deep "a question-only turn is not blocked"
    else fail deep "a question-only turn was blocked (exit $rc)"; ok=0; fi
    unset CLAUDE_PROJECT_DIR
  fi
fi

# ---------------------------------------------------------------- report
NPASS="$(grep -c '^PASS' "$RES")"; NWARN="$(grep -c '^WARN' "$RES")"; NFAIL="$(grep -c '^FAIL' "$RES")"
if [ "$JSON" = 1 ]; then
  jq -Rn --argjson p "$NPASS" --argjson w "$NWARN" --argjson f "$NFAIL" \
    '{summary: {pass: $p, warn: $w, fail: $f}, results: [inputs | split("\t") | {level: .[0], area: .[1], message: .[2]}]}' "$RES" 2>/dev/null \
    || echo '{"error":"jq is required for --json"}'
else
  echo "Audit of $TARGET"
  echo
  # failures first, then warnings, then the rest
  for lvl in FAIL WARN INFO PASS; do
    awk -F'\t' -v l="$lvl" '$1 == l { printf "%-5s %-10s %s\n", $1, $2, $3 }' "$RES"
  done
  echo
  echo "Summary: pass=$NPASS warn=$NWARN fail=$NFAIL"
fi
[ "$NFAIL" -gt 0 ] && exit 2
exit 0
