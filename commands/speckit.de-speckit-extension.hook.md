---
description: "TODO: one-line description of what this command does"
---

# de-speckit-extension Hook

This command is invoked as a hook before/after core Spec Kit commands (see
`hooks:` in `extension.yml`). It is shared across every lifecycle event —
the event name tells you which phase triggered it.

## Behavior

1. Determine the event name from the hook context (e.g. `before_plan`,
   `after_implement`).
2. Read `.specify/extensions/de-speckit-extension/de-speckit-extension-config.yml`:
   - Check `enabled` (global toggle) — if false, skip entirely.
   - Look up `hooks.<event_name>.enabled`; fall back to `hooks.default` if the
     event has no specific entry.
3. If disabled, skip with a short message. If enabled, run the logic below.

<!-- TODO: describe the actual behavior this hook should perform. -->

## Execution

- **Bash**: `.specify/extensions/de-speckit-extension/scripts/bash/hook.sh <event_name>`
- **PowerShell**: `.specify/extensions/de-speckit-extension/scripts/powershell/hook.ps1 <event_name>`

Replace `<event_name>` with the actual hook event that triggered this command.

## Graceful Degradation

<!-- TODO: what should happen if a dependency this hook needs is missing? -->
- If disabled via config: skip silently (no error).
