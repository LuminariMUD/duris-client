# Local Mudlet testing — GUI/server connection audit

## Final integrated candidate — 2026-10-23

Version 2.1.2 carries every reviewed feature and the portable save/rollback/
backup recovery repair. All 21 final-package suite expectations pass, including
combined private unread/reveal, stationary map and Windows-semantics cases.
Current candidate/source/per-run hashes are in ../testing/issue-5/review-2026-10-23.json.
Top-level current SHIP qualification fields were recomputed for this exact tree;
parent and live/4.22 evidence remains explicitly historical. No native Windows,
minimum-version, physical-DPI/input or fresh live qualification is claimed.


## Integrated review completion — 2026-10-23

PR #12 now follows #10 in the preserved stack: #7 → #8 → #9 → #11 → #10 → #12.
Version 2.1.1 carries compact headers, SHIP and parent review repairs. Prior
stack notes are in [plan-stack-through-10.md](plan-stack-through-10.md).

All three original findings are valid and repaired through the existing
panelIsVisible rule: covered private tells remain unread through layout/open
requests, actual reveal clears the count and refreshes its indicator, and
maximized maps redraw despite saved hidden/minimized state. Deferred paints
check effective visibility again at callback time. Saved normal state survives
restore; room/map data continues to be accepted while covered. Removed the
duplicate header redraw path in favor of the existing accepted-data viewport
callback. No new timer or renderer was introduced.

Red/green runs reproduce covered unread loss, minimized-map miscentering and a
stale contact indicator. All 21 final-package Mudlet 5.0.1 expectations pass;
map/layout checkpoint-only follow-ups also pass and supply inspected covered,
revealed, normal/minimized/hidden maximize and Errors images. Local release
payload validation, 15 release tests and ten controller tests pass.
[Current source/payload, per-run archives and regression records](../testing/issue-5/review-2026-10-23.json).
Historical live/4.22/matrix proof retains its original identity; no fresh live,
minimum-version, hardware-DPI/input or other-OS qualification is claimed.


## Qualification evidence carry-forward — 2026-10-23

PR #10 remains documentation/evidence only relative to #11. Runtime source,
controller, VERSION and archive are byte-identical to that parent. The inherited
hidden-tell finding is fixed in the carried stack. Published reference text has
no trailing whitespace; the entire current PR diff passes git diff --check.

Current 2.0.1 source/archive identities and offline 21-case proof are in
[review-2026-10-23.json](../testing/issue-3/review-2026-10-23.json), with the
fresh 115-assertion editor-capture run in editor-review-2026-10-23.json.
Historical live/4.22 evidence retains its original hashes under explicit
historical fields. It establishes the recorded ship facts and old archive,
not fresh qualification of the integrated dashboard. Earlier qualification
handoff is preserved in [plan-ship-qualification.md](plan-ship-qualification.md).
No release version bump or runtime rerun is needed for this evidence-only delta.


## 2026-10-22 - Issue #3 SHIP readability, 1.3.7


## Latest parent repair carry-forward — 2026-10-23

Current SHIP candidate is 2.0.2 and retains the portable save/rollback/recovery
and wilderness repaint repair from #8. All 21 final-package suite expectations
pass, including the new Windows-semantics fixture and SHIP scroll regression.
Current hashes and per-run archives are in ../testing/issue-3/review-2026-10-23.json.
The earlier 1280x720 SHIP check is reused only for unchanged renderer/geometry.


## Integrated SHIP review completion — 2026-10-23

PR #9 is stacked on #8, retaining #7 and both layout review repairs. Version
2.0.1 prevents a downgrade to the former standalone 1.3.7 candidate. The prior
layout handoff is preserved in [plan-issue-5.md](plan-issue-5.md).

All four existing review findings remain valid and addressed: authoritative
bridge departure stays empty; fresh zero Contacts navigation beats cached Info;
the manifest now identifies this integrated candidate; all 21 final-package
Mudlet suite expectations pass. The inherited hidden-tell defect is fixed by
#7 and retained. Integration exposed a one-row SHIP scroll drift (22 to 21);
the existing absolute scrollTo path repairs it, with the failing and passing
connection runs recorded. The 1280x720 connection case also passes 115 assertions.

Local build/release payload validation, 15 release and ten controller tests pass.
Weapon/refresh/Errors screenshots were inspected. Current source, archive and
per-run payload identities: [review record](../testing/issue-3/review-2026-10-23.json).
The old 1.3.7 live, 4.22 and size/DPI evidence is historical; the new combined
layout is not qualified by those captures. No live/minimum-version/hardware-DPI/
other-platform rerun is claimed. No merge or manual tag was performed.


## 2026-10-22 - Issue #3 SHIP readability, final 1.3.7 candidate

Ordered identity/navigation, condition, numeric-slot weapons, crew, equipment,
cargo and contacts replace the generic dump. Separate ammo/damage/timer status,
signed modifiers and honest units retain the available facts. Text fallback,
automation, zero/false, unknown maxima and state clearing survive.

Final archive SHA-256: `75f78b1b67df13425b6ba4da090b44d3b24229638177e75000ee5b944e97cbd3`.
Core `26663f2`, controller `d33a4e6`; review order PR #9, #11, #10.

- Eight controller checks and final **20/20** real-Mudlet suite expectations
  PASS under `/tmp/duris-issue3-navigation-suite`, including wire decoding,
  lifecycle/reopen, editor capture and expected deliberate failures/faults.
- A review assertion reproduced the Info-clear then empty-contacts display
  defect before the guard. `connections` and `server-wire` now verify the
  no-ship display; the separate text-only fixture starts with reset state.
- Fresh zero Contacts navigation also overrides optional cached Info fields;
  this regression failed before the two-line repair and passes after it.
- Repeated editor capture failures after passing behavior exposed a 0.3-second
  timing assumption. The separate controller PR waits up to five seconds using
  the existing readiness helper and application-exit check. Final suite passes.
- Original populated 1280x720, 1366x768, 1920x1080 and 2732x1536 scale-2 captures
  remain valid for the populated layout, whose inputs and formatting are
  unchanged by the empty-footer/navigation repairs. Exact final identities and
  the explicit reuse decision are in
  [review-followup.json](../testing/issue-3/review-followup.json); original run
  identities/screenshots stay in [offline-evidence.json](../testing/issue-3/offline-evidence.json).
- **4.22.0 / Qt 6.9.0 PASS**, all **115** assertions, fresh exact-archive import
  in a separate portable root through the connection dialog's Offline button.
  Departure and actual Errors-view screenshots were inspected; no Lua errors.
- **Final-archive live comparison PASS:** fresh profile, actual GallTest bridge
  packets and `look ship`/`look crew`; identity, navigation, four condition arcs,
  sail, passengers, crew/chiefs/skills/modifiers, stamina, repair, six weapons
  and silk cargo agree. Captures, decoded GMCP and reference/panel text are in
  [qualification.json](../testing/issue-3/qualification.json).
- Cargo is **5/70 crates**, whereas the reference's **80/165 load** is weight.
  Hull weight, set orders, exact timers and equipment damage are not supplied.
  Live equipment/contacts were empty; populated/damaged/no-ammo cases are offline.
- Published reference transcripts remove trailing line padding while retaining
  interior diagram alignment; untrimmed capture hashes remain in qualification.
- Real bridge departure clears state **and display**. Veridian was returned
  to the original Inn of Oceans (66899), quit and disconnected normally;
  owned desktops closed and temporary credentials removed. No ship state changed.
- Lua 5.1.5 syntax and release source/archive equality validation PASS.
  Environment: Ubuntu 24.04.4 WSL2, Mudlet 5.0.1 / Qt 6.11.1, Xvfb 96dpi,
  DejaVu Sans Mono. **4.19.1, physical desktop DPI and Windows/macOS unverified.**

Rich constructed fixtures and actual live packets retain distinct provenance;
the checked-in serializer JSON was not regenerated. The updated [plan](plan.md)
is the continuation reference. Hosted CI is separate from local qualification.

## Later review findings — 2026-10-23

The Windows replacement finding is valid: repeated saves now retain a backup
while replacing an existing destination, restore it on failed installation,
and can load it after interruption. The real-Mudlet fixture fails before this
repair and passes with simulated Windows destination semantics, rollback and
recovery. This is not native Windows runtime qualification.
Wilderness resize now repaints the last accepted payload; zone/session changes
retire it. The inactive private-frame menu placeholder is removed from this
dashboard-only parent. Registered private frames, commands and recovery are
implemented and tested in dependent #12; no feature is dropped from the stack.
Version 2.0.1, local release payload checks, 15 release/ten controller tests and
all 21 suite expectations pass. Current hashes/runs are in review-2026-10-23.json;
its predecessor record remains historical. Native-platform limits are unchanged.

## Integrated review repair — 2026-10-23

PR #8 now carries #7 (compact header and hidden-tell repair). Merge #7 before
#8; dependent branches will carry the combined runtime forward. Published
history is preserved through a merge, with no manual release tags.
The prior header plan is preserved in [plan-issue-4.md](plan-issue-4.md).

The map-over-maximized-output finding is valid. Covered dashboard frame trees
are hidden without changing saved normal state. The mapper checks effective
body visibility before event/deferred paints, retains accepted room updates,
and reveals the latest room when output is restored. No new timer or renderer
was introduced. The hidden-tell regression from #7 remains passing.

Local release validation, 15 release tests, ten controller tests and all 21
Mudlet 5.0.1 suite expectations pass after the affected maps rerun. That rerun
corrects a fixture assumption: compact geometry can grow without adding a full
blank text row. The regression checks Geyser's hidden OR auto_hidden state;
covered output, restored latest-room map, reset layout and Errors images were
inspected. [Current source/payload and per-run archive hashes](../testing/issue-5/review-2026-10-23.json)
identify the integrated package. Earlier manifests remain historical evidence;
no fresh live, 4.22, minimum-version, hardware-DPI or other-OS claim is made.


## Review follow-up — 2026-10-23

The inherited private-chat visibility finding is valid. `ui off` now clears the
visibility flag for every conversation, including contacts without a window.
Unread tells remain unread until that conversation is explicitly opened.
The extended command-path chat fixture fails on b055e15 and passes after repair.
Version 1.4.1 includes this fix and the rebuilt package.

Local release validation, 15 release tests, eight controller tests, and all
20 real Mudlet 5.0.1 suite expectations pass. The chat/reopen screenshot and
Errors view were inspected. Exact source/archive identities and run directories
are in [the review record](../testing/issue-4/review-2026-10-23.json).
Earlier matrix/live/4.22 captures retain their historical identities; their
unchanged compact-header geometry and enabled-map behavior are reused.
No new live/minimum-version/physical-DPI/platform qualification is claimed.

## 1.4.0 compact header — 2026-10-22

[Issue #4 / PR #7](https://github.com/LuminariMUD/duris-client/pull/7) adds the
saved `ui set compactHeader on|off` option. Full artwork remains the default;
compact mode uses the existing gradient and moves the root top from 10.5% to
2.8%. The [handoff plan](plan.md) records implementation and scope decisions.
The implementation was committed as `091d0a9` after merging master `72efad6`.

**PASS:** Lua 5.1.5 syntax for all three scripts, `python3 build.py --check`,
the version 1.4.0 build, eight controller unit tests, and local release-file
validation. `python3 scripts/mudlet_suite.py --root
/home/aiwithapex/.local/share/duris-client-dev/issue-4-final-suite --jobs 3` passed
all **20** registered expectations (14 positive scenarios and six intentional
failure/startup-fault cases). Every positive run closed normally, cleaned up
its processes, and recorded no Lua exceptions. Deliberate zero-maxima inputs
in `vitals` retain the existing Geyser guard warnings in the Errors view.

**PASS:** real Mudlet **5.0.1 / Qt 6.11.1**, Ubuntu 24.04 / WSL2, Xvfb/Openbox,
DejaVu Sans Mono. Inspected candidate, relevant scenario/checkpoints, reopened
profile and actual Errors-view images; used the controller's `review` command
for all positive scenarios and the size/scale runs. Full artwork, restored
artwork, intentional compact gradient, missing-art fallback, crowded groups,
long output, native key input and tabs remain usable. Compact mode preserves
widgets, scrollback, other settings and handler counts, stays hidden when
changed under `ui off`, and survives connection/style events, reinstall and
full profile restart. Populated zone maps recenter and retain hover targets;
wilderness maps recompute padding without a new map request or zoom reset.

The controls scenario checks both modes at the same actual font/scale. Its
physical window sizes and measured logical content geometry were:

- **1280x720, scale 1:** logical 1280x668; root height 579 -> 630 px;
  main console 446.9301 -> 486.2970 px (**+39.37 px**).
- **1366x768, scale 1:** logical 1366x716; root 620 -> 675 px;
  console 478.5780 -> 521.0325 px (**+42.45 px**).
- **1920x1080, scale 1:** logical 1920x1028; root 891 -> 970 px;
  console 687.7629 -> 748.7430 px (**+60.98 px**).
- **2732x1536, scale 2:** logical 1366x716; root 620 -> 675 px;
  console 478.5780 -> 521.0325 px (**+42.45 logical px**).

Root bottoms and widths remain stable; measured gains match the planned
7.7% root / 5.94363% console increase within widget rounding. At unchanged
font size, the compact checkpoints visibly show additional game-text rows.

**PASS:** a separate official Mudlet **4.22.0 / Qt 6.9.0** extracted AppImage
copy, isolated with `portable.txt` and the connection dialog's **Offline**
button. The real controls fixture passed default/legacy settings, full/compact
aliases, repeated changes, input and hidden/show behavior. The lifecycle
fixture passed uninstall/reinstall, native resize in compact mode, normal
save/close and a full process reopen; screenshots and Errors views reviewed.
No unsupported 5.x startup/isolation flags were passed to the 4.x executable.

**PASS — review regression:** the automated PR review found that layout's
direct wilderness renderer call could bypass `mapper off`, because Mudlet
still replaces `gmcp.Room.Map` while the package ignores its event. The new
`maps.lua` command-path sequence reproduced the failure before the fix, then
passed against the rebuilt archive in **5.0.1 and 4.22.0**. The repair gates
layout redraw on the existing mapper `state.enabled` flag. It preserves the
accepted display through full/compact changes, resize and hide/show while
paused; `mapper on` resumes accepting maps. No new state/cache is needed.
Final paused/resumed and Errors-view captures were inspected, and the required
20-case suite, eight controller tests and release validation passed again.

Evidence: [manifest and measured bounds](../testing/issue-4/evidence.json),
[full](../testing/issue-4/full-5.0.1.png),
[compact](../testing/issue-4/compact-5.0.1.png),
[Errors view](../testing/issue-4/errors-5.0.1.png), and
[4.22 reopened compact](../testing/issue-4/reopened-4.22.png), plus
[paused map in final 4.22 archive](../testing/issue-4/paused-map-4.22.png).
The final archive is SHA-256
`cf20f25c4605b3e67cdeaa070997ba3fcad30c02035702a4f4f5d493187b7dfc`,
with payload SHA-256
`8de8a5fc0aef8ebef20c8ac646856719096a75df460890520d3b6f78ef8d60ba`.
It passed the final 20-case suite and 4.22 maps scenario. Initial matrix,
4.22 controls/reopen and live checks used payload
`845104dcd0069f4466d1a3925e6901d5d50d6f1039959b74b2287321033e2046`.
Those results are retained with their own identities: the only subsequent
runtime change is the mapper-enabled guard, leaving geometry, settings,
styles, lifecycle and enabled-map rendering unchanged. Final 1366x768
controls also remeasured the same gain. Original positive-suite visuals are
reused for unchanged paths; final controls/maps and paused-state captures
have additional explicit reviews. The evidence file distinguishes every
candidate instead of relabeling older runs as final-archive checks.
Complete profiles, manifests, fixture hashes and original captures remain
outside the checkout under the per-run paths in the evidence file.

**NOT RUN:** Mudlet 4.19.1 (no local executable, and its official tagged
release currently exposes no downloadable binaries); physical desktop DPI
(scale-2/Xvfb is simulated). The declared minimum is unchanged; 4.22/5.x
results do not establish minimum-version compatibility.

**PASS — live:** after the user supplied credentials and confirmed
`mud.duris.sbs:7777`, a separate `Duris-Live-Header` profile imported the same
archive with no offline companion, command override or public-map restriction.
All automation stayed off. Actual Char.Status/Vitals and Room.Info arrived;
`look` showed real room text. A bounded full -> compact -> full comparison
passed **24 assertions**: real connection/data, off automation, widget/state,
tabs and handler preservation, expected 42.4545 px console gain, and full
geometry/artwork restoration while the socket remained connected. Inspected
all three live captures, footer hover and the actual clean Errors view.
The character returned to its account menu with `quit`; `0` disconnected
the account, then the dedicated desktop closed normally. No movement,
combat, ship-control commands or messages to other players were needed.

The initial local listener did not recognize the account and was disconnected
at its unconfirmed new-account prompt without creating an account. Earlier
remote attempts were closed by the host while navigating the login flow;
the final bounded comparison retained its connection and explicitly logged
out. Credentials remained in the ignored local `.env`; login prompts and
private live captures are outside the checkout. Only sanitized live bounds,
assertions and screenshot hashes are included in the evidence file. No
server/website source or configuration was changed.

## 1.3.6 wilderness map colors — 2026-10-22

[Issue #2 investigation and evidence](map-color-bleeding.md) records the
server color contract, reproduced 1.3.5 failure, fixed 1.3.6 result and
reviewed screenshots. The same diagnostic fixture fails in the original
archive and passes all 23 checks in real Mudlet **4.22.0**, using fresh
portable profiles and the connection dialog's Offline button.

Mudlet 5.0.1 passed all **20** suite expectations. Focused map-color checks
also passed at 1280×720, 1920×1080 and scale 2 / 2732×1536, with initial-map
and Errors-view captures inspected at each size. Source/package validation,
8 controller tests and 15 release tests passed. Movement/`look` coverage is
synthetic GMCP; live wilderness, 4.19.1 and physical desktop DPI remain
unverified. Hosted CI is separate from these local checks.

## 1.3.4 primary feed background — 2026-10-15

The primary output console and its surrounding panel now use opaque black,
matching the main Mudlet console's background in the test profile. The bronze
frame and secondary panel colors are preserved.

- `python3 build.py` passed Lua 5.1 syntax, XML validation and package assembly.
- `python3 scripts/mudlet_suite.py --root /home/staging/.local/share/duris-client-dev/runs/primary-background-1.3.4`
  passed **19/19 expectations** in Mudlet 5.0.1 (thirteen positive scenarios
  and six expected failures).
- Reviewed the `lowhp` scenario, `text` scenario and artwork fallback,
  `lifecycle` reopened fixture, and their Errors-view screenshots. The feed
  remains black, ANSI colors and wrapping are intact, and no Lua errors appear.
  Visual PASS notes are recorded for those three runs; other scenarios received
  automated checks only.
- Pixel comparison with the 1.3.3 `text/scenario.png` confirms the feed changed
  from RGB `(12,11,9)` to `(0,0,0)` at `(600,500)`. Panel padding at `(252,500)`
  and `(600,608)` is also `(0,0,0)` in the new text screenshot.
- `candidate-comparison.json` in that evidence root confirms all nineteen
  tested archives have the same payload as the rebuilt root package, whose
  SHA-256 is `44452b7da3a78fdee712a300a1a3c49ec86994acb339f75efcc1a13cfab82fa0`.

This visual fix was checked offline at 1366×768 under Xvfb. No live server
check was needed; Mudlet 4.19.1 and physical desktop DPI remain unverified.

## 1.3.3 connection audit — 2026-10-14

The client/server source audit and fixes cover all **eleven GMCP packages
consumed by this client**, their login/reconnect/empty-state lifecycles, the
existing text/command interfaces, and the HTTPS zone-map dependency. Client
candidate **1.3.3** is prepared for publication to this repository's `master`
at the user's request. The user is handling the server repository separately;
changes in `/home/staging/duris` remain uncommitted by this audit. No release,
production restart or binary replacement was performed. The 1.3.2 results
below are retained as historical evidence.

### Fixes and connection matrix

| Connection | Finding and resulting behavior | Verification |
| --- | --- | --- |
| Telnet GMCP / Core.Hello / Supports | Advertisement omitted maps, ships and quests in some paths. Advertise all eleven packages with the built version, renew on reconnect, use Supports.Add, release gmod registrations on uninstall. | Real Mudlet loopback negotiation; received Hello/Supports log; `connections`, `server-wire`, `lifecycle`. |
| Character login, linkdead reconnect, late negotiation, GMCP preference re-enable | Event-only state could remain empty until gameplay changed it. Server sends identity, vitals, affects, room, group, quest, combat and ship clearing; schedules a map refresh. Linkdead account reconnect calls the same helper. | Native contract exercises bootstrap/negotiation and checks all caller hooks; GMCP preference regression; client `login` and `connections`. |
| Char.Vitals | Publish immediately on combat start/stop, damage and vamp healing. Flag group observers even if the affected member does not use GMCP. | Native combat/group hooks, gameplay telemetry regressions, actual serialized vitals in `server-wire`; `vitals`. |
| Char.Status | Name/class/race and login detection agree with actual fields; color normalization retained. | Production serializer replay, `login`, `information`. |
| Char.Affects | Initial snapshot now includes active effects; empty updates replace old effects. | Production serializer replay of populated/empty lists; `combat`. |
| Room.Info | Mapper now reads abbreviated keys in `doors` and explicit `closed`; retains legacy `#` exit fallback. Room/area/door/player/NPC/item names are escaped once by cJSON rather than twice. | Native quote-escaping regression; actual `Gate of "Dawn"` over Telnet; `maps`, `connections`, room/group fixtures. |
| Room.Map | Ship passenger rendering no longer temporarily marks a Telnet descriptor as WebSocket. Map output stays in its negotiated transport. | Server framing/source guard, Telnet output regressions, actual Room.Map decoding in `server-wire`; zone/wilderness transitions in `maps`. |
| Group.Status | New members/observers receive data; leaving/disbanding clears the departing and last member, refreshes remaining members. `group` refresh works for Telnet while retaining normal text. `maxSize` reflects good/evil properties (default 13; CTF 5). | Executable group mutation/disband and configured-limit checks, serialized populated/empty groups, `crowded`. |
| Comm.Channel | Channel/message/sender shape matches the client; existing text fallbacks retained. | Production nchat serialization over Telnet plus eight text/channel forms and six tabs in `chat`. |
| Combat.Update | Server now publishes applied damage rounds and immediate target/start/end state. Client treats explicit null as authoritative even for bleeding targets; retains state when the field is absent. Once rounds are observed, queued final text damage cannot count again after GMCP end. Counter reset preserves stream detection; disabling streaming restores text fallback. | Native applied-damage publication and start/stop hooks; real round/null replay followed by delayed text; `combat`, `connections`. |
| Quest.Status | Active/empty payloads agree; display the complete server description without adding duplicate Ask/Kill prefixes. | Production quest serializer replay, `information`, quest-remaining regression. |
| Ship.Info | Per-descriptor hashes deliver unchanged ships to new bridge observers and track personalized bonuses. Bridge exit clears data. Client renders nested armor/hull, weapons, equipment and cargo and passes maxSpeed to automation. | Native observer join/leave/rejoin and personalized-speed tests; actual serializer replay; ship screenshot review. |
| Ship.Contacts | Server refreshes each recipient and sends empty contacts on docking/departure. Client takes heading/speed from the envelope, allegiance from `race`, and target lock from `you_targeting`. Empty GMCP lists retire old text contacts and target locks. | Native docking/observer tests, real populated/empty replay, `connections` asserts relative order heading 160 from bearing 70. |
| Account menu / disconnect / new character | Clear character, inventory/equipment/who, group, affects, quest, combat, ship and mapper state; cancel login queries, command timers, scan reports and pending map callbacks. Re-arm same-socket character login. Chat history and user preferences remain available. | `connections`, `login`, `lifecycle`, real socket disconnect in `server-wire`. |
| Text and outgoing commands | INV→`inv`, EQ→`eq`, WHO→`who`, STATS→`score`, SHIP→`look contacts`, time, movement and ship heading interfaces match server handlers. Telnet GA ends inventory/equipment capture even with a custom prompt. | Server command/ship-handler inspection; real custom-prompt replay; mouse/key and recorded-command fixtures in `information`, `controls`, `text`. |
| HTTPS zone map | Existing `https://duris.sbs/api/wiki/zones/<zone>/map-data` shape remains compatible; no website change needed. | Zone 228 returned HTTP 200 with successful TLS verification, 7 nodes/12 edges and room 22800; retained `map-api-228.json`. Loopback `maps` checks errors, timeouts, stale responses and recovery. |

The applied-damage boundary does not retain damage-type/critical metadata;
new rounds deliberately report `damageType: "unknown"` and do not infer a
critical hit. Optional fields the server does not send, such as player-list
alignment, remain optional. This audit does not add new protocol features
such as Quest.Map consumption or a WebSocket client.

### Reproducible evidence

Evidence root: `/home/staging/.local/share/duris-client-dev` (outside Git).

- `runs/connections-reviewed-1.3.3`: final rebuilt package suite: **19/19
  expectations passed** (thirteen positive scenarios and six expected failures).
  Screenshot review recorded PASS for all thirteen positive scenarios.
  Every retained candidate payload matches the root archive exactly;
  `candidate-comparison.json` records that check. Root archive SHA-256:
  `646ae303623718e544a4468e3614bb7bc569c2cab5afd6cc42f729c8e62c8946`.
- `runs/connections-final-1.3.3`: preceding suite passed all 19 expectations;
  actual screenshots reviewed for all thirteen positive scenarios. Final review
  subsequently added cancellation of the separate scan timer and retention of
  GMCP damage capability on manual counter reset, with regressions for both.
- `runs/connections-suite-1.3.3`: initial suite exposed the removed legacy `#`
  door fallback; restored and verified in `connections-map-retest` and later
  suites. The first expanded wire test also exposed a fixture console-name
  capitalization error; corrected before the passing runs.
- `tests/mudlet/fixtures/server-gmcp.json`: all eleven packages produced by the
  server executable contract test against isolated world/mechanics state.
  Includes source hashes and server commit; contains no live player data.
  `tests/mudlet/gmcp_server.py` replays them over a loopback socket, writes frames
  in fragments, and records the actual Mudlet handshake.
- Server native regressions passed: `test_gui_gmcp_contract.py`,
  `test_telemetry_combat_hooks.py`, `test_telemetry_group_hooks.py`,
  `test_gmcp_prompt_regressions.py`, `test_telnet_fragmentation_contract.py`,
  `test_telnet_output_runtime.py`, `test_json_utils_runtime.py` (13 cases),
  `test_telemetry_gameplay_hooks.py`, `test_racewar_admission.py`, and
  `test_world_quest_remaining_unloaded.py`.
- Eight client controller unit tests passed. Server `make -C src -j4` passed;
  final log: `/home/staging/duris/bin/gui-connection-build-final.log`.
  The quote regression failed before its fix; evidence is retained at
  `/home/staging/duris/bin/gui-gmcp-room-escaping-before.log`.
- Both worktrees pass `git diff --check`. Changed C/C++ lines were formatted
  with `scripts/format.sh`; whole-file `--check` still flags existing baseline
  drift in `account/account.c`, `cmd/actoth.c`, and `net/comm.c`. The same drift
  was confirmed in their HEAD versions. Unrelated whole-file formatting was
  deliberately left out of this connection fix.

```bash
# From /home/staging/duris
make -C src -j4
python3 tests/async/test_gui_gmcp_contract.py
python3 tests/async/test_telemetry_combat_hooks.py
python3 tests/async/test_telemetry_group_hooks.py

# From /home/staging/gui
python3 scripts/capture_server_gmcp.py --server /home/staging/duris
python3 build.py
python3 -m unittest discover -s tests/mudlet -p 'test_*.py'
python3 scripts/mudlet_suite.py
```

### Verification boundaries

These are source/build, executable server-function, and **real Mudlet 5.0.1
Telnet/GMCP integration** results. The loopback peer replays actual serializer
output; it does not boot a complete game world. The new server candidate has
not been exercised through a production gameplay session. Ship combat and
other unavailable live world states are not claimed as live passes. The
4.19.1 minimum and other platforms still need separate manual verification.

Both trees were clean at audit start. The server `.env` declares production;
PID 3429849 remains the original `bin/server/dms 7777` process started at
17:47:57 UTC. The built replacement is `bin/server/dms_new`. Applying it to
production is a separate operational action requiring owner permission under
[server AGENTS.md](/home/staging/duris/AGENTS.md): “Never run migrations, wipes,
or operational scripts against production without owner/user permission.”
Source fixes are ready for review; no production activation is included in
these results. No credentials, player files or environment files were edited.

## Historical 1.3.2 testing

Updated **2026-10-14**. The recorded 1.3.1 defects and additional defects found
by offline/live testing are fixed in **1.3.2**. All eleven offline scenarios and
six deliberate failure cases pass their automated expectations in real Mudlet
5.0.1. Screenshot review passed for the eleven positive scenarios and ten
additional size/scaling runs. Both the runtime and syntax/build workflows
passed on GitHub after publication.

The user's target is this installed Ubuntu/Mudlet environment. Coverage of
other Mudlet versions, physical displays and unavailable live game states is
listed explicitly; this is not a claim that every possible platform or game
state has passed. The [Linux guide](../LINUX_DEVELOPMENT.md#automated-offline-tests)
contains the reproducible operator commands.

## Candidate and environment

| Item | Recorded value |
| --- | --- |
| Starting source | `aebfd727844a57c974cdb6f329377646732a836a` plus the source/diff saved per run |
| Package | 1.3.2; root archive rebuilt from `src/`, with matching VERSION/changelog |
| Root archive SHA-256 | `8710d00927eec1d2418ca65d87e1adb10d33099fefeee38cdcc2deb7be7c574b` |
| Package payload SHA-256 | `68192e95cdabd172a27ba3c9126122c5b2e4dfcf246f74d117ee1c5c2a3694d1` |
| OS / client | Ubuntu 26.04.1 amd64; native Mudlet 5.0.1; Qt 6.10.2 build/runtime |
| Compiler / font | Lua 5.1.5; DejaVu Sans Mono 12 (also the local Consolas substitution) |
| Display | Xvfb/Openbox; 1280×720, 1366×768, 1920×1080 at scale 1; 2732×1536 at scale 2 |
| Server source | `d27e2b5ec5431d6489acd6258c264dcb1aeec29a` |
| Website source | `f5efe2394d0a0ce9cbc99191316449fe266b6d56` |
| Live endpoint | Confirmed running Duris listener at `74.208.126.44:7777`; test character Veridian |

The official Ubuntu Mudlet installer was checksum-verified:
`6ea43609e9d043e9272b67ddb356ba8b33894682453ddfb4d61c0406e5dc8b25`.
Every test requires a real Lua 5.1 compiler, validates ZIP/XML, all three
assembled scripts, both injected versions and source assets before import.

Build ZIP timestamps vary. Each manifest records its exact archive hash;
`payload_sha256` additionally identifies uncompressed filenames/content.
`artifacts/remediation/candidate-comparison.json` verifies that the final suite
and size-matrix archives contain the same package payload as the root archive.
The companion and fixtures never enter the player package.

## Evidence and how to reproduce

Evidence root: `/home/staging/.local/share/duris-client-dev` (outside Git).
These links refer to retained local directories on this workstation:

- [Final full suite](../../../.local/share/duris-client-dev/runs/final-reviewed-1.3.2):
  one fresh profile per scenario; `suite-results.json` records all 17 cases.
- [Final size/scaling matrix](../../../.local/share/duris-client-dev/runs/final-reviewed-matrix-1.3.2):
  `matrix-results.json`, manifests, checkpoints and screenshots.
- [Live and before/after evidence](../../../.local/share/duris-client-dev/artifacts/remediation):
  `live-final.json`, `live-extra.json`, `live-logout.json`, `live-fresh-errors.png` and
  `candidate-comparison.json`.
- [Original setup evidence](../../../.local/share/duris-client-dev/artifacts/setup-20261014T184545Z):
  the 1.3.1 baseline, including the first failing artwork/footer/input captures.

Each run retains its built archive, source diff, controller, fixture inputs,
manifest, results, readable report, main-console text, application logs and
actual screenshots. Filenames identify intermediate transitions, including
failures and recovery. Assertions and visual review are separate result fields.
The controller returns zero for automated success; overall status remains
`NOT RUN` until an actual review is recorded. A failed assertion/error/cleanup
cannot be promoted to a passing overall result by visual review.

```bash
python3 scripts/mudlet_test.py doctor
python3 -m unittest discover -s tests/mudlet -p 'test_*.py'
python3 scripts/mudlet_suite.py
python3 scripts/mudlet_test.py run --scenario maps --size 1280x720 --timeout 70
python3 scripts/mudlet_test.py run --scenario crowded --scale 2 --size 2732x1536
```

The suite never reads `.env`, connects to Duris or uses the public map service.
It uses a loopback map server and records attempted commands in a disconnected
profile. The separate live profile has no test companion, send override or map
override. Credentials were read privately from ignored `.env`; none are in the
repo, fixtures, reports or shared screenshots.

## Findings and fixes

All package findings below are fixed; evidence is in the named final scenario
and the retained earlier failing runs. Severity describes the original impact.

| ID / severity | Reproduction and observed failure | Fix and verification |
| --- | --- | --- |
| LINUX-001 / cosmetic | Linux import selected the gradient although the installed artwork existed: Windows backslashes made `io.open()` fail. | Preserve compatible separators; `lowhp` shows artwork, `text` verifies both missing-asset fallback and restoration. |
| LINUX-002 / layout | Custom and native command inputs both remained visible. Mudlet 5.0.1 rejects disabling its main command line. | Keep the native input, reclaim console space; keyboard/tab/control checks and all sizes show one main input. |
| LINUX-003 / cosmetic | Footer showed v1.0 while package/runtime were 1.3.1. | Render the build-injected version; final screenshots show 1.3.2. |
| LIFECYCLE-001 / high | Uninstall left UI, 17 UI event entries, 2 mapper handlers, 162 automation aliases and 71 triggers. Hide/show also reset state. | Own and cancel callbacks, aliases, triggers and download handlers; delete widgets where supported; preserve state on hide/show. `lifecycle` tests three hide/show cycles, pending actions/download, uninstall, replacement and full process reopen. Original `uninstall-before.json/png` retained. |
| GROUP-001 / layout | Twelve members overlapped and clipped into the players panel; a long NPC name lost its marker. Final screenshot review also found the scrolled viewport could stay beyond the remaining members after removal. | Scroll within the group panel using readable row heights, retain `*`, supply full-name tooltip, and hide departing widgets before deferred deletion to recompute scroll extents; `crowded` includes scrolling, removal and solo transitions at all sizes. |
| COMBAT-001 / state | A fight using GMCP left the source flag set, suppressing text damage in the next fight; mixed sources could double count. | Reset source at fight end and keep one source per fight; `combat` verifies both source orders and next-fight text fallback. |
| COMBAT-002 / runtime | Actual disengage sent `Combat.Update {target:null}`. Mudlet's truthy null sentinel caused a table-indexing error. | Require target/tank tables. `combat` decodes JSON null; live training-dummy disengage receives the real update with no Lua error. Earlier `live-combat-errors.txt` retained. |
| TEXT-001 / layout | Real long NPC/room text was clipped by a fixed 400-column console. | Use automatic wrapping; `text` verifies the ending across wrapped rows, with readable live room output and size checks. |
| INV-001 / data loss | Live inventory's bare names, capitalized names and `[2]` counts were discarded; deduplication could suppress identical items. | Retain nonempty item lines until the prompt, including repeats and empty completion; `information` and actual live inventory pass. |
| EQ-001 / stale state | Server's empty-equipment message has no normal capture header, leaving old equipment visible. | Clear on that message and show an explicit empty state; offline populated→empty transition and live EQ pass. |
| STATS-001 / state/command | Live class contained raw color codes, room text became stale, and STATS requested immortal `stat` help. | Normalize identity, refresh on room changes and request `score`; `information` plus live north/south movement pass. |
| ROOM-001 / runtime | Omitting optional area text fell back to a numeric zone ID and crashed color rendering. | Normalize the fallback to text; `lifecycle` includes that room payload. |
| MAP-001 / state/error | Repeated requests, unowned completion handlers and malformed/delayed responses could leave bad state or replace wilderness. | Deduplicate requests, validate nested data, bound waits to 15 seconds, cancel owned handlers, reject stale rendering. `maps` and pending-download uninstall pass. |
| MAP-002 / stale display | Failed new-zone fetch retained the previous map; CPU-time throttling could leave an idle client stale. | Show unavailable-map state and coalesce updates using wall time; malformed/503/schema/timeout/recovery checkpoints pass. |
| MAP-003 / hover/layout | Player marker intercepted room hover; fixed tooltip width/position could exceed a narrow map. | Decorative labels pass mouse events through; constrain tooltip width/position. Actual hover screenshots show the room ID/name within the map at 1280×720 and larger sizes. |
| SETUP-001 / environment | Default `generic_mapper` emitted unrelated prompt warnings in the baseline. | Sanitized offline profiles include only the candidate and test companion. Saved manual profile has the generic package removed. |

Harness defects were kept separate: the first chat fixture used the wrong
console-name capitalization; a menu click hit its header; uninstall checks ran
before Mudlet's deferred deletion; a long-line assertion ignored wrapping;
the saved companion could load before the package after replacement; a live
login helper initially accepted cached GMCP; and failure-message matching did
not account for wrapped lines. Each was corrected and rerun. The controller
also now fails if capture/reopen raises an exception after fixture assertions
have passed; a focused unit test guards that failure path.

The earlier manual desktop helper left an orphaned Xvfb holding its lock after
Mudlet exited. Its ownership was verified before stopping that process. Final
automated runs shut down normally, and the final process check found no Mudlet,
Openbox or Xvfb processes left behind. Download cancellation removes handlers
and timers; Mudlet may still finish the underlying transfer into its profile.

## Offline results

The final full suite is under `runs/final-reviewed-1.3.2/<scenario>/<run-id>`.
Every positive run completed normal shutdown, owned-process cleanup and Lua
error collection. Negative cases intentionally have `FAIL` run status and exit
1; the suite passes only when the expected failure is observed.

| Scenario | Automated result | Observed coverage |
| --- | --- | --- |
| lowhp | PASS | Candidate-only startup, background/version, 15% HP, mana/movement, two members, incoming text and off defaults |
| vitals | PASS | Full/zero/absent maxima, non-mana class, experience notice, coins and STATS |
| crowded | PASS | Twelve-member scrolling group, NPC/away/weakest markers, crowded NPC/item/player lists, removal and empty-room clearing |
| combat | PASS | Target/tank, affects/expiry, null target, fight reset, GMCP/text deduplication and fallback |
| chat | PASS | Eight incoming channel forms, all six tabs, wrapping/timestamps, outgoing tell history and private window |
| information | PASS | Mouse-driven INV/EQ/WHO/STATS/SHIP, actual-format inventory, empty gear, quest progress/clear, contact range ordering/removal |
| maps | PASS | Loopback requests/counts, zone/current room/doors/hover/zoom, wilderness, delayed responses, malformed JSON/nested schema, HTTP 503, timeout and reload recovery |
| controls | PASS | Native input, numpad on/off, representative aliases, every default-off toggle, enabled autoStand, selected context command, spam cancellation and persisted settings |
| login | PASS | One time query per login and renewal after a connection event |
| text | PASS | Artwork/fallback, scan format/summary, alert, ANSI and long-line wrapping |
| lifecycle | PASS | Hide/show state, resource deletion, pending-action cancellation, uninstall/reinstall, saved-profile full restart |
| assertion/timer/event failures | PASS (expected FAIL) | All three deliberate failures detected, with error evidence and clean shutdown |
| wrong profile/candidate/no readiness | PASS (expected FAIL) | No readiness accepted; bounded failure with diagnostic capture and clean shutdown |
| Controller unit tests | PASS | Eight tests, including old-version isolation rejection and failure after an initially passing fixture |

The additional matrix repeats startup/lowhp, crowded/empty room and maps at
1280×720, 1920×1080 and 2732×1536 scale 2; controls also repeat at scale 2.
Actual achieved dimensions are recorded in manifests. The ordinary full suite
uses 1366×768. Each invocation uses a clean profile; lowhp is therefore repeated
across independent launches. These are actual X/Qt mouse/key events, not a
physical keyboard or monitor test.

Visual review examines artwork/fallback, wrapping, contrast, input visibility,
scrolling, overlapping panels, map hover and state clearing. Narrow names and
area headings remain intentionally abbreviated/clipped within their panels,
with full-name tooltips; crowded consoles retain scrollable history. No pixel
baseline is automatically accepted or masked. Per-run review notes identify
the reviewed evidence. All 21 positive runs have recorded overall `PASS`.
The earlier `release-1.3.2` crowded run is retained with visual `FAIL`: its
`02-member-removal.png` exposed the scroll-extent defect despite passing state
assertions. Final removal screenshots at all four geometries show both members.
The final lifecycle run passed 319 assertions before restart and another 27
after reopening the saved profile.

## Live integration

`Duris-Live-Test` imported the rebuilt root archive with all automation off.
The listener was verified from the running local production service and bound
socket. No server/website code, game configuration or service was changed.
The live helper waits for a **new** Char.Status event after connection; cached
GMCP cannot count as a login. Final core checks passed **31 assertions**.

| Check | Result and limits |
| --- | --- |
| Transport/login/reconnect | PASS: real GMCP negotiation, Char.Status/Vitals/Affects, Room.Info and Quest.Status; multiple clean replacement/reconnect cycles |
| Inventory/EQ/WHO/STATS | PASS: actual responses captured, bare/capitalized/count items retained, empty gear shown, clean class text and player `score` command |
| Movement/room/zone map | PASS: north from room 22800 to 22801, refreshed STATS/room/exits, south back to 22800; actual public HTTPS zone map rendered |
| Training-dummy combat | PASS for attack/disengage and null-target clearing, with actual Combat.Update and no Lua errors. This dummy check does not establish a full multi-round combat stream. |
| Group/affects/quests | Solo/empty affects/inactive quest states observed; populated group, active affects and active quest progression NOT RUN live |
| Chat | Self-tell probe refused by server; no message sent to another player. Live Comm.Channel NOT RUN; synthetic routing passes. |
| Ships/wilderness | NOT RUN live: no test ship or known short wilderness route in the available state; corresponding offline fixtures pass |
| Errors and logout | `live-fresh-errors.png` and error capture clean in a new Mudlet process; normal `quit`/account-menu exit confirmed disconnected in starting room 22800; desktop closed normally |

## Compatibility, CI and remaining coverage

- **Primary target:** Ubuntu 26.04.1 / Mudlet 5.0.1 passed the exercised local
  behavior and rendering checks. Scale 2 is simulated in Xvfb; physical DPI,
  physical input, Windows and macOS remain **NOT RUN**.
- **Declared minimum 4.19.1:** **BLOCKED / not verified**. Its official GitHub
  release exposes no binary assets, and the attempted old official Linux
  AppImage URL was unavailable (the latest recorded request returned HTTP 403).
  See `minimum-version-attempt.json`. No unverified third-party binary was used.
  A compatible 4.19.1 installation and the manual portable/offline workflow
  are still needed; 5.x `--offline`/XDG startup is deliberately refused for 4.x.
- **Unavailable live states:** the table above remains open; synthetic
  fixtures do not substitute for live group/ship/wilderness/chat/active-quest
  and full combat checks. Quest-map rendering remains an unsupported feature.
- **Remote CI:** first push reached `master` at `66d5d69`. The first runtime
  [attempt](https://github.com/LuminariMUD/duris-client/actions/runs/38630930024)
  was rejected before jobs started: the job-level environment referenced
  `runner.temp`, which is unavailable in that expression context. Artifact
  setup now uses `$RUNNER_TEMP` inside a step and writes `$GITHUB_ENV`;
  the corrected [runtime run](https://github.com/LuminariMUD/duris-client/actions/runs/38631065544)
  at `e327e8a` **passed**, including all 17 scenario/fault expectations,
  eight controller checks, cleanup and artifact upload. The corresponding
  [syntax/build run](https://github.com/LuminariMUD/duris-client/actions/runs/38631065661)
  also **passed**. Runtime evidence is retained for 14 days as artifact
  `mudlet-runtime-e327e8a4d06542b824614f5b4cfea0179c2dd213` (ID `11925974054`);
  local API result snapshots are in `artifacts/remediation/ci-*.json`.
  `.github/workflows/mudlet-runtime.yml` pins Ubuntu 26.04, Mudlet 5.0.1 and its
  installer checksum, runs the same suite, bounds runtime and uploads evidence
  on failure. It supports manual dispatch and relevant push/PR changes.
  CI success means automated expectations passed; screenshot review remains
  explicit. The existing fast syntax/build workflow is retained.

The original seven-phase plan and 1.3.1 setup report remain in Git history at
[`aebfd72`](https://github.com/LuminariMUD/duris-client/blob/aebfd727844a57c974cdb6f329377646732a836a/docs/ongoing-projects/mudlet-local-testing.md).
Environment/baseline, repeatable execution, offline fixtures, triage and operator
documentation are implemented. Live/compatibility has the explicit limits
above; remote CI execution and evidence upload passed. No unresolved
reproduced defect currently blocks ordinary use in the tested primary target.

## Issue #5 dashboard chunk — 2026-10-22

Candidate 2.0.0 adds ten adjustable dashboard frames. Real Mudlet 5.0.1 / Qt
6.11.1, Xvfb 1366x768 scale 1: physical title drag, border resize, right-click
menu, reset button, all dashboard actions, off/on and profile restart pass.
The 21-case suite ran with 19 initial passes; fixes for hover dispatch and a
wrap-sensitive chat assertion passed targeted chat/maps reruns. Layout/lifecycle
also pass after restoring explicitly hidden frame bodies and clearing frame
menu registries. Ten Python controller tests pass. Inspected default,
resized, reset/menu, mixed-state and Errors-view images; no Lua errors.
See [candidate evidence](../testing/issue-5/dashboard-evidence.json) for hashes,
run paths and selected screenshots. Private chats, cached map redraw, full size/
scale matrix and 4.x qualification remain pending in the implementation plan.

## Issue #5 integration qualification — 2026-10-22

Candidate **2.1.0** completes private frame controls, fixed recovery, cached
map redraw and teardown ownership. **21/21** full-suite cases pass on real
Mudlet 5.0.1; all six additional layout/crowded size/scale cases pass. Targeted
final layout/bounds (121 + 31 reopen), lifecycle (332 + 27 reopen), controls and
maps pass after the last menu/heading changes; unaffected suite/matrix evidence
is reused. Ten controller and fifteen release tests pass, and local release
preparation confirms the committed candidate payload.

Real **Mudlet 4.22.0**, isolated extracted portable runtime, passes physical
pointer actions, private Send/input, right-click and fixed recovery menus,
reset and saved-profile reopening. Inspected default/crowded/private/map-maximize
and Errors screenshots on 5.0.1 and the 4.22 recovery/reopened/Errors captures.

Live `mud.duris.sbs:7777` (user-confirmed endpoint) authenticated, received fresh
identity/vitals/room GMCP and passed **35 layout assertions** with all automation
off. Reset retains game state/scrollback and off/on retains customization. Normal
quit/account disconnect completed, and the isolated desktop closed. Published
results contain aggregate checks only; credentials and live text/screenshots
are excluded. No server/website code or configuration changed.

[Exact candidate identities and reused evidence](../testing/issue-5/integration-evidence.json).
**4.19.1 remains unverified:** no official GitHub binary assets and no 4.19.1
entry in the current [official archive](https://www.mudlet.org/wp-content/files/?C=M%3BO%3DD);
the attempted old Linux URL returned 404. Physical DPI/input and Windows/macOS
also remain NOT RUN. This is the same minimum-version limit already recorded
for the incumbent package, not a new minimum-version claim.
