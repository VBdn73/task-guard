# Changelog

## Unreleased

- Require Slayer toggles to have been presented by MiniMenuOpened before permitting a preference change. Hover/default-left-click menu builds stay inert. Add a regression for the reported Ascension members disable followed by an unintended Camel warriors enable.
- Keep Slayer Enable/Disable menu entries below Cancel in priority, using Add's documented append index even with stale entry snapshots. A Cancel-only shielded row must never make Enable task its default left-click action. Add regression coverage for both live and snapshot entry lists.
- Defer Slayer shield reconciliation until the normal logic tick after a picker-menu setting change. Menu callbacks now validate a read-only snapshot without creating/removing controls during click dispatch, addressing the captured Ascension members/Camel warriors double callback.
- Make Slayer menu callbacks one-shot and invalidate actions retained from earlier menu builds, with two-task dispatch regression coverage. Add requirement mouse-repeat/native-hover detection while keeping tooltip allocation lazy.
- Key Slayer rows by component address rather than raw Lua wrapper identity, while rechecking native identity and task name. Add fresh-wrapper regression coverage for retained shields and right-click callbacks. Move overlay text to disabled decoration so the enabled input catcher has no label to brighten on click.
- Restore lazy requirement tooltips after reported lag: attach only the hovered row on a logic tick, not all rows at picker open. Bucket Slayer background snapshots by row to avoid full sprite scans for each task.
- Retain Slayer shields on partially visible rows using native viewport clipping, pre-attach requirement tooltip hover hooks, and add right-click Enable/Disable task actions without replacing native default choices. Live clipping and hover delivery need retesting.
- Add an experimental Slayer mouse guard for the captured shared Spria/Laniakea interface 201, using global settings, validated artwork/rows, conservative viewport clipping, duplicate Strigoi handling and independent lifecycle cleanup. Live click interception remains unverified.
- Cross-check the global Slayer catalogue against all twelve wiki master tables, add missing tasks and migrate spelling variants while preserving disabled preferences. Record Laniakea's interface 201 capture and the known duplicate Strigoi bug.
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
