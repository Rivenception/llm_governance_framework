---
name: init
description: Install the LLM governance framework (rules, llm/ records, enforcement hooks) into the current project. Safe for new and existing projects; never overwrites project files.
argument-hint: "[--sandbox]"
disable-model-invocation: true
allowed-tools: Read Bash(${CLAUDE_SKILL_DIR}/scripts/install.sh --dry-run *)
---

# Install the LLM governance framework

Install the framework into the project at `${CLAUDE_PROJECT_DIR}`.
Optional argument: `--sandbox` also installs the dev container config.
Arguments given: `$ARGUMENTS`

All file changes are done by the bundled script, which is deterministic,
idempotent and never overwrites project content. Your job is to run it
safely, explain the result, and help with the parts that need judgment.
Do not hand-copy framework files yourself.

Only the `--dry-run` form of the script is pre-approved, and only during your
first turn, so run the dry run (step 2) in that turn before asking the user
anything, and put any question together with the plan. The real install
will trigger Claude Code's own permission prompt, which is the user's
approval gate for writing files. That is intentional; do not try to avoid
it (for example by writing the files another way).

## Steps

1. **Check the target.** `${CLAUDE_PROJECT_DIR}` must be the project root. If it
   plainly is not (for example a home directory or the plugin's own `plugin/`
   directory), stop and ask the user. A repository that merely contains the
   plugin source is a normal project.

2. **Preview.** Run:

   `${CLAUDE_SKILL_DIR}/scripts/install.sh --dry-run $ARGUMENTS "${CLAUDE_PROJECT_DIR}"`

   Summarize the plan in plain language: what will be created, merged, kept
   and what conflicts. Explain each line type if the user is unfamiliar:
   CREATE (new file), MERGE (existing file extended; the user's content is
   preserved), OK (already installed), KEEP (existing project record, left
   alone), CONFLICT (differs from the framework version, left untouched).
   - If it prints a WARN about uncommitted changes or no git repository,
     recommend committing first so the install is a reviewable diff.
   - If the script reports `jq is required`, stop and give the install
     command it prints; the hooks need `jq` too.

3. **Confirm.** Ask the user to approve the plan. Do not continue without a
   clear yes.

4. **Install.** Run the same command without `--dry-run`. Claude Code will ask
   the user to approve this command; tell them that is expected. If the user
   declines or the command is denied, stop and say nothing was written. Exit
   code 0 means done, 2 means done with conflicts left for the user to
   review, 1 means an error (show the output and stop).

5. **Resolve conflicts with the user.** For each CONFLICT, show the user how
   the file differs from the framework's copy (read both, the framework copy is
   under `${CLAUDE_PLUGIN_ROOT}`) and ask what they want. Do not change the
   conflicting file without their decision. Files under `llm/framework/` and
   `.claude/hooks/` are framework-owned: differences usually mean a local edit
   or an older install.

6. **Fill in `CLAUDE.md` placeholders (new projects only).** If the script says
   to fill in placeholders, `CLAUDE.md` has bracketed sections for project
   overview, commands and scope and stack. Ask the user about each and draft
   the text with them. The scope-and-stack section is human-owned: only write
   what the user states or approves, and leave `[...]` where they have not
   decided. Never invent commands, stack choices or requirements.

7. **Wrap up.** Tell the user, briefly:
   - what was installed and what (if anything) needs their attention;
   - hooks are read at session start, so enforcement begins in a new session;
   - the first PROJECT_STATE.md update will be required once project files change;
   - `jq` and `bash` must be available wherever Claude Code runs (including
     inside a dev container).

Do not modify anything under `llm/` other than as the user asks; those
files are the project's records.
