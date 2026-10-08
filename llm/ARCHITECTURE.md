# Architecture
Static reference — how the system fits together. Update on structural
change only, not per session.

## Overview
The "LLM Governance Framework" is a Claude Code plugin (`llm-governance`,
version in `plugin/.claude-plugin/plugin.json`) that installs and maintains,
in any project, a record of AI-assisted work (`llm/`), behavioral rules and
enforcement hooks. The plugin is the product (`plugin/`); the repo root (docs,
tests, examples, README, marketplace manifest) is the project around it. This
repo also adopts the framework itself (see "Installed copies" below).

## Components
**Product: `plugin/`** (the only thing shipped to users' plugin cache)
- `.claude-plugin/plugin.json`: manifest and version. Claude Code updates an
  installed plugin only when this version changes.
- `skills/{init,adopt,update,audit}/`: four skills, each a thin `SKILL.md`
  wrapping a deterministic bash script in `scripts/`.
  - `init/scripts/install.sh` is the installer; `adopt/scripts/install.sh`
    just execs it. `init/scripts/lib.sh` holds the helpers shared by install,
    update and audit (hashing, the managed-file list, manifest read/write,
    CR-tolerant line matching, the `settings.json` merge, the `CLAUDE.md`
    block extract/append).
  - `adopt/scripts/scan.sh`: read-only, whitelist-based scan of an existing
    project (redacts secrets, never opens `.env` or key files).
  - `update/scripts/update.sh`: brings a project to the plugin's version.
  - `audit/scripts/audit.sh`: read-only health check, including a "deep" run
    of the project's own hooks in a temporary copy.
- `core/`: tool-agnostic `RULES.md` and `llm-records.md`.
- `adapters/claude-code/`: the Claude Code specifics copied into projects:
  `CLAUDE.md` (its framework block), `.gitignore` and `.gitattributes` lines,
  and `.claude/` (`settings.json` plus six hook scripts and their `lib.sh`).
- `templates/llm/`: blank `llm/` record files.
- `sandbox/`: optional container layer (`devcontainer.json` works; the
  `Dockerfile`, `init-firewall.sh` and `allowed-domains.txt` are placeholders).
- `CHANGELOG.md`: release notes, read by the `update` skill.

**Project around the product (repo root)**
- `.claude-plugin/marketplace.json`: makes the repo installable; source `./plugin`.
- `docs/`: setup guide, walkthrough, startup checklist, bootstrap design,
  sandbox threat model (stub), global CLAUDE.md snippet.
- `examples/llm/`: a populated sample of the `llm/` formats.
- `tests/`: `test_install.sh`, `test_update.sh`, `test_scan.sh`, `test_audit.sh`.
- `.devcontainer/`: this repo's own dev environment (Ubuntu base image, Node and Claude Code features, a per-project volume for the Claude login; `devcontainer-lock.json` pins the feature versions). It is where the test suites run in seconds. It is separate from the shippable `plugin/sandbox/devcontainer.json`, which will be hardened (firewall) for users.

**Installed copies (this repo as a consumer of its own framework)**
- `.claude/hooks/*.sh` and `.claude/settings.json`: hooks on SessionStart,
  PostToolUse (Edit/Write/MultiEdit/NotebookEdit), Stop, PreCompact, SessionEnd.
- `llm/` records, `llm/framework/` (rules, `VERSION`, `MANIFEST`), the marked
  framework block in `CLAUDE.md`, `.gitignore` and `.gitattributes` lines.
- These are managed by `update`. Edit the sources under `plugin/`, then run
  `bash plugin/skills/update/scripts/update.sh .`.

## Data flow
- **Install (init / adopt):** the skill runs its script with `--dry-run`, then
  the real run after the user's approval. The script creates missing `llm/`
  records (never overwriting), copies `core/` into `llm/framework/` and the
  hooks into `.claude/hooks/`, merges hook entries into `.claude/settings.json`,
  adds or appends the markered framework block to `CLAUDE.md`, and appends missing
  lines to `.gitignore` and `.gitattributes`. It records the sha256 of every
  framework-owned file in `llm/framework/MANIFEST` and the version in
  `llm/framework/VERSION`.
- **Update:** compares each framework-owned file's current hash with the
  MANIFEST. Unedited files are refreshed; edited files, or files with no
  recorded baseline, are reported as conflicts and left alone (`--accept-new
  <path>` takes the plugin's copy). `VERSION` advances only when there are no
  conflicts. Project content is never touched.
- **Enforcement at run time:** SessionStart injects the session ID and time and
  records a baseline hash of `PROJECT_STATE.md`; PostToolUse flags edits outside
  `llm/` and `.claude/`; Stop blocks until the content hash of `PROJECT_STATE.md`
  has changed (it stamps its `Last updated:` line); PreCompact reminds to
  update it; SessionEnd appends a line to `llm/SESSIONS.jsonl`.
- **Distribution:** users add the GitHub repo as a marketplace; Claude Code
  copies `plugin/` into its cache, so the scripts run from there.

## External dependencies
- `bash`, `jq`, and `sha256sum` or `shasum` at runtime.
- `git` for the tests and the audit's git checks.
- Claude Code (plugin, marketplace and hook mechanisms). Only Claude Code is supported.
- GitHub (`Rivenception/llm_governance_framework`) as the distribution source.
- No CI configuration yet (see TODO).

## Known architectural debt
- Decision-ownership and architecture rules are prose only, by design (KNOWN_ISSUES).
- Only the Claude Code adapter exists; LLM-agnostic support is a long-term goal
  (`core/` is kept tool-neutral for it).
- The sandbox module is a scaffold.

## Open questions
- Which hook events Claude Code reloads mid-session (see KNOWN_ISSUES).
- Whether SessionEnd fires for every way a desktop session can end; the log is best-effort until confirmed (see KNOWN_ISSUES).
