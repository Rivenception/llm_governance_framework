> **DRAFT, unconfirmed.** Generated from a read-only scan on 2026-10-07 (session d1296834-35c7-4ccc-8532-1203a6fefad0). Verify before relying on it; delete this line once reviewed.

# Architecture
Static reference — how the system fits together. Update on structural
change only, not per session.

## Overview
The repository appears to be the source of the "LLM Governance Framework": a
Claude Code plugin (`llm-governance`, version 0.4.0 per
`plugin/.claude-plugin/plugin.json`) that installs record-keeping files
(`llm/`), behavioral rules and enforcement hooks into other projects
(`README.md`). The plugin is the product (`plugin/`); the repo root
(docs, tests, examples, README, marketplace manifest) is the project around it.
This repo also adopts the framework itself (this file is part of that).

## Components
**Product: `plugin/`** (the only thing shipped to users' plugin cache, per README)
- `plugin/.claude-plugin/plugin.json`: plugin manifest and version.
- `plugin/skills/{init,adopt,update,audit}/`: four skills, each a `SKILL.md`
  plus a `scripts/` directory (README: "a deterministic script").
- `plugin/core/`: tool-agnostic `RULES.md` and `llm-records.md`.
- `plugin/adapters/claude-code/`: Claude Code adapter (`CLAUDE.md`,
  `.gitignore`, `.claude/` hooks and settings), the files copied into projects.
- `plugin/templates/llm/`: blank `llm/` record files.
- `plugin/sandbox/`: optional container layer (`Dockerfile`, `devcontainer.json`,
  `init-firewall.sh`, `allowed-domains.txt`); README calls it a scaffold.
- `plugin/CHANGELOG.md`: release notes read by the `update` skill.

**Project around the product (repo root)**
- `.claude-plugin/marketplace.json`: makes the repo installable; source `./plugin`.
- `docs/`: setup guide, walkthrough, startup checklist, bootstrap design,
  sandbox threat model, global CLAUDE.md snippet.
- `examples/llm/`: a populated sample of the `llm/` formats.
- `tests/`: `test_install.sh`, `test_scan.sh`, `test_update.sh`, `test_audit.sh`.
- `.devcontainer/`: untracked at adoption time; not part of this adoption.

**Installed by this adoption (this repo as a consumer)**
- `.claude/hooks/*.sh` and `.claude/settings.json`: hooks on SessionStart,
  PostToolUse (Edit/Write/MultiEdit/NotebookEdit), Stop, PreCompact, SessionEnd.
- `llm/` records, `llm/framework/` rules, `CLAUDE.md`, `.gitignore`.

## Data flow
Appears to be: a user installs the plugin from the marketplace; a skill's
script copies/merges templates, core rules and adapter files into the target
project, recording installed files in `llm/framework/MANIFEST` and the version
in `llm/framework/VERSION` (so `update` can detect user edits and report
conflicts). Inside an adopted project, hooks track edits and check that
`llm/PROJECT_STATE.md` was updated before a session stops. Not verified by
reading the scripts.

## External dependencies
- `bash`, `jq`, and `sha256sum` or `shasum` at runtime (README).
- `git` for the tests (README).
- Claude Code (plugin, marketplace and hook mechanisms). Only Claude Code is supported.
- GitHub (`Rivenception/llm_governance_framework`) as the distribution source.
- No CI configuration found.

## Known architectural debt
None observed from the files read. README says LLM-agnostic support is a
long-term goal; today only the Claude Code adapter exists.

## Open questions
- What is the intended role of `.devcontainer/` at the root versus `plugin/sandbox/`?
- How the skill scripts behave in detail (only the dry-run output and tests'
  existence were observed, not the script sources).
- Whether the `README.md` "not automated yet" note about bootstrapping into
  existing projects is stale, since the `adopt` skill now does this.
