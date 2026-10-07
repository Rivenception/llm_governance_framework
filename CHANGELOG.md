# Changelog

Release notes for the LLM governance framework plugin. The `update` skill
reads this file to tell users what changed between their installed version and
the plugin's. Newest first.

## 0.2.0 (unreleased)
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
