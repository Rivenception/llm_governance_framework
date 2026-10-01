# Project instructions for Claude Code

## Project overview
[One paragraph: what this project is, who it's for, current phase.]

## Commands
- Install: `[e.g. npm install]`
- Test: `[e.g. npm test]`
- Run: `[e.g. npm run dev]`

## Project scope and stack
[Fill in — this section is the human-owned source of truth for intent.
Claude should treat it as fixed unless you explicitly change it here.]

You can draft this section collaboratively with Claude during initial
project setup — talk through target users, stack options, and scope in
conversation before writing anything here. That's fine; it's normal
brainstorming, not a violation of "human-owned." The rule kicks in once
you've approved and written the actual content below: from that point,
treat it as settled, and any further change goes through the same
approval process as the rest of Decision ownership. If this section still
has unfilled `[...]` placeholders, treat it as a draft in progress, not
yet-locked policy.

- Target users / purpose: [...]
- Explicitly out of scope: [...]
- Tech stack (languages, frameworks, DB, infra): [...] — not to be swapped
  without your explicit approval, regardless of how good an alternative
  looks mid-task.
- Design/UX conventions: [...]
- Architecture pattern in use (e.g. layered, MVC, none-yet): [...] — don't
  assume a pattern that wasn't specified here.

## Change tracking (llm/ folder)
This project uses `llm/` for a durable record of AI-assisted changes,
readable by both humans and future Claude sessions. Keep entries factual
and short — detail belongs in code/commits, not here.

### llm/PROJECT_STATE.md — the current-truth snapshot
Overwrite (not append) this file at the end of every session, and again
right before context compaction. This is the single most important file:
it should let anyone (human or a fresh Claude session) understand the
project's status in under a minute.

### llm/CHANGELOG.md — prose history
Append one entry per logical change (not per file edit). Format:
```
## [YYYY-MM-DD HH:MM] Short title
Session: <session-id>
What: 2-4 sentences on what changed and why.
Files: file1.py, file2.py
```

### llm/CHANGES.jsonl — structured per-file log
Append one JSON line per file modified in a change:
```
{"date":"YYYY-MM-DD","session":"<session-id>","file":"src/auth.py","type":"logic-change","summary":"short summary"}
```
`type` is one of: `logic-change`, `bugfix`, `refactor`, `config`, `docs`, `test`

### llm/DECISIONS.md — architecture decision records
Append when a nontrivial design choice is made — especially when
rejecting an approach:
```
## [YYYY-MM-DD] Decision title
Context: why this came up
Chose: what was picked
Rejected: alternatives considered and why not
Session: <session-id>
```

### llm/ARCHITECTURE.md — static reference
Update only on structural change (new service, new data flow), on request.

### llm/TODO.md — actual roadmap
Update when priorities shift, on request. Not a scratchpad.

### llm/KNOWN_ISSUES.md — bugs, limitations, tech debt
Distinct from TODO.md: this tracks problems that exist now, not planned
work. Add an entry when a bug, limitation, or piece of tech debt is
discovered during a task. Update its status when resolved — don't delete
resolved entries, mark them resolved instead so the history stays intact.
Format:
```
## [YYYY-MM-DD] Short title
Severity: low | medium | high
Status: open | in-progress | resolved
Files: file1.py, file2.py
Description: what's wrong
Potential solution: if known
```

## Decision ownership
Some decisions are yours; routine implementation decisions are Claude's
to make without asking. Knowing which is which up front avoids both
constant interruption and silent scope creep.

**Requires my approval before changing:**
- Core product goals, scope, or target users
- Fundamental requirements or acceptance criteria
- The tech stack or any non-negotiable technology listed above
- Major architectural patterns
- Security model or data-ownership model
- Deployment strategy or major third-party services
- Significant database migrations
- Any change that substantially increases project complexity

**Claude's call, no need to ask:**
- Function/variable names, internal implementation details
- File organization within already-established boundaries
- Small refactors, bug fixes, test implementation
- Minor dependency configuration
- Routine documentation updates

If a decision could materially affect architecture and doesn't clearly
fall in the second list, explain the tradeoff and ask rather than
deciding silently. When it's genuinely ambiguous, err toward asking.

## Architectural change protocol
If a task seems to require a significant architectural change (new
framework, new database, new state-management approach, replacing auth,
reorganizing the project), don't make it inline while implementing
something else. Instead:
1. Identify the existing architecture and why it's insufficient for the task
2. Propose the new approach and what it affects
3. Flag migration risks
4. Ask for approval before implementing

Adding a feature should never silently result in a framework swap, a
database change, or a project-wide reorganization.

## Task completion standard
A task is only complete when: the requested functionality works, nothing
existing was unintentionally broken, relevant tests pass, important
behavior was actually verified (not assumed), relevant `llm/` docs are
updated, and no temporary files, debug code, or test credentials were
left behind. If something couldn't be verified, say so explicitly rather
than reporting it as done.

Before marking a task done, self-check it against the "Requires my
approval" list above. If anything in the task plausibly touched one of
those items and wasn't explicitly surfaced for approval first, flag that
now, in the task summary — don't wait to be asked. This rule exists
specifically because no hook can detect a skipped approval step; the
self-check is the only enforcement this has, so treat it as mandatory,
not optional.

## Handling uncertainty
Distinguish between what's known, what's a reasonable assumption, what
needs my approval, and what hasn't been verified yet — and say which is
which. Don't invent project requirements, APIs, credentials, or test
results. When there are multiple reasonable approaches with meaningful
long-term consequences, lay out the options and ask rather than picking
one silently.

## Handling personal and sensitive data
Treat application data, credentials, environment variables, uploaded
files, and user information as potentially sensitive by default —
independent of the framework-secrets rule below, which only covers this
project's own tooling config.
- Never commit secrets or hard-code credentials into application code.
- Don't expose sensitive data in logs, error messages, or debug output
  unnecessarily.
- Don't add sensitive files (user data exports, credential dumps, real
  production data) to source control.
- Use synthetic test data instead of real personal data whenever
  synthetic data is sufficient for the test's purpose.
- Follow whatever security requirements this project defines above (see
  Project scope and stack) — this section is a baseline, not a substitute
  for project-specific rules.

## Rules
- Update `llm/PROJECT_STATE.md` with real content before ending any task —
  this is enforced by a Stop hook that checks the file's content actually
  changed (not just that it was touched), so treat it as non-optional.
  Note: Stop fires at the end of every response turn, not only at session
  end, so don't be surprised if this check runs frequently.
- Append-only for CHANGELOG.md, CHANGES.jsonl, and DECISIONS.md — never
  rewrite or delete past entries.
- For KNOWN_ISSUES.md, update status in place (open → in-progress →
  resolved) rather than deleting resolved entries.
- Don't re-read the full CHANGELOG at the start of a session unless asked
  to review history.
- Never put secrets, tokens, or credentials in `.claude/settings.json` —
  it's committed to the repo. Put them in `.claude/settings.local.json`
  instead, and before writing to that file, confirm
  `.claude/settings.local.json` is already listed in `.gitignore`. If it
  isn't, add it before writing any secret to the file — don't assume this
  happens automatically.
