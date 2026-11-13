# Task Guard - Slayer & Reaper

Task Guard is intended to help prevent unwanted Slayer cape choices and Reaper's Choice selections.

**Status: manual Helwyr overlay proof of concept only. No automatic task protection.** The user confirmed that tested clicks were intercepted without choosing Helwyr and that the static grey appearance works. Full hitbox coverage and alternative input routes remain unverified. This project is not represented as approved for distribution.

## Current features

- Plugin settings and ribbon controls to show/remove a Helwyr overlay.
- Static dark background and grey text, without the standard button hover/press style.
- Validation of the captured label's identity, visibility and bounds before creating the overlay.
- Removal on detected target movement/replacement, with shutdown cleanup attempts.
- No discovery scans, native enabled-state probes, automatic task actions, external dependencies or additional permissions.

See **[reapers-choice-findings.md](reapers-choice-findings.md)** for the captured interface structure, evidence, limitations and steps needed to support other Reaper choices. See [planning.md](planning.md) for the broader roadmap.

## Local development

Follow the [RuneScape API getting-started guide](https://developer.runescape.com/rs/getting-started.html). Keep this folder at `RuneScape-BETA/dev_plugins/task-guard/`. In the client console (**Alt + `**):

```text
prf
pon task-guard
```

After Lua changes, run `prl task-guard`; after manifest changes, run `prf` first.

With Reaper's Choice open and Helwyr visible, open Task Guard settings and press **Overlay Helwyr**. Use **Remove overlay** when finished. The overlay covers the known text bounds only and is removed rather than reapplied when movement is detected.

**A failed block can select a task.** Only test a choice you are willing to receive. Edges, context menus, keyboard/controller routes and separate confirmation paths are not verified. Close/reopen the game dialog if cleanup fails. Confirm the approach is permitted with Jagex before distributing.

Run the mocked tests using Lua 5.4 from this directory:

```powershell
lua tests/lifecycle.lua
lua tests/reaper-overlay.lua
```

Mocks do not verify native rendering or click interception.

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

Separate, user-managed Slayer and Reaper guard lists, empty by default. Never automatically choose, accept, reroll or complete tasks. Leave unrelated interfaces and unknown choices unchanged. Do not modify the game's own block/prefer lists. These features are not implemented.

## Feedback and collaboration

Report bugs and suggestions to [vincent.rs.plugins@gmail.com](mailto:vincent.rs.plugins@gmail.com). Include reproduction steps and client version. Discuss substantial contributions before implementing them; avoid sharing personal information publicly.

## Permissions and data protection

No additional permissions are requested. The overlay reads the configured component's type, restriction, visibility, exact text, parent and geometry. It creates plugin-owned UI and logs overlay actions/errors to the client console. It does not read chat, inventory or character identity, persist settings, transmit data externally or change native task actions. The captured label address is stored in `reaper-config.lua`; dynamic IDs are not assumed to be stable.

## EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula (and all terms incorporated into it by reference). The development and any use of the Plugin is at all times subject to the Jagex EULA.
