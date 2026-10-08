#!/bin/bash
# Tests for plugin/skills/audit/scripts/audit.sh. Run: bash tests/test_audit.sh
# Each scenario breaks several independent things at once, then asserts every
# finding separately (an audit run is slow on Windows).

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$REPO/plugin"
AUDIT="$PLUGIN/skills/audit/scripts/audit.sh"
INSTALL="$PLUGIN/skills/init/scripts/install.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0

check() { # name expected actual
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "PASS $1"
  else FAIL=$((FAIL+1)); echo "FAIL $1 (expected: $2 | got: $3)"; fi
}
# lv LEVEL AREA SUBSTRING -> yes/no: a result line with that level/area containing the text
lv() { printf '%s\n' "$OUT" | awk -v l="$1" -v a="$2" -v s="$3" '$1==l && $2==a && index($0,s) {f=1} END{print f?"yes":"no"}'; }
has() { printf '%s' "$1" | grep -qF -- "$2" && echo yes || echo no; }
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi | awk '{print $1}'; }
treehash() { (cd "$1" && find . -type f -not -path './.git/*' | sort | while read -r f; do echo "$f $(sha < "$f")"; done | sha); }
aud() { OUT="$(bash "$AUDIT" "$@" 2>&1)"; RC=$?; }

# Some filesystems (Windows/Git Bash) report every .sh file as executable.
probe="$TMP/probe.sh"; printf '#!/bin/bash
' > "$probe"; chmod +x "$probe"; chmod -x "$probe"
if [ -x "$probe" ]; then CAN_UNEXEC=no; else CAN_UNEXEC=yes; fi

# ---- a committed, healthy base project; each scenario works on a copy ----
BASE="$TMP/base"; mkdir -p "$BASE"; cd "$BASE" || exit 1
git init -q . && git config user.email t@t && git config user.name t && git config core.autocrlf false
bash "$INSTALL" "$BASE" >/dev/null 2>&1
git add -A >/dev/null 2>&1; git commit -q -m install
cd "$REPO" || exit 1
fresh() { P="$TMP/$1"; cp -r "$BASE" "$P"; cd "$P" || exit 1; git config user.email t@t; git config user.name t; git config core.autocrlf false; }

# ================= healthy install =================
fresh healthy; cd "$REPO" || exit 1
aud --no-deep "$P"
check "healthy: exit 0" 0 "$RC"
check "healthy: no FAIL lines" 0 "$(printf '%s\n' "$OUT" | grep -c '^FAIL')"
check "healthy: records PASS" yes "$(lv PASS records 'all 8')"
check "healthy: imports PASS" yes "$(lv PASS claude-md 'imports the framework rules')"
check "healthy: settings PASS" yes "$(lv PASS settings 'all framework hook events registered')"
check "healthy: hooks PASS" yes "$(lv PASS hooks 'all 6 hook scripts')"
check "healthy: version PASS" yes "$(lv PASS version 'matches the plugin')"
check "healthy: line endings pinned" yes "$(lv PASS line-endings 'pinned to LF')"
check "healthy: integrity PASS" yes "$(lv PASS integrity 'match the install record')"
check "healthy: warns about placeholders" yes "$(lv WARN claude-md 'unfilled')"
check "healthy: warns PROJECT_STATE never stamped" yes "$(lv WARN health 'never been stamped')"
check "healthy: warns PROJECT_STATE blank template" yes "$(lv WARN health 'blank template')"
check "healthy: failures sorted before passes" yes "$(printf '%s\n' "$OUT" | awk '/^WARN/{w=NR} /^PASS/{if(!p)p=NR} END{print (w<p)?"yes":"no"}')"

# ================= several FAIL conditions at once =================
fresh broken
rm llm/TODO.md llm/framework/RULES.md .claude/hooks/mark_dirty.sh
echo 'this is not valid bash (((' >> .claude/hooks/lib.sh
sed -i '/@llm\/framework\/llm-records.md/d' CLAUDE.md
jq 'del(.hooks.Stop) | .hooks.PreCompact += [{"hooks":[{"type":"command","command":"bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/ghost.sh"}]}]' .claude/settings.json > s.tmp && mv s.tmp .claude/settings.json
echo '{}' > .claude/settings.local.json
sed -i '/settings.local.json/d' .gitignore
echo '{"date":"2026-01-01","session":"s","file":"a","type":"docs","summary":"ok"}' >> llm/CHANGES.jsonl
echo 'NOT JSON' >> llm/CHANGES.jsonl
mkdir -p .claude/hooks/.state && echo x > .claude/hooks/.state/dirty && git add -f .claude/hooks/.state/dirty >/dev/null 2>&1
cd "$REPO" || exit 1
aud --no-deep "$P"
check "broken: exit 2" 2 "$RC"
check "broken: missing record" yes "$(lv FAIL records 'llm/TODO.md')"
check "broken: missing RULES.md" yes "$(lv FAIL framework 'RULES.md missing')"
check "broken: missing import" yes "$(lv FAIL claude-md 'does not import @llm/framework/llm-records.md')"
check "broken: RULES import points at nothing" yes "$(lv FAIL claude-md 'RULES.md but that file does not exist')"
check "broken: missing hook script" yes "$(lv FAIL hooks 'mark_dirty.sh missing')"
check "broken: hook syntax error" yes "$(lv FAIL hooks 'lib.sh has a shell syntax error')"
check "broken: unregistered Stop" yes "$(lv FAIL settings 'hook for Stop is not registered')"
check "broken: stale hook reference" yes "$(lv FAIL settings 'ghost.sh')"
check "broken: settings.local.json not ignored" yes "$(lv FAIL secrets 'NOT git-ignored')"
check "broken: tracked hook state" yes "$(lv FAIL secrets 'tracked in git')"
check "broken: invalid CHANGES.jsonl" yes "$(lv FAIL health 'CHANGES.jsonl has 1 line')"
check "broken: SESSIONS.jsonl still fine" yes "$(lv PASS health 'SESSIONS.jsonl lines are valid JSON')"

# ================= settings.json invalid / missing =================
fresh badjson; echo '{ nope' > .claude/settings.json; cd "$REPO" || exit 1
aud --no-deep "$P"
check "settings invalid JSON: FAIL" yes "$(lv FAIL settings 'not valid JSON')"
check "settings invalid JSON: exit 2" 2 "$RC"
fresh nosettings; rm .claude/settings.json; cd "$REPO" || exit 1
aud --no-deep "$P"
check "settings missing: FAIL" yes "$(lv FAIL settings 'missing')"

# ================= several WARN conditions at once =================
fresh warns
sed -i '/llm-governance:\(begin\|end\)/d' CLAUDE.md
chmod -x .claude/hooks/session_start.sh
echo 0.0.1 > llm/framework/VERSION
printf '> **DRAFT, unconfirmed.** x\n' >> llm/ARCHITECTURE.md
printf '## [2026-01-01 10:00] older first\nx\n\n## [2026-02-01 10:00] newer second\nx\n' >> llm/CHANGELOG.md
echo '{"date":"2026-01-01","session":"s","file":"a","summary":"no type"}' >> llm/CHANGES.jsonl
echo '{"date":"2026-01-01","session":"s","file":"a","type":"weird","summary":"bad type"}' >> llm/CHANGES.jsonl
printf '\n## [2026-01-01] x\nSeverity: low\nStatus: pending\n' >> llm/KNOWN_ISSUES.md
sed -i '/hooks\/.state/d' .gitignore
git rm -q --cached .gitattributes; rm -f .gitattributes   # git check-attr falls back to the index otherwise
cd "$REPO" || exit 1
aud --no-deep "$P"
check "warns: exit 0 (warnings are not failures)" 0 "$RC"
check "warns: missing markers" yes "$(lv WARN claude-md 'no markers')"
if [ "$CAN_UNEXEC" = yes ]; then
  check "warns: hook not executable" yes "$(lv WARN hooks 'session_start.sh is not executable')"
else
  echo "SKIP warns: hook not executable (this filesystem cannot clear the executable bit)"
fi
check "warns: version behind" yes "$(lv WARN version 'behind the plugin')"
check "warns: DRAFT still marked" yes "$(lv WARN health 'ARCHITECTURE.md')"
check "warns: CHANGELOG order" yes "$(lv WARN health 'not newest-first')"
check "warns: CHANGES missing key" yes "$(lv WARN health 'missing a required key')"
check "warns: CHANGES bad type" yes "$(lv WARN health 'type outside')"
check "warns: KNOWN_ISSUES status" yes "$(lv WARN health 'Status line')"
check "warns: LF rules missing" yes "$(lv WARN line-endings 'not pinned to LF')"
check "warns: state dir not ignored" yes "$(lv WARN secrets 'not git-ignored')"

# ================= Windows (CRLF) line endings =================
fresh crlf
sed -i 's/$/\r/' .claude/hooks/lib.sh
cd "$REPO" || exit 1
aud --no-deep "$P"
check "CRLF hook: FAIL names the real cause" yes "$(lv FAIL hooks 'lib.sh has Windows (CRLF) line endings')"
check "CRLF hook: FAIL gives the fix" yes "$(has "$OUT" "sed -i 's/\\r\$//'")"
check "CRLF hook: not reported as a generic syntax error" no "$(lv FAIL hooks 'syntax error')"
check "CRLF hook: integrity warning marks it CRLF" yes "$(lv WARN integrity 'lib.sh(CRLF)')"
check "CRLF hook: exit 2" 2 "$RC"

fresh crlfmd
sed -i 's/$/\r/' CLAUDE.md
cd "$REPO" || exit 1
aud --no-deep "$P"
check "CRLF CLAUDE.md: imports still recognised" yes "$(lv PASS claude-md 'imports the framework rules')"
check "CRLF CLAUDE.md: block not reported as edited" no "$(lv WARN integrity 'CLAUDE.md framework block was edited')"
check "CRLF CLAUDE.md: still no FAIL" 0 "$(printf '%s\n' "$OUT" | grep -c '^FAIL')"

# ================= integrity / version / stamp =================
fresh integ
echo "# my change" >> .claude/hooks/lib.sh
sed -i 's/Use that exact session ID/Use THE session ID/' CLAUDE.md
echo 9.9.9 > llm/framework/VERSION
sed -i 's/^Last updated:.*/Last updated: 2026-10-07 10:00 | Session: abc/' llm/PROJECT_STATE.md
cd "$REPO" || exit 1
aud --no-deep "$P"
check "integrity: edited hook named" yes "$(lv WARN integrity 'lib.sh')"
check "integrity: edited CLAUDE.md block" yes "$(lv WARN integrity 'CLAUDE.md framework block was edited')"
check "version: newer than plugin" yes "$(lv WARN version 'newer than this plugin')"
check "stamped PROJECT_STATE passes" yes "$(lv PASS health 'Last updated stamp')"

# ================= no manifest, no stamp line, placeholders filled =================
fresh legacy
rm llm/framework/MANIFEST
sed -i '/^Last updated:/d' llm/PROJECT_STATE.md
sed -i 's/\[\.\.\.\]/x/g; s/\[One paragraph[^]]*\]/x/; s/\[e\.g\. [^]]*\]/x/g' CLAUDE.md
cd "$REPO" || exit 1
aud --no-deep "$P"
check "no manifest: WARN" yes "$(lv WARN framework 'no llm/framework/MANIFEST')"
check "no Last updated line: WARN" yes "$(lv WARN health "no 'Last updated:' line")"
check "placeholders filled: PASS" yes "$(lv PASS claude-md 'no unfilled placeholders')"

# ================= git conditions =================
fresh nogit; rm -rf .git; cd "$REPO" || exit 1
aud --no-deep "$P"
check "non-git: WARN" yes "$(lv WARN git 'not a git repository')"
check "non-git: exit 0" 0 "$RC"

fresh history
printf '## [2026-03-01 10:00] first\nx\n\n## [2026-02-01 10:00] second\nx\n' >> llm/CHANGELOG.md
git add -A >/dev/null 2>&1; git commit -q -m "two entries"
sed -i '/second/,+1d' llm/CHANGELOG.md
git add -A >/dev/null 2>&1; git commit -q -m "delete an entry"
cd "$REPO" || exit 1
aud --no-deep "$P"
check "add-only violated in history: WARN" yes "$(lv WARN git 'CHANGELOG.md had')"

fresh appendonly
printf '## [2026-03-01 10:00] first\nx\n' >> llm/CHANGELOG.md
git add -A >/dev/null 2>&1; git commit -q -m "add entry"
cd "$REPO" || exit 1
aud --no-deep "$P"
check "add-only respected: no history WARN" no "$(lv WARN git 'had')"

# ================= deep functional check =================
fresh deep
cd "$REPO" || exit 1
H0="$(treehash "$P")"; GS0="$(git -C "$P" status --porcelain)"
aud "$P"
check "deep healthy: exit 0" 0 "$RC"
check "deep: SessionStart" yes "$(lv PASS deep 'SessionStart injects')"
check "deep: dirty marking" yes "$(lv PASS deep 'marks the turn dirty')"
check "deep: Stop blocks" yes "$(lv PASS deep 'Stop blocks')"
check "deep: Stop releases" yes "$(lv PASS deep 'Stop passes once PROJECT_STATE changes')"
check "deep: Q&A turn not blocked" yes "$(lv PASS deep 'question-only turn is not blocked')"
check "read-only: project tree unchanged by a full audit" "$H0" "$(treehash "$P")"
check "read-only: git status unchanged" "$GS0" "$(git -C "$P" status --porcelain)"

fresh sabotage
sed -i 's/exit 2/exit 0/g' .claude/hooks/check_project_state.sh
cd "$REPO" || exit 1
aud "$P"
check "sabotaged Stop hook: deep FAIL" yes "$(lv FAIL deep 'Stop did not block')"
check "sabotaged Stop hook: integrity WARN too" yes "$(lv WARN integrity 'check_project_state.sh')"
check "sabotaged Stop hook: exit 2" 2 "$RC"

fresh deepskip; rm .claude/hooks/mark_dirty.sh; cd "$REPO" || exit 1
aud "$P"
check "deep skipped when a hook is missing" yes "$(lv INFO deep 'skipped')"

# ================= json output =================
fresh json; cd "$REPO" || exit 1
OUT="$(bash "$AUDIT" --json --no-deep "$P" 2>&1)"; RC=$?
check "json: valid" yes "$(printf '%s' "$OUT" | jq -e . >/dev/null 2>&1 && echo yes || echo no)"
check "json: summary matches results" yes "$(printf '%s' "$OUT" | jq -e '.summary.pass == ([.results[]|select(.level=="PASS")]|length) and .summary.fail == 0' >/dev/null 2>&1 && echo yes || echo no)"
check "json: results have level/area/message" yes "$(printf '%s' "$OUT" | jq -e '.results | all(has("level") and has("area") and has("message"))' >/dev/null 2>&1 && echo yes || echo no)"

# ================= environment / arguments =================
mkdir -p "$TMP/notinstalled"; aud "$TMP/notinstalled"
check "not installed: exit 1" 1 "$RC"
check "not installed: explains" yes "$(printf '%s' "$OUT" | grep -q 'init or adopt' && echo yes || echo no)"
aud; check "no args: exit 1" 1 "$RC"
aud "$TMP/nope"; check "missing dir: exit 1" 1 "$RC"
aud --bogus "$P"; check "unknown option: exit 1" 1 "$RC"
if ! PATH="/usr/bin:/bin" command -v jq >/dev/null 2>&1; then
  OUT="$(PATH="/usr/bin:/bin" bash "$AUDIT" "$P" 2>&1)"; RC=$?
  check "no jq: FAIL tooling" yes "$(lv FAIL tooling 'jq is not installed')"
  check "no jq: settings skipped, not crashed" yes "$(lv INFO settings 'skipped')"
  check "no jq: exit 2" 2 "$RC"
fi

# ================= hooks stamp UTC, whatever the machine time zone =================
# Pacific/Kiritimati is UTC+14 and Pacific/Pago_Pago is UTC-11, so local time
# differs from UTC by a different date at the same moment. Compare to date -u
# taken just before and just after (the minute may roll over in between).
fresh tz; HK="$P/.claude/hooks"
utc_ok() { # stamp-prefix check against date -u before/after
  case "$1" in "$B"*|"$E"*) echo yes ;; *) echo no ;; esac
}
for ZONE in Pacific/Kiritimati Pacific/Pago_Pago; do
  B="$(date -u '+%Y-%m-%d %H:%M')"
  OUTJ="$(echo '{"session_id":"tz-s"}' | TZ=$ZONE CLAUDE_PROJECT_DIR="$P" bash "$HK/session_start.sh")"
  E="$(date -u '+%Y-%m-%d %H:%M')"
  GOT="$(printf '%s' "$OUTJ" | jq -r '.hookSpecificOutput.additionalContext' | tr -d '\r' | sed -n 's/.*Session started: \([0-9-]* [0-9:]*\) UTC\..*/\1/p')"
  check "SessionStart injects UTC ($ZONE)" yes "$(utc_ok "$GOT")"
  check "SessionStart tells the assistant to use date -u ($ZONE)" yes "$(has "$OUTJ" 'date -u')"
  # Stop hook stamp: mark dirty, change the body, run the hook
  mkdir -p "$P/.claude/hooks/.state"; : > "$P/.claude/hooks/.state/dirty"
  echo "tz run $ZONE" >> "$P/llm/PROJECT_STATE.md"
  B="$(date -u '+%Y-%m-%d %H:%M')"
  echo '{}' | TZ=$ZONE CLAUDE_PROJECT_DIR="$P" bash "$HK/check_project_state.sh" >/dev/null 2>&1
  E="$(date -u '+%Y-%m-%d %H:%M')"
  GOT="$(grep '^Last updated:' "$P/llm/PROJECT_STATE.md" | tr -d '\r' | sed -n 's/^Last updated: \([0-9-]* [0-9:]*\) |.*/\1/p')"
  check "Stop hook stamps UTC ($ZONE)" yes "$(utc_ok "$GOT")"
  # SessionEnd log line (seconds precision; compare date and hour:minute)
  : > "$P/llm/SESSIONS.jsonl"
  B="$(date -u '+%Y-%m-%dT%H:%M')"
  echo '{"session_id":"tz-s","reason":"other"}' | TZ=$ZONE CLAUDE_PROJECT_DIR="$P" bash "$HK/log_session_end.sh" >/dev/null 2>&1
  E="$(date -u '+%Y-%m-%dT%H:%M')"
  GOT="$(jq -r '.date' "$P/llm/SESSIONS.jsonl" | tr -d '\r' | cut -c1-16)"
  check "SessionEnd logs UTC ($ZONE)" yes "$(utc_ok "$GOT")"
done
cd "$REPO" || exit 1
aud --no-deep "$P"
check "audit: stamp form PASS" yes "$(lv PASS health 'YYYY-MM-DD HH:MM form')"
sed -i 's/^Last updated:.*/Last updated: yesterday-ish | Session: x/' "$P/llm/PROJECT_STATE.md"
aud --no-deep "$P"
check "audit: odd stamp form WARN" yes "$(lv WARN health 'not in the YYYY-MM-DD HH:MM form')"

echo
echo "passed=$PASS failed=$FAIL"
[ "$FAIL" = 0 ]
