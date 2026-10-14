# Local Mudlet deployment and testing plan

Create a repeatable local environment that loads the built Duris package into
real Mudlet, exercises the GUI, records problems, and verifies fixes. Extend
that workflow to live Duris integration and an automated offline smoke suite.
The [Linux development guide](../LINUX_DEVELOPMENT.md) supplies the initial
setup procedure; this plan tracks the implementation and its acceptance gates.

Status: **Environment installed; manual offline baseline verified with known visual issues.** Updated
2026-10-14 against commit `1ae83e8`, package version `1.3.1`. Phase 1 is complete;
Phase 2 has actual import, fixture, screenshot, reopen and error-view evidence. The full
automated suite, live integration and desktop compatibility work remain open.
See the execution log below for observations and limitations.

## Starting point

| Area | Current evidence | Work needed |
| --- | --- | --- |
| Package build | [build.py](../../build.py) assembles the three Lua scripts, XML, metadata, and assets. | Build and identify the exact candidate used for each run. |
| Static checks | [CI](../../.github/workflows/ci.yml) installs Lua 5.1, checks syntax, builds, and checks archive metadata. `--check` can report `Lua OK` after skipping an absent compiler. | Require an actual Lua 5.1 compiler in the test runner. |
| Local environment | System tools and checksum-verified Mudlet 5.0.1 installed on 2026-10-14; Xvfb/Openbox launch verified. | Retain reusable launch commands; expand coverage in later phases. |
| Runtime coverage | Manual low-health fixture executed in real Mudlet with reviewed screenshots and numeric assertions. No automated runtime suite exists yet. | Automate the proven baseline and address the recorded visual issues. |
| Server integration | `.env` can locate sibling server and website checkouts. The package does not load it. | Establish a running endpoint and test character separately. |
| Existing references | [Imported reference docs](../README.md#imported-reference-material) describe LuminariGUI tooling and MSDP in places. | Use Duris source and GMCP; do not copy unrelated test commands. |

## Execution log — 2026-10-14 setup

Scope of the current request: install and configure the Linux development
workflow, verify it in real Mudlet, and retain findings here. The later full
runtime/CI project remains separately tracked by the unchecked phases. The
[prepared-workstation commands](../LINUX_DEVELOPMENT.md#this-workstations-prepared-setup)
start the saved offline profile, capture its desktop and select scale 2.

Local development root: `/home/staging/.local/share/duris-client-dev`.
Evidence directory: [`setup-20261014T184545Z`](../../../.local/share/duris-client-dev/artifacts/setup-20261014T184545Z)
(the relative link is local to this checkout on this machine; artifacts are not
committed). It contains `manifest.json`, `source.diff`, the candidate package,
fixture inputs, runtime JSON results, geometry records and screenshots.

### Installed environment and candidate

- Ubuntu 26.04.1 amd64; Mudlet **5.0.1** native release package, Qt **6.10.2**
  at build and runtime; Lua compiler **5.1.5**. User ran the sudo installation
  because the `staging` account cannot use sudo.
- Installed Xvfb, Openbox, xdotool, ImageMagick and Lua 5.1, with the guide's
  Python, xauth, fonts, fontconfig, curl and certificate prerequisites. Used
  `--no-install-recommends`; apt's preview had no removals or upgrades.
- Official release asset SHA-256 verified against both the guide and GitHub
  release metadata:
  `6ea43609e9d043e9272b67ddb356ba8b33894682453ddfb4d61c0406e5dc8b25`.
- Real `luac5.1 -p`, `python3 build.py --check`, and an external candidate build
  passed. Archive integrity, assembled XML, all three scripts, both injected
  version values and all source assets were checked.
- Candidate SHA-256:
  `27c3e6e49d6ed9d4385779fbc98ff088af10e16ea896a6dcb547dd953a7e5317`.
  Package sources, `VERSION`, and the committed root archive were not changed.
- No pre-existing default Mudlet profile or applicable `portable.txt` override
  was found. Mudlet itself confirmed the profile home as
  `/home/staging/.local/share/duris-client-dev/config/mudlet/profiles/Duris-Visual`
  before import; see `preferences.png` and `runtime-ready.json`.
- `Duris-Visual` was created through the UI, offline at `127.0.0.1:65534`
  (port checked unused), with no login credentials, startup connection or
  automatic reconnect. GMCP is enabled. Console font: **DejaVu Sans Mono 12**;
  `Consolas` resolves to DejaVu Sans Mono on this machine. Qt scale initially 1.
- Imported **Arjinius Client 1.3.1** through Package Manager. Runtime assertions
  confirmed ArjUI, ArjMapper and ArjAuto initialized and every automation toggle
  was off. Added the guide's exact `dev lowhp` fixture as an enabled standalone
  profile alias, outside the installed package. Ran `baseui hide`.

### Verified checks and retained findings

| Check | Result / evidence |
| --- | --- |
| Build and isolated profile | **PASS**; `manifest.json`, `runtime-ready.json`, profile XML. |
| Initial import | **PASS**; `imported.png`, `initial-1366x768.png`. Initial Errors view contains only Mudlet starter-UI debug output, no package Lua errors. |
| Low-health fixture | **PASS** for injected identity, vitals, group and incoming text; `lowhp-assertions.json` reports HP 15%, mana 70%, movement 50%, two members and disconnected state. Reviewed `lowhp-1366x768.png` and `stats-1366x768.png`. |
| Long companion name | The UI intentionally normalizes and truncates names to 14 characters in `renderGroup()`. The shortened label does not overlap movement/position in the reviewed captures. Full-name display is not established. |
| Input and tabs | **PASS** for command entry, STATS/GROUP and TELLS/ALL selection. The incoming fixture text appears in the package console. |
| Hide/show | `ui off` exposes the working Mudlet console; `ui on` recreates widgets and resets vitals/group, while retaining some identity/text. This is not a clean independent-scenario reset; reopen the profile before independent tests. See `ui-off.png`, `ui-on.png`. |
| Resizing | Reviewed 1280×720, 1366×768 and full 1920×1080 captures. Increased the launcher default screen to 2048×1200 so the largest window and its decorations fit. Retained the first clipped capture as `lowhp-1920x1080-clipped.png`; corrected capture is `lowhp-1920x1080.png`. |
| Reopen | **PASS**; normal shutdown exited successfully, launcher restarted the saved profile offline, persisted fixture alias worked, assertions passed again, and Errors view was clean. See `lowhp-reopened-1366x768.png`, `lowhp-reopened-assertions.json`, `reopened-errors.png`. |
| Scale 2 | Fixture and assertions passed at `QT_SCALE_FACTOR=2`, physical client size 2732×1536, on a 4096×2400 virtual display. Reviewed `lowhp-scale2-2732x1536.png` and `scale2-errors.png`: vitals/group and input are usable; the same known background/extra-input issues remain. This does not establish physical high-DPI desktop compatibility. |
| Live server, maps, full scenario matrix, Mudlet 4.19.1 and player desktop | **NOT RUN**. No live compatibility claim. |

**LINUX-001 — Decorative background missing (cosmetic, confirmed, open).** The installed
`Arjinius Client/duris-v1.png` can be opened using its actual Linux path.
Replacing `/` with `\` makes `io.open()` fail, as done by
`ArjUI:applyBackground()`. Runtime inspection confirmed the gradient fallback
stylesheet, and the screenshots show that fallback. Evidence:
`check-lowhp.lua`, `lowhp-assertions.json`, `lowhp-1366x768.png`. The environment
is usable, but artwork verification fails. No package fix made in this setup.

**SETUP-001 — Default generic mapper interference (resolved in test-profile
configuration; reopen verified).** New Mudlet profiles include `generic_mapper`. Feeding the
fixture caused its unrelated prompt-detection warning in the main console,
visible in `ui-off.png`. Uninstalled that default package from Duris-Visual
using Mudlet's `uninstallPackage()`; Duris has its own ArjMapper. On reopening,
the default mapper was absent and the fixture ran with a clean Errors view. This does not
supply map data or prove map functionality. The built-in map widget's empty-map
controls remain visible as expected when no map exists.

**LINUX-002 — Main command line remains visible (minor layout issue, open).** The
package's custom input works, but Mudlet's original command line is also visible
below it despite the package attempting to disable it. This uses extra space;
no input failure was observed. The empty map prompt was clipped on the initial
import and laid out correctly after resizing. Retain these as layout findings
for investigation rather than treating basic fixture success as a complete
visual pass.

**LINUX-003 — Stale footer version (cosmetic, confirmed, open).** The bottom
right footer says `Arjinius Client v1.0` while Package Manager, the startup
banner and runtime `ArjUI.VERSION` report 1.3.1. See the low-health screenshots.
This is a display discrepancy; both build-time version-injection checks passed.

**Evidence-capture limitation.** Mudlet created `log/errors.txt`, but the file
remained empty even though the Errors view showed startup/debug messages.
Retained actual Errors-view screenshots instead; an empty file or stdout is
not treated as complete Lua error evidence. Future automated collection still
requires the deliberate-error validation in Phase 3.

**Shutdown and retained state.** Three desktop sessions closed normally with
exit status 0. No Mudlet, Openbox or Xvfb processes owned by this account remained
after the final shutdown, and `session.env` was removed. The saved profile
retains exactly one enabled `dev lowhp` alias matching the guide, GMCP enabled,
DejaVu Sans Mono 12 and Lua-error echo enabled. See the final `manifest.json`,
`results.json` and `installed-versions.txt`. Profiles/tools/evidence are retained
outside the checkout; no VNC listener or live profile was configured. No more
sudo commands are needed for the offline workflow.

**Environment diagnostics.** Stdout reports unavailable optional Discord,
PulseAudio/PipeWire and NVIDIA VDPAU services. Mudlet's window and rendering
work under Xvfb; sound and Discord integration were not tested. Profile
credentials are empty. Errors view is reviewed separately from stdout.

## Intended workflow and boundaries

Build from `src/`, import the resulting `.mpackage`, exercise it in Mudlet,
inspect screenshots and script errors, record findings, then rebuild and repeat
the affected scenarios after fixes. Keep the dark fantasy appearance and
percentage-based layout as acceptance requirements.

Use three distinct environments: a disconnected **Duris-Visual** profile for
fixtures, a **Duris-Live-Test** profile for actual server traffic, and a player
desktop check for native fonts, DPI, and physical input. The browser client
cannot establish that Geyser/Qt rendered this package correctly. Local GMCP
injection does not exercise Telnet negotiation or network JSON decoding.

Start with the guide's pinned [Mudlet 5.0.1 release](https://github.com/Mudlet/Mudlet/releases/tag/Mudlet-5.0.1).
Verify the installation asset and checksum for the actual OS before use.
Keep a separate compatibility run for the declared minimum, Mudlet 4.19.1.
The [upstream CLI documentation](https://wiki.mudlet.org/w/Command_line_options)
places `--offline` and `XDG_CONFIG_HOME` support in 5.0; the 4.x run needs the
connection dialog's offline option and separate portable configuration.

Store runtime tools, profiles, downloads, and evidence beneath
`$HOME/.local/share/duris-client-dev`, outside the checkout. Use a unique run
directory and configuration root for each independent scenario; lifecycle
tests deliberately reuse their own profile. Keep fixtures and the controller
in the repo, outside `src/`, so they never enter the distributable package.
Do not add external Lua dependencies to the package.

## Deliverables

The controller, fixtures and CI paths below remain proposed, not available
commands. The execution log in this document now contains actual setup results.

| Deliverable | Purpose |
| --- | --- |
| `scripts/mudlet_test.py` | Python standard-library controller with `doctor`, `bootstrap`, `run`, and `stop` operations; builds the candidate, manages the virtual desktop, and gathers results. |
| `tests/mudlet/bootstrap.lua` | Test-only companion package entry point, readiness checks, scenario dispatch, assertions, and result output. |
| `tests/mudlet/scenarios.json` | Scenario IDs, fixture paths, expected results, required geometry, and coverage layer. |
| `tests/mudlet/fixtures/` | Versioned Lua payloads, incoming text, and map JSON with source revision and expected behavior documented. |
| `tests/mudlet/map_server.py` | Loopback HTTP fixture server for successful, delayed, malformed, and failed map responses. |
| `tests/mudlet/test_runner.py` | Focused controller tests for failure reporting, stale results, timeouts, and process cleanup. |
| `.github/workflows/mudlet-runtime.yml` | Offline smoke job using the same controller after local automation is reliable. |
| `docs/ongoing-projects/mudlet-local-testing.md` (execution log above) | Keep findings and run summaries here, linking to retained evidence, as requested. |

The development guide remains the operator reference. Update it with working
commands and limitations as phases finish, instead of maintaining competing
installation recipes. Keep raw screenshots, logs, profiles, and generated
test packages in run artifacts rather than committing them by default.

## Phase 1 — Prepare the environment and candidate

Depends on: no earlier phase.

- [x] Record OS/architecture, source revision and dirty diff, `VERSION`, tool
  paths, existing Mudlet configuration, and any `portable.txt` overrides.
- [x] Install the guide's dependencies and a compatible, checksum-verified
  Mudlet build. Record Mudlet/Qt, Lua, fonts, and installation source. If a
  native package cannot run, evaluate the documented extracted AppImage route.
- [x] Establish the external development root and explicit profile directory.
  Confirm isolation inside Mudlet using `getMudletHomeDir()` before importing.
- [x] Require `luac5.1` and verify its version. Run `python3 build.py --check`,
  then build with `python3 build.py -o <run-directory>/duris-client.mpackage`.
  An absent compiler is a failed prerequisite, even if the build exits zero.
- [x] Verify archive integrity, parse assembled XML, check that no script
  placeholders remain, verify both injected version values, and check the
  three scripts and expected assets. Record the candidate SHA-256.

Acceptance: a verified candidate and environment manifest exist; Lua actually
passed syntax checking; the test root does not resolve to a player's profile.
Neither package import nor rendering is considered tested at this stage.

## Phase 2 — Establish a real Mudlet baseline

Depends on: Phase 1.

- [x] Follow the guide to launch Xvfb, Openbox, and Mudlet with a shared display
  and authentication context. Record startup logs and actual window geometry.
- [x] Create Duris-Visual offline with an unused loopback destination, enable
  GMCP, disable automatic login/reconnect, and record the console font. Hide
  Mudlet's starter UI if it competes with ArjUI.
- [x] Import the candidate through Package Manager as **Arjinius Client**.
  Confirm all three scripts initialize and wait for delayed mapper setup.
- [x] Capture the initial UI and Errors view. Exercise command input, tab
  clicks, `ui off`, and `ui on`; confirm the main console is usable when hidden.
- [x] Run the guide's low-health fixture. Check identity, HP 15%, mana 70%,
  movement 50%, two group members, long-name layout, and incoming text.
- [x] Save and close normally, reopen offline, and repeat the basic checks.
  Preserve the first failing screenshots and errors before changing code.

Acceptance: screenshots show the actual package before and after the fixture,
with explicit observations and error review. Initialization failures become
reproducible findings; repair blockers through Phase 6 before automating them.
Do not build automation around an unverified manual import procedure.

## Phase 3 — Implement repeatable execution and evidence capture

Depends on: a working Phase 2 baseline.

- [ ] Implement `doctor` with explicit prerequisite failures and `bootstrap`
  for a disposable profile. Automate the proven profile/import steps using
  real UI input or supported Mudlet APIs. Do not assume `--profile` creates a
  profile or invent an executable-Lua CLI option.
- [ ] Have the controller assemble a separate test companion package from
  `bootstrap.lua` and fixtures. Import the unchanged candidate first, then
  the companion. Keep a candidate-only startup check to detect interference
  introduced by the companion.
- [ ] Before fixtures run, assert the expected profile name and path, a
  disconnected state, candidate version, and initialized UI/mapper. Associate
  the profile with the imported candidate hash in the controller manifest.
- [ ] Use a test alias to dispatch scenarios through Mudlet's command input.
  Emit readiness and completion files containing a unique run ID, scenario
  ID, assertion results, and errors. Wait for matching acknowledgments rather
  than treating a fixed delay or a stale output file as completion.
- [ ] Bound startup, scenario, download, and shutdown waits. On failure,
  capture the current desktop, relevant logs, and process status. Track only
  processes started by the controller; `stop` must leave other Mudlet sessions
  alone. Attempt normal shutdown before terminating owned processes.
- [ ] Capture fixture exceptions and inspect Mudlet's Errors view for event
  handlers and asynchronous timers too. Prove error collection using a
  deliberate test-only failure. If complete automatic capture is unavailable,
  retain an explicit manual error-review gate; stdout alone is insufficient.
- [ ] Reset from a clean, stopped test profile between independent scenarios.
  Do not reuse saved automation, login commands, tell history, map caches, or
  stale readiness files. Lifecycle scenarios specify their intended reuse.
- [ ] Produce `manifest.json`, `results.json`, a readable report, screenshots,
  and logs per run. Distinguish assertion outcomes from visual-review status.
- [ ] Test missing dependencies, a wrong candidate/profile, no readiness,
  a deliberate assertion failure, a timer error, stale acknowledgments, and
  timeout cleanup. Confirm each prevents an overall successful result.

Acceptance: the same scenario runs twice from clean profiles with equivalent
state and reviewed layout; negative cases cannot report a pass. A failed run
retains enough evidence to diagnose it and leaves no owned processes running.

## Phase 4 — Cover the GUI and control network dependencies

Depends on: Phase 3. Add scenarios incrementally, starting with vitals/group.

- [ ] Build payloads from current handlers and server source, using the
  [server study](updates-upgrades.md) as a starting reference. Record the source
  revision; older findings in that log are not a statement of current behavior.
- [ ] Set `gmcp` tables before raising the corresponding events. Feed received
  text through `feedTriggers()` so triggers execute. Include removal/clearing
  transitions and relevant missing optional fields, not just populated panels.
- [ ] Keep the starter fixture's login/time suppression explicit. Add a
  separate login scenario that allows and observes that behavior. In offline
  control/automation cases, record attempted commands with test-only send
  instrumentation; never install that instrumentation in the live profile.
- [ ] Serve versioned map responses from loopback and set the visual profile's
  `ArjMapper.config.apiBase` to that endpoint before room injection. This is an
  existing setting in [ArjMapper.lua](../../src/scripts/ArjMapper.lua).
  Restart between cases to reset cache and in-flight requests. Assert expected
  requests at the fixture server; test map failure and recovery explicitly.
- [ ] Ensure fixture runs have no dependence on the public map website.
  `--offline` prevents startup game connections, but does not disable HTTP.
- [ ] Implement and review the following scenario matrix. Use screenshots
  for appearance and assertions/observed commands for behavior.

| Scenario group | Required observations |
| --- | --- |
| Startup and assets | Empty data remains usable; background image and fallback are distinguished; fonts and command focus are correct. |
| Vitals and identity | Full/low/zero HP, mana/non-mana classes, movement, experience, coins, long names/titles, and zero or missing maxima render sensibly. |
| Group | Solo, two-member, full group, long names, weakest member, away/NPC markers, movement, scrolling, and member removal. |
| Room | Long descriptions, crowded players/NPCs/items, fighting annotations, exits and closed/locked doors, tooltips, and context-menu commands. |
| Combat and affects | Start/update/end, target clearing, prompt-derived tank, round damage versus text fallback, damage reset, long and expired affects. |
| Chat | ALL/TELLS/NCHAT/ROOM/GUILD/GROUP routing, `gcc`/`gsay`/`jchat`, petition/wizmsg, timestamps, outgoing tells, tell windows, and long messages. |
| Information tabs and quests | STATS/INV/EQ/WHO/SHIP selection and refresh commands, recognized incoming text, quest progress/clear, and ship contacts/range ordering. |
| Maps | Zone and wilderness transitions, current room, zoom limits, tooltips, cached data, reload, delayed/error/malformed responses, and recovery. |
| Text helpers | Scan formatting, experience notices, alerts, ANSI/color handling, wrapping, and readable console history. |
| Input and automation | Numpad on/off, representative aliases, every automation toggle's off default, selected enabled actions, stop/cancel, and persisted settings. Record command count and arguments. |
| Lifecycle | Repeated hide/show, profile reopen, uninstall/reinstall, and replacement package; no duplicate actions, stale widgets, or surviving package callbacks after teardown. |

- [ ] Capture representative empty, populated, crowded, and map scenarios at
  1280×720, 1366×768, and 1920×1080, using actual achieved dimensions. Repeat
  representative scenarios at scale factor 2 after restarting Mudlet.
- [ ] Review wrapping, clipping, panel overlap, contrast, input visibility,
  menus, and tooltips. Compare images only with matching Mudlet/Qt, fonts,
  dimensions, scale, and fixtures. Record any masked dynamic regions; do not
  automatically accept a new baseline because it differs from the old one.

Acceptance: each matrix row has named fixtures and recorded expected/observed
results. Screenshots are inspected, package errors are reviewed, and external
map availability cannot affect the offline result. Known unsupported features,
such as quest-map rendering, are recorded separately from regressions.

## Phase 5 — Verify live Duris and desktop compatibility

Depends on: Phase 2 for initial integration; Phase 4 for final comparison.
Run this work alongside offline coverage when server access is available.

- [ ] Locate server/website source through the configured `.env` paths and
  read their own setup instructions. Determine whether a development server
  already exists. If one must be started, use its documented isolated data,
  port, and startup procedure; record ownership and shutdown steps.
- [ ] Establish the intended hostname, Telnet/TLS port, test character, and
  available game states from actual configuration/operator information.
  A source checkout or website URL does not establish a running game listener.
  Record unavailable access as blocked while continuing offline work.
- [ ] Create Duris-Live-Test separately, import the same candidate hash,
  enable GMCP, and review automation/login settings before connecting. Keep
  fixture injection, send instrumentation, and map overrides out of it.
- [ ] Verify actual GMCP negotiation and received character/room data. Compare
  real payloads and text with fixtures, then correct fixtures where needed.
- [ ] Exercise movement/exits, room lists, inventory/equipment/who, chat,
  affects, group, combat, quests, zone/wilderness maps, and ships where the
  test character can reach them. Record commands and observed server/UI effects.
- [ ] Test real map HTTPS downloads, disconnect/reconnect, and renewed initial
  data. Confirm there is no duplicated output or unintended automation.
- [ ] Repeat a core import, fixture, controls, and lifecycle subset on Mudlet
  4.19.1 using its supported isolation/startup procedure. Investigate version
  differences before claiming minimum-version compatibility.
- [ ] Run the candidate on the player's intended desktop OS with physical
  keyboard input and actual DPI. Record OS, Mudlet, font, scaling, resize,
  screenshot, and input results; list other platforms as untested.

Acceptance: live results are tied to the candidate, endpoint/server revision
where available, and test states. Unavailable ships/combat/access remain
`NOT RUN` or `BLOCKED`; synthetic coverage cannot close those checks. A newer
Mudlet run cannot substitute for the minimum-version or desktop checks.

## Phase 6 — Triage findings and verify fixes

Depends on: any reproducible finding; repeat throughout Phases 2–5.

- [ ] Log each finding with an ID, severity, environment, candidate hash,
  reproduction/scenario, expected and actual behavior, screenshot/error links,
  suspected cause, fix status, and verification run.
- [ ] Prioritize inability to import/use the client and unintended commands,
  then incorrect state/layout and lifecycle problems, then cosmetic defects.
  Distinguish package defects, harness errors, and upstream Mudlet issues.
- [ ] Reproduce the existing Linux asset-path concern first:
  [ArjUI:applyBackground()](../../src/scripts/ArjUI.lua) converts `/` to `\`
  before `io.open()`. Inspect the installed asset path and resulting stylesheet
  and screenshot. Treat it as a suspected defect until observed in Mudlet.
- [ ] Check delayed timers, mapper download handlers, and all three scripts
  during teardown/reinstall; do not infer cleanup from `ui off` alone.
- [ ] Make focused fixes in `src/`. Preserve a failing scenario and before/after
  evidence. Follow [release rules](../RELEASING.md) for package changes: bump
  `VERSION`, add the dated changelog section, and rebuild the committed
  `duris-client.mpackage`. Never edit version injection targets by hand.
- [ ] Load the replacement archive into a fresh/restarted test profile. Rerun
  the failing scenario, adjacent behavior, startup/lifecycle checks, and any
  affected live/desktop checks. Record a new candidate hash after every rebuild.

Acceptance: a fixed finding has an observed passing rerun against its rebuilt
candidate, with no new relevant regression. Remaining defects have severity,
impact, and follow-up recorded. Commit or publish only when separately asked;
documentation and harness-only changes do not require a package version bump.

## Phase 7 — Add CI and finish the operator workflow

Depends on: repeatable Phases 3–4 and resolution of blocking local findings.

- [ ] Add a manually triggered offline runtime job first. Pin a compatible
  runner image, Mudlet release/checksum, dependencies, font, geometry, and scale.
  Do not combine an OS-specific binary with an unexamined `ubuntu-latest` image.
- [ ] Run candidate import, low-health/group, populated layout, map fixture,
  and lifecycle smoke scenarios through the same local controller. Keep the
  existing fast syntax/build job. CI needs no real game credentials.
- [ ] Upload manifest, results, screenshots, and logs even on failure. Set
  bounded job/runtime timeouts and always run owned-process cleanup.
- [ ] Demonstrate detection of a deliberate assertion/error and startup
  timeout. Separate automated smoke success from outstanding visual review.
  Do not equate an uploaded PNG or live Mudlet process with passing UI checks.
- [ ] After stable clean runs, enable the offline smoke job for pull requests
  affecting package sources, assets, build code, or the test harness. Leave
  live-server and player-desktop checks explicitly manual.
- [ ] Update the Linux guide, documentation index, contribution instructions,
  and release checklist with the actual commands, supported environments,
  evidence locations, result interpretation, and remaining limitations.

Acceptance: a clean checkout can reproduce the offline suite using documented
setup and commands, both locally and in CI. Deliberate failures are reported
and evidence survives them. Live and desktop coverage is reported separately.

## Result records and completion criteria

Every run manifest must identify source revision/dirty diff, package version
and hash, fixture revision, Mudlet/Qt/OS, profile path, font and scaling,
window geometry, timestamps, network mode, and relevant server revision.
Store the exact inputs and command transcript alongside observations.
Exclude passwords and private chat from retained/shared evidence.

Use these result values per scenario and per required review:

| Result | Meaning |
| --- | --- |
| `PASS` | Expected behavior was observed and required assertions, visual review, and error review completed. |
| `FAIL` | Observed behavior differs; link the finding and evidence. |
| `BLOCKED` | A named prerequisite or upstream problem prevents execution/assessment. |
| `NOT RUN` | The check has not been attempted, including pending visual review. |

The first useful milestone is Phase 2: a locally deployed GUI and a concrete
issue report. Continue to the following completion gates for the full project:

- [ ] All seven phases have their acceptance evidence linked from the results
  log; open tasks and unsupported coverage are explicitly accounted for.
- [ ] The offline matrix is repeatable, reviewed, and passes against the final
  candidate; controller failure cases are demonstrated.
- [ ] Live integration, minimum-version compatibility, and the intended player
  desktop checks have actual results. Any required blocked/unrun check keeps
  that part of the project incomplete.
- [ ] No unresolved defect prevents import, ordinary play, correct core state,
  or safe command execution. Lower-impact known issues have tracked follow-up.
- [ ] The smoke workflow and operator documentation reproduce the final
  process, and process/profile cleanup has been verified.

Do not replace earlier failed evidence with the final screenshots. Preserve
the chain from finding to fix to verification, and keep the report's claims
limited to the environments and scenarios actually exercised.
