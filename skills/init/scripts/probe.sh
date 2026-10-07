#!/bin/bash
# Prototype probe: shows that a skill-bundled script can see the plugin payload.
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
echo "script-resolved plugin root: $ROOT"
echo "CLAUDE_PLUGIN_ROOT env: ${CLAUDE_PLUGIN_ROOT:-<unset>}"
echo "CLAUDE_PROJECT_DIR env: ${CLAUDE_PROJECT_DIR:-<unset>}"
echo "cwd: $(pwd)"
for d in adapters/claude-code templates/llm core; do
  echo "--- $d"; ls "$ROOT/$d"
done
