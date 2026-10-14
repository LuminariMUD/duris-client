# Real Mudlet tests

Run `python3 scripts/mudlet_test.py doctor`, then
`python3 scripts/mudlet_suite.py` from the repository root. See the
[Linux guide](../../docs/LINUX_DEVELOPMENT.md#automated-offline-tests) for tools,
focused scenarios, geometry, review and cleanup commands.

The controller creates disposable offline profiles outside the checkout.
It imports a freshly built candidate before this test-only companion. The
companion feeds real event/text handlers, records outgoing commands and confines
map downloads to a loopback server. It never reads `.env`. Never import it
into a live/player profile. [Fixture provenance](fixtures/README.md) identifies
the server/website revisions and the live-derived regression cases.

`scenarios.json` registers the eleven positive scenarios, three deliberate Lua
failures and three startup faults. The suite's zero exit code means those
automated expectations passed, including normal process cleanup. It does not
approve screenshots. Use the controller's `review` operation after inspecting
the relevant candidate/checkpoint/scenario and Errors-view images.

Every manifest identifies the exact archive SHA-256, source revision/diff,
fixture inputs and environment. ZIP timestamps vary between builds;
`payload_sha256` identifies the same uncompressed filenames and contents.
The package's Lua and assets are unchanged by the companion. The source tree,
controller and input copies retained in each run make failures reviewable.

`test_runner.py` covers prerequisite/isolation failures, stale/partial results,
bounded waits, process ownership, invalid archives, and errors after a fixture
has already passed. The real negative scenarios additionally prove capture of
assertion, asynchronous timer and event-handler errors inside Mudlet.
