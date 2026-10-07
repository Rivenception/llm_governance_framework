# TODO
Actual roadmap, prioritized. Not a scratchpad — if it's not worth doing,
remove it rather than letting it sit.

## Now
- [ ] Fill in the `[...]` placeholders in the root `CLAUDE.md`: project overview, commands, and scope and stack. Scope and stack is the owner's to define. A proposal (marked observed vs guess) was shown during the adoption session; ask Claude to redraft it from the repo and edit it before it is written.
- [ ] Review and confirm the two adoption drafts, `llm/ARCHITECTURE.md` and `llm/PROJECT_STATE.md`, then delete their DRAFT lines.
- [ ] Decide the root `.devcontainer/`: track it as this repo's own dev environment, or remove it. `plugin/sandbox/devcontainer.json` is the shippable copy (they differ only in the name).
- [ ] Choose a license. There is none yet and it is needed before wider publishing.

## Next
- [ ] Release the next plugin version. `plugin/CHANGELOG.md` has an Unreleased section (update dry-run version stamp, Windows line-ending protection, skill preflight fixes). Follow the release checklist in the README, then verify the two-step update.
- [ ] Sandbox module: implement `plugin/sandbox/init-firewall.sh` as an original implementation (default deny, editable `allowed-domains.txt`, no blanket outbound SSH, fail closed, self-test), fill `allowed-domains.txt`, write `docs/SANDBOX_THREAT_MODEL.md`, decide whether the `Dockerfile` is needed, and wire `--sandbox` through `init`/`adopt` end to end. Anthropic's reference container is proprietary, so none of its files may be copied.
- [ ] Decide the timestamp convention for `llm/` entries. The spec says local `date`, but a host session (local time) and a container session (UTC) produced entries that sort out of order. UTC (`date -u`) is the likely answer; the rules, the skills and the audit's newest-first check would then agree.
- [ ] Look into the one-off garbled `.gitattributes` seen when `update` ran in the dev container against the Windows bind mount (not reproducible in four attempts). Appends are now single writes; consider also writing edits to user files via a temp file and rename.
- [ ] Add CI: run the four suites in `tests/` on Linux on every push (they take seconds there), plus an occasional Windows run (minutes). There is no CI config today.
- [ ] Check whether Claude Code's startup auto-update picks up new plugin versions without the manual commands. `plugin update` alone worked once and reported "already latest" another time.
- [ ] Find out which hook events Claude Code reloads mid-session (the Stop and PostToolUse hooks fired in the adoption session without a restart) and correct the skills' "hooks start in a new session" wrap-up text; see KNOWN_ISSUES.
- [ ] Test the skills in interactive (not `-p`) sessions and with plugin scopes other than `user`.

## Later / unscheduled
- [ ] Add technology badges to the README (owner's reminder; it also sits in `examples/llm/TODO.md` as a placeholder, which can be removed from there now that this file exists).
- [ ] LLM-agnostic support beyond Claude Code: add adapters next to `plugin/adapters/claude-code/`; `plugin/core/` is already tool-neutral.
- [ ] Let projects record intentional edits to framework files (for example a `LOCAL_OVERRIDES` list) so `update` stops reporting them as conflicts every time.
- [ ] `update`: remove settings hook entries that point at scripts a release renamed (today it only warns).
- [ ] Automated release test using the simulated smart-HTTP git remote (Claude Code clones shallowly and rejects `file://` marketplace URLs).
- [ ] Pin the root `.gitattributes` itself to LF (it is CRLF in the working tree with `core.autocrlf=true`, which git tolerates).
- [ ] Behavior of the `adopt` scan on very large repositories and monorepos.
- [ ] Hosts without bash on Windows: today the audit tells people to install Git Bash/`jq`; consider whether a PowerShell path is worth it.
