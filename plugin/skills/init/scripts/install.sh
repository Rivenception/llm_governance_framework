#!/bin/bash
# install.sh -- install the LLM governance framework into a project.
#
# Usage: install.sh [--dry-run] [--sandbox] <target-project-dir>
#
# Deterministic and idempotent: running it twice changes nothing the second
# time. It never overwrites project content.
#   CREATE    file did not exist; created
#   MERGE     existing file extended (settings.json hooks, CLAUDE.md, .gitignore)
#   OK        already installed / already merged; nothing to do
#   KEEP      project record already exists; left untouched
#   CONFLICT  existing file differs from the framework's; left untouched
#   WARN      advisory
#
# To move an already-installed project to a newer plugin version, use the
# update skill (update.sh) instead; install.sh reports differences as conflicts.
#
# Exit codes: 0 done, 1 error (nothing guaranteed), 2 done but conflicts remain.

set -u

DRY=0
SANDBOX=0
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --sandbox) SANDBOX=1 ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    -*) echo "install.sh: unknown option: $arg" >&2; exit 1 ;;
    *) if [ -n "$TARGET" ]; then echo "install.sh: only one target directory allowed" >&2; exit 1; fi
       TARGET="$arg" ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "usage: install.sh [--dry-run] [--sandbox] <target-project-dir>" >&2
  exit 1
fi
if [ ! -d "$TARGET" ]; then
  echo "install.sh: target is not a directory: $TARGET" >&2
  exit 1
fi

# Plugin / repo root = three levels above this script (skills/init/scripts).
SRC="$(cd "$(dirname "$0")/../../.." && pwd)"
TARGET="$(cd "$TARGET" && pwd)"
source "$(dirname "$0")/lib.sh"

case "$TARGET/" in
  "$SRC"/*) echo "install.sh: refusing to install into the framework itself ($SRC)" >&2; exit 1 ;;
esac

if ! command -v jq >/dev/null 2>&1; then
  echo "install.sh: jq is required (the hooks need it too)." >&2
  echo "  Windows: winget install jqlang.jq   macOS: brew install jq   Debian/Ubuntu: apt install jq" >&2
  exit 1
fi

for f in "$ADAPTER/CLAUDE.md" "$ADAPTER/.claude/settings.json" "$ADAPTER/.gitignore" "$ADAPTER/.gitattributes" \
         "$SRC/core/RULES.md" "$SRC/core/llm-records.md" "$SRC/templates/llm" "$SRC/.claude-plugin/plugin.json"; do
  if [ ! -e "$f" ]; then echo "install.sh: framework payload missing: $f" >&2; exit 1; fi
done
if ! payload_block | grep -q .; then
  echo "install.sh: framework block not found in adapter CLAUDE.md (expected a '$BLOCK_HEAD' heading)" >&2
  exit 1
fi

CREATED=0; MERGED=0; OK=0; KEPT=0; CONFLICTS=0; ERRORS=0
NEW_CLAUDE_MD=0

report() { printf '%-9s %s\n' "$1" "$2"; }

# ---- primitives -----------------------------------------------------------

# copy_file <src> <rel-dest> <managed|record> [exec]
#   managed: framework-owned; a differing existing file is a CONFLICT
#   record : project-owned; a differing existing file is KEPT untouched
copy_file() {
  local src="$1" rel="$2" kind="$3" exe="${4:-}" dest="$TARGET/$2"
  if [ ! -e "$dest" ]; then
    if [ "$DRY" = 0 ]; then
      mkdir -p "$(dirname "$dest")" && cp "$src" "$dest" || { report ERROR "$rel"; ERRORS=$((ERRORS+1)); return; }
      [ -n "$exe" ] && chmod +x "$dest"
    fi
    report CREATE "$rel"; CREATED=$((CREATED+1))
  elif cmp -s "$src" "$dest"; then
    report OK "$rel"; OK=$((OK+1))
  elif [ "$kind" = record ]; then
    report KEEP "$rel (exists; left untouched)"; KEPT=$((KEPT+1))
  else
    report CONFLICT "$rel (differs from framework version; left untouched)"; CONFLICTS=$((CONFLICTS+1))
  fi
}

# ---- git hygiene (advisory) -------------------------------------------------

if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ -n "$(git -C "$TARGET" status --porcelain 2>/dev/null)" ]; then
    report WARN "git working tree has uncommitted changes; commit first so the install is a reviewable diff"
  fi
else
  report WARN "target is not a git repository; the install will not be reviewable as a diff"
fi
[ "$DRY" = 1 ] && report INFO "dry run: nothing will be written"

PLUGIN_VERSION="$(jq -r '.version // empty' "$SRC/.claude-plugin/plugin.json" 2>/dev/null)"
if [ -z "$PLUGIN_VERSION" ]; then
  echo "install.sh: cannot read the plugin version from $SRC/.claude-plugin/plugin.json (missing, unreadable or invalid JSON)." >&2
  exit 1
fi
if [ -f "$TARGET/llm/framework/VERSION" ] && [ "$(cat "$TARGET/llm/framework/VERSION")" != "$PLUGIN_VERSION" ]; then
  report WARN "this project has framework $(cat "$TARGET/llm/framework/VERSION") installed and the plugin is $PLUGIN_VERSION; use the update skill to upgrade"
fi

# ---- 1. llm/ records (project-owned) ----------------------------------------

for f in "$SRC"/templates/llm/*; do
  copy_file "$f" "llm/$(basename "$f")" record
done

# ---- 2. llm/framework + 3. hooks (framework-owned) ---------------------------

while IFS='|' read -r rel src exe; do
  if [ "$exe" = 1 ]; then copy_file "$src" "$rel" managed exec; else copy_file "$src" "$rel" managed; fi
done < <(managed_list)

VERSION_TMP="$(mktemp)"
printf '%s\n' "$PLUGIN_VERSION" > "$VERSION_TMP"
copy_file "$VERSION_TMP" "llm/framework/VERSION" managed
rm -f "$VERSION_TMP"

# ---- 4. .claude/settings.json (merge hook entries) ---------------------------

SETTINGS_SRC="$ADAPTER/.claude/settings.json"
SETTINGS_REL=".claude/settings.json"
SETTINGS_DEST="$TARGET/$SETTINGS_REL"

if [ ! -e "$SETTINGS_DEST" ]; then
  copy_file "$SETTINGS_SRC" "$SETTINGS_REL" managed
elif ! jq -e . "$SETTINGS_DEST" >/dev/null 2>&1; then
  report CONFLICT "$SETTINGS_REL (not valid JSON; left untouched, merge by hand)"; CONFLICTS=$((CONFLICTS+1))
else
  MERGED_JSON="$(settings_merged)"
  if [ -z "$MERGED_JSON" ]; then
    report CONFLICT "$SETTINGS_REL (unexpected hooks structure; left untouched, merge by hand)"; CONFLICTS=$((CONFLICTS+1))
  elif [ "$(jq -S . <<<"$MERGED_JSON")" = "$(jq -S . "$SETTINGS_DEST")" ]; then
    report OK "$SETTINGS_REL (hooks already registered)"; OK=$((OK+1))
  else
    if [ "$DRY" = 0 ]; then
      printf '%s\n' "$MERGED_JSON" > "$SETTINGS_DEST" || { report ERROR "$SETTINGS_REL"; ERRORS=$((ERRORS+1)); }
    fi
    report MERGE "$SETTINGS_REL (added missing hook entries; other settings preserved)"; MERGED=$((MERGED+1))
  fi
fi

# ---- 5. CLAUDE.md ---------------------------------------------------------------

CLAUDE_DEST="$TARGET/CLAUDE.md"
IMPORT_MARK='@llm/framework/RULES.md'

if [ ! -e "$CLAUDE_DEST" ]; then
  # New project: placeholders first, then the framework block between markers
  # so the update skill can find and refresh it later.
  if [ "$DRY" = 0 ]; then
    {
      payload_head
      printf '%s\n' "$BLOCK_BEGIN"
      payload_block
      printf '%s\n' "$BLOCK_END"
    } > "$CLAUDE_DEST" || { report ERROR "CLAUDE.md"; ERRORS=$((ERRORS+1)); }
  fi
  report CREATE "CLAUDE.md"; CREATED=$((CREATED+1))
  NEW_CLAUDE_MD=1
elif grep -qF "$IMPORT_MARK" "$CLAUDE_DEST"; then
  report OK "CLAUDE.md (framework sections already present)"; OK=$((OK+1))
else
  if [ "$DRY" = 0 ]; then
    append_block "$CLAUDE_DEST" "$(printf '\n%s\n%s\n%s\n' "$BLOCK_BEGIN" "$(payload_block)" "$BLOCK_END")" \
      || { report ERROR "CLAUDE.md"; ERRORS=$((ERRORS+1)); }
  fi
  report MERGE "CLAUDE.md (appended framework sections; your content untouched)"; MERGED=$((MERGED+1))
fi

# ---- 6. .gitignore --------------------------------------------------------------

GI_DEST="$TARGET/.gitignore"
if [ ! -e "$GI_DEST" ]; then
  copy_file "$ADAPTER/.gitignore" ".gitignore" managed
else
  MISSING="$(gitignore_missing)"
  if [ -z "$MISSING" ]; then
    report OK ".gitignore (entries already present)"; OK=$((OK+1))
  else
    if [ "$DRY" = 0 ]; then
      append_block "$GI_DEST" "$(printf '\n# llm-governance (hook state, local settings)\n%s\n' "$MISSING")" \
        || { report ERROR ".gitignore"; ERRORS=$((ERRORS+1)); }
    fi
    report MERGE ".gitignore (added missing entries)"; MERGED=$((MERGED+1))
  fi
fi

# ---- 6b. .gitattributes (keep framework scripts LF on Windows checkouts) ----------

GA_DEST="$TARGET/.gitattributes"
if [ ! -e "$GA_DEST" ]; then
  copy_file "$ADAPTER/.gitattributes" ".gitattributes" managed
else
  MISSING="$(gitattributes_missing)"
  if [ -z "$MISSING" ]; then
    report OK ".gitattributes (LF rules already present)"; OK=$((OK+1))
  else
    if [ "$DRY" = 0 ]; then
      append_block "$GA_DEST" "$(printf '\n# llm-governance (framework scripts and rules keep LF line endings)\n%s\n' "$MISSING")" \
        || { report ERROR ".gitattributes"; ERRORS=$((ERRORS+1)); }
    fi
    report MERGE ".gitattributes (added LF rules for framework files)"; MERGED=$((MERGED+1))
  fi
fi

# ---- 7. optional sandbox ----------------------------------------------------------

if [ "$SANDBOX" = 1 ]; then
  copy_file "$SRC/sandbox/devcontainer.json" "$DEVCONTAINER_REL" managed
fi

# ---- 8. manifest (what is installed pristine; lets update tell edits from age) -----

if [ "$DRY" = 0 ] && [ "$ERRORS" = 0 ]; then
  if [ "$(manifest_write)" = changed ]; then report INFO "$MANIFEST_REL (record of installed framework files)"; fi
fi

# ---- summary ---------------------------------------------------------------------------

echo
echo "Summary: created=$CREATED merged=$MERGED ok=$OK kept=$KEPT conflicts=$CONFLICTS errors=$ERRORS$([ "$DRY" = 1 ] && echo ' (dry run)')"
if [ "$NEW_CLAUDE_MD" = 1 ]; then
  echo "NEXT: fill in the [bracketed] placeholders in CLAUDE.md (overview, commands, scope and stack)."
fi
if [ "$CONFLICTS" -gt 0 ]; then
  echo "NEXT: $CONFLICTS file(s) conflict with the framework version and were left untouched; review them."
fi

[ "$ERRORS" -gt 0 ] && exit 1
[ "$CONFLICTS" -gt 0 ] && exit 2
exit 0
