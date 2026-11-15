# Task Guard - Slayer & Reaper

Task Guard is intended to help prevent unwanted Slayer cape choices and Reaper's Choice selections.

**Status: automatic, settings-driven mouse overlays; full protection is not verified.** The user confirmed that tested Helwyr clicks were intercepted without choosing the task and that the static grey appearance works. Other tasks, full hitbox coverage and alternative input routes still need client testing. This project is not represented as approved for distribution.

## Current features

- General, Reaper and Slayer settings tabs styled like Pre-flight Check, with two tasks per row, green enabled/red disabled backgrounds and checkboxes. Both task tabs offer independent saved preferences and Enable all/Disable all buttons.
- Slayer settings use a bundled assignment catalogue from the RuneScape Wiki, with all tasks enabled by default. Client default currently uses the alphabetical catalogue order for Slayer. Both sets of preferences are saved locally through PersistentDB.
- The global Slayer catalogue covers all masters, cross-checked against the wiki's twelve master assignment tables as well as its overview. It includes Sanguine crawlers and Sanguine werewolves as separate tasks. Captured Laniakea names take precedence over wiki spelling; older saved spelling variants are migrated without losing disabled preferences. One Ravenous strigoi setting covers the known duplicate picker entries. The catalogue is bundled, not fetched over the network at runtime.
- Experimental Slayer mouse shields use interface 201 and the exact title `Select your Slayer task`, with the shared Spria/Laniakea list structure. Known 230 × 20 rows overlapping the viewport with matching companion labels and complete captured background artwork receive shields; native clipping is expected to constrain partially visible shields and needs client verification. Both Ravenous strigoi rows use the same preference; other duplicate names and unknown layouts are left untouched. Native disabled backgrounds receive transparent requirement targets with pre-attached hover tooltips and no additional dimming. Right-click Enable/Disable actions save the global preference while retaining the native default choice; game-blocked rows do not offer these actions. The native Slayer picker also applies General alphabetical and enabled-first sorting, moving complete rows and restoring original positions when sorting is off, the dialog closes or the plugin shuts down. Click interception, native action mapping after sorting, clipping/scroll offsets, hover delivery and other masters still need client testing.
- The plugin settings' General tab offers saved Client default/Alphabetical task ordering and an independent enabled-first toggle. The ribbon only shows Reaper and Slayer tabs, but uses the same ordering preferences. Both plugin task lists update immediately.
- Client default in the plugin lists matches the native November 2026 picker sequence, read left-to-right across rows. Newly discovered tasks append to the catalogue. Saved enabled/disabled preferences are unchanged when the catalogue order changes.
- Alphabetical ordering ignores a leading “The ” (e.g. The Ambassador sorts under A), while keeping the full displayed task names. This applies to settings, ribbon and native picker ordering.
- Native enabled-first sorting puts both plugin-disabled tasks and tasks with complete in-game disabled backgrounds at the bottom. Settings and ribbon sorting use plugin preferences only, since game availability is known only in the open native picker.
- Experimental native Reaper's Choice ordering uses those same preferences. Complete recognised rows (background sprites, named/empty labels and companion-list labels) move together without replacing task names or dispatching actions. Client default with enabled-first off restores original positions; shutdown and dialog closure attempt restoration too. Unknown or incomplete layouts are left untouched. Native action mapping, hover, scrolling and restoration still require in-client verification.
- Saved Reaper preferences (enabled means allowed; all tasks are allowed by default). Disabled tasks receive automatic overlays when uniquely resolved in the captured Reaper choice list.
- Ribbon task toggles using the same saved preferences, with responsive columns sized to fit the longest boss name and checkbox.
- Side-by-side Enable all and Disable all buttons in both task tabs in settings and ribbon menus. Each action changes only that tab's preferences; failed saves restore the previous state.
- Dynamic discovery of new, unique visible task labels in the validated Reaper choice list. Discovered tasks are saved locally, default to enabled, and appear in both menus automatically.
- Task names are used directly for display, persistence and native matching, without runtime aliases. Legacy Telos/Black Stone Dragon/Giant Mole settings are migrated once, preserving disabled preferences. A future game-side rename is treated as a new enabled task.
- Mouse shield over a disabled, native-styled decorative button, plus a hover popup explaining that it is blocked by plugin settings rather than game requirements. The decoration uses the standard button stylesheet; matching the contextual picker artwork needs in-client verification. Nine separate disabled-row sprites are omitted to avoid the confirmed all-disabled picker lag.
- Validation of the captured label's identity, visibility and bounds before creating the overlay.
- Existing overlays follow movement of the same task row without rebuilding. Changed identity, parent or dimensions, and choice-dialog closure, remove them; shutdown independently cleans up each overlay. Retained menu callbacks cannot recreate overlays after shutdown.
- PrettyUI hover tooltip; scoped enumeration of the captured choice list, without global scans, native enabled-state changes, automatic task actions or additional permissions.

See **[reapers-choice-findings.md](reapers-choice-findings.md)** for the captured interface structure, evidence, limitations and steps needed to support other Reaper choices. See [planning.md](planning.md) for the broader roadmap.

## Local development

Follow the [RuneScape API getting-started guide](https://developer.runescape.com/rs/getting-started.html). Keep this folder at `RuneScape-BETA/dev_plugins/task-guard/`. In the client console (**Alt + `**):

```text
prf
pon task-guard
```

After Lua changes, run `prl task-guard`; after manifest changes, run `prf` first. PrettyUI (dependency ID `6398181`) must be available.

The settings menu shows two Reaper tasks per row; the ribbon dynamically fits columns to the available width, boss names and checkboxes. Both views share saved preferences. Disable a task to overlay its label in Reaper's Choice; enable it to remove the overlay. Matching requires the captured interface 1761, the exact title `Pick A task`, and at least two distinct known boss labels. New unique task labels in that list are added automatically and default to enabled; ambiguous, restricted or unavailable labels are left untouched. Open and scroll through Reaper's Choice to discover visible new tasks. Discovery does not fetch updates from the wiki or inspect unopened choices. Open plugin menus rebuild when the catalogue grows. Matching is English-only and needs live-client validation after UI updates. Shields are reconciled each logic tick on settings changes, movement, replacement and closing/reopening.

**A failed block can select a task.** Only test a choice you are willing to receive. Edges, context menus, keyboard/controller routes and separate confirmation paths are not verified. Close/reopen the game dialog if cleanup fails. Confirm the approach is permitted with Jagex before distributing.

Run the mocked tests using Lua 5.4 from this directory:

```powershell
lua tests/lifecycle.lua
lua tests/reaper-overlay.lua
lua tests/settings.lua
lua tests/settings-view.lua
lua tests/reaper-guard.lua
lua tests/reaper-order.lua
lua tests/slayer-order.lua
lua tests/slayer-guard.lua
lua tests/slayer-catalogue.lua
```

Mocks do not verify native rendering or click interception.

Plugin shutdown destroys owned views and overlays and unsubscribes event handlers.
Closing the Reaper choice dialog clears its overlays on the next logic tick, while
leaving the watcher active for reopening. Hidden plugin menus skip refresh work;
failed/disposed views are cleaned up. Tooltip positions are refreshed only for
hovered rows, avoiding unnecessary positioning work when many tasks are disabled.
Tooltips are allocated only on a row's first hover, rather than for every disabled
task at picker-open. Owned overlay components are excluded from native discovery.
Task menus only relayout or rewrite card state when preferences or dimensions
change. Native ordering only sorts on ordering changes (or task toggles with
enabled-first enabled); idle ticks validate named task labels, with full row
validation retained before reordering. Shields follow moved rows in place,
avoiding repeated destruction, allocation and movement-removal logs.

### Native requirement detection

Task Guard preserves game-blocked row visuals when all nine native background
sprites `18504–18512` match the captured row geometry. This visual-state heuristic
was captured on The Magister and The Ghrazi Blood Knights; available Helwyr and
Nex used `18468–18476` normally and `18477–18485` on hover. It is not a direct
requirements API and needs in-client verification. Unknown, partial, restricted,
ambiguous or differently scaled backgrounds retain normal overlay behaviour.
These rows receive a transparent, input-enabled hover target with the popup
**Blocked by requirements**, even when allowed in Task Guard. No additional
dimming is applied. The target consumes clicks over the already game-blocked row
without dispatching a task action; click-through targets did not reliably deliver
hover events. Hover delivery still needs client verification. Saved preferences are unchanged:
normal protection resumes if the native block disappears.
Native sprites are captured during the existing choice-list traversal and reused
for all task checks, avoiding a separate native list scan per disabled task.
Run `lua tests/reaper-requirements.lua` for mocked detection coverage.

## Project layout

```text
main.lua                   Plugin lifecycle and event handlers
tasks/reaper/              Reaper catalogue and picker guard
tasks/slayer/              Slayer catalogue, picker guard and ordering adapter
constants.lua              Plugin identity and event prefix
tasks/                     Shared task settings, ordering, requirements and picker constants
ui/                        Settings view and owned mouse overlays
tests/                     Isolated mocked regression suites
scripts/test.ps1           Complete Lua 5.4 test runner
scripts/package.ps1        Runtime-only, versioned release ZIP builder
```

## Planned behaviour

Verify multi-task mouse overlays, Slayer picker compatibility across masters, full hitboxes and alternative input routes. Never automatically choose, accept, reroll or complete tasks. Leave unrelated interfaces and unknown choices unchanged. Do not modify the game's own block/prefer lists.

## Feedback and collaboration

Report bugs and suggestions to [vincent.rs.plugins@gmail.com](mailto:vincent.rs.plugins@gmail.com). Include reproduction steps and client version. Discuss substantial contributions before implementing them; avoid sharing personal information publicly.

## Permissions and data protection

This plugin requests no additional permissions. General ordering preferences, Reaper and Slayer toggles, and discovered Reaper names are saved locally through PersistentDB under `taskGuard.tasks.v1`. They are retained across reloads and client restarts; no character identity is read and the plugin does not implement character-specific storage. Enable all resets a tab's toggles but does not delete discovered names. There is currently no in-plugin delete-data control; clearing the plugin's PersistentDB data through supported client facilities resets stored data. Uninstall deletion behaviour must be verified in-client.

The plugin reads visible picker labels, component identity, restrictions, geometry and artwork to identify rows. It creates owned UI, moves validated native rows for sorting, and reports failures to the client console. It does not read chat or inventory, send data to the developer or external services, or dispatch native task actions. Data-protection case selection must be confirmed against the current Jagex requirements before submission.

## Release preparation

Run all mocked suites from the repository root with `powershell -File scripts/test.ps1` (Lua 5.4 required). Every suite runs in a separate process to isolate API mocks. Tests do not verify rendering, native action mapping, clipping, input interception or client persistence.

Create the runtime ZIP with `powershell -File scripts/package.ps1`. It includes `main.lua`, `plugin.json`, `constants.lua` and the Lua modules in `tasks/` and `ui/`, retaining relative paths. Tests, editor files and maintainer documentation are excluded. The output is `dist/task-guard-<manifest-version>.zip`; existing releases are not overwritten.

Follow [the submission checklist](../SUBMISSION.md) before publishing. Personally review every module and test in-client on the required platforms. Input/menu customisation is explicitly subject to Jagex review; this refactor is not a compliance certification. Confirm the monitored email, data-protection case and collaboration policy, prepare the listing image/screenshots, and copy the Email, Feedback and collaboration, Permissions, Data protection and EULA sections into the mod.io description. No approval or submission is claimed.

### Email

Contact: [vincent.rs.plugins@gmail.com](mailto:vincent.rs.plugins@gmail.com). Confirm this address is monitored before publishing.

## EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula (and all terms incorporated into it by reference). The development and any use of the Plugin is at all times subject to the Jagex EULA.
