# LuminariGUI audit: what to bring into the Duris client

Audit date: 2026-11-13. Source: `~/projects/LuminariGUI` at `00b738c`
(package 2.0.4.048), compared against durisclient `master` at `73c58ab`
(2.7.0). This is a findings and recommendations record. **Nothing here is
implemented.**

LuminariGUI is a Mudlet package for LuminariMUD. It is MSDP-based, assembled
from XML fragments in `theGUI/src/`, and comes with a large Python tooling
layer. The Duris client already took five of its reference docs (see
[docs/README.md](../README.md#imported-reference-material)). This audit covers
everything else: runtime features, developer tooling, CI and docs.

Path shorthand: **LG** = `LuminariGUI/theGUI/src/`, **DC** = `src/scripts/`,
**DS** = the Duris server checkout (`.env`).

## Summary

Most of LuminariGUI is either MSDP/Luminari-specific or something durisclient
already does better: GMCP chat routing, the server-authoritative mapper,
per-panel persisted layouts, real-Mudlet scenario tests, and the semver release
flow. Some pieces are still worth taking.

| # | Recommendation | Kind | Effort | Server work? |
|---|---|---|---|---|
| R1 | Opt-in sound alerts: low HP, low moves, tells/chat | Feature | M | No |
| R2 | Spell-casting progress indicator in VITALS | Feature | S–M | No (text) |
| R3 | Unread markers on chat channel tabs | Feature | S | No |
| R4 | Group panel: leader marker, class (level when sent) | Feature | S | No (level: maybe) |
| R5 | Richer `ui debug` diagnostic snapshot | Support | S | No |
| T1 | Lua globals guard using `luac5.1 -l`, and require Lua 5.1 | Tooling | S | — |
| T2 | Pin Actions to SHAs, add Dependabot, harden workflows | CI | S | — |
| T3 | Markdown link/anchor checker in CI | Docs | S | — |
| T4 | Forbidden-pattern / resource-ownership lint with fixtures | Tooling | S | — |
| T5 | gitleaks in CI | Security | S | — |
| T6 | luacheck on `src/scripts` (report-only first) | Tooling | M | — |
| T7 | ruff on Python harness; clean-checkout assertion; step summaries | CI | S | — |

Lower-value or blocked ideas are under [Deferred](#deferred). Rejections are
under [Not worth porting](#not-worth-porting).

## Implementation status

Delivered as a stack of pull requests, one group per PR. Rows are updated as
each lands.

| Items | Status |
| --- | --- |
| T1 (globals guard), T3 (link checker), T4 (pattern/ownership lint), dead `duris-v1.png` links | Implemented: `tests/lint/`, run by CI. The `build.py` Lua 5.1 requirement ships with the first runtime PR because `build.py` changes need a `VERSION` bump. |
| T2, T5 | Pending |
| T6, T7 | Pending |
| R3, R4 | Pending |
| R5 | Pending |
| R2 | Pending |
| R1 | Pending |

## Runtime features

### R1. Opt-in sound alerts (M)

**Gap.** DC has no `playSoundFile`/`stopSounds` calls. A missed tell or low
HP while the window is in the background is a real risk in a PK MUD.

**What LuminariGUI does** (`LG/scripts/gui/43_sound_core.xml`,
`44_sound_commands.xml`, `LuminariGUI/docs/SOUND_USAGE.md`):
- **Channels.** Each channel has its own enable, volume (0–100), cooldown
  (0–3600 s), priority and file. A master switch sits above them, and
  everything defaults to off.
- **Low-vitals latch.** A low-vitals alert fires once on crossing below its
  threshold, then stays quiet until the value recovers past a reset level.
  Defaults are HP 25/35% and moves 20/30% (`43_sound_core.xml:28-47, 267-287`).
- **Tagged playback.** Sounds use the table form of `playSoundFile` with a
  tag, so `sound stop` stops only the package's own audio (`:222-298`).
- **Robustness.** File paths are sanitised (`:177-193`), and each playback
  failure is reported only once.
- **Command.** `sound status|on|off|test|stop|volume|cooldown|threshold|file`
  (`44_sound_commands.xml:310-478`). Chat sound plays only when a message
  lands outside the active tab (`LG/scripts/yatco/10_tabbed_chat.xml:238-262`).

**Duris adaptation:**
- **Hooks.**
  - Vitals: the `Char.Vitals` handler (`DC/ArjUI.lua:~3040`). Guard
    `maxHp <= 0`, because vitals can be 0/0 around login.
  - Tells: `handleIncomingTell` (`ArjUI.lua:~2649`).
  - Channel lines: `onCommChannel` (`ArjUI.lua:~3279`).
  - The existing alert banners (scrying, disarm, sanctuary down;
    `ArjUI.lua:~4887-4917`) can become additional channels.
- **Settings.** Use a nested `sound` table in `arjui_settings.json`. The `ui
  set` loader coerces values to booleans (`ArjUI.lua:~4615`), so the sound
  table needs its own read and write.
- **Assets.** Ship the audio files in `src/assets/`. Resolve paths the way
  `findArtwork` does (`ArjUI.lua:182-192`), but check with `io.open`. The
  origin of LuminariGUI's `audio/*.wav|mp3` files is undocumented; confirm
  their licensing or source new ones before shipping.
- **Lifecycle.** Stop tagged sounds on uninstall and in `kill()`.
- **Tests.** Add a scenario for the threshold latch: cross down, stay quiet,
  recover, re-arm.
- **Compatibility.** Verify the table form of `playSoundFile` on 4.19.1. It
  should exist from 4.15 onward, but that is untested.
- **Overlap.** None; no existing plan mentions audio.

### R2. Spell-casting progress indicator (S–M)

**Gap.** DC shows spell *preparation* (`Char.SpellPreparation`,
`ArjUI.lua:~1460-1480`), but nothing while a spell is actually being cast.

**What the server actually prints.** The cast messages are confirmed in DS
`src/net/sparser.c`:
- Start: line 2792, `You start chanting...`.
- Progress: line 3110, `Casting: <spell> ` followed by one `*` per 4 time
  units, repeated each pulse.
- Completion: around line 3301, `You complete your spell...`; psionics
  print `Your mental manipulations become a reality...`.
- Abort: lines 1342/1348/1354, `You abort your spell|mental image|prayer
  before it…`. These differ from LuminariGUI's abort strings
  (`LG/triggers/01_gui.xml:107-111`), so their abort triggers would not match.
- The `Casting:` line prints only when a skill roll passes (`sparser.c:
  3105-3108`), except for some classes, which always see it. Completion or
  abort can therefore arrive with no progress line at all.

**Design.**
- Arm on `You start chanting...` or on an outgoing `cast '…'` (the existing
  `sysDataSendRequest` hook).
- Update the spell name and remaining stars from `Casting:` lines.
- Resolve on complete or abort, then clear after a short delay using
  `ArjUI:after` with a stable timer id.
- Render in VITALS beside the preparation estimate rather than adding a new
  console.
- Do not copy LuminariGUI's code literally: it calls `:title()` on a nil
  spell (`LG/scripts/gui/21_cast_console.xml:58,63,70`) and never clears
  `castingNow` on completion.
- **Server follow-up (optional).** A GMCP cast event would make the
  indicator exact. Raise it under the
  [protocol investigation](protocol-interface-investigation.md), whose
  "spell preparation" item covers memorize/pray, not casting.

### R3. Unread markers on chat channel tabs (S)

**Gap.** Private tell windows already count unread messages
(`ArjUI.lua:~2581-2690`). The NCHAT/ROOM/GUILD/GROUP/TELLS tabs give no
signal when a hidden tab receives a line.

**LuminariGUI** blinks tabs using a perpetual 3 s recurring timer
(`LG/scripts/yatco/10_tabbed_chat.xml:29-60, 265-290`). **Do not copy the
blink.**

**Duris approach.**
- Increment a per-tab count in `onCommChannel` when the tab isn't active and
  the chat panel isn't showing it.
- Clear the count in `switchChatTab`.
- Show it as a gold accent or `(n)` suffix in `updateChatTabStyles`
  (`ArjUI.lua:~3948-3976`).
- Follow the existing reveal/unread rules (DESIGN.md private conversations;
  [plan.md](plan.md), [plan-issue-4.md](plan-issue-4.md)), and respect
  `panelIsVisible`.
- Optionally share R1's chat-sound trigger point.

### R4. Group panel: leader, class, level (S)

**Gap.** `Group.Status.members[]` already carries `rank` (`head`/`front`),
`class` and `level` (fixture `tests/mudlet/fixtures/server-gmcp.json:~570-596`).
`paintGroupRow` (`ArjUI.lua:~3805-3850`) ignores all three.

**LuminariGUI** prints a ♔ leader mark, `[lvl]` and a class code
(`LG/scripts/gui/32_group.xml:84-103`).

**Duris approach.**
- Add a leader glyph to the leader's name.
- Put rank, class and level in the existing row tooltip, so the row does not
  get wider.
- Do not trust `level` yet: the production-generated fixture has `level: 0`
  for every member, so the server may withhold it. Show level only when it
  is non-zero, and confirm against a live server.

### R5. Richer `ui debug` snapshot (S)

**Gap.** `ui debug` (`ArjUI.lua:~6009-6030`) reports only whether 7 GMCP
tables have arrived.

**LuminariGUI's snapshot** (`LG/scripts/gui/99_debug_instrumentation.xml:12-160`)
also reports Mudlet version, OS, package version, window size, profile home,
handler/timer counts and missing assets.

**Duris version.** Add these items:
- Environment: `getMudletVersion()`, `getOS()`, `ArjUI.VERSION`.
- Protocol state: `Duris.Capabilities`, `Duris.Session` state, and the
  last-seen times of `Comm.Channel`, `Combat.Update`, `Quest.Status` and
  `Char.Items`.
- Resource counts: `self.timers`, `eventHandlers` and runtime triggers for
  each script.
- Missing artwork.

Guard every probe with `pcall`, as LuminariGUI does (`:32-60`). This makes
player bug reports self-describing. Do **not** port the always-on `GUI.DEBUG`
tracing wrappers.

### Deferred

- **Gag chat duplicates from GAME OUTPUT (opt-in, M).** LuminariGUI deletes a
  matched line plus the trailing prompt (`LG/scripts/gui/71_delete_line_prompt.xml`,
  `01_preferences.xml:5-22`). DC receives chat via GMCP, so a gag needs a text
  match against the main-window line. Two things need checking on a live
  server first: how the GMCP packet is ordered relative to the text line, and
  how wrapped chat lines behave.
- **Wilderness map legend (S–M).** LuminariGUI's legend
  (`LG/scripts/gui/35_room_info.xml:85-99`) uses Luminari's symbols. A Duris
  legend needs the sector symbol and colour table taken from the server
  source.
- **Room vnum/terrain/coords (S, low value).** `Room.Info` has `num`,
  `coords` and a numeric `terrain`. Showing terrain needs a sector-name table;
  the vnum could go in the room-name tooltip.

### Not worth porting

- **Affect icon grid and mode icons** (`LG/scripts/gui/31_affects.xml`,
  91 PNGs). They are keyed to Luminari's AFFECTED_BY flags. Duris `Char.Affects`
  has no flag affects, and its `icon` field is hard-coded to `"shield"`
  (DS `core/json_utils.c:~1065`). Porting would need new server data and new
  art.
- **Action-economy icons and the PSP gauge.** These are Luminari mechanics
  that Duris doesn't have.
- **MSDPMapper auto-mapper, map stretching, `shift`, map.dat download.** These
  would fight DC's server-authoritative zone layouts. LuminariGUI has no
  speedwalk to borrow.
- **ASCII map boundary-tag capture.** Duris sends `Room.Map` over GMCP.
- **YATCO text-trigger chat routing.** DC's `Comm.Channel` routing is better.
- **Layout presets** (`60_layout_profiles.xml`). The presets are nearly
  identical, and DC's per-panel persisted layout supersedes them.
- **Others:**
  - `hscroll`: it only affects Mudlet's main window, which DC hides.
  - Profile-wide scrollbar QSS: DESIGN.md deliberately keeps system
    scrollbars.
  - `fix gui`/`fix chat`: covered by `ui on/off` and `ui layout reset`.
- **Resource-ownership layer** (`LG/scripts/00_resources.xml`). DC already
  owns timers, handlers and triggers per script, and cleans them up in
  `kill()` and on uninstall. The one raw `tempTimer`, `ArjUI.scanTimer`
  (`ArjUI.lua:~4862`), is already cancelled in `endSession` and teardown
  (`:941`, `:4688`).
- **Numpad bindings.** DC's keypad (`ArjUI.lua:~5622-5640`) is already a
  superset: it adds 0 for flee.

## Tooling, CI and docs

DC's Lua lives in plain `.lua` files, so LuminariGUI's whole extraction and
remapping layer is unnecessary: `extract_embedded_lua.py`,
`remap_lua_diagnostics.py`, `map_generated_line.py` and `format_xml.py`. Any
Lua tool can read `src/scripts/` directly.

DC's runtime testing is already stronger than LuminariGUI's. It runs
real-Mudlet scenarios with a fake GMCP server on every CI run. LuminariGUI
only has a manual Xvfb smoke test plus mock-Mudlet Python tests.

### T1. Lua globals guard (S, highest value for the cost)

This catches a mistyped global read (for example `ArjUi`) or a missing `local`
before runtime. It needs no new dependency: `luac5.1 -p -l` lists `SETGLOBAL`
and `GETGLOBAL`.

- A stdlib test asserts that the global writes are exactly `{ArjUI,
  ArjMapper, ArjAuto}`, and that every global read is in a checked-in
  allowlist of Mudlet/Geyser/stdlib names.
- The audit confirmed today's code is clean: those three globals are the only
  writes, and about 120 API names are read.
- Use LuminariGUI's `tests/test_configs/luacheck_config.lua` list only as a
  reference.
- **Also fix `build.py:56`.** It falls back to `luac5.3`/`luac5.4`, which
  accept `goto`, `//` and bitwise operators that Mudlet's Lua 5.1 rejects. It
  should require `luac5.1` (at least in CI) and assert `_VERSION == "Lua
  5.1"`, as LuminariGUI's CI does.

### T2. Workflow hardening (S)

The current workflows use movable tags (`actions/checkout@v4`,
`upload-artifact@v4` in `ci.yml`, `mudlet-runtime.yml` and `release.yml`),
even though `release.yml` runs with `contents: write`.

- Pin actions to commit SHAs with a version comment, in LuminariGUI's style
  (`.github/workflows/ci.yml`, `security.yml`).
- Add `.github/dependabot.yml` for `github-actions` only.
- Set `persist-credentials: false` in `ci.yml` and `mudlet-runtime.yml`. Not in
  `release.yml`: `release.py` pushes tags.
- Add `timeout-minutes` to the `ci.yml` build job.
- Add PR-only `concurrency` with `cancel-in-progress`. Never apply it to
  release.

### T3. Markdown link checker (S)

Docs here are heavily cross-linked, and AGENTS.md asks for them to stay
aligned. A stdlib checker should check relative paths and heading or
`<a id>` anchors, skip external URLs and `docs/archive/`, and allowlist the
machine-local evidence links in [mudlet-local-testing.md](mudlet-local-testing.md).
This automates LuminariGUI's manual `docs/docs-audit.md` Phase 1.

**It already finds real breakage.** `plan-slim-frame-backdrop.md:36` and
`plan-issue-4.md:139` both link to `src/assets/duris-v1.png`, which no longer
exists.

An earlier pass also reported dead table-of-contents anchors in
`docs/MUDLET_DEVELOPMENT.md`. That was a false positive: the file defines
explicit `<a id>` anchors. The checker must handle those.

### T4. Forbidden-pattern / ownership lint (S)

LuminariGUI has two checks to draw from: its Semgrep rules
(`semgrep/rules/luminari-lua-security.yml`) and its handler audit
(`scripts/analyze_handlers.py`). Port their high-confidence parts as a
stdlib regex lint over `src/scripts/*.lua`. It should fail on:

- `os.execute`, `io.popen`, `loadstring`, `loadfile`, `dofile` or bare `load(`;
- `tempTimer`, `tempTrigger`, `tempAlias` or `tempKey` called with a string
  callback;
- a `registerAnonymousEventHandler`, `tempTimer`, `tempRegexTrigger` or
  `tempAlias` result that is not stored.

All counts are zero today, so this is a regression lock. Ownership in DC means
"the result is stored", not "it goes through a wrapper". Test the lint itself
with positive and negative fixture snippets, as `scripts/test_semgrep_rules.py`
and `semgrep/fixtures/` do.

### T5. gitleaks in CI (S)

The repo is public, and the checkout contains a gitignored `.env` with a test
login. A local gitleaks run over the full history found no leaks.

- Copy LuminariGUI's `security.yml` gitleaks job: a checksum-pinned binary, a
  redaction canary step, a PR-range scan, and a full-history scan on push.
- Copy its `.gitleaks.toml` (`useDefault = true`).
- Optionally add a weekly schedule.

### T6. luacheck (M)

Beyond T1, luacheck catches unused locals and arguments, shadowing and
unreachable code across about 8.7k lines.

- Configure it with `std = "lua51"` (LuminariGUI's config wrongly uses
  `luajit`), globals = the three namespaces, and `read_globals` = the T1
  allowlist.
- Pin luacheck 0.23.0.
- Start report-only and block on errors only, as
  `LuminariGUI/docs/LUA_STATIC_ANALYSIS.md` does. Expect a noisy first
  baseline.
- LuaLS with stubs is optional. LuminariGUI's `stubs/mudlet/4.22/` lacks many
  APIs DC uses (`sendGMCP`, `createMiniConsole`, `yajl`, `getConfig`…), so it
  would need DC-specific stubs.

### T7. Small CI extras (S)

- **ruff.** Run `ruff check --select E9,F` (pinned, CI-only) on `scripts/` and
  `tests/`. It passes today, so it can block immediately. `build.py` stays
  stdlib-only.
- **Clean-checkout check.** End jobs with
  `test -z "$(git status --porcelain --untracked-files=all)"` to prove checks
  don't modify the checkout.
- **Step summaries.** Write release validation results and scenario pass/fail
  counts to `GITHUB_STEP_SUMMARY`.
- **CI docs.** Once T1–T6 land, document blocking versus report-only checks
  and how to reproduce CI locally, modelled on `LuminariGUI/docs/CI.md:12-49`.

### Tooling not worth adopting

- **Auto-incrementing build versions** (`theGUI/package.py`). This conflicts
  with the hand-bumped `VERSION` semver flow that `release.py` enforces.
- **Archiving every build in the repo** (LuminariGUI `Releases/`, about
  36 MB). DC publishes to GitHub Releases with SHA256SUMS.
- **The embedded-Lua extraction and remapping scripts, and XML formatting.**
  DC's Lua is not embedded.
- **LuaCov coverage pipeline.** It measures mock drivers that DC doesn't have.
  Even LuminariGUI sets no coverage threshold.
- **Mock-Mudlet Python test suites.** They would be weaker duplicates of the
  real-Mudlet scenarios.
- **StyLua.** Reformatting would create a huge diff that collides with
  parallel PRs. LuminariGUI itself runs it report-only.
- **Full Semgrep in Docker.** T4 covers its high-confidence rules. Its taint
  rules would be noisy given about 115 `setStyleSheet` calls.
- **dependency-review, pip Dependabot, mypy, hash-locked requirements.** DC has
  no Python dependencies.
- **A CodeQL workflow.** The repository's default code scanning setup may
  already cover this; check the repo settings.
- **LuminariGUI's Xvfb `mudlet.yml`.** DC's `mudlet-runtime.yml` already
  supersedes it.
- **More Mudlet compatibility notes.** DC's `docs/MUDLET_COMPATIBILITY.md`
  already matches LuminariGUI's apart from its scope banner. The real gap is
  Mudlet 5.0.x, which CI runs and which LuminariGUI doesn't cover.

## Suggested order

1. T1, T3 and T4 together: cheap, stdlib-only regression locks. Fix the two
   dead `duris-v1.png` links in the same change.
2. T2 and T5 as one CI-hardening PR.
3. R3 and R4: small UI wins with no risk to the protocol.
4. R5, which helps with triaging R1 and R2 reports.
5. R2 (casting indicator), with an offline scenario that injects the
   `sparser.c` text lines.
6. R1 (sound), after the audio licensing question is answered and the
   4.19.1 `playSoundFile` check is done.
7. T6 and T7 as follow-ups.

Each runtime item needs a `VERSION` bump, a CHANGELOG entry, a rebuilt
`.mpackage` and an offline Mudlet scenario, following AGENTS.md.

## Verification notes

- This was a read-only audit; nothing was run in Mudlet.
- **Checked directly against code and fixtures:**
  - DC has no sound calls.
  - `Group.Status` has `rank`/`class`/`level`, with `level` = 0.
  - The `sparser.c` cast, start and abort lines exist.
  - `scanTimer` is cleaned up.
  - The `duris-v1.png` links are broken, and the `MUDLET_DEVELOPMENT.md`
    anchors are fine.
  - `build.py` has the luac fallback order.
  - Actions use tag pins.
- **Taken from the audit pass and not independently re-run:**
  - The `luac -l` globals inventory.
  - The gitleaks and ruff results.
  - The LuminariGUI line references.
- Line numbers marked `~` are approximate and will drift as `ArjUI.lua`
  changes.
