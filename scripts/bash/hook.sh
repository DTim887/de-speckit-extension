#!/usr/bin/env bash
# Entry point for the de-speckit-extension hook command.
# Invoked as: hook.sh <event_name>
set -euo pipefail

EVENT_NAME="${1:-}"

if [[ -z "$EVENT_NAME" ]]; then
  echo "Usage: hook.sh <event_name>" >&2
  exit 1
fi

# TODO: implement the actual hook logic here.
# $EVENT_NAME will be one of: before_constitution, before_specify,
# before_clarify, before_plan, before_tasks, before_implement,
# before_checklist, before_analyze, before_taskstoissues,
# after_constitution, after_specify, after_clarify, after_plan,
# after_tasks, after_implement, after_checklist, after_analyze,
# after_taskstoissues.

echo "[de-speckit-extension] hook fired: $EVENT_NAME (not yet implemented)"
