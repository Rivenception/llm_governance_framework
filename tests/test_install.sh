#!/bin/bash
# Tests for plugin/skills/init/scripts/install.sh. Run: bash tests/test_install.sh
# Needs bash, jq, git, sha256sum/shasum. Uses a throwaway temp dir.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$REPO/plugin"
INSTALL="$PLUGIN/skills/init/scripts/install.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0

check() { # name expected actual
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "PASS $1"
  else FAIL=$((FAIL+1)); echo "FAIL $1 (expected: $2 | got: $3)"; fi
}
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi | awk '{print $1}'; }
treehash() { (cd "$1" && find . -type f -not -path './.git/*' | sort | while read -r f; do echo "$f $(sha < "$f")"; done | sha); }
newproj() { P="$TMP/$1"; mkdir -p "$P"; }
run() { OUT="$(bash "$INSTALL" "$@" 2>&1)"; RC=$?; }

# ---------- 1. empty project ----------
newproj empty
run "$P"
check "empty: exit 0" 0 "$RC"
check "empty: 20 files created" yes "$(echo "$OUT" | grep -q 'created=20' && echo yes || echo no)"
for f in CLAUDE.md .gitignore .claude/settings.json llm/PROJECT_STATE.md llm/KNOWN_ISSUES.md \
         llm/framework/RULES.md llm/framework/llm-records.md llm/framework/VERSION \
         .claude/hooks/lib.sh .claude/hooks/mark_dirty.sh; do
  check "empty: has $f" yes "$([ -f "$P/$f" ] && echo yes || echo no)"
done
check "empty: hooks executable" yes "$([ -x "$P/.claude/hooks/check_project_state.sh" ] && echo yes || echo no)"
check "empty: VERSION matches plugin.json" "$(jq -r .version "$PLUGIN/.claude-plugin/plugin.json")" "$(cat "$P/llm/framework/VERSION")"
check "empty: imports resolve" yes "$(cd "$P" && grep -o '^@.*' CLAUDE.md | while read -r i; do [ -f "${i#@}" ] || echo MISSING; done | grep -q MISSING && echo no || echo yes)"
check "empty: hooks are valid bash" yes "$(for h in "$P"/.claude/hooks/*.sh; do bash -n "$h" || echo BAD; done | grep -q BAD && echo no || echo yes)"
check "empty: settings valid JSON with 5 events" 5 "$(jq '.hooks|keys|length' "$P/.claude/settings.json")"
check "empty: tells user to fill placeholders" yes "$(echo "$OUT" | grep -q 'NEXT: fill in' && echo yes || echo no)"

# ---------- 2. idempotence ----------
H1="$(treehash "$P")"
run "$P"
check "idempotent: exit 0" 0 "$RC"
check "idempotent: nothing created/merged" yes "$(echo "$OUT" | grep -q 'created=0 merged=0' && echo yes || echo no)"
check "idempotent: tree byte-identical" "$H1" "$(treehash "$P")"

# ---------- 3. dry run writes nothing ----------
newproj dry
run --dry-run "$P"
check "dry-run: exit 0" 0 "$RC"
check "dry-run: reports plan" yes "$(echo "$OUT" | grep -q 'created=20.*dry run' && echo yes || echo no)"
check "dry-run: directory stays empty" 0 "$(ls -A "$P" | wc -l | tr -d ' ')"

# ---------- 4. existing project with its own files ----------
newproj existing
cd "$P" || exit 1
git init -q . && git config user.email t@t && git config user.name t
printf '# My App\n\nExisting instructions, no trailing newline' > CLAUDE.md
printf 'node_modules/\n.env' > .gitignore
mkdir -p .claude llm
cat > .claude/settings.json <<'EOF'
{
  "permissions": { "allow": ["Bash(npm test)"] },
  "env": { "FOO": "bar" },
  "hooks": {
    "Stop": [ { "hooks": [ { "type": "command", "command": "echo my-own-stop-hook" } ] } ],
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "echo guard" } ] } ]
  }
}
EOF
printf '# TODO\n- my real todo item\n' > llm/TODO.md
git add -A && git commit -q -m init
cd "$REPO" || exit 1
CLAUDE_BEFORE="$(cat "$P/CLAUDE.md")"
run "$P"
check "existing: exit 0" 0 "$RC"
check "existing: CLAUDE.md original content intact" yes "$(head -c ${#CLAUDE_BEFORE} "$P/CLAUDE.md" | cmp -s - <(printf '%s' "$CLAUDE_BEFORE") && echo yes || echo no)"
check "existing: CLAUDE.md gained import" yes "$(grep -qF '@llm/framework/RULES.md' "$P/CLAUDE.md" && echo yes || echo no)"
check "existing: CLAUDE.md has begin/end markers" 2 "$(grep -c 'llm-governance:\(begin\|end\)' "$P/CLAUDE.md")"
check "existing: CLAUDE.md placeholders NOT injected" no "$(grep -q 'One paragraph' "$P/CLAUDE.md" && echo yes || echo no)"
check "existing: no 'fill in placeholders' nag" no "$(echo "$OUT" | grep -q 'NEXT: fill in' && echo yes || echo no)"
check "existing: user llm/TODO.md untouched" "$(printf '# TODO\n- my real todo item\n')" "$(cat "$P/llm/TODO.md")"
check "existing: settings permissions kept" 'Bash(npm test)' "$(jq -r '.permissions.allow[0]' "$P/.claude/settings.json")"
check "existing: settings env kept" bar "$(jq -r '.env.FOO' "$P/.claude/settings.json")"
check "existing: user Stop hook kept" yes "$(jq -e '[.hooks.Stop[].hooks[].command]|index("echo my-own-stop-hook")' "$P/.claude/settings.json" >/dev/null && echo yes || echo no)"
check "existing: framework Stop hook added" yes "$(jq -e '[.hooks.Stop[].hooks[].command]|map(test("check_project_state"))|any' "$P/.claude/settings.json" >/dev/null && echo yes || echo no)"
check "existing: user PreToolUse kept" 1 "$(jq '.hooks.PreToolUse|length' "$P/.claude/settings.json")"
check "existing: PostToolUse matcher added" 'Edit|Write|MultiEdit|NotebookEdit' "$(jq -r '.hooks.PostToolUse[0].matcher' "$P/.claude/settings.json")"
check "existing: .gitignore originals kept" yes "$(grep -qx 'node_modules/' "$P/.gitignore" && grep -qx '.env' "$P/.gitignore" && echo yes || echo no)"
check "existing: .gitignore entries added" yes "$(grep -qxF '.claude/hooks/.state/' "$P/.gitignore" && grep -qxF '.claude/settings.local.json' "$P/.gitignore" && echo yes || echo no)"
H2="$(treehash "$P")"
run "$P"
check "existing: second run exit 0" 0 "$RC"
check "existing: second run changes nothing" "$H2" "$(treehash "$P")"
check "existing: no duplicate Stop entries" 2 "$(jq '.hooks.Stop|length' "$P/.claude/settings.json")"
check "existing: no duplicate .gitignore lines" 1 "$(grep -cxF '.claude/hooks/.state/' "$P/.gitignore")"
check "existing: no duplicate CLAUDE.md blocks" 1 "$(grep -c 'llm-governance:begin' "$P/CLAUDE.md")"

# ---------- 5. conflicts are reported and left untouched ----------
newproj conflict
run "$P"
echo "# locally modified hook" >> "$P/.claude/hooks/mark_dirty.sh"
echo "garbage" > "$P/llm/framework/RULES.md"
HC="$(treehash "$P")"
run "$P"
check "conflict: exit 2" 2 "$RC"
check "conflict: hook reported" yes "$(echo "$OUT" | grep -q 'CONFLICT.*mark_dirty.sh' && echo yes || echo no)"
check "conflict: RULES.md reported" yes "$(echo "$OUT" | grep -q 'CONFLICT.*RULES.md' && echo yes || echo no)"
check "conflict: nothing overwritten" "$HC" "$(treehash "$P")"

newproj badjson
mkdir -p "$P/.claude"; echo '{ not json' > "$P/.claude/settings.json"
run "$P"
check "invalid settings.json: exit 2" 2 "$RC"
check "invalid settings.json: left untouched" '{ not json' "$(cat "$P/.claude/settings.json")"

# ---------- 6. sandbox option ----------
newproj sandbox
run --sandbox "$P"
check "sandbox: devcontainer created" yes "$([ -f "$P/.devcontainer/devcontainer.json" ] && echo yes || echo no)"
newproj nosandbox
run "$P"
check "no sandbox flag: no .devcontainer" no "$([ -e "$P/.devcontainer" ] && echo yes || echo no)"

# ---------- 7. argument / environment errors ----------
run "$TMP/does-not-exist"
check "missing target: exit 1" 1 "$RC"
run
check "no args: exit 1" 1 "$RC"
run --bogus "$TMP"
check "unknown option: exit 1" 1 "$RC"
run "$PLUGIN"
check "refuses to install into the plugin itself: exit 1" 1 "$RC"
run "$PLUGIN/sandbox"
check "refuses subdir of the plugin: exit 1" 1 "$RC"
run --dry-run "$REPO"
check "repo root (parent of the plugin) is an allowed target: exit 0" 0 "$RC"
if ! PATH="/usr/bin:/bin" command -v jq >/dev/null 2>&1; then
  newproj nojq
  OUT="$(PATH="/usr/bin:/bin" bash "$INSTALL" "$P" 2>&1)"; RC=$?
  check "no jq: exit 1" 1 "$RC"
  check "no jq: explains fix" yes "$(echo "$OUT" | grep -q 'jq is required' && echo yes || echo no)"
  check "no jq: nothing written" 0 "$(ls -A "$P" | wc -l | tr -d ' ')"
fi

# ---------- 8. installed hooks actually work ----------
newproj behavior
run "$P"
export CLAUDE_PROJECT_DIR="$P"
cd "$P" || exit 1
echo '{"session_id":"T1"}' | bash .claude/hooks/session_start.sh >/dev/null
check "behavior: baseline hash recorded" yes "$([ -f .claude/hooks/.state/last_verified_hash ] && echo yes || echo no)"
echo "{\"tool_input\":{\"file_path\":\"$P/src/app.js\"}}" | bash .claude/hooks/mark_dirty.sh
echo '{"session_id":"T1"}' | bash .claude/hooks/check_project_state.sh >/dev/null 2>&1
check "behavior: edit + unchanged state blocks" 2 "$?"
echo "- did work" >> llm/PROJECT_STATE.md
echo '{"session_id":"T1"}' | bash .claude/hooks/check_project_state.sh >/dev/null 2>&1
check "behavior: updated state passes" 0 "$?"
cd "$REPO" || exit 1

echo
echo "passed=$PASS failed=$FAIL"
[ "$FAIL" = 0 ]
