# Server interface handoff for client #26

The first server delivery provides time, lifecycle, combat target/tank and applied
outgoing damage, plus owner inventory/equipment. It is a useful subset of
[client #26](https://github.com/LuminariMUD/duris-client/issues/26).
Server [#542](https://github.com/LuminariMUD/Duris/pull/542),
[#544](https://github.com/LuminariMUD/Duris/pull/544),
[#545](https://github.com/LuminariMUD/Duris/pull/545) and
[#546](https://github.com/LuminariMUD/Duris/pull/546) are merged;
[#547](https://github.com/LuminariMUD/Duris/pull/547) supplies owner items.
The captured server [wire contract](https://github.com/LuminariMUD/Duris/blob/0c580ba4453f670e75b300393f909ebd3ae58dcd/docs/network/GMCP.md)
owns the exact fields and limits. PR availability does not establish deployment.

## Source selection

Advertise the versions the client implements with `Core.Supports.Set/Add`.
Include `Duris.Capabilities 1`, `Duris.Time 1`, `Duris.Session 1`,
`Duris.Combat 1` and `Char.Items 1` as those handlers are adopted.
`Duris.Subscribe` replaces the interest array: keep Time/Combat only while
wanted, and add Items when its panel is interested. Session is control and does
not need Subscribe. Support alone never opens an item panel subscription.
Use `Duris.Capabilities.active` to invalidate unavailable new stream state.
Older servers keep the existing text fallback; silence from an unchanged stream
is not failure. Choose a single source for each value or event.

- **Time:** `Duris.Time` supplies hour/phase on entry, re-enable and changes.
  Use it to replace background `time` requests on supporting servers.
- **Session:** key once-per-entry work by `(context,generation)`. Repeated
  negotiation/bootstrap is the same entry. Clear body views on `bodyRevision`
  changes, including switch/morph; process changes reset revision/sequence
  baselines after hotboot. Account/chargen have `character:null`.
- **Combat state:** use `Combat.Update.target` and `.tank`, including explicit
  null clears. A missing tank field on older servers needs fallback. Keep self
  HP exclusively on `Char.Vitals`; target and tank have separate percentages.
  Disable prompt/death text overwrites when the structured state owns the view.
- **Damage:** `Duris.Combat` is an outgoing positive applied-hit event, including
  secondary victims. `critical:null` means unknown. It is not misses, incoming
  damage, action success or a complete combat log. Active subscribers receive no
  duplicate legacy `Combat.Update.round`. On quota exhaustion Capabilities
  removes this interest; mark history incomplete and retain appropriate fallback.
  Explicit resubscription restarts future events without replay.
- **Items:** stage contiguous `Char.Items.List` pages per location/revision.
  Replace only on `complete:true`. `available:false` invalidates a view;
  `available:true,items:[],complete:true` means known-empty visible contents.
  A new top-level revision, body/process boundary or stream invalidation discards
  stale nested staging and selectors. Keep all identity/revision/sequence values
  as strings. Selectors are opaque command targets, never template/global IDs.
  `Char.Items.Get []` resyncs top-level inv/eq. After both finish,
  `Char.Items.Get ["<selector>"]` requests one container's direct contents; its
  response location is that selector. One latest request is retained. Preserve
  native access refusal; a token grants no permission and expires on mutation.

## Existing packets can remove additional scraping

- Use `Ship.Info`/`Ship.Contacts` while a working ship stream is available, and
  suspend redundant optional `look contacts` polling. Enemy-ship scan details
  still need their own authorized result.
- The current STATS panel already renders `Char.Status`/`Char.Vitals`; a `score`
  request is not its required refresh. Those packets are not the complete score.
- Diff visible `Char.Affects` IDs with a fresh session baseline for effect loss.
  Loss alone does not establish natural expiry or skill readiness. Count existing
  durations locally; hidden cooldown tags remain unavailable.
- Render existing `Quest.Map` and `Quest.Status.availability/replacementDue`,
  including clears, without another map generation/query path.
- Consume group bids from `Comm.Channel` with membership/duplicate checks and one
  source per bid. Dice results remain text until their separate contract exists.

WHO, scan, dice, identify, action outcomes, cooldowns/activity, richer skills/score,
affect reasons and additional observer notices are follow-ups. Do not retire
fallbacks or advertise support for them. The reported self/pet/opponent HP widget
symptom still needs real-client reproduction and numeric/style checks.

## Captured fixtures and proof boundary

[server-gmcp.json](../../tests/mudlet/fixtures/server-gmcp.json) is captured from
actual production serializer/parser/send functions through the server harness.
It uses isolated world/mechanics services and synthetic characters; it contains
no live accounts or player data. Provenance records the server commit and source
hashes, including the item naming, condition, command, publisher and test owners.

New phases include `control`, `time`, `session-account`, `session-enter`,
`session-clear`, `combat-subjects`, `damage-secondary`, `items-empty`,
`items-equipment` and `items-nested`. Existing populated/clear package phases are
retained. New contract phases are independent examples with their own contexts;
replaying all phases as one session would be invalid. These fixtures provide
contract/adoption examples; capturing them does
not implement the client handlers or prove a real Mudlet widget fix.

Refresh with `python3 scripts/capture_server_gmcp.py --server /path/to/server`.
This handoff changes test fixtures/docs only, with no package runtime or release.

The refreshed existing `server-wire` scenario passes in real Mudlet (run
`20261101T102603Z-38eccfe8-server-wire`); populated and clear screenshots were
inspected. Its expected wolf percentage is 32, matching the captured fixture.
This proves existing packet decoding/clears, not new item/time/session UI adoption.

The final capture also fingerprints the worn-container `get` lookup. Its existing
`server-wire` populated/clear inputs are unchanged except the chat timestamp, so
the recorded wire/screenshot pass remains applicable.

Additional PR review verified all 26 source hashes against the recorded Git
objects, all 12 phases and authoritative empty items. Fresh Mudlet 5.0.1 /
Qt 6.11.1 wire run `20261101T134338Z-6cd309f5-server-wire` passed 27
assertions. Populated, clear and Errors-view screenshots were inspected; no
Lua errors appeared. This remains an offline transport check.
