# Project instructions for Claude Code

## Project overview
LLM Governance Framework: a Claude Code plugin (`llm-governance`) that installs
and maintains, in any project, a durable record of AI-assisted work (`llm/`),
behavioral rules that keep the human in charge of key decisions, and hooks that
enforce the record-keeping. Four skills: `init`, `adopt`, `update`, `audit`.
v1, Claude Code only. This repo governs itself with the same framework.

## Commands
- Dependencies: none to install; needs bash, git, jq, and sha256sum or shasum.
- Test: `bash tests/test_install.sh` (also `test_update.sh`, `test_scan.sh`,
  `test_audit.sh`). Minutes on Windows; seconds in the dev container.
- Dev container: `.devcontainer/` (VS Code: "Dev Containers: Reopen in
  Container") is the fast place to run the suites and try the skills with a
  real Claude Code.
- Validate: `claude plugin validate .` and `claude plugin validate ./plugin`
- Try local plugin edits: `claude --plugin-dir ./plugin`
- Refresh this repo's installed framework after changing `plugin/`:
  `bash plugin/skills/update/scripts/update.sh .`

## Project scope and stack
Human-owned: treat this section as settled. Any change to it goes through the
approval process in Decision ownership.

- Target users / purpose: developers using Claude Code who want governed,
  auditable AI-assisted work in new and existing projects.
- Explicitly out of scope:
  - Adapters for assistants other than Claude Code in the current releases
    (a long-term goal; `plugin/core/` is kept tool-neutral so it stays possible).
  - A hosted service, web UI or GUI: the framework is files, scripts and a plugin.
  - Replacing project judgment: it records and enforces process; it does not
    decide architecture or approvals for the user.
- Tech stack: Bash scripts, Markdown, JSON/JSONL. Needs bash, jq, git and a
  sha256 tool. Claude Code plugin, marketplace and hook mechanisms; GitHub for
  distribution. No language runtime. Not to be swapped (for example, no rewrite
  of the scripts in Node or Python) without my approval.
- Design conventions: scripts are deterministic and idempotent, never overwrite
  project content, preview with `--dry-run`, and real changes go through the
  permission prompt. LF line endings. Skills are thin wrappers around scripts.
  `llm/` logs are add-only.
- Architecture pattern: the plugin lives in `plugin/` (`core/` is tool-neutral,
  `adapters/` is tool-specific, plus `templates/`, `skills/`, `sandbox/`). The
  repo root is an ordinary governed project around it.

## Working in this repo
- Never hand-edit the installed copies at the root: `.claude/hooks/*`,
  `llm/framework/*`, and the marked block in this file. Change the source under
  `plugin/` and run update.
- A release = bump `plugin/.claude-plugin/plugin.json`, add a
  `plugin/CHANGELOG.md` entry, validate both manifests, run all four suites.
  Pushing is the release: ask before it. Installed copies only update when the
  version changes.
- Record timestamps in UTC: use `date -u "+%Y-%m-%d %H:%M"` for `llm/` entries
  in this repo. This overrides the machine-local `date` in the framework block
  below until the convention is settled (see `llm/TODO.md`).
- Windows gotchas: `jq.exe` emits CRLF (strip before `read` loops); `grep` on
  Git Bash strips CRs (use `tr`/`cmp` to detect them); new scripts need
  `git update-index --chmod=+x`.
- Do not copy files from Anthropic's reference dev container (proprietary).
- Also needs my approval: plugin layout, the install-record (MANIFEST) format,
  the never-overwrite and merge guarantees, adding or removing a skill, hook
  behavior, the license.

<!-- llm-governance:begin (installed by the llm-governance plugin) -->
## Session ID and timestamps
A SessionStart hook injects the session ID and start time into your
context. Use that exact session ID in every `Session:` field and in
`CHANGES.jsonl`. For entry timestamps, run `date "+%Y-%m-%d %H:%M"` —
never estimate. If no session ID was injected, write `unknown` rather than
inventing one, and tell me the hook isn't working (usually `jq` missing).

## Framework rules (imported)
These files are copied into the project by the framework installer. They
are the source of truth for behavior and for the `llm/` record formats.

@llm/framework/RULES.md
@llm/framework/llm-records.md

## Claude Code enforcement
- If you modify any project file (anything outside `llm/` and `.claude/`),
  a Stop hook will block the turn from ending until
  `llm/PROJECT_STATE.md`'s content has actually changed, so treat
  updating it as non-optional. Turns that only answer questions or only
  touch `llm/` are not blocked. The hook can't see file changes made via
  the Bash tool, so update PROJECT_STATE.md for those too.
- Never put secrets, tokens, or credentials in `.claude/settings.json` —
  it's committed to the repo. Put them in `.claude/settings.local.json`
  instead, and before writing to that file, confirm
  `.claude/settings.local.json` is already listed in `.gitignore`. If it
  isn't, add it before writing any secret to the file — don't assume this
  happens automatically.
<!-- llm-governance:end -->
