# Known Issues
Bugs, limitations, and tech debt that exist right now — distinct from
TODO.md (planned work). Update status in place; don't delete resolved
entries.

New entries use `## [YYYY-MM-DD] Short title` (see llm/framework/llm-records.md
for the full template). The one exception is directly below: `[framework]` in place of
a date marks a permanent note about the framework itself, not a dated
occurrence — don't copy that header style for actual bugs.

## [framework] Decision-ownership and architecture-protocol rules are prose-only
Severity: medium
Status: accepted
Files: llm/framework/RULES.md
Description: Accepted by design. The "requires my approval" list and
architectural change protocol are natural-language instructions, not
hook-enforced. Nothing blocks the assistant from making one of those
changes without asking; the only safeguard is the self-check it runs
before marking a task done (see RULES.md, Task completion standard).
Potential solution: A PreToolUse hook flagging edits to sensitive paths
(package.json, config root, migration files) for confirmation would add
real enforcement here, if this ever proves insufficient in practice.

## [2026-10-07] Skills tell users hooks only start in a new session, but they seem to apply immediately
Severity: low
Status: open
Files: plugin/skills/init/SKILL.md, plugin/skills/adopt/SKILL.md, plugin/skills/update/SKILL.md, plugin/core/llm-records.md
Description: The wrap-up guidance says hooks are read at session start, so enforcement begins in a new session. In this repo's own adoption session the PostToolUse and Stop hooks did fire without a restart: .claude/hooks/.state appeared mid-session and the Stop hook stamped PROJECT_STATE.md with that session's ID. SessionStart cannot have run, so the injected session ID and baseline hash were missing for that session. Two records written in that session wrongly say the hooks were not active.
Potential solution: Verify what Claude Code reloads mid-session (all hook events, or only some), then reword the skills' wrap-up text and note that SessionStart-derived values (session ID, baseline hash) only exist from the next session.

## [2026-10-07] A one-off garbled .gitattributes after update ran on a Windows bind mount
Severity: medium
Status: open
Files: plugin/skills/update/scripts/update.sh, plugin/skills/init/scripts/install.sh, plugin/skills/init/scripts/lib.sh
Description: Running update from the dev container against this repo (a Windows bind mount) appended three writes' worth of text to .gitattributes and the result was mangled: part of the comment line was overwritten by a rule and git reported an invalid attribute name. Four later attempts, including against host-written copies on the same mount, all produced correct output, so the cause is unknown.
Potential solution: Appends are now a single write (append_block in lib.sh), which removes the likeliest mechanism. Consider also writing edits to user files via a temp file and rename, and have update re-read what it wrote and fail loudly on a mismatch.

## [2026-10-07] Record timestamps mix local time and UTC
Severity: low
Status: open
Files: plugin/core/llm-records.md, plugin/adapters/claude-code/.claude/hooks/check_project_state.sh
Description: The spec says to take timestamps from the machine's date. A host session (local time, UTC-4 here) and a container session (UTC) therefore stamp entries hours apart, so CHANGELOG entries can sort out of order and trip the audit's newest-first check. The Stop hook stamps PROJECT_STATE.md in local time.
Potential solution: Decide on UTC (date -u) everywhere and update the rules, the skills, the stamp hook and the audit together.

## [2026-10-07] Edited framework files are reported as conflicts at every update
Severity: low
Status: accepted
Files: plugin/skills/update/scripts/update.sh
Description: A framework file the user deliberately customized (a hook, llm/framework/*) differs from the install record forever, so every update lists it as a conflict and holds back the version stamp until it is resolved. Documented in the design notes; customizations belong in the project's own CLAUDE.md sections.
Potential solution: Let projects record intentional overrides (for example a LOCAL_OVERRIDES list) so update skips them quietly. In TODO.

## [2026-10-07] update does not remove settings hook entries for renamed scripts
Severity: low
Status: open
Files: plugin/skills/update/scripts/update.sh
Description: If a release renames a hook script, update removes the old file when it is unedited but only warns that .claude/settings.json still references it, so a dangling hook entry can remain (the audit flags it as a FAIL).
Potential solution: Remove settings entries whose command points at a script the update just removed.

## [2026-10-07] Legacy --sandbox installs are no longer touched by update
Severity: low
Status: accepted
Files: plugin/skills/update/scripts/update.sh
Description: After the fix below, update manages .devcontainer/devcontainer.json only when the install record lists it. A project that installed the dev container with an early version (no install record) will not have it refreshed, because that file cannot be told apart from the project's own.
Potential solution: None needed unless such installs exist; re-running init --sandbox on a project without the file would create it.

## [2026-10-07] Test suites are slow on Windows
Severity: low
Status: accepted
Files: tests/test_install.sh, tests/test_update.sh, tests/test_scan.sh, tests/test_audit.sh
Description: Process spawning on Git Bash makes the suites take minutes (update about 6, audit about 3.5); on Linux they take seconds. No CI exists yet.
Potential solution: Run them in the dev container, and add CI. In TODO.

## [2026-10-07] update dry run did not list the version-stamp change
Severity: low
Status: resolved
Files: plugin/skills/update/scripts/update.sh, plugin/skills/update/SKILL.md
Description: When no file content differed, the dry run showed only OK lines and the real run silently advanced llm/framework/VERSION, so the assistant had to infer it. Fixed in commit b033313: the plan now lists the UPDATE line (or says the stamp is held back by conflicts).
Potential solution: Resolved.

## [2026-10-07] Skills asked preflight questions before their pre-approved dry run
Severity: low
Status: resolved
Files: plugin/skills/adopt/SKILL.md, plugin/skills/init/SKILL.md
Description: allowed-tools pre-approval lasts only for the skill's first turn, so asking first meant the read-only dry run needed a permission prompt in the next turn. Fixed in commit 308ceaf: the scan and dry run run first and questions come with the plan.
Potential solution: Resolved.

## [2026-10-07] Skills refused a repository that merely contains the plugin source
Severity: low
Status: resolved
Files: plugin/skills/adopt/SKILL.md, plugin/skills/init/SKILL.md
Description: After the plugin moved into plugin/, the preflight still told the assistant to stop at "the framework repo itself", so adopting this repo was refused. Fixed in commit cf687bf: only the plugin directory is off limits.
Potential solution: Resolved.

## [2026-10-07] update treated a project's own .devcontainer as framework-owned
Severity: medium
Status: resolved
Files: plugin/skills/update/scripts/update.sh
Description: update managed .devcontainer/devcontainer.json whenever the file existed, so a project's own dev container was reported as a conflict (baseline unknown) and the version stamp was held back. Found by running update on this repo. Fixed (uncommitted): it is managed only when the install record lists it.
Potential solution: Resolved.

## [2026-10-07] CRLF .gitignore and .gitattributes collected duplicate lines
Severity: medium
Status: resolved
Files: plugin/skills/init/scripts/lib.sh
Description: The merge matched lines exactly, so a CRLF file (a Windows autocrlf checkout read from Linux) never matched and the framework's lines were appended again on every run. Fixed (uncommitted): matching ignores CRs.
Potential solution: Resolved.

## [2026-10-07] Audit reported missing imports for a CRLF CLAUDE.md
Severity: low
Status: resolved
Files: plugin/skills/audit/scripts/audit.sh
Description: The import check matched whole lines, so the trailing CR made @llm/framework/RULES.md look absent. Fixed (uncommitted): the check ignores CRs, and the framework-block comparison does too.
Potential solution: Resolved.

## [2026-10-07] Audit CRLF detection via grep never fired on Git Bash
Severity: medium
Status: resolved
Files: plugin/skills/audit/scripts/audit.sh
Description: grep on Windows Git Bash strips carriage returns before matching, so a grep-based CRLF check silently found nothing there. Found while verifying with core.autocrlf=true. Fixed (uncommitted): the check compares bytes (tr and cmp).
Potential solution: Resolved. Avoid grep for CR detection on Windows.

## [2026-10-07] Windows CRLF checkouts broke the hook scripts of adopted projects
Severity: high
Status: resolved
Files: plugin/adapters/claude-code/.gitattributes, plugin/skills/init/scripts/install.sh, plugin/skills/update/scripts/update.sh, plugin/skills/audit/scripts/audit.sh
Description: With core.autocrlf=true a clone turned all six hooks and the llm/framework files into CRLF, which bash rejects on Linux, WSL and dev containers; only this repo had a protecting .gitattributes, and the audit could only report a generic syntax error. Fixed (uncommitted): init, adopt and update add LF rules to the project's .gitattributes, and the audit names CRLF with the exact fix. See llm/DECISIONS.md.
Potential solution: Resolved.
