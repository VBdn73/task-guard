# Task Guard - Slayer & Reaper

Helps prevent unwanted Slayer cape and Reaper's Choice selections using mouse overlays and saved task preferences.

## Features

- Separate Reaper and Slayer task preferences in plugin settings and the ribbon, with search and **Enable all / Disable all** controls. All tasks are allowed by default.
- Mouse shields and static grey artwork for disabled tasks in recognised native pickers, plus requirement tooltips for recognised game-blocked rows.
- Client-default or alphabetical ordering (ascending or descending), with optional enabled-first sorting in plugin menus and recognised native pickers.
- Per-character settings, a bundled Slayer catalogue and local discovery of new, unique visible Reaper tasks.
- No automatic task selection, acceptance, rerolling or completion; the game's block/prefer lists are unchanged.

## How to use

1. Install **PrettyUI** (mod.io ID `6398181`), the required dependency, and enable the plugin.
2. Open plugin settings or the ribbon. In **Reaper** or **Slayer**, disable tasks you want guarded. Bulk controls affect tasks matching the current search.
3. In **General**, choose task ordering and optionally enable enabled-first sorting. Alphabetical sorting ignores a leading “The”.
4. Open the relevant game picker. Recognised disabled rows receive overlays; right-click supported, available rows to enable or disable them. Open and scroll Reaper's Choice to discover new visible tasks.

## Limitations

- Guards cover recognised task rows in supported English pickers. Unknown, ambiguous, restricted or incomplete rows are left untouched.
- Mouse overlays are not a guarantee against task selection through other input routes. Close and reopen the picker if overlays or sorting do not clear correctly.
- New Reaper tasks default to allowed; game-side renames can become new tasks. No catalogue updates are fetched online.
- Saving requires a valid logged-in character name. Renaming starts a separate profile; old device-wide settings are not imported.

See [changelog.md](changelog.md) for release notes and [planning.md](planning.md) for planned work.

## Feedback and collaboration

Report bugs or propose contributions through the repository's issue tracker or email [vincent.rs.plugins@gmail.com](mailto:vincent.rs.plugins@gmail.com). Include reproduction steps and your client version; discuss substantial contributions before implementing them and avoid posting personal information publicly.

## Permissions

This plugin requests no additional permissions.

## Data protection

**Case 1 (local only):** The plugin reads your character's display name to select a profile and visible picker labels, component state, geometry and artwork to identify task rows. Task preferences, ordering and discovered Reaper names are stored locally through `PersistentDB`, keyed by character name with case and surrounding spaces ignored. No chat or inventory access; nothing is transmitted to the developer or external services.

Settings persist across reloads and client restarts with no automatic expiry. Reusing a display name on the same device can inherit its settings. **Enable all** changes matching preferences, not stored names. Disabling does not erase data; there is no full-data deletion control, and uninstalling should not be assumed to clear the client database. Legacy shared settings remain stored. The developer cannot access or delete local data remotely.

## Local development

Follow the [RuneScape API getting-started guide](https://developer.runescape.com/rs/getting-started.html). Place the repository in `RuneScape-BETA/dev_plugins/task-guard/` and install PrettyUI. In the client console (**Alt + `**), run:

```text
prf
pon task-guard
```

After Lua changes, use `prl task-guard`; after `plugin.json` changes, run `prf` first.

Before publishing, follow [SUBMISSION.md](../SUBMISSION.md) and Jagex's [plugin guidelines](https://developer.runescape.com/rs/submission/guidelines.html). Distribution requires Jagex moderation approval; this repository does not imply approval. Include the contact, collaboration, permissions, data protection and EULA sections in the mod.io description.

## EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula (and all terms incorporated into it by reference). The development and any use of the Plugin is at all times subject to the Jagex EULA.
