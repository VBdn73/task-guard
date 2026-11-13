# Planned work and investigations

This is a development roadmap, not a promise that the client API supports task blocking. The current plugin is a read-only scaffold.

## 1. Confirm feasibility and compliance

- [ ] Review the current Jagex plugin guidelines for modifying task-choice interactions.
- [ ] Inspect Slayer cape task-choice and Reaper's Choice interfaces in-client; record verified component IDs and task identifiers.
- [ ] Establish whether a supported API can disable each choice before an action is sent. Observing an already-selected menu entry is not sufficient protection.
- [ ] Check every supported input route: direct clicks, context menus and keyboard shortcuts, where present.
- [ ] If reliable blocking is unavailable or prohibited, document the limitation and agree on a clearly labelled warning-only alternative rather than claiming protection.

## 2. Settings and task identity

- [ ] Add independent Slayer and Reaper guard lists, empty by default.
- [ ] Use verified stable identifiers where possible; avoid ambiguous substring matching or guessing from display order.
- [ ] Add searchable task lists, clear guarded-state labels and an explicit reset control.
- [ ] Decide whether settings are shared or character-specific before adding persistence; document storage scope and deletion behaviour.
- [ ] Consider PrettyUI (`6398181`) when interactive settings are introduced. Do not require it while the scaffold uses only native text.

## 3. Guard integration

- [ ] Keep Slayer cape and Reaper's Choice adapters separate from the shared guard rules.
- [ ] Change only verified choice entries and explain why guarded entries cannot be selected.
- [ ] Preserve the game's own unavailable/locked states; never enable a choice the game disabled.
- [ ] Restore any plugin-owned changes on reset, interface replacement, logout and shutdown without undoing newer game state.
- [ ] Leave unknown interfaces unchanged. Clearly report unavailable protection instead of silently claiming it is active.
- [ ] Handle an all-guarded list without automatically selecting or rerolling anything.

## 4. Testing and release

- [x] Add mocked lifecycle smoke coverage for settings, ribbon and shutdown.
- [ ] Add pure-Lua tests for guard matching, settings validation and persistence migrations as those modules are implemented.
- [ ] Verify settings/ribbon sizing, reopening, reload and disable behaviour in-client.
- [ ] Test real task choices, pagination, scrolling, interface replacement and all input routes.
- [ ] Verify unrelated Slayer/Reaper dialogs and game block/prefer lists remain untouched.
- [ ] Update README, changelog, permissions and data-protection details to match implemented behaviour.
- [ ] Follow the workspace submission checklist and Jagex moderation process before distribution.
