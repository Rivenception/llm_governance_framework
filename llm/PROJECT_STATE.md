# Project State
Last updated: 2026-10-07 16:49 | Session: 115017e7-19b7-45eb-8573-d45f62282310
> **DRAFT, unconfirmed.** Generated from a read-only scan on 2026-10-07 (session d1296834-35c7-4ccc-8532-1203a6fefad0) and updated by hand since. The owner has not reviewed it yet. Verify before relying on it; delete this line once reviewed.

## Status
Shell-script and Markdown project: the Claude Code plugin `llm-governance` (skills `init`, `adopt`, `update`, `audit`), in `plugin/`. The repo root is an ordinary project that governs itself with the same framework.
- **Published on GitHub (origin/master):** plugin 0.5.0, released with the commit that pushed it: the Windows line-ending protection, the update dry-run version stamp, the skill preflight fixes, the `.devcontainer` fix for `update`, the filled-in root CLAUDE.md and the llm/ records. Earlier published: 0.4.0 (the `plugin/` layout).
- **Not yet verified:** the published 0.5.0 against real GitHub (two-step plugin update, then `/llm-governance:update` on a project). Run that first.
- **Tests (Linux dev container):** install 75, update 110, scan 47, audit 79 all pass; `claude plugin validate` passes for the marketplace and the plugin. Windows runs the same suites in minutes.
- **Audit of the repo root:** 0 failures, 1 warning (the two adoption drafts are unreviewed).

## What just happened (this session)
- Published 0.5.0 (commit and push).
- Restructured the repo so the plugin lives in `plugin/` (released as 0.4.0); verified install, update and validation against the real GitHub repo.
- Adopted the framework in this repo with the real `adopt` skill (dogfooding). That found and fixed bugs in the skills' preflight and `update` (see KNOWN_ISSUES).
- Added Windows line-ending protection (LF rules in the project's .gitattributes via init/adopt/update; audit diagnoses CRLF) and several CRLF fixes; made the update dry run list the version stamp.
- Logged the session's bugs in llm/KNOWN_ISSUES.md, the open items in llm/TODO.md, decisions in llm/DECISIONS.md.
- Prepared 0.5.0 and ran the upgrade on this repo (framework stamp 0.4.0 -> 0.5.0).
- Filled in the root CLAUDE.md (overview, commands, scope and stack with the owner's out-of-scope choices, and a "Working in this repo" section with an interim UTC timestamp rule).

## Current state of the codebase
- `plugin/` is the product: `.claude-plugin/plugin.json` (version, now 0.5.0 in the working tree), `skills/{init,adopt,update,audit}` (SKILL.md plus scripts; shared helpers in `skills/init/scripts/lib.sh`), `core/`, `adapters/claude-code/`, `templates/llm/`, `sandbox/` (scaffold: firewall and Dockerfile are empty placeholders), `CHANGELOG.md`.
- The root holds `docs/`, `examples/`, `tests/`, `README.md`, `.claude-plugin/marketplace.json` (source `./plugin`), and this repo's own installed framework (`.claude/`, `llm/`, `CLAUDE.md`). The installed copies are managed by `update`: edit the sources in `plugin/`, never the copies.
- Working tree clean except the untracked `.devcontainer/` (undecided).
- No CI, no license.

## Next recommended task
1. Owner reviews the root CLAUDE.md and confirms the two drafts (delete their DRAFT lines).
2. Verify the published 0.5.0 against real GitHub in the dev container: `claude plugin marketplace update llm-governance`, then `claude plugin update llm-governance@llm-governance`, then `/llm-governance:update` on a project installed at an older version; confirm the new `.gitattributes` rules arrive and the version stamp moves.
3. Then see llm/TODO.md: sandbox module, license, timestamp convention, CI.

## Open risks / questions
- `.devcontainer/` is untracked and undecided; no license chosen.
- Which hook events Claude Code reloads mid-session is unverified (the skills' "starts in a new session" text may be wrong).
- One garbled `.gitattributes` was seen once on the Windows bind mount and never reproduced; appends are now single writes.
- Timestamps: this repo uses UTC (interim rule in CLAUDE.md); the Stop hook's PROJECT_STATE stamp is machine-local.
- Interactive (non -p) skill use and non-`user` plugin scopes are untested.

## How to resume
- Read `CLAUDE.md`, then `llm/TODO.md`, `llm/KNOWN_ISSUES.md` and `llm/ARCHITECTURE.md` (draft).
- Run the suites in the dev container (VS Code "Reopen in Container"; find it with `docker ps`): `docker exec -u vscode <id> bash -c 'cd /workspaces/llm-governance-framework && bash tests/test_install.sh'` (also test_update, test_scan, test_audit). They take seconds there and minutes on Windows.
- Tooling quirks that cost time: in Git Bash set `MSYS_NO_PATHCONV=1` for docker commands with `/tmp` paths but not for scripts that run the Windows `jq` on the host; the Bash tool collapses double backslashes in commands, so use the Edit/Write tools for content with backslashes and check for stray CR bytes; never use grep to detect CRs on Git Bash.
- Hooks are active in sessions here: after Edit/Write on project files the Stop hook blocks until this file's content changes.
