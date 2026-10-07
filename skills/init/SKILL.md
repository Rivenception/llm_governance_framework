---
name: init
description: Install the LLM governance framework into a new project (prototype stub).
disable-model-invocation: true
allowed-tools: Read Bash(${CLAUDE_SKILL_DIR}/scripts/probe.sh *)
---

# init (prototype stub)

This skill does not install anything yet. It only proves that the plugin
loads and that a skill can reach the framework files bundled with the plugin.

Plugin root: `${CLAUDE_PLUGIN_ROOT}`
Skill dir: `${CLAUDE_SKILL_DIR}`
Project dir: `${CLAUDE_PROJECT_DIR}`

Do these two checks, then report the results. Do not create, modify or
delete any files.

1. Run `${CLAUDE_SKILL_DIR}/scripts/probe.sh probe` and show its output.
2. Use the Read tool on `${CLAUDE_PLUGIN_ROOT}/core/RULES.md` (first 5 lines
   only) and say whether the Read succeeded or was denied.

End with one line per check: PASS or FAIL, and why.
