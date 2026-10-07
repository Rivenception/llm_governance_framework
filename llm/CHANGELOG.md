# Changelog
Prose history of logical changes. Add-only, newest at top.

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
