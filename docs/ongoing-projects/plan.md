# Issue #5: adjustable client panels

Date: 2026-10-22. Status: implementation in progress; dashboard frame integration underway.

Work item: [#5 — Support resizable and/or dockable client panels](https://github.com/LuminariMUD/duris-client/issues/5).
Parent context: [#1 — Voodoo client feedback index](https://github.com/LuminariMUD/duris-client/issues/1).
Implementation branch: `branch/issue-5-adjustable-panels`.

Audited package baseline: `master` at
[`7247c9d8d2d07295ba35c70238661b7eeccb7ed8`](https://github.com/LuminariMUD/duris-client/tree/7247c9d8d2d07295ba35c70238661b7eeccb7ed8),
`VERSION` **1.3.5**. Reconcile intervening changes before implementation,
especially other feedback work touching the mapper or header.

## Current handoff (2026-10-22)

- Reused the clean worktree `/home/aiwithapex/projects/durisclient-issue-5-plan` on
  `branch/issue-5-adjustable-panels`; merged `origin/master` at `72efad6` to retain
  the released map color fix (1.3.6). The planning commit remains in history.
- Applying the requested ablation skill from the existing sibling copy
  `/home/aiwithapex/projects/duris/.agents/skills/ablation/SKILL.md`; no skill copy
  exists in this client checkout. No separate planning approval is needed for
  this implementation request.
- First reviewable chunk implemented: sibling dashboard frames, common commands/recovery,
  normalized persistence and actual pointer proof. Next chunk: private chats,
  cached map redraw and complete lifecycle/geometry qualification. Publish the
  first PR as soon as its built-package checks pass; stack dependent work.
- Simplification from source inspection: call the bundled frame's gesture
  callbacks directly, then capture/clamp the owned frame and save on release.
  This removes the proposed global reposition subscription and save debounce
  timer; programmatic/root resizing cannot be mistaken for a gesture.
- Use release automation for tags only. Leave PRs open for review; do not merge
  or publish a release as part of this task. Runtime compatibility and visual
  acceptance are pending, and #5 remains open.

### Dashboard chunk evidence

Implemented dashboard commands, normalized storage, fixed recovery and physical
frame gestures, retaining console names and existing data paths. The 2.0.0
archive is rebuilt. Ten Python controller tests pass. The 20-case real-Mudlet
suite initially passed 18 cases; its two failures were the new action dispatch
rejecting existing hover and a chat assertion depending on a line-wrap boundary.
Both are corrected. Targeted **layout (including close/reopen), chat, maps and
lifecycle** pass after the fixes; unaffected suite results are reused.
Screenshot inspection found and fixed explicit `Inside.hidden` surviving
minimize/restore; the layout fixture now checks all restored panel bodies.
Combat chrome uses the documented taller bottom strip and fixed label heights.
Candidate hashes, exact run directories and selected screenshots are in
[dashboard-evidence.json](../testing/issue-5/dashboard-evidence.json).

Remaining work: session-only private chat frames and reset of their drafts/
history; cached stationary-map redraw; malformed/partial layout and geometry
matrix; 4.x runtime/desktop checks. This first chunk does not close #5. Do not
interpret its passing command tests as proof of those remaining requirements.

## Outcome and boundaries

Give players practical control of the existing dashboard: move and resize
panels, float them and return them to their home positions, minimize/restore
auxiliary panels, maximize/restore a panel, lock the arrangement, and retain
their layout across profile restarts. Provide both `ui layout reset` and a
small fixed recovery control that restore every panel's default geometry and
layout state. Preserve readable game output, native input, the dark-fantasy
palette, and percentage-based scaling.

This is an enhancement, not a reproduced Mudlet defect. The report names Mudlet
4.22.0 and client 1.3.5; the issue explicitly says the behavior has not been
reproduced and leaves the precise mechanisms open. The implementation must
prove its chosen behavior in the built package, rather than treating a screenshot
or syntax check as evidence of usability.

Non-goals: a general docking framework, arbitrary nested splits or tab tearing,
OS-level detached windows, cross-profile layout sharing, multiple named layout
presets, a new theme system, changes to GMCP/server behavior, or a web-client
rewrite. Issues #2, #3, and #4 cover map color, SHIP presentation, and header
height respectively; this plan does not absorb those requests. Header space is
used for recovery controls without changing its height.

All implementation phases below belong to #5. They are delivery steps for one
coherent feature, not deferred acceptance criteria. No additional work items
are needed for the chosen scope; if scope is later split, link concrete issues
before claiming the corresponding acceptance item is complete.

## Findings from the codebase

- [ArjUI:init()](../../src/scripts/ArjUI.lua), particularly lines 435–954,
  creates nested fixed-percentage regions with `makePanel`, a `Geyser.Label`
  helper. The left and center columns share an upper region; the right column
  occupies the full root height; vitals/tank/target sit below the left/center.
  This confirms the lack of dashboard layout controls, not a broken resize
  implementation. [DESIGN.md](../DESIGN.md#interface-layout) records the same
  arrangement.
- `ArjUI:layout()` (956–992) resizes the root/background and positions the
  credit label. It does not store user geometry. Geyser supplies percentage
  resizing of children; that is different from player-adjustable dimensions.
- `openPrivateChat()` (1442–1605) already implements title-bar dragging, but
  hardcodes a 300×220 window and pixel-sized children with a wrap width of 40.
  The assertion that nothing can move would therefore be too broad. Private
  conversations need the same resize/recovery treatment as the dashboard.
- `setVisible()`, `setupRouteAll()`, and `setupAliases()` deliberately retain
  widgets and game state through `ui off/on`. The routing trigger copies into
  the stable `ArjUI_Console` name and removes the underlying game line only
  while the UI is visible. `init()` calls `kill()` and resets state, so neither
  function is an acceptable implementation of layout reset.
- `loadSettings()`/`saveSettings()` (3272–3296) own six boolean settings in
  `arjui_settings.json`; loading explicitly filters through boolean defaults.
  Putting geometry into that format would require changing its contract.
  Use separate layout storage and leave existing preferences intact.
- [ArjMapper](../../src/scripts/ArjMapper.lua) mounts inside `ArjUI.mapWrap`.
  `renderZoneMap()` calculates rooms and clipping from measured dimensions;
  `updateWildernessMap()` calculates vertical padding from console height.
  `setupHandlers()` subscribes to room/map data, not panel resize events.
  A map resize must invalidate the view without requiring a room update or
  downloading the zone again. Zone data is cached, but the mapper does not
  retain wilderness input for redraw; add that small session-owned cache.
- Existing tests exercise tabs, chat, maps, hide/show, uninstall/reinstall,
  and saved-profile reopening. The action loop in
  [mudlet_test.py](../../scripts/mudlet_test.py) currently supports keys,
  left clicks, scrolling, and pointer movement, but not a mouse-button drag
  or right click. [reopen.lua](../../tests/mudlet/fixtures/reopen.lua) checks
  startup after restart, not persisted layout. These are concrete verification
  gaps to extend, not reasons to introduce another test framework.
- The local website source was inspected as a usability reference at sibling
  `durisweb` revision `a614b8bf4318635750c19fac45c822e37c8102c8`:
  `MudGameClient.vue` has saved sidebar/chat sizes and explicit detach/dock
  handlers; `FloatingMapWindow.vue` has dragging, resizing and maximize;
  `useFloatingPanels.ts` saves floating/minimized choices. This supports an
  explicit return-to-home docking model. It does not establish that Mudlet
  should duplicate Vue components, CSS breakpoints, or every web behavior.

### Mudlet capability check

Use the bundled `Adjustable.Container` for the interactive frame. Its documented
capabilities include moving, resizing and minimizing. Consult the
[official Geyser manual](https://wiki.mudlet.org/w/Manual:Geyser#Adjustable.Container)
and the source for the actual target versions, not the imported LuminariGUI
examples in this repository.

Source inspection covered
[4.19.1](https://github.com/Mudlet/Mudlet/blob/Mudlet-4.19.1/src/mudlet-lua/lua/geyser/GeyserAdjustableContainer.lua),
[4.22.0](https://github.com/Mudlet/Mudlet/blob/Mudlet-4.22.0/src/mudlet-lua/lua/geyser/GeyserAdjustableContainer.lua),
and the repository's pinned
[5.0.1 revision](https://github.com/Mudlet/Mudlet/blob/592821c8c0c6a638be87a9de5995b8a278f2e4b4/src/mudlet-lua/lua/geyser/GeyserAdjustableContainer.lua).
The old versions expose `AdjustableContainerReposition`; their nested mouse
resizing has no useful application-specific minimum. Their native attachment
path calls `setBorder*`, conflicting with ArjUI's full-window border reservation.
The 5.0.1 source also contains lifecycle/drag-out facilities absent from the old
files. Therefore do not rely on newer-only helpers or native border attachment.
Disable frame auto-save/load and own the package's layout and cleanup explicitly.
Source availability is not a runtime compatibility pass.

## Chosen scope and interaction model

### Panel inventory

Use stable IDs for ten dashboard groups. Existing member fields and console
names remain available to renderers, automation, and tests.

- `map`: area/world links, map, exits, and time as one navigation group.
  Combining the tiny exits/time strip with the map avoids an unreadable
  independent title bar. Preserve every existing navigation action.
- `mobs` and `items`: each existing room list and its header.
- `output`: XP, room title, and the black main game console as one group.
- `character`: the existing GROUP/STATS/INV/EQ/WHO/SHIP tab group; tabs are
  views within one panel, not six separately dockable windows.
- `players`: the existing players list and its header.
- `chat`: all existing chat tabs, consoles, and tell contacts together.
- `vitals`: HP, MP, movement, and position together.
- `tank`: tank state and the player's buffs together.
- `target`: target state, player's debuffs, and damage total together.

The background, frame, credits, recovery controls and native command line are
fixed infrastructure. Context menus and command/spell editors remain transient
popups; clamp their placement to the available viewport, but do not turn them
into saved dashboard panels. Private tell windows share move/resize,
minimize/restore, maximize and close/show behavior with session-only geometry.
They remain floating rather than occupying dashboard dock slots, and open
unlocked to preserve their existing dragging behavior. The Panels menu includes
existing conversations, identified as `tell:<name>`, for individual recovery.

### States and actions

1. **Fresh/default layout:** every dashboard panel is visible, docked in its
   current named home area, unminimized, unmaximized, and locked. GROUP and ALL
   are selected. Private conversations start closed. Preserve the present
   column/bottom-strip proportions, with the smallest measured adjustment
   needed for frame controls and readable headers. Do not shrink text to pay
   for chrome. Reuse existing headers where possible.
2. **Unlock and adjust:** `ui layout unlock` enables title dragging and frame
   resizing; `ui layout lock` stops accidental movement. Title menus expose
   the equivalent actions. A drag or resize of a home panel makes it floating.
   Existing content clicks, text selection, scrolling and inputs must remain
   distinct from the title/border gesture.
3. **Float:** the panel stays within the inset content root and retains its
   normalized rectangle on window resize. Clicking its frame raises it above
   other panels. Floating overlap is intentional and recoverable; the layout
   does not automatically reshuffle neighboring panels.
4. **Dock:** a title action returns that panel to its own named home rectangle
   and marks it docked. This is explicit return-to-home docking, comparable to
   the web client's detach/dock workflow. It is not attachment to Mudlet's
   native borders or an arbitrary IDE-style split tree. Floating a panel leaves
   its home area available; docking restores the default tile. Resizing a
   docked panel is supported by converting it to floating rather than silently
   changing other panels' geometry.
5. **Minimize/restore and hide/show:** auxiliary panels can collapse to a
   reachable title strip or be hidden via their controls. A fixed Panels menu
   lists every panel and can restore/show it without disturbing other panels.
   Restore retains the previous full rectangle. Repeated minimize/restore is
   idempotent at the package boundary. The output panel can move, resize, dock
   and maximize, but cannot be minimized or hidden independently: the game feed
   remains a non-collapsed panel without adding a second routing mode. An
   auxiliary maximize can cover it until restored. Private chat close
   continues to retain session history and update unread counts.
6. **Maximize/restore:** one panel at a time may fill the content root, keeping
   the fixed recovery controls and native input available. Retain its previous
   geometry/state and restore it exactly. A second maximize restores the first;
   dock/reset unwinds maximize first. This does not create an OS window.
7. **Persistence:** remember dashboard mode, normal rectangle, lock,
   hidden/minimized state and sufficient restore geometry. Maximize is a
   transient view and is not restored on startup. Private chat history and
   geometry remain session-only. Panel layout is a profile preference and
   survives logout/reconnect/character changes; live state clearing stays as-is.

Provide `ui layout` for the current state, panel IDs and help, plus
`ui panel <id> show|hide|minimize|restore|maximize|dock|float|lock|unlock`.
Commands and UI actions call the same dispatcher and enforce each panel's
capabilities, including the output restriction and floating-only tell windows.
These commands provide access even when a frame is obscured.
Do not intercept similarly named game commands outside these exact aliases.

### Full reset and recovery contract

`ui layout reset` and a small, fixed **Reset layout** button call one reset
function. Put the button and **Panels** control outside the movable content
root, inside the existing frame margin; raise them above maximized/floating
panels. They cannot move, minimize or be hidden through panel controls. The
command remains available while `ui off`; reset then leaves the UI off and
applies defaults before the next `ui on`.

A reset must:

- Cancel an active drag/resize and pending layout save, unwind maximization,
  and replace every saved dashboard layout entry with its factory default.
- Dock all ten groups at their default proportions, show them, restore their
  full heights, restore default locking, and select GROUP/ALL. Reset the hidden
  and minimized flags as well as what is currently painted.
- Return every existing private tell window to its initial geometry and
  closed state. Keep its history, contacts, unread data and draft text; opening
  it again uses the reset geometry. Do not persist per-player windows.
- Close transient menus/popups, redraw the current map and selected views,
  and keep the fixed controls reachable. Resetting twice produces the same
  layout. Persist defaults immediately so reopening cannot resurrect the old
  positions or stale minimized/maximize restore rectangles.
- Preserve game/chat scrollback, live GMCP state, automation choices, custom
  commands, and other `ui set` preferences. Send no server command. Do not call
  `init()`, `kill()`, uninstall/reinstall, or a profile reset.

## Implementation design and affected files

### One layout owner inside ArjUI

Keep the implementation in [ArjUI.lua](../../src/scripts/ArjUI.lua), grouped
into panel construction, geometry/state operations, persistence, and lifecycle
helpers. Add a small descriptor list for the ten actual panels: stable ID,
title, home rectangle, measured minimum size, and capabilities. This list is
also the source for reset and the Panels menu, preventing competing default
tables. No new script/module loader or package XML placeholder is needed.

Mount the dashboard frames as siblings under `uiRoot`, with `dragOut` disabled
where available and without relying on that newer option. Each frame contains
the existing panel content; preserve `self.mapWrap`, `self.console`, tab maps,
and other consumed references. Convert the current nested percentages to
root-relative home rectangles before removing obsolete positional wrappers
and the bottom separator. Do not retain a second hidden dashboard layout.
Child content continues using percentages, with a bounded title/control band.

Use only the bundled frame's proven public behavior. Disable its independent
auto-save/load, native Attach/Connect actions, and unrelated global layout
operations for these frames. Install only package-owned menu actions. Filter
`AdjustableContainerReposition` by owned frame identity; avoid recursive
move/resize updates with one application guard. Batch the final update/save
after gestures rather than writing a file on each pointer movement.

Store dashboard layout in `getMudletHomeDir()/arjui_layout.json`, using Mudlet's
existing `yajl` facilities. A versioned envelope contains known panel IDs,
normalized root-relative rectangles and the selected layout flags. Validate
finite numeric coordinates, allowed modes/booleans and positive dimensions;
merge missing panels with defaults and ignore unknown IDs. A missing, malformed
or unsupported layout loads defaults with a concise local diagnostic, while
other preference files remain intact. Use a temporary file plus replacement
for saves; report a write failure and keep the current in-memory layout usable.
Reset replaces this file's layout content rather than deleting profile data.

Bounds/minimum handling belongs to the same geometry function for drag,
resize, load, maximize and window resize. Derive numeric minima from the real
headers, six-tab rows, gauges and inputs at the supported geometries; stock
frame minima do not establish readability. Keep the title/recovery controls
inside the viewport even if it becomes smaller than a preferred content
minimum. Do not permanently overwrite the user's normal rectangle merely
because a temporary small viewport clamps its displayed rectangle. Percentage
state must be relative to the content root, not the OS desktop or parent column.

### Content and mapper integration

- In [ArjMapper.lua](../../src/scripts/ArjMapper.lua), add one owned viewport
  refresh entry point. On final map-frame resize/show/restore/reset or root
  resize, redraw zone labels from cached zone data or re-pad cached wilderness
  input according to the active mode. Retain the last accepted wilderness
  payload for this redraw and clear it on session reset and when retiring that
  wilderness view; never replay a previous character/location's map. Reuse
  existing render coalescing and timer ownership; do not trigger HTTP/GMCP
  refreshes. Hide stale hover content and measure after child geometry settles.
- Reapply selected character/chat tab visibility and the active map mode after
  parent show/restore, because recursive parent visibility must not expose all
  tab consoles or both map modes. Keep hidden/minimized panels receiving data
  and updating history; restore displays the latest state without duplicate
  chat messages, server requests, or damage accounting.
- Replace private chat's bespoke drag callbacks with the shared frame path.
  Make its history/input/Send controls respond to the available inner size and
  use wrapping based on that size. Preserve focus, send behavior and history.
- `setVisible()` must hide every owned frame/menu/private window and fixed
  control, restore native borders on `ui off`, and reapply the saved per-panel
  states on `ui on`. Temporary UI hiding must never become a persisted choice
  that all panels are hidden.
- Extend `kill()` and `disposeWidget()` handling for owned frame handlers,
  timers, frame/menu widgets and registry entries. Do not touch another
  package's `Adjustable.Container` instances or use global save/reset calls.
  Old Mudlet lacks the newer deletion cleanup: explicitly unregister only the
  resources this package created, including closures/registries that would
  otherwise retain hidden frames. Save state before ordinary teardown; make
  no scheduled layout callback act after teardown or overwrite a reset.

### Test and documentation files

- Extend [mudlet_test.py](../../scripts/mudlet_test.py)'s existing actions with
  button-aware clicks and a bounded pointer drag, using existing scaled/window
  coordinates. Ensure a drag releases the mouse button even on failure. Extend
  [test_runner.py](../../tests/mudlet/test_runner.py) only for concrete runner
  risks introduced by these actions and scenario-specific reopen checks.
- Add `tests/mudlet/fixtures/layout.lua` and register it in
  [scenarios.json](../../tests/mudlet/scenarios.json). Extend existing
  [reopen](../../tests/mudlet/fixtures/reopen.lua),
  [lifecycle](../../tests/mudlet/fixtures/lifecycle.lua),
  [chat](../../tests/mudlet/fixtures/chat.lua), and
  [maps](../../tests/mudlet/fixtures/maps.lua) fixtures where their behavior
  already supplies the relevant proof. Keep generic reopen checks valid for
  scenarios other than layout.
- Update [README.md](../../README.md#commands),
  [DESIGN.md](../DESIGN.md), the
  [testing log](mudlet-local-testing.md), and test instructions for the new
  commands, interaction model, defaults, storage and coverage limits.
- Release candidate is **2.0.0**: the dashboard layout is rebuilt, which
  [RELEASING.md](../RELEASING.md) explicitly classifies as MAJOR. Existing
  boolean settings remain compatible. This supersedes the initial 1.4.0
  estimate below. Add the matching
  dated [CHANGELOG](../../CHANGELOG.md) section, run the build and commit
  [duris-client.mpackage](../../duris-client.mpackage) with source. Starting
  from this audited 1.3.5 baseline, the expected version is 1.4.0. Existing
  settings and defaults remain compatible and require no player reconfiguration;
  if implementation instead requires that, reassess the MAJOR rule in
  [RELEASING.md](../RELEASING.md). Never hand-edit injected versions or the zip.

## Delivery sequence and estimate

1. **Prove the frame integration and defaults — 4–6 hours.** In the isolated
   test profile, exercise one actual map frame and the output frame using the
   built package. Confirm parent-relative geometry, content focus, title/menu
   styling, minima, reset reachability and teardown. Finalize the ten descriptors
   and recorded docking/visibility contract before converting the remaining
   groups. Inspect 4.19.1/4.22.0 behavior early; do not silently raise the minimum
   version or fork a replacement window toolkit when a constraint fails.
2. **Dashboard behavior, storage and recovery — 10–14 hours.** Convert all
   groups, add shared actions, bounds, save/load, fixed controls and full reset.
   Prove the same dispatcher through typed commands and actual frame controls.
   Record the chosen geometry/minima in DESIGN.md.
3. **Private chats, mapper and lifecycle — 6–8 hours.** Integrate content resize,
   tab/map visibility restoration, cached map redraw, private chat frames,
   hide/show, session transitions and removal/reinstall. Verify stable console
   buffers and all owned resources. Remove replaced drag/positional code.
4. **Qualification, docs and release candidate — 8–12 hours.** Extend the
   existing runner/fixtures, inspect the geometry/scaling matrix, exercise
   restart/reset and 4.x desktop compatibility, update docs/version/changelog,
   and commit a rebuilt package with traceable evidence.

Base estimate: **28–40 engineering hours**. Allow **6–10 hours** for older
Mudlet frame cleanup/Qt behavior and visual adjustments: **34–50 hours total,
roughly 5–7 working days for one engineer**. This includes implementation,
focused regression coverage, visual review, documentation and package building.
It excludes waiting for access to a physical 4.x installation, reviewer
turnaround and production/release scheduling. Re-estimate after step 1 if the
older runtime behavior prevents this design; source inspection alone cannot
remove that uncertainty.

These can be small implementation commits/PRs on the linked feature branch,
but partial delivery does not close #5. Keep this document current as evidence
changes; preserve completed requirements and record any scoped follow-up links.

## Proof and completion criteria

### Focused runtime acceptance

- Physically drag and resize representative frames using their actual title
  and border, then cover every panel through the common actions. Check root
  bounds, minima, floating/dock return, global/per-panel lock, maximize/restore,
  repeated minimize/restore, hide/show, raising, and the output restrictions.
  Verify clicks on tabs, map rooms/zoom, exits/time, context menus, scrollboxes,
  console text and private input still perform their original actions.
- Create a mixed layout with moved/resized, hidden, minimized and maximized
  panels plus two tell windows. Reset first by the alias and then independently
  through the fixed button. Assert all default rectangles, modes, flags, tabs
  and private-window states, unchanged game/chat data and preferences, no sent
  commands, and no resurrection after save/close/reopen. Also reset while the
  UI is off; the next `ui on` must show defaults while ordinary off/on retains
  customization.
- Reopen a customized saved profile and check saved normal geometry and flags,
  then test a missing/corrupt/partial/unsupported layout file and a smaller
  viewport. Assert that invalid geometry cannot strand controls offscreen.
  Exercise reconnect and account/character transitions without clearing layout.
- Resize/restore/maximize the map while stationary in both zone and wilderness
  modes. Verify centering, bounds, hover, zoom, correct mode and no extra
  downloads. Feed updates while a panel is minimized/hidden and verify the
  latest content after restore without duplicate text or counters.
- Exercise `ui off/on`, pending save/drag cancellation, uninstall and reinstall
  with custom layouts. Assert there is one set of aliases/handlers, no late
  layout callbacks, no surviving frame/menu widgets or owned registry entries,
  no changed third-party frames, and no mouse button left held by the runner.

### Commands and visual evidence

Use the existing [Linux workflow](../LINUX_DEVELOPMENT.md#automated-offline-tests).
On this workstation the prepared Mudlet launcher is outside the default WSL
PATH; include it, or pass the runner's explicit Mudlet path option.

```bash
export PATH="/home/aiwithapex/.local/bin:$PATH"
python3 scripts/mudlet_test.py doctor
python3 build.py --check
python3 build.py
python3 -m unittest discover -s tests/mudlet -p 'test_*.py'
python3 scripts/mudlet_test.py run --scenario layout --size 1366x768 --timeout 70
python3 scripts/mudlet_suite.py
git diff --check
```

Run the layout scenario at **1280×720, 1366×768 and 1920×1080**, plus
**2732×1536 with `--scale 2`**. The default suite does not execute this complete
matrix. Use crowded/long-text states while reviewing the changed panels.
Inspect candidate-only, interaction/checkpoint and Errors-view screenshots;
record each actual review with `mudlet_test.py review --run-dir ... --result
PASS --note ...`. A suite pass without visual inspection is not acceptance.
Use manifest archive/payload hashes to identify the exact built candidate.

Manually test the built candidate on **Mudlet 4.19.1** (declared minimum) and
**4.22.0** (reported environment), including pointer gestures, right-click
menus, private input, save/reopen, reset, teardown and physical desktop
font/DPI behavior. The automated isolated controller requires Mudlet 5.0+;
use dedicated offline/portable 4.x profiles as documented. A 5.0.1 Xvfb pass
does not stand in for these checks. No live server or production operation is
needed to establish layout behavior; preserve the existing loopback GMCP and
lifecycle coverage for integration.

Issue #5 is ready to close only when the chosen scope is implemented and the
built-package behavior, visual review and compatibility results are attached
with any remaining limitations plainly recorded. The issue's assessment item
is supplied by this plan; its implementation, Mudlet interaction verification
and full-reset items remain open until that evidence exists.

## Ablation decisions

- **Keep** a shared frame and descriptor list: ten real panels plus dynamic
  tell windows need the same actions and factory defaults. Removing it would
  duplicate movement/reset behavior and make a complete reset unreliable.
- **Simplify** docking to named home rectangles inside `uiRoot`. Native border
  attachment fights the existing console reservation; arbitrary split trees,
  automatic reflow and OS windows are not needed for the chosen requested scope.
- **Keep** one layout JSON file and package-owned state. Boolean settings cannot
  represent geometry, while frame auto-save would create competing sources and
  complicate recovery/old-version cleanup. Drop presets, import/export and
  per-conversation persistence.
- **Keep** cached map redraw and parent visibility reconciliation: measured map
  coordinates and hidden tab/map modes are direct consumers of panel geometry
  and visibility. Drop server/API changes and forced network refreshes.
- **Simplify** the tiny navigation strip into the map group and keep the main
  output unhideable. This preserves every navigation action and game visibility
  without a second text-routing implementation or unreadable extra chrome.
- **Keep** fixed reset and a Panels menu in addition to typed recovery. If all
  recovery lives in a movable/hidden frame, the mouse workflow can strand itself.
  Drop a separate layout editor, settings wizard and approval phase.
- **Keep** a narrow extension of the existing real-Mudlet action runner and
  fixtures: direct function calls and syntax checks cannot prove dragging,
  frame menus, reset-button reachability or restart persistence. Drop a second
  UI-testing system and unrelated regression expansion.

## Planning verification

This planning change contains repository documentation only. No package version,
runtime source, XML, fixtures or built archive is changed. No incumbent
`docs/ongoing-projects/plan.md` existed at the audited baseline.

The prepared workstation passed `mudlet_test.py doctor` with the launcher on
PATH: Mudlet 5.0.1, Lua 5.1.5, Qt 6.11.1 and the Xvfb/input/capture tools were
found; Consolas resolves to DejaVu Sans Mono here. This checks prerequisites,
not the proposed feature. Runtime scenarios and manual 4.x checks have not
been run for this unimplemented design. The documentation is checked for
relative-link targets and whitespace before its plan-only commit is published.
