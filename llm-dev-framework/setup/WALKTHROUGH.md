# Walkthrough: setting up a new project with this framework

This is the step-by-step version of `FRAMEWORK_SETUP_GUIDE.md` — same
information, laid out as explicit actions rather than reference tables.
Use `STARTUP_CHECKLIST.md` afterward to verify everything took.

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
   Paste in the full contents of `setup/GLOBAL_CLAUDE_md_snippet.md`.
7. Save and close the editor. Claude Code reloads it automatically.
8. Exit the session (`/exit`), then delete the throwaway folder — it has
   no further purpose once this file is saved.

**Trust prompt note:** if you accidentally launched from your home
directory and got asked to trust your entire profile, choose **No, exit**
and restart from step 2 with a small dedicated folder instead. Trusting
your whole home directory is broader access than this step needs.

## 1. Copy the project template into your new repo

1. Locate wherever you've stored this framework permanently (e.g.
   `~/claude-templates/llm-dev-framework/`).
2. Copy the entire contents of `project-template/` — not the `setup/`
   folder — into your new project's root directory:
   ```
   cp -r ~/claude-templates/llm-dev-framework/project-template/. path/to/new-project/
   ```
3. Confirm the copy landed correctly: `CLAUDE.md`, `.gitignore`, `.claude/`,
   and `llm/` should now all be sitting at your new project's root.

## 2. Edit CLAUDE.md — the one file that needs your input

Open the copied `CLAUDE.md` and fill in the bracketed placeholders:

- **Project overview** — one paragraph: what this project is, who it's
  for, current phase.
- **Commands** — install / test / run commands for your actual stack.
- **Project scope and stack** — target users, what's explicitly out of
  scope, tech stack, design conventions, architecture pattern in use.
  You can talk this through with Claude conversationally before writing
  the final version here — that's fine, it's brainstorming, not a
  conflict with "human-owned." Just make sure it's actually filled in
  (no leftover `[...]`) before you consider it settled, since from that
  point on it's treated as fixed.

Everything else in the file — the change-tracking spec, decision-ownership
list, architectural change protocol, task completion standard, personal
data handling, and rules — is
already complete and ready to use as-is.

## 3. Clear example content from the llm/ files

For each of these, delete the sample entries but keep the file's header
and section format:
- `llm/PROJECT_STATE.md`
- `llm/CHANGELOG.md`
- `llm/CHANGES.jsonl` (leave empty)
- `llm/DECISIONS.md`
- `llm/ARCHITECTURE.md`
- `llm/TODO.md`
- `llm/SESSIONS.jsonl` (leave empty or delete — the SessionEnd hook
  recreates it)

**One exception:** in `llm/KNOWN_ISSUES.md`, delete only the three example
bug entries (the token-revocation, authorization-check, and flaky-test
examples). Keep the `[framework]` entry and the note above it — that's
permanent documentation about the framework itself, not example content.

## 4. Make the hook scripts executable

From the project root:
```
chmod +x .claude/hooks/*.sh
```
Required once per project. Without it, the Stop, PreCompact, and
SessionEnd hooks will silently fail to run.

## 5. Confirm .gitignore and settings.json

Both are copy-paste-ready, no edits needed:
- `.gitignore` already includes `.claude/settings.local.json`. If your
  project already has its own `.gitignore`, merge that one line into it
  rather than overwriting your existing file.
- `.claude/settings.json` already wires up all three hooks correctly.

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

Run through `STARTUP_CHECKLIST.md` to confirm the folder structure,
`CLAUDE.md` content, hooks, and `.gitignore` are all correctly in place
before you start real work.

---

**Quick reference — what needs editing vs. what's copy-paste:**

| Needs your input | Copy-paste as-is |
|---|---|
| `CLAUDE.md` (overview, commands, scope/stack) | `.claude/settings.json` |
| `llm/*` files (clear examples, keep structure) | `.claude/hooks/*.sh` |
| | `.gitignore` |
