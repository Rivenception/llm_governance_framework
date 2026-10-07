# LLM Governance Framework

A lightweight framework for working with AI coding assistants: a durable,
human-readable record of what changed and why (`llm/`), behavioral rules
that keep the human in charge of the decisions that matter, and hooks that
enforce the record-keeping where the tool allows it.

**Status:** v1. Built and tested for Claude Code only. The long-term goal is
to be LLM-agnostic, which is why tool-neutral content lives in `core/` and
everything Claude Code-specific lives in `adapters/claude-code/`.

## Repo map

| Path | What it is |
|---|---|
| `core/` | Tool-agnostic rules (`RULES.md`) and the `llm/` record spec (`llm-records.md`) |
| `adapters/claude-code/` | Claude Code adapter: `CLAUDE.md`, hooks, settings, `.gitignore` |
| `templates/llm/` | Blank `llm/` record files to drop into a project |
| `examples/llm/` | A populated sample showing the formats in use |
| `sandbox/` | Optional container layer (devcontainer, firewall); scaffold, see its README |
| `skills/` | Reserved for reusable skills (bootstrap, adr, resume, audit) |
| `docs/` | Setup guide, walkthrough, startup checklist, global snippet |

## Quick start (new project, Claude Code)

Requires `bash`, `jq`, and `sha256sum` or `shasum`.

```
TARGET=path/to/your/project
cp -r adapters/claude-code/. "$TARGET"/
mkdir -p "$TARGET"/llm/framework
cp -r templates/llm/. "$TARGET"/llm/
cp core/*.md "$TARGET"/llm/framework/
chmod +x "$TARGET"/.claude/hooks/*.sh
```

Then fill in the project sections of the copied `CLAUDE.md`. See
[docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md) for details and
[docs/WALKTHROUGH.md](docs/WALKTHROUGH.md) for the step-by-step version.

Bootstrapping into an existing project (merging with an existing
`CLAUDE.md`, `.claude/settings.json` and `.gitignore`) is not automated yet;
merge by hand for now.
