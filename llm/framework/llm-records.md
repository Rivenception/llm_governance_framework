# Change records (llm/ folder)
This project uses `llm/` for a durable record of AI-assisted changes,
readable by both humans and future assistant sessions. Keep entries factual
and short — detail belongs in code/commits, not here.

## Timestamps
All timestamps in these records are UTC, written without a suffix:
`YYYY-MM-DD HH:MM` (or `YYYY-MM-DD` where only a date is asked for). Take
them from the clock (`date -u "+%Y-%m-%d %H:%M"`), never from memory. One
clock keeps entries in order when sessions run in different time zones or
containers. Entries written before a project adopted this rule may be in
local time; they are not rewritten.

## llm/PROJECT_STATE.md — the current-truth snapshot
Overwrite (not append) this file at the end of every session, and again
right before context compaction. This is the single most important file:
it should let anyone (human or a fresh assistant session) understand the
project's status in under a minute.

## llm/CHANGELOG.md — prose history
Add one entry per logical change (not per file edit), at the TOP of the
file (newest first). Format:
```
## [YYYY-MM-DD HH:MM] Short title
Session: <session-id>
What: 2-4 sentences on what changed and why.
Files: file1.py, file2.py
```

## llm/CHANGES.jsonl — structured per-file log
Append one JSON line per file modified in a change:
```
{"date":"YYYY-MM-DD","session":"<session-id>","file":"src/auth.py","type":"logic-change","summary":"short summary"}
```
`type` is one of: `logic-change`, `bugfix`, `refactor`, `config`, `docs`, `test`

## llm/DECISIONS.md — architecture decision records
Add an entry at the TOP of the file (newest first) when a nontrivial
design choice is made — especially when rejecting an approach:
```
## [YYYY-MM-DD] Decision title
Context: why this came up
Chose: what was picked
Rejected: alternatives considered and why not
Session: <session-id>
```

## llm/ARCHITECTURE.md — static reference
Update only on structural change (new service, new data flow), on request.

## llm/TODO.md — actual roadmap
Update when priorities shift, on request. Not a scratchpad.

## llm/KNOWN_ISSUES.md — bugs, limitations, tech debt
Distinct from TODO.md: this tracks problems that exist now, not planned
work. Add an entry when a bug, limitation, or piece of tech debt is
discovered during a task. Update its status when resolved — don't delete
resolved entries, mark them resolved instead so the history stays intact.
Format:
```
## [YYYY-MM-DD] Short title
Severity: low | medium | high
Status: open | in-progress | resolved | accepted
Files: file1.py, file2.py
Description: what's wrong
Potential solution: if known
```

## Record rules
- Update `llm/PROJECT_STATE.md` with real content before ending any task.
  The content must actually change, not just be touched. Tool adapters may
  enforce this mechanically (see the adapter's instructions file).
- CHANGELOG.md and DECISIONS.md are add-only, newest entry at the top.
  CHANGES.jsonl is add-only, new lines at the end. Never rewrite or delete
  past entries in any of them.
- For KNOWN_ISSUES.md, update status in place (open → in-progress →
  resolved) rather than deleting resolved entries.
- Don't re-read the full CHANGELOG at the start of a session unless asked
  to review history.
