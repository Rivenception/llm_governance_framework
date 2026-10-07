---
name: update
description: Update the LLM governance framework files in this project to the installed plugin version. Refreshes hooks, rules and the CLAUDE.md framework block; never touches project records; reports edited files as conflicts instead of overwriting them.
disable-model-invocation: true
allowed-tools: Read Bash(${CLAUDE_SKILL_DIR}/scripts/update.sh --dry-run *)
---

# Update the LLM governance framework in this project

Project: `${CLAUDE_PROJECT_DIR}`. Session: `${CLAUDE_SESSION_ID}`.

This brings the framework-owned files (hooks, `llm/framework/`, the framework
block in `CLAUDE.md`, hook entries in `.claude/settings.json`) up to the
version of the installed plugin. Two rules:

1. **The bundled script does all file changes.** Do not hand-copy framework
   files. Project records (`llm/*.md` other than `llm/framework/`) are never
   modified by the update.
2. **Edited files are conflicts, never overwritten.** A framework file is
   updated only if it still matches the hash recorded at install time. If the
   user edited it, or the baseline is unknown, it is left alone and the user
   decides.

Only the `--dry-run` form is pre-approved. The real update triggers Claude
Code's own permission prompt, which is the user's approval gate for writing
files. Do not route around it.

## Steps

1. **Preview.** Run
   `${CLAUDE_SKILL_DIR}/scripts/update.sh --dry-run "${CLAUDE_PROJECT_DIR}"`.
   - If it says the framework is not installed, stop and point the user to the
     `init` (new project) or `adopt` (existing project) skill.
   - If it refuses a downgrade, tell the user to update the plugin first.
   - If it reports `jq is required`, give the install command it prints.
   - If the working tree is dirty or there is no git repo, recommend committing
     first so the update is one reviewable diff.

2. **Explain what changes.** State the installed and available versions. Read
   `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md` and summarize, in plain language, the
   entries between those versions (what is new, anything that changes behavior).
   Then walk through the plan: UPDATE (unedited file refreshed), CREATE (new
   file), REMOVE (file the framework dropped), MERGE (settings/`.gitignore`
   additions or `CLAUDE.md` markers added), OK (already current), CONFLICT
   (left untouched), WARN (needs a look). If nothing but OK lines, say the
   project is up to date and stop.

3. **Confirm, then update.** Ask for a clear yes. Then run the same command
   without `--dry-run`; the user will get a permission prompt for it. If it is
   declined, stop and say nothing was written. Exit code 0 is done, 2 is done
   with conflicts (the version stamp is held back until they are resolved), 1
   is an error (show the output and stop).

4. **Resolve conflicts with the user, one at a time.** For each CONFLICT, read
   the project's file and the plugin's version and show what differs. The
   plugin's copy lives at:
   - `llm/framework/<f>`: `${CLAUDE_PLUGIN_ROOT}/core/<f>`
   - `.claude/hooks/<f>`: `${CLAUDE_PLUGIN_ROOT}/adapters/claude-code/.claude/hooks/<f>`
   - `CLAUDE.md` framework block: the part of
     `${CLAUDE_PLUGIN_ROOT}/adapters/claude-code/CLAUDE.md` from the
     "Session ID and timestamps" heading onward
   - `.devcontainer/devcontainer.json`: `${CLAUDE_PLUGIN_ROOT}/sandbox/devcontainer.json`

   Ask which they want: **take the plugin's version** (re-run the script with
   `--accept-new <path>`, using `CLAUDE.md` for the framework block; this
   triggers a permission prompt), **keep theirs**, or **merge by hand** (only
   if they direct it). Make clear that a kept or hand-merged framework file will
   be reported as a conflict again at every future update, and that project
   customizations belong in the project's own `CLAUDE.md` sections instead of
   in framework files. Once all conflicts are settled, re-run the update so the
   version stamp advances.

5. **Record the update.** Add one entry at the top of `llm/CHANGELOG.md`
   (`## [YYYY-MM-DD HH:MM] Update LLM governance framework <old> -> <new>`,
   `Session: ${CLAUDE_SESSION_ID}`, 2-4 sentences, files list) and one
   `llm/CHANGES.jsonl` line per framework file that was updated, created or
   removed. Take the timestamp from `date`, never estimate. These logs are
   add-only: put the CHANGELOG entry at the top with an edit, and append the
   `CHANGES.jsonl` lines at the end (for example with `printf ... >>`). Never
   rewrite either file wholesale.

6. **Wrap up, briefly.** What changed; any conflicts still open (and that the
   version stamp is held back while they are); hooks are read at session start
   so updated hooks apply from a new session; suggest committing the update as
   one commit.
