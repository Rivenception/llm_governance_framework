# Project State
Last updated: 2026-07-29 16:40 | Session: sess_2026-07-29_02

## Status
Working prototype. Auth and core CRUD routes are functional; billing is not
started. No known blockers.

## What just happened (this session)
- Refactored auth middleware to use JWT refresh tokens instead of long-lived
  access tokens (see DECISIONS.md, 2026-07-29 entry).
- Fixed a bug where expired sessions returned a 500 instead of a 401.
- Added tests for the new refresh-token flow.

## Current state of the codebase
- `src/auth/` — refresh-token flow live, covered by tests
- `src/api/` — CRUD routes for `users` and `projects` resources, stable
- `src/billing/` — stub only, not implemented
- `db/` — schema is stable, no pending migrations

## Next recommended task
Implement the billing resource endpoints (`POST /billing/subscribe`,
`GET /billing/status`), following the same route pattern as `src/api/projects`.

## Open risks / questions
- Refresh-token revocation on logout isn't implemented yet — tokens remain
  valid until expiry even after logout. Needs a decision on whether to add
  a revocation list or accept short-lived tokens as sufficient.
- No rate limiting on any endpoint yet.

## How to resume
Run `npm test` to confirm current state, then read `llm/DECISIONS.md`
(2026-07-29 entry) before touching auth code.
