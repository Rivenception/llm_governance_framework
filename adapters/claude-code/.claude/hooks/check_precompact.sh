#!/bin/bash
# PreCompact hook: fires right before context compaction, when reasoning is
# most likely to get silently lost. Prints a reminder to stderr; PreCompact
# can't block compaction, so this is advisory rather than enforced.

echo "Reminder: context is about to compact. Before continuing, make sure llm/PROJECT_STATE.md reflects the current state and llm/DECISIONS.md captures any decisions made so far this session." >&2

exit 0
