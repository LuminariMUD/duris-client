# Local Mudlet testing — 1.3.2 results

Updated **2026-10-14**. The recorded 1.3.1 defects and additional defects found
by offline/live testing are fixed in **1.3.2**. All eleven offline scenarios and
six deliberate failure cases pass their automated expectations in real Mudlet
5.0.1. Screenshot review passed for the eleven positive scenarios and ten
additional size/scaling runs. Remote CI is being verified after publication.

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
  the corrected workflow is being verified.
  `.github/workflows/mudlet-runtime.yml` pins Ubuntu 26.04, Mudlet 5.0.1 and its
  installer checksum, runs the same suite, bounds runtime and uploads evidence
  on failure. It supports manual dispatch and relevant push/PR changes.
  CI success means automated expectations passed; screenshot review remains
  explicit. The existing fast syntax/build workflow is retained.

The original seven-phase plan and 1.3.1 setup report remain in Git history at
[`aebfd72`](https://github.com/LuminariMUD/duris-client/blob/aebfd727844a57c974cdb6f329377646732a836a/docs/ongoing-projects/mudlet-local-testing.md).
Environment/baseline, repeatable execution, offline fixtures, triage and operator
documentation are implemented. Live/compatibility has the explicit limits
above; remote CI evidence is recorded after its first run. No unresolved
reproduced defect currently blocks ordinary use in the tested primary target.
