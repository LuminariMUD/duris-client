# GMCP interface adoption — v2.6.0

Date: 2026-11-10. Status: **implemented and locally qualified; ready for PR review**.
Branch: `branch/gmcp-interface-adoption`, based on client
`e4f6cc694ec509c9ebc96bfdb5c52e89c3bf43b1`.

This implements chat presentation/links, `Duris.Time`, `Duris.Session`,
`Duris.Combat` and `Char.Items` in the existing Mudlet UI. It follows the
[server handoff](server-interface-handoff.md) and the
[current server contract](https://github.com/LuminariMUD/Duris/blob/79088b9fcddf2e3ef7192b859a0af2cd815966db/docs/network/GMCP.md).
The fresh production-serializer fixtures pin server
`08b98339dbfb6b2541f6647558428673c1735498`; the audited newer server revision
has no intervening changes in the network contract owners. These fixtures use
synthetic characters and isolated dependencies, not live player data.

## Behavior and ownership

- **Negotiation:** one versioned Supports.Add advertises implemented decoders.
  Capability-acknowledged, bounded retries preserve other add-ons' latest
  interests. Time/preparation stay interested; damage events follow the existing
  damageTracker setting; owner items follow GEAR selection. Unchanged or pending
  interests do not produce duplicate subscription requests. Reinstall requests
  fresh snapshots. Teardown cancels local retries without deleting shared socket
  interests whose ownership cannot be established.
- **Time:** the HUD accepts the server hour/phase with lossless revision and
  process checks. It cancels the background time query and ignores competing
  text guesses. Body changes preserve this connection-scoped clock; a new server
  process resets its baseline. Manual HUD clicks still send `time`. Old peers
  retain the bounded text-query fallback.
- **Session:** `(context,generation)` controls once-per-entry initialization.
  Replayed bootstrap and protocol re-enable do not repeat login actions, even
  when legacy bootstrap preceded the first capability acknowledgment. Body and
  process boundaries retire gameplay views, continuations and selector scopes.
  Account/chargen clear the character and reject subsequent stale gameplay
  updates. Process changes resync state without claiming another character entry.
- **Combat:** positive outgoing applied-hit events include secondary victims.
  Scope and decimal sequence checks reject duplicates and stale bodies/processes.
  Structured target and tank state remain independent of self vitals and override
  late combat prompts/death text. Active events do not count legacy rounds/text
  again. Quota removal marks history incomplete instead of silently restarting;
  `ui set damageTracker on` explicitly requests future events. No lost history is
  replayed. Counter reset cannot hide a still-stopped stream. These events do not
  constitute misses, incoming damage, action outcomes or a complete combat log.
- **Owner items:** GEAR stages contiguous pages and publishes a list only at
  completion. It distinguishes known-empty, unavailable and pending views.
  Entire pages are validated before advancing revisions or expiring actions.
  New top-level cycles invalidate nested views and selectors. Item links open
  existing game actions using the opaque selector, or request direct container
  contents; Back returns to the top level. Unseen equipped placeholders have no
  invented selector/condition. Only the latest requested nested view is retained.
  Explicit Get requests coalesce at the server's refill pace; session/scope
  invalidation cancels pending requests. Tokens grant no additional permission
  and never turn into keyword targets after expiry.
- **Chat:** approved non-preserve full-line snapshots retain recipient colors;
  preserve/unprofiled channels use the approved body inside the existing layout.
  Unicode code-point spans and bounded palette/link metadata are decoded before
  rendering literal text. Only HTTP/HTTPS targets become chat links, with Lua
  callbacks rather than executable strings. Invalid/absent snapshots use the
  existing fallback. Tells retain validated frames through deferred window
  creation and history replay. Native MXP help links in the main console remain
  owned by Mudlet's existing protocol and copy/append-buffer path.

The implementation is in `src/scripts/ArjUI.lua`. It adds no Lua dependency,
new panel, backend endpoint, persistent protocol state or alternative action API.
Inventory/equipment, time and combat text paths remain compatibility fallbacks;
WHO and unrelated automation are unchanged. `VERSION` and the dated changelog
advance to **2.6.0**, and `duris-client.mpackage` is rebuilt from source.

## Verification

The Windows working checkout is the source of truth. Real Linux Mudlet testing
uses an isolated native Linux validation checkout containing the same candidate
sources because Linux Git cannot resolve the managed Windows worktree's UNC Git
pointer. Runs record source diffs, fixture hashes, candidate contents, assertion
results, screenshots, Errors views, shutdown and process cleanup. Built archive
payloads are compared entry-for-entry, ignoring only ZIP timestamps.

Commands run include:

```text
python3 build.py --check
python3 build.py
python3 -m unittest discover -s tests/mudlet -p 'test_*.py'
python3 -m unittest discover -s tests/release -p 'test_*.py'
python3 scripts/release.py --output /tmp/duris-client-gmcp-release-2.6.0
python3 scripts/capture_server_gmcp.py --server /home/aiwithapex/projects/duris-item-values-art
python3 scripts/mudlet_suite.py --jobs 2 --root <isolated qualification root>
python3 scripts/mudlet_test.py run --scenario protocol --mudlet <isolated Mudlet executable> --timeout 90
python3 scripts/mudlet_test.py run --scenario protocol-wire --mudlet <isolated Mudlet executable> --timeout 90
git diff --check
```

Lua 5.1/XML and release-payload validation pass, as do **11 controller tests**
and **15 release tests**. Release unit-test publication output is mocked; nothing
was tagged or published. The primary runtime is **Mudlet 5.0.1 / Qt 6.11.1**.
Its AppImage was downloaded from the official Mudlet release and checked against
the published SHA256SUMS. A version-only Xvfb wrapper compensates for that
AppImage lacking Qt's offscreen plugin; runtime tests use normal isolated Xvfb
profiles. The optional newer runtime is **Mudlet 5.1.1 / Qt 6.11.3**.

The `protocol` scenario covers large decimal counters, real link activation,
item action/menu activation, staged/nested/hidden items, stale actions and scopes,
malformed-page rejection, explicit re-entry, hotboot-like process changes,
transport re-enable, full-line/body chat, literal Unicode and incomplete damage
history. `protocol-wire` uses actual Telnet/GMCP framing/decoding and production
serializer records. Their independent synthetic scopes are explicitly rebased
into one loopback entry; duplicated captured hits test deduplication.

The full suite also verifies legacy fallback, maps, group/health ownership,
ship views, spell/preparation behavior, settings, lifecycle and expected failure
semantics. Required final results and reviewed image names are recorded in the
[testing log](mudlet-local-testing.md).

The complete 5.0.1 suite passes **31 expectations** (25 ordinary scenarios and
six intentional failure/isolation cases). Final availability/clock-caption and
stopped-counter closeout changes were verified with fresh runs of `protocol`
(54 assertions), `protocol-wire` (15), and legacy `time` (107); their payloads
match the rebuilt package. They also remove the initial/disconnected clock's
guessed Day placeholder. Full-suite evidence is under
`~/.local/share/duris-client-dev/gmcp-adoption-final-package-20261110/`.
The final focused primary runs are `20261110T145128Z-8bd89af9-protocol`,
`20261110T145128Z-4891da13-protocol-wire` and
`20261110T145128Z-b726b1c1-time` under the normal runs directory. The 5.1.1
new-interface scenario also passes; its exact final run is in the testing log.

## Evidence limits

No real game login, production operation, server source change or deployment was
performed. Loopback record replay is not a booted-server gameplay or native
original-socket copyover journey. A real mouse click invokes the exact captured
URL callback; the OS browser is intercepted in the test rather than launched.
Mudlet **4.19.1** and physical desktop DPI remain unverified.

The full 5.1.1 exploratory run found two existing compatibility failures:
`connections` ship-scroll preservation (`22 -> 26`) and `layout` scenic Panels
pointer activation. Both reproduce on untouched 2.5.3 and pass under the
documented 5.0.1 suite runtime. They were not hidden by weakening assertions or
bundled into this protocol change. The former server-wire failure depended on
the retired background time query; it now issues an explicit interleaved manual
query and preserves the original capture-ordering assertion.

This candidate is prepared for PR review. No release tag is created manually;
the ordinary release workflow applies after review and integration.
