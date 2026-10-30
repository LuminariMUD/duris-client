# Protocol interfaces and low-cost telemetry investigation

Date: **2026-10-30**. Status: **investigation complete; implementation proposed**.

Tracking issue: [#26](https://github.com/LuminariMUD/duris-client/issues/26).
Work branch: [branch/protocol-interface-improvements](https://github.com/LuminariMUD/duris-client/tree/branch/protocol-interface-improvements).
The issue also tracks reproduction of the reported player/pet/opponent HP
display confusion; its cause and fix remain unconfirmed.

## Findings that drive the next work

The client already uses GMCP for most of its persistent dashboard. The largest
remaining captures, **INV, EQ and WHO, do not have working server protocol
equivalents yet**. `Char.Items` and `Char.Skills` are header declarations only;
advertising them from Mudlet would not make the server send data.

There are useful client-only improvements now: retire redundant ship-contact
polling when the stream is available, receive loot bids through `Comm.Channel`,
use affect changes for appropriate buff-loss alerts, and expose the existing
`Quest.Map` and quest availability fields. The tank bar still needs a server
addition: `Combat.Update` has a target but no tank.

The best small server additions are **game time/phase, tank state, explicit
session transitions, and inventory/equipment snapshots**. Action outcomes and
cooldowns would remove many more automation regexes, but require a separate,
careful contract for what happened and when another action is allowed.

No new telemetry is literally free. Aim for **no additional gameplay
calculation, blocking I/O, or periodic world traversal**, with small bounded
serialization at events the engine already processes. The cost assessments
below are source-based estimates, not benchmark results.

## Scope and reproducibility

Inspected the clean local checkouts, including serializers, send sites, command
handlers and flush scheduling:

- Client **2.4.1**, `09924db4f2c9a5ffe47c44ebbed7977cc432eecb`, at
  `/home/aiwithapex/projects/durisclient`.
- Server `c9361959ceb6cb2a9004fea2c03748cef909dc3f`, at
  `/home/aiwithapex/projects/duris` (`../duris/`).
- Client sources of truth: `src/scripts/ArjUI.lua`, `ArjAuto.lua`,
  `ArjMapper.lua`; package skeleton; existing fixture provenance and design docs.

This is a current source audit, not a live-server observation or a performance
measurement. Older findings in [updates-upgrades.md](updates-upgrades.md) and
[mudlet-local-testing.md](mudlet-local-testing.md) provide context; the current
owning source determines the findings here. No runtime code, package archive,
version, server configuration or player data was changed for this investigation.

Source references `[C1]`–`[S15]` below resolve to the inspected revisions in the
[source index](#source-index). Proposed message names and JSON shapes are design
suggestions, not implemented server APIs.

## 1. What already works through protocol

The client advertises and consumes **11 gameplay packages**. The server also
emits `Quest.Map`, opt-in `Char.Input`, and the service-specific
`Core.AuthChallenge`; these are not in that client list. [C1, S1]

| Interface | Current data source | Finding |
| --- | --- | --- |
| HP, mana, moves, posture, fighting, XP/TNL, carried coins | `Char.Vitals` | Already protocol. XP gain is calculated locally from successive values. |
| Character name, level, class, race, guild, title | `Char.Status` | Already protocol; self only. It is not a feed of other players' identities. |
| Room title/area, exits, doors, visible mobs/items/players | `Room.Info` | Already protocol. Current payload includes player command selectors and NPC fighting information. |
| Group roster, HP/moves, position, rank, presence | `Group.Status` | Already protocol. Auto-heal targeting and group spell aliases also use this state. |
| Enemy target, HP percentage/condition, position | `Combat.Update.target` | Already protocol, but a text combat-prompt trigger also writes these fields. |
| Outgoing damage counter | `Combat.Update.round` | Preferred source already; `[Damage: N]` is fallback. Event coverage has limits described below. |
| Buff/debuff list | `Char.Affects` | Already protocol. Buff/debuff classification still guesses from names. |
| Chat tabs and private tells | `Comm.Channel` | Already protocol, including outgoing tells. Some automation still separately parses rendered chat. |
| Bartender quest progress | `Quest.Status` | Already protocol. Availability/replacement fields are currently unused. |
| Captain's Table, own vessel, cargo/crew/slots, contacts | `Ship.Info`, `Ship.Contacts` | Already protocol. Most ship text triggers are fallback, rather than the panel's primary source. |
| Wilderness/ocean map | `Room.Map.map` | Protocol carries a colored map string. Parsing that string is presentation decoding, not scraping the main console. |
| Full zone layout | HTTPS zone-map JSON API plus `Room.Info` | Already structured data. The graph comes from the website API and is cached by zone; live room/door state comes from GMCP. |

The structured zone API should stay outside the game loop. Moving full zone
graph generation/download into the server would add work without removing a
text dependency. Likewise, `Room.Map` already reuses the generated map buffer;
a structured tile grid would be a new representation, not a prerequisite for
eliminating console scraping. [C3, S2]

GMCP fits the existing transport and Lua event model. Mudlet documents
`gmcp.<package>` events and `sendGMCP()`; protocol support does not imply a
particular game implements every named module.
[Mudlet protocol documentation](https://wiki.mudlet.org/w/Manual:Supported_Protocols#GMCP).

## 2. Remaining text interfaces and what can replace them

### Persistent panels and state

| Interface and client location | Text dependency today | Available replacement and remaining work |
| --- | --- | --- |
| INV — `setupCaptureTriggers`, `renderInventory` [C2] | Header `You are carrying:`, then arbitrary lines until prompt/GA. Updated by `inv`. | **Server work required.** `Room.Info.items` is ground contents, not carried inventory. Add owner inventory snapshots; `Char.Items` has no serializer/send handler. |
| EQ — same capture system [C2] | `You are using:`, slot lines and empty-equipment sentence. Updated by `eq`. | **Server work required.** Publish worn slots/items and explicit empty state. Existing ship equipment is unrelated to character equipment. |
| WHO — same capture system [C2] | `Listing of the Gods`, bracketed rows, headings/counts, prompt boundary. | **Server work required.** A requested, viewer-filtered WHO snapshot can replace capture. `Room.Info.players` and `Group.Status` have narrower scopes; no current GMCP WHO list exists. |
| STATS — `requestTabData`, `renderStats` [C2] | Clicking sends `score`, but the panel itself renders GMCP state; it does not parse a full score sheet. | **Client-only cleanup for today's panel.** Stop treating `score` as its data refresh. If a richer score panel is wanted, additional fields need a server packet; current identity/vitals are not the whole score command. |
| Clock — login query, `setup` time triggers [C1] | Silent `time` query and four-line gagging, plus nine phase-announcement forms. | **Server work required.** A time/phase snapshot eliminates query ownership, matching and gagging. Current `timestamp` is chat wall time, not game time. |
| Target bar — combat prompt, death/flee triggers [C1] | Prompt health words overwrite GMCP's exact percentage with estimates; any matching death sentence clears the target. | **Mostly available.** Prefer existing target/null packets on supported servers; isolate legacy fallback. Verify target freshness when allies deal damage or positions change before removing all fallback. |
| Tank bar and assist state [C1] | `T:/TP:/TC:` combat prompt; assist/stop-assist sentences. | **Partial only.** Group HP exists, but membership is not the identity of the enemy's current opponent. Add `Combat.Update.tank`; use group HP after authoritative tank selection. |
| Character entry, account-menu return [C1, C4] | UI uses `Char.Status` for entry with prompt fallback, but account-menu reset and ArjAuto login commands still match text. | **Partial now; explicit session packet preferred.** Use a guarded character-entry event for automation. A new server state/generation packet is needed for same-socket exits and unambiguous new sessions. |
| Ship fallback, alerts and polling [C5, C7] | Contact columns and ANSI colors; board/depart/dock/lock text; crew skill-gain notices; `look contacts` timer. | **Most values already available.** Use snapshots/empty clears and diff skills, people and target state. Keep fallback for older/no-stream sessions. Bridge-only subscription does not mean every vessel room receives ship state. |

Two related cleanup findings matter when doing these conversions:

- `switchTab()` tests `statsRaw`, `invRaw` and `eqRaw`, but no source assigns
  those fields. Actual inventory/equipment use `state.inventory/equipment`.
  Switching tabs therefore keeps requesting commands even after data has been
  captured. Test received state explicitly, including a known empty list.
  WHO has no `hasData` case either. [C2]
- The UI assist trigger expects `You are now assisting ...`, whereas ordinary
  `do_assist_core()` emits `You assist $N heroically.` This path does not establish
  a persistent assist relationship. An authoritative tank should come from the
  combat relationship, not a remembered command or that sentence. [C1, S7]

`Combat.Update.round` also has narrower semantics than a full combat log. The
applied-damage call site currently supplies `damageType:"unknown"` and
`critical:false`; when damaging someone other than the attacker's existing
opponent, it refreshes the existing target instead of publishing that damage
round. It does not provide a complete feed of misses, attacks on allies, or
all secondary-target damage. Rich damage breakdowns would need real outcome
metadata from existing combat calculations, with no extra damage calculation
or random roll. Keep this limitation visible when judging counter coverage.
[S7]

### Automation, alerts and one-off results

| Feature and location | Protocol opportunity | Boundary that remains |
| --- | --- | --- |
| Loot-split bids — `setupSplitTriggers` [C6] | **Client-only:** consume `Comm.Channel` with `channel == "gsay"` and message `bid`; the server already emits group chat. | Preserve member validation, duplicate handling and collection state. Do not process both GMCP and text for one bid. |
| Dice results for loot split [C6] | **New event:** publish the already-generated `do_dice()` results, roller, sides, index/count and roll identifier. | Existing `Comm.Channel` does not carry dice results. Preserve ordering, ownership, bounds checks and rejection sampling. [S9] |
| Buff-loss alerts and auto-rage [C4, C5] | **Partial client-only:** compare previous/current `Char.Affects` IDs to detect disappearance of visible effects. | A missing effect means loss, not necessarily natural expiration; dispel/death/session reset differ. Hidden cooldown tags are excluded. An action/affect reason field helps preserve semantics. [S4] |
| Auto-stand, studies/prayers/infusion completion [C4] | Existing vitals posture covers part of knockdown; new activity/outcome data can cover completion and cancellation. | Position alone cannot distinguish resting, intentionally sitting or memorizing. Do not issue stand on every non-standing packet. Ensure all relevant position transitions publish. |
| Auto-wield/disarm [C4, C5] | New equipment changes plus a disarm/drop outcome replace weapon-loss sentences. | An empty hand could be voluntary; equipment state alone is not the reason. |
| Rebash and rescue retry timing [C4] | New cooldown/action state replaces the fixed 13.99-second bash timer and inferred rescue unlocks. | `Char.Input` only means a command was dequeued. It does not mean success, action completion or readiness. Hidden bash cooldowns are not in `Char.Affects`. [S4, S7, S8] |
| Auto-rescue/auto-assist observing others [C4] | New small combat-relation/outcome events, or suitable additions to group state, can replace attack/miss sentences. | Current `Combat.Update` is not a room-wide feed of attacks on allies. NPC `Room.Info.npcs[].fighting` is useful state, but misses PC attackers, misses and precise event timing. |
| Flee-stab direction, failed flee, arrivals/traps [C4] | New movement/action outcome with visible direction/reason, and filtered arrival events. | `target:null` does not say why combat ended. A room snapshot diff does not prove arrival cause or movement direction, especially in wilderness. |
| Scan formatter/reporter [C5] | New requested scan-result array with direction and distance from the successful scan pass. | No current protocol equivalent. Preserve its random detection, blindness/terrain/visibility rules; do not run another scan or make it an automatic radar. [S10] |
| Identify compactor [C6] | New authorized identify-result packet can carry already-revealed item fields. | Inventory metadata must not reveal identify-only properties. Publish after the spell/service succeeds; do not run identification again for telemetry. [S11] |
| Epic-zone completion tracker [C6] | New requested/cached structured report and optional allowed completion changes. | Preserve the configurable completion disclosure delay (default 15 minutes) and displayed alignment. Current Redis/text report is not an automatic JSON source. [S12] |
| Character-creation roller [C6] | New Telnet GMCP chargen packet using the same rolled values and permitted feedback. | JSON builder functions exist, but source search finds no callers for `json_build_stat_roll`/`json_build_chargen_complete`; they are not a usable Mudlet stream. Do not expose more precision than chargen policy intends. [S13] |
| Consent/follow/group notices; songs, mining, skill-ups, tracks, frost beacon, scrying, spell-hit reports [C4–C7] | Small semantic events at existing success/failure/notification sites would replace these regex families. | Group membership is not consent; disappearance of an affect is not song completion; room contents are not a mining success event. Send only information already delivered to that recipient. |

The main-console route-all trigger copies game output into the UI console. It
is display plumbing, not extraction of structured state, and can remain.
Movement, attacks, orders and other user actions can also continue as ordinary
commands. Adding telemetry does not require adding a second action API.

## 3. Existing data we can use more fully without new gameplay work

1. **Ship stream instead of contacts polling.** While a GMCP character is on a
   loaded vessel's bridge, the server checks contacts/info every two pulses,
   approximately 500 ms. It suppresses unchanged sends using descriptor hashes.
   `ship poll on` nevertheless sends `look contacts` every two seconds by
   default. Receiving the stream can suspend that optional timer, saving about
   **30 commands per minute per continuously polling client**. This arithmetic
   is not a measured CPU saving; the timer is opt-in. Gate on session capability
   or receipt, rather than interpreting an unchanged stream's silence as failure.
   [C7, S5]
2. **Ship skill/passenger/lock notices from snapshots.** `Ship.Info` already has
   `skills`, `people/maxPeople`, `bridge.target`, desired heading/speed, hull
   weight/load, crew stamina display/band and detailed slot timers/status.
   Diff these for notices, initializing a baseline on vessel/session change.
   Do not add duplicate fields based on the older study's missing-field list.
   Weapon `ready` means timer-ready, not that ammo/damage/arc permits firing.
   [C5, S6]
3. **Keep ship `look out` and targeted `scan` distinct.** `lout on` requests a
   map plus `new_look()` output every 1.8 seconds; `shipf` requests target scans
   every five seconds. `Room.Map` already covers map display, but a contact
   list does not contain the enemy armor/internal details from `scan_target()`.
   Disable lookout polling only where its map-only purpose is satisfied; the
   target scan needs an equivalent authorized result before replacement.
   [C7, S10]
4. **Quest map and availability.** Receive `Quest.Map {map, zoneNumber}` and
   render it in a separate quest view; do not overwrite the current-room map.
   Honor `{map:"",zoneNumber:0}` clears. Use `Quest.Status.availability` and
   `replacementDue` to explain unavailable/blocked/replacement states instead
   of displaying only active quests. The server already sends these fields;
   map generation is synchronous and should not become a refresh poll. [C1, S2]
5. **Chat presentation and timestamps.** Say/tell/guild packets can include
   `presentation {version, text, runs, policy, ...}` with recipient-specific
   color runs. The UI currently strips message colors, applies its own channel
   format, and timestamps receipt using the local clock. It could optionally
   use the server timestamp and validated presentation data. This improves
   fidelity using data already serialized, without scraping ANSI output.
   Other channels still need the ordinary field fallback. [C8, S3]
6. **Opt-in command receipts.** `Core.Hello` accepts `commandReceipts:true`;
   `Char.Input` sends `sequence` and a command label when playing input is
   dequeued, before execution. The client currently does not request/consume it.
   Useful for queue/latency feedback, but neither success confirmation nor an
   end-of-response marker. It adds one event per processed command when enabled,
   so enable only for an actual feature. [S8]
7. **Use existing selectors and door metadata.** Prefer server player `target`
   selectors and NPC keyword/targeting information over reconstructing names.
   `Room.Info.doors` already gives closed/locked state; the mapper uses it.
   A template `vnum` is not a unique item or creature instance identifier.
   Selectors must still be revalidated by normal command handlers. [C3, S13]
8. **Local affect countdowns.** `Char.Affects.duration` already gives seconds;
   the current renderer displays the received minutes without maintaining an
   elapsed-time countdown. The client can estimate remaining time from a
   monotonic receipt time and reset on the next snapshot. This requires no
   extra server ticks. An authoritative expiry/cancellation contract is useful
   only where an estimate does not meet the feature's needs. [C5, S4]

## 4. Recommended server additions, in priority order

### A. Small time snapshot: highest benefit for very little work

Propose `Duris.Time` with `hour`, `phase`, and optional calendar fields. These
names are a local extension proposal. Reuse `time_info` and the existing phase
rules: dawn 04–08, day 09–15, dusk 16–18, night 19–03. Define calendar indexing
explicitly if included. [S14]

Send on character entry/re-enable and hour/phase change, including staff-set
time. Build common global data once per change and send to interested players.
If the feature only needs a phase icon, phase changes suffice after the initial
snapshot. Existing astronomical announcements are limited to awake players in
eligible outdoor rooms, so text alone can leave the icon stale indoors.

Marginal work is a few scalar reads, one small serialization and recipient
delivery at rare existing events. Do **not** implement it by invoking `do_time()`:
that handler also reads reboot settings and can schedule an autoreboot after
the uptime threshold. A time serializer should only read state. [S14]

Optional shutdown metadata (`kind`, deadline) can be published when shutdown
state changes, allowing a client countdown instead of repeated text queries.
It does not need second-by-second server packets.

### B. Complete `Combat.Update` with tank state

Add `tank: {name, position, health, healthPercent}` or `tank:null`. The current
client already accepts a tank table, so this completes an existing intended
interface. Update it to process explicit tank clears too. [C1, S7]

Use the same relationship the prompt uses: the player's opponent's opponent,
subject to same-room and recipient visibility rules. Refresh when that
relationship changes, and when the tank's health/posture changes, including
rescue, flee, death and departure. Group state can then supply already-published
group HP without guessing the tank's identity. Ensure observer updates occur
even when the tank does not itself use GMCP.

Constant-size data is cheap; identifying affected observers is the main cost.
Mark relevant existing combat participants/group observers dirty at mutation
sites and coalesce their snapshots. Avoid a scan of every character on every
hit. Removing the prompt parser must also prevent text from overwriting exact
target percentages or clearing an unrelated ongoing fight.

### C. Explicit character/session lifecycle

Propose `Duris.Session {state, generation, character}` with states such as
`account`, `chargen`, `playing`, plus explicit character clearing. Publish on
the existing account/nanny transitions, attach/detach and GMCP re-enable.
Send it in a defined order relative to initial character snapshots. [S1, S15]

This removes account-menu border matching and gives UI/automation a shared,
idempotent session boundary. Generation distinguishes a new character session
from a repeated initial snapshot. Keep commands tied to entry only once;
renegotiation must not rerun saved login commands. Consider an explicit stream
enabled/disabled notification to replace matching the GMCP preference sentence.
This is a few fields per transition with no new world lookup.

### D. Inventory/equipment: high value, bounded list work

Implement owner snapshots under a documented `Char.Items` contract, for example
`Char.Items.List` with a location (`inv`/`eq`), revision and item array. Start
with requested snapshots or a dirty, subscribed panel; add incremental
add/update/remove messages only if needed. The name resembles other MUDs'
conventions, but Duris has no such handler today and must specify its schema.

Include only visible item descriptions, quantity, worn slot, command selector,
and useful known condition/flags; optionally carrying count/weight/capacity.
Use an opaque per-instance handle with a generation if clients need stable
identity. Do not use template vnums as identities. Preserve empty snapshots,
wraithform/anatomy restrictions, grouped duplicates, and normal item visibility.
Keep nested-container contents on request. [C2, S13]

Candidate dirty hooks include `obj_to_char`, `obj_from_char`,
`obj_to_char_at_end`, `equip_char`, `unequip_char`, extraction, renaming and
relevant condition changes. Audit real mutations, not just player commands.
Do not serialize within every helper: bulk looting and temporary unequip during
saves must not emit intermediate states. Mark the owner dirty and serialize
once after a completed mutation/at a bounded flush. A list is O(items), so this
is not the same cost class as a time scalar. [S13]

### E. Action outcomes and meaningful cooldown/activity state

Propose a narrow `Duris.Action` result (`kind`, `outcome`, permitted target,
reason, event ID) and self-only readiness/activity metadata. Initial useful
events: bash, rescue, disarm, flee, study/prayer/infusion completion, song end,
mining and consent. Send from the branch that already determines success or
failure; do not infer it again from command input. [C4, S7]

Publish a cooldown deadline/remaining interval when created, changed or cleared;
let the client animate locally. Keep global action wait, individual skill
cooldown and status restrictions distinct. `CharWait()` and scheduled short
affects already own this state, but some short affects are `AFFTYPE_NOSHOW`
and excluded from `Char.Affects`. Explicitly select permitted cooldowns; do not
dump every internal hidden tag. Position alone also lacks an activity's cause.
These additions cost a small event at an existing transition, without another
timer per client per second. [S4, S7, S15]

For accurate rescue/assist automation, publish observable combat relationship
changes to eligible local observers, rather than a full extra combat log or
everyone's cooldowns. Add only the event kinds needed by actual client features.

### F. Requested results: scan, dice, identify, WHO

- **Scan:** collect detected results during the existing `do_scan()` pass,
  after its checks/random decisions. Send one bounded array plus explicit
  empty/failure result. No second traversal and no reroll of visibility. A
  structured enemy-ship scan can similarly serialize `scan_target()`'s allowed
  armor/internal result, independently of routine contacts. [S10]
- **Dice:** publish the actual result(s) just generated in `do_dice()`, with a
  roll ID and recipient scope matching the existing output. Do not generate
  replacement random values for the protocol. [S9]
- **Identify:** return authorized fields after successful identify/service
  completion, not on every inventory update. Preserve item cost/permission and
  hidden-property boundaries. [S11]
- **WHO:** reuse the requested command's filtered result, with its viewer,
  anonymity, trust, level and visibility restrictions. Do not add a continuously
  broadcast roster. MSSP is deliberately refused while public population is
  private; it is not an alternate WHO/count source. [S13]

All four remove text capture, but their existing commands still do work. A GMCP
request must not bypass normal eligibility, wait/queue rules or rate limits.
Where practical, first emit JSON alongside the authorized existing command;
a separate read request handler can follow if needed to suppress duplicate
text. Replacing `send("scan")` with a GMCP request alone does not make scanning
cheaper.

### G. Additional useful metadata, after the above

| Candidate | Useful client behavior | Low-cost publication rule |
| --- | --- | --- |
| Affect `category`/polarity, optional expiry/reason | Reliable buff/debuff placement and alerts instead of name keywords | Static metadata lookup while building current affects; permit mixed/unknown. Reuse already-known expiry, without another event-list search per field. |
| Richer score: attributes, relevant combat stats, hunger/thirst, known resource capacities | A fuller STATS panel | Initial/requested snapshot plus dirty updates for relevant changes; reuse normal score eligibility. Avoid attaching a full score sheet to every HP update. |
| `Char.Skills` list/change results | Skill browser, skill-up notices | Serialize permitted learned skills on request, send changes from actual improvement sites. There is no active SKILLS tab; the `skillsRaw` branch is leftover code. [C2] |
| Spell preparation/activity summary | Memorizing/praying progress and completion | Snapshot current activity and deadlines at existing activity transitions; send cancellation as well as completion. |
| Epic-zone report | Replace paged-text completion capture | Serve a prepared structured report or existing cached catalog view on request; preserve completion/alignment disclosure delay. No per-player refresh queries or immediate hidden completion broadcast. [S12] |
| Local weather/visibility or map-mode flag | Weather indicator and explicit wilderness detection | Read already-resolved local state on room entry/weather change. A map-mode boolean could replace `num == 0`/boolean-exit inference; no new weather simulation. |
| Explicit chat direction/recipient and event ID | Stop parsing `"You -> Name"`; deduplicate automation/history | Add at existing recipient message construction. Preserve old fields and current recipient-specific identity masking. |
| Capability/schema metadata | Reliable source selection and fallback | One small version/capability response on negotiation, updated if enabled streams change. Do not force clients to guess support from a quiet stream. |

## 5. What keeping the event loop light requires

### Gate work before constructing JSON

`ArjUI` sends `Core.Supports.Add`, but current `gmcp_handle_input()` only
handles `Core.Hello` and `Client.Info`. It does not parse Supports Set/Add/Remove
or gameplay data requests. `GMCP_ENABLED` currently gates on negotiation and
the player preference, not the requested package set. Advertising a new module
or hiding a panel does not currently reduce server serialization. [C1, S1]

For new, potentially large streams, add bounded per-descriptor interest state
and an explicit server capability response. Distinguish "can understand this
package" from "currently wants its updates" if panel subscriptions are added.
Check interest/dirty state before building a snapshot. Preserve legacy default
behavior for old clients when introducing filtering, and retain existing
preference, bridge and recipient restrictions. Any schema-version change must
be additive or explicitly negotiated.

### Coalesce state, preserve actual events

An HP/room/inventory snapshot can be coalesced to the latest state in one
flush. A dice result or action outcome cannot be silently replaced by the
next result. Use bounded event delivery with IDs and explicit reset/resync
semantics. Bound arrays, pending work, request rates and per-flush bytes; avoid
an unbounded backlog for a slow client. Initialize/reset per-connection state
on attach, reconnect, GMCP re-enable and character switch.

Define whole-list replacement versus partial update, omitted field versus
explicit null, stable identity, time units and clock basis. Always send an
authoritative empty/clear state. Mudlet's decoded JSON null can be truthy;
the existing combat handler uses type checks for this reason. The current ship
runtime `shipKey` is a useful model for replacement/session identity. [C1, C5]

### Hash suppression is not computation suppression

Current ship contacts are built once per vessel per flush and shared between
observers using verified/unverified payload variants. Own-ship info is
personalized and rebuilt per observer before hashing. Thus unchanged hashes
save network output, **not** the traversal/serialization before the hash.
The function names `gmcp_flush_dirty_ship_*` do not imply mutation-only work.
Contacts still call `getcontacts()`; ship info calls capacity/people helpers.
Do not put growing catalogs or recursive item trees into this 500 ms path.
[S5, S6]

Room snapshots are also viewer-specific. Do not share a payload across players
unless their visibility/permissions are equivalent. NPC group targeting can
scan room occupants, so enriching an existing packet does not automatically
make the entire sender O(1). Prefer cheap scalar additions, explicit dirty
flags, and reuse of already-computed results. [S4, S13]

### Preserve existing information policy

The server intentionally removes ship `worldX/worldY` from unverified
connections. Mudlet should use relative contacts/maps, not request a bypass
of the website-service authentication. Quest maps require a valid active
quest and a bought map. Epic completion/alignment visibility has a delay.
WHO and room contents depend on the recipient. New metadata must preserve
these rules, including after reconnect and permission changes. [S2, S5, S12, S13]

### Keep I/O and rendering out of telemetry hot paths

Do not add synchronous SQL/Redis/file calls, pathfinding, recursive catalog
generation, a second map/scan pass, or per-client per-second countdown work.
Use authoritative in-memory state or a prepared cache; reuse the asynchronous
completion/publication path where a feature already depends on durable work.
In particular, do not poll `gmcp_quest_status()` just to repaint the UI: it
refreshes quest state, checks availability and can generate a quest map.
The existing zone-map HTTP graph remains an appropriate separate service.

## 6. Suggested implementation sequence and acceptance checks

1. **Client-only cleanup:** use GMCP bids and appropriate affect diffs, suspend
   optional contacts polling on a known stream, fix tab received-state checks,
   use current STATS state, add Quest.Map/availability display if desired.
   Baseline/reset diffs on session/ship change so initial snapshots do not
   produce false alerts.
2. **Small contract improvements:** time, tank, lifecycle and capability
   metadata. Make stream authority explicit and stop corresponding text writes
   only after supported contract coverage is established.
3. **Inventory/equipment:** start with requested/dirty snapshots and empty
   clears. Cover all ownership/slot mutations, bulk operations and persistence
   restoration before adding deltas.
4. **Targeted events:** action/cooldown, scan/dice/identify, then the additional
   features actually wanted. Keep WHO/epic/skills reports requested or cached.

Verification for implementation should include:

- Run focused native serializer/send-path regressions in `../duris/`, extend
  `test_gui_gmcp_contract.py` and capture actual new payloads with
  `scripts/capture_server_gmcp.py --server ../duris` from the client repo.
- Extend real-Mudlet scenarios (`server-wire`, `connections`, `information`,
  `combat`, `time`, `split`, ship scenarios and lifecycle as applicable), run
  the affected subset and inspect screenshots. Reconnect, same-socket account
  return, empty state, late/duplicate text, stream disable/re-enable, and old
  server fallback are material cases.
- For events test exactly-once handling; for state test final consistency.
  Combat tests must include ally damage, rescue/tank swaps, unrelated deaths,
  departures and hidden targets. Item tests need duplicate names, empty lists,
  `get all`, wear/remove/disarm, container transfers and restoration.
- Compare before/after with equal simulated populations, combat, ship
  observers, large inventories and slow consumers. Record payload/byte counts,
  serializer invocation counts, allocations if available, and event-loop
  p50/p95/p99/max and overruns. Check that no new synchronous I/O is introduced.
- The existing `latency_trace_record("gmcp_flush", ...)` timer also spans
  persistence/cache/completion work. It is useful context but does not isolate
  GMCP costs; measure the changed serializers/flushes directly for attribution.
  [S15]
- Establish a measured budget against baseline before claiming negligible
  overhead. Source review alone cannot establish "no weight" at production load.

For this documentation-only investigation, validation consisted of inspecting
the current Lua handlers/triggers/command calls, C/C++ serializers/call sites,
loop cadence, source revision/cleanliness and documentation links. No runtime
suite or live load test was run, because no behavior changed. Package build,
version bump and release are not needed for this report.

## Source index

These immutable links preserve the investigated code and line numbers. Local
counterparts are under `src/` and `../duris/src/` respectively.

| Ref | Source and relevant locations |
| --- | --- |
| C1 | [ArjUI protocol/session/combat/time handlers](https://github.com/LuminariMUD/duris-client/blob/09924db4f2c9a5ffe47c44ebbed7977cc432eecb/src/scripts/ArjUI.lua#L1948-L2403), plus advertised modules at 790–803 and tank rendering at 2795–2860. |
| C2 | [ArjUI tabs and renderers](https://github.com/LuminariMUD/duris-client/blob/09924db4f2c9a5ffe47c44ebbed7977cc432eecb/src/scripts/ArjUI.lua#L3024-L3217), [capture and tab requests](https://github.com/LuminariMUD/duris-client/blob/09924db4f2c9a5ffe47c44ebbed7977cc432eecb/src/scripts/ArjUI.lua#L3360-L3493); actual six tabs at 1000–1001. |
| C3 | [ArjMapper HTTP requests and GMCP handlers](https://github.com/LuminariMUD/duris-client/blob/09924db4f2c9a5ffe47c44ebbed7977cc432eecb/src/scripts/ArjMapper.lua#L1116-L1277); map string decoder at 112–179 and wilderness inference at 181–190. |
| C4 | [ArjAuto combat/group/utility triggers](https://github.com/LuminariMUD/duris-client/blob/09924db4f2c9a5ffe47c44ebbed7977cc432eecb/src/scripts/ArjAuto.lua#L222-L459); GMCP-backed helpers at 95–125. |
| C5 | [ArjUI damage/scan/alerts/ship handlers](https://github.com/LuminariMUD/duris-client/blob/09924db4f2c9a5ffe47c44ebbed7977cc432eecb/src/scripts/ArjUI.lua#L3632-L3936); ship view at 4001–4037 and affects at 3219–3323. |
| C6 | [ArjAuto split, identify, epic, roller, login](https://github.com/LuminariMUD/duris-client/blob/09924db4f2c9a5ffe47c44ebbed7977cc432eecb/src/scripts/ArjAuto.lua#L532-L771). |
| C7 | [ArjAuto ship triggers/timer](https://github.com/LuminariMUD/duris-client/blob/09924db4f2c9a5ffe47c44ebbed7977cc432eecb/src/scripts/ArjAuto.lua#L485-L529), [polling aliases](https://github.com/LuminariMUD/duris-client/blob/09924db4f2c9a5ffe47c44ebbed7977cc432eecb/src/scripts/ArjAuto.lua#L1005-L1069). |
| C8 | [ArjUI chat routing](https://github.com/LuminariMUD/duris-client/blob/09924db4f2c9a5ffe47c44ebbed7977cc432eecb/src/scripts/ArjUI.lua#L2405-L2461). |
| S1 | [GMCP negotiation/input/initial state](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/gmcp.c#L43-L308); [declared package names and enabled checks](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/gmcp.h#L31-L44) (enabled macro at 138–152). |
| S2 | [Map envelope senders](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/gmcp.c#L333-L402), [quest status/map policy and generation](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/gmcp.c#L1175-L1247), [quest fields](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/core/json_utils.c#L1185-L1288). |
| S3 | [Recipient chat presentation serializer](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/chat_presentation.c#L24-L123). |
| S4 | [Vitals/status/affects serializers](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/core/json_utils.c#L873-L1073); [group serializer](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/gmcp.c#L773-L971); [hidden short-affect creation](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/magic/affects.c#L1938-L1961). |
| S5 | [Ship observer tracking, contact construction and hash flushes](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/gmcp.c#L463-L729). |
| S6 | [Complete Ship.Info serializer](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/core/json_utils.c#L1297-L1511). |
| S7 | [Combat.Update serializer](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/gmcp.c#L1013-L1109), [tank prompt relationship](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/prompt.c#L297-L349), [assist command](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/cmd/actoff.c#L5193-L5258); applied-damage hook in `src/combat/fight.c:5748–5759`, end at 8797–8804, bash cooldown checks in `actoff.c:6917–6920` and branches at 7302–7322. |
| S8 | [Char.Input receipt and opt-in](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/gmcp.c#L104-L149), [input dispatch placement](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/comm.c#L1583-L1617). |
| S9 | [Dice command results](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/economy/tradeskill.c#L2546-L2598). |
| S10 | [Player scan](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/cmd/actinf.c#L9761-L9908), [enemy vessel scan](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/ships/ship_combat.c#L196-L252), [ship lookout](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/ships/ship_utils.c#L305-L327). |
| S11 | [Identify spell and output](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/magic/magic.c#L10499-L10540); further item-value output at 10919 and service implementations in `src/item/locker_identify.c`, `src/economy/auction_houses.c:1086`. |
| S12 | [Epic display delay/alignment policy](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/world/epic.c#L1746-L1772), [cached report](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/world/epic.c#L1950-L2024), catalog at 2163–2176. |
| S13 | [Room serializer/selectors](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/core/json_utils.c#L531-L869), unused chargen builders at 1124–1179; [inventory](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/cmd/actinf.c#L8435-L8451), equipment at 8786–8810, WHO at 7430–8006; [MSSP refusal](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/mssp.c#L1-L15); item mutations in `src/world/handler.c:1891,2010,2089,2157,3051`. |
| S14 | [Clock mutation, phase and announcement restrictions](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/world/weather.c#L75-L246), [time command and autoreboot side effect](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/cmd/actinf.c#L6981-L7085). |
| S15 | [500 ms flush and composite latency timer](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/net/comm.c#L2323-L2380), group refresh at 2481–2491; [wait events](https://github.com/LuminariMUD/Duris/blob/c9361959ceb6cb2a9004fea2c03748cef909dc3f/src/world/events.c#L327-L445); initial-state callers in `src/account/nanny.c:2215` and `src/account/account.c:2206`. |
