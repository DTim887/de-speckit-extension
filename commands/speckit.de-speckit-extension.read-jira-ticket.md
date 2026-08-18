---
description: "Fetch a JIRA ticket's description and use it as context for /speckit.specify; also wired as a mandatory before_specify gate"
scripts:
  sh: ../../scripts/bash/read-jira-ticket.sh
---

# Read JIRA Ticket

Fetches the `description` field of a JIRA ticket from
`https://disneyexperiences.atlassian.net` and renders it as plain text
(paragraph breaks preserved; no Markdown formatting; tables/lists are not
specially rendered).

## User Input

$ARGUMENTS

## Manual Usage

Run directly with a ticket key:

```text
/speckit.de-speckit-extension.read-jira-ticket SHDRP-437322
```

- `$ARGUMENTS` must be a single ticket key matching `^SHDRP-[0-9]+$`
  (e.g. `SHDRP-437322`). Anything else is a validation error — stop and
  report it, do not call the script.

## Hook Usage (mandatory `before_specify` gate)

This command is also registered on the `before_specify` hook with
`optional: false` (see `extension.yml`), so it runs automatically and
unconditionally every time `/speckit.specify` is invoked — every spec must
be grounded in a real JIRA ticket.

When triggered as a hook (not invoked directly by the user), there are no
hook-passed arguments, so:

1. Look at the user's most recent `__SPECKIT_COMMAND_SPECIFY__` invocation
   and take the **first whitespace-separated token** of its arguments as
   the candidate ticket key.
2. Validate it against `^SHDRP-[0-9]+$`.
   - If missing or malformed: **stop**. Do not run `__SPECKIT_COMMAND_SPECIFY__`.
     Tell the user `/speckit.specify` requires a leading JIRA ticket key in
     the form `SHDRP-<digits>` (e.g. `SHDRP-437322`).
3. Run the script with the validated ticket key (see Execution below).
4. If the script exits non-zero for **any** reason (bad credentials,
   network error, ticket not found, empty description, etc.): **stop**. Do
   not run `__SPECKIT_COMMAND_SPECIFY__`. Surface the script's stderr
   message to the user verbatim.
5. If the script succeeds, take its stdout (the ticket description as
   plain text) and use it as additional context when running
   `__SPECKIT_COMMAND_SPECIFY__` — prepend it ahead of the user's original
   arguments so the spec is generated with the real ticket content in
   view.

## Execution

- **Bash**: `.specify/extensions/de-speckit-extension/scripts/bash/read-jira-ticket.sh <TICKET-KEY>`

Requires `ATLASSIAN_EMAIL` and `ATLASSIAN_API_TOKEN` in the environment
(already provisioned for this org). `ATLASSIAN_BASE_URL` may override the
default `https://disneyexperiences.atlassian.net` if ever needed.

## Graceful Degradation

None — intentionally. This command backs a mandatory policy: no JIRA
ticket, no spec. Any failure — bad ticket key format, missing credentials,
network/auth error, ticket not found, or an empty description — must stop
`/speckit.specify` from proceeding, with
a clear error shown to the user.
