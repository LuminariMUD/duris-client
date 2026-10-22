# Issue #3: readable SHIP panel

Status: implementation and scoped qualification complete; PR #9 -> #11 -> #10
are ready for review. Issue #3 remains open pending review/merge.

Date: 2026-10-22. Work item: [issue #3](https://github.com/LuminariMUD/duris-client/issues/3).
Parent: [feedback index #1](https://github.com/LuminariMUD/duris-client/issues/1).
Implementation branch: `branch/issue-3-ship-readability`.

Client baseline: refreshed to `72efad6` on `origin/master`, package `1.3.6`;
merged without rewriting the published planning commit. Candidate is `1.3.7`.
Historical source references below describe `7247c9d` (package `1.3.5`). Recheck the
affected paths against master before implementation, particularly if other
feedback work has merged.

## Outcome

Replace the SHIP panel's generic field dump with an ordered, readable view of
the ship's identity, navigation, condition, weapons, crew, equipment, cargo and
contacts. Use `look ship` as the information hierarchy and visual reference;
adapt it to the existing narrow panel. Keep useful information available through
scrolling, with clear labels, recognizable weapon entries and condition colors.
Verify the built package in real Mudlet and manually compare it with `look ship`
for the same ship.

## Current handoff (2026-10-22)

- **All implementation and scoped qualification complete; ready for review.**
  Merge order is [PR #9](https://github.com/LuminariMUD/duris-client/pull/9)
  (SHIP), [PR #11](https://github.com/LuminariMUD/duris-client/pull/11)
  (controller readiness), then [PR #10](https://github.com/LuminariMUD/duris-client/pull/10)
  (qualification evidence). Retarget each successor after its parent merges.
  Core head `26663f2`; controller head `d33a4e6`; evidence branch is
  `branch/issue-3-ship-evidence` in `/home/aiwithapex/projects/durisclient-issue3-plan`.
- Master `eec642f` was merged without rewriting published commits. Its final
  change was `.env.example` only. Final version **1.3.7**, archive SHA-256
  `75f78b1b67df13425b6ba4da090b44d3b24229638177e75000ee5b944e97cbd3`.
  No tags were pushed; release publication stays with master CI after review.
- Ablation reused the existing panel, handlers, state, color helpers and
  fixtures. The generic info walk was replaced by local ship-specific sections.
  Numeric slots, separate ammo/damage/timer facts, honest units, zero/false,
  missing maxima, contacts/automation, text fallback and clearing are preserved.
  Only the SHIP scrollbar and coalesced scroll restoration were added locally.
- PR review reproduced an omitted display assertion: `Ship.Info {}` followed
  by `Ship.Contacts {contacts=[]}` used to show Contacts: None after departure.
  The footer now requires other displayed ship facts. The added assertion failed
  before this guard, then passed; `server-wire` also checks the authoritative
  sequence. The text-only fixture resets its session after the GMCP case.
  Review thread is resolved. See [review-followup.json](../testing/issue-3/review-followup.json).
- A later review caught cached Info heading/speed masking fresh Contacts.
  The added zero-navigation assertion failed before the two-line precedence
  repair and now passes. The primary manifest identifies the current source,
  archive and fresh run; historical size/DPI evidence is explicitly separate.
- A separate controller defect reproduced several Errors-editor capture
  failures after successful behavior. PR #11 uses the existing bounded wait
  helper (five seconds and application-exit detection), replacing a fixed
  0.3-second delay. Eight controller checks and the final **20/20** suite pass
  at `/tmp/duris-issue3-navigation-suite`, including wire, lifecycle/reopen,
  ordinary captures and expected negative/fault outcomes.
- Original four-size/DPI populated coverage remains valid: review changed
  the empty footer and optional cached-navigation precedence, leaving that
  fixture's populated formatting/geometry intact. The final archive passed
  Mudlet 5.0.1, Mudlet **4.22.0 / Qt 6.9.0** (**115** assertions), and
  in a fresh live profile. Exact payload/source identities and coverage reuse
  are recorded in [offline-evidence.json](../testing/issue-3/offline-evidence.json)
  and the review follow-up. Reviewed departure/Errors captures show no Lua errors.
- **Manual same-ship comparison PASS for the final archive.** Actual GallTest
  bridge packets and `look ship`/`look crew` agree on identity/status/ID/frags,
  navigation, four armor/hull arcs, sail, passengers, repair, stamina,
  crew/chiefs/skills/modifiers, all six weapon entries and silk cargo.
  [qualification.json](../testing/issue-3/qualification.json) includes decoded
  packets, text, inspected screenshots, hashes and exact import provenance.
- Weight/load, set orders and exact reload timers/equipment damage are not in
  the received contract. Cargo **5/70 crates** is distinct from **80/165 weight
  load**. Live equipment/contacts were empty; their populated, damaged and
  no-ammo cases remain offline coverage. No missing values were inferred.
- Final live profile had no companion, send override or injected GMCP.
  Real bridge departure cleared info/maxSpeed/target **and the display**.
  Veridian returned to the original Inn of Oceans (66899), quit and disconnected
  normally. Owned desktops are closed and temporary credential copies removed.
  User `.env` remains ignored in the master checkout. No ship/gameplay settings
  or server sources were changed.
- Runtime: Ubuntu 24.04.4 WSL2, Xvfb 96dpi, DejaVu Sans Mono. Raw final runs:
  `/tmp/duris-issue3-navigation-suite`, `/tmp/duris-issue3-navigation-4.22`,
  `/tmp/duris-issue3-nav-clean`; earlier evidence remains under the other
  `/tmp/duris-issue3-*` directories. Use a login shell for `~/.local/bin/mudlet`.
  Committed evidence remains useful if those temporary directories disappear.
- Lua 5.1 syntax, source/archive release validation and `git diff --check`
  pass. This evidence-only update reuses final runtime results; no further
  regression run is needed for prose, PNG or JSON changes.
- Published reference text removes trailing line padding so the complete PR
  diff passes its whitespace check; original capture hashes are preserved.
- All three original acceptance items have evidence. Keep #3 open for PR
  review. Declared **4.19.1** (official release has no binary assets), physical
  desktop DPI and Windows/macOS remain unverified; do not claim them. Hosted
  checks remain separate from the completed local proof.
- Next session: address new review feedback, then integrate the above stack
  in order. No scoped implementation work remains. Preserve the source/package
  pairing and let the existing master workflow create the eventual tag/release.

The original audit/specification below remains the source and comparison
reference. Historical setup/progress statements are superseded by this handoff
and the testing log.

All three issue acceptance items remain required:

1. A structured display replaces raw ship fields, including nested weapons.
2. A manual same-ship comparison checks statistics and weapons, with protocol
   differences recorded explicitly.
3. The rebuilt `.mpackage` is imported and inspected in Mudlet.

## Non-goals

- Changes for map colors (#2), header height (#4), or resizable/dockable panels
  (#5). The parent issue is an index, not authority to include its siblings.
- A radar, interactive ship controls, new tabs/settings, a full client redesign,
  a general GMCP rendering framework, or external Lua dependencies.
- Reproducing the wide ASCII ship illustration pixel for pixel. Named,
  color-coded condition rows can convey its useful information in this panel.
- Changing the server protocol or gameplay, inferring missing values, or
  claiming that reported data is incorrect. Preserve the existing text fallback,
  tab command, state lifecycle and automation contracts.

## Evidence and assertions checked

### What the client actually does

- [`ArjUI.lua`](../../src/scripts/ArjUI.lua), `renderShip()` at lines 3674-3783,
  emits a name/navigation preamble, then alphabetically iterates arbitrary
  `Ship.Info` keys. Nested weapons, equipment and cargo become long
  `field=value` strings. This directly explains the presentation problem;
  no new data-acquisition subsystem is needed.
- The same function already supports armor/internal `[current,max]` pairs,
  nested ship items, contact sorting, allegiance colors and target marks. The
  task is to organize existing data, not add basic ship support.
- `buildTabs()` at lines 692-695 creates a `Geyser.MiniConsole` with 9-point
  text inside the percentage-based tab container. `makeConsole()` at lines
  205-214 enables wrapping. The right column is 26% of the root and character
  tabs occupy its upper 45%; see [DESIGN.md](../DESIGN.md). A copy of the wide
  game display would wrap badly here.
- `onShipInfo()` and `onShipContacts()` at lines 3624-3650 already separate
  slow-changing details from heading/speed and contacts. Empty `Ship.Info`
  resets ship state; empty GMCP contacts retire previous contacts and locks.
  `setupShipText()` at lines 3579-3621 supplies a smaller text-only fallback.
- `requestTabData()` at lines 3244-3256 sends `look contacts` for SHIP.
  [`ArjAuto.lua`](../../src/scripts/ArjAuto.lua), `shipState()` and
  `targetContact()` at lines 464-476, consumes the same state. `maxSpeed`,
  contact bearings and target IDs must keep their current meaning.

### What the report establishes, and what it does not

Both attachments in [issue #3](https://github.com/LuminariMUD/duris-client/issues/3)
were visually inspected. `client-03.png` shows raw labels such as `chiefs`,
`skillMods` and a flattened weapons list in the SHIP tab. `client-02.png` shows
`look ship` with an identity/status header, a colored condition diagram and
separate weapon rows. These agree with the source's presentation paths.

The screenshots report Mudlet 4.22.0/client 1.3.5; they are historical evidence,
not a new reproduction. They also contain changing state, including different
heading/boarding information. They do not establish a serialization defect or
prove that every pictured value should be identical between captures.

### Server contract and reference display

The sibling server checkout was inspected read-only at clean revision
`ca548bae11cab98490fd5e4e954785630b3a07da`. This is local source evidence,
not proof of the currently deployed server. Relevant pinned sources:

- [`json_build_ship_info()`](https://github.com/LuminariMUD/Duris/blob/ca548bae11cab98490fd5e4e954785630b3a07da/src/core/json_utils.c#L1274)
  sends identity, status, maximum speed, contact range, sail, crew/stamina,
  chiefs, skills/modifiers, passengers, four armor/internal arcs, weapons,
  equipment and cargo. Weapon fields are `slot`, `name`, `position`, `ammo`,
  `maxAmmo`, `damage` and boolean `ready`.
- [`look_ship()`](https://github.com/LuminariMUD/Duris/blob/ca548bae11cab98490fd5e4e954785630b3a07da/src/ships/ship_control.c#L1676)
  supplies the reference hierarchy. Its hull weight, slot-weight load/capacity,
  set heading and set speed are not in the inspected `Ship.Info` payload.
  Cargo crate capacity is a different quantity from the displayed weight load;
  do not relabel one as the other. Current heading/speed come from
  `Ship.Contacts` in the client.
- [`generate_slot()`](https://github.com/LuminariMUD/Duris/blob/ca548bae11cab98490fd5e4e954785630b3a07da/src/ships/ship_control.c#L1614)
  and [`ShipSlot::get_status_str()`](https://github.com/LuminariMUD/Duris/blob/ca548bae11cab98490fd5e4e954785630b3a07da/src/ships/ship_utils.c#L1339)
  distinguish damage, ammunition and timers. GMCP `ready` only means the timer
  is zero; it does not certify a usable gun. The exact reload countdown and
  equipment damage are not supplied. Show only the supported facts.
- [`look_crew()`](https://github.com/LuminariMUD/Duris/blob/ca548bae11cab98490fd5e4e954785630b3a07da/src/ships/ship_control.c#L1247)
  shows integer Deck/Guns/Repair skills and separate signed modifiers. Preserve
  that meaning; do not turn the skill numbers into invented percentages.
- [`gmcp_player_ship()`](https://github.com/LuminariMUD/Duris/blob/ca548bae11cab98490fd5e4e954785630b3a07da/src/net/gmcp.c#L453)
  subscribes bridge observers and clears ship packages on departure. Being
  somewhere aboard a ship does not guarantee full bridge data.

The checked-in [serializer fixture](../../tests/mudlet/fixtures/server-gmcp.json)
has older provenance, revision `d27e2b5...`, and empty weapons/equipment arrays.
It does not include `crewType`, which the inspected newer serializer supplies.
The [connections fixture](../../tests/mudlet/fixtures/connections.lua) supplies
nonempty weapons/equipment and cargo, but is a constructed scenario. Keep these
evidence types distinct; a current source read does not silently refresh fixture
provenance or prove the live contract.

### Validation available during planning

The repository and issue were inspected; no gameplay or runtime result is
claimed. `python3 scripts/mudlet_test.py doctor` currently reports
`FAIL: Missing prerequisites: mudlet` in this WSL environment. Prepare the
documented runtime before implementation qualification. Existing testing logs
describe previous machines/runs and do not establish current availability.

## Ablation decisions

- **Keep:** explicit ship-specific formatting. Removing it leaves the reported
  generic field dump unchanged.
- **Simplify:** reuse `shipBox`, `renderShip()`, existing color stripping,
  numeric conversion, state and GMCP handlers. Use a small number of local
  formatting helpers only where repeated ship sections need them.
- **Keep:** useful nested condition/item data, navigation, contacts, text-only
  fallback and clearing behavior. Simplifying the display by hiding these
  would lose current player information or break traced automation consumers.
- **Simplify:** use a compact condition table and vertically stacked weapon
  entries. This preserves the reference's grouping without a wide diagram,
  a second renderer or a new resize/breakpoint system.
- **Drop:** the generic `Ship.Info` key walk, arbitrary nested-table flattening,
  and duplicate summary fields once the explicit view replaces them. Do not
  retain a second raw-dump mode or expose unknown fields automatically.
- **Drop:** a server change solely to match missing reference fields, hard-coded
  ship class catalogs, additional polling, and a parser for all of `look ship`.
  The required presentation can use the already available information.
- **Investigate narrowly:** compare actual live packets and rendering for one
  ship. Resolve discrepancies through the producing source before changing a
  value or label. A demonstrated missing fact essential to acceptance would
  require an updated plan; speculative protocol expansion does not.
- **Keep:** real Mudlet import, visual review and same-ship comparison, because
  text assertions and syntax checks cannot prove those acceptance items.

## Intended presentation

Use one narrow, scrollable text view in the existing dark-fantasy palette.
Arrange sections in the following order; use a heading per section and blank
lines between groups rather than a line per raw key.

1. **Identity and navigation:** ship name and ID, status, captain, frags;
   heading, current/max speed, contact range and locked target. Prefer current
   GMCP values, using existing text state only for absent values. Present each
   fact once. Zero heading/speed is valid; missing data is unknown, not zero.
2. **Condition:** rows ordered Bow/Forward, Port, Starboard, Stern/Rear, with
   separate Armor and Hull current/max values; sail current/max nearby. Use
   readable numbers plus muted/red/amber/green condition accents, retaining
   labels so meaning does not depend on color. Missing or zero maxima stay
   neutral and never cause division by zero or a false healthy percentage.
3. **Weapons:** stable numeric slot order, one named entry per weapon. Put
   slot/name on its own line and labeled position, ammo current/max, damage and
   timer readiness underneath. Bow maps to Forward and stern to Rear to match
   `look ship`; preserve other supplied positions. Use explicit Ready/Not ready
   for the timer, with damage and empty ammunition visibly separate so a timer
   flag cannot disguise an unusable weapon. Do not invent a reload countdown
   or treat the damage level as a percentage. Preserve `false` and zero values.
4. **Crew and supplies:** crew type when supplied; stamina current/max,
   passengers current/max, repair stock, chiefs and Deck/Guns/Repair skills
   with separately labeled signed modifiers. Missing chiefs show None only
   for a known empty value; absent fields stay unknown or are omitted.
5. **Equipment and cargo:** named equipment entries with slot and supplied
   timer readiness; cargo crates current/max and individual named cargo rows,
   crate counts, contraband markers and invoice price when supplied. Use
   honest labels for units. Numeric `class` has no required role here: omit it
   rather than inventing a class name; all operational information above stays.
6. **Contacts:** retain range ordering, target/allegiance/threat/sunk markers
   and existing navigation details. Keep the list distinct from own-ship
   condition and weapons. A small explicit empty-contact message can distinguish
   an empty list from unavailable data without reviving stale text contacts.

Known empty lists should be legible as empty; partial/older payloads should
remain useful without blank walls of placeholders or Lua errors. Sanitize all
incoming names with the existing helpers before writing colored text. Do not
mutate incoming tables or shared ship state while sorting/formatting.

Choose a layout that works at the smallest supported test geometry using
short labels and intentional line breaks. Long ship/weapon/cargo names wrap
without dropping names, ammunition or status. Keep existing percentage-based
geometry and font readability. Check that periodic updates leave lower sections
reachable through scrolling; make only a local scroll adjustment if the real
Mudlet review exposes a blocker introduced by this change.

## Implementation sequence and files

### 1. Establish the candidate and comparison inputs

Refresh master and recheck the affected source, issue comments and package
version. Run `doctor`; prepare Mudlet using [LINUX_DEVELOPMENT.md](../LINUX_DEVELOPMENT.md).
Capture the current `connections` SHIP checkpoint as the baseline when the
runtime is available. Arrange one bridge-accessible test ship for the manual
comparison; record server/Mudlet/package versions and payload provenance.

### 2. Replace the renderer's generic information block

Edit [`src/scripts/ArjUI.lua`](../../src/scripts/ArjUI.lua), principally
`renderShip()`. Add the ordered formatting described above and remove the
replaced generic path. Reuse existing state/fallback precedence; preserve
`maxSpeed`, contacts, target IDs and clearing behavior. Do not change
`ArjAuto.lua`, `ArjMapper.lua`, the XML skeleton or tab commands unless a
specific integration failure demonstrates that it is necessary.

### 3. Extend the existing real-Mudlet scenarios

- [`information.lua`](../../tests/mudlet/fixtures/information.lua): retain
  mouse-driven SHIP reachability and `look contacts` command proof. Add
  headings/field ordering and a representative multiweapon view.
- [`connections.lua`](../../tests/mudlet/fixtures/connections.lua): extend
  the populated payload with all four arcs, realistic crew/skills/modifiers,
  cargo and multiple slot-ordered weapons. Exercise damaged, no-ammo and
  `ready=false` cases, zero/missing maxima, partial payloads, long/color-coded
  names, empty lists, text-only fallback and populated-to-empty replacement.
  Assert readable output, supplied values and unchanged automation state.
  Add a later checkpoint to show stale weapons/cargo disappear after replacement.
- Keep [`server-wire.lua`](../../tests/mudlet/fixtures/server-wire.lua)
  exercising the checked-in real serializer snapshot and clears through Telnet.
  Adjust presentation assertions only if necessary; do not replace it with
  direct-event mocks or regenerate the JSON just to make screenshots richer.
- Reuse named steps/checkpoints, `T.emit`, `T.lines` and screenshots. No new
  test runner or scenario file is needed. Assertions should check observable
  values/ordering/clearing, not freeze every space or color code.

### 4. Package, document and qualify

Update [`docs/DESIGN.md`](../DESIGN.md) to describe the section hierarchy,
condition treatment and fallback boundary. Record exact results and outstanding
coverage in [mudlet-local-testing.md](mudlet-local-testing.md). Bump
[`VERSION`](../../VERSION) by PATCH for this visual change (provisionally
`1.3.6`; use the next patch if master advances), add the dated
[`CHANGELOG.md`](../../CHANGELOG.md) entry and rebuild
[`duris-client.mpackage`](../../duris-client.mpackage). Version injection is
owned by the builder; do not hand-edit version literals or the archive.

Expected implementation files are ArjUI, the two existing scenario fixtures,
DESIGN/testing log, VERSION, CHANGELOG and the rebuilt package. Modify the
fixture README only if provenance needs documenting; modify server-wire only
if its assertions require it. Each additional file needs a concrete reason.

## Proof and completion gates

During implementation, use focused checks first, then the repository-required
completion checks after the final build:

```bash
python3 scripts/mudlet_test.py doctor
python3 build.py --check
python3 build.py
python3 scripts/mudlet_test.py run --scenario information
python3 scripts/mudlet_test.py run --scenario connections --size 1280x720
python3 scripts/mudlet_test.py run --scenario connections --size 1366x768
python3 scripts/mudlet_test.py run --scenario connections --size 1920x1080
python3 scripts/mudlet_test.py run --scenario connections --scale 2 --size 2732x1536
python3 scripts/mudlet_suite.py
python3 scripts/release.py --output /tmp/duris-client-issue3-release
git diff --check
```

`build.py --check` is syntax only and can skip checking when no compiler is
found: require an actual Lua 5.1 compiler and inspect the output. The full suite
is the AGENTS.md runtime completion requirement; it also checks wire decoding,
lifecycle/reopen and deliberate harness failures. Its default run does not
replace the focused size/DPI matrix. Release validation checks XML and equality
with the committed package; none of these proves visual quality by itself.

Inspect actual populated, partial, empty and replacement SHIP screenshots,
candidate-only captures and the Errors view. Confirm readable text, no clipped
values, usable scrolling, preserved contacts and no Lua errors. Record visual
review for each relevant run with the existing `mudlet_test.py review` command.
Reuse unchanged passing evidence; rerun affected checks only after relevant
changes, except where the repository requires a final suite.

In a separate live profile, import the exact rebuilt package and go to the
bridge of the same ship used for the comparison. With no ship changes between
captures, issue `look ship`, capture the SHIP tab and record the received
`Ship.Info`/`Ship.Contacts`. Compare name/ID/captain/status/frags, speed range,
passengers, condition by arc, sail, crew/stamina/repair and every occupied weapon
slot/name/position/ammo against the corresponding received fields. Check that
readiness is represented honestly, allowing for a timer changing between
captures. Inspect cargo/equipment where present. Record protocol omissions
(weight, set orders, exact timers/equipment damage) separately from defects;
never fill them with derived guesses.

Repeat the import/visual smoke on the reported Mudlet 4.22.0, and separately
verify the declared 4.19.1 minimum before claiming that compatibility. The
automated controller needs 5.0+; follow the documented isolated/manual profile
workflow for 4.x. Record OS, window size and DPI. If a runtime, compatible binary
or accessible test ship is unavailable, leave that gate explicitly unverified
and keep the issue open. Offline fixtures cannot satisfy the manual acceptance.

The issue is complete only when all three acceptance items have evidence, the
required tests and reviewed screenshots pass, source and package agree, and
the design/testing records reflect the implemented behavior and actual limits.

## Estimate and delivery

Budget **8-12 active engineering hours**, approximately **1-2 focused working
days**, assuming a usable Mudlet installation and an accessible test ship:

- Renderer and section formatting: 3-4 hours.
- Existing-fixture extensions and focused regression work: 2-3 hours.
- Size/DPI review, same-ship and 4.x import checks: 2-4 hours.
- Documentation, version/build and final publication checks: about 1 hour.

Allow another **1-3 hours** for runtime/archived-version setup; Mudlet is
currently absent. Waiting for bridge access or a compatible test environment is
additional elapsed time. A demonstrated server-contract blocker would require
a revised estimate rather than silently broadening this client presentation task.

The planning commit remains in history. Publish the renderer, existing-fixture
proof, design notes and rebuilt 1.3.7 package as the first focused PR, then stack
the compatibility/live evidence chunk as it is ready. Leave PRs ready for review;
do not merge or close #3 before acceptance. Releases follow
[RELEASING.md](../RELEASING.md) through master CI; never push a tag manually.
