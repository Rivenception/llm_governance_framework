# Known Issues
Bugs, limitations, and tech debt that exist right now — distinct from
TODO.md (planned work). Update status in place; don't delete resolved
entries.

New entries use `## [YYYY-MM-DD] Short title` (see CLAUDE.md for the full
template). The one exception is directly below: `[framework]` in place of
a date marks a permanent note about the framework itself, not a dated
occurrence — don't copy that header style for actual bugs.

## [framework] Decision-ownership and architecture-protocol rules are prose-only
Severity: medium
Status: accepted (by design, see llm/DECISIONS.md if you revisit this)
Files: CLAUDE.md
Description: The "requires my approval" list and architectural change
protocol in CLAUDE.md are natural-language instructions, not hook-
enforced. Nothing blocks Claude from making one of those changes without
asking; the only safeguard is the self-check Claude runs before marking
a task done (see CLAUDE.md, Task completion standard).
Potential solution: A PreToolUse hook flagging edits to sensitive paths
(package.json, config root, migration files) for confirmation would add
real enforcement here, if this ever proves insufficient in practice.

## [2026-07-29] No refresh-token revocation on logout
Severity: medium
Status: open
Files: src/auth/tokens.js
Description: Refresh tokens remain valid until natural expiry even after
a user logs out. No revocation list exists yet.
Potential solution: Redis-backed revocation list, or accept short-lived
tokens as sufficient (see llm/DECISIONS.md, 2026-07-29).

## [2026-07-28] No authorization checks on projects CRUD
Severity: high
Status: in-progress
Files: src/api/projects.js
Description: Any authenticated user can read/edit/delete any project,
not just their own. Shipped without authorization to unblock frontend
work (see llm/DECISIONS.md, 2026-07-28).
Potential solution: Add ownership check middleware before project routes.

## [2026-07-26] Flaky test in users.test.js
Severity: low
Status: resolved
Files: tests/users.test.js
Description: `should reject duplicate email` occasionally passed even
with a duplicate, due to a race in the test's setup/teardown order.
Potential solution: Fixed by awaiting teardown before the next test's
setup. Resolved 2026-07-27.
