# de-speckit-extension

<!-- TODO: one paragraph describing what this extension does and why. -->

A [Spec Kit](https://github.com/github/spec-kit) extension that hooks into
every core SDD lifecycle event (`before_*`/`after_*` for `constitution`,
`specify`, `clarify`, `plan`, `tasks`, `implement`, `checklist`, `analyze`,
`taskstoissues`). Every hook is **optional and individually configurable**,
following the same pattern as the bundled `git` extension.

## Commands

| Command | Description |
|---------|-------------|
| `speckit.de-speckit-extension.hook` | TODO: describe |

## Hooks

All lifecycle events currently point at the single `speckit.de-speckit-extension.hook`
command (see `extension.yml`), which branches on the event name it receives.
Split any event out into its own command + `provides.commands` entry if it
needs different logic.

## Configuration

Configuration lives in `.specify/extensions/de-speckit-extension/de-speckit-extension-config.yml`
after install (copied from `config-template.yml`):

```yaml
enabled: true

hooks:
  default: false
  after_specify:
    enabled: true
  # ... one entry per before_*/after_* event, see config-template.yml
```

## Installation

Internal extension — install directly from a release archive on our internal
Git host (no official Spec Kit catalog listing):

```bash
specify extension add de-speckit-extension \
  --from https://github.com/TODO/de-speckit-extension/archive/refs/tags/v0.1.0.zip
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

<!-- TODO -->

## Publishing a new version

1. Bump `version` in `extension.yml` (semver) and add a `CHANGELOG.md` entry.
2. Tag and push: `git tag vX.Y.Z && git push --tags`.
3. Create a release for that tag — `specify extension add ... --from <url>`
   points at the release archive's zip URL.
