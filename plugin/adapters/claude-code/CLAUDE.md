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

## Session ID and timestamps
A SessionStart hook injects the session ID and start time into your
context. Use that exact session ID in every `Session:` field and in
`CHANGES.jsonl`. All timestamps are UTC. For entry timestamps, run
`date -u "+%Y-%m-%d %H:%M"` — never estimate. If no session ID was injected, write `unknown` rather than
inventing one, and tell me the hook isn't working (usually `jq` missing).

## Framework rules (imported)
These files are copied into the project by the framework installer. They
are the source of truth for behavior and for the `llm/` record formats.

@llm/framework/RULES.md
@llm/framework/llm-records.md

## Claude Code enforcement
- If you modify any project file (anything outside `llm/` and `.claude/`),
  a Stop hook will block the turn from ending until
  `llm/PROJECT_STATE.md`'s content has actually changed, so treat
  updating it as non-optional. Turns that only answer questions or only
  touch `llm/` are not blocked. The hook can't see file changes made via
  the Bash tool, so update PROJECT_STATE.md for those too.
- Never put secrets, tokens, or credentials in `.claude/settings.json` —
  it's committed to the repo. Put them in `.claude/settings.local.json`
  instead, and before writing to that file, confirm
  `.claude/settings.local.json` is already listed in `.gitignore`. If it
  isn't, add it before writing any secret to the file — don't assume this
  happens automatically.
