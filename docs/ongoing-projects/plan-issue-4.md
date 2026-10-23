# Issue #4: compact Duris header implementation plan

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

Date: 2026-10-22. Status: implementation, acceptance and review repair complete; PR #7 ready for review.

Work item: [#4 — Reduce the Duris banner height or offer a compact header option](https://github.com/LuminariMUD/duris-client/issues/4).
Parent context: [#1 — Voodoo client feedback index](https://github.com/LuminariMUD/duris-client/issues/1).
Implementation branch: `branch/issue-4-compact-header`, based on `master` at
`7247c9d8d2d07295ba35c70238661b7eeccb7ed8` (package `1.3.5`).

## Implementation handoff (2026-10-22)

- Reused the clean existing worktree at
  `/home/aiwithapex/projects/durisclient-issue-4-plan`. Merged refreshed
  `origin/master` at `72efad6` (package `1.3.6`) to retain the completed #2 map
  color fix without rewriting the published planning commit.
- Applied the requested ablation skill from
  `/home/aiwithapex/projects/duris/.agents/skills/ablation/SKILL.md`; this
  repository does not contain `.agents/skills/ablation`. The selected plan is
  already minimal: one existing settings command, one shared percentage
  decision, existing gradient and renderers, no new assets or dependencies.
- `doctor` now passes with real Mudlet **5.0.1**, Qt **6.11.1**, Lua **5.1.5**,
  Xvfb, Openbox and DejaVu Sans Mono. The earlier missing-runtime finding below
  is historical. Baseline `controls` passed with normal shutdown and no Lua
  errors; run directory:
  `/home/aiwithapex/.local/share/duris-client-dev/runs/20261022T195104Z-257b015c-controls`.
  Inspected its candidate image: full artwork and original geometry present.
- Implemented early settings load, the persisted mode, immediate styling and
  geometry changes, and active map redraw through the existing renderers.
  No mapper source change or delayed-work layer was needed: real Geyser
  resizing updates the child geometry synchronously, and the existing zone
  renderer owns its throttled redraw. Extended the six planned fixtures;
  README/design/help and the `1.4.0` archive are updated.
- Focused `controls`, `maps`, `text`, and `lifecycle` checks passed, including
  full profile restart. At physical 1366x768 / logical 1366x716, the root grew
  from 620 to 675 logical px and the console from 478.578 to 521.0325 px;
  width/bottom remained stable. The native-input assertion uses a temporary
  test alias reached by physical keypress/Return: reading pending input after
  the controller types its next command cannot prove focus. No runtime input
  change was required.
- Lua 5.1 syntax/build, the eight controller unit tests and release-file
  validation pass. The required final suite passed all **20** cases at
  `/home/aiwithapex/.local/share/duris-client-dev/issue-4-final-suite`.
  Controls passed at all four requested size/scale combinations; all positive
  suite runs and matrix runs have recorded screenshot/Errors reviews.
  Real **4.22.0** portable/offline controls and lifecycle/resize/reopen checks
  also passed. **4.19.1 NOT RUN:** no executable locally and the official
  tagged release has no downloadable assets. Physical desktop DPI NOT RUN.
- Published commit `091d0a9` in focused
  [PR #7](https://github.com/LuminariMUD/duris-client/pull/7), targeting master.
  Its hosted build/runtime/CodeQL checks passed. The source is mergeable;
  GitHub's protected-branch status is `BLOCKED` pending review. Do not merge
  or push tags; release automation owns tags after a later validated merge.
- Tracked [evidence](../testing/issue-4/evidence.json) pins package payload,
  source/fixture hashes, suite/matrix results, measured bounds and selected
  screenshots. Detailed results are in the
  [testing log](mudlet-local-testing.md#140-compact-header--2026-10-22).
  The initial evidence commit was `d35c525`; master-sync commit `43ec2e4`
  incorporated the user's `.env.example` changes without changing the package.
  The subsequent one-condition review fix has its own final payload and suite
  evidence below. Do not rerun green checks for evidence-only changes.
- The user added ignored `.env` credentials and supplied the live endpoint
  `mud.duris.sbs:7777`. A dedicated profile without the offline companion is
  used for actual output/header switching with automation off. The local
  listener did not recognize that account; it was disconnected without
  confirming account creation. Remote authentication and the final bounded
  live comparison passed **24 assertions** while connected. Real room/vitals
  data survived both header transitions; measured console gain was 42.4545
  logical px. Full/compact/restored captures, footer hover and the clean
  Errors view were reviewed. `quit` returned to the account menu and `0`
  disconnected; the dedicated desktop closed normally. No player messages,
  movement, combat, ship control or server/website changes were needed.
- All three issue acceptance criteria passed in real built-package imports.
  Final review identified one additional state interaction: `mapper off`
  ignores incoming maps, but Mudlet still replaces `gmcp.Room.Map`, allowing
  layout's direct renderer call to display a paused payload. The new real
  command-path regression failed against the original implementation, and
  passes with the guard in real **5.0.1 and 4.22.0**. The ablated repair gates
  layout redraw on the existing `state.enabled` flag; no new accepted-map
  cache or renderer API was needed. Final 20-case suite and controller/release
  checks passed; paused/resumed and Errors-view screenshots were reviewed.
  Final payload:
  `8de8a5fc0aef8ebef20c8ac646856719096a75df460890520d3b6f78ef8d60ba`.
  The evidence file preserves earlier payload identities and explicitly
  reuses the unchanged geometry/enabled-map matrix, reopen and live proof.
  No implementation work remains. The repair is included in the existing PR;
  final closeout resolves the verified review finding.
  The declared minimum/physical-DPI limits
  above remain explicit review considerations, not implied passes. Next
  action is reviewer approval and a separately authorized merge/release;
  do not merge this PR or create tags as part of this implementation task.

## Outcome and boundaries

Provide a persistent, user-selectable compact header that gives the recovered
height to actual game output and supporting panels. Keep the current full
artwork mode available, retain the dark-fantasy palette and percentage-based
layout, and prove the result by importing the built package into real Mudlet.

This issue is a presentation preference, not an established rendering defect.
The reported Mudlet 4.22.0 / package 1.3.5 environment has not been reproduced
in this planning pass. The supplied screenshot is reporter evidence; it is
not a measurement of `getMainWindowSize()` or a runtime acceptance result.

Non-goals: map ANSI/background fixes (#2), SHIP presentation changes (#3),
resizable/dockable panels (#5), new artwork, a theme/layout framework, font
changes, server/website changes, changes to automation, and production access.
The parent index stays open for its other work items. This planning commit
changes only this document; it does not change `VERSION` or the package.

## Findings checked against the codebase

Source locations below refer to the pinned base. Follow the linked functions
when line numbers move during implementation.

- **The reserved height is real and fixed today.**
  [`ArjUI:init()`](../../src/scripts/ArjUI.lua#L435) sets `bannerPct = 10.5`,
  side insets to 2.5%, and the bottom inset to 2.8%. The content root therefore
  receives 86.7% of the main-window height. There is no header toggle in the
  current six boolean settings. This supports a smaller-footprint option;
  it does not establish that every player finds the current size excessive.
- **The title is part of one background image, not a header widget.**
  [`applyBackground()`](../../src/scripts/ArjUI.lua#L137) stretches
  [`duris-v1.png`](../../src/assets/duris-v1.png) over a root-level label.
  Inspection of that asset and the
  [artwork record](../artwork/duris-frame.md) confirms the wordmark and upper
  decoration are baked into the perimeter frame. Reducing `bannerPct` alone
  would put content over that artwork. Hiding a nonexistent title label, or
  changing only image dimensions, cannot deliver the complete outcome.
- **Gameplay height depends on the content root.**
  [`layout()`](../../src/scripts/ArjUI.lua#L956) moves and resizes `uiRoot`;
  `topSection` is 83% of it, and the
  [main console](../../src/scripts/ArjUI.lua#L623) is 93% of the center column.
  `setBorderTop(h)` deliberately hides Mudlet's original output so the
  package MiniConsole can display it. It is not the decorative header size
  and must retain that role.
- **The existing preference path already supplies the required control.**
  [`loadSettings()` / `setSetting()`](../../src/scripts/ArjUI.lua#L3263)
  read/write profile-local `arjui_settings.json`; the
  [`ui set` aliases](../../src/scripts/ArjUI.lua#L3919) accept boolean toggles.
  A default of `false` works with their `~= nil` recognized-key checks.
  However, settings currently load after background creation and the first
  layout. Persisting a header flag without fixing that order would leave
  initial geometry/style dependent on defaults or a later refresh.
- **Switching modes should preserve live state.**
  [`setVisible()`](../../src/scripts/ArjUI.lua#L118) already hides/shows the
  existing widgets. Calling `init()` to change a header would invoke `kill()`
  and recreate UI/state unnecessarily. Connection and stylesheet handlers
  also call `applyBackground()`, so that method must respect the saved mode.
- **A dependent geometry consumer needs attention.**
  [`ArjMapper:renderZoneMap()`](../../src/scripts/ArjMapper.lua#L728) calculates
  room positions in pixels from its container size;
  [`updateWildernessMap()`](../../src/scripts/ArjMapper.lua#L355) calculates
  vertical padding from height. There is no mapper resize-event registration.
  Parent resizing alone is not proof that already-rendered map content
  recenters. Check both modes and include the smallest redraw needed for the
  header transition; a map renderer rewrite is not justified.
- **Existing fixtures need mode-aware expectations.**
  [`lowhp.lua`](../../tests/mudlet/fixtures/lowhp.lua) unconditionally expects
  `border-image`. [`lifecycle.lua`](../../tests/mudlet/fixtures/lifecycle.lua)
  and [`reopen.lua`](../../tests/mudlet/fixtures/reopen.lua) both reuse it.
  Reuse those paths for saved compact-mode coverage without silently
  resetting the preference to make the old assertion pass.
- **The verification machinery exists, but runtime is unavailable here.**
  The [controller and fixtures](../../tests/mudlet/README.md) import a fresh
  archive into isolated real Mudlet 5.0+ profiles. During planning,
  `python3 scripts/mudlet_test.py doctor` returned
  `FAIL: Missing prerequisites: mudlet`. No import, layout reproduction,
  screenshot review, or 4.x compatibility pass is claimed by this document.

## Selected behavior

Add one boolean preference: `compactHeader`, default **off**. Users select it
through the existing command: `ui set compactHeader on|off`; `ui set` lists
its description and current value. Existing profiles without this key retain
their current appearance. No new menu, dedicated command family, or settings
file is necessary.

- **Full mode:** retain the existing frame image, 10.5% upper reservation,
  2.5% side insets, and 2.8% bottom inset. Missing artwork still uses the
  existing dark-gradient fallback without changing the full-mode geometry.
- **Compact mode:** use that existing dark gradient intentionally, omit the
  illustrated frame/wordmark, and reduce the upper reservation to **2.8%**.
  Keep side/bottom insets, bronze panel borders, warm dark surfaces, and black
  game output. This is the collapsed decorative-header option allowed by #4.
  It avoids clipping or distorting the full image to fit a smaller band.
- Apply changes immediately to existing widgets and persist the choice in the
  active profile. Preserve console contents/scrollback, selected tabs, chat,
  GMCP state, map cache/zoom, input focus/history, and handler ownership.
  Changing the setting while `ui off` must keep the interface hidden;
  `ui on` must use the selected geometry and background.

With `H = getMainWindowSize()` height, the proposed root grows from `0.867H`
to `0.944H`, recovering `0.077H`. Its bottom remains at `0.972H`. With current
child proportions, expected main-console height gain is
`0.077 × 0.83 × 0.93 × H = 0.0594363H`, subject to widget rounding.
For an actual logical content height of 720, that is about 55 px more root
height and 43 px more console height. Outer screenshot/window dimensions are
not interchangeable with `H`. These are source-derived targets to measure
in Mudlet, not previously observed results.

## Ablation decisions

- **Keep** a saved boolean and the existing alias/settings display: they give
  the player a reversible choice and preserve current profiles.
- **Keep** a coordinated root/background change: omitting either leaves
  unused space or overlaps the baked-in title.
- **Simplify** compact decoration to the existing gradient and panel chrome:
  it meets the aesthetic constraint without a second image, image-generation
  dependency, asset-selection subsystem, or crop/scaling workaround.
- **Simplify** geometry to one full/compact percentage decision shared by
  initialization and resize. Remove the competing 5.5% fallback from this
  affected path; it is not the initialized full-mode value.
- **Keep** focused geometry, command, persistence, map, and lifecycle proof:
  each covers an acceptance criterion or a traced consumer. Extend existing
  fixtures and checkpoints rather than creating a new harness.
- **Investigate** map redraw timing in real Geyser. Reuse existing renderers
  with current-session data only when their geometry needs refreshing;
  preserve map display mode and avoid downloads or new session data.
  Add delayed work only if observed layout timing requires it, and then use
  the existing owned timer cleanup.
- **Drop** arbitrary sliders/percentages, three or more header modes,
  clickable collapse widgets, global default changes, panel docking,
  broad cleanup, new dependencies, server fixtures, and unrelated tests.
  None is needed to satisfy the three acceptance items in #4.

## Implementation sequence and files

1. **Establish a runtime baseline.** Make a supported Mudlet 5.x executable
   available, rerun `doctor`, and import the unchanged base archive in an
   isolated profile. Record geometry, fonts, scale, visible full header,
   `uiRoot` and main-console bounds, and the Errors view. Keep profiles and
   screenshots outside the checkout. Use the
   [Linux development workflow](../LINUX_DEVELOPMENT.md); do not connect to
   the MUD for this layout task.
2. **Implement the mode in `src/scripts/ArjUI.lua`.** Add the false default,
   load preferences before initial background/geometry construction, and use
   one percentage decision in initial and later layouts. Make
   `applyBackground()` distinguish intentional compact styling from the
   missing-image fallback. Extend `setSetting()` to repaint and relayout
   for this key without rebuilding the UI. Update `showSettings()` and help
   as needed for discoverability. Existing connection/style callbacks must
   retain compact mode. Check loaded map geometry and reuse a guarded redraw
   if required; edit `src/scripts/ArjMapper.lua` only if its existing paths
   cannot supply the necessary redraw safely. Do not add resize handlers
   duplicating the existing UI handler.
3. **Extend the existing real-Mudlet fixtures.** In `controls.lua`, invoke the
   actual `expandAlias("ui set compactHeader on")` and off path, assert
   default/full and compact bounds after layout settles, exercise repeated
   changes, and confirm other settings and widget/state identities survive.
   In `lowhp.lua`, assert the correct artwork/gradient for the selected mode
   while keeping full artwork positively tested on fresh profiles. Extend
   `lifecycle.lua` / `reopen.lua` to leave compact enabled before reinstall
   and full profile restart, then verify the saved choice, initial geometry,
   background, hidden/show behavior, and absence of duplicate resources.
   Extend `text.lua` for full-mode missing-art fallback and compact behavior
   with/restored artwork; extend `maps.lua` only for the relevant populated
   zone/wilderness geometry transition. Use `T.steps` for visible full and
   compact checkpoints. No controller or registry change is expected.
4. **Prove usability and recovery of space.** Run the checks below, inspect
   real screenshots and Errors views, and record measured bounds plus visual
   review in `docs/ongoing-projects/mudlet-local-testing.md`. If a value
   needs adjustment, change the single compact percentage and its documented
   target; do not add tuning settings. Keep a material reduction and the
   existing usable controls.
5. **Document and package the finished change.** Update `README.md` commands
   and defaults plus `docs/DESIGN.md` layout/artwork/persistence behavior.
   Reserve a MINOR version under [RELEASING.md](../RELEASING.md), because this
   adds a backward-compatible user option (next candidate `1.4.0`, unless
   intervening releases use it). Update `VERSION` and `CHANGELOG.md`, run
   `python3 build.py`, and include rebuilt `duris-client.mpackage` with the
   source. Do not hand-edit injected version fields or the archive. Keep
   this plan updated with implementation/evidence status.

Expected files are the UI script, the six named existing fixture files,
README/design/testing documentation, `VERSION`, `CHANGELOG.md`, and the built
archive. Mapper changes are conditional on the traced redraw requirement.
`src/package.xml`, `src/config.lua`, assets, automation, CI, and the build
system need no planned source edits.

## Proof and acceptance

Use focused runs during development; run the required existing suite once
the final runtime candidate is ready. Commands run from the repository root:

```bash
python3 scripts/mudlet_test.py doctor
command -v luac5.1
luac5.1 -p src/scripts/ArjUI.lua src/scripts/ArjMapper.lua src/scripts/ArjAuto.lua
python3 build.py --check
python3 build.py
python3 scripts/mudlet_test.py run --scenario controls
python3 scripts/mudlet_test.py run --scenario lifecycle
python3 scripts/mudlet_test.py run --scenario text
python3 scripts/mudlet_test.py run --scenario maps
python3 scripts/mudlet_suite.py
```

`build.py --check` is syntax-only and can skip compilation if no compiler is
found; verify `luac5.1` explicitly. The suite imports the built archive into
real Mudlet but does not approve its appearance. Inspect candidate,
full/compact checkpoint, scenario, reopened, and Errors-view images; record
each reviewed run with the controller's `review` command. Match payload
hashes so evidence belongs to the committed package contents.

- **Acceptance 1 — smaller/selectable footprint:** fresh/legacy settings
  retain full mode; the documented user alias selects compact and restores
  full. Confirm the saved key, startup behavior, and repeated changes through
  the real alias path, not only direct helper calls.
- **Acceptance 2 — recovered usable gameplay space:** at identical actual
  window size, font, and scale, measure that compact moves the root upward,
  increases root and main-console heights by the derived amounts within
  Geyser rounding (allow roughly 1–2 logical px per measured boundary), and
  keeps root bottom and widths stable. Show visibly more game text at the
  same font size. Check wrapping/scrollback, room/XP labels, populated maps
  and hover, tabs/chat, vitals/target, footer tooltip, and native input for
  clipping, overlaps, or displaced click targets. Confirm hidden-mode
  setting changes, reconnection/style reapplication, reinstall and reopen.
- **Acceptance 3 — built-package import:** retain manifests/hashes and
  real-Mudlet screenshots for the final candidate. Run `controls` in both
  modes at 1280×720, 1366×768, and 1920×1080, plus
  `--scale 2 --size 2732x1536`. Use actual recorded logical geometry; the
  normal suite alone does not cover this matrix. Inspect all mode
  checkpoints and Errors views. Repeat crowded/long-text content in compact
  mode using existing fixtures where needed to check readability.

The reported **4.22.0** build and declared minimum **4.19.1** each require a
separate manual offline import/toggle/resize/reopen check. Follow the 4.x
profile/portable instructions; the 5.x controller cannot prove either one.
Record unavailable versions and physical-desktop DPI as **NOT RUN/BLOCKED**,
with the reason, rather than claiming compatibility from Xvfb. Do not mark
this plan's proposed behavior accepted before the implementation evidence
exists. No live-server check is needed unless implementation changes a
server-facing behavior, which is outside the selected design.

Deliver the runtime change as one focused PR referencing #4, with the source,
archive, docs and proof together. Use `Refs #4` for planning; reserve a closing
reference for the implementation after its acceptance evidence is complete.
Do not close #1 or its sibling issues. Merge/release is subsequent work;
the repository publishes releases automatically from validated `master`
pushes, and tags must not be pushed manually.

## Estimate

Budget **6–10 active engineering hours**, approximately **1–2 focused working
days**: baseline/tool setup 0.5–1 hour; settings/layout/background and map
integration 1.5–2 hours; existing-fixture extensions 1.5–2 hours; runtime,
geometry/scaling and available 4.x checks 2–4 hours; docs/package closeout
0.5–1 hour. These are estimates, not measured implementation results.

The range assumes the existing controller and renderer APIs suffice and a
supported Mudlet executable can be obtained normally. Missing Mudlet is the
current known prerequisite. Difficult 4.19.1/4.22.0 installation may add
1–2 active hours and external waiting; report that separately. New artwork,
panel resizing/docking, and other feedback issues are excluded.

## Planning validation

Inspected the current issue and parent index, repository instructions,
UI/mapper consumers, settings and aliases, existing fixtures/controller,
asset, design and release rules. `HEAD` matched refreshed `origin/master`
before writing this plan, and there was no existing `plan.md` to replace.
Runtime remains unverified for the prerequisite reason above. Validate local
document links, the planning-only diff, whitespace, published commit parity,
and the native #4 branch link before reporting this planning task complete.
