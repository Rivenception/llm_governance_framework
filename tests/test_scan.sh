#!/bin/bash
# Tests for plugin/skills/adopt/scripts/scan.sh and the adopt installer wrapper.
# Run: bash tests/test_scan.sh   (needs bash, git, jq)

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$REPO/plugin"
SCAN="$PLUGIN/skills/adopt/scripts/scan.sh"
WRAP="$PLUGIN/skills/adopt/scripts/install.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0

check() { # name expected actual
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "PASS $1"
  else FAIL=$((FAIL+1)); echo "FAIL $1 (expected: $2 | got: $3)"; fi
}
has() { printf '%s' "$1" | grep -qF -- "$2" && echo yes || echo no; }
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi | awk '{print $1}'; }
treehash() { (cd "$1" && find . -type f | sort | while read -r f; do echo "$f $(sha < "$f")"; done | sha); }
gitinit() { git init -q . && git config user.email t@t && git config user.name t && git config core.autocrlf false; }

# ---------- fixture: Node/Express project with secrets lying around ----------
N="$TMP/node-app"; mkdir -p "$N/src/auth" "$N/src/api" "$N/tests" "$N/node_modules/leftpad" "$N/.github/workflows"
cd "$N" || exit 1; gitinit
cat > package.json <<'EOF'
{ "name": "acme-api", "version": "1.2.0", "main": "src/index.js",
  "scripts": { "start": "node src/index.js", "test": "jest", "deploy": "deploy --token abc123" },
  "dependencies": { "express": "^4.18.0", "pg": "^8.11.0", "jsonwebtoken": "^9.0.0" },
  "devDependencies": { "jest": "^29.0.0", "supertest": "^6.3.0" } }
EOF
printf '# Acme API\n\nA small REST API for managing projects.\n\nAdmin password: hunter2\n' > README.md
echo "console.log('hi')" > src/index.js; echo "x" > src/auth/tokens.js; echo "x" > src/api/projects.js
echo "test('a',()=>{})" > tests/projects.test.js
printf 'DATABASE_URL=postgres://u:SUPERSECRET@h/db\n' > .env
printf 'AWS_SECRET=ENVLOCALSECRET\n' > .env.local
printf 'FROM node:20\nENV API_KEY=DOCKERSECRET\nCMD ["node","src/index.js"]\n' > Dockerfile
printf -- '-----BEGIN PRIVATE KEY-----\nPEMSECRET\n' > server.pem
echo "module.exports=1" > node_modules/leftpad/index.js
printf 'name: ci\non: push\n' > .github/workflows/ci.yml
printf '# Acme\n\n## Style\nUse 2 spaces.\n' > CLAUDE.md
printf 'node_modules/\n' > .gitignore   # note: .env NOT gitignored on purpose
git add -A >/dev/null 2>&1; git commit -q -m "initial"; git commit -q --allow-empty -m "add auth tokens"
echo "uncommitted" > notes.txt
cd "$REPO" || exit 1

H_BEFORE="$(treehash "$N")"; GS_BEFORE="$(git -C "$N" status --porcelain)"
OUT="$(bash "$SCAN" "$N" 2>&1)"; RC=$?
check "node: exit 0" 0 "$RC"
check "node: scan is read-only (tree unchanged)" "$H_BEFORE" "$(treehash "$N")"
check "node: scan is read-only (git status unchanged)" "$GS_BEFORE" "$(git -C "$N" status --porcelain)"

for secret in SUPERSECRET ENVLOCALSECRET DOCKERSECRET PEMSECRET hunter2 abc123; do
  check "node: secret '$secret' not in output" no "$(has "$OUT" "$secret")"
done
check "node: redaction markers present" yes "$(has "$OUT" 'REDACTED')"
check "node: .env files not listed" no "$(printf '%s' "$OUT" | grep -E '(^|[ /-])\.env(\.local)?( |$)|DATABASE_URL' >/dev/null && echo yes || echo no)"
check "node: key file not listed" no "$(has "$OUT" 'server.pem')"
check "node: node_modules excluded" no "$(has "$OUT" 'leftpad')"
check "node: package name" yes "$(has "$OUT" 'name: acme-api')"
check "node: dependencies listed" yes "$(has "$OUT" 'dependencies: express, jsonwebtoken, pg')"
check "node: test script kept" yes "$(has "$OUT" 'test: jest')"
check "node: test file counted" yes "$(has "$OUT" '- test files: 1')"
check "node: CI detected" yes "$(has "$OUT" '.github/workflows/ci.yml')"
check "node: README title shown" yes "$(has "$OUT" '# Acme API')"
check "node: commit subject shown" yes "$(has "$OUT" 'add auth tokens')"
check "node: uncommitted count" yes "$(has "$OUT" 'uncommitted changes: 1')"
check "node: existing CLAUDE.md seen" yes "$(has "$OUT" 'CLAUDE.md (4 lines)')"
check "node: no scope/stack section detected" yes "$(has "$OUT" 'CLAUDE.md has NO scope/stack section')"
check "node: no llm/ folder noted" yes "$(has "$OUT" 'no llm/ folder')"
check "node: .js is top language" yes "$(printf '%s' "$OUT" | grep -A1 '^## Languages' | tail -1 | grep -q '\.js' && echo yes || echo no)"

# ---------- scope/stack section detection + already-installed detection ----------
M="$TMP/has-scope"; mkdir -p "$M"; cd "$M" || exit 1; gitinit
printf '# P\n\n## Project scope and stack\n- Node\n' > CLAUDE.md; git add -A >/dev/null 2>&1; git commit -q -m i
cd "$REPO" || exit 1
OUT="$(bash "$SCAN" "$M" 2>&1)"
check "scope: existing section detected" yes "$(has "$OUT" 'appears to have a scope/stack section')"

# installed project: scan notices framework + hook events + llm/ contents
I="$TMP/installed"; mkdir -p "$I"
bash "$PLUGIN/skills/init/scripts/install.sh" "$I" >/dev/null 2>&1
OUT="$(bash "$SCAN" "$I" 2>&1)"
check "installed: sees framework import" yes "$(has "$OUT" 'already imports the framework rules')"
check "installed: lists hook events" yes "$(has "$OUT" 'hook events: PostToolUse, PreCompact, SessionEnd, SessionStart, Stop')"
check "installed: lists llm/ files" yes "$(has "$OUT" 'llm/ already exists')"

# ---------- other project shapes ----------
P="$TMP/py"; mkdir -p "$P/app" "$P/tests"; cd "$P" || exit 1
printf '[project]\nname = "svc"\ndependencies = ["fastapi"]\n' > pyproject.toml
echo "x=1" > app/main.py; echo "def test_a(): pass" > tests/test_main.py
cd "$REPO" || exit 1
OUT="$(bash "$SCAN" "$P" 2>&1)"; RC=$?
check "python/non-git: exit 0" 0 "$RC"
check "python/non-git: says no git" yes "$(has "$OUT" '- git: no')"
check "python/non-git: pyproject shown" yes "$(has "$OUT" 'fastapi')"
check "python/non-git: test_*.py counted" yes "$(has "$OUT" '- test files: 1')"
check "python/non-git: .py language" yes "$(has "$OUT" '.py')"

E="$TMP/empty"; mkdir -p "$E"
OUT="$(bash "$SCAN" "$E" 2>&1)"; RC=$?
check "empty dir: exit 0" 0 "$RC"
check "empty dir: no manifests" yes "$(has "$OUT" '(none found)')"

# ---------- bounded output ----------
B="$TMP/big"; mkdir -p "$B"; cd "$B" || exit 1
for d in $(seq 1 60); do mkdir -p "d$d/s$d"; for f in $(seq 1 30); do : > "d$d/s$d/f$f.js"; done; done
cd "$REPO" || exit 1
OUT="$(bash "$SCAN" "$B" 2>&1)"
check "big repo: output bounded (<200 lines)" yes "$([ "$(printf '%s\n' "$OUT" | wc -l)" -lt 200 ] && echo yes || echo no)"
check "big repo: counts files" yes "$(has "$OUT" 'files (excluding ignored/vendored): 1800')"

# ---------- argument errors ----------
bash "$SCAN" >/dev/null 2>&1;            check "no args: exit 1" 1 "$?"
bash "$SCAN" "$TMP/nope" >/dev/null 2>&1; check "bad dir: exit 1" 1 "$?"

# ---------- adopt's installer wrapper ----------
W="$TMP/wrap"; mkdir -p "$W"
OUT="$(bash "$WRAP" --dry-run "$W" 2>&1)"; RC=$?
check "wrapper: dry run exit 0" 0 "$RC"
check "wrapper: plans 21 creates" yes "$(has "$OUT" 'created=21')"
check "wrapper: dry run wrote nothing" 0 "$(ls -A "$W" | wc -l | tr -d ' ')"
bash "$WRAP" "$W" >/dev/null 2>&1; check "wrapper: real install exit 0" 0 "$?"
check "wrapper: files installed" yes "$([ -f "$W/llm/framework/RULES.md" ] && echo yes || echo no)"
echo "tampered" >> "$W/.claude/hooks/lib.sh"
bash "$WRAP" "$W" >/dev/null 2>&1; check "wrapper: conflict exit code propagates (2)" 2 "$?"
bash "$WRAP" "$PLUGIN" >/dev/null 2>&1; check "wrapper: refuses the plugin dir (1)" 1 "$?"

echo
echo "passed=$PASS failed=$FAIL"
[ "$FAIL" = 0 ]
