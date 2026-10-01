# Walkthrough: setting up a new project with this framework

This is the step-by-step version of `SETUP_GUIDE.md` — same
information, laid out as explicit actions rather than reference tables.
Use `docs/STARTUP_CHECKLIST.md` afterward to verify everything took.

## 0. One-time: create your global CLAUDE.md

You only do this once, ever — not per project.

1. Open a terminal.
2. Create a small, throwaway folder outside `~/.claude` and outside your
   home directory root — e.g. `mkdir ~/claude-setup && cd ~/claude-setup`.
   (Don't run `claude` directly from your home directory or from
   `~/.claude` itself — the trust prompt that appears would grant that
   session broader access than you need for this step. See "Trust prompt"
   note below if you hit it.)
3. Run `claude`. If asked "Do you trust the files in this folder?", choose
   **Yes, proceed** — this folder is empty and low-stakes.
4. Once inside the session, run `/memory`.
5. From the menu, choose **User Memory (`~/.claude/CLAUDE.md`)**.
6. Your default editor opens the file (creating it if it doesn't exist).
   Paste in the full contents of `docs/GLOBAL_CLAUDE_md_snippet.md`.
7. Save and close the editor. Claude Code reloads it automatically.
8. Exit the session (`/exit`), then delete the throwaway folder — it has
   no further purpose once this file is saved.

**Trust prompt note:** if you accidentally launched from your home
directory and got asked to trust your entire profile, choose **No, exit**
and restart from step 2 with a small dedicated folder instead. Trusting
your whole home directory is broader access than this step needs.

## 1. Copy the framework pieces into your new repo

1. Locate wherever you've cloned this framework permanently (e.g.
   `~/claude-templates/llm-governance-framework/`).
2. From the framework repo, with `TARGET` set to your new project's root:
   ```
   cp -r adapters/claude-code/. "$TARGET"/
   mkdir -p "$TARGET"/llm/framework
   cp -r templates/llm/. "$TARGET"/llm/
   cp core/*.md "$TARGET"/llm/framework/
   ```
3. Confirm the copy landed correctly: `CLAUDE.md`, `.gitignore`, `.claude/`,
   and `llm/` (with `llm/framework/` inside) should now all be sitting at
   your new project's root.

## 2. Edit CLAUDE.md, the one file that needs your input

Open the copied `CLAUDE.md` and fill in the bracketed placeholders:

- **Project overview**: one paragraph on what this project is, who it's
  for, current phase.
- **Commands**: install / test / run commands for your actual stack.
- **Project scope and stack**: target users, what's explicitly out of
  scope, tech stack, design conventions, architecture pattern in use.
  You can talk this through with Claude conversationally before writing
  the final version here. That's fine, it's brainstorming, not a
  conflict with "human-owned." Just make sure it's actually filled in
  (no leftover `[...]`) before you consider it settled, since from that
  point on it's treated as fixed.

Everything else (the session-ID note, the `@imports` of the core rules,
and the enforcement notes) is ready to use as-is. The rules themselves
(decision ownership, architectural change protocol, completion standard,
personal data handling, record formats) live in `llm/framework/`.

## 3. The llm/ files start blank

The `llm/` files copied from `templates/llm/` are empty skeletons, so
there is nothing to clear. `llm/KNOWN_ISSUES.md` ships with the
`[framework]` entry and the note above it; keep those, they're permanent
documentation about the framework itself. See `examples/llm/` for what
populated files look like.

## 4. Install jq and make the hook scripts executable

Install `jq` first if you don't have it (`jq --version` to check) — the
hooks need it.

From the project root:
```
chmod +x .claude/hooks/*.sh
```
Required once per project. Without it, the SessionStart, Stop, PreCompact, and
SessionEnd hooks will silently fail to run.

## 5. Confirm .gitignore and settings.json

Both are copy-paste-ready, no edits needed:
- `.gitignore` already includes `.claude/settings.local.json`. If your
  project already has its own `.gitignore`, merge that one line into it
  rather than overwriting your existing file.
- `.claude/settings.json` already wires up all four hooks correctly.

## 6. Start Claude Code in the project directory

```
cd path/to/new-project
claude
```

Claude Code automatically reads the project's `CLAUDE.md` (and your
global one) on launch — there's no separate command needed to point it
at the framework. If this is a new folder, you'll see the trust prompt
again; choose **Yes, proceed** since this is your actual project.

## 7. Verify it's working

Run through `docs/STARTUP_CHECKLIST.md` to confirm the folder structure,
`CLAUDE.md` content, hooks, and `.gitignore` are all correctly in place
before you start real work.

---

**Quick reference — what needs editing vs. what's copy-paste:**

| Needs your input | Copy-paste as-is |
|---|---|
| `CLAUDE.md` (overview, commands, scope/stack) | `.claude/settings.json` |
| | `.claude/hooks/*.sh` |
| | `llm/` skeletons and `llm/framework/` |
| | `.gitignore` |
