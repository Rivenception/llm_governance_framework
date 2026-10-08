# Changelog
Prose history of logical changes. Add-only, newest at top.

## [2026-10-08 18:30] Verify the published 0.6.0 against real GitHub
Session: 115017e7-19b7-45eb-8573-d45f62282310
What: In the dev container, added the marketplace from GitHub and installed the plugin: it came in as 0.6.0 with a lean cache, executable scripts and the `date -u` hooks. Claude Code only accepts a branch or tag as a marketplace ref, so the 0.5.0 -> 0.6.0 plugin hop was not repeated (it was verified for 0.4.0 -> 0.5.0). Instead built a throwaway project with the real 0.5.0 installer (from commit b016a0e) and ran the live `/llm-governance:update` with the 0.6.0 plugin: six files updated, no conflicts, version stamp 0.6.0, correct CHANGELOG and CHANGES entries; the project's audit had 0 failures (2 expected warnings for an unfilled CLAUDE.md and an unstamped PROJECT_STATE). The run's SessionEnd hook wrote a line to the throwaway project's SESSIONS.jsonl. Removed the test project, plugin and marketplace from the container.
Files: llm/PROJECT_STATE.md, llm/KNOWN_ISSUES.md, llm/CHANGELOG.md, llm/CHANGES.jsonl

 Release 0.6.0: UTC timestamps everywhere
Session: 115017e7-19b7-45eb-8573-d45f62282310
What: Made UTC the framework-wide timestamp convention (no Z suffix). The CLAUDE.md block, the SessionStart, Stop and SessionEnd hooks, the record spec (new Timestamps section), the adopt and update skill text and the docs now say or use `date -u`; the audit checks the `Last updated:` stamp form. Added tests that run the three hooks under UTC+14 and UTC-11 and compare with `date -u` (mutation-checked); suites in the dev container: install 75, update 110, scan 47, audit 89; both manifests validate. Ran update on this repo (0.5.0 -> 0.6.0, six files, no conflicts) and removed the interim UTC override from CLAUDE.md. Not pushed; the release happens on push.
Files: plugin/.claude-plugin/plugin.json, plugin/CHANGELOG.md, plugin/core/llm-records.md, plugin/adapters/claude-code/CLAUDE.md, plugin/adapters/claude-code/.claude/hooks/session_start.sh, plugin/adapters/claude-code/.claude/hooks/check_project_state.sh, plugin/adapters/claude-code/.claude/hooks/log_session_end.sh, plugin/skills/adopt/SKILL.md, plugin/skills/update/SKILL.md, plugin/skills/audit/scripts/audit.sh, tests/test_audit.sh, docs/SETUP_GUIDE.md, docs/STARTUP_CHECKLIST.md, CLAUDE.md, llm/framework/*, .claude/hooks/*, llm/DECISIONS.md, llm/KNOWN_ISSUES.md, llm/TODO.md, llm/PROJECT_STATE.md

## [2026-10-08 17:28] Re-review llm/ records; investigate empty SESSIONS.jsonl
Session: 115017e7-19b7-45eb-8573-d45f62282310
What: Re-read every file in llm/ and fixed what was stale: rewrote ARCHITECTURE.md from draft hedging ("appears to be", version 0.4.0) into verified facts for 0.5.0 (skills, shared lib.sh, install/update/runtime data flow); removed the finished LF-pin item from TODO.md; changed five "Fixed (uncommitted)" and "unreleased" mentions in KNOWN_ISSUES.md to "Fixed in 0.5.0"; backfilled the two docs/ edits missing from CHANGES.jsonl (marked as backfilled). Investigated SESSIONS.jsonl: the SessionEnd hook is registered and works by hand and in a real `claude -p` run in the dev container, so the empty log is probably because the adoption session predates the hook and the desktop session has not ended; logged as open in KNOWN_ISSUES.md with a test to confirm. Audit passes (29 checks) in the dev container.
Files: llm/ARCHITECTURE.md, llm/TODO.md, llm/KNOWN_ISSUES.md, llm/CHANGES.jsonl, llm/CHANGELOG.md, llm/PROJECT_STATE.md

## [2026-10-07 21:07] Track the dev container; add README badges
Session: 115017e7-19b7-45eb-8573-d45f62282310
What: Started tracking .devcontainer/ (config plus the lock file VS Code generated), renamed from the placeholder "My Sandboxed Project", and documented it in the README Contributing section and CLAUDE.md commands. Added seven technology badges (Bash, jq, Markdown, JSON, Claude Code plugin, Dev Container, GitHub) under the README title; each URL was checked to return an SVG with its logo. The owner reviewed ARCHITECTURE.md and PROJECT_STATE.md and removed their DRAFT lines; refreshed both, removed the resolved TODO items (drafts, dev container, badges and the owner's placeholder line in examples/llm/TODO.md) and recorded the decision.
Files: .devcontainer/devcontainer.json, .devcontainer/devcontainer-lock.json, README.md, CLAUDE.md, llm/ARCHITECTURE.md, llm/PROJECT_STATE.md, llm/TODO.md, llm/DECISIONS.md, examples/llm/TODO.md

## [2026-10-07 20:56] Verify the published 0.5.0 against real GitHub
Session: 115017e7-19b7-45eb-8573-d45f62282310
What: Installed 0.4.0 from GitHub, pushed the release (commit 5e7f539), then ran the two-step plugin update (0.4.0 -> 0.5.0) and /llm-governance:update on a project installed before the line-ending rules existed. The cache is lean and its scripts executable; update created .gitattributes with the LF rules (no CRs; git reports eol=lf), advanced the stamp and logged the update; the project's audit had 0 failures. Noted that the 0.4.0 on GitHub already contained the line-ending files because they were pushed before the version bump, so only installs made before those commits lack them. Cleaned up the container. Correction: the previous entry (Publish 0.5.0) is stamped 20:55 but was written at about 20:50 by adding minutes instead of reading the clock; it cannot be rewritten (add-only), so this entry's time comes from date -u and is after it.
Files: llm/PROJECT_STATE.md, llm/TODO.md, llm/CHANGELOG.md, llm/CHANGES.jsonl

## [2026-10-07 20:55] Publish 0.5.0
Session: 115017e7-19b7-45eb-8573-d45f62282310
What: Committed the prepared release and pushed it to origin/master, which publishes plugin 0.5.0 (Windows line-ending protection, update dry-run version stamp, skill preflight fixes, update leaving a project's own .devcontainer alone, clearer error for an unreadable plugin.json). Records updated to say it is published and that verification against real GitHub is still pending.
Files: plugin/.claude-plugin/plugin.json, plugin/CHANGELOG.md, CLAUDE.md, llm/PROJECT_STATE.md, llm/TODO.md, llm/CHANGELOG.md, llm/CHANGES.jsonl

## [2026-10-07 20:48] Fill in the project sections of CLAUDE.md
Session: 115017e7-19b7-45eb-8573-d45f62282310
What: Replaced the template placeholders in the root CLAUDE.md with the project overview, commands, scope and stack (out of scope: other assistants in the current releases, a hosted service or UI, replacing project judgment) and a new "Working in this repo" section (never edit the installed copies, release checklist, UTC timestamps, Windows gotchas, approval list). The content was proposed in chat and the owner chose the out-of-scope items, the location of the repo rules and the UTC interim rule. The framework-managed block is untouched. Audit: 0 failures, 1 warning (drafts awaiting review).
Files: CLAUDE.md, llm/DECISIONS.md, llm/TODO.md, llm/PROJECT_STATE.md

## [2026-10-07 20:38] Prepare the 0.5.0 release
Session: 115017e7-19b7-45eb-8573-d45f62282310
What: Bumped the plugin to 0.5.0 and moved the Unreleased notes under it (added upgrade guidance and the update-vs-.devcontainer behavior change). Hardened install.sh and update.sh to fail with a clear message when plugin.json is unreadable (update previously said "newer than this plugin ()"). Made the repo-root install test assert "not refused" instead of a specific exit code, since the root is itself an adopted project. Ran the upgrade on this repo (update 0.4.0 -> 0.5.0) as a user would. Validation passes; install 75, update 110, scan 47, audit 79. Not committed or pushed; the release happens on push.
Files: plugin/.claude-plugin/plugin.json, plugin/CHANGELOG.md, plugin/skills/init/scripts/install.sh, plugin/skills/update/scripts/update.sh, tests/test_install.sh, tests/test_update.sh, llm/framework/VERSION

## [2026-10-07 20:26] Fix CRLF payload leaking into projects' .gitattributes
Session: 115017e7-19b7-45eb-8573-d45f62282310
What: Right after pushing the LF-pinning work, found and reproduced that the plugin's own adapter .gitattributes, unpinned, arrives as CRLF on a Windows autocrlf clone and leaks CRs into projects and breaks idempotence. Line matching now ignores CRs on both sides, this repo's .gitattributes pins itself to LF, and test_install.sh has a regression scenario (75 checks). Logged in KNOWN_ISSUES as resolved. Uncommitted at the time of writing.
Files: plugin/skills/init/scripts/lib.sh, .gitattributes, tests/test_install.sh, llm/KNOWN_ISSUES.md

## [2026-10-07 20:20] Record the session's bugs in KNOWN_ISSUES and correct the hooks claim
Session: 115017e7-19b7-45eb-8573-d45f62282310
What: Added 15 entries to KNOWN_ISSUES.md (8 resolved bugs kept as history, 4 open, 3 accepted limitations) after they were missed in the previous entry. Correction: the previous entry and the DECISIONS entry say the framework's hooks were not active in the session; they were (the Stop hook stamped PROJECT_STATE.md with this session's ID), which also contradicts the skills' "hooks start in a new session" text. Those add-only entries are left as written and the correction lives here, in PROJECT_STATE.md and in KNOWN_ISSUES.md. Added the matching TODO item.
Files: llm/KNOWN_ISSUES.md, llm/PROJECT_STATE.md, llm/TODO.md

## [2026-10-07 20:13] Windows line-ending protection and dogfooding fixes
Session: unknown (the framework's hooks were not active in this session)
What: Added LF rules for the hooks and llm/framework to the project's .gitattributes via init, adopt and update, and taught the audit to diagnose CRLF (byte-exact, because grep on Git Bash strips CRs) and to verify the rules. Made CLAUDE.md, .gitignore and .gitattributes handling CRLF-tolerant. Dogfooding found and fixed: update treated a project's own .devcontainer as framework-owned and held back the version; the skills refused a repo that merely contains the plugin source and asked questions before their pre-approved dry run. Appends are now single writes after one garbled .gitattributes was seen once on the Windows bind mount. Wrote the open items to TODO.md. Tests: install 70, update 106, scan 47, audit 79 on Linux.
Files: plugin/adapters/claude-code/.gitattributes, plugin/skills/init/scripts/lib.sh, plugin/skills/init/scripts/install.sh, plugin/skills/update/scripts/update.sh, plugin/skills/audit/scripts/audit.sh, plugin/skills/*/SKILL.md, plugin/CHANGELOG.md, tests/*.sh, docs/*.md, .gitattributes, llm/TODO.md, llm/DECISIONS.md

## [2026-10-07 19:35] Adopt LLM governance framework
Session: d1296834-35c7-4ccc-8532-1203a6fefad0
What: Installed the framework into the repo root with the adopt skill (20 files created, no merges or conflicts). Drafted llm/ARCHITECTURE.md and llm/PROJECT_STATE.md from a read-only scan, both marked unconfirmed. Scope and stack was proposed in chat only and not written to CLAUDE.md. .devcontainer/ left untracked; nothing staged or committed.
Files: CLAUDE.md, .gitignore, .claude/settings.json, .claude/hooks/*.sh, llm/*, llm/framework/*
