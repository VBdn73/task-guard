# Changelog

## Unreleased

- Populate Slayer settings and ribbon tabs with the shared task-card menu, independent saved preferences, bulk toggles and general sorting. Existing Reaper preferences are preserved. Slayer native blocking is not implemented.
- Retain manual Helwyr overlay controls with static visuals and input interception.
- Remove interface discovery, parent dumps, native enabled-state probes and their configuration/tests from Task Guard.
- Add `reapers-choice-findings.md` documenting captured IDs, user-reported results, limitations and the extension plan.
- Keep mocked lifecycle/overlay regression tests. No automatic or complete task protection is claimed.

## 0.0.1 - 2026-11-13

### Added

- Initial Task Guard project scaffold and plugin manifest.
- Read-only settings and ribbon status panels, with shutdown cleanup.
- README, implementation roadmap, editor/package ignore rules and mocked lifecycle test.

### Limitations

- Task detection, guard settings, persistence and click blocking are not implemented.
- No claims of client API feasibility or Jagex approval are made.
