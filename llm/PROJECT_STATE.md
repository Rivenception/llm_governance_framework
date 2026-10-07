# Project State
Last updated: (auto-stamped by the Stop hook)
> **DRAFT, unconfirmed.** Generated from a read-only scan on 2026-10-07 (session d1296834-35c7-4ccc-8532-1203a6fefad0). Verify before relying on it; delete this line once reviewed.

## Status
Shell-script and Markdown project: the Claude Code plugin `llm-governance`
v0.4.0 (with an "Unreleased" changelog entry about the `update` dry run).
Four test suites exist under `tests/`; they were not run in this session.
The framework was just adopted into this repo.

## What just happened (this session)
- Adopted the framework into the repo root: 20 files created (`llm/`,
  `llm/framework/`, `.claude/`, `CLAUDE.md`, `.gitignore`), nothing merged or conflicting.
- Drafted `llm/ARCHITECTURE.md` and this file, both unconfirmed.
- Scope-and-stack proposal presented in chat only; not written to `CLAUDE.md`.
- Nothing staged or committed. `.devcontainer/` was left untracked on purpose.

## Current state of the codebase
- `plugin/` is the product; `docs/`, `tests/`, `examples/`, `README.md` and
  `.claude-plugin/marketplace.json` are the project around it.
- Recent commits: version-stamp change listed in the update dry-run plan;
  CHANGELOG 0.3.0 heading restored; plugin moved into `plugin/` (0.4.0).
- No CI configuration found.

## Next recommended task
Review and confirm (or correct) the two drafts and the scope/stack proposal,
fill the `[...]` placeholders in `CLAUDE.md`, then commit the adoption as one commit.

## Open risks / questions
- Hooks are read at session start; enforcement begins in a new session.
- `.devcontainer/` is untracked and undecided.
- `README.md` says bootstrapping into existing projects is "not automated yet",
  which may be stale given the `adopt` skill.
- Tests not run, so build/test health is unknown.

## How to resume
Read `CLAUDE.md`, then `llm/ARCHITECTURE.md` (draft). Run `bash tests/test_install.sh`
(needs bash, git, jq) to check the baseline.
