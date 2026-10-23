# Fixture provenance

These files belong to the test companion, never the distributable package.
They exercise actual Mudlet events, text triggers, widgets, aliases and HTTP.
Most scenarios inject events directly. `server-wire` additionally exercises
real loopback Telnet negotiation, GMCP decoding and disconnects in Mudlet.
These tests do not establish production gameplay coverage.

Payload fields were checked on 2026-10-14 against Duris server revision
`d27e2b5ec5431d6489acd6258c264dcb1aeec29a` (`src/core/json_utils.c`,
`src/net/gmcp.c`, `src/cmd/actinf.c`) and website revision
`f5efe2394d0a0ce9cbc99191316449fe266b6d56` for zone map shape.
The information scenario also includes observed live inventory naming and
empty-equipment messages. The map is invented test geography in the production
API's nodes/edges shape; no actual world data is needed for offline tests.

`lowhp` reproduces the original manual fixture. Other scenarios exercise state
transitions, not just fully populated panels. Login querying is suppressed in
ordinary fixtures and separately observed in `login`. `send` is recorded only
in the offline companion. Downloads are restricted to its loopback map server.
The live profile never imports this companion.

`map-colors` uses invented diagnostic glyphs with the actual Duris color
contract, checked on 2026-10-22 against server revision
`ca548bae11cab98490fd5e4e954785630b3a07da`, `src/net/ansi.c`
(`AnsiString::set`, `put_ansi`, `AnsiString::ansi`) and `src/world/map.c`
(`display_map_room`). Combined codes are background first; foreground-only
codes clear the background, background-only codes clear the foreground, and
LF resets both. Real map glyphs include `&=bB ` water followed by `&+g.`
plains: the latter must not inherit the blue background. The scenario checks
rendered character colors in Mudlet, synthetic movement/look GMCP redraws,
and later ordinary console output. It is not a captured live session or a
reconstruction of the report's exact map.

`server-gmcp.json` contains all eleven consumed packages emitted by production
Duris serializers against isolated world/mechanics fixtures. Its provenance
includes the server commit and hashes of the modified source and test harness.
Refresh it after server protocol changes, then run the wire scenario:

```bash
python3 scripts/capture_server_gmcp.py --server /path/to/duris
python3 scripts/mudlet_test.py run --scenario server-wire
```

Generation requires the server's native build dependencies. Ordinary client
tests use the checked-in JSON and require no server checkout. The loopback
server offers GMCP, records Core.Hello/Supports, writes frames in fragments,
and sends populated and empty snapshots plus a custom Telnet-GA prompt. It
never reads credentials or connects to a game server.

`assertion-error`, `timer-error` and `event-error` deliberately fail. A zero
exit code from any of them is a harness regression. Readiness/profile/candidate
failure injection is provided by the controller's `--fault` options.

`profile.xml` is a minimal allowlist of settings exported from the manually
created offline profile. It includes a passive Lua command alias for supported
`installPackage()` calls. Every ordinary run copies it to a new external
configuration root before starting Mudlet; no player profile is copied.

The issue #3 `connections` additions (2026-10-22) are constructed ship cases
checked against `json_build_ship_info()` at server revision
`ca548bae11cab98490fd5e4e954785630b3a07da`: four condition arcs, crew/chiefs,
integer skills and signed modifiers, unsorted numeric weapon slots, damage,
ammo/timer status and cargo invoice/contraband fields. They also intentionally
test omitted fields, unknown maxima, long names, empty lists and replacement.
They do not refresh `server-gmcp.json` or establish a live-game comparison.
