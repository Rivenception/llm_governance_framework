# Known Issues
Bugs, limitations, and tech debt that exist right now — distinct from
TODO.md (planned work). Update status in place; don't delete resolved
entries.

New entries use `## [YYYY-MM-DD] Short title` (see llm/framework/llm-records.md
for the full template). The one exception is directly below: `[framework]` in place of
a date marks a permanent note about the framework itself, not a dated
occurrence — don't copy that header style for actual bugs.

## [framework] Decision-ownership and architecture-protocol rules are prose-only
Severity: medium
Status: accepted
Files: llm/framework/RULES.md
Description: Accepted by design. The "requires my approval" list and
architectural change protocol are natural-language instructions, not
hook-enforced. Nothing blocks the assistant from making one of those
changes without asking; the only safeguard is the self-check it runs
before marking a task done (see RULES.md, Task completion standard).
Potential solution: A PreToolUse hook flagging edits to sensitive paths
(package.json, config root, migration files) for confirmation would add
real enforcement here, if this ever proves insufficient in practice.
