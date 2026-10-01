# Starting a new project with Claude Code — checklist

Run through this before (or right at) the start of real work on a new repo.

## 1. Confirm folder structure
- [ ] `llm/PROJECT_STATE.md` exists
- [ ] `llm/CHANGELOG.md` exists
- [ ] `llm/CHANGES.jsonl` exists
- [ ] `llm/DECISIONS.md` exists
- [ ] `llm/ARCHITECTURE.md` exists
- [ ] `llm/TODO.md` exists
- [ ] `llm/KNOWN_ISSUES.md` exists
- [ ] `llm/SESSIONS.jsonl` exists (or let the SessionEnd hook create it)
If missing, copy from `templates/llm/` in this framework, or ask
Claude: "set up the llm/ change-tracking folder from my standard template."

## 2. Confirm CLAUDE.md
- [ ] `CLAUDE.md` exists at repo root and `@imports` `llm/framework/RULES.md` and `llm/framework/llm-records.md`
- [ ] `llm/framework/RULES.md` and `llm/framework/llm-records.md` both exist
- [ ] Project overview, commands, and project scope/stack sections are
      filled in (not placeholder text)
- [ ] `llm/framework/RULES.md` contains the decision-ownership,
      architectural-change-protocol, uncertainty-handling, and personal
      data sections. These govern behavior, not just file tracking, and
      are worth a periodic re-read. The sensitive-data section covers the
      application's own user data, distinct from the framework-secrets
      rule in section 4 below

## 3. Confirm hooks are wired up
- [ ] `.claude/settings.json` exists in this repo (not just globally)
- [ ] `.claude/hooks/lib.sh`, `session_start.sh`, `mark_dirty.sh`,
      `check_project_state.sh`, `check_precompact.sh`, and
      `log_session_end.sh` are all present
- [ ] `jq` is installed (`jq --version`) — hooks fail visibly without it
- [ ] Scripts are executable: `chmod +x .claude/hooks/*.sh`
- [ ] Quick test: ask Claude to edit any source file, then confirm it is
      blocked from finishing the turn until PROJECT_STATE.md really
      changes. A pure question turn should NOT be blocked
- [ ] Quick test: run `/exit` and confirm a line was appended to
      `llm/SESSIONS.jsonl`

## 4. Confirm secrets are protected
- [ ] `.gitignore` includes `.claude/settings.local.json` — add it manually,
      don't assume Claude Code does this automatically (it's inconsistent)
- [ ] Any tokens/keys used in hooks or MCP config live in
      `.claude/settings.local.json`, never in the committed `.claude/settings.json`
- [ ] Run `git status` before your first commit on a new project and check
      nothing sensitive is staged

## 5. Confirm global setup (one-time, not per-project)
- [ ] `~/.claude/CLAUDE.md` includes the global pointer snippet

## 6. Session anchor
- [ ] No action needed — the Stop hook auto-stamps the session ID and
      timestamp onto `PROJECT_STATE.md`'s header line every time it fires.
      Just confirm the header line reads `Last updated: ... | Session: ...`
      with a real value (not "unknown") after your first session — if it
      says "unknown," `jq` likely isn't installed, or this Claude Code
      version doesn't expose `session_id` on the Stop hook yet.

## Why this exists
This exists so I (or a future collaborator) can reconstruct AI-driven
decisions without re-reading every diff. A missing step here isn't fatal,
but it's the difference between a project with a real audit trail and one
that quietly loses its reasoning the moment the session window scrolls past it.
