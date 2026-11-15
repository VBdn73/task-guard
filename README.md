# Task Guard - Slayer & Reaper

Task Guard is intended to help prevent unwanted Slayer cape choices and Reaper's Choice selections.

**Status: automatic, settings-driven mouse overlays; full protection is not verified.** The user confirmed that tested Helwyr clicks were intercepted without choosing the task and that the static grey appearance works. Other tasks, full hitbox coverage and alternative input routes still need client testing. This project is not represented as approved for distribution.

## Current features

- Reaper and Slayer settings tabs styled like Pre-flight Check, with two Reaper tasks per row, green enabled/red disabled backgrounds and checkboxes. Slayer is empty for now.
- Saved Reaper preferences (enabled means allowed; all tasks are allowed by default). Disabled tasks receive automatic overlays when uniquely resolved in the captured Reaper choice list.
- Ribbon task toggles using the same saved preferences, with one task per row.
- Dynamic discovery of new, unique visible task labels in the validated Reaper choice list. Discovered tasks are saved locally, default to enabled, and appear in both menus automatically.
- Task names are used directly for display, persistence and native matching, without runtime aliases. Legacy Telos/Black Stone Dragon/Giant Mole settings are migrated once, preserving disabled preferences. A future game-side rename is treated as a new enabled task.
- Mouse shield with a translucent dark overlay to give Helwyr a disabled appearance while retaining the native entry and border, without button hover/press animation, plus a hover popup explaining that it is blocked by plugin settings rather than game requirements.
- Validation of the captured label's identity, visibility and bounds before creating the overlay.
- Removal on detected target movement/replacement, with shutdown cleanup attempts.
- PrettyUI hover tooltip; scoped enumeration of the captured choice list, without global scans, native enabled-state changes, automatic task actions or additional permissions.

See **[reapers-choice-findings.md](reapers-choice-findings.md)** for the captured interface structure, evidence, limitations and steps needed to support other Reaper choices. See [planning.md](planning.md) for the broader roadmap.

## Local development

Follow the [RuneScape API getting-started guide](https://developer.runescape.com/rs/getting-started.html). Keep this folder at `RuneScape-BETA/dev_plugins/task-guard/`. In the client console (**Alt + `**):

```text
prf
pon task-guard
```

After Lua changes, run `prl task-guard`; after manifest changes, run `prf` first. PrettyUI (dependency ID `6398181`) must be available.

The settings menu shows two Reaper tasks per row; the ribbon shows one per row. Both views share saved preferences. Disable a task to overlay its label in Reaper's Choice; enable it to remove the overlay. Matching requires the captured interface 1761, the exact title `Pick A task`, and at least two distinct known boss labels. New unique task labels in that list are added automatically and default to enabled; ambiguous, restricted or unavailable labels are left untouched. Open and scroll through Reaper's Choice to discover visible new tasks. Discovery does not fetch updates from the wiki or inspect unopened choices. Open plugin menus rebuild when the catalogue grows. Matching is English-only and needs live-client validation after UI updates. Shields are reconciled each logic tick on settings changes, movement, replacement and closing/reopening.

**A failed block can select a task.** Only test a choice you are willing to receive. Edges, context menus, keyboard/controller routes and separate confirmation paths are not verified. Close/reopen the game dialog if cleanup fails. Confirm the approach is permitted with Jagex before distributing.

Run the mocked tests using Lua 5.4 from this directory:

```powershell
lua tests/lifecycle.lua
lua tests/reaper-overlay.lua
lua tests/settings.lua
lua tests/reaper-guard.lua
```

Mocks do not verify native rendering or click interception.

### Native requirement detection

Task Guard preserves game-blocked row visuals when all nine native background
sprites `18504–18512` match the captured row geometry. This visual-state heuristic
was captured on The Magister and The Ghrazi Blood Knights; available Helwyr and
Nex used `18468–18476` normally and `18477–18485` on hover. It is not a direct
requirements API and needs in-client verification. Unknown, partial, restricted,
ambiguous or differently scaled backgrounds retain normal overlay behaviour.
These rows receive a transparent, click-through hover target with the popup
**Blocked by requirements**, even when allowed in Task Guard. No additional
dimming or plugin click interception is applied. Native click-through hover
delivery still needs client verification. Saved preferences are unchanged:
normal protection resumes if the native block disappears.
Native sprites are captured during the existing choice-list traversal and reused
for all task checks, avoiding a separate native list scan per disabled task.
Run `lua tests/reaper-requirements.lua` for mocked detection coverage.

## Project layout

```text
main.lua                    Plugin lifecycle and view event handlers
status-view.lua             Manual overlay controls and status
reaper-config.lua           Captured Helwyr label address
reaper-overlay.lua          Owned overlay creation, validation and cleanup
tests/lifecycle.lua         Mocked lifecycle coverage
tests/reaper-overlay.lua    Mocked overlay coverage
reapers-choice-findings.md  Findings, limitations and extension plan
planning.md                 Broader implementation roadmap
changelog.md                Version history
```

## Planned behaviour

Verify multi-task mouse overlays, full hitboxes and alternative input routes, and add a user-managed Slayer guard list. Never automatically choose, accept, reroll or complete tasks. Leave unrelated interfaces and unknown choices unchanged. Do not modify the game's own block/prefer lists.

## Feedback and collaboration

Report bugs and suggestions to [vincent.rs.plugins@gmail.com](mailto:vincent.rs.plugins@gmail.com). Include reproduction steps and client version. Discuss substantial contributions before implementing them; avoid sharing personal information publicly.

## Permissions and data protection

No additional permissions are requested. Reaper preferences are saved locally through PersistentDB. The overlay reads the configured component's type, restriction, visibility, exact text, parent and geometry. It creates plugin-owned UI and logs overlay actions/errors to the client console. It does not read chat, inventory or character identity, transmit data externally or change native task actions. The captured label address is stored in `reaper-config.lua`; dynamic IDs are not assumed to be stable.

## EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula (and all terms incorporated into it by reference). The development and any use of the Plugin is at all times subject to the Jagex EULA.
