# Decisions
Architecture Decision Records. Add-only, newest at top. Log real forks in
the road — not every small choice.

## [2026-10-07] Pin framework files to LF through the project's .gitattributes
Context: On Windows with core.autocrlf=true, a clone turned all six hook scripts and the llm/framework files into CRLF (demonstrated: 42 CRs in lib.sh). Bash then fails under Linux, WSL and dev containers, and the audit could only report a generic syntax error. Only this repo was protected, by its own .gitattributes.
Chose: init, adopt and update add LF rules (`.claude/hooks/*.sh`, `llm/framework/**`) to the project's .gitattributes, created or appended and never overwritten, like .gitignore. The audit now names CRLF as the cause with the exact fix and checks the rules are in effect. CLAUDE.md, which the user owns, is not pinned; instead the block comparison and the audit's import check tolerate CRs.
Rejected:
- Documentation only: the failure is silent until a Linux or container run, and people do not read setup notes at that moment.
- Forcing eol=lf on the user's CLAUDE.md: it is the user's file, and tolerating CRs costs less than imposing a rule on it.
- Converting the hooks at runtime: bash executes them directly, so there is no hook point before they fail.
Session: unknown (the framework's hooks were not active in this session)
