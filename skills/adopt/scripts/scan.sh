#!/bin/bash
# scan.sh -- read-only scan of an existing project, for drafting
# llm/ARCHITECTURE.md and llm/PROJECT_STATE.md.
#
# Usage: scan.sh <project-dir>
#
# Guarantees:
#   - Writes nothing.
#   - Reads only a whitelist of well-known manifest/config/README files plus
#     file NAMES from the project listing. It never opens .env files, keys,
#     certificates, or source code.
#   - Lines that look like secrets (password/secret/token/api key/credential/
#     private) are replaced with a redaction marker in everything it prints.
#   - Output is bounded.
#
# Output is plain markdown sections ("## ...") for a human or an assistant.

set -u
export LC_ALL=C

ROOT="${1:-}"
if [ -z "$ROOT" ] || [ ! -d "$ROOT" ]; then
  echo "usage: scan.sh <project-dir>" >&2
  exit 1
fi
cd "$ROOT" || exit 1
ROOT="$(pwd)"

HAS_GIT=0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && HAS_GIT=1
HAS_JQ=0
command -v jq >/dev/null 2>&1 && HAS_JQ=1

IGNORE_DIRS='(^|/)(node_modules|vendor|dist|build|target|out|\.venv|venv|env|__pycache__|\.next|\.nuxt|coverage|\.gradle|\.idea|\.vscode|bin/Debug|obj)/'

list_files() {
  if [ "$HAS_GIT" = 1 ]; then
    git ls-files --cached --others --exclude-standard 2>/dev/null
  else
    find . -type f -not -path './.git/*' 2>/dev/null | sed 's|^\./||'
  fi
}

FILES="$(list_files | grep -vE "$IGNORE_DIRS" | grep -vE '(^|/)\.env($|\.)|\.(pem|key|p12|pfx|crt)$|(^|/)id_(rsa|ed25519)' )"
NFILES="$(printf '%s\n' "$FILES" | grep -c .)"

# Print a file's first N lines with secret-looking lines redacted.
show() { # file [lines]
  head -n "${2:-40}" "$1" 2>/dev/null | sed -E 's/.*([Pp][Aa][Ss][Ss]([Ww][Oo][Rr][Dd]|[Ww][Dd])?|[Ss][Ee][Cc][Rr][Ee][Tt]|[Tt][Oo][Kk][Ee][Nn]|[Aa][Pp][Ii][_-]?[Kk][Ee][Yy]|[Cc][Rr][Ee][Dd][Ee][Nn][Tt][Ii][Aa][Ll]|[Pp][Rr][Ii][Vv][Aa][Tt][Ee]).*/[REDACTED: line looked like a secret]/'
}

echo "# Project scan"
echo
echo "## Overview"
echo "- root: $ROOT"
echo "- name: $(basename "$ROOT")"
echo "- files (excluding ignored/vendored): $NFILES"
if [ "$HAS_GIT" = 1 ]; then
  echo "- git: yes, branch $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  echo "- commits: $(git rev-list --count HEAD 2>/dev/null || echo 0)"
  echo "- uncommitted changes: $(git status --porcelain 2>/dev/null | grep -c .)"
  echo "- recent commit subjects:"
  git log -n 8 --format='  - %s' 2>/dev/null
else
  echo "- git: no"
fi

echo
echo "## Existing assistant/governance config"
for f in CLAUDE.md AGENTS.md GEMINI.md .cursorrules .github/copilot-instructions.md; do
  [ -f "$f" ] && echo "- $f ($(grep -c '' "$f") lines)"
done
if [ -f CLAUDE.md ]; then
  echo "- CLAUDE.md headings:"
  grep -E '^#{1,3} ' CLAUDE.md | head -30 | sed 's/^/  /'
  if grep -qF '@llm/framework/RULES.md' CLAUDE.md; then echo "- CLAUDE.md already imports the framework rules"; fi
  if grep -qiE '^#{1,3} .*(scope|stack)' CLAUDE.md; then echo "- CLAUDE.md appears to have a scope/stack section"; else echo "- CLAUDE.md has NO scope/stack section"; fi
else
  echo "- no CLAUDE.md"
fi
if [ -f .claude/settings.json ]; then
  if [ "$HAS_JQ" = 1 ] && jq -e . .claude/settings.json >/dev/null 2>&1; then
    echo "- .claude/settings.json hook events: $(jq -r '(.hooks // {}) | keys | join(", ")' .claude/settings.json)"
  else
    echo "- .claude/settings.json present (not parsed)"
  fi
fi
[ -f .claude/settings.local.json ] && echo "- .claude/settings.local.json present (contents not read)"
if [ -d llm ]; then
  echo "- llm/ already exists: $(ls llm | tr '\n' ' ')"
else
  echo "- no llm/ folder"
fi
[ -d .devcontainer ] && echo "- .devcontainer/ present"

echo
echo "## Languages (by file extension, top 12)"
printf '%s\n' "$FILES" | grep -vE '(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|poetry\.lock|Gemfile\.lock|composer\.lock)$' \
  | awk -F/ '{ n=$NF; if (n ~ /\./) { sub(/.*\./,"",n); c["."n]++ } }
             END { for (k in c) print c[k], k }' | sort -rn | head -12 | sed 's/^/- /'

echo
echo "## Layout (file counts)"
echo "top level:"
printf '%s\n' "$FILES" | awk -F/ '{ if (NF==1) a["(files in root)"]++; else a[$1"/"]++ } END { for (k in a) print a[k], k }' | sort -rn | head -25 | sed 's/^/- /'
echo "second level (largest 20):"
printf '%s\n' "$FILES" | awk -F/ 'NF>=3 { a[$1"/"$2"/"]++ } END { for (k in a) print a[k], k }' | sort -rn | head -20 | sed 's/^/- /'

echo
echo "## Manifests and build/config files (depth <= 3)"
MANIFEST_RE='(^|/)(package\.json|pyproject\.toml|requirements[^/]*\.txt|setup\.py|setup\.cfg|Pipfile|go\.mod|Cargo\.toml|Gemfile|composer\.json|pom\.xml|build\.gradle(\.kts)?|settings\.gradle(\.kts)?|Makefile|Dockerfile|docker-compose[^/]*\.ya?ml|tsconfig\.json|[^/]*\.csproj|[^/]*\.sln)$'
MANIFESTS="$(printf '%s\n' "$FILES" | grep -E "$MANIFEST_RE" | awk -F/ 'NF<=4' | head -25)"
if [ -z "$MANIFESTS" ]; then
  echo "(none found)"
else
  while IFS= read -r m; do
    echo
    echo "### $m"
    case "$(basename "$m")" in
      package.json)
        if [ "$HAS_JQ" = 1 ] && jq -e . "$m" >/dev/null 2>&1; then
          echo "name: $(jq -r '.name // "-"' "$m")  version: $(jq -r '.version // "-"' "$m")  type: $(jq -r '.type // "-"' "$m")  main: $(jq -r '.main // "-"' "$m")"
          echo "scripts:"; jq -r '(.scripts // {}) | to_entries[] | "  \(.key): \(.value)"' "$m" | head -25 | sed -E 's/.*([Tt][Oo][Kk][Ee][Nn]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Pp][Aa][Ss][Ss]).*/  [REDACTED]/'
          echo "dependencies: $(jq -r '(.dependencies // {}) | keys | join(", ")' "$m" | cut -c1-600)"
          echo "devDependencies: $(jq -r '(.devDependencies // {}) | keys | join(", ")' "$m" | cut -c1-600)"
        else
          show "$m" 60
        fi ;;
      *) show "$m" 40 ;;
    esac
  done <<< "$MANIFESTS"
fi

echo
echo "## Tests and CI"
TESTS="$(printf '%s\n' "$FILES" | grep -E '(^|/)(test|tests|__tests__|spec|specs|e2e)/|(\.|_)(test|spec)\.[A-Za-z]+$|(^|/)test_[^/]*\.py$|_test\.go$')"
echo "- test files: $(printf '%s\n' "$TESTS" | grep -c .)"
printf '%s\n' "$TESTS" | head -8 | sed 's/^/  - /'
CI="$(printf '%s\n' "$FILES" | grep -E '^\.github/workflows/|^\.gitlab-ci\.yml$|^Jenkinsfile$|^\.circleci/|^azure-pipelines|^\.travis\.yml$|^bitbucket-pipelines\.yml$')"
if [ -n "$CI" ]; then echo "- CI config:"; printf '%s\n' "$CI" | head -10 | sed 's/^/  - /'; else echo "- CI config: none found"; fi

echo
echo "## README"
README="$(printf '%s\n' "$FILES" | grep -iE '^readme(\.md|\.rst|\.txt)?$' | head -1)"
if [ -n "$README" ]; then
  echo "($README, first 30 lines)"
  show "$README" 30
else
  echo "(no README in project root)"
fi

echo
echo "## Notes"
echo "- Source code and .env/secret files were not read. Read specific source files yourself when drafting."
exit 0
