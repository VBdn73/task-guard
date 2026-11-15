# Changelog

## 0.0.2 - 2026-11-15

### Added

- Settings-driven mouse guards for recognised Reaper's Choice and Slayer task rows, with static grey artwork and hover explanations for plugin-disabled and game-blocked tasks.
- Independent Reaper and Slayer preferences in settings and ribbon menus. All tasks are allowed by default; supported picker rows offer right-click **Enable task / Disable task** actions.
- Search and **Enable all / Disable all** controls that affect only the currently displayed tasks.
- General settings for client-default, alphabetical ascending/descending and enabled-first ordering, applied to plugin menus and recognised native pickers. Alphabetical ordering ignores a leading “The”.
- Per-character persistence for task preferences, ordering and discovered Reaper names, with automatic profile switching and saving only when character identity is available.
- A bundled Slayer catalogue covering all masters, including missing assignments and separate Sanguine crawler/werewolf entries. Known duplicate Ravenous Strigoi rows share one preference.
- Automatic local discovery of new, unique visible Reaper tasks, defaulting to allowed. Legacy task-name spelling migrations preserve disabled preferences.

### Changed

- Replaced the initial read-only panels and manual overlay experiments with shared General, Reaper and Slayer controls in both settings and ribbon menus.
- Matched Reaper client-default ordering to the native picker; validated native rows move together for sorting and return to their original positions when sorting is disabled or the picker closes.
- Improved responsive task columns, bulk-button sizing and narrow-window tabs. Resizing preserves the selected tab.
- Reduced overlay lag and frame drops through static canvas rendering, lazy tooltips, cached row checks and fewer idle layout, sorting and UI updates.
- Improved overlay tracking across scrolling and changing component wrappers, with conservative handling of unknown or incomplete layouts.
- Refactored shared settings, ordering, requirement detection and picker logic into task and UI modules; expanded mocked regression coverage.
- Simplified the README with current usage, limitations, contact details, permissions, local data handling and submission guidance.

### Fixed

- Unintended Slayer preference changes from stale or repeated menu callbacks; hover and default-left-click menu builds no longer toggle preferences.
- Enable/Disable menu priority and reconciliation during click dispatch, preserving native default choices and keeping Cancel as the default on shielded rows.
- Enabled tasks becoming unclickable, requirement-tooltip hover handling and Slayer picker ordering not following General settings.
- Excessive overlay allocation and repeated rendering/position updates when many tasks are disabled.
- Cleanup of owned views, overlays and event handlers on dialog closure, reload and shutdown, with stale-handle checks and independent cleanup attempts.

### Removed

- Interface discovery tools, parent dumps and native enabled-state probes from the plugin.

### Limitations

- Guards depend on recognised English picker layouts and mouse overlays; complete protection across all input routes is not guaranteed.
- No automatic task actions or changes to the game's block/prefer lists. Jagex moderation approval is not implied.

## 0.0.1 - 2026-11-13

### Added

- Initial Task Guard project scaffold and plugin manifest.
- Read-only settings and ribbon status panels, with shutdown cleanup.
- README, implementation roadmap, editor/package ignore rules and mocked lifecycle test.

### Limitations

- Task detection, guard settings, persistence and click blocking are not implemented.
- No claims of client API feasibility or Jagex approval are made.
