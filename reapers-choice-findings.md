# Reaper's Choice: findings and extension plan

> Implementation update: `reaper-guard.lua` now reconciles saved disabled-task preferences against exact, unique dynamic labels in the captured list. It requires the captured title plus multiple known boss labels, then uses the generalised Helwyr overlay factory. The manual implementation notes below describe the original experiment. The new scoped discovery and multi-task behaviour remain unverified in-client; the title address, English names, direct-child list structure and label-only bounds are assumptions requiring validation. No full-hitbox or alternative-input protection is claimed.

## Outcome

### Native requirement background capture

User captures distinguish available Helwyr/Nex backgrounds (`18468–18476`),
their hover backgrounds (`18477–18485`), and game-blocked Magister/Blood Knights
backgrounds (`18504–18512`). Label and parent input states were identical.
`reaper-requirements.lua` now suppresses overlays only for a complete, unique,
geometrically matching nine-piece disabled background in the same native list.
Unknown states preserve overlay behaviour. This is a client-dependent visual
heuristic, not a requirements API; live suppression testing remains outstanding.
Temporary native-label and row diagnostic tooling has been removed.

Live-client testing established a useful proof of concept: a plugin-owned overlay above the Helwyr entry intercepted the user's tested clicks without choosing the task. Removing the default button stylesheet and adding a static dark rectangle with grey text also worked in-client, without the overlay's default hover/press animation.

This is not yet a complete guard implementation. No client build number was recorded. Coverage of the entire native hitbox, context menus, keyboard/controller inputs and lifecycle transitions has not been established. API access does not imply Jagex approval for distribution.

## Verified interface structure

The capture identified interface **1761** as the choice dialog:

| Component | Static ID | Category ID | Dynamic ID | Observed type |
| --- | ---: | ---: | ---: | --- |
| Helwyr label | 1 | 0 | 262 | LABEL (`2`) |
| Pick A task title | 7 | 0 | 14 | LABEL (`2`) |

Helwyr's observed parent chain was:

1. Interface 1761, static 1: shared choice list, type 20.
2. Interface 1761, static 5: list container, type 20.
3. Interface 1761, static 4: surrounding container, type 20.
4. Interface 1761, static 2: dialog container, type 20.

These are observed addresses, not guaranteed stable task identifiers. In particular, do not infer other bosses' IDs by adding offsets to 262. Dynamic IDs can be reused or change after reopening, scrolling, filtering or a client update. The generic title may also be reused by unrelated dialogs; interface and title alone are not sufficient long-term identification.

## What did not work / what it means

- Scanning for a native BUTTON named Helwyr found nothing: the choice text is a LABEL.
- The native Helwyr label and its parents already reported `enabled=false` while the choice remained usable. Writing that same value is not a demonstrated blocking mechanism. No native interaction configuration was conclusively identified.
- The parent is shared by other choices. Disabling or hiding it would affect unrelated items.
- Other Helwyr matches appeared in chat (interface 137) and another display (1639). Global text matching is unsafe for task targeting.
- The standard plugin button stylesheet animated on hover/press. Keep input interception enabled, but remove that stylesheet for a static disabled appearance.
- `ui.TextData` supports `rgba`, not `rgb`; the latter caused a Lua binding error. The overlay mock now rejects unsupported text colour properties.

## Current implementation

- `reaper-config.lua` holds the captured Helwyr label address.
- `reaper-overlay.lua` rechecks that address is a visible unrestricted LABEL whose content is exactly `Helwyr`, with usable bounds and an unrestricted parent.
- On explicit **Overlay Helwyr**, it creates a translucent black rectangle and a button without a stylesheet or label above it. This dims the native row's text and background for an unmet-requirements-style appearance while retaining its artwork and border; the visual match still needs live-client verification. A PrettyUI tooltip explains that the block is due to plugin settings, not in-game requirements, using the same attach/position/Show pattern as Pre flight check. It is hosted outside the scrolling list and destroyed with the overlay. PrettyUI owns hover visibility; logic ticks only validate the target and never override tooltip visibility. The cursor-bounds fallback was removed after live testing showed a brief flash followed by disappearance. PrettyUI is a required manifest dependency; live-client verification is still required.
- The button remains `enabled=true` and `clickthrough=false`. Its press callback only logs receipt; it never invokes a game action. Disabling the input catcher is deliberately avoided because click interception might stop working.
- Position and size come from the label's local bounds. The covered area is the label rectangle, not a verified native hitbox. No padding is guessed.
- Logic ticks remove the overlay if validation fails, the target/parent changes, its local or global bounds change, or the shield becomes invisible. It is not automatically reapplied. Shutdown attempts to destroy both owned components.
- A frame/tick gap can exist before a change is detected. Cleanup after native interface destruction is best-effort; close/reopen the dialog if it fails.
- The native enabled state and task actions are never changed. No guard list or persistence exists yet.

Discovery scans, parent dumps, native enabled-state probes and their panel controls have been removed from Task Guard. The separate `bank-interface-diagnostics` utility remains independent; it is not a plugin dependency. `copy.txt` is an investigation artifact, not runtime input.

## Extending to other choices

1. **Identify the correct dialog instance.** Establish a reliable Reaper-specific discriminator before applying any overlays. Confirm unrelated dialogs using interface 1761 cannot match accidentally.
2. **Enumerate choices only within the verified list.** Traverse that list's dynamic components and identify exact task labels. Build a reviewed mapping to stable task IDs if the API exposes them; otherwise use explicit exact-name mapping and document localisation/version limits. Do not search chat or all interfaces.
3. **Resolve fresh component instances.** On open/reopen and list changes, rebuild the task-to-component mapping. Require unique, visible, unrestricted matches. Leave unknown or ambiguous entries untouched and report protection unavailable.
4. **Verify the full per-entry hitbox.** Inspect siblings, visual bounds and interaction configuration around each label. Check both columns, edges, row spacing and clipping. Do not extend an overlay into neighbouring choices, the scrollbar or confirmation controls.
5. **Generalise the overlay factory.** Accept a verified target, task identity and display text instead of hard-coding Helwyr. Maintain an independent owned overlay per guarded visible entry. Preserve static visuals and input interception; never invoke native task actions.
6. **Implement guard settings.** Add a user-managed Reaper guard list, empty by default, separate from Slayer cape settings and game block/prefer lists. Decide storage scope, validation, migration and reset behaviour before persisting it.
7. **Implement lifecycle management.** Reconcile overlays with settings, scrolling, pagination, resize/UI scaling, dialog movement, task changes, close/reopen, logout, reload and shutdown. Choose whether moving overlays can be updated safely or must be removed/recreated. Never leave a stale shield over another task. Clearly indicate when protection is unavailable.
8. **Verify every input route.** Centre/edge left clicks, right clicks/context menus, existing open menus, keyboard shortcuts, controller input and any separate confirm path must be tested. A visual/mouse overlay must not be advertised as complete protection if another route bypasses it.
9. **Confirm policy and release requirements.** Ask Jagex whether this interaction-blocking overlay is permitted. Update README, permissions/data handling and release claims to match actual coverage, and follow moderation before distribution.

## Validation checklist

- [x] User-reported Helwyr click interception without task selection.
- [x] User-reported static overlay appearance works after colour-property fix.
- [x] Mocked lifecycle and overlay validation/cleanup coverage.
- [ ] Record client build, UI scale and exact tested input routes.
- [ ] Full hitbox including borders and gaps; no neighbouring choice affected.
- [ ] Right-click/context menus, keyboard/controller and confirm-path coverage.
- [ ] Multiple guarded bosses, none guarded, all guarded, unavailable bosses.
- [ ] Scrolling, pagination, resize, movement, reopening, logout and reload.
- [ ] Reliable Reaper-only dialog identification and fresh identity mapping.
- [ ] Settings persistence/reset and robust multi-overlay cleanup.
- [ ] Jagex policy confirmation and distribution review.

Mock commands: `lua tests/lifecycle.lua` and `lua tests/reaper-overlay.lua`. Mocks validate plugin logic, not native hit testing, rendering or client event ordering.
