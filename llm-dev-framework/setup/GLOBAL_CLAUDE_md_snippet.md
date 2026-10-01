# Global snippet — add this block to ~/.claude/CLAUDE.md
# (applies to every project automatically, keep it short)

## Change tracking convention
Every project should maintain an `llm/` folder for change tracking and an
`.claude/settings.json` with enforcement hooks. If `llm/` doesn't exist in a
project I'm working in, create it using the standard template (ask the user
for the template if not already present, or check for a docs/llm-setup.md /
STARTUP_CHECKLIST.md in the repo).

Core files: llm/PROJECT_STATE.md, llm/CHANGELOG.md, llm/CHANGES.jsonl,
llm/DECISIONS.md, llm/ARCHITECTURE.md, llm/TODO.md, llm/KNOWN_ISSUES.md,
llm/SESSIONS.jsonl (written by the SessionEnd hook).

Full format lives in the project's own CLAUDE.md once created — read that
first if present. Never skip updating llm/PROJECT_STATE.md before ending
a session.
