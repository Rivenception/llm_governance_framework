# Changelog

Release notes for the LLM governance framework plugin. The `update` skill
reads this file to tell users what changed between their installed version and
the plugin's. Newest first.

## 0.6.0
- **Timestamps are now UTC everywhere.** The `CLAUDE.md` block tells the
  assistant to use `date -u`, the SessionStart hook injects UTC, the Stop hook
  stamps `PROJECT_STATE.md` in UTC, and `SESSIONS.jsonl` lines are UTC. Formats
  are unchanged and there is no `Z` suffix. The record spec (`llm-records.md`)
  states the rule.
- **Upgrading.** Update the plugin, then run `/llm-governance:update` in each
  project. It refreshes the three hooks, `llm/framework/llm-records.md` and the
  `CLAUDE.md` block (files you edited are reported as conflicts, not
  overwritten). Existing entries are not rewritten, so older ones may be in
  local time.
- The audit checks that the `Last updated:` stamp has the `YYYY-MM-DD HH:MM` form.

## 0.5.0
- **Upgrading.** Update the plugin, then run `/llm-governance:update` in each
  project: it adds the new `.gitattributes` rules below and moves the version
  stamp. No framework file content changes in this release.
- The `update` dry run now lists the version-stamp change, so an update where no
  file content differs is visible in the plan.
- `update` now manages `.devcontainer/devcontainer.json` only when the install
  record shows the framework installed it. A project's own dev container is
  left alone (before, it was reported as a conflict that held back the version).
  A very early install that added the dev container with no install record is
  no longer refreshed by `update`.
- **Windows line endings.** On Windows with `core.autocrlf=true`, a checkout
  turned the hook scripts into CRLF, which breaks them under Linux, WSL and dev
  containers. `init`, `adopt` and `update` now add LF rules for `.claude/hooks/`
  and `llm/framework/` to the project's `.gitattributes` (created or appended,
  never overwritten). `audit` now names the real cause (CRLF) with the exact
  fix, checks that the rules are in effect, and no longer mistakes a CRLF
  `CLAUDE.md` for a missing import or an edited framework block.
- The skills' preflight no longer treats a repository that merely contains the
  plugin source as the plugin itself, and run their dry run before asking
  questions (pre-approval lasts only for the skill's first turn).

## 0.4.0
- **Repository layout.** The plugin now lives in `plugin/` in the repository
  (the marketplace entry points at `./plugin`), so the plugin cache no longer
  includes the repo's tests, docs, examples or README, and the repository root
  can adopt the framework like any other project. No change to the skills, the
  installed files, or how you install and update.

## 0.3.0
- **New `audit` skill.** Read-only health check of the framework in a project
  (files, imports, hooks, settings, secrets hygiene, version, record formats,
  add-only history) plus a functional test that runs the project's own hooks in
  a temporary copy. Reports PASS/WARN/FAIL; `--json` for tooling.

## 0.2.0
- **New `update` skill.** Brings a project's framework files up to the plugin's
  version without touching project records. Files you edited are reported as
  conflicts and left alone; you can take the plugin's version per file.
- **Install record.** `init` and `adopt` now write `llm/framework/MANIFEST`
  (hashes of the framework files as installed). This is what lets `update`
  tell "you edited this" from "this is just the old version".
- **`CLAUDE.md` markers.** New projects now wrap the framework block in
  `<!-- llm-governance:begin/end -->` markers (adopted projects already had
  them), so `update` can refresh it without touching your own text.
- Projects installed by 0.1.0 have no manifest: the first update reports any
  differing framework file as a conflict (baseline unknown) instead of guessing;
  accept the plugin's version per file and the manifest is created.

## 0.1.0
- `init` skill: installs the framework into a new project.
- `adopt` skill: read-only codebase scan, install without overwriting, and
  unconfirmed drafts of `llm/ARCHITECTURE.md` and `llm/PROJECT_STATE.md`.
- Rules (`core/`), `llm/` record templates, and Claude Code hooks: session
  start (injects session ID and time), edit tracking, PROJECT_STATE enforcement
  on turns that change project files, pre-compaction reminder, session log.
- Optional sandbox dev container config (firewall and threat model still stubs).
