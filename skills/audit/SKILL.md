---
name: audit
description: Check the health of the LLM governance framework in this project: files, imports, hooks, settings, secrets hygiene, version, record formats, and a live test that the enforcement hooks actually work here. Read-only.
argument-hint: "[--no-deep]"
disable-model-invocation: true
allowed-tools: Read Bash(${CLAUDE_SKILL_DIR}/scripts/audit.sh *)
---

# Audit the LLM governance framework in this project

Project: `${CLAUDE_PROJECT_DIR}`. Optional argument: `--no-deep` skips the
functional hook test. Arguments given: `$ARGUMENTS`

The audit is read-only: it never changes the project. The deep check copies
the project's own hook scripts into a temporary directory and runs them there
to prove the enforcement works in this environment.

## Steps

1. **Run it.** `${CLAUDE_SKILL_DIR}/scripts/audit.sh $ARGUMENTS "${CLAUDE_PROJECT_DIR}"`
   - Exit 0: no failures (warnings are possible). Exit 2: at least one FAIL.
   - Exit 1 with "does not appear to be installed": point the user to `init`
     (new project) or `adopt` (existing project) and stop.

2. **Report in priority order, in plain language.** Start with a one-line
   verdict: healthy, healthy with notes, or needs fixes. Then:
   - **FAIL**: each one says what is broken and why it matters (for example, an
     unregistered Stop hook means PROJECT_STATE is not enforced; an un-ignored
     `settings.local.json` can leak secrets). Give the specific fix.
   - **WARN**: group them as "needs action" and "expected / informational".
     On a freshly installed project three warnings are normal: unfilled
     `CLAUDE.md` placeholders, PROJECT_STATE never stamped, and PROJECT_STATE
     still the blank template. They clear as the user fills in `CLAUDE.md` and
     finishes a first turn that changes project files.
   - **PASS**: mention only the count and anything notable (for example that the
     deep check confirmed the hooks work).

3. **Point to the right fix.** Do not make changes during the audit. Suggest:
   - missing or outdated framework files, hooks, settings entries, markers,
     version behind the plugin, no install record: the `update` skill
     (use `--accept-new` for files the user wants reset);
   - unfilled placeholders and scope/stack: offer to draft them with the user
     (scope and stack is human-owned; write only what they state or approve);
   - secrets or `.gitignore` findings: show the exact line to add or the exact
     `git rm --cached` command; run it only if the user asks;
   - missing tools: the install command the audit printed (`jq`, hash tool);
   - a deep-check FAIL: the hooks do not behave correctly in this environment,
     so say which step failed (for example "Stop did not block") and check that
     `bash` and `jq` are available to wherever Claude Code runs;
   - DRAFT markers: the user should review the drafted files and delete the
     DRAFT line once satisfied;
   - add-only violations in git history: tell the user plainly; history cannot
     be undone by the audit, but future entries should be added, not rewritten;
   - "edited since install" warnings: not wrong, but the next `update` will
     report those files as conflicts; customizations belong in the project's own
     `CLAUDE.md` sections.

4. If the user wants fixes applied, do them with the appropriate skill or with
   their explicit approval of each change. Do not record the audit itself in
   `llm/CHANGELOG.md` (it changes nothing); record only changes you then make.
