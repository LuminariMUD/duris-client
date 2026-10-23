# SHIP redesign: the Captain's Table

Date: 2026-10-23. Status: implementation and scoped qualification complete; review repairs ready for sequential merge.

## Current handoff

**Implementation and scoped qualification are complete; the client stack is ready for sequential merge.**
Keep issue #13 open until review/integration. No client PR has been merged or manually tagged here.

- Merge order: [#14 — Details](https://github.com/LuminariMUD/duris-client/pull/14)
  (`c7d4e10`) → [#15 — Captain's Table](https://github.com/LuminariMUD/duris-client/pull/15)
  (`2cf57f69fc8525f9b084e89d289fedcd9eeae9b1`) →
  [#16 — qualification](https://github.com/LuminariMUD/duris-client/pull/16).
  Current master `e540a12` is already an ancestor of all three branches. Keep the
  dependent bases until their predecessors merge. Prefer merge commits to preserve
  ancestry, then retarget each successor to master. If squash merges are chosen,
  save each predecessor tip and explicitly rebase its successor onto master before
  retargeting; simply retargeting would reintroduce predecessor history. #16 carries
  the latest #15 fix through merge `a63cf1d`. Master CI continues to own release tags.
- Active branch: `branch/issue-13-ship-qualification`. The original requested branch
  `branch/issue-13-ship-captains-table` owns #14. All completed work is committed/pushed.
- Final package: **2.3.0**, source plus rebuilt `duris-client.mpackage` in #15.
  Archive SHA-256 `cedd3627f739bd45a397bd686df516b4877f47afd253f42cda02d5ff3ddaae78`;
  canonical payload `8d4976fb5c2a31876ba8bdbde15ab49f37b0746e1292b030bab9f4a137c8b330`.
  [offline-evidence.json](../testing/issue-13/offline-evidence.json) and
  [live-qualification.json](../testing/issue-13/live-qualification.json) identify the
  exact archive and canonical payload hashes, sources, environments, inputs and proof.
- Outcome: full bridge information preservation and a responsive Captain's Table
  inside Character → SHIP, with complete selectable Details and Copy details.
  Non-goals remain ship mechanics, combat controls, new polling, a new window/framework,
  external dependencies or a change to existing typed automation.
- Ablation reused production display/load helpers, ArjUI lifecycle owners and native
  Geyser widgets. A code-native schematic replaces the optional bitmap dependency.
  Slot/contact inspectors reuse the same complete rows as their manifests. No new
  dashboard framework, image requirement, heartbeat or local timer countdown was added.
- Server prerequisite [Duris #304](https://github.com/LuminariMUD/Duris/pull/304) was
  squash-merged by the user as `e86bf7f24c52449b1260bb378443efafd1d9c491` and deployed
  to `mud.duris.sbs:7777`. Production-helper/wire/lifecycle checks, server build,
  formatting and whitespace checks passed. Client wire fixtures identify that source.
  The protocol does not expose the deployed binary revision; live behavior is verified directly.
- New Info/Contacts associate by opaque observing-vessel key. Contacts for another key
  wait for matching Info; replacement snapshots do not retain omitted new-only fields.
  Legacy explicit ordinary-ID changes, or changed names for `**`, clear navigation;
  partial untagged Info without identity fields retains the last untagged navigation.
  Explicit target null differs from absence. Display locks never supply an invented bearing.
- Eighteen reported code review findings are repaired in their owning PRs:
  optional target fallback, reveal repaint, complete duplicate-ID scans, duplicate
  identity checks before bearing validation, captain availability to cargo automation,
  current-snapshot inspectors for identical contacts, legacy Contacts without identity,
  removed-slot highlight clearing, bare-array navigation, captured marker generations,
  grouped targeting flags, truthful text provenance, unknown contact counts and independent
  legacy sunk state. The empty-captain guard preserves the existing cargo alias's
  unknown-captain behavior. The bearing rings and markers share a calibrated radius.
  The latest #15 repair clears a whole mixed contact group when any member becomes
  ambiguous, preserves destroyed Yes/No/unknown, and combines overlapping actual/ordered
  helm glyphs while retaining both exact headings. Existing fixtures cover all cases.
  The renderer needs no new state, framework or compatibility path for these fixes.
- **Offline proof:** the full **23/23** suite passed after the review repairs at
  `~/.local/share/duris-captains-table-reviewed-suite`, source `2e7cc5d`.
  Subsequent repairs passed focused `ship-bridge` and `ship-table` checks at
  `~/.local/share/duris-captains-final-all-ship` and `~/.local/share/duris-captains-calibrated-plot`.
  Fresh `ship-table` runs on the current payload pass **58/58** assertions at scale 1
  (`~/.local/share/duris-pr15-review-final/20261023T134157Z-abcaea30-ship-table`) and scale 2
  (`~/.local/share/duris-pr16-review-scale2/20261023T134422Z-d8cddce6-ship-table`), with no Lua errors
  and normal shutdown/cleanup. Release validation and whitespace checks pass. The unchanged
  Python release/controller paths retain their 15/10 passing tests from #14. Reuse the
  broad suite for unchanged paths; the focused runs prove the new Bridge behavior.
- **Visual/native proof:** inspected 1280×720, 1366×768, 1920×1080, minimum 285×160
  Character, scrolled manifest before/after updates, selected modes, and Errors views.
  The current scale-1/2 helm, manifest, minimum frame and Errors views were inspected.
  Actual **Mudlet 4.22.0 / Qt 6.9.0** proof at
  `~/.local/share/duris-captains-table-4.22-qualified` retains its pre-review payload.
  Its executable path/hash, original launcher and rechecked full version output are now
  preserved in `offline-evidence.json`; the latest three Bridge repairs were not rerun
  on 4.22. Unrelated suite cases establish behavior rather than blanket visual fidelity.
- **Compatibility:** legacy Info/Contacts, fallback/clears and automation use the
  retained focused Mudlet fixtures. Old-server/new-current-client live qualification
  is not claimed because that run has no self-contained retained evidence. The original
  **2.1.2** archive passes the focused real-wire scenario with the new additive payload.
- **Retained new-server same-ship baseline PASS:** independent `Duris-Live-Test`, exact
  pre-review archive recorded in `live-qualification.json`, no companion, send override
  or injected GMCP. This is reusable baseline evidence, not a new live run of the current
  archive. GallTest's reference text,
  decoded packets, Bridge and Details pass **62** assertions plus screenshot inspection:
  hull weight **330000**, load **80/165**, cargo **5/70 crates**, ordered/actual **0/0**,
  max speed **50**, display/raw/max stamina **800/800/800**, all four armor/internal
  arcs, sail **130/130**, six weapon rows and independent slot status/timer/destruction,
  crew/chiefs/skills/modifiers, repairs, passengers, explicit null target and matching keys.
  See [live-bridge.png](../testing/issue-13/live-bridge.png),
  [live-details.png](../testing/issue-13/live-details.png), reference text and JSON beside them.
  The three new fixes affect only Bridge presentation/selection; accepted packets,
  Details and reference commands are unchanged. Reuse the baseline only for those
  paths. The live captain was Zahm: empty-captain/cargo-alias proof comes exclusively
  from the focused `ship-bridge` regression, not the 62 live assertions.
- **Live cleanup:** real bridge departure cleared info/key/max-speed/target and the ledger.
  Veridian returned to the original Inn of Oceans, room **66899**, quit and disconnected.
  Owned desktops are closed and temporary credential copies removed. Raw independent
  live evidence is retained externally at `~/.local/share/duris-captains-live-qualified`.
  No production ship orders or mechanics were changed.
- **Limits:** the live vessel was docked with no equipment, contacts or target. Moving
  orders, fatigue, damaged/reloading equipment, destruction thresholds, contraband,
  populated/overlapping contacts and all 16 occupied slots use production-helper,
  wire and Mudlet fixtures, not invented live claims. Actual **Mudlet 4.19.1**, native
  Windows/macOS and physical DPI/input are unverified. The 4.19.1 source API audit confirms
  the chosen primitives; it is not runtime qualification. The minimum remains unchanged.
- Next: integrate #14 → #15 → #16 using the ancestry rules above.
  Preserve source/archive pairing and the documented evidence boundaries. There is no
  scoped implementation work left open; unsupported-platform manual checks remain explicit limits.


## Tracking and navigation

- Work item: [issue #13 — Captain's Table SHIP view with full look ship parity](https://github.com/LuminariMUD/duris-client/issues/13).
- Dedicated branch: [branch/issue-13-ship-captains-table](https://github.com/LuminariMUD/duris-client/tree/branch/issue-13-ship-captains-table), linked in the issue's Development section.
- [Published plan on that branch](https://github.com/LuminariMUD/duris-client/blob/branch/issue-13-ship-captains-table/docs/ongoing-projects/plan-ship-bridge.md).
- Earlier work: [SHIP readability issue #3](https://github.com/LuminariMUD/duris-client/issues/3), [feedback index #1](https://github.com/LuminariMUD/duris-client/issues/1), and the [historical qualification plan](plan-ship-qualification.md).

Keep the issue checklist and this plan aligned as implementation progresses.
The earlier issues remain completed; #13 tracks the expanded bridge parity and
graphical redesign. The original tracking branch began with planning documents; the review stack above now carries the implementation.

## Recommendation

Turn Character → SHIP into a **Captain's Table**: an engraved, live ship diagram,
navigation instruments, an armament manifest, and a contact bearing plot. Keep a
**Details** view containing every existing SHIP field, plus everything needed to
match the bridge's `look ship`. The diagram should explain the ship's condition
at a glance; the ledger should make every number readable and copyable.

Deliver this as a coordinated **server contract extension and client redesign**.
A client-only visual refresh cannot recover facts that the server does not send.
Support the present server during rollout, but do not call the work complete
until full bridge parity is demonstrated against an updated server.

Use the existing adjustable Character frame from PRs #8/#12. Resizing or
maximizing it reveals a wider composition; the ordinary sidebar remains useful.
Keep the dark iron, bronze, parchment-colored text and restrained status colors
of [DESIGN.md](../DESIGN.md). Keep the main game feed and native command input.

## Evidence and scope

Inspected clean client `master` at
[`e540a1235d92e851791dab522aa4bc33eaba2b90`](https://github.com/LuminariMUD/duris-client/tree/e540a1235d92e851791dab522aa4bc33eaba2b90),
package version **2.1.2**. PRs
[#7](https://github.com/LuminariMUD/duris-client/pull/7),
[#8](https://github.com/LuminariMUD/duris-client/pull/8),
[#9](https://github.com/LuminariMUD/duris-client/pull/9),
[#10](https://github.com/LuminariMUD/duris-client/pull/10),
[#11](https://github.com/LuminariMUD/duris-client/pull/11) and
[#12](https://github.com/LuminariMUD/duris-client/pull/12) are merged. Preserve their
compact-header, adjustable-panel, scroll, visibility, recovery and lifecycle fixes.

Inspected the supplied server checkout at
[`e2c7570f207f5c8fd9b9292055a0c473fd6b807a`](https://github.com/LuminariMUD/Duris/tree/e2c7570f207f5c8fd9b9292055a0c473fd6b807a).
This establishes source behavior, not which revision the live game is running.

The saved [GallTest look ship](../testing/issue-3/look-ship.txt),
[SHIP details](../testing/issue-3/live-panel.txt),
[decoded GMCP](../testing/issue-3/live-gmcp.json), and
[side-by-side screenshot](../testing/issue-3/live-look-ship.png) provide a useful
same-ship reference. They are historical 1.3.7 evidence, not new qualification of
2.1.2 or this proposal. The [earlier qualification plan](plan-ship-qualification.md)
explicitly recorded the missing weight/load, orders and slot-state fields.

### What the ASCII ship actually means

The outline in `look_ship()` is fixed art, but its contents form a live damage
diagram. Bow is at the top, port left, starboard right, and stern at the bottom.
Outer values show current/max armor; inner values show current/max internal
structure for each of those four arcs. The rigging annotation shows current/max
sail. Armor/internal colors change with damage. Preserve this spatial meaning.

The adjacent list enumerates occupied slots 0–15. A row's height beside the art
does **not** locate that slot physically on the hull. Group weapon markers by
their actual reported arc; do not invent deck coordinates or class-specific
anatomy. Source: [look_ship and generate_slot](https://github.com/LuminariMUD/Duris/blob/e2c7570f207f5c8fd9b9292055a0c473fd6b807a/src/ships/ship_control.c#L1603).

### Why the present displays differ

1. **Different presentation:** `renderShip()` is a scrolling MiniConsole. It
   flattens the spatial damage diagram into sections. Clicking SHIP requests
   `look contacts`, not `look ship`.
2. **Missing bridge facts:** `Ship.Info` omits hull weight, current/max weight
   load, set heading and set speed. Current heading/speed arrive separately in
   `Ship.Contacts`. Cargo crates are a different capacity measure from load.
3. **Incomplete slot state:** weapons have numeric damage and `ready`; equipment
   has only `ready`. The bridge also prints damage/status wording and timer
   values. `ready` means `timer == 0`, not that a weapon can fire.
4. **Stamina semantics:** GMCP sends integer raw stamina. The bridge calls
   `get_display_stamina()`, which compresses a negative deficit using a square
   root. For example, raw -400 displays as -20. The positive-stamina GallTest
   reference did not exercise this difference.
5. **Different damage colors:** the client uses ratios ≤25% and ≤60%; the server
   uses strict comparisons with integer one-third and two-thirds thresholds.
   Match the server's boundaries for armor/internal structure and keep labels
   readable without color.
6. **Target completeness:** the client reconstructs the lock from contacts and
   clears it on an empty list. `look ship` can still name a loaded locked target
   absent from that list. Preserve both target ID and name without inventing a
   bearing for an unseen target.
7. **Other contract gaps:** contact X/Y values are received but normally omitted
   from SHIP rendering. Contraband names take a different lookup path in
   `generate_slot()` than in the current JSON cargo serializer; parity tests
   must cover that case, not just ordinary silk cargo.

Sources: [current SHIP implementation](https://github.com/LuminariMUD/duris-client/blob/e540a1235d92e851791dab522aa4bc33eaba2b90/src/scripts/ArjUI.lua#L3795),
[Ship.Info serializer](https://github.com/LuminariMUD/Duris/blob/e2c7570f207f5c8fd9b9292055a0c473fd6b807a/src/core/json_utils.c#L1275),
[contacts and delivery](https://github.com/LuminariMUD/Duris/blob/e2c7570f207f5c8fd9b9292055a0c473fd6b807a/src/net/gmcp.c#L495),
[slot status](https://github.com/LuminariMUD/Duris/blob/e2c7570f207f5c8fd9b9292055a0c473fd6b807a/src/ships/ship_utils.c#L1339),
[stamina](https://github.com/LuminariMUD/Duris/blob/e2c7570f207f5c8fd9b9292055a0c473fd6b807a/src/ships/ship_utils.c#L1640),
[damage colors](https://github.com/LuminariMUD/Duris/blob/e2c7570f207f5c8fd9b9292055a0c473fd6b807a/src/ships/ship_utils.c#L2185).

## Visual and interaction design

### 1. A living damage diagram

Use a quiet, top-down hull engraving with **two distinct layers**: armor around
the outside and internal structure inside. Each arc carries its name and exact
current/max numbers. A small paired gauge reinforces each pair. The sail has its
own rigging gauge. Damage changes the affected section's accent and an adjacent
text label, rather than tinting the whole vessel and losing location information.

Use a generic schematic initially. Decorative artwork contains no numbers,
weapon positions or authoritative state. Overlay live values with real widgets,
so long names, font changes and unknown maxima remain readable. A missing image
must leave a complete labeled four-arc display.

Clicking an arc focuses its detail block and highlights weapons mounted on that
arc. This is local inspection. It must not send an order, change target lock or
switch the main character tab unexpectedly. Keep all values accessible without
hover; tooltips only explain terminology.

### 2. Helm instruments: actual versus ordered

Show **Heading / Ordered heading** and **Speed / Ordered speed / Maximum** as
separate labeled values. A bronze compass bezel can place a solid actual-heading
marker and a hollow ordered-heading marker; their exact degree values sit beside
it. The instrument only moves when accepted data changes. Handle 359° → 0°
without an invented long rotation. Unknown orders remain unknown.

Keep ship name, designation, captain, frags, status and target ID/name together.
The ship's explicit status is primary; use distinct text for docking, anchoring,
immobility and sinking. Show hull weight, weight load, cargo crates, passengers
and repair stock with their own labels. Never combine them into one capacity bar.

### 3. Broadside manifest

Place compact numbered weapon badges along Forward/Port/Starboard/Rear rails.
Within an arc, order badges by numeric slot. This encodes mounting arc only.
Unmapped/hold positions have a labeled neutral area. Selecting a badge opens its
full row: name, slot, mounting position, ammo current/max, numeric damage, server
status, timer count and timer-ready flag.

The manifest also offers **All slots**, interleaving weapons, equipment and cargo
by their actual slot number, like the bridge. Category sections remain available
in Details. Preserve every occupied slot, including long names and slot 0.

Use separate labels for **Timer ready**, **Out of ammo**, **Damaged** and
**Destroyed**. A green timer marker must not advertise firing eligibility.
Equipment timers are generic timers; a levistone countdown is not automatically
a weapon reload. No speculative progress percentage or seconds remaining.

### 4. The bearing glass

A compass-like contact plot adds tactical interest without replacing the list.
Keep north at the top, print ring ranges in server range units, show contact IDs,
and distinguish **our lock** from **targeting us** with labeled marker shapes.
The adjacent list keeps every contact's name, X/Y, range, bearing, heading, speed,
two-letter arc, allegiance and status. Range sorting remains deterministic, with
ID as a tie-breaker. Overlapping markers reveal a list of their contacts.

This is a **bearing/range diagram**, not an authoritative terrain map. The server
uses 0° north/90° east; plot screen X using `sin(bearing)` and Y using
`-cos(bearing)`. Range includes altitude, so radial placement represents reported
range, not necessarily horizontal geographic distance. State that in its legend.
Do not invent coastlines, world position, firing solutions or movement trails.

Preserve X/Y as the server's tactical coordinates, centered on the observer's
50/50 reference; do not label them longitude/latitude or assume they are global
map coordinates. Ordinary Mudlet clients do not receive the verified-web-client
`worldX/worldY` fields. Do not depend on those fields.

Decode a valid two-letter arc as **our arc / their arc**: for example, `SF` means
the contact bears on our starboard and we bear on its forward arc. Display an
unrecognized value literally. Include good, evil, undead, squid and unknown
allegiances, plus flying/sinking/immobile/docked/anchored status. Unknown allegiance
must not be inferred from a name. The source's forward/rear arcs are 80° and beam
arcs 100°; avoid drawing four equal firing sectors or claiming weapon reach.

Sources: [contact coordinates, bearings and arcs](https://github.com/LuminariMUD/Duris/blob/e2c7570f207f5c8fd9b9292055a0c473fd6b807a/src/ships/ship_utils.c#L1040)
and [three-dimensional range](https://github.com/LuminariMUD/Duris/blob/e2c7570f207f5c8fd9b9292055a0c473fd6b807a/src/ships/ship_utils.c#L2200).

### 5. Crew watch and hold ledger

Give Deck, Guns and Repair one readable row each: chief, integer skill and signed
modifier. Show crew type, bridge-display stamina, raw stamina, maximum stamina,
passengers and repair stock. A negative stamina value becomes an explicit fatigue
readout, never a negative-width gauge. Show known empty chief slots as None.

The hold ledger separates weight load from crate capacity. Each cargo entry keeps
slot, full commodity name, crates, invoice price and a written contraband marker.
Equipment gets full names and condition/timer details. Warnings can draw attention
to supplied facts such as empty ammunition or sinking; they do not create a new
automatic gameplay action.

### 6. Bridge and Details, with real reference commands

Provide two view controls: **Bridge** and **Details**. Bridge is the visual
composition with scrollable sections; Details is the complete, selectable text
ledger using the existing MiniConsole. Preserve its section order, wrapping and
scroll behavior. A local Copy details action exports that same rendered state.
Changing view or resizing sends no command.

Explicit **Look ship**, **Look crew** and **Contacts** actions send exactly the
named read-only game command once and leave the output visible in the game feed.
The normal SHIP refresh action should request `look ship`, fixing the present
contacts-only behavior. Do not start polling on tab selection. Keep existing
ArjAuto contact polling opt-in and independent.

Contact/weapon clicks select an inspector only. Combat controls, automatic locks,
course changes, firing, jettisoning and new automation are outside this redesign.
Existing typed aliases remain available and must retain their behavior.

## Responsive composition

Use the **available SHIP body size**, after frame chrome and character tabs, to
choose layout. Starting targets below are subject to real-Mudlet visual checks:

- Below about 420 logical pixels wide: one vertical column, a compact hull with
  four explicit arc blocks, textual helm values, then weapons/crew/hold/contacts.
  The bearing plot is collapsed behind its own local control; the complete
  contact list remains. Full names wrap. Do not shrink fonts to fit more art.
- At about 420–719 pixels: hull and helm share a row when text fits; everything
  else stacks. If font metrics make that cramped, use the narrow layout.
- At 720 pixels and above: hull/armament on the left; helm/bearing glass on the
  right; manifest, crew and hold below. Details still offers the full ledger.
- At very short heights, keep only the small mode/action strip fixed; identity,
  instruments and sections scroll. A decorative header must not consume the
  usable body of the current 285×160 minimum Character frame.

Wide arrangement, using historical GallTest values solely to illustrate placement:

```text
SHIP    [Bridge] [Details]                  [Look ship] [Look crew] [Contacts]
GallTest  [**]   DOCKED       Captain Zahm       Frags 0

             FORWARD                       HELM
          Armor 81/88                       Heading 0°    Ordered 0°
          Hull  44/44                       Speed   0     Ordered 0   Max 50
                 /\
 PORT           /  \       STARBOARD        Hull weight 330,000
 Armor 76/110  |    |       Armor 91/110     Weight load 80/165
 Hull  52/55   |mast|       Hull  55/55      Cargo 5/70 crates
               |    |                      Passengers 0/20   Repairs 330
               |____|                      CONTACT BEARING GLASS + LIST
            REAR / STERN                   Docked · Contacts 0
          Armor 41/55
          Hull  27/27       Sail 130/130

ALL SLOTS [0] [1] [2] [3] [4] [5] [6]       CREW WATCH
Selected slot: full name, position,         Corwell Sea Dogs · Stamina 800/800
ammo, damage, status and timer              Deck / Guns / Repair + chiefs/mods
HOLD: [6] Silk Cloth · 5 crates · invoice 156000
```

Existing frame controls supply maximize/restore, lock, dock and reset. No separate
ship window, independent layout persistence system or forced full-screen mode.
Remember only the user's Bridge/Details preference; live ship state remains
session-local. Restoring or reopening returns to the selected view and section.

## Information preservation contract

Every row below must have a fixture assertion and a visible destination. Essential
facts cannot live only in tooltips, colors, an image or a collapsed summary.

| Information | Existing sources | Required destination / parity rule |
| --- | --- | --- |
| Name, ID, captain, frags, status | `Ship.Info`, text fallback, `look ship` | Identity block and Details; full text, including ID `**` |
| Current heading/speed, max speed, contact range | Contacts envelope, Info, text | Helm and Details; retain fresh zero values and observer-specific maximum speed |
| Set heading/speed | `look ship`; missing in GMCP | Separate ordered values; never substitute current values |
| Locked target ID/name | `look ship`, contact flags, lock text | Identity/target inspector; unseen target has no fabricated navigation |
| Bow/port/starboard/stern armor and internal current/max; sail current/max | Info and `look ship` | Spatial hull plus all nine exact pairs in Details |
| Hull weight; current/max weight load | `look ship`; missing in GMCP | Separate weight rows; independent of cargo crates |
| Weapon slot/name/position/ammo/maxAmmo/damage/ready | Info; bridge adds status/timer and destroyed-ammo marker | Arc badges and complete slot rows; retain numeric damage and timer-ready even when unusable |
| Equipment slot/name/ready | Info; bridge adds status/damage/timer | Complete equipment rows; generic timer semantics |
| Crew type, chiefs, three integer skills and signed modifiers | Info, `look crew`, text skills | Crew watch and Details; preserve skill-increase notices |
| Raw/display/max stamina; passengers/max; repair stock | Info plus bridge display rules | Explicit raw/display distinction when different; known zeros stay visible |
| Cargo current/max crates; every slot/name/crates/invoice/contraband | Info, `look ship`, cargo text | Hold ledger and Details; preserve invoices and correct contraband names |
| All contact fields and target flags | Contacts, contact text | Plot inspector plus complete range-sorted list; X/Y and both arc meanings visible |
| Legacy fallback facts: aboard/docked/under-way, skills, lock, facing/pointing, sunk marker | Existing text triggers and accepted legacy payloads | Preserve representable facts, marked as text-derived; never override authoritative clears |

`class` is already received but not rendered. Retain it in state; use a class name
only if the server supplies one. Do not hard-code a numeric class-to-art mapping.
Preserve supported legacy field aliases without dumping arbitrary JSON into the UI.

## Server contract work

Extend the existing packages additively; retain old fields and types so the
current client and website continue to work. Suggested new **optional** fields:

- `Ship.Info.bridge.hullWeight`: numeric weight exactly as printed by the bridge
  (`SHIP_HULL_WEIGHT * 1000`), using a safe numeric conversion. Do not invent tons
  or pounds; the current display does not establish a physical unit.
- `bridge.load.current` / `bridge.load.max`: `SHIP_SLOT_WEIGHT` / `SHIP_MAX_WEIGHT`.
  Use the actual helper: equipment, cargo and flying levistones affect load.
- `bridge.setHeading` / `bridge.setSpeed`: the same values/casts as `look_ship()`.
- `bridge.displayCrewStamina`: `get_display_stamina()` before information is lost
  to the existing integer raw-stamina serialization. Add `bridge.crewStaminaBand` from
  the same raw comparisons as `get_stamina_prefix()` for correct fatigue color.
- `bridge.target`: null for no displayable target, otherwise `{id, name}` under
  the same loaded-target condition as the bridge. Absence means an older contract.
- `weapons[].statusText`, `equipment[].statusText`: stripped, trimmed copies of
  `get_status_str()`. Include `timer` for both and `damage` for equipment. Retain
  `ready` as the existing independent boolean. Expose weapon `destroyed` using
  the existing combat predicate, and `positionLabel` from `get_position_str()`
  where the enum alone would lose bridge wording.
- Cargo item names: use the matching normal-cargo/contraband description helper;
  this is a naming correction, not a change to crate counts or invoice units.
- `Ship.Info.shipKey` / `Ship.Contacts.shipKey`: the same opaque, session-local
  observing-vessel identity in both packets. Use the existing runtime reference
  (slot plus generation), serialized as a string to avoid Lua integer precision
  loss. Never use the displayed designation as this key: docked vessels share
  `**`, and designations can change. Keep the existing departure payload and
  empty-contact behavior compatible; clear the key on disconnect. The existing
  [runtime identity registry](https://github.com/LuminariMUD/Duris/blob/e2c7570f207f5c8fd9b9292055a0c473fd6b807a/src/ships/ship_identity.c#L8)
  already distinguishes live ships from reused storage.

There is a source edge case to preserve explicitly: weapon destruction checks
`damage >= 100`, while `get_status_str()` prints Destroyed only above 100. At 100,
the bridge can show `**` ammo and Badly Damaged. Export the actual status and
predicate independently; test 99/100/101. Do not silently alter combat rules or
rewrite that server wording as part of a display change.

Armor/internal color parity can use a small tested client helper matching the
server's integer thresholds. Empty/invalid maxima stay neutral with literal
numbers. Sail and other new gauges must not imply server condition rules that
the bridge does not apply to them.

Timers are server counters, **not seconds**. Weapon timer decrements can pause
for ramming/mindblast and skip due to fatigue; equipment uses different behavior.
Show the supplied counter, never a locally ticking ETA or inferred percentage.
Source: [slot timer updates](https://github.com/LuminariMUD/Duris/blob/e2c7570f207f5c8fd9b9292055a0c473fd6b807a/src/ships/ship_base.c#L2953).

The server checks ship updates every two pulses (approximately 500 ms) and sends
only changed hashes. Do not add a timestamp to every payload and defeat that
suppression. Preserve personalized max speed, per-descriptor delivery, bridge-only
scope and unverified-client world-coordinate filtering. An unchanged ship may
legitimately send nothing for a long time.

## Mudlet implementation approach

This is feasible with the native UI stack already used by the package:

- **Layout:** `Geyser.Container` with percentage constraints and measured text
  sizes; the existing `Adjustable.Container` remains the outer owner. Geyser
  supports relative geometry and nested visibility.
  [Geyser manual](https://wiki.mudlet.org/w/Manual:Geyser).
- **Hull and instruments:** `Geyser.Label` for a bundled PNG engraving, labels,
  markers and local click callbacks; Qt stylesheets for restrained borders and
  fills. Position markers with Lua geometry instead of assuming browser canvas,
  CSS transforms, JavaScript, WebGL or an embedded web view.
  [Label reference](https://www.mudlet.org/geyser/files/geyser/Geyser.Label.html).
- **Condition:** `Geyser.Gauge` supports values, text and styling. Use exact
  current/max labels alongside bars and handle unknown/negative values before
  calling the gauge API.
  [Gauge reference](https://www.mudlet.org/geyser/files/geyser/Geyser.Gauge.html).
- **Long content:** use a `Geyser.ScrollBox` for the visual page and retain
  `Geyser.MiniConsole` for the complete Details ledger and copyable text. Verify
  wheel ownership and scroll restoration with nested interactive widgets.
  [ScrollBox](https://www.mudlet.org/geyser/files/geyser/Geyser.ScrollBox.html),
  [MiniConsole](https://www.mudlet.org/geyser/files/geyser/Geyser.MiniConsole.html).
- **Sizing and compatibility:** measure with `calcFontSize`; use existing label
  callback and tooltip APIs. Do not require `Geyser.TextEdit`/`createTextEdit`,
  whose documented minimum is 4.21, while this package promises 4.19.1.
  [UI functions](https://wiki.mudlet.org/w/Manual:UI_Functions#calcFontSize),
  [TextEdit minimum](https://wiki.mudlet.org/w/Manual:UI_Functions#createTextEdit).

Official references were checked on 2026-10-23. Current documentation confirms
the approach, not every historical Geyser method's availability. Audit the
actually bundled 4.19.1 API before implementation and manually qualify that
minimum. The automated controller requires Mudlet 5.0+.

### State and ownership

Keep changes inside ArjUI's existing ship subsystem initially. Use a small
normalization step consumed by Bridge and Details; do not introduce a general
dashboard framework or a fourth script merely for this feature. Preserve the
state fields read by `ArjAuto:shipState()`, `targetContact()` and relative-heading
aliases. Do not mutate incoming `gmcp` tables or sort their arrays in place.

Treat Info and Contacts as independent **replacement snapshots**, with absence,
empty arrays, null, false and numeric zero distinguished. New Info does not keep
old missing weapons/cargo alive. Contacts navigation remains authoritative for
actual heading/speed; ordered values are a separate source. Old-contract Info
must not continue showing new-contract-only facts from a previous vessel.

For new packets, associate by observing ship key and client session generation. Contacts
currently flush before Info, so allow that order when changing bridges; avoid
applying a previous vessel's contacts, text capture or delayed paint to the new
vessel. Define and test legacy untagged ordering without requiring the new field.
Do not deduplicate contact rows by displayed ID: several docked contacts can be
`**`. Use the supplied targeting flags, retain each row, and clear a local
selection if its identity becomes ambiguous after a replacement snapshot.

Keep a separate display target from the contact used by automation. New explicit
`bridge.target` can identify an unseen lock; automation must still require a
current matching contact with a known bearing. With the old contract, retain
the existing empty-contacts lock clearing. Explicit target null retires the
new display target. UI selection is never a server target lock.

Retain text fallback for older servers. Fix its parsing against real server
examples: IDs need not be `\w+` (`**` is valid); the contact suffix contains two
arc letters followed by optional F/S/D/A status. S means **sinking**, not a
confirmed sunk vessel. Existing synthetic `|NE` examples do not validate this
grammar. Verify actual ANSI allegiance/lock colors instead of inheriting the
current two-color guesses. Preserve legacy `sunk` payload support separately.

Render from accepted state; build widgets once and update changed values. Reuse
ArjUI's owned deferred callbacks, with at most one pending ship paint. Gate paint
on UI visibility, active SHIP and `panelIsVisible("character")`, including inside
the deferred callback. Hidden panels keep accepting data, then paint once on
reveal. Preserve section/slot selection and scroll anchors through updates and
layout changes; contact reordering must not move the reader to the top.
Mount a ship-root container in `tabPanels.ship`, and retain `shipBox` /
`ArjUI_ShipBox` as the Details console so existing consumers and text assertions
have a stable destination. Parent show must reconcile the chosen mode rather
than exposing both child views.

On `Ship.Info {}`, bridge departure, disconnect, account-menu return, new
character, reinstall and teardown, clear live ship facts, target/selection,
captures and pending work through existing lifecycle owners. Do not persist a
ship snapshot. Register and dispose every new widget/callback/timer through the
existing ownership path. A missing artwork file must not break text rendering.

Never mark data stale solely because a packet has not arrived recently: delivery
is change-suppressed. A local diagnostic may say when a value last changed, but
must not present that as a server heartbeat. Explicit disconnect/departure clears
the display; no invented polling or stale-time threshold is needed.

Escape server strings separately for MiniConsole color markup and label rich
text. Names containing `<`, `&`, quotes or Duris color codes must display as
text and cannot become markup or executable callback content.

## Delivery sequence

1. **Lock the parity contract.** Turn the preservation rows into concrete
   fixtures, using GallTest as the historical reference and new fixtures for
   cases it did not cover. Record the exact server/client baselines. Select
   final field names before implementing either side. Exit: every fact has an
   owner, destination and assertion, with missing-data behavior specified.
2. **Extend the server and qualify the protocol.** Add the optional facts above
   through production helpers; test status boundaries, negative stamina,
   contraband and bridge changes. Extend the existing GMCP harness without
   replacing display-helper behavior with duplicate test formulas. Verify old
   clients still consume the original contract. Exit: executable server contract
   proof and refreshed client wire fixtures.
3. **Deliver complete Details parity first.** Normalize new and old packets,
   add missing bridge rows, preserve the existing renderer/automation contract,
   and correct text fallback. Exit: field-by-field parity and lifecycle tests
   pass in real Mudlet before decorative work begins.
4. **Build the Captain's Table.** Add the hull, helm, arc manifest, crew/hold and
   bearing glass with the responsive layouts above. Wire local inspectors and
   explicit reference commands. Exit: narrow and expanded layouts are readable,
   every detail is reachable, and rendering never sends gameplay commands.
5. **Integrate and qualify the actual package.** Update DESIGN, user help and
   fixture provenance; rebuild and inspect the packaged result. Complete the
   same-ship live comparison and compatibility checks below. Exit: evidence
   identifies the exact delivered source and archive.

These are implementation slices, not delivery-time commitments. A server contract
change can be reviewed independently; the full redesign remains unfinished until
all slices and parity acceptance pass. Cosmetic polish may be reduced if it harms
readability, but no information-preservation requirement may be removed.

Expected files: client `src/scripts/ArjUI.lua`, optional bundled art under
`src/assets/`, affected Mudlet fixtures, `docs/DESIGN.md`, README/help,
VERSION/CHANGELOG and rebuilt package. Server work belongs in `src/core/json_utils.c`,
`src/net/gmcp.c` and focused ship/helper tests as needed. Keep existing ship
mechanics unchanged. The current planning-only change needs no package rebuild
or version bump. Future runtime work follows [RELEASING.md](../RELEASING.md),
normally a minor bump if installation/settings remain compatible; choose the
actual version at implementation time. Master CI owns release tags.

## Validation and definition of done

- **Protocol and semantics:** cover all 16 occupied slots, category interleaving,
  every condition arc, threshold boundaries, zero/missing maxima, empty ammo,
  damage 0/1/20/21/99/100/101, timer zero/positive/paused, equipment damage,
  fatigue above/at/below zero and the negative maximum boundary, empty chiefs,
  signed modifiers, contraband naming and nonzero invoice values. Confirm hull
  weight, load and cargo capacity remain distinct.
- **Transitions:** dock/undock, anchor, no contacts, unknown allegiance, flying
  contacts, mutual targeting, target outside contact range, explicit target
  clear, direct bridge-to-bridge change (including two `**` vessels), departure,
  reconnect and new character. Preserve multiple contacts sharing `**`.
  Exercise Info/Contacts ordering, replacement by partial payloads and late
  fallback text. Re-run existing ArjAuto relative-heading behavior and skill
  notices. Unchanged packets must not require a heartbeat.
- **Visual fidelity:** at 1280×720, 1366×768, 1920×1080 and relevant logical DPI
  scales, inspect default/minimum/resized/maximized Character frames, both header
  modes, long names, full slot/contact lists and missing artwork. Inspect all
  section scroll positions, both display modes and the Mudlet Errors window.
  Verify labels/numbers without relying on colors or hover. Clicking a marker
  must inspect locally; command buttons must send only their labeled command.
- **Existing panel behavior:** cover hidden/minimized Character, another panel
  maximized, deferred updates while covered, restore, reset layout, `ui off/on`,
  reinstall and teardown. No resurrected widgets, scroll jumps, altered saved
  normal rectangles, duplicate callbacks or command-input focus loss.
- **Bounded rendering:** retain widget identities across repeated updates; a
  long fixture run must not accumulate timers/widgets or increasingly delay the
  command line. A burst of Info/Contacts should coalesce into one paint, with no
  recurring paint or network timer while unchanged/hidden.
- **Build and runtime:** server C/C++ changes require `make -C src` and focused
  `python3 tests/async/test_gui_gmcp_contract.py` plus real-helper parity coverage.
  Refresh client fixtures with `python3 scripts/capture_server_gmcp.py --server
  /home/aiwithapex/projects/duris`. Client `python3 build.py --check` is syntax only;
  rebuild with `python3 build.py`, run focused connections/server-wire/layout/
  lifecycle scenarios while iterating, then `python3 scripts/mudlet_suite.py` for
  the final package. Inspect screenshots rather than equating assertions with
  visual acceptance. Record hashes and remaining limitations once per candidate.
- **Live comparison:** in a separate profile without test injections, capture
  `look ship`, `look crew`, `look contacts`, decoded packets, Bridge and Details
  for the same vessel/state. Require the GallTest-style weight/load/order rows,
  all damage arcs, slots, target and stamina semantics to agree. Exercise moving
  orders, damaged/reloading equipment and fatigue on an authorized local/staging
  ship where production would require gameplay changes. Record which cases are
  live, staging, fixture-only or unverified; historical evidence cannot qualify
  the new archive.
- **Compatibility:** qualify actual Mudlet 4.19.1 separately; the 5.0+ controller
  cannot certify it. Check 4.22/Qt6 and current 5.x, with native Windows/macOS and
  physical DPI/input checks recorded explicitly. Verify old server/new client and
  new server/old client combinations. Reuse existing legacy clear-state tests.

Completion means the visual hull preserves the meaning of the original ASCII
diagram, every current SHIP fact remains available, every `look ship` fact has a
faithful destination, and the final built package has fresh parity and visual
evidence. A beautiful diagram backed by the old incomplete contract is not done.
