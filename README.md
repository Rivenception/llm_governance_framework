# LLM Governance Framework

A lightweight framework for working with AI coding assistants: a durable,
human-readable record of what changed and why (`llm/`), behavioral rules
that keep the human in charge of the decisions that matter, and hooks that
enforce the record-keeping where the tool allows it.

**Status:** v1. Built and tested for Claude Code only. The long-term goal is
to be LLM-agnostic, which is why tool-neutral content lives in `plugin/core/`
and everything Claude Code-specific lives in `plugin/adapters/claude-code/`.

## Repo map

The repository root is an ordinary project. Everything that gets installed
for users lives under `plugin/`; that folder is the Claude Code plugin, and
it is all that ends up in a user's plugin cache.

**The plugin (`plugin/`)**

| Path | What it is |
|---|---|
| `plugin/.claude-plugin/plugin.json` | Plugin manifest and version |
| `plugin/skills/` | The skills: `init`, `adopt`, `update`, `audit` (each a `SKILL.md` plus a deterministic script) |
| `plugin/core/` | Tool-agnostic rules (`RULES.md`) and the `llm/` record spec (`llm-records.md`) |
| `plugin/adapters/claude-code/` | Claude Code adapter: `CLAUDE.md`, hooks, settings, `.gitignore` |
| `plugin/templates/llm/` | Blank `llm/` record files to drop into a project |
| `plugin/sandbox/` | Optional container layer (devcontainer, firewall); scaffold, see its README |
| `plugin/CHANGELOG.md` | Release notes (the `update` skill reads this) |

**The repository around it**

| Path | What it is |
|---|---|
| `.claude-plugin/marketplace.json` | Makes this repo installable; points at `./plugin` |
| `docs/` | Setup guide, walkthrough, startup checklist, design notes |
| `examples/llm/` | A populated sample showing the `llm/` formats in use |
| `tests/` | Test suites for the install, scan, update and audit scripts |

## Quick start: Claude Code plugin

Requires `bash`, `jq`, and `sha256sum` or `shasum` wherever Claude Code runs.

```
claude plugin marketplace add Rivenception/llm_governance_framework
claude plugin install llm-governance@llm-governance
```

Then, from your project root in Claude Code:

- `/llm-governance:init` for a new project
- `/llm-governance:adopt` for an existing project: scans the codebase
  read-only, installs the framework without overwriting anything, and drafts
  `ARCHITECTURE.md` and `PROJECT_STATE.md` marked unconfirmed for you to review
- `/llm-governance:update` after the plugin is updated (see below): refreshes
  the framework's hooks, rules and `CLAUDE.md` block to the new version. Files
  you edited are reported as conflicts and never overwritten.

- `/llm-governance:audit` any time: a read-only health check. It verifies the
  files, imports, hooks, settings, secrets hygiene, version and record formats,
  and runs the project's own hooks in a temporary copy to prove enforcement
  actually works in your environment.

`init`, `adopt` and `update` preview first, and the real change asks for your
approval. `audit` changes nothing. Add
`--sandbox` to `init` or `adopt` to also install the dev container config.

### Updating

Updating has two parts: get the new plugin version, then bring each project up
to it.

1. Refresh the marketplace, then update the plugin, then restart Claude Code:

   ```
   claude plugin marketplace update llm-governance
   claude plugin update llm-governance@llm-governance
   ```

   Run both commands. `plugin update` on its own can report "already at the
   latest version" because it works from the cached marketplace catalog.

2. In each project, run `/llm-governance:update`. It shows what changed in the
   new version (from `CHANGELOG.md`), previews the plan, and asks before
   writing. Project records (`llm/*.md`) are never touched.

Projects installed by 0.1.0 have no install record, so the first update
reports any framework file that differs as a conflict ("baseline unknown")
rather than guessing. Accept the plugin's version for each file and later
updates are exact.

## Quick start: manual copy (new project)

```
TARGET=path/to/your/project
cp -r plugin/adapters/claude-code/. "$TARGET"/
mkdir -p "$TARGET"/llm/framework
cp -r plugin/templates/llm/. "$TARGET"/llm/
cp plugin/core/*.md "$TARGET"/llm/framework/
chmod +x "$TARGET"/.claude/hooks/*.sh
```

Then fill in the project sections of the copied `CLAUDE.md`. See
[docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md) for details and
[docs/WALKTHROUGH.md](docs/WALKTHROUGH.md) for the step-by-step version.

For an existing project that already has its own `CLAUDE.md`,
`.claude/settings.json` or `.gitignore`, use the plugin's `/llm-governance:adopt`
(above): it merges instead of overwriting. Copying by hand is meant for new
projects.

## Contributing

- Try local edits to the plugin without installing it:
  `claude --plugin-dir ./plugin`. An installed plugin runs from its cache, so
  it will not see your edits.
- Run the test suites with `bash tests/test_install.sh` (and `test_scan.sh`,
  `test_update.sh`, `test_audit.sh`). They need `bash`, `git` and `jq`. On
  Windows they are slow (minutes); on Linux, for example in the dev container,
  they take seconds.
- Run `claude plugin validate .` and `claude plugin validate ./plugin` before
  releasing. A release needs a version bump in
  `plugin/.claude-plugin/plugin.json` (installed copies only update when the
  version changes) and an entry in `plugin/CHANGELOG.md`.
- New shell scripts need the executable bit recorded in git
  (`git update-index --chmod=+x <file>`); Windows checkouts do not set it.
