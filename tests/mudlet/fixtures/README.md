# Fixture provenance

These files belong to the test companion, never the distributable package.
They exercise actual Mudlet events, text triggers, widgets, aliases and HTTP.
They do not establish live transport coverage.

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

`assertion-error`, `timer-error` and `event-error` deliberately fail. A zero
exit code from any of them is a harness regression. Readiness/profile/candidate
failure injection is provided by the controller's `--fault` options.

`profile.xml` is a minimal allowlist of settings exported from the manually
created offline profile. It includes a passive Lua command alias for supported
`installPackage()` calls. Every ordinary run copies it to a new external
configuration root before starting Mudlet; no player profile is copied.
