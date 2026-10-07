#!/bin/bash
# Tests for plugin/skills/update/scripts/update.sh. Run: bash tests/test_update.sh
# Simulates plugin releases by copying the plugin/ directory and altering the copies:
#   OLD (0.1.0, plus a hook that later disappears) -> NEW (0.2.0, changed payload)

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$REPO/plugin"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0

check() { # name expected actual
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "PASS $1"
  else FAIL=$((FAIL+1)); echo "FAIL $1 (expected: $2 | got: $3)"; fi
}
has() { printf '%s' "$1" | grep -qF -- "$2" && echo yes || echo no; }
yn() { if "$@" >/dev/null 2>&1; then echo yes; else echo no; fi; }
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi | awk '{print $1}'; }
treehash() { (cd "$1" && find . -type f -not -path './.git/*' | sort | while read -r f; do echo "$f $(sha < "$f")"; done | sha); }

copy_repo() { # dest version
  mkdir -p "$1"
  (cd "$PLUGIN" && tar --exclude=.git -cf - .) | (cd "$1" && tar -xf -)
  jq --arg v "$2" '.version=$v' "$1/.claude-plugin/plugin.json" > "$1/pj.tmp" && mv "$1/pj.tmp" "$1/.claude-plugin/plugin.json"
}

# ---- build plugin releases ----
OLD="$TMP/plugin-old"; copy_repo "$OLD" 0.1.0
printf '#!/bin/bash\n# hook that was removed in a later release\nexit 0\n' > "$OLD/adapters/claude-code/.claude/hooks/old_only.sh"
OLD_DEV_FILE="$OLD/sandbox/devcontainer.json"

MID="$TMP/plugin-mid"; copy_repo "$MID" 0.1.5          # same payload as OLD, no block change
PREV="$TMP/plugin-prev"; copy_repo "$PREV" 0.1.0       # identical payload to MID, older version

NEW="$TMP/plugin-new"; copy_repo "$NEW" 0.2.0
echo "NEW RULE LINE" >> "$NEW/core/RULES.md"
echo "# changed in 0.2.0" >> "$NEW/adapters/claude-code/.claude/hooks/check_precompact.sh"
printf '#!/bin/bash\nexit 0\n' > "$NEW/adapters/claude-code/.claude/hooks/extra_hook.sh"
printf '# New record\n' > "$NEW/templates/llm/NEWREC.md"
echo "- new enforcement note in 0.2.0" >> "$NEW/adapters/claude-code/CLAUDE.md"
jq '.hooks.UserPromptSubmit=[{"hooks":[{"type":"command","command":"bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/extra_hook.sh"}]}]' \
  "$NEW/adapters/claude-code/.claude/settings.json" > "$NEW/s.tmp" && mv "$NEW/s.tmp" "$NEW/adapters/claude-code/.claude/settings.json"
jq '.name="LLM Governance Sandbox v2"' "$NEW/sandbox/devcontainer.json" > "$NEW/d.tmp" && mv "$NEW/d.tmp" "$NEW/sandbox/devcontainer.json"

oi() { bash "$OLD/skills/init/scripts/install.sh" "$@" >/dev/null 2>&1; }
up() { OUT="$(bash "$NEW/skills/update/scripts/update.sh" "$@" 2>&1)"; RC=$?; }
newproj() { P="$TMP/$1"; mkdir -p "$P"; }

# ================= 1. standard upgrade of an init-created project =================
newproj p1
oi "$P"
printf '\n## My own notes\nkeep me\n' >> "$P/CLAUDE.md"          # user content after the block
echo "- my real todo" >> "$P/llm/TODO.md"                          # project record
jq '.hooks.Stop += [{"hooks":[{"type":"command","command":"echo my-stop"}]}] | .env={"A":"b"}' "$P/.claude/settings.json" > "$P/s.tmp" && mv "$P/s.tmp" "$P/.claude/settings.json"
check "old install: VERSION 0.1.0" 0.1.0 "$(cat "$P/llm/framework/VERSION")"
check "old install: manifest written" yes "$([ -s "$P/llm/framework/MANIFEST" ] && echo yes || echo no)"
check "old install: block has markers" 2 "$(grep -c 'llm-governance:\(begin\|end\)' "$P/CLAUDE.md")"
check "old install: old_only.sh present" yes "$([ -f "$P/.claude/hooks/old_only.sh" ] && echo yes || echo no)"

H0="$(treehash "$P")"
up --dry-run "$P"
check "dry-run: exit 0" 0 "$RC"
check "dry-run: writes nothing" "$H0" "$(treehash "$P")"
check "dry-run: shows versions" yes "$(has "$OUT" 'installed 0.1.0, plugin 0.2.0')"
check "dry-run: plans RULES.md update" yes "$(has "$OUT" 'UPDATE    llm/framework/RULES.md')"
check "dry-run: plans removal" yes "$(has "$OUT" 'REMOVE    .claude/hooks/old_only.sh')"
check "dry-run: plans the version stamp" yes "$(has "$OUT" 'UPDATE    llm/framework/VERSION (0.1.0 -> 0.2.0)')"

up "$P"
check "upgrade: exit 0" 0 "$RC"
check "upgrade: RULES.md is the new one" yes "$(cmp -s "$NEW/core/RULES.md" "$P/llm/framework/RULES.md" && echo yes || echo no)"
check "upgrade: changed hook updated" yes "$(cmp -s "$NEW/adapters/claude-code/.claude/hooks/check_precompact.sh" "$P/.claude/hooks/check_precompact.sh" && echo yes || echo no)"
check "upgrade: new hook created" yes "$([ -f "$P/.claude/hooks/extra_hook.sh" ] && echo yes || echo no)"
check "upgrade: new hook executable" yes "$([ -x "$P/.claude/hooks/extra_hook.sh" ] && echo yes || echo no)"
check "upgrade: obsolete hook removed" no "$([ -e "$P/.claude/hooks/old_only.sh" ] && echo yes || echo no)"
check "upgrade: new record created" yes "$([ -f "$P/llm/NEWREC.md" ] && echo yes || echo no)"
check "upgrade: new settings event merged" yes "$(jq -e '.hooks.UserPromptSubmit' "$P/.claude/settings.json" >/dev/null && echo yes || echo no)"
check "upgrade: user's own Stop hook kept" yes "$(jq -e '[.hooks.Stop[].hooks[].command]|index("echo my-stop")' "$P/.claude/settings.json" >/dev/null && echo yes || echo no)"
check "upgrade: user's env setting kept" b "$(jq -r '.env.A' "$P/.claude/settings.json")"
check "upgrade: CLAUDE.md block refreshed" yes "$(grep -qF 'new enforcement note in 0.2.0' "$P/CLAUDE.md" && echo yes || echo no)"
check "upgrade: user notes after block intact" yes "$(grep -q 'keep me' "$P/CLAUDE.md" && echo yes || echo no)"
check "upgrade: exactly one begin marker" 1 "$(grep -c 'llm-governance:begin' "$P/CLAUDE.md")"
check "upgrade: project record untouched" yes "$(grep -q 'my real todo' "$P/llm/TODO.md" && echo yes || echo no)"
check "upgrade: VERSION now 0.2.0" 0.2.0 "$(cat "$P/llm/framework/VERSION")"
check "upgrade: manifest matches new RULES.md" "$(sha < "$NEW/core/RULES.md")" "$(awk '$2=="llm/framework/RULES.md"{print $1}' "$P/llm/framework/MANIFEST")"
check "upgrade: manifest dropped removed hook" no "$(grep -q old_only "$P/llm/framework/MANIFEST" && echo yes || echo no)"

H1="$(treehash "$P")"
up "$P"
check "idempotent: exit 0" 0 "$RC"
check "idempotent: nothing changed" "$H1" "$(treehash "$P")"
check "idempotent: reports zero updates" yes "$(has "$OUT" 'updated=0 removed=0')"

# ================= 2. local edits are conflicts, never overwritten =================
newproj p2
oi "$P"
echo "# my local tweak" >> "$P/.claude/hooks/lib.sh"
TWEAKED="$(cat "$P/.claude/hooks/lib.sh")"
up "$P"
check "edited hook: exit 2" 2 "$RC"
check "edited hook: reported" yes "$(has "$OUT" 'CONFLICT  .claude/hooks/lib.sh (edited since install')"
check "edited hook: left untouched" "$TWEAKED" "$(cat "$P/.claude/hooks/lib.sh")"
check "edited hook: other files still updated" yes "$(cmp -s "$NEW/core/RULES.md" "$P/llm/framework/RULES.md" && echo yes || echo no)"
check "edited hook: VERSION held back" 0.1.0 "$(cat "$P/llm/framework/VERSION")"
up --accept-new .claude/hooks/lib.sh "$P"
check "accept-new: exit 0" 0 "$RC"
check "accept-new: file replaced" yes "$(cmp -s "$NEW/adapters/claude-code/.claude/hooks/lib.sh" "$P/.claude/hooks/lib.sh" && echo yes || echo no)"
check "accept-new: VERSION advanced" 0.2.0 "$(cat "$P/llm/framework/VERSION")"

newproj p2b
oi "$P"
rm "$P/.claude/hooks/mark_dirty.sh"
up "$P"
check "deleted managed file: conflict (exit 2)" 2 "$RC"
check "deleted managed file: not silently recreated" no "$([ -e "$P/.claude/hooks/mark_dirty.sh" ] && echo yes || echo no)"
up --accept-new .claude/hooks/mark_dirty.sh "$P"
check "deleted managed file: --accept-new restores it" yes "$([ -f "$P/.claude/hooks/mark_dirty.sh" ] && echo yes || echo no)"

# ================= 3. edited CLAUDE.md block =================
newproj p3
oi "$P"
sed -i 's/Use that exact session ID/Use THE session ID/' "$P/CLAUDE.md"
echo "## after" >> "$P/CLAUDE.md"
up "$P"
check "edited block: exit 2" 2 "$RC"
check "edited block: reported" yes "$(has "$OUT" 'CONFLICT  CLAUDE.md framework block (edited since install')"
check "edited block: edit preserved" yes "$(grep -q 'Use THE session ID' "$P/CLAUDE.md" && echo yes || echo no)"
up --accept-new CLAUDE.md "$P"
check "edited block accept-new: exit 0" 0 "$RC"
check "edited block accept-new: refreshed" yes "$(grep -qF 'new enforcement note in 0.2.0' "$P/CLAUDE.md" && grep -q 'Use that exact session ID' "$P/CLAUDE.md" && echo yes || echo no)"
check "edited block accept-new: content after block kept" yes "$(grep -q '^## after' "$P/CLAUDE.md" && echo yes || echo no)"

# ================= 4. adopt-style CLAUDE.md (existing user content) =================
newproj p4
printf '# Existing project\n\nMy own instructions.\n' > "$P/CLAUDE.md"
oi "$P"
up "$P"
check "adopted CLAUDE.md: exit 0" 0 "$RC"
check "adopted CLAUDE.md: block refreshed" yes "$(grep -qF 'new enforcement note in 0.2.0' "$P/CLAUDE.md" && echo yes || echo no)"
check "adopted CLAUDE.md: user text intact" yes "$(grep -q 'My own instructions' "$P/CLAUDE.md" && echo yes || echo no)"
check "adopted CLAUDE.md: starts with user heading" '# Existing project' "$(head -1 "$P/CLAUDE.md")"

# ================= 5. legacy installs =================
newproj p5     # no manifest
oi "$P"; rm "$P/llm/framework/MANIFEST"
up "$P"
check "no manifest: exit 2" 2 "$RC"
check "no manifest: warns about baseline" yes "$(has "$OUT" 'no llm/framework/MANIFEST')"
check "no manifest: differing file is a conflict" yes "$(has "$OUT" 'baseline unknown')"
check "no manifest: nothing overwritten" yes "$(! cmp -s "$NEW/core/RULES.md" "$P/llm/framework/RULES.md" && echo yes || echo no)"
check "no manifest: VERSION held back" 0.1.0 "$(cat "$P/llm/framework/VERSION")"
up --accept-new llm/framework/RULES.md --accept-new llm/framework/llm-records.md --accept-new .claude/hooks/check_precompact.sh --accept-new CLAUDE.md "$P"
check "no manifest, all accepted: exit 0" 0 "$RC"
check "no manifest, all accepted: VERSION advanced" 0.2.0 "$(cat "$P/llm/framework/VERSION")"
check "no manifest, all accepted: manifest now exists" yes "$([ -s "$P/llm/framework/MANIFEST" ] && echo yes || echo no)"

newproj p6     # init-created by an older version that wrote no markers
oi "$P"; rm "$P/llm/framework/MANIFEST"
sed -i '/llm-governance:\(begin\|end\)/d' "$P/CLAUDE.md"
OUT="$(bash "$MID/skills/update/scripts/update.sh" "$P" 2>&1)"; RC=$?
check "markerless, unchanged block: exit 0" 0 "$RC"
check "markerless, unchanged block: markers added" yes "$(has "$OUT" 'added markers')"
check "markerless, unchanged block: markers now present" 2 "$(grep -c 'llm-governance:\(begin\|end\)' "$P/CLAUDE.md")"
newproj p6b
oi "$P"; sed -i '/llm-governance:\(begin\|end\)/d' "$P/CLAUDE.md"
up "$P"
check "markerless, changed block: warns instead of guessing" yes "$(has "$OUT" 'no markers')"
check "markerless, changed block: CLAUDE.md untouched" 0 "$(grep -c 'llm-governance' "$P/CLAUDE.md")"

# ================= 6. removed-but-edited file =================
newproj p7
oi "$P"
echo "# user changed me" >> "$P/.claude/hooks/old_only.sh"
up "$P"
check "removed+edited: stays in place" yes "$([ -f "$P/.claude/hooks/old_only.sh" ] && echo yes || echo no)"
check "removed+edited: warned" yes "$(has "$OUT" 'old_only.sh is no longer part of the framework but was edited')"

# ================= 7. optional devcontainer =================
newproj p8
oi --sandbox "$P"
up "$P"
check "devcontainer: updated when installed" yes "$(cmp -s "$NEW/sandbox/devcontainer.json" "$P/.devcontainer/devcontainer.json" && echo yes || echo no)"
newproj p8b
oi "$P"
up "$P"
check "devcontainer: not created when never installed" no "$([ -e "$P/.devcontainer" ] && echo yes || echo no)"

# ================= 8. the version stamp is part of the plan =================
newproj p11
bash "$PREV/skills/init/scripts/install.sh" "$P" >/dev/null 2>&1
H11="$(treehash "$P")"
OUT="$(bash "$MID/skills/update/scripts/update.sh" --dry-run "$P" 2>&1)"; RC=$?
check "version-only dry run: exit 0" 0 "$RC"
check "version-only dry run: lists the stamp" yes "$(has "$OUT" 'UPDATE    llm/framework/VERSION (0.1.0 -> 0.1.5)')"
check "version-only dry run: it is the only change" yes "$(has "$OUT" 'created=0 updated=1 removed=0 merged=0')"
check "version-only dry run: writes nothing" "$H11" "$(treehash "$P")"
OUT="$(bash "$MID/skills/update/scripts/update.sh" "$P" 2>&1)"; RC=$?
check "version-only real run: exit 0" 0 "$RC"
check "version-only real run: stamp advanced" 0.1.5 "$(cat "$P/llm/framework/VERSION")"
check "version-only real run: same summary as the plan" yes "$(has "$OUT" 'created=0 updated=1 removed=0 merged=0')"
OUT="$(bash "$MID/skills/update/scripts/update.sh" "$P" 2>&1)"
check "version-only: second run has nothing to do" yes "$(has "$OUT" 'updated=0 removed=0 merged=0')"
check "version-only: second run lists no stamp change" no "$(has "$OUT" 'UPDATE    llm/framework/VERSION')"

newproj p12
oi "$P"; echo "# local edit" >> "$P/.claude/hooks/lib.sh"
up --dry-run "$P"
check "dry run with a conflict: says the stamp is held back" yes "$(has "$OUT" 'stays at 0.1.0 until every conflict is resolved')"
check "dry run with a conflict: lists no stamp UPDATE" no "$(has "$OUT" 'UPDATE    llm/framework/VERSION')"

# ================= 9. .gitattributes LF rules, CRLF-tolerant CLAUDE.md block =================
newproj p13     # installed before the rules existed: no .gitattributes at all
oi "$P"; rm "$P/.gitattributes"
up "$P"
check "no .gitattributes: update creates it" yes "$([ -f "$P/.gitattributes" ] && echo yes || echo no)"
check "no .gitattributes: reported as CREATE" yes "$(has "$OUT" 'CREATE    .gitattributes')"
check "no .gitattributes: has the LF rules" yes "$(grep -qxF '.claude/hooks/*.sh text eol=lf' "$P/.gitattributes" && echo yes || echo no)"

newproj p14     # user's own .gitattributes without the rules
oi "$P"; printf '*.png binary' > "$P/.gitattributes"
up "$P"
check "user .gitattributes: reported as MERGE" yes "$(has "$OUT" 'MERGE     .gitattributes')"
check "user .gitattributes: original line kept" yes "$(grep -qxF '*.png binary' "$P/.gitattributes" && echo yes || echo no)"
check "user .gitattributes: LF rules appended" yes "$(grep -qxF 'llm/framework/** text eol=lf' "$P/.gitattributes" && echo yes || echo no)"
up "$P"
check "user .gitattributes: second run adds nothing" 1 "$(grep -cxF 'llm/framework/** text eol=lf' "$P/.gitattributes")"

newproj p15     # Windows autocrlf checkout of CLAUDE.md: block must not read as "edited"
oi "$P"; sed -i 's/$/\r/' "$P/CLAUDE.md"
up "$P"
check "CRLF CLAUDE.md: update is not a conflict (exit 0)" 0 "$RC"
check "CRLF CLAUDE.md: block refreshed" yes "$(grep -qF 'new enforcement note in 0.2.0' "$P/CLAUDE.md" && echo yes || echo no)"

newproj p16     # a project's own dev container is never the framework's business
oi "$P"; mkdir -p "$P/.devcontainer"; echo '{"name":"mine"}' > "$P/.devcontainer/devcontainer.json"
up "$P"
check "own devcontainer: no conflict (exit 0)" 0 "$RC"
check "own devcontainer: left untouched" '{"name":"mine"}' "$(cat "$P/.devcontainer/devcontainer.json")"
check "own devcontainer: version still advances" 0.2.0 "$(cat "$P/llm/framework/VERSION")"
check "own devcontainer: not mentioned in the plan" no "$(has "$OUT" 'devcontainer')"

newproj p17     # Windows checkout: CRLF .gitignore/.gitattributes must not collect duplicates
oi "$P"; sed -i 's/$/\r/' "$P/.gitignore" "$P/.gitattributes"
up "$P"
up "$P"
check "CRLF ignore files: second update merges nothing" yes "$(has "$OUT" 'merged=0')"
check "CRLF .gitignore: no duplicate entry" 1 "$(tr -d '\r' < "$P/.gitignore" | grep -cxF '.claude/hooks/.state/')"
check "CRLF .gitattributes: no duplicate rule" 1 "$(tr -d '\r' < "$P/.gitattributes" | grep -cxF 'llm/framework/** text eol=lf')"

newproj p18     # unreadable plugin manifest: a clear error, not a misleading version message
oi "$P"
BROKEN="$TMP/plugin-broken"; copy_repo "$BROKEN" 0.2.0; echo '{ not json' > "$BROKEN/.claude-plugin/plugin.json"
OUT="$(bash "$BROKEN/skills/update/scripts/update.sh" "$P" 2>&1)"; RC=$?
check "unreadable plugin.json (update): exit 1" 1 "$RC"
check "unreadable plugin.json (update): names the problem" yes "$(has "$OUT" 'cannot read the plugin version')"
mkdir -p "$TMP/p18-new"
OUT="$(bash "$BROKEN/skills/init/scripts/install.sh" "$TMP/p18-new" 2>&1)"; RC=$?
check "unreadable plugin.json (install): exit 1" 1 "$RC"
check "unreadable plugin.json (install): names the problem" yes "$(has "$OUT" 'cannot read the plugin version')"

# ================= 10. refusals =================
newproj p9
bash "$NEW/skills/init/scripts/install.sh" "$P" >/dev/null 2>&1
OUT="$(bash "$OLD/skills/update/scripts/update.sh" "$P" 2>&1)"; RC=$?
check "downgrade: refused (exit 1)" 1 "$RC"
check "downgrade: explains" yes "$(has "$OUT" 'Refusing to downgrade')"
up "$P"
check "same version: exit 0" 0 "$RC"
check "same version: nothing to do" yes "$(has "$OUT" 'updated=0 removed=0 merged=0')"
newproj p10
up "$P"
check "not installed: exit 1" 1 "$RC"
check "not installed: points to init/adopt" yes "$(has "$OUT" 'init or adopt')"
up --accept-new not/a/managed/file "$TMP/p9"
check "accept-new bogus path: exit 1" 1 "$RC"
up
check "no args: exit 1" 1 "$RC"
up --bogus "$TMP/p9"
check "unknown option: exit 1" 1 "$RC"
up "$TMP/does-not-exist"
check "missing dir: exit 1" 1 "$RC"
bash "$NEW/skills/update/scripts/update.sh" "$NEW" >/dev/null 2>&1
check "refuses to touch the plugin directory: exit 1" 1 "$?"

echo
echo "passed=$PASS failed=$FAIL"
[ "$FAIL" = 0 ]
