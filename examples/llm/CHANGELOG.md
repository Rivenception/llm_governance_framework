# Changelog
Prose history of logical changes. Add-only, newest at top.

## [2026-07-29 16:35] Switch auth to JWT refresh-token flow
Session: sess_2026-07-29_02
What: Replaced long-lived access tokens with short-lived access tokens plus
refresh tokens, to reduce the exposure window if a token leaks. Existing
sessions are invalidated on deploy; users will need to log in once.
Files: src/auth/middleware.js, src/auth/tokens.js, src/auth/routes.js, tests/auth.test.js

## [2026-07-29 15:10] Fix 500 on expired session
Session: sess_2026-07-29_02
What: Expired sessions were hitting an unhandled null check and returning a
raw 500. Now returns a proper 401 with a "session expired" message.
Files: src/auth/middleware.js

## [2026-07-28 11:00] Initial CRUD routes for projects resource
Session: sess_2026-07-28_01
What: Added create/read/update/delete routes for the `projects` resource,
mirroring the pattern already used for `users`. Includes basic validation
but no authorization checks yet (tracked in TODO.md).
Files: src/api/projects.js, src/api/routes.js, tests/projects.test.js
