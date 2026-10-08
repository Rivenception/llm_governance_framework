# TODO
Actual roadmap, prioritized. Not a scratchpad — if it's not worth doing,
remove it rather than letting it sit.

## Now
- [ ] Choose a license. There is none yet and it is needed before wider publishing.

## Next
- [ ] Sandbox module: implement `plugin/sandbox/init-firewall.sh` as an original implementation (default deny, editable `allowed-domains.txt`, no blanket outbound SSH, fail closed, self-test), fill `allowed-domains.txt`, write `docs/SANDBOX_THREAT_MODEL.md`, decide whether the `Dockerfile` is needed, and wire `--sandbox` through `init`/`adopt` end to end. Anthropic's reference container is proprietary, so none of its files may be copied.
- [ ] Look into the one-off garbled `.gitattributes` seen when `update` ran in the dev container against the Windows bind mount (not reproducible in four attempts). Appends are now single writes; consider also writing edits to user files via a temp file and rename.
- [ ] Add CI: run the four suites in `tests/` on Linux on every push (they take seconds there), plus an occasional Windows run (minutes). There is no CI config today.
- [ ] Check whether Claude Code's startup auto-update picks up new plugin versions without the manual commands. `plugin update` alone worked once and reported "already latest" another time.
- [ ] Find out which hook events Claude Code reloads mid-session (the Stop and PostToolUse hooks fired in the adoption session without a restart) and correct the skills' "hooks start in a new session" wrap-up text; see KNOWN_ISSUES.
- [ ] Confirm `llm/SESSIONS.jsonl` gets a line when a desktop session ends (the hook works in `claude -p`; see KNOWN_ISSUES).
- [ ] Test the skills in interactive (not `-p`) sessions and with plugin scopes other than `user`.

## Later / unscheduled
- [ ] LLM-agnostic support beyond Claude Code: add adapters next to `plugin/adapters/claude-code/`; `plugin/core/` is already tool-neutral.
- [ ] Let projects record intentional edits to framework files (for example a `LOCAL_OVERRIDES` list) so `update` stops reporting them as conflicts every time.
- [ ] `update`: remove settings hook entries that point at scripts a release renamed (today it only warns).
- [ ] Automated release test using the simulated smart-HTTP git remote (Claude Code clones shallowly and rejects `file://` marketplace URLs).
- [ ] Behavior of the `adopt` scan on very large repositories and monorepos.
- [ ] Hosts without bash on Windows: today the audit tells people to install Git Bash/`jq`; consider whether a PowerShell path is worth it.
