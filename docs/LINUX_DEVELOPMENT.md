# Linux development and visual testing

This guide describes how to develop and test the Duris **Mudlet package** in a
real Linux Mudlet process, including on a machine without a physical display.
Use repeatable offline scenarios for visual changes, a separate live profile
for server integration, and a final check on the player's desktop.

## Verification status and supported versions

Research verified on **2026-10-12**, against this repository at `e4a48a3`
and upstream Mudlet **5.0.1**, tag commit
[`592821c8c0c6a638be87a9de5995b8a278f2e4b4`](https://github.com/Mudlet/Mudlet/tree/592821c8c0c6a638be87a9de5995b8a278f2e4b4).

| Claim | Evidence and limits |
| --- | --- |
| Mudlet can run under Xvfb on Linux. | The [upstream Linux Lua test job](https://github.com/Mudlet/Mudlet/blob/592821c8c0c6a638be87a9de5995b8a278f2e4b4/.github/workflows/build-mudlet.yml#L670) launches the real client with `xvfb-run`. This proves the approach is used upstream, not that this package has passed visual tests. |
| A virtual display supports screenshots and input automation. | [xvfb-run](https://manpages.debian.org/trixie/xvfb/xvfb-run.1.en.html), [xdotool](https://manpages.debian.org/trixie/xdotool/xdotool.1.en.html), and [ImageMagick import](https://manpages.debian.org/trixie/imagemagick-7.q16/import.1.en.html) document the required operations. |
| Offline startup and a separate configuration root are available. | Mudlet's [CLI documentation](https://wiki.mudlet.org/w/Command_line_options), [argument parsing](https://github.com/Mudlet/Mudlet/blob/592821c8c0c6a638be87a9de5995b8a278f2e4b4/src/main.cpp#L414), and [configuration resolution](https://github.com/Mudlet/Mudlet/blob/592821c8c0c6a638be87a9de5995b8a278f2e4b4/src/utils.h#L226) confirm the behavior below. `--offline` and profile-root support through `XDG_CONFIG_HOME` require **Mudlet 5.0+**. |
| Client handlers can consume synthetic data. | Mudlet documents [GMCP tables](https://wiki.mudlet.org/w/Manual:Supported_Protocols#GMCP), [local events](https://wiki.mudlet.org/w/Manual:Event_Engine#Raising_a_custom_event), and [feedTriggers](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#feedTriggers). Local injection bypasses network negotiation and JSON decoding. |

The package's declared minimum remains **Mudlet 4.19.1**. The setup examples
below target **5.0.1**; a successful run there does not prove compatibility with
4.19.1. Test the minimum version separately when making compatibility claims.
On 4.x, use a dedicated profile opened through the connection dialog's offline
option and, if isolation is needed, the documented
[portable mode](https://wiki.mudlet.org/w/Portable_App). Do not assume the 5.x
CLI or configuration-root behavior exists in older versions.

At documentation verification on 2026-10-12, the workspace was Ubuntu 26.04.1
x86_64, with no active `DISPLAY` or `WAYLAND_DISPLAY`. Python 3 and `xauth` were available; Mudlet,
Xvfb, Openbox, xdotool, ImageMagick and a Lua compiler were absent from `PATH`.
An isolated Lua 5.1 compiler was subsequently extracted into a temporary
directory to validate examples and the package build, without installing it
system-wide. Graphical execution had not yet been attempted at that time.

On **2026-10-14**, the native Mudlet 5.0.1 build and Linux tools were installed.
The isolated offline profile, actual package import, low-health fixture,
1280×720 / 1366×768 / 1920×1080 captures, scale factor 2, normal shutdown and
profile reopen were exercised. The background-path defect was confirmed and
other setup/layout findings were recorded in the
[local testing execution log](ongoing-projects/mudlet-local-testing.md#execution-log--2026-10-14-setup).
Live-server, map-data, full scenario-matrix, minimum-version and player-desktop
checks remain unrun; the setup smoke checks do not establish those results.

Documentation checks were rerun after setup: all 15 Bash blocks parsed with
`bash -n`,
the Lua fixture and package scripts passed Lua 5.1 syntax checks, relative file
links resolved, and a temporary package build passed archive integrity,
assembled-XML and version-metadata checks. These are static/build results,
not graphical or live-server results.

This document supplies a setup procedure and a starter scenario. It does not
add a fixture runner or a visual CI job. Current
[repository CI](../.github/workflows/ci.yml) checks Lua syntax and builds the
archive; the older [smoke-test reference](MUDLET_SMOKE_TEST.md) describes another
project's tooling.

The [local Mudlet testing plan](ongoing-projects/mudlet-local-testing.md)
tracks the work to execute this procedure, build repeatable runtime coverage,
investigate findings, and add offline CI.

## This workstation's prepared setup

The following helpers exist locally at
`/home/staging/.local/share/duris-client-dev`; they are not a committed fixture
runner or CI suite. The generic installation procedure below remains the
reference for other machines.

Start the saved **Duris-Visual** profile in a virtual desktop:

```bash
/home/staging/.local/share/duris-client-dev/desktop.sh
```

The launcher uses the isolated configuration root, offline mode, scale 1 and a
2048×1200 Xvfb screen, leaving space for a 1920×1080 window plus decorations.
It keeps a separate log directory for each desktop session and rejects a
second concurrent desktop using the same configuration. In Mudlet's package
command line, enter `dev lowhp` to run the saved fixture. Close Mudlet normally
to save and stop the desktop; the launcher cleans up Openbox, Xvfb and the
authentication file.

For commands from another shell while that desktop is running:

```bash
/home/staging/.local/share/duris-client-dev/on-desktop.sh \
  xdotool search --onlyvisible --class mudlet
/home/staging/.local/share/duris-client-dev/on-desktop.sh \
  import -window root /home/staging/.local/share/duris-client-dev/artifacts/desktop.png
```

`on-desktop.sh` shares the running session's display and authentication. Use
the returned main-window ID with the geometry/capture commands later in this
guide. For a scale-2 session, close the existing desktop first, then run:

```bash
QT_SCALE_FACTOR=2 MUDLET_SCREEN=4096x2400x24 \
  /home/staging/.local/share/duris-client-dev/desktop.sh
```

The prepared profile uses DejaVu Sans Mono 12, GMCP on, automatic reconnect
off, all ArjAuto toggles off, and no login credentials. The starter UI is
hidden. The unrelated default `generic_mapper` package was removed after it
reacted to fixture text; ArjMapper remains installed. The source build is at
`~/.local/share/duris-client-dev/artifacts/duris-client.mpackage`, and the
initial evidence is under `artifacts/setup-20261014T184545Z/`. A future build
should use a new artifact directory to preserve this baseline.

No VNC listener or live-server connection was configured. Follow the optional
viewer and live-test sections when those are needed.

## Testing layers

| Layer | Use it for | Evidence to retain |
| --- | --- | --- |
| Lua syntax and package build | Syntax, version injection, XML and archive structure | Command output and package hash |
| Offline Mudlet scenarios | Layout, fonts, gauges, tabs, long text, resize behavior | Actual screenshots, scenario inputs, Lua errors |
| Live Duris session | GMCP negotiation, received fields, text triggers, commands, reconnects and map downloads | Observed actions, relevant events and errors |
| Player desktop | OS font rendering, actual DPI, keyboard behavior and usability | Desktop OS/Mudlet version and screenshots |

Screenshots must come from Mudlet rendering this package. The browser client
in DurisWeb uses a different renderer and cannot validate Geyser/Qt layout.
Mocked Lua tests can check logic, but cannot establish that widgets look correct.

## Install the Linux tools

For Ubuntu/Debian, install the build and virtual-display tools:

```bash
sudo apt-get update
sudo apt-get install python3 lua5.1 xvfb xauth openbox xdotool \
  imagemagick fonts-dejavu-core fontconfig curl ca-certificates
```

Choose a Mudlet build deliberately. The workspace's configured apt indexes did
not list a `mudlet` candidate. The official
[5.0.1 release](https://github.com/Mudlet/Mudlet/releases/tag/Mudlet-5.0.1)
provides an Ubuntu 26.04 amd64 package, an x64 AppImage archive, and other
platform builds. For **Ubuntu 26.04 amd64 only**, this pins the native package
and checks the SHA-256 published in the release metadata:

```bash
MUDLET_DOWNLOAD_DIR=$(mktemp -d -t duris-mudlet-download.XXXXXX)
(
  set -eu
  cd "$MUDLET_DOWNLOAD_DIR"
  curl --fail --location --output Mudlet-5.0.1-ubuntu-26.04-amd64.deb \
    https://github.com/Mudlet/Mudlet/releases/download/Mudlet-5.0.1/Mudlet-5.0.1-ubuntu-26.04-amd64.deb
  printf '%s  %s\n' \
    '6ea43609e9d043e9272b67ddb356ba8b33894682453ddfb4d61c0406e5dc8b25' \
    'Mudlet-5.0.1-ubuntu-26.04-amd64.deb' | sha256sum --check -
  sudo apt-get install ./Mudlet-5.0.1-ubuntu-26.04-amd64.deb
)
```

On other distributions, choose a matching release asset or follow
[Mudlet's compilation guide](https://wiki.mudlet.org/w/Compiling_Mudlet).
For an AppImage, extract the downloaded `.tar`, mark the AppImage executable,
and use its absolute path wherever this guide says `mudlet`. If FUSE is
unavailable, AppImage documents `--appimage-extract` followed by
`squashfs-root/AppRun`; extract in a tools directory outside the repository.
See [AppImage FUSE troubleshooting](https://docs.appimage.org/user-guide/troubleshooting/fuse.html).

## Prepare a build and an isolated profile directory

Run from the repository root. Keep profiles, logs and test builds outside the
checkout:

```bash
export MUDLET_DEV_ROOT="$HOME/.local/share/duris-client-dev"
mkdir -p "$MUDLET_DEV_ROOT/config/mudlet/profiles" "$MUDLET_DEV_ROOT/artifacts"
command -v luac5.1
luac5.1 -v
luac5.1 -p src/scripts/ArjUI.lua src/scripts/ArjMapper.lua src/scripts/ArjAuto.lua
python3 build.py --check
python3 build.py -o "$MUDLET_DEV_ROOT/artifacts/duris-client.mpackage"
sha256sum "$MUDLET_DEV_ROOT/artifacts/duris-client.mpackage"
```

Stop if the compiler check fails. In the current [build script](../build.py),
a missing compiler produces a warning and a successful return value;
`--check` then prints `Lua OK`. That output alone is not evidence of a syntax
check. Prefer Lua **5.1**, as used by repository CI, over the build script's
fallback to a later language version. Even with a compiler, no Geyser or
Mudlet API calls execute during this check.

On Mudlet 5.x, creating `config/mudlet/profiles` explicitly selects the test
configuration root when it competes with an existing default profile folder.
A `portable.txt` beside the executable or in `~/.config/mudlet` takes
precedence: inspect existing portable configuration before using this recipe.
Verify the selected profile path in Mudlet with `getMudletHomeDir()`.

The repository's optional `.env` records `MUD_SERVER_PATH` and
`MUD_WEBSITE_PATH` for finding sibling source trees. Neither `build.py` nor
this package loads that file automatically. Those paths do not configure a
Mudlet connection or start a server. Keep `.env` local and ignored.

## Start a persistent virtual desktop

All GUI, input and screenshot commands must share the same `DISPLAY` and
`XAUTHORITY`. Start an interactive Bash session inside `xvfb-run`:

```bash
env XDG_CONFIG_HOME="$MUDLET_DEV_ROOT/config" \
  QT_QPA_PLATFORM=xcb QT_SCALE_FACTOR=1 \
  xvfb-run --auto-servernum \
  --server-args='-screen 0 1920x1080x24 -dpi 96 -nolisten tcp' \
  bash --noprofile --norc
```

In that new shell, start a window manager, then Mudlet:

```bash
openbox >"$MUDLET_DEV_ROOT/artifacts/openbox.log" 2>&1 &
MUDLET_WM_PID=$!
mudlet --version
mudlet --help
mudlet --offline >"$MUDLET_DEV_ROOT/artifacts/mudlet.log" 2>&1 &
MUDLET_APP_PID=$!
```

Xvfb supplies the screen; Openbox handles window placement and activation.
Qt's `xcb` backend puts Mudlet on that X11 display. On a normal Linux desktop,
Mudlet can instead use the existing desktop display; Xvfb is for remote or
repeatable screen setups.

### First-run profile setup

Use screenshots and input automation, or the optional VNC viewer below, to
complete these steps. If Mudlet's first-run tutorial appears, select
**Skip - show me the games list** to reach the profile dialog.

1. Create a dedicated profile named **Duris-Visual**. Use a loopback host
   (`127.0.0.1`) with an unused local port and select the dialog's **Offline**
   button. Leave automatic login and automatic reconnect disabled. `--profile` selects an
   existing saved profile; this guide does not assume it creates one.
2. Enable GMCP in the profile preferences. Choose and record the font and
   font size. Mudlet 5.0.1 adds a starter interface; run `baseui hide` if it
   appears, so it does not compete with ArjUI. This behavior is described in
   the [Mudlet interface manual](https://wiki.mudlet.org/w/Manual:Mudlet_User_Interface#Commands).
3. Open Package Manager (`Alt+O`) and install the absolute path to the build
   in `$MUDLET_DEV_ROOT/artifacts/duris-client.mpackage`. The installed package
   name is **Arjinius Client**. Wait for its UI and delayed mapper setup.
4. Open Mudlet's Errors view and check for Lua errors. Save the profile,
   close Mudlet normally, and wait for the process to finish.

Subsequent starts from the same virtual-desktop shell can use:

```bash
mudlet --profile=Duris-Visual --offline \
  >"$MUDLET_DEV_ROOT/artifacts/mudlet.log" 2>&1 &
MUDLET_APP_PID=$!
```

`--offline` prevents startup game connections; it does not prevent scripts
from downloading HTTP resources or subsequently connecting. Keep visual
fixtures in this disconnected profile and live tests in another profile.

### Optional interactive viewing

Install `x11vnc` if a human needs to see and control this virtual desktop:

```bash
sudo apt-get install x11vnc
```

Inside the virtual-desktop shell, create its password interactively and start
a localhost listener:

```bash
x11vnc -storepasswd "$MUDLET_DEV_ROOT/vnc.pass"
x11vnc -display "$DISPLAY" -auth "$XAUTHORITY" \
  -localhost -rfbport 5901 -forever -shared \
  -rfbauth "$MUDLET_DEV_ROOT/vnc.pass" \
  >"$MUDLET_DEV_ROOT/artifacts/vnc.log" 2>&1 &
MUDLET_VNC_PID=$!
```

From the viewing workstation, forward port 5901 over SSH to this machine,
then point a VNC viewer at `127.0.0.1:5901`. Substitute the actual SSH account
and hostname:

```bash
ssh -N -L 5901:127.0.0.1:5901 user@development-host
```

This viewing channel is optional; an agent can inspect captured PNGs instead.
See the [x11vnc documentation](https://manpages.debian.org/trixie/x11vnc/x11vnc.1.en.html).

## Exercise a repeatable offline scenario

Mudlet stores received protocol data in `gmcp` and raises events such as
`gmcp.Char.Vitals`. For visual tests, set the table first and raise the event
second. `sendGMCP()` sends toward the server and is not a way to simulate an
incoming event. `feedTriggers()` exercises text processing; `echo()` alone
does not exercise incoming text triggers.

The example below is a **manual starter fixture**, reviewed against
[ArjUI handlers](../src/scripts/ArjUI.lua) and the server's
[`json_utils.c`](https://github.com/LuminariMUD/Duris/blob/6b9845556ea6fcd7e3ef29b911c83906933de181/src/core/json_utils.c).
Its Lua syntax can be checked independently, but rendering must be verified
inside Mudlet. Create an enabled alias in the **Duris-Visual** profile,
outside the installed package, with pattern `^dev lowhp$` and this Lua body:

```lua
assert(getProfileName() == "Duris-Visual", "Use the visual test profile")
local host, port, connected = getConnectionInfo()
assert(connected == false, "Disconnect before injecting fixtures")
assert(ArjUI and ArjUI.main and ArjUI.state, "Load Arjinius Client first")

-- Suppress this fixture's Char.Status-triggered login/time query.
-- Restart the profile before testing actual login behavior.
ArjUI.initialDataRequested = true
gmcp = gmcp or {}
gmcp.Char = gmcp.Char or {}
gmcp.Char.Status = {
  name = "VisualTester", level = 25, class = "Psionicist", race = "Human",
  alignment = "good", guild = "", title = "Visual test"
}
raiseEvent("gmcp.Char.Status")

gmcp.Char.Vitals = {
  hp = 150, maxHp = 1000, mana = 350, maxMana = 500,
  move = 60, maxMove = 120, exp = 10000, tnl = 5000,
  platinum = 1, gold = 2, silver = 3, copper = 4,
  position = "standing", usesMana = true
}
raiseEvent("gmcp.Char.Vitals")

gmcp.Group = gmcp.Group or {}
gmcp.Group.Status = {
  size = 2, maxSize = 8,
  members = {
    {name = "VisualTester", hp = 150, maxHp = 1000,
     move = 60, maxMove = 120, position = "standing", rank = "head",
     isNpc = false, inRoom = true},
    {name = "A deliberately long companion name", hp = 900, maxHp = 1000,
     move = 100, maxMove = 120, position = "sitting", rank = "back",
     isNpc = false, inRoom = true}
  }
}
raiseEvent("gmcp.Group.Status")
feedTriggers("Visual test: plain incoming text.\n")
ArjUI:renderAll()
```

Run `dev lowhp` in the package's command line. Expected observations: the
character identity updates, health is 15%, mana is 70%, movement is 50%, the
group panel has two members, and the incoming text appears in the console.
Inspect the long name for clipping or overlap and check the Errors view.
The connection assertion uses the documented third result of
[`getConnectionInfo()`](https://wiki.mudlet.org/w/Manual:Networking_Functions#getConnectionInfo).

Extend scenarios with source-accurate room, affects, combat, chat and ship
payloads. Reset/reopen the profile between independent scenarios: fields,
timers, caches and saved settings can survive individual UI updates.
Use the [server study](ongoing-projects/updates-upgrades.md) as a field-name
reference, while checking current server code when behavior differs.

Two package behaviors affect offline tests:

- `ArjUI:onCharStatus()` calls `onLoginDetected()`, which schedules a `time`
  command. The example suppresses that query; it therefore does **not** test
  login behavior. Fresh profiles default ArjAuto toggles to off, but copied
  profiles may restore automation and login commands from `arjauto.json`.
- `ArjMapper:processRoom()` can fetch missing zone data from the website.
  A room fixture needs known map data or an explicitly recorded network
  dependency. The starter fixture above does not inject rooms. A future
  offline map runner should supply fixed map responses as well as GMCP.

Table/event injection tests client handlers and rendering, not the Telnet
transport, GMCP negotiation, JSON parsing, timing or completeness of real
server output. Plain text logs also cannot replace GMCP payloads.

## Capture and compare visual results

In the same virtual-desktop shell, list visible Mudlet windows and identify
the main window rather than the editor, connection dialog or a popup:

```bash
timeout 20s xdotool search --sync --onlyvisible --class mudlet
for MUDLET_WINDOW_ID in $(xdotool search --onlyvisible --class mudlet); do
  printf '%s: ' "$MUDLET_WINDOW_ID"
  xdotool getwindowname "$MUDLET_WINDOW_ID"
done
read -r -p 'Main Mudlet window ID: ' MUDLET_WINDOW_ID
xdotool windowactivate --sync "$MUDLET_WINDOW_ID"
xdotool windowsize --sync "$MUDLET_WINDOW_ID" 1366 768
xdotool getwindowgeometry --shell "$MUDLET_WINDOW_ID"
```

After layout updates settle and dialogs are closed, capture the window:

```bash
import -window "$MUDLET_WINDOW_ID" "$MUDLET_DEV_ROOT/artifacts/lowhp-1366x768.png"
import -window root "$MUDLET_DEV_ROOT/artifacts/desktop.png"
```

On ImageMagick installations without the `import` compatibility command, use
`magick import` with the same arguments. Root captures include popups and the
window manager. Inspect the PNG itself; creating an image file is not a pass.
Avoid capturing login passwords or unrelated live chat in shared artifacts.

For input automation, activate the window, locate the target from a current
screenshot, and use `xdotool mousemove --window ID X Y click 1`. Type only
after confirming focus is in the expected command line. Coordinate scripts
must be revisited after resizing; keystrokes sent to the wrong dialog do not
exercise the intended control.

Use the same Mudlet/Qt version, fonts, profile settings, locale, window size,
map data and input sequence for before/after captures. Record actual geometry
because a window manager can constrain a requested size. The package requests
fonts including **Consolas**, which may resolve to a different font on Linux;
record `fc-match Consolas` and the chosen console font. Identical screenshot
pixels across Linux, Windows and macOS are not an appropriate requirement.

Recommended visual coverage:

| Scenario | Check |
| --- | --- |
| Empty profile and solo character | All panels initialize; input and output remain usable |
| Full, low and zero health; mana user and non-user | Gauge proportions, labels, colors and visibility |
| Solo, two-member and full group | Long names, weakest-member highlight, rows and scrolling |
| Long room/area names; many NPCs, items and players | Wrapping, clipping, exits and context menus |
| Combat start, updates and end | Target clearing, tank prompt handling and damage display |
| Every information/chat tab; long affects and ship contacts | Active styles, overflowing content and readable text |
| Zone and wilderness maps | Map source readiness, current location, zoom and tooltip placement |
| Resize and reopen | No overlaps, hidden controls, stale widgets or duplicate output |

Capture at least 1280×720, 1366×768 and 1920×1080 where the window manager
permits. Repeat a representative scenario with `QT_SCALE_FACTOR=2`, restarting
Mudlet to apply it and increasing the Xvfb screen if needed. Qt documents this
as a way to test scaling without high-DPI hardware; physical screen pixels and
Qt logical geometry differ at higher scale factors.
See [Qt high-DPI testing](https://doc.qt.io/qt-6/highdpi.html#testing).

Confirmed in the 2026-10-14 Linux run:
`ArjUI:applyBackground()` converts `/` to `\` before `io.open()`. Ordinary
Linux asset paths fail the existence check and select the gradient fallback.
Runtime inspection found the installed asset readable through its Linux path
and confirmed the fallback stylesheet. See **LINUX-001** in the
[execution log](ongoing-projects/mudlet-local-testing.md#execution-log--2026-10-14-setup).
The decorative background check fails; the package has not yet been changed
to resolve it.

## Test a live server separately

Create **Duris-Live-Test** in the isolated configuration root. Use the
operator-confirmed Telnet/TLS hostname, port and test character. The website
URL used for map downloads is not evidence of the game listener's port.
Do not infer a running server from a local source checkout.

1. Start with the profile offline, install the same candidate package, enable
   GMCP and review `auto` settings and stored login commands. Keep visual
   fixture aliases out of this profile.
2. Connect intentionally with Mudlet's connection controls and log in. Check
   actual `Char.Status`, `Char.Vitals` and `Room.Info` reception with Mudlet's
   Debug view and the package's `ui debug` command.
3. Exercise room transitions and selected commands appropriate to the test
   character. Check both server responses and the resulting widgets. Use
   `mapper status` and `mapper debug` when investigating map behavior.
4. Cover group, affects, combat and ships when those states are available;
   record unavailable scenarios as **NOT RUN**. Some data, including tank
   tracking and inventory/equipment captures, depends on text as well as GMCP.
5. Disconnect and reconnect. Confirm initial data returns and event handlers
   do not duplicate output. Review the Errors view, then close the profile.

A dedicated development Duris instance is useful for repeatable game states
if one is available. Follow that server repository's own environment and
startup instructions; this client guide does not start or modify a server.
Complete the relevant integration checks against the intended live endpoint
before claiming live compatibility. No live connection was attempted during
this documentation work.

## Iterate and record results

For each candidate: edit `src/`, build to the artifacts directory, load the
candidate package, run the chosen scenarios, inspect screenshots and errors,
then perform the relevant live and desktop checks.

For a trustworthy replacement test, uninstall **Arjinius Client**, save and
close the test profile, then reopen offline and install the new archive.
Restart after installation for a clean startup check. A fresh disposable
profile is preferable when investigating persistence or resource leaks.
`ui off` / `ui on` rebuilds the current in-memory UI; it does **not** reload
edited source files or prove complete teardown of all three package scripts.
Directly calling `dofile()` on changed scripts is not the documented baseline.

Before committing package changes, follow [AGENTS.md](../AGENTS.md) and
[RELEASING.md](RELEASING.md): update the version and changelog as required,
build the root `.mpackage`, and include it with the source changes.
Documentation-only changes do not change the package version.

Record each test run with:

- Source commit plus any uncommitted diff, `VERSION`, and package SHA-256.
- OS, Mudlet/Qt version, installation source, fonts, scale and window geometry.
- Profile setup, scenario inputs and map/network dependencies.
- Expected and observed results, screenshots and relevant Lua errors.
- Per-scenario status: **PASS**, **FAIL**, **BLOCKED** (with reason), or
  **NOT RUN**. Missing tools or login access are not passes.

Close Mudlet normally to save the test profile. After it has exited, stop the
optional VNC process and window manager, then exit the virtual-desktop shell:

```bash
wait "$MUDLET_APP_PID"
if [ -n "${MUDLET_VNC_PID:-}" ]; then kill "$MUDLET_VNC_PID"; fi
kill "$MUDLET_WM_PID"
exit
```

`xvfb-run` cleans up its X server and temporary authentication file when its
child shell exits. Keep the test profile and artifacts for the next run.

## Troubleshooting

| Symptom | Investigation |
| --- | --- |
| `could not connect to display` | Run Mudlet and capture commands inside the same Xvfb session; preserve `DISPLAY` and `XAUTHORITY`. |
| Qt platform-plugin failure | Inspect `mudlet.log`; confirm `QT_QPA_PLATFORM=xcb`, matching distro dependencies and the selected Mudlet build. Use [`QT_DEBUG_PLUGINS=1`](https://doc.qt.io/qt-6/deployment-plugins.html#debugging-plugins) for a diagnostic launch. |
| Default/player profiles appear | Check `portable.txt`, selected `XDG_CONFIG_HOME`, the explicit `mudlet/profiles` directory and `getMudletHomeDir()`. |
| Blank or unrelated screenshot | Confirm the process is alive, select the correct window, close modal dialogs and wait for profile/package initialization. |
| Unexpected extra dock or captured chat | Check whether Mudlet's starter UI is active; use `baseui hide` in the test profile. |
| Missing artwork or changed typography | Inspect the Linux asset-path issue above, installed assets and font substitution before changing layout measurements. |
| Empty panels despite a successful build | Check Lua errors, package installation and received/injected events. Syntax and XML checks do not exercise handlers. |
| Map fails offline | Check whether the scenario supplied the zone data; `--offline` does not supply or disable HTTP map downloads. |
| Lua error absent from terminal log | Inspect Mudlet's Errors view; application stdout/stderr is not a complete capture of script errors. |

Future automation should add explicit profile bootstrap, versioned fixtures,
readiness signals, error capture, screenshot review and bounded shutdown.
Upstream's Busted/self-test environment variables belong to its own test
harness; copying them into this repository does not create Duris UI tests.
