# Slim Duris frame and Stormwatch backdrop

Date: 2026-10-25. Status: **implementation in progress; initial real-Mudlet drag and render checks pass**.

- Work item: [#21 — Slim the Duris frame and add an atmospheric workspace backdrop](https://github.com/LuminariMUD/duris-client/issues/21).
- Included defect: [#20 — Panels cannot be dragged above the red line beneath the Duris banner](https://github.com/LuminariMUD/duris-client/issues/20).
- Dedicated branch: [branch/slim-frame-atmospheric-backdrop](https://github.com/LuminariMUD/duris-client/tree/branch/slim-frame-atmospheric-backdrop).
- Verified base: `master` and freshly fetched `origin/master` at
  `bdfdbe4fbd631f87003e39309cbc650e924be27b`, package **2.3.0**.
- Planning artifacts are maintained on the dedicated branch linked above.
  Runtime work is now based on that planning commit.

## Outcome

Replace the tall DURIS banner with a thin top rail matching the sides and
bottom. Give its recovered height to the actual movable-panel workspace.
Behind that workspace, reveal an original, subdued dark-fantasy panorama as
players move, resize, minimize, or hide panels. Keep the game feed and other
information surfaces opaque and readable.

The owner has delegated artistic decisions. The selected direction is
**Stormwatch: the ruined stronghold**, described below. Implementation should
carry this direction through asset generation and real-client visual review;
another concept-selection approval is not a prerequisite.

Issue #20 belongs in this implementation because changing the panel parent's
bounds can remove the old movement boundary. Artwork replacement alone cannot
close it. Keep both issues open until their implementation acceptance passes;
the eventual implementation PR should close #21 and #20 together. No live
reproduction or fix is claimed by this planning document.

## Evidence inspected

The following observations refer to the pinned base, not a future build:

- [The current frame](../../src/assets/duris-v1.png) bakes the tall wordmark,
  crest, perimeter, and black interior into one opaque image. Its
  [artwork record](../artwork/duris-frame.md) describes a deliberately empty
  center. The [rearranged-panel capture](../testing/issue-5/dashboard-resized.png)
  shows that black surface exposed beside a floating panel. This is historical
  screenshot evidence, not a fresh drag reproduction.
- In [ArjUI.lua](../../src/scripts/ArjUI.lua), `applyBackground()` stretches
  the whole image in normal mode and supplies a gradient in compact mode.
  `headerHeightPct()` returns 10.5 or 2.8. `init()` and `layout()` use that
  height for `uiRoot`; side and bottom insets are 2.5% and 2.8%.
- `createPanel()` parents each adjustable frame to `uiRoot` with
  `dragOut=false`. `panelBounds()` and `capturePanelGesture()` also clamp to
  that root. Source supports investigating a real geometry constraint;
  it does not establish the complete pointer behavior reported in #20.
- The existing recovery buttons are 22 logical pixels high and placed at
  `max(0, banner - 24)`. Simply choosing 2.8% at every height can leave less
  clearance than the buttons require. `applyPanelLayout()` raises them above
  the frames, but raising a control alone does not prevent title overlap.
- Settings load before widget creation. `compactHeader` already persists,
  repaints, and relayouts existing widgets. Layout version 1 stores normalized
  floating rectangles; docked panels use descriptor home rectangles.
- `panelPrimary` and MiniConsole backgrounds are opaque. `panelGlass` and
  some wrappers currently use translucent dark colors; those surfaces need
  explicit opacity review when scenery replaces black underneath them.
- [DESIGN.md](../DESIGN.md), [the Linux guide](../LINUX_DEVELOPMENT.md), and
  [the Mudlet suite](../../tests/mudlet/README.md) define the existing lifecycle
  and verification paths. No runtime checks were run for this planning pass.

## Selected visual design

### The slim perimeter

Retain the obsidian iron and worn bronze identity: double-beveled rails,
fine navigation engravings, tiny rivets, and restrained verdigris in recesses.
All four sides should have comparable visual weight. Corners join the rails
cleanly without projecting into the panel workspace. Remove the tall DURIS
plaque and crest; retain package identity in existing help/startup/footer text.

Keep the frame independent of the landscape. Use transparent interior artwork
and scale-safe corners/edge strips or a verified Qt slicing arrangement. Do
not stretch a complete decorated rectangle indiscriminately with the scenery.
Use the fewest native Geyser labels needed to achieve the result, with one
clear lifecycle owner. No general theme framework is needed.

### Stormwatch panorama

An ancient ruined stronghold emerges through layered mist. Broken walls and
mountain silhouettes span the scene; a storm-dark sky and a few faraway amber
windows give it depth. Charcoal, desaturated slate, weathered bronze, and small
verdigris accents connect it to the frame. Keep detail across left, center,
and right so arbitrary panel arrangements reveal useful fragments.

Use an original landscape, not a canonical map or a claim about a particular
in-game location. No foreground hero, prominent face, giant central emblem,
readable text, bright lightning bolt, or essential feature that must stay
uncovered. No animated weather, parallax, or changing scene. The atmosphere
should reward exposed space without competing with combat information.

Generate a landscape master at least 2560 pixels wide when supported; prepare
an optimized packaged PNG after inspecting actual tool output. Use a centered,
aspect-preserving cover crop within the inner frame opening. Keep focal details
away from crop-sensitive edges. Set final dimness in the artwork or one fixed
dark overlay, judged in the client; do not add a brightness-settings subsystem.

### Asset brief for generation

Generate the panorama and frame as separate assets. For the frame, inspect and
reference the existing production artwork, requesting a slim top that matches
the side/bottom rails, transparent interior, no wordmark, and no enlarged crest.
For the panorama, use this brief:

> Original panoramic dark-fantasy environment for the background of a text
> game workspace. An ancient ruined stronghold, fractured ramparts, distant
> mountains, layered drifting-looking but static mist, and a storm-dark sky.
> Obsidian charcoal and desaturated slate, weathered bronze accents, sparse
> dim amber windows, very restrained verdigris. Rich material detail with low
> overall brightness and soft broad contrast. Spread interest across the
> whole composition so movable opaque panels can cover any region. No central
> hero, faces, text, logos, frame, interface, glowing centerpiece, or lightning
> flash. Atmospheric original world illustration, not a map. Landscape canvas
> suitable for centered cover cropping at 16:10, 16:9, and ultrawide ratios.

Record prompts, references, generation output, dimensions, hashes, and any
export/crop steps in a new artwork record. Suggested package names are
`duris-frame-slim.png` (or clearly named frame strips) and
`duris-backdrop-stormwatch.png` under `src/assets/`. Keep the existing artwork
record as history; remove the old packaged asset only after auditing references.

## Layout and preference contract

Both values of `compactHeader` receive the same expanded workspace. There is
no remaining mode that reserves 10.5% for the old banner:

- **Off, the existing default:** slim illustrated perimeter and Stormwatch.
- **On:** the same slim perimeter with the existing quiet dark gradient in
  place of the panorama. This preserves the preference for subdued decoration.

Keep the saved key and command spelling to avoid breaking existing profiles
and aliases. Update settings descriptions and help to explain scenic/quiet
presentation; stop promising collapse/restore of a tall header. Do not add a
third legacy-banner mode or silently reset a saved preference.

For logical window width `W` and height `H`, use one shared geometry calculation
for initial creation and subsequent layout:

```text
left = right = 0.025 * W
top = max(0.028 * H, 24 logical pixels)
bottom = 0.028 * H
root width = max(0, W - left - right)
root height = max(0, H - top - bottom)
```

The 24px minimum protects the existing 22px recovery buttons plus clearance;
it is functional control space, not a new decorative banner. Match the visible
top rail to the other rails independently of that small clearance. Preserve
usable clamping when the window becomes unusually small.

Where the percentage exceeds the minimum, the root gains 7.7% of logical
window height over the old full mode. At smaller heights, report the actual
gain `0.105 * H - top`, not a blanket 7.7% claim. Main-console gain depends on
panel arrangement. Keep buttons above the root at `top - 24`, raised and
clickable even during maximization. Verify this in the rendered UI.

Preserve descriptor home rectangles, normalized saved floating rectangles,
mode/lock/visibility/minimization state, and layout schema version 1. A taller
root naturally changes absolute panel positions/sizes; no user reset or loss
of customization is required. Transient small-window clamping must not replace
the saved normal rectangle. Issue #19's alternative arrangement is separate.

## Implementation sequence

1. **Capture the boundary baseline.** Import the base package into an isolated
   real Mudlet profile. Use pointer dragging to reproduce #20 in full and
   compact modes; record root and title coordinates, logical size, and the
   screenshot. Record any additional native Adjustable constraints discovered.
2. **Prove the layer and crop primitives.** Check the available Mudlet/Geyser
   and Qt APIs for aspect-preserving crop, transparent frame interior, stable
   corner sizing, and input pass-through. Keep every decorative layer behind
   the dashboard and recovery controls. Use a small runtime experiment before
   committing to asset slicing; do not assume browser CSS works in Qt.
3. **Produce and integrate artwork.** Generate the selected assets, record
   provenance, and implement independent asset lookup/fallbacks. A missing
   panorama uses the gradient while retaining the frame; a missing frame uses
   simple bronze native borders while retaining the selected background.
   Neither failure changes geometry or disables controls. No runtime downloads.
4. **Expand panel bounds.** Share geometry between `init()` and `layout()`;
   preserve native input and the existing `setBorderTop(h)` console ownership.
   Reuse the existing panel and map refresh paths. Resolve additional observed
   gesture constraints only where needed to place titles above the old boundary.
5. **Preserve lifecycle and readability.** Change backgrounds on existing
   widgets rather than reinitializing. Include new layers in hide/show, resize,
   reinstall and `kill()` ownership. Keep all information panels opaque; remove
   incidental translucency where it exposes scenery behind text. Preserve
   output/scrollback, selected tabs/SHIP mode, chat drafts/history/unread state,
   map zoom/cache and paused-map semantics. No commands or network activity on
   resize, presentation changes, or redraw. Do not add polling or animation.
6. **Qualify and document.** Extend existing fixtures, capture the visual matrix,
   and run the final suite once the implementation stabilizes. Update README,
   help, DESIGN.md, artwork records and the local testing log with exact evidence.
   Update this plan and the issue checklist to distinguish completed work from
   remaining compatibility checks.

## Acceptance and evidence

- [ ] Real dragging places a panel title above the old `0.105 * H` boundary
  and at the new usable top in both preference states. Pointer input, not only
  direct geometry assignments, proves this. Compare against the base behavior.
- [ ] At the upper edge, resize, dock/float, minimize/restore, maximize/restore,
  and lock/unlock retain accessible title controls. Panels and Reset remain
  clickable; reset restores descriptor defaults. Include a private tell frame.
- [ ] Save/reopen and window shrink/grow preserve normalized floating state;
  switching scenic/quiet mode preserves the new root geometry and user layout.
  Cover fresh installs and upgrades with saved true/false/missing preferences.
- [ ] Frame corners stay coherent and the top visually matches other edges.
  The scene keeps its aspect ratio, has no seams or exposed unpainted strips,
  and remains attractive in a sparse layout with panels moved off the center.
- [ ] Review default, sparse/rearranged, and maximized layouts at physical
  1280x720, 1366x768, 1920x1080, 2732x1536 at scale 2, and 3440x1440 ultrawide.
  Record logical dimensions separately. Inspect both scenic and quiet modes
  where their appearance differs; do not equate emulated scale with physical DPI.
- [ ] Game output, chat, room lists, vitals, maps, and SHIP content retain
  readable opaque backgrounds and unchanged semantic colors. Native input
  focus/history and ordinary click/drag routing still work.
- [ ] Independent missing/corrupt asset cases fall back cleanly. Hide/show,
  reconnect/style repaint, profile restart, uninstall/reinstall, and repeated
  resize leave no orphan labels, duplicate callbacks, errors, or stale images.
- [ ] Existing `layout`, `controls`, `text`, `lowhp`, `maps`, `chat`, lifecycle
  and reopen paths cover the changed contracts. Replace obsolete full-header
  expectations with assertions of real bounds, preserved state and rendering.
- [ ] Build and full real-Mudlet suite pass; inspect affected screenshots and
  Errors views and record review against the exact candidate. Retain source,
  asset, archive/payload hashes, geometry and runtime versions with the evidence.

Use the existing commands and review procedure in the Linux guide:

```bash
python3 scripts/mudlet_test.py doctor
python3 build.py --check
python3 build.py
python3 scripts/mudlet_test.py run --scenario layout --size 1366x768
python3 scripts/mudlet_test.py run --scenario controls --scale 2 --size 2732x1536
python3 scripts/mudlet_suite.py
```

Syntax success alone is not behavior or visual acceptance. Record actual
Mudlet 4.19.1 verification separately; 5.0+ offline results do not certify the
declared minimum, native Windows/macOS, or physical DPI/input. If any such
environment is unavailable, record NOT RUN and the remaining qualification
explicitly. Any live check uses a separate profile from the offline companion.

## Packaging and closeout

Implementation uses **2.4.0** and a rebuilt archive. Follow [RELEASING.md](../RELEASING.md): a compatible presentation
and behavior change is a minor increment (provisionally 2.4.0 from this base;
reconcile with master before delivery). Do not require a reinstall or reset.
Add the dated changelog entry, rebuild through `build.py`, and include source,
assets and package together when commits are requested. Never hand-edit the
archive or generated version strings; master CI owns release tags.

Close #20 only after every one of its acceptance bullets has direct evidence
in both presentation states. Close #21 after artwork, expanded bounds,
fallback/lifecycle behavior, documentation, packaging, and available runtime
and visual checks are complete, with compatibility limits stated accurately.
Creating this plan is not implementation acceptance.

Out of scope: issue #19's panel ordering/presets, mapper defects #17/#18, new
game mechanics, GMCP/server/website changes, automation, a theme editor, custom
image uploading, animated backgrounds, or a release/deployment in this pass.

## Implementation handoff — 2026-10-25

Outcome: slim perimeter, separate Stormwatch scenery, identical expanded bounds
in both preferences, preserved player state and independent asset fallbacks.
Non-goals remain the scope exclusions above. Files: ArjUI, two PNGs, existing
Mudlet fixtures, package/version/changelog, README/DESIGN/artwork/testing records.
Proof: actual pointer gestures, saved-profile restart, fallback/lifecycle checks,
reviewed size/scaling captures and the final offline suite.

Ablation: used the existing layout/settings/teardown paths. Three background
labels (one owner plus scenery and frame) supply independent fallbacks and
native Qt crop/slicing. No theme framework, new settings, timers, network work,
user-layout migration or alternative renderer is needed. The requested skill
was absent here; the same `ablation/SKILL.md` was read from the adjacent Duris
checkout at `/home/aiwithapex/projects/duris/.agents/skills/ablation/SKILL.md`.

Base reproduction: package 2.3.0, planning commit `07063aa`, real Mudlet 5.0.1 /
Qt 6.11.1 under WSL2/Xvfb. Physical window 1366x768, client logical 1366x716.
Pointer dragging a mobs title upward stops at y=75 (root y=75) in full mode and
y=20 (root y=20) in compact mode. Evidence:
`~/.local/share/duris-client-dev/issue-21-baseline/20261025T141955Z-702a15f0-layout`.
The fixture-only addition recorded geometry before runtime edits; screenshots
and the archive are retained there. The old full boundary is reproduced.

The initial 2.4.0 runtime run at
`~/.local/share/duris-client-dev/issue-21-layout/20261025T142308Z-3dc79d6e-layout`
passes layout and restart behavior. Pointer titles/root reach y=24 in both
states, recovering 51 logical pixels in scenic mode. The candidate capture
shows centered panorama cropping and coherent slim rails; the previously
opaque panorama remains behind opaque panels. A first prototype exposed an
initial-footer reference to the removed inset field; it was repaired before
this successful run. It is not acceptance evidence.

Current next steps: finish top-edge interaction/fallback tests and visual
matrix, run the final required suite, inspect Errors views, record source,
asset and payload hashes, publish the focused PR and update this section with
exact delivery/evidence pointers. Minimum Mudlet 4.19.1, native Windows/macOS,
physical DPI/input and live gameplay remain NOT RUN unless explicitly recorded.
No tag, release, merge or deployment is authorized by this implementation pass.
