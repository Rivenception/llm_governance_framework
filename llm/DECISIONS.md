# Decisions
Architecture Decision Records. Add-only, newest at top. Log real forks in
the road — not every small choice.

## [2026-10-07] Track the root .devcontainer as this repo's dev environment
Context: The suites take minutes on Windows and seconds on Linux, and a working dev container (Claude Code, node, jq, git, a volume for the login) already existed untracked at the repo root. It had been left undecided since the adoption.
Chose: Track `.devcontainer/` (devcontainer.json and VS Code's devcontainer-lock.json) as the repo's own development environment, named "LLM Governance Framework (dev)", and point CLAUDE.md and the README's Contributing section at it. It stays separate from `plugin/sandbox/devcontainer.json`, the copy shipped to users.
Rejected:
- Removing it: contributors (and Claude sessions) would lose the only fast, Linux-faithful way to run the suites and try the skills.
- Making the shipped sandbox the repo's dev container: the two have different goals (the shipped one will be locked down with an egress firewall; the dev one needs tools and network).
Session: 115017e7-19b7-45eb-8573-d45f62282310

## [2026-10-07] Use UTC for llm/ record timestamps in this repo (interim)
Context: A host session (local time, UTC-4) and a container session (UTC) stamped entries hours apart, so CHANGELOG entries sorted out of order and the audit's newest-first check could trip. The framework default is the machine-local date.
Chose: In this repo, record timestamps with `date -u`; stated in the "Working in this repo" section of CLAUDE.md, which overrides the framework block's local `date` until the framework-wide convention is decided (still in TODO). The Stop hook's own PROJECT_STATE stamp remains machine-local.
Rejected: Leaving it unspecified (keeps producing out-of-order entries); changing the framework block now (it is managed text shared by every project and the decision should be made once, with the rules, skills, stamp hook and audit together).
Session: 115017e7-19b7-45eb-8573-d45f62282310

## [2026-10-07] Pin framework files to LF through the project's .gitattributes
Context: On Windows with core.autocrlf=true, a clone turned all six hook scripts and the llm/framework files into CRLF (demonstrated: 42 CRs in lib.sh). Bash then fails under Linux, WSL and dev containers, and the audit could only report a generic syntax error. Only this repo was protected, by its own .gitattributes.
Chose: init, adopt and update add LF rules (`.claude/hooks/*.sh`, `llm/framework/**`) to the project's .gitattributes, created or appended and never overwritten, like .gitignore. The audit now names CRLF as the cause with the exact fix and checks the rules are in effect. CLAUDE.md, which the user owns, is not pinned; instead the block comparison and the audit's import check tolerate CRs.
Rejected:
- Documentation only: the failure is silent until a Linux or container run, and people do not read setup notes at that moment.
- Forcing eol=lf on the user's CLAUDE.md: it is the user's file, and tolerating CRs costs less than imposing a rule on it.
- Converting the hooks at runtime: bash executes them directly, so there is no hook point before they fail.
Session: unknown (the framework's hooks were not active in this session)
