# Task Guard - Slayer & Reaper

**Task Guard** is a RuneScape plugin project intended to help prevent accidentally choosing unwanted Slayer tasks through a Slayer cape or unwanted Reaper tasks through Reaper's Choice.

**Status: development scaffold only. No tasks are currently blocked, disabled or protected.** API feasibility and compliance still need to be verified. This project is not represented as approved for distribution.

## Current features

- Loadable plugin entry point and manifest, version `0.0.1`.
- Read-only development status in the plugin settings and ribbon panel.
- View cleanup and event unsubscription on shutdown.
- No external dependencies or additional permissions.

## Planned behaviour

- Separate, user-managed lists for Slayer cape task choice and Reaper's Choice.
- Prevent selecting guarded entries only if a supported, permitted API mechanism is available.
- Clearly distinguish plugin guards from RuneScape's own block/prefer lists. Task Guard will not change those lists.
- Never choose, accept, reroll or complete tasks automatically.
- Leave unrelated interfaces and unrecognised choices unchanged.

These are goals, not implemented features. See [planning.md](planning.md) for feasibility checks and milestones, and [changelog.md](changelog.md) for changes.

## Local development

Follow the [RuneScape API getting-started guide](https://developer.runescape.com/rs/getting-started.html). Keep this folder at `RuneScape-BETA/dev_plugins/task-guard/`. In the client console (**Alt + `**), run:

```text
prf
pon task-guard
```

Open the plugin settings or ribbon panel to see the development notice. After Lua changes, run `prl task-guard`; after manifest changes, run `prf` first.

Run the mocked lifecycle test from this directory using Lua 5.4:

```powershell
lua tests/lifecycle.lua
```

Mocked tests do not verify native UI behaviour or protection against clicks. Live-client testing is required before claiming support.

## Project layout

```text
main.lua              Plugin lifecycle and view event handlers
plugin.json           Client manifest
constants.lua         Shared names and event prefix
status-view.lua       Read-only placeholder panel
tests/lifecycle.lua   Mocked lifecycle smoke test
planning.md           Implementation backlog and validation checklist
changelog.md          Version history
```

## Feedback and collaboration

Report bugs and suggestions to [vincent.rs.plugins@gmail.com](mailto:vincent.rs.plugins@gmail.com), or use the repository issue tracker once one is available. Include reproduction steps and your client version. Discuss substantial contributions before implementing them; avoid sharing personal information publicly.

## Permissions

This plugin requests no additional permissions.

## Data protection

The current scaffold only creates plugin-owned status text. It does not read task choices, chat, inventory or character identity; it does not persist settings or transmit data to the developer or external services. Persistent guard lists are planned but not implemented. This section must be updated when data handling changes.

## EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula (and all terms incorporated into it by reference). The development and any use of the Plugin is at all times subject to the Jagex EULA.
