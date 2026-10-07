# Bootstrap design

**Status:** design draft, nothing built yet. Decisions below were made on
2026-10-07.

## Goal
Let a user put this framework into a project in one step, whether the project
is brand new or already has code, a `CLAUDE.md`, `.claude/settings.json` and a
`.gitignore`. v1 targets Claude Code only; the structure must not block other
tools later.

## Decisions
| # | Decision | Why |
|---|---|---|
| 1 | **Hooks are vendored into each project** (copied into the committed `.claude/` folder). | Anyone who clones gets enforcement with no plugin install, and it works offline. Plugin-provided hooks would silently not run for teammates who skipped the install, and would fire in every project. |
| 2 | **v1 ships as a Claude Code plugin with `init` and `adopt` skills.** `update` and `audit` follow; `sandbox` after that. | Bootstrapping an existing project needs judgment (merging, drafting architecture), which a skill run by Claude does better than a script. |
| 3 | **A plain `install.sh` comes later**, wrapping the same payload. | Covers non-plugin users, CI and other tools. Not in v1. |
| 4 | **No git submodules for hooks.** | Settings paths would depend on submodule location, and a submodule update does not refresh copied files. May revisit for sharing `core/` with non-Claude adapters. |

The plugin is the installer and updater; **the project owns its copy** of
the framework files once installed.

## What gets installed in a project
| Source in this repo | Destination in the project |
|---|---|
| `adapters/claude-code/CLAUDE.md` | `CLAUDE.md` (merged if one exists) |
| `adapters/claude-code/.claude/` (settings + hooks) | `.claude/` (settings merged, hooks copied) |
| `adapters/claude-code/.gitignore` entries | appended to `.gitignore` |
| `templates/llm/*` | `llm/` (never overwrites an existing file) |
| `core/*.md` | `llm/framework/` |
| (new) | `llm/framework/VERSION`, recording the framework version installed |
| `sandbox/devcontainer.json` (optional) | `.devcontainer/devcontainer.json` |

## Plugin layout (proposed)
The repo root doubles as the plugin root, so the existing `adapters/`,
`templates/`, `core/` and `sandbox/` folders are the payload and need no
restructure:

```
.claude-plugin/plugin.json        name: llm-governance, version
.claude-plugin/marketplace.json   makes this repo installable as a marketplace
skills/
  init/SKILL.md                   new project
  adopt/SKILL.md                  existing project
  update/SKILL.md                 later
  audit/SKILL.md                  later
adapters/ core/ templates/ sandbox/   payload the skills copy from
```

Skills should be user-invoked only, since they write files. Each skill keeps
its deterministic logic in `skills/<name>/scripts/` (see prototype findings).

## Skills
### `init` (new or empty project)
1. Confirm the target is the project root; recommend a clean git tree.
2. Copy the payload per the table above.
3. Walk the user through the `CLAUDE.md` placeholders (overview, commands,
   scope and stack). Scope and stack stays human-owned: Claude may draft it
   in conversation, but nothing is final until the user approves it.
4. Run the startup-checklist verification (see `audit`).

### `adopt` (existing project)
1. **Preflight:** require a git repo with a clean tree for the files it will
   touch, so every change is a reviewable diff.
2. **Scan** the project (languages, package manifests, directory layout,
   test and CI config) read-only.
3. **Plan:** present a per-file plan: create, merge or skip. Ask before any
   write.
4. **Merge, never overwrite** (rules below).
5. **Draft** `llm/ARCHITECTURE.md` and a first `llm/PROJECT_STATE.md` from the
   scan. Every drafted section is marked `DRAFT: unconfirmed` until the user
   approves it. Scope and stack in `CLAUDE.md` is only proposed, never
   silently filled.
6. Run `audit`; summarize what changed and what still needs the user.

### Merge rules
| File | Rule |
|---|---|
| `CLAUDE.md` exists | Append the "Framework rules (imported)" and enforcement sections; leave the user's content untouched. |
| `.claude/settings.json` exists | JSON-merge the `hooks` entries by event; keep every existing hook and setting; never duplicate an entry on re-run. |
| `.gitignore` exists | Append only the missing lines. |
| `llm/<file>` exists | Skip it and report; never overwrite project records. |
| Hook scripts exist (name clash) | Show a diff and ask. |
| Everything | Idempotent: a second run produces no changes. |

### `update` (later)
Compare `llm/framework/VERSION` and the vendored hooks and core files against
the installed plugin version; show a diff; apply only on approval. Never
touches project records (`llm/*.md` other than `llm/framework/`).

### `audit` (later)
Automates `docs/STARTUP_CHECKLIST.md`: files present, imports resolve, hooks
executable, `jq` present, `.gitignore` entries, `settings.json` valid.

## Prototype findings (2026-10-07)
A minimal plugin (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
and a stub `skills/init/`) was built and run in the dev container with real
`claude -p` sessions. Answers to the original open questions:

| Question | Answer |
|---|---|
| Can the repo root be the plugin? | **Yes.** `claude plugin validate` passes, a marketplace entry with `"source": "./"` is accepted, and add + install + run works from a local-path marketplace. |
| How does a skill reference bundled files? | `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_SKILL_DIR}` are substituted in the skill text. Neither is set in the Bash environment, so scripts must be passed paths or derive their location from `$0`. |
| How to make a skill user-invoked only? | `disable-model-invocation: true`. The skill registers as `/llm-governance:init`. (That Claude will not auto-invoke it was not tested.) |
| Can skills read plugin files outside the project? | **Yes** with the Read tool (allowed with `allowed-tools: Read`). |
| Can skills use `!` shell injection on the plugin? | **No.** It is limited to the session's working directories, and a blocked injection aborts the whole skill. Do not use it. |

**Design consequence:** skills should be thin wrappers around bundled,
deterministic scripts (`skills/<name>/scripts/*.sh`), pre-approved with
`allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/<script> *)`, plus Claude's
judgment for the parts that need it (drafting `ARCHITECTURE.md`, resolving
merge conflicts with the user). The same scripts can later back a standalone
`install.sh` with no duplicated logic.

**Git-hosted install verified** (`claude plugin marketplace add
Rivenception/llm_governance_framework`, then install): the plugin cache copy
contains only tracked files (no `.git`, no untracked folders such as
`.devcontainer/`), keeps the executable bit on scripts (needs `100755` in
git; Windows checkouts record `100644`, so run
`git update-index --chmod=+x` on new scripts), and the skill runs from the
cache path with its script and `Read` access working.

**`allowed-tools` lasts only for the skill's own turn.** A skill that pauses
for the user's confirmation and then writes in a later turn gets no
pre-approval for the write. We use this deliberately: `init` pre-approves only
`install.sh --dry-run *`, so the real install always triggers Claude Code's own
permission prompt. That prompt is the approval gate for writing files,
enforced by the tool rather than by the model's judgment.

Not yet verified: `update` flows; Windows hosts without bash.

## Open questions
1. Should `init` and `adopt` be one skill that detects the situation?
2. Sandbox: an `--sandbox` option on `init`/`adopt`, or a separate skill?
3. Windows: hooks need bash and `jq`; should `audit` check for them and
   explain the fix?
4. Dogfooding: this repo should adopt its own framework (it has no `llm/`
   folder yet).
5. License: none chosen yet; needed before publishing the marketplace.

## Test plan
Run in the dev container against scratch projects, using real Claude Code
sessions as in the hook test:
- empty directory (`init`)
- existing Node project with its own `CLAUDE.md`, `.claude/settings.json` and
  `.gitignore` (`adopt`)
- running either skill twice (idempotence: no diff the second time)
- a project with a name clash on a hook script
- after install, the hook behaviors still pass (Q&A turn, edit turn, block,
  retry)

## Next steps
1. ~~Minimal plugin to settle the layout questions~~ (done, see findings).
2. ~~Build the `init` script and skill~~ (built: `skills/init/scripts/install.sh`,
   `skills/init/SKILL.md`, tests in `tests/test_install.sh`; verified live on an
   empty directory in the dev container).
3. ~~Build `adopt`~~ (built: `skills/adopt/SKILL.md`, read-only
   `skills/adopt/scripts/scan.sh`, a wrapper that reuses `init`'s installer;
   tests in `tests/test_scan.sh`; verified live on an existing Node project in
   the dev container: no secrets written, user content preserved, drafts
   hedged and marked unconfirmed, scope/stack proposed but not written).
4. Then `update`, `audit`, and the sandbox option.
