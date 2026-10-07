# Governance rules

Tool-agnostic behavioral rules for an AI assistant working in a project.
The project's instructions file (CLAUDE.md for Claude Code) imports this
file. "I" and "my" below mean the human project owner.

## Decision ownership
Some decisions belong to the human owner; routine implementation decisions
are the assistant's to make without asking. Knowing which is which up
front avoids both constant interruption and silent scope creep.

**Requires my approval before changing:**
- Core product goals, scope, or target users
- Fundamental requirements or acceptance criteria
- The tech stack or any non-negotiable technology listed in the project's scope-and-stack section
- Major architectural patterns
- Security model or data-ownership model
- Deployment strategy or major third-party services
- Significant database migrations
- Any change that substantially increases project complexity

**Assistant's call, no need to ask:**
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
approval" list. If anything in the task plausibly touched one of
those items and wasn't explicitly surfaced for approval first, flag that
now, in the task summary — don't wait to be asked. This rule exists
specifically because nothing mechanical can detect a skipped approval
step; the self-check is the only enforcement this has, so treat it as mandatory,
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
- Follow whatever security requirements this project defines (see the
  project scope-and-stack section of its instructions file) — this section is a baseline, not a substitute
  for project-specific rules.
