# de-speckit-extension

DE's organization-wide Spec Kit extension. It exists so DE-specific
conventions and governance checks can run automatically alongside the
standard spec-kit workflow, without every team having to redefine them
per project.

A [Spec Kit](https://github.com/github/spec-kit) extension.

## Commands

| Command | Description |
|---------|-------------|
| `speckit.de-speckit-extension.read-jira-ticket` | Fetch a JIRA ticket's description (`SHDRP-<number>`) as plain text; also gates `/speckit.specify` on a valid ticket reference |
| `speckit.de-speckit-extension.figma-implement-design` | Translate a Figma design into production-ready code with 1:1 visual fidelity, via the Figma MCP server |

## Hooks

`before_specify` is wired to `speckit.de-speckit-extension.read-jira-ticket`
with `optional: false` (see `extension.yml`) — every `/speckit.specify` run
must carry a leading `SHDRP-<number>` ticket key, or it's blocked. See the
command file for the full behavior.

## Configuration

No configurable options yet. `config-template.yml` is a stub reserved for
future commands added to this extension; nothing currently reads it.

## Installation

Internal extension — install directly from a release archive on our internal
Git host (no official Spec Kit catalog listing):

```bash
specify extension add de-speckit-extension \
  --from https://github.com/DTim887/de-speckit-extension/archive/refs/tags/v0.2.0.zip
```

For local development against a checkout of this repo:

```bash
specify extension add de-speckit-extension --dev /path/to/de-speckit-extension
```

## Disabling

```bash
specify extension disable de-speckit-extension
specify extension enable de-speckit-extension
```

## Graceful Degradation

None — intentionally. `speckit.de-speckit-extension.read-jira-ticket` is a
mandatory gate: a missing/malformed ticket key, missing credentials, or any
Jira API failure blocks `/speckit.specify` with a clear error rather than
skipping silently. See the command file's Graceful Degradation section for
details.

## Publishing a new version

1. Bump `version` in `extension.yml` (semver) and add a `CHANGELOG.md` entry.
2. Tag and push: `git tag vX.Y.Z && git push --tags`.
3. Create a release for that tag — `specify extension add ... --from <url>`
   points at the release archive's zip URL.
