# AGENTS.md

Guidance for AI agents working in this repo. `CLAUDE.md` and `GEMINI.md` are symlinks to this file.

## .env
The `.env` file, if relevant, will contain local locations of the MUD server code and MUD website code (MUD website also has a built-in MUD client)

## What this is
A **Mudlet client package** for the MUD *Duris*. Repository: https://github.com/LuminariMUD/duris-client (originally by Arjinius).

## Layout
- `src/` — **the source of truth.**
  - `src/scripts/ArjUI.lua`, `src/scripts/ArjMapper.lua`, `src/scripts/ArjAuto.lua` — the three Mudlet scripts (UI, mapper, automation/aliases).
  - `src/package.xml` — Mudlet XML skeleton. Each `<script>` body is a `@@SCRIPT:<Name>@@` placeholder filled from `src/scripts/<Name>.lua`.
  - `src/config.lua` — package metadata; its `version` line is overwritten at build time.
  - `src/assets/` — files copied into the zip verbatim.
- `VERSION` — the package version. The build writes it into `config.lua` and into `ArjUI.VERSION`.
- `build.py` — assembles the package (stdlib Python only). `python3 build.py --check` only syntax-checks the Lua.
- `duris-client.mpackage` — **build output**, committed so users can download it. Never hand-edit it.
- `README.md` — user-facing install docs. `docs/` — reference material and the ongoing-projects log.
- `docs/DESIGN.md` — interface layout, visual conventions, interactions, architecture, and lifecycle. Keep it aligned with design changes.

## Working on the package
- Edit `src/`, then run `python3 build.py`. Commit the rebuilt `.mpackage` together with the source change.
- Bump `VERSION` (semver `MAJOR.MINOR.PATCH`; rules in `docs/RELEASING.md`) when changing the package. Do not edit `version` in `src/config.lua` or `ArjUI.VERSION` by hand.
- Add a `## <VERSION> - <date>` section to `CHANGELOG.md` for each version.
- Releases: pushing to `master` runs CI, then automatically tags and publishes any unreleased `VERSION` after build and Mudlet checks pass. Do not push tags manually. Steps and retry instructions in `docs/RELEASING.md`.
- Keep XML well-formed; the build validates it. Lua gets XML-escaped automatically, so write plain Lua.
- Requires **Mudlet 4.19.1+** and **GMCP**. Use Mudlet/Geyser APIs; do not introduce external Lua deps.
- GMCP field examples and their provenance are in `tests/mudlet/fixtures/server-gmcp.json` and `tests/mudlet/fixtures/README.md`. `docs/ongoing-projects/mudlet-local-testing.md` records later connection audits; `docs/ongoing-projects/updates-upgrades.md` preserves the original server study.

## Constraints
- Keep the dark-fantasy aesthetic and percentage-based scaling consistent.
- `build.py --check` is syntax only. Use `python3 scripts/mudlet_suite.py` for offline behavior in real Mudlet 5.0+, then inspect its screenshots; see `docs/LINUX_DEVELOPMENT.md`. Live checks use a separate profile. The declared 4.19.1 minimum needs separate manual verification.

## Git
- Commit only when asked. Keep commits small and describe what changed in the XML/Lua.
