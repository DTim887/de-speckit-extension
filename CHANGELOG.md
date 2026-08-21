# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2026-08-21

### Added

- Added `speckit.de-speckit-extension.figma-implement-design`: translates a
  Figma design into production-ready code with 1:1 visual fidelity via the
  Figma MCP server.

## [0.2.0] - 2026-08-19

### Changed

- Removed the generic `speckit.de-speckit-extension.hook` scaffold command
  (and its bash/PowerShell scripts), which was wired into every
  `before_*`/`after_*` lifecycle event.
- Added `speckit.de-speckit-extension.read-jira-ticket`: fetches a JIRA
  ticket's description (`SHDRP-<number>`, from the org's Jira Cloud
  instance) and gates `/speckit.specify` on a valid ticket reference —
  mandatory (`optional: false`), with no graceful degradation on failure.
- Simplified `config-template.yml` to a stub; there are no configurable
  options now that the per-event enable/disable scaffold is gone.

## [0.1.0] - 2026-08-16

### Added

- Initial extension scaffold: `extension.yml`, config template, and a shared
  hook command wired into every `before_*`/`after_*` lifecycle event.
