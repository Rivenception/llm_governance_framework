#!/bin/bash
# update.sh -- bring a project's framework files up to the plugin's version.
#
# Usage: update.sh [--dry-run] [--accept-new <path>]... <project-dir>
#
# Only framework-owned files are touched: llm/framework/*, .claude/hooks/*,
# the framework block in CLAUDE.md (between its markers), hook entries in
# .claude/settings.json, missing .gitignore lines, and the optional
# .devcontainer/devcontainer.json. Project records (llm/*.md) are never
# modified; records that are new in this version are created if missing.
#
# A framework file is updated only if it still matches the hash recorded in
# llm/framework/MANIFEST at install/update time (i.e. nobody edited it).
# Anything edited, or with an unknown baseline, is a CONFLICT and is left
# untouched. --accept-new <path> overwrites a conflicting file with the
# plugin's version after the user has decided that (use CLAUDE.md for the
# framework block).
#
#   CREATE UPDATE REMOVE MERGE OK CONFLICT WARN
# Exit codes: 0 done, 1 error, 2 done but conflicts remain.

set -u

DRY=0
TARGET=""
ACCEPT=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --accept-new) shift; [ $# -gt 0 ] || { echo "update.sh: --accept-new needs a path" >&2; exit 1; }; ACCEPT+=("$1") ;;
    -h|--help) sed -n '2,21p' "$0"; exit 0 ;;
    -*) echo "update.sh: unknown option: $1" >&2; exit 1 ;;
    *) if [ -n "$TARGET" ]; then echo "update.sh: only one project directory allowed" >&2; exit 1; fi
       TARGET="$1" ;;
  esac
  shift
done

if [ -z "$TARGET" ]; then
  echo "usage: update.sh [--dry-run] [--accept-new <path>]... <project-dir>" >&2
  exit 1
fi
if [ ! -d "$TARGET" ]; then
  echo "update.sh: not a directory: $TARGET" >&2
  exit 1
fi

# Plugin / repo root = three levels above this script (skills/update/scripts).
SRC="$(cd "$(dirname "$0")/../../.." && pwd)"
TARGET="$(cd "$TARGET" && pwd)"
source "$SRC/skills/init/scripts/lib.sh"

case "$TARGET/" in
  "$SRC"/*) echo "update.sh: refusing to touch the framework itself ($SRC)" >&2; exit 1 ;;
esac
if ! command -v jq >/dev/null 2>&1; then
  echo "update.sh: jq is required (the hooks need it too)." >&2
  echo "  Windows: winget install jqlang.jq   macOS: brew install jq   Debian/Ubuntu: apt install jq" >&2
  exit 1
fi

if [ ! -f "$TARGET/llm/framework/VERSION" ] || [ ! -f "$TARGET/llm/framework/RULES.md" ]; then
  echo "update.sh: the framework is not installed in $TARGET (no llm/framework/VERSION). Use the init or adopt skill first." >&2
  exit 1
fi

INSTALLED_VERSION="$(tr -d '[:space:]' < "$TARGET/llm/framework/VERSION")"
NEW_VERSION="$(jq -r '.version' "$SRC/.claude-plugin/plugin.json")"
if [ "$INSTALLED_VERSION" != "$NEW_VERSION" ]; then
  lowest="$(printf '%s\n%s\n' "$INSTALLED_VERSION" "$NEW_VERSION" | sort -V | head -1)"
  if [ "$lowest" = "$NEW_VERSION" ]; then
    echo "update.sh: the project has framework $INSTALLED_VERSION, newer than this plugin ($NEW_VERSION). Refusing to downgrade; update the plugin first." >&2
    exit 1
  fi
fi

# --accept-new targets must be things this script manages.
valid_target() {
  [ "$1" = "CLAUDE.md" ] && return 0
  [ "$1" = "$DEVCONTAINER_REL" ] && return 0
  managed_list | cut -d'|' -f1 | grep -qxF "$1"
}
for a in "${ACCEPT[@]+"${ACCEPT[@]}"}"; do
  if ! valid_target "$a"; then echo "update.sh: --accept-new: not a framework-managed path: $a" >&2; exit 1; fi
done
accepted() { local a; for a in "${ACCEPT[@]+"${ACCEPT[@]}"}"; do [ "$a" = "$1" ] && return 0; done; return 1; }

CREATED=0; UPDATED=0; REMOVED=0; MERGED=0; OK=0; CONFLICTS=0; ERRORS=0
report() { printf '%-9s %s\n' "$1" "$2"; }
conflict() { report CONFLICT "$1"; CONFLICTS=$((CONFLICTS+1)); }

echo "framework: installed $INSTALLED_VERSION, plugin $NEW_VERSION"
[ "$DRY" = 1 ] && report INFO "dry run: nothing will be written"
if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ -n "$(git -C "$TARGET" status --porcelain 2>/dev/null)" ]; then
    report WARN "git working tree has uncommitted changes; commit first so the update is a reviewable diff"
  fi
else
  report WARN "target is not a git repository; the update will not be reviewable as a diff"
fi
[ -f "$TARGET/$MANIFEST_REL" ] || report WARN "no $MANIFEST_REL (installed by an older version): edited files cannot be told from old ones, so differing files are reported as conflicts"

do_copy() { # src rel exec
  [ "$DRY" = 1 ] && return 0
  mkdir -p "$(dirname "$TARGET/$2")" && cp "$1" "$TARGET/$2" || { report ERROR "$2"; ERRORS=$((ERRORS+1)); return 1; }
  [ "$3" = 1 ] && chmod +x "$TARGET/$2"
  return 0
}

# ---- 1. framework-owned files ----------------------------------------------------------

process_file() { # rel src exec
  local rel="$1" src="$2" exe="$3" dest="$TARGET/$1" base cur
  base="$(manifest_get "$rel")"
  if [ ! -e "$dest" ]; then
    if [ -n "$base" ] && ! accepted "$rel"; then
      conflict "$rel (installed earlier but now missing; --accept-new $rel restores it)"
    else
      do_copy "$src" "$rel" "$exe" && { report CREATE "$rel"; CREATED=$((CREATED+1)); }
    fi
  elif cmp -s "$src" "$dest"; then
    report OK "$rel"; OK=$((OK+1))
  else
    cur="$(sha256_file "$dest")"
    if accepted "$rel"; then
      do_copy "$src" "$rel" "$exe" && { report UPDATE "$rel (accepted the new version)"; UPDATED=$((UPDATED+1)); }
    elif [ -n "$base" ] && [ "$cur" = "$base" ]; then
      do_copy "$src" "$rel" "$exe" && { report UPDATE "$rel"; UPDATED=$((UPDATED+1)); }
    elif [ -n "$base" ]; then
      conflict "$rel (edited since install; left untouched)"
    else
      conflict "$rel (baseline unknown and differs from the new version; left untouched)"
    fi
  fi
}

while IFS='|' read -r rel src exe; do
  process_file "$rel" "$src" "$exe"
done < <(managed_list)

if [ -e "$TARGET/$DEVCONTAINER_REL" ] || [ -n "$(manifest_get "$DEVCONTAINER_REL")" ]; then
  process_file "$DEVCONTAINER_REL" "$SRC/sandbox/devcontainer.json" 0
fi

# ---- 2. files that were framework-owned but no longer are -----------------------------

if [ -f "$TARGET/$MANIFEST_REL" ]; then
  current="$(managed_list | cut -d'|' -f1; echo "$DEVCONTAINER_REL"; echo "CLAUDE.md#block")"
  while read -r hash rel; do
    [ -z "$rel" ] && continue
    printf '%s\n' "$current" | grep -qxF "$rel" && continue
    [ -e "$TARGET/$rel" ] || continue
    if [ "$(sha256_file "$TARGET/$rel")" = "$hash" ]; then
      [ "$DRY" = 0 ] && rm -f "$TARGET/$rel"
      report REMOVE "$rel (no longer part of the framework)"; REMOVED=$((REMOVED+1))
    else
      report WARN "$rel is no longer part of the framework but was edited; left in place"
    fi
    if grep -qF "$rel" "$TARGET/.claude/settings.json" 2>/dev/null; then
      report WARN ".claude/settings.json still references $rel; remove that hook entry by hand"
    fi
  done < "$TARGET/$MANIFEST_REL"
fi

# ---- 3. new project records (never touches existing ones) ----------------------------------

for f in "$SRC"/templates/llm/*; do
  rel="llm/$(basename "$f")"
  if [ ! -e "$TARGET/$rel" ]; then
    do_copy "$f" "$rel" 0 && { report CREATE "$rel (new record in this version)"; CREATED=$((CREATED+1)); }
  fi
done

# ---- 4. .claude/settings.json (add missing hook entries) ------------------------------------

SETTINGS_REL=".claude/settings.json"
SETTINGS_DEST="$TARGET/$SETTINGS_REL"
if [ ! -e "$SETTINGS_DEST" ]; then
  do_copy "$ADAPTER/.claude/settings.json" "$SETTINGS_REL" 0 && { report CREATE "$SETTINGS_REL"; CREATED=$((CREATED+1)); }
elif ! jq -e . "$SETTINGS_DEST" >/dev/null 2>&1; then
  conflict "$SETTINGS_REL (not valid JSON; left untouched, merge by hand)"
else
  MERGED_JSON="$(settings_merged)"
  if [ -z "$MERGED_JSON" ]; then
    conflict "$SETTINGS_REL (unexpected hooks structure; left untouched, merge by hand)"
  elif [ "$(jq -S . <<<"$MERGED_JSON")" = "$(jq -S . "$SETTINGS_DEST")" ]; then
    report OK "$SETTINGS_REL (hooks already registered)"; OK=$((OK+1))
  else
    [ "$DRY" = 0 ] && printf '%s\n' "$MERGED_JSON" > "$SETTINGS_DEST"
    report MERGE "$SETTINGS_REL (added missing hook entries; other settings preserved)"; MERGED=$((MERGED+1))
  fi
fi

# ---- 5. CLAUDE.md framework block ----------------------------------------------------------

replace_block() { # block-file
  local tmp; tmp="$(mktemp)"
  awk -v blockfile="$1" -v begin="$BLOCK_BEGIN_PREFIX" -v end="$BLOCK_END" '
    BEGIN { skip = 0 }
    skip == 1 { if (index($0, end) == 1) { skip = 0; print } ; next }
    index($0, begin) == 1 { print; while ((getline l < blockfile) > 0) print l; skip = 1; next }
    { print }' "$TARGET/CLAUDE.md" > "$tmp" && cp "$tmp" "$TARGET/CLAUDE.md"
  rm -f "$tmp"
}

process_block() {
  local f="$TARGET/CLAUDE.md" pb inner pay base n total
  if [ ! -f "$f" ]; then report WARN "CLAUDE.md is missing; use the init or adopt skill"; return; fi
  pb="$(mktemp)"; payload_block > "$pb"
  pay="$(printf '%s\n' "$(payload_block)" | sha256_text)"
  if has_markers; then
    inner="$(printf '%s\n' "$(target_block)" | sha256_text)"
    base="$(manifest_get "CLAUDE.md#block")"
    if [ "$inner" = "$pay" ]; then
      report OK "CLAUDE.md (framework block current)"; OK=$((OK+1))
    elif accepted "CLAUDE.md" || { [ -n "$base" ] && [ "$inner" = "$base" ]; }; then
      [ "$DRY" = 0 ] && replace_block "$pb"
      report UPDATE "CLAUDE.md (framework block refreshed; your content untouched)"; UPDATED=$((UPDATED+1))
    elif [ -n "$base" ]; then
      conflict "CLAUDE.md framework block (edited since install; left untouched)"
    else
      conflict "CLAUDE.md framework block (baseline unknown and differs; left untouched)"
    fi
  elif grep -qF '@llm/framework/RULES.md' "$f"; then
    # Installed by a version that did not write markers.
    n="$(printf '%s\n' "$(payload_block)" | wc -l)"
    if [ "$(tail -n "$n" "$f")" = "$(payload_block)" ]; then
      if [ "$DRY" = 0 ]; then
        total="$(wc -l < "$f")"
        { head -n $((total - n)) "$f"; printf '%s\n' "$BLOCK_BEGIN"; cat "$pb"; printf '%s\n' "$BLOCK_END"; } > "$pb.new" && cp "$pb.new" "$f"
        rm -f "$pb.new"
      fi
      report MERGE "CLAUDE.md (added markers around the framework block so future updates can refresh it)"; MERGED=$((MERGED+1))
    else
      report WARN "CLAUDE.md has the framework sections but no markers and they differ from the current ones; compare by hand with adapters/claude-code/CLAUDE.md"
    fi
  else
    report WARN "CLAUDE.md has no framework sections; use the adopt skill"
  fi
  rm -f "$pb"
}
process_block

# ---- 6. .gitignore ----------------------------------------------------------------------------

GI_DEST="$TARGET/.gitignore"
if [ -e "$GI_DEST" ]; then
  MISSING="$(gitignore_missing)"
  if [ -n "$MISSING" ]; then
    if [ "$DRY" = 0 ]; then
      { [ -n "$(tail -c1 "$GI_DEST")" ] && printf '\n'; printf '\n# llm-governance (hook state, local settings)\n'; printf '%s\n' "$MISSING"; } >> "$GI_DEST"
    fi
    report MERGE ".gitignore (added missing entries)"; MERGED=$((MERGED+1))
  fi
else
  do_copy "$ADAPTER/.gitignore" ".gitignore" 0 && { report CREATE ".gitignore"; CREATED=$((CREATED+1)); }
fi

# ---- 7. version stamp and manifest ---------------------------------------------------------------

if [ "$DRY" = 0 ] && [ "$ERRORS" = 0 ]; then
  if [ "$CONFLICTS" = 0 ]; then
    if [ "$INSTALLED_VERSION" != "$NEW_VERSION" ]; then
      printf '%s\n' "$NEW_VERSION" > "$TARGET/llm/framework/VERSION"
      report UPDATE "llm/framework/VERSION ($INSTALLED_VERSION -> $NEW_VERSION)"
    fi
  else
    report WARN "llm/framework/VERSION stays at $INSTALLED_VERSION until every conflict is resolved; re-run update afterwards"
  fi
  manifest_write >/dev/null
fi

echo
echo "Summary: created=$CREATED updated=$UPDATED removed=$REMOVED merged=$MERGED ok=$OK conflicts=$CONFLICTS errors=$ERRORS$([ "$DRY" = 1 ] && echo ' (dry run)')"
if [ "$CONFLICTS" -gt 0 ]; then
  echo "NEXT: $CONFLICTS item(s) conflict and were left untouched. For each, either keep your version, merge by hand, or re-run with --accept-new <path> to take the plugin's version."
fi

[ "$ERRORS" -gt 0 ] && exit 1
[ "$CONFLICTS" -gt 0 ] && exit 2
exit 0
