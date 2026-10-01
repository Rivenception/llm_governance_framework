# Decisions
Architecture Decision Records. Append-only, newest at top. Log real forks in
the road — not every small choice.

## [2026-07-29] Refresh tokens over long-lived access tokens
Context: The original auth implementation issued a single long-lived JWT
(7-day expiry) as both identity and session proof. If a token leaked, an
attacker had up to 7 days of valid access with no way to revoke it short of
rotating the signing secret for all users.
Chose: Short-lived access tokens (15 min) plus a separate refresh token
(7-day expiry, rotated on use) stored httpOnly. Reduces the exposure window
for a leaked access token to 15 minutes.
Rejected:
- Session-store-backed tokens (Redis-backed opaque tokens) — would allow
  instant revocation, but adds an infrastructure dependency this project
  doesn't otherwise need yet. Revisit if revocation-on-logout becomes a hard
  requirement (see PROJECT_STATE.md open risks).
- Keeping long-lived tokens but shortening expiry to 1 day — simpler, but
  doesn't solve the "no revocation" problem, just narrows the window.
Session: sess_2026-07-29_02

## [2026-07-28] No authorization checks on projects CRUD yet
Context: Initial CRUD routes needed to ship to unblock frontend work.
Chose: Ship routes with authentication (must be logged in) but no
authorization (any logged-in user can edit any project). Tracked as a
follow-up in TODO.md rather than blocking the initial routes.
Rejected: Building full role-based access control before shipping any
routes — would have delayed frontend integration by an estimated 2-3 days
for a project still validating basic functionality.
Session: sess_2026-07-28_01
