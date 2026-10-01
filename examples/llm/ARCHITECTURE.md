# Architecture
Static reference — how the system fits together. Update on structural
change only, not per session.

## Overview
Node/Express API backed by Postgres. No frontend in this repo (consumed by
a separate client app).

## Components
- `src/auth/` — JWT-based auth. Access tokens (15 min) + refresh tokens
  (7 day, rotated). See llm/DECISIONS.md, 2026-07-29.
- `src/api/` — REST resource routes (`users`, `projects`). Follows a
  consistent controller pattern: `routes.js` registers paths, each resource
  has its own file with handler functions.
- `src/billing/` — stub, not yet implemented.
- `db/` — Postgres schema and migrations, managed via `[migration tool]`.

## Data flow
Client → Express routes → auth middleware (validates access token) →
resource controller → Postgres → response.

## External dependencies
- Postgres (primary datastore)
- [payment provider] — planned for billing, not yet integrated

## Known architectural debt
- No authorization layer (any authenticated user can access any resource) —
  see llm/DECISIONS.md, 2026-07-28.
- No rate limiting.
- No token revocation on logout — see llm/PROJECT_STATE.md open risks.
