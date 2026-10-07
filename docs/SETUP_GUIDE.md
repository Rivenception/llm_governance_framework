# AI Dev-Tracking Framework — setup guide

This is the setup guide for the framework itself, not for any project built
with it. Each project you build should have its own `README.md`.

A two-pronged system for working collaboratively with Claude Code: a
human-readable record of what changed and why, plus a machine-readable log
and enforcement hooks so the record can't be silently skipped.

## What's in this repo

| Path | Purpose |
|---|---|
| `plugin/core/RULES.md` | Tool-agnostic behavioral rules (decision ownership, architectural change protocol, completion standard, uncertainty, sensitive data) |
| `plugin/core/llm-records.md` | Tool-agnostic spec for the `llm/` record folder (formats, add-only rules) |
| `plugin/templates/llm/` | Blank skeletons of the `llm/` files; includes the standing `[framework]` note in `KNOWN_ISSUES.md` |
| `examples/llm/` | A populated sample (fictional Node/Express project) showing the formats in use |
| `plugin/adapters/claude-code/CLAUDE.md` | Project instructions file: project-specific sections to fill in, plus `@imports` of the core files |
| `plugin/adapters/claude-code/.claude/settings.json` | Wires up the SessionStart, PostToolUse, Stop, PreCompact, and SessionEnd hooks |
| `plugin/adapters/claude-code/.claude/hooks/session_start.sh` | Injects the session ID and datetime into Claude's context so llm/ entries use real values |
| `plugin/adapters/claude-code/.claude/hooks/mark_dirty.sh` | PostToolUse: flags the session when a file outside `llm/` and `.claude/` is edited |
| `plugin/adapters/claude-code/.claude/hooks/check_project_state.sh` | Stop: if the session is flagged, blocks until PROJECT_STATE.md's content actually changes |
| `plugin/adapters/claude-code/.claude/hooks/lib.sh` | Shared helpers (jq check, sha256, path handling) sourced by the other hooks |
| `plugin/adapters/claude-code/.claude/hooks/check_precompact.sh` | Advisory reminder before context compaction |
| `plugin/adapters/claude-code/.claude/hooks/log_session_end.sh` | Advisory logger: appends to llm/SESSIONS.jsonl on real session end |
| `plugin/adapters/claude-code/.gitignore` | Pre-includes `.claude/settings.local.json` (secrets) and the hooks' local state dir |
| `plugin/sandbox/` | Optional container module: working `devcontainer.json`; `Dockerfile` and `init-firewall.sh` are empty placeholders. See `plugin/sandbox/README.md` |
| `plugin/skills/` | The plugin's skills: `init`, `adopt`, `update`, `audit` (each a `SKILL.md` plus a deterministic script) |
| `docs/GLOBAL_CLAUDE_md_snippet.md` | Paste into `~/.claude/CLAUDE.md` once; makes every project aware of the convention |
| `docs/STARTUP_CHECKLIST.md` | Run through when starting (or auditing) a project |
| `docs/WALKTHROUGH.md` | Step-by-step version of the setup below, with explicit commands |

## Prerequisites

- `bash` (Git Bash on Windows works), `jq`, and `sha256sum` or `shasum`.
- **`jq` is required.** Without it the hooks print a visible error and
  PROJECT_STATE enforcement does not run. Windows: `winget install jqlang.jq`
  or `choco install jq`; macOS: `brew install jq`.

## How to set up a new project

Run these from the framework repo, with `TARGET` set to your project root:

```
cp -r plugin/adapters/claude-code/. "$TARGET"/
mkdir -p "$TARGET"/llm/framework
cp -r plugin/templates/llm/. "$TARGET"/llm/
cp plugin/core/*.md "$TARGET"/llm/framework/
chmod +x "$TARGET"/.claude/hooks/*.sh
```

1. One-time: append `docs/GLOBAL_CLAUDE_md_snippet.md` to `~/.claude/CLAUDE.md`
2. Run the commands above. If the project already has a `.gitignore`,
   `CLAUDE.md`, or `.claude/settings.json`, merge by hand instead of
   overwriting (or use the `adopt` skill, which merges for you).
3. Fill in the project overview / commands / scope sections of the
   project's `CLAUDE.md`
4. Run through `docs/STARTUP_CHECKLIST.md`

The `llm/` files start blank, and `llm/framework/` holds the imported core
rules. Keep the `[framework]` entry in `KNOWN_ISSUES.md`: it's a standing
note about the framework itself.

From that point, Claude Code picks up the convention automatically, with no
re-instruction needed at the start of future sessions.

## Session commands for regular use

| Command | What it does |
|---|---|
| `claude` | Starts a fresh session in the current directory |
| `claude -c` / `claude --continue` | Resumes your most recent session automatically, no picker |
| `claude -r` / `claude --resume` | Opens a picker to choose from past sessions |
| `/clear` | Ends the current session and starts a new one (new session ID), while staying inside Claude Code. Fires `SessionEnd` (reason: `clear`), then `SessionStart` |
| `/exit` | Fully closes Claude Code, back to your normal terminal. Fires `SessionEnd` (reason varies by version — `exit` or `other`) |
| `/compact` | Summarizes the current conversation to free up context, without ending the session. Does not fire `SessionEnd` or `Stop` |
| Closing the terminal / Ctrl+D | Also ends the session; everything is autosaved continuously so nothing is lost |

There's no timeout — sessions don't expire from inactivity. Ending one is always one of the actions above, not something that happens automatically in the background.

## Design notes
- `PROJECT_STATE.md` is the single most important file: overwritten (not
  appended), it answers "where are we right now" in under a minute for
  anyone — human or a fresh Claude session.
- `CHANGELOG.md` / `CHANGES.jsonl` are append-only and update per logical
  change, not per session.
- `DECISIONS.md` is judgment-based — no hook can detect "a decision
  happened," so this one relies on the core rules and periodic
  human review.
- `ARCHITECTURE.md` and `TODO.md` update on request, not on a timer.
- The core rules cover behavior, not just file-tracking conventions:
  a decision-ownership boundary (what needs your approval vs. what
  Claude can decide alone), an architectural-change protocol (propose
  and get approval before a big restructure, rather than reshaping the
  app mid-feature), a task-completion standard (don't report something
  done without verifying it), and explicit uncertainty-handling rules
  (state what's known vs. assumed vs. unverified, don't invent
  requirements or results). These are enforced only by the model reading
  and following CLAUDE.md — there's no hook that can verify "did Claude
  actually ask before a big architectural change," so treat this layer
  as strong guidance, not a guarantee, the same as DECISIONS.md.
- `KNOWN_ISSUES.md` is separate from `TODO.md`: TODO is planned work,
  KNOWN_ISSUES is problems that exist right now (bugs, limitations, tech
  debt). Status is updated in place (open → in-progress → resolved)
  rather than deleting entries, so it stays a real history.
- `CLAUDE.md`'s "Handling personal and sensitive data" section covers the
  *application's* data (user info, uploaded files, test data) — distinct
  from the Rules-section instruction about framework secrets
  (`.claude/settings.local.json`), which only covers this project's own
  tooling config. Both are needed; they protect different things.
- Claude cannot see its own session ID or the clock. `session_start.sh`
  injects both via `additionalContext` at session start, and CLAUDE.md
  tells Claude to use them (and `date` for timestamps) instead of guessing.
- The Stop hook's retry guard (`stop_hook_active`) means a block fires once
  per turn; Claude can ignore it on the retry. Treat the hook as a strong
  nudge, not a hard guarantee.
- Hook commands use `$CLAUDE_PROJECT_DIR` so they work regardless of the
  directory Claude is currently in.
- **Enforcement lives on `Stop`, not `SessionEnd`.** `Stop` fires at the end
  of *every response turn*, not just when a session truly ends — and it's
  the only one of the two that can actually block anything. `SessionEnd`
  fires on real session boundaries (`/exit`, `/clear`, logout) but is
  advisory-only in Claude Code: it cannot block termination, and some
  versions have had it fail to fire reliably on every exit path. So
  `SessionEnd` is used here purely to log the boundary to
  `llm/SESSIONS.jsonl` — the actual safety net is still `Stop`.
- **Enforcement only applies to turns that changed project files.** A
  PostToolUse hook (`mark_dirty.sh`) drops a marker in
  `.claude/hooks/.state/` when Edit/Write/MultiEdit/NotebookEdit touches a
  file outside `llm/` and `.claude/`. The Stop hook does nothing on turns
  without the marker, so Q&A turns and `llm/`-only turns pass freely. The
  marker is cleared only once PROJECT_STATE.md has really changed, so a
  block that Claude skips via the retry guard persists to the next turn.
  **Known gap:** changes made through the Bash tool (`sed -i`, scripts,
  git operations) are not detected, so a turn that only changes files
  that way won't be flagged.
- `SessionStart` records a baseline hash of PROJECT_STATE.md the first
  time it runs in a project, so a blank template left unchanged after
  real work is blocked like any other unchanged state.
- Because `Stop` fires so often, the check can't just be "was the file
  touched recently" — that would trivially pass forever after the first
  edit, including from the hook's own auto-stamp step. Instead,
  `check_project_state.sh` hashes the file's content (excluding the
  `Last updated:` line it stamps) and only allows the session to continue once that hash
  has actually changed since the last check.
- The Stop hook auto-stamps the session ID and timestamp onto
  `PROJECT_STATE.md`'s header line using the `session_id` field Claude Code
  passes to every hook on stdin — no manual lookup needed. This depends on
  `jq` being installed and on your Claude Code version exposing
  `session_id` to the Stop event; if the header shows "unknown," check both.
