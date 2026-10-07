---
name: adopt
description: Adopt the LLM governance framework in an existing project. Scans the codebase read-only, installs the framework without overwriting anything, and drafts ARCHITECTURE.md and PROJECT_STATE.md for the user to confirm.
argument-hint: "[--sandbox]"
disable-model-invocation: true
allowed-tools: Read Bash(${CLAUDE_SKILL_DIR}/scripts/scan.sh *) Bash(${CLAUDE_SKILL_DIR}/scripts/install.sh --dry-run *)
---

# Adopt the LLM governance framework in this project

Project: `${CLAUDE_PROJECT_DIR}`. Optional argument: `--sandbox` also installs
the dev container config. Arguments given: `$ARGUMENTS`
Session: `${CLAUDE_SESSION_ID}`

You are adding the framework to a project that already has code, and maybe
its own `CLAUDE.md`, `.claude/settings.json` and `.gitignore`. Two rules
govern everything below:

1. **Existing project content is never overwritten.** All installing and
   merging is done by the bundled script, not by you. Do not hand-copy
   framework files.
2. **Nothing you draft is fact until the user confirms it.** Drafts come only
   from evidence (the scan, files you read) and are marked unconfirmed.
   The project's scope and stack is human-owned: you may propose it, but you
   never write it as settled.

Only the scan and the `--dry-run` form of the installer are pre-approved. The
real install and every file you write will trigger Claude Code's own
permission prompt. That is the user's approval gate; do not route around it.

## Steps

1. **Preflight.** `${CLAUDE_PROJECT_DIR}` must be the project root. If it
   plainly is not (home directory, the framework repo itself), stop and ask.
   If the project is not a git repository, or the scan shows uncommitted
   changes, strongly recommend committing (ideally on a new branch) first so
   the adoption is one reviewable diff. Proceed only if the user insists.

2. **Scan.** Run `${CLAUDE_SKILL_DIR}/scripts/scan.sh "${CLAUDE_PROJECT_DIR}"`.
   It is read-only and redacts secret-looking lines. Never open `.env` files,
   keys, certificates or credential files yourself, and never put values like
   those in anything you write.

3. **Read selectively.** Using Read, open only what you need to describe the
   project truthfully: the README, the manifests the scan lists, the entry
   points, and any existing `CLAUDE.md` / `AGENTS.md` (honor their existing
   conventions). Keep it proportionate; this is not a code audit. Note what you
   could not determine.

4. **Plan the install.** Run
   `${CLAUDE_SKILL_DIR}/scripts/install.sh --dry-run $ARGUMENTS "${CLAUDE_PROJECT_DIR}"`
   and explain the plan: CREATE (new), MERGE (existing file extended, user
   content preserved), OK (already installed), KEEP (existing project record,
   left alone), CONFLICT (differs, left untouched). If it reports `jq is
   required`, stop and give the install command it prints.

5. **Confirm, then install.** Ask for a clear yes. Then run the same command
   without `--dry-run`; the user will get a permission prompt for it, which is
   expected. If it is declined, stop and say nothing was written. Exit code 0
   is done, 2 is done with conflicts, 1 is an error (show output and stop).
   Resolve any CONFLICT with the user, showing the difference; never change a
   conflicting file without their decision.

6. **Draft `llm/ARCHITECTURE.md`.** Fill it only if it is still the blank
   skeleton; if it has real content, leave it and propose additions in chat.
   - Begin the file with this line, with today's date from `date`:
     `> **DRAFT, unconfirmed.** Generated from a read-only scan on <date> (session ${CLAUDE_SESSION_ID}). Verify before relying on it; delete this line once reviewed.`
   - Describe only what the evidence supports (components, directory
     responsibilities, data flow, external dependencies), citing the paths you
     saw. Hedge inferences ("appears to"). Put gaps under an **Open questions**
     heading. Do not invent components, services, or intent.
   - Known architectural debt: only items you actually observed.

7. **Draft `llm/PROJECT_STATE.md`** the same way, with one placement rule:
   the file's first two lines stay the title and the `Last updated:` line
   (leave its text as is; the Stop hook stamps it), and the DRAFT line goes
   after them. The hook only restamps within the first three lines.
   Status = what is observable (builds? tests exist? recent commit
   subjects). "What just happened" = the adoption itself. "Next recommended
   task" = the user reviews and confirms the drafts and the scope/stack
   proposal. Open risks = real unknowns only.

8. **Propose scope and stack.** Check whether the project's `CLAUDE.md` has a
   scope-and-stack section (the scan says). If not, present a proposal in
   chat: target users/purpose, tech stack and versions as seen in manifests,
   architecture pattern, explicitly out of scope (leave blank unless the user
   says), design conventions. Mark every item as *observed* or *guess*. Write
   it into `CLAUDE.md` as a new `## Project scope and stack` section only
   after the user approves, and keep `[...]` for anything undecided. Do not
   edit the user's existing sections.

9. **Record the adoption.** Add one entry at the top of `llm/CHANGELOG.md`
   (`## [YYYY-MM-DD HH:MM] Adopt LLM governance framework`, `Session:
   ${CLAUDE_SESSION_ID}`, what changed in 2-4 sentences, files: the framework
   files, plus `CLAUDE.md`, `.gitignore`, `.claude/settings.json` if merged).
   Add one `llm/CHANGES.jsonl` line for each of those three existing files
   that were merged, and for each draft you wrote. Take the timestamp from
   `date`, never estimate.

10. **Wrap up, briefly.** What was installed and what needs the user's
    attention (drafts to review, conflicts); hooks are read at session start so
    enforcement begins in a new session; suggest committing the adoption as a
    single commit; `jq` and `bash` must be available wherever Claude Code runs.
