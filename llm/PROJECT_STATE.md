# Project State
Last updated: 2026-10-07 16:26 | Session: 115017e7-19b7-45eb-8573-d45f62282310
> **DRAFT, unconfirmed.** Generated from a read-only scan on 2026-10-07 (session d1296834-35c7-4ccc-8532-1203a6fefad0), updated by hand on 2026-10-07 after the line-ending work. Verify before relying on it; delete this line once reviewed.

## Status
Shell-script and Markdown project: the Claude Code plugin `llm-governance`, released as 0.4.0 (skills `init`, `adopt`, `update`, `audit`). This repo now governs itself with the same framework (adopted on 2026-10-07). Unreleased work sits on top of 0.4.0: the update dry run lists the version stamp, LF rules protect framework files from Windows CRLF checkouts, the audit diagnoses CRLF, and fixes found while dogfooding. On Linux in the dev container the four suites pass: install 75, update 106, scan 47, audit 79 (Windows runs the same suites in minutes instead of seconds).

## What just happened (this session)
- Pushed the four earlier commits (adoption, README fix, two skill fixes).
- Added LF rules for the hooks and llm/framework to the project's .gitattributes through init, adopt and update; made CLAUDE.md, .gitignore and .gitattributes handling CRLF-tolerant; audit now names CRLF as the cause and checks the rules. Verified by cloning with core.autocrlf=true: without the rules all six hooks arrive as CRLF, with them none do.
- Dogfooding the new update on this repo found two bugs, both fixed with tests: a project's own .devcontainer was treated as framework-owned, and one append produced a garbled .gitattributes (not reproducible; appends are now single writes).
- Wrote the open items to llm/TODO.md and the line-ending decision to llm/DECISIONS.md.
- Logged the session's bugs and limitations in llm/KNOWN_ISSUES.md (15 entries: 8 resolved, 4 open, 3 accepted).
- Committed and pushed all of the above as 1c2d4c6. Then found and fixed a bug in it: the plugin's own .gitattributes payload, unpinned, arrives as CRLF on a Windows autocrlf clone and leaked CRs into projects (regression test added; commit follows this note).

## Current state of the codebase
- `plugin/` is the product; `docs/`, `tests/`, `examples/`, `README.md` and `.claude-plugin/marketplace.json` are the project around it.
- Local, unpushed commits: none. Uncommitted: the line-ending work, the bug fixes, docs, and these llm/ records.
- `.devcontainer/` is untracked and undecided.
- No CI configuration.

## Next recommended task
Review and commit the uncommitted work, then fill in the root CLAUDE.md placeholders (scope and stack is the owner's to define) and confirm the two drafts. See llm/TODO.md for the rest.

## Open risks / questions
- The hooks turned out to be active mid-session: the Stop hook stamped this file with this session's ID (115017e7-19b7-45eb-8573-d45f62282310) and created .claude/hooks/.state. Two earlier records say the hooks were not active; that is wrong (see KNOWN_ISSUES). SessionStart never ran in this session, so the injected session ID and baseline hash were missing.
- Record timestamps mix local time (host) and UTC (container); needs a convention (TODO).
- One garbled .gitattributes was seen once and could not be reproduced.
- `.devcontainer/` fate undecided; no license chosen.

## How to resume
Read `CLAUDE.md`, then `llm/TODO.md` and `llm/ARCHITECTURE.md` (draft). Run the suites in the dev container with `bash tests/test_install.sh` (and `test_update.sh`, `test_scan.sh`, `test_audit.sh`).
