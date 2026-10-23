# Changelog

Notable changes to the Duris Client Mudlet package. Versions follow [Semantic Versioning](https://semver.org) (`MAJOR.MINOR.PATCH`); see [docs/RELEASING.md](docs/RELEASING.md) for what each part means here. Each version heading must match `VERSION`; the release workflow copies that section into the GitHub Release notes.

## 2.0.0 - 2026-10-22

- Rebuild the dashboard as ten adjustable panels with title/border gestures, named home docking, locking, minimize, hide and maximize actions.
- Add `ui layout`, `ui panel`, fixed Panels and Reset layout controls, and profile-local normalized layout persistence.
- Keep game output visible and preserve scrollback and selected views during layout changes.
- Keep event-driven map paints below a different maximized panel and reveal the latest accepted room on restore.

## 1.4.1 - 2026-10-23

- Preserve unread private tells received while the UI is hidden; opening the conversation reveals and marks them read.

## 1.4.0 - 2026-10-22

- Add `ui set compactHeader on|off`, a saved option that collapses the illustrated header into a dark gradient and gives the recovered height to gameplay panels. Full artwork remains the default.
- Recenter populated zone and wilderness maps when the header or window size changes, preserving map mode, cache and zoom.
- Keep a paused mapper's display frozen during header changes, resize, and UI hide/show.

## 1.3.6 - 2026-10-22

- Fix wilderness map background bleeding by reading Duris combined colors in background/foreground order and clearing old backgrounds on foreground-only terrain.
- Handle background-only map colors, distinguish black from bright black, and reset colors at line and map boundaries.

## 1.3.5 - 2026-10-15

- Replace the old border artwork with a custom obsidian-and-bronze atlas frame, engraved compass details, and a compact DURIS wordmark.
- Remove the "New Duris" heading and keep the frame's interior black for readable game output.

## 1.3.4 - 2026-10-15

- Use a solid black background for the primary MUD text feed and its surrounding panel so incoming text blends with the console.

## 1.3.3 - 2026-10-14

- Advertise all consumed GMCP packages, including maps, quests and ships.
- Clear character, combat, ship and map state and cancel pending actions on logout or disconnect.
- Consume ship navigation and targeting from the server's actual payload fields; keep empty contact lists authoritative.
- Display nested ship armor, hull, weapons, equipment and cargo data.
- Read mapper door state from Room.Info.doors.
- Finish inventory and equipment captures on Telnet prompts, including custom prompts.
- Show complete server quest descriptions without duplicate Ask/Kill prefixes.
- Clear combat on the server's end notification, including bleeding targets.
- Avoid counting buffered text damage again after a GMCP fight ends.

## 1.3.2 - 2026-10-14

- Load the decorative background using platform-compatible asset paths.
- Use Mudlet's native command line as the single input and give the reclaimed space to the output console.
- Display the built package version in the footer.
- Preserve character state and widgets when hiding and showing the UI.
- Remove package aliases, triggers, event handlers and delayed actions on uninstall; clean up map download handlers and bound their waits.
- Keep delayed zone downloads from replacing a newer wilderness map, and report malformed map responses.
- Clear stale maps when a zone cannot load; refresh using wall time and validate nested map fields.
- Let room tooltips work through the player marker and keep them inside narrow maps.
- Show a compact map placeholder until room data arrives.
- Keep large groups readable in a scrolling panel and retain NPC markers on long names.
- Recompute group scrolling when members leave so remaining members stay visible.
- Reset the damage source between fights so text damage works after a GMCP-tracked fight.
- Accept the server's JSON-null combat target when disengaging without raising a Lua error.
- Render a numeric zone ID safely when optional room area text is absent.
- Wrap console text to the available width when resizing.
- Capture inventory items with capitalized names, bare names and grouped counts; finish empty captures at the prompt.
- Clear equipment when the server reports nothing worn, remove Duris color codes from identity text, and refresh STATS on room changes using the player `score` command.

## 1.3.1 - 2026-10-12

- Use Duris naming in the package metadata, UI messages, documentation, and issue forms.
- Point zone-map downloads and world-map/wiki links to `https://duris.sbs`.
- Rename the packaged background to `duris-v1.png` and update the UI's asset paths.
- Point repository and publishing instructions to `LuminariMUD/duris-client` with `origin` as the only remote.

## 1.3.0 - 2026-09-20

New **ArjAuto** script: the automation and utility side of the "lielz scripts" archive, reworked so nothing is hardcoded to one character. Every automatic behaviour is off until `auto <name> on`; toggles, variables, the rescue list, bidscores and login commands persist in `arjauto.json`. Type `auto` for help.

- **Toggles**: autoStand, autoGroup, autoRescue, autoAssist, autoRage, autoWield, autoLoot, autoOre, autoFollow, autoPlay, trapKill, scanReport, eventReport, shipKeys, roller.
- **Variables** (`vars`): target, container, food, weapon, held, door, tank, song, cargo, contra, idscroll, spam, report channel, intervals, roll threshold.
- **Rescue list**: `rescue add|del|group|list|clear`; rescue lag handled with the archive's response lines plus a safety timeout.
- **Combat**: `kt`, `bsh`, `bsht`, bash-by-race shortcuts, `rbsh`/`rbsht`/`bof` rebash after the 14 s bash lag, `fls` flee-stab, `bac` backstab, `uw <item> [target]` hold-and-use.
- **Containers and corpses**: `pcb gcb pab gab lib pi gi grep rrep eat qf rq`, `lc lcb lic dc nlc slc elc wlc`.
- **Movement**: door helpers with the `dd` variable, `ep egh emw ewh enl env`, `sw <dirs>`, `lall`, `sfle`, `fc`, `of`, `rm`.
- **Group**: `castall <spell>`, `vitall`, `virtueall`, `weakest`.
- **Timers**: `spam <cmd>` with `spamon`/`spamoff`, `scan timer on|off`; both only fire while idle and standing.
- **Ship**: `oh os fff ffp ffs ffr ffall`, orders relative to the locked contact (`otf otp ots otr oth otsp`), `jet disem`, farsee `le ln lne lnw ls lse lsw lw`, `ship poll on|off`, `lout on|off`, `shipf/shipn`, `qkcargo`, `qkreload`, Ctrl and Ctrl+Shift hotkeys behind `auto shipKeys on`.
- **Loot split**: `split start|roll|free|scores|set|flush` with persisted bidscores and multi-die rolls.
- **Identify**: `id <item>` recites your `idscroll` and compacts the readout to one line.
- **Epic zones**: `epic report` lists zones seen completed this boot.
- **Login commands**: `login add|list|clear` sent when you enter the game.
- **Plane direction notes**: `dirs eth|astral|air|fire|water|neg`.
- ArjUI's scan summary hands off to ArjAuto for channel reporting; `ui help` mentions `auto`.

## 1.2.1 - 2026-09-20

- Removed the "client-side UI only, no automation" scope statements from the package description, README, and contributor guide. No code changes.

## 1.2.0 - 2026-09-20

Display helpers ported from the community "lielz scripts" collection (`docs/archive/lielz_scripts_04-2024.mpackage`). Everything is client-side display; no gameplay automation was carried over. Details in `docs/ongoing-projects/lielz-port.md`.

- **SHIP tab**: contacts sorted by range and colored by side, heading and speed, captain, max speed, lock-on target, and sailing skill gains. Reads GMCP `Ship.Info`/`Ship.Contacts` when present and the `look contacts` text otherwise. First step toward the ship radar noted in the server study.
- **Damage counter** in the target panel: per-fight total that resets when a kill or experience share arrives, plus a session report with damage per second (`ui damage`, `ui damage reset`, or click the counter). Uses `Combat.Update.round` or `[Damage: N]` lines, never both.
- **Experience notices**: `[+N exp] M to level, about K more like that` from GMCP `exp`/`tnl`. The TNL bar shows the last gain.
- **Scan formatter**: `scan` lines become `[E ] 2  A Drow Elf` with distance and direction colored, followed by a per-direction summary.
- **Alert banners** for sanctuary, hellfire, stone skin, heroism, rage, and war cry dropping; being disarmed, dropping your weapon, disarm results; being scryed; skill improvements; song finished or failed; frost beacons; and tracks.
- **Group panel**: moves percentage per member colored by how spent it is, HP as `cur/max -missing`, and the most hurt player in the room highlighted.
- **Chat timestamps** (`hh:mm`) on every chat line.
- **Numpad movement keys**: 8/2/4/6, 7/9/1/3, `-` up, `+` down, 5 look, `/` scan, 0 flee.
- **Settings**: `ui set` lists six toggles, all on by default and persisted to `arjui_settings.json`. `ui help` lists commands.
- `ui debug` also reports `Ship.Info` and `Ship.Contacts`.

## 1.1.0 - 2026-09-20

Same package as 1.1, re-released to adopt semantic versioning.

- Versions are now `MAJOR.MINOR.PATCH`. The build and the release workflow reject anything else.
- `build.py` creates the output directory when it is missing.

## 1.1 - 2026-09-20

First tagged release.

- Aligned ArjUI with the Duris server's GMCP output (`Char.Status`, `Char.Vitals`, room, group, and combat fields).
- Split the package into editable sources under `src/` with a stdlib-only `build.py` assembler.
- Renamed the build output to `duris-client.mpackage`.
- Added GitHub Actions: CI syntax-checks and builds on every push; pushing a `v*` tag publishes a release with the package attached.
- Refreshed the README with install steps, an architecture overview, and troubleshooting.

## 1.0

Original Arjinius Client package by Arjinius, as uploaded to the repository.
