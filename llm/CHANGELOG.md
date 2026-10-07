# Changelog
Prose history of logical changes. Add-only, newest at top.

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
