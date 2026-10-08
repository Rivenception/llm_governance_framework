# Project State
Last updated: 2026-10-07 17:08 | Session: 115017e7-19b7-45eb-8573-d45f62282310

## Status
Shell-script and Markdown project: the Claude Code plugin `llm-governance` (skills `init`, `adopt`, `update`, `audit`), in `plugin/`. The repo root is an ordinary project that governs itself with the same framework.
- **Published on GitHub (origin/master, 782c315):** plugin 0.6.0 (UTC timestamps everywhere; verified 2026-10-08 by installing from GitHub and running the live update on a 0.5.0 project) on top of 0.5.0 (Windows line-ending protection, update dry-run version stamp, skill preflight fixes, `.devcontainer` fix for `update`, clearer unreadable-manifest error), the filled-in root CLAUDE.md and the llm/ records. Earlier published: 0.4.0 (the `plugin/` layout).
- **Verified against real GitHub (2026-10-07):** `marketplace update` + `plugin update` took 0.4.0 to 0.5.0 (lean cache, executable scripts, CHANGELOG headings correct), and `/llm-governance:update` on a project installed before the rules created its `.gitattributes` with the LF rules (no CRs, `git check-attr` reports eol=lf), advanced the stamp and recorded the update; the audit of that project had 0 failures.
- **Tests (Linux dev container):** install 75, update 110, scan 47, audit 79 all pass; `claude plugin validate` passes for the marketplace and the plugin. Windows runs the same suites in minutes.
- **Audit of the repo root:** 0 failures. The owner has reviewed `llm/ARCHITECTURE.md` and this file and removed their DRAFT lines.

## What just happened (this session)
- Pushed 0.6.0 (782c315) and verified it: fresh install from GitHub gives 0.6.0; live update on a project installed by the real 0.5.0 installer worked with no conflicts. A pinned older marketplace ref needs a branch or tag, so the plugin-level 0.5.0 -> 0.6.0 hop was not repeated.
- Implemented the UTC timestamp convention (no Z suffix) as plugin 0.6.0: CLAUDE.md block, three hooks, record spec, skill text, docs, an audit stamp-form check, and tests that run the hooks under UTC+14 and UTC-11. Suites in the dev container: install 75, update 110, scan 47, audit 89; both manifests validate. Ran update on this repo (0.5.0 -> 0.6.0) and removed the interim UTC override from CLAUDE.md. Decision logged.
- Earlier today: re-reviewed all llm/ records (committed as 0eed286, not pushed) and investigated the empty SESSIONS.jsonl (hook works in `claude -p`; unconfirmed for desktop sessions; KNOWN_ISSUES).
- Work now happens in the dev container (`unruffled_euclid`), driven with `docker exec` from the host.

## Current state of the codebase
- `plugin/` is the product: `.claude-plugin/plugin.json` (version 0.6.0), `skills/{init,adopt,update,audit}` (SKILL.md plus scripts; shared helpers in `skills/init/scripts/lib.sh`), `core/`, `adapters/claude-code/`, `templates/llm/`, `sandbox/` (scaffold: firewall and Dockerfile are empty placeholders), `CHANGELOG.md`.
- The root holds `docs/`, `examples/`, `tests/`, `README.md`, `.claude-plugin/marketplace.json` (source `./plugin`), and this repo's own installed framework (`.claude/`, `llm/`, `CLAUDE.md`). The installed copies are managed by `update`: edit the sources in `plugin/`, never the copies.
- Everything is pushed except the records written after the 0.6.0 verification (uncommitted).
- No CI, no license.

## Next recommended task
Pick the next item from llm/TODO.md. Suggested order: choose a license (the only item under Now), then the sandbox module (firewall, allowlist, threat model), CI for the four suites, and finding out which hook events Claude Code reloads mid-session.

## Open risks / questions
- No license chosen.
- Which hook events Claude Code reloads mid-session is unverified (the skills' "starts in a new session" text may be wrong).
- One garbled `.gitattributes` was seen once on the Windows bind mount and never reproduced; appends are now single writes.
- Timestamps: UTC everywhere from 0.6.0. Entries written before it may be local time (add-only logs, not rewritten).
- Interactive (non -p) skill use and non-`user` plugin scopes are untested.

## How to resume
- Read `CLAUDE.md`, then `llm/TODO.md`, `llm/KNOWN_ISSUES.md` and `llm/ARCHITECTURE.md`.
- Run the suites in the dev container (`.devcontainer/`; VS Code "Reopen in Container"; find it with `docker ps`): `docker exec -u vscode <id> bash -c 'cd /workspaces/llm-governance-framework && bash tests/test_install.sh'` (also test_update, test_scan, test_audit). They take seconds there and minutes on Windows.
- Tooling quirks that cost time: in Git Bash set `MSYS_NO_PATHCONV=1` for docker commands with `/tmp` paths but not for scripts that run the Windows `jq` on the host; the Bash tool collapses double backslashes in commands, so use the Edit/Write tools for content with backslashes and check for stray CR bytes; never use grep to detect CRs on Git Bash.
- SessionEnd logging in desktop sessions is unconfirmed (see KNOWN_ISSUES). Otherwise hooks are active in sessions here: after Edit/Write on project files the Stop hook blocks until this file's content changes.
