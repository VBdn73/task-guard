# Slayer cape choice capture

## First capture (November 2026)

User supplied all 19 report pages: 720 visible unrestricted components from
interface **201**, found by the case-insensitive title search. The user confirmed
the master was **Laniakea**. Client build and UI scale have not yet been recorded. This is one capture, not
evidence that all masters share the interface.

| Role | Interface | Static | Category | Dynamic |
| --- | ---: | ---: | ---: | ---: |
| Dialog root | 201 | 0 | -1 | -1 |
| Scrolling viewport | 201 | 3 | -1 | -1 |
| Companion empty-label list | 201 | 4 | -1 | -1 |
| Named task/background list | 201 | 5 | -1 | -1 |
| Scrollbar | 201 | 6 | -1 | -1 |
| Title: `Select your Slayer task` | 201 | 7 | 0 | 14 |

Lists 4 and 5 share parent static 3 and local position (0, 0). Their captured
dimensions are 480 × 677; the viewport is 480 × 286. Task labels are 230 × 20,
at local x=8 or x=248, with y=5 + 23 × row. The named labels are direct children
of static 5, with nine background sprites and an empty label per task rectangle.
Static 4 contains corresponding empty labels. The root's parent is interface
1477, static 748; do not treat this external host address as a task identifier.

Available-looking rows use sprites 18468–18476; disabled-looking rows use
18504–18512, matching the artwork captured for Reaper. Examples of the latter
include Aquanites, Black demons, Creatures of the Lost Grove and Crystal
shapeshifters. This is visual evidence, not a confirmed requirements API or
proof of why the game has disabled a row.

Important native-name differences from the wiki settings catalogue:

- `Kalphite` rather than `Kalphites`.
- `Profane scabarites` rather than `Profane Scabarites`.
- `Ravenous strigoi` rather than `Ravenous Strigoi`.
- `Sanguine werewolves` appears, whereas the bundled list has `Sanguine crawlers`;
  do not assume these are the same task or migrate one into the other.

`Ravenous strigoi` occurs twice in this capture: static 5/category 0/dynamic
482 at (248, 488), and dynamic 636 at (248, 649). Both have background rows and
empty companion labels. Name-only resolution must not silently choose one;
The user confirmed this duplication is a known game bug. Keep one global
`Ravenous strigoi` preference; a future adapter should validate each duplicate
row independently and apply that same preference to both, not choose one by offset.

Dynamic addresses are observations only; never infer task identity from offsets.
The report includes rows outside the viewport, so `visibleGlobal` alone must not
be interpreted as proof that a row is onscreen or safely clickable.

## Spria comparison (November 2026)

User supplied all three report pages from **Spria**, containing 114 components.
Both Spria and Laniakea use interface **201** and the exact title
`Select your Slayer task` at static 7/category 0/dynamic 14. Their root, external
host, viewport, companion list and named task list have the same captured
addresses and parent chains. Both use task rectangles of 230 × 20, columns
x=8/248 and row positions y=5 + 23 × row.

Spria's task order, read left-to-right across rows, is:

1. Birds, Cave bugs
2. Cows, Crawling hands
3. Gelatinous abominations, Trolls
4. Wolves (left column only)

All seven names already exist in the global catalogue. Each task has nine
background sprites 18468–18476, a named label and an empty label in static 5,
plus an empty companion label in static 4. No disabled-background example is
present in this capture. Lists 4 and 5 are 480 × **500**, compared with
Laniakea's 480 × **677**; list height and task count must not be hard-coded.
Spria's static 6 scrollbar container exists but has no captured dynamic sprite
children, unlike Laniakea's populated scrollbar.

Dynamic task addresses are reused for different tasks: dynamic 9 is **Birds**
for Spria and **Abyssal demons** for Laniakea; dynamic 20 is **Cave bugs** versus
**Acheron mammoths**. A guard must resolve exact current labels and component
instances on each open/master change, never cache task identity by address.

These captures establish a shared picker structure for **the two tested
masters**, supporting a single Slayer adapter backed by the global rules.
Other masters have not been captured; compatible structures should be checked
at runtime rather than assuming every interface 201 instance is safe to modify.

## Next validation

1. Laniakea confirmed; retain this as the first-master baseline.
2. Spria comparison completed: shared interface/title/list structure and row
   geometry confirmed for both tested masters; other masters remain unverified.
3. Investigate duplicate Ravenous strigoi rows and confirm native task names.
4. Verify clipping, scrolling, game-disabled visuals and native hitboxes before
   creating shields. Keep the global Slayer rules independent of Reaper rules.

`slayer-guard.lua` now implements experimental label-bounds mouse shields using
the two-master structure. It validates the exact title and parent chain, companion
labels and complete normal/hover/disabled background artwork, and requires each
row to overlap the viewport after native scroll offsets. Partially visible rows
retain shields as children of the native list, relying on its viewport clipping;
fully hidden rows are removed. Shields are keyed by current
component address with fresh native-identity/name checks (not raw Lua wrapper
table keys); both Ravenous strigoi rows share the global rule. Native
game-disabled rows use the existing transparent requirement target. Dialog
closure, changed identities/layouts and shutdown remove owned shields. Slayer
right-click Enable/Disable actions now share saved global preferences, with
separate callback dispatch IDs and identity/requirements checks before saving.
Native ordering remains unchanged. Native click
interception, scroll-coordinate semantics, clipping and other input routes remain
unverified; only test choices you are willing to receive.

Run `lua tests/slayer-guard.lua` for mocked row, duplicate, requirements, clipping,
master-change and shutdown coverage.

The `CHOICE MATCHES: 0` summary is Reaper-specific (Helwyr / Pick a task) and
does not indicate a failed Slayer capture; the title match found interface 201.
