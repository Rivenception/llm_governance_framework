#!/bin/bash
# lib.sh -- helpers shared by install.sh and update.sh. Sourced, not run.
# The caller must set SRC (plugin root) and TARGET (project root) first.

ADAPTER="$SRC/adapters/claude-code"
MANIFEST_REL="llm/framework/MANIFEST"
BLOCK_BEGIN='<!-- llm-governance:begin (installed by the llm-governance plugin) -->'
BLOCK_END='<!-- llm-governance:end -->'
BLOCK_BEGIN_PREFIX='<!-- llm-governance:begin'
BLOCK_HEAD='## Session ID and timestamps'
DEVCONTAINER_REL=".devcontainer/devcontainer.json"

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'; fi
}
sha256_text() { # stdin
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'
  else shasum -a 256 | awk '{print $1}'; fi
}

# Framework-owned files: "<rel-dest>|<src>|<exec 0/1>". The devcontainer file
# is optional and handled separately (only managed where it was installed).
managed_list() {
  local f
  for f in "$SRC"/core/*.md; do printf '%s|%s|0\n' "llm/framework/$(basename "$f")" "$f"; done
  for f in "$ADAPTER"/.claude/hooks/*.sh; do printf '%s|%s|1\n' ".claude/hooks/$(basename "$f")" "$f"; done
}

# ---- CLAUDE.md framework block ------------------------------------------------

# Framework sections of the adapter CLAUDE.md (from the Session ID heading on).
payload_block() { sed -n "/^$BLOCK_HEAD/,\$p" "$ADAPTER/CLAUDE.md"; }
# Everything before the framework sections (the project placeholders).
payload_head() { sed "/^$BLOCK_HEAD/,\$d" "$ADAPTER/CLAUDE.md"; }

has_markers() {
  [ -f "$TARGET/CLAUDE.md" ] && grep -qF "$BLOCK_BEGIN_PREFIX" "$TARGET/CLAUDE.md" && grep -qF "$BLOCK_END" "$TARGET/CLAUDE.md"
}
# Text between the markers in the target's CLAUDE.md.
target_block() {
  sed -n "/$BLOCK_BEGIN_PREFIX/,/^$BLOCK_END\$/p" "$TARGET/CLAUDE.md" | sed '1d;$d'
}

# ---- manifest: "<sha256>  <rel>" lines of what was installed pristine -----------

manifest_get() { # rel -> hash (empty if none)
  [ -f "$TARGET/$MANIFEST_REL" ] || return 0
  awk -v k="$1" '$2==k {print $1; exit}' "$TARGET/$MANIFEST_REL"
}

# Print the manifest as it should be given the files' current state. A file that
# matches the plugin's copy is recorded with its hash; a file that differs keeps
# its previous entry (so later runs still know its baseline); anything no longer
# part of the framework is dropped.
manifest_compute() {
  local rel src exe dest old payload_hash inner
  while IFS='|' read -r rel src exe; do
    dest="$TARGET/$rel"
    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
      printf '%s  %s\n' "$(sha256_file "$dest")" "$rel"
    else
      old="$(manifest_get "$rel")"; [ -n "$old" ] && printf '%s  %s\n' "$old" "$rel"
    fi
  done < <(managed_list)
  if [ -f "$TARGET/$DEVCONTAINER_REL" ] && cmp -s "$SRC/sandbox/devcontainer.json" "$TARGET/$DEVCONTAINER_REL"; then
    printf '%s  %s\n' "$(sha256_file "$TARGET/$DEVCONTAINER_REL")" "$DEVCONTAINER_REL"
  else
    old="$(manifest_get "$DEVCONTAINER_REL")"; [ -n "$old" ] && printf '%s  %s\n' "$old" "$DEVCONTAINER_REL"
  fi
  payload_hash="$(printf '%s\n' "$(payload_block)" | sha256_text)"
  if has_markers; then
    inner="$(printf '%s\n' "$(target_block)" | sha256_text)"
    if [ "$inner" = "$payload_hash" ]; then printf '%s  %s\n' "$inner" "CLAUDE.md#block"
    else old="$(manifest_get "CLAUDE.md#block")"; [ -n "$old" ] && printf '%s  %s\n' "$old" "CLAUDE.md#block"; fi
  fi
}

manifest_write() { # writes the recomputed manifest; echoes "changed" or "same"
  local tmp dest="$TARGET/$MANIFEST_REL"
  tmp="$(mktemp)"
  manifest_compute | LC_ALL=C sort -k2 > "$tmp"
  if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then echo same
  else mkdir -p "$(dirname "$dest")" && cp "$tmp" "$dest" && echo changed; fi
  rm -f "$tmp"
}

# ---- settings.json merge -----------------------------------------------------------

# Print the target's settings.json with the framework's hook entries added
# (existing settings and hooks preserved). Non-zero if the file cannot be merged.
settings_merged() {
  jq --indent 2 --argjson s "$(cat "$ADAPTER/.claude/settings.json")" '
    .hooks //= {} |
    reduce ($s.hooks | to_entries[]) as $ev (.;
      reduce $ev.value[] as $entry (.;
        if ((.hooks[$ev.key] // [])
            | any(.[]; (.hooks // []) | any(.[]; .command as $c | ($entry.hooks | map(.command) | index($c)) != null)))
        then .
        else .hooks[$ev.key] = ((.hooks[$ev.key] // []) + [$entry])
        end))' "$TARGET/.claude/settings.json" 2>/dev/null
}

# .gitignore lines from the adapter that the target lacks.
gitignore_missing() {
  local line
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    grep -qxF "$line" "$TARGET/.gitignore" 2>/dev/null || printf '%s\n' "$line"
  done < "$ADAPTER/.gitignore"
}
