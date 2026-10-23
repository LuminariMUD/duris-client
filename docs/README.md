# docs/

## Duris client documentation

Proposed SHIP follow-up: [Captain's Table bridge redesign](ongoing-projects/plan-ship-bridge.md)
reconciles `look ship` with the SHIP tab and specifies a graphical hull, helm,
contact plot and complete details ledger. This is a plan, not implemented behavior.
Track [issue #13](https://github.com/LuminariMUD/duris-client/issues/13) on
[branch/issue-13-ship-captains-table](https://github.com/LuminariMUD/duris-client/tree/branch/issue-13-ship-captains-table).

| File | Purpose |
| --- | --- |
| [DESIGN.md](DESIGN.md) | Interface layout, palette, typography, interactions, runtime architecture, state ownership, and design validation. |
| [LINUX_DEVELOPMENT.md](LINUX_DEVELOPMENT.md) | Verified Linux/Mudlet setup, Xvfb screenshots, offline scenarios, live-server testing and visual review. Includes prerequisites and verification limits. |
| [Local Mudlet testing results](ongoing-projects/mudlet-local-testing.md) | Versioned findings, connection audits, real Mudlet scenario results, live integration, evidence locations and remaining coverage limits. |
| [Test suite](../tests/mudlet/README.md) and [fixture provenance](../tests/mudlet/fixtures/README.md) | Offline scenario/controller documentation and server-generated GMCP examples. |
| [RELEASING.md](RELEASING.md) | Package versioning, builds and releases. |
| [Server study and implementation log](ongoing-projects/updates-upgrades.md) | Historical server protocol snapshot and early client improvements; use the later connection audit and fixtures for updated behavior. |
| [lielz port log](ongoing-projects/lielz-port.md) | Adapted display helpers and automation. |
| [Frame artwork](artwork/duris-frame.md) and [README header artwork](assets/header-prompt.md) | Art direction and generation records for the installed frame and the separate README illustration. |

## Imported reference material

Reference material copied from the sibling project **LuminariGUI**
(`~/projects/LuminariGUI/docs/`), a Mudlet UI package for a different MUD.
The files below retain LuminariGUI's architecture and conventions, with scope
notes and navigation corrections. They have **not** been adapted into Duris
implementation guides. Use [DESIGN.md](DESIGN.md) and
[LINUX_DEVELOPMENT.md](LINUX_DEVELOPMENT.md) for this package.

| File | Why it is here | What does NOT apply here |
|---|---|---|
| [MUDLET_COMPATIBILITY.md](MUDLET_COMPATIBILITY.md) | Historical Mudlet 4.19 → 4.22 changes (Qt6, stylesheet, label-callback, protocol-settings, resize events) and a triage checklist. | LuminariGUI's version target and MSDP instructions. Duris declares **4.19.1+**, uses **GMCP**, and runs its offline controller on **5.0+**. |
| [MUDLET_DEVELOPMENT.md](MUDLET_DEVELOPMENT.md) | The "General Mudlet Development Best Practices" section onward: namespaces, Geyser/Qt stylesheets, label callbacks, resize handling, GMCP integration, package lifecycle, error handling. | The "Project Architecture" section at the top (`theGUI/` fragment build system, `build.py`, `package.py`). This repo edits `src/` and assembles `duris-client.mpackage` with the root `build.py`. |
| [MUDLET_SMOKE_TEST.md](MUDLET_SMOKE_TEST.md) | Template for a manual real-Mudlet release checklist and result vocabulary (`PASS` / `FAIL-PACKAGE` / `UPSTREAM-BLOCKED`). | LuminariGUI's checklist items, MSDP steps, and CI job. Duris has its own real-Mudlet suite and screenshot-review procedure. |
| [RESOURCE_LIFECYCLE.md](RESOURCE_LIFECYCLE.md) | Pattern for owning anonymous event handlers and temp timers so package uninstall / profile reset cleans up properly. | The `GUI.registerOwnedHandler` / `GUI.setOwnedTimer` helpers and audit scripts do not exist in this package. |
| [DEBUGGING.md](DEBUGGING.md) | Pattern for a single master debug flag with prefixed console trace lines. | The `GUI.DEBUG` flag and `00_debug.xml` fragment are LuminariGUI-only. Use `ui debug`, `mapper status`, and `mapper debug` here. |

Not copied (LuminariGUI-specific tooling): `CI.md`, `COVERAGE.md`,
`PYTHON_TOOLS.md`, `LUA_STATIC_ANALYSIS.md`, `SOUND_USAGE.md`,
`PROTOCOL_REFERENCE.md` (MSDP for LuminariMUD), changelogs, and
`ongoing-projects/`.
