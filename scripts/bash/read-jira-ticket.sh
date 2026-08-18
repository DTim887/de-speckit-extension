#!/usr/bin/env bash
# Fetches a Jira issue's `description` field and prints it as plain text
# (paragraph breaks preserved, no Markdown formatting, tables/lists not
# specially rendered — just flattened block by block).
# Invoked as: read-jira-ticket.sh <TICKET-KEY>
#
# Requires ATLASSIAN_EMAIL and ATLASSIAN_API_TOKEN in the environment.
# ATLASSIAN_BASE_URL may override the default DE Jira Cloud instance.
#
# Exits non-zero (with a message on stderr) on any failure: bad ticket key
# format, missing credentials, missing tools, network/auth/HTTP errors, or a
# ticket with no description. There is no "degrade gracefully" path here —
# this script backs a mandatory before_specify gate, so any failure must be
# visible and must stop the caller from proceeding.
set -euo pipefail

TICKET_KEY="${1:-}"
BASE_URL="${ATLASSIAN_BASE_URL:-https://disneyexperiences.atlassian.net}"
TICKET_PATTERN='^SHDRP-[0-9]+$'

err() {
  echo "[read-jira-ticket] $1" >&2
}

if [[ -z "$TICKET_KEY" ]]; then
  err "Missing required argument: a JIRA ticket key (e.g. SHDRP-437322)."
  err "Usage: read-jira-ticket.sh <TICKET-KEY>"
  exit 1
fi

if [[ ! "$TICKET_KEY" =~ $TICKET_PATTERN ]]; then
  err "Invalid ticket key '$TICKET_KEY' — expected format SHDRP-<digits> (e.g. SHDRP-437322)."
  exit 1
fi

if [[ -z "${ATLASSIAN_EMAIL:-}" || -z "${ATLASSIAN_API_TOKEN:-}" ]]; then
  err "Missing ATLASSIAN_EMAIL and/or ATLASSIAN_API_TOKEN environment variables."
  exit 1
fi

for tool in curl jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    err "Required tool '$tool' is not installed."
    exit 1
  fi
done

API_URL="${BASE_URL%/}/rest/api/3/issue/${TICKET_KEY}?fields=description"

http_response="$(curl -sS -w '\n%{http_code}' \
  -u "${ATLASSIAN_EMAIL}:${ATLASSIAN_API_TOKEN}" \
  -H "Accept: application/json" \
  "$API_URL")" || {
  err "Network error while contacting Jira at $BASE_URL."
  exit 1
}

http_status="${http_response##*$'\n'}"
http_body="${http_response%$'\n'*}"

case "$http_status" in
  200) ;;
  401 | 403)
    err "Authentication failed (HTTP $http_status). Check ATLASSIAN_EMAIL / ATLASSIAN_API_TOKEN."
    exit 1
    ;;
  404)
    err "Ticket '$TICKET_KEY' was not found in $BASE_URL."
    exit 1
    ;;
  *)
    err "Jira API returned HTTP $http_status for '$TICKET_KEY'."
    exit 1
    ;;
esac

# Atlassian Document Format (ADF) -> plain text. Preserves paragraph/block
# breaks (blank line between blocks); does not render Markdown syntax and
# does not special-case tables/lists (their cells/items are just flattened
# into the block stream, one per line).
read -r -d '' ADF_TO_TEXT_FILTER <<'JQ_EOF' || true
def render_inline(node):
  if node.type == "text" then (node.text // "")
  elif node.type == "hardBreak" then "\n"
  elif node.type == "mention" then (node.attrs.text // node.attrs.id // "")
  elif node.type == "emoji" then (node.attrs.shortName // node.attrs.text // "")
  elif node.type == "status" then (node.attrs.text // "")
  elif node.type == "date" then (node.attrs.timestamp // "")
  elif node.type == "inlineCard" then (node.attrs.url // "")
  else "" end;

def render_inline_list(content):
  [ (content // [])[] | render_inline(.) ] | join("");

def render_block(node):
  if node.type == "paragraph" or node.type == "heading" or node.type == "codeBlock"
     or node.type == "tableCell" or node.type == "tableHeader" or node.type == "taskItem" then
    render_inline_list(node.content)
  else
    # Containers (doc, bulletList/orderedList/listItem, blockquote, table,
    # tableRow, taskList, panel, expand, mediaSingle, ...): flatten children,
    # one block per line, blank line between them.
    [ (node.content // [])[] | render_block(.) ] | map(select(length > 0)) | join("\n\n")
  end;

render_block(.)
JQ_EOF

description_json="$(printf '%s' "$http_body" | jq -c '.fields.description' 2>/dev/null)" || {
  err "Failed to parse Jira API response as JSON."
  exit 1
}

if [[ -z "$description_json" || "$description_json" == "null" ]]; then
  err "Ticket '$TICKET_KEY' has no description content."
  exit 1
fi

plain_text="$(printf '%s' "$description_json" | jq -r "$ADF_TO_TEXT_FILTER")"

if [[ -z "${plain_text// /}" ]]; then
  err "Ticket '$TICKET_KEY' has an empty description."
  exit 1
fi

printf '%s\n' "$plain_text"
