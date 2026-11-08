---
name: ablation
description: >-
  Simplify a Duris Mudlet client plan or change to what the requested outcome needs,
  then implement and prove it when implementation is requested. Use for scope reviews,
  before implementing features or fixes, or when work accumulates speculative layers,
  workarounds, or unrelated changes. Preserve every requirement and acceptance criterion.
---

# Ablation

Deliver the complete requested outcome through the simplest correct change. Cut machinery and
work, never the outcome or its acceptance criteria. Fewer lines, fewer files, or green tests do
not by themselves make a solution better.

Ablation is a counterfactual check: mentally remove or replace a part, then trace what would
fail. It needs no alternative implementations or experiments. Apply it to a plan before editing,
and again whenever new evidence changes the plan or the work starts to grow.

## Establish what must survive

- Read the request, earlier decisions, and acceptance criteria. Separate required outcomes and
  constraints from suggested approaches and assumptions. Difficulty, effort spent, or existing
  test coverage never redefine the objective.
- Inspect the relevant code, callers, tests, configuration, and [repository instructions](../../../AGENTS.md)
  directly. Trace the affected path far enough to know its behavior and dependencies, and
  investigate uncertainty that could change correctness, scope, or the approach.
- Inspect existing changes before editing, so later pruning removes only work this task owns.
- State the outcome, affected files, and proof in the current plan or conversation; a sentence
  covers a small task. Do not create a separate report, checklist, or approval stage.

## Ablate the plan

For each meaningful change, abstraction, dependency, configuration option, fallback, and check,
ask: **if this is omitted, which requirement or concrete failure goes unaddressed, and what
evidence shows it?** A requirement, a traced consumer, a reproduced defect, or a repository rule
justifies work. Hypothetical future use does not.

- **Keep** what supplies required behavior, compatibility, safety, recovery, or verification.
- **Simplify** when the need is real but an existing path or smaller mechanism can meet it.
- **Drop** what no requirement or demonstrated current risk depends on.
- **Investigate** specific missing evidence that could change the decision.

Judge related parts together. A framework can look necessary only because its adapter,
configuration, and tests depend on it, so test whether the whole cluster can go. Keep the
supporting changes a required migration, integration, or recovery path needs, even when they
expose no feature of their own.

Prefer the existing path, fix the root cause, and preserve unrelated behavior. Reuse helpers,
patterns, and tests. Keep one implementation unless independent responsibilities or required
compatibility justify more. Add an abstraction, adapter, or configuration surface only for an
explicit requirement, a second real caller, or a demonstrated correctness boundary.

Compare total complexity: branches, state, dependencies, public interfaces, operational burden,
and maintenance. A shorter patch that hides behavior, stacks workarounds, or leaves competing
paths may be worse; a necessary multi-file repair belongs in scope even when a local symptom
patch would be smaller. Check both directions: every retained change has a concrete purpose,
and every requirement still has an implementation path and proof.

Say briefly what was removed or simplified and why, then update the plan. If nothing can go,
say why the plan is already minimal; do not manufacture a deletion quota.

## Apply the client boundaries

- `src/` is the source of truth. Trace UI behavior through `ArjUI.lua`, mapping through
  `ArjMapper.lua`, automation through `ArjAuto.lua`, and the relevant aliases, triggers, or
  bindings in `src/package.xml`. Edit plain Lua in the source files; never patch the generated
  `duris-client.mpackage` or replace the XML script placeholders with copied implementations.
- Preserve the dark-fantasy aesthetic, percentage-based scaling, and supported saved settings.
  Read [docs/DESIGN.md](../../../docs/DESIGN.md) for layout, interactions, and lifecycle changes,
  and keep it aligned with the result. Hiding a panel does not prove teardown or source reload;
  inspect the affected event handlers, timers, widgets, and persistence path before removing them.
- Use Mudlet/Geyser APIs without external Lua dependencies. Keep the declared Mudlet 4.19.1+
  and GMCP contract unless a compatibility change is explicitly in scope. For protocol changes,
  inspect [GMCP fixture provenance](../../../tests/mudlet/fixtures/README.md) and
  `tests/mudlet/fixtures/server-gmcp.json`; use the server path in `.env` when current server
  evidence is needed. Changing the client does not authorize changing or deploying the server.
- For package changes, follow [docs/RELEASING.md](../../../docs/RELEASING.md): bump `VERSION`,
  add the dated changelog section, and run `python3 build.py`. Include the rebuilt package with
  the source when committing; do not hand-edit generated version fields. Repository-only docs
  and skill changes need no package version bump or rebuild.

## Implement within scope

- A request to review or simplify a plan authorizes that review, not implementation. Read-only
  discovery is allowed throughout. Implement only when the user has requested implementation.
- Make the local edits and checks the authorized outcome needs without adding confirmation
  steps for routine choices. Drop optional extras such as repository-wide cleanup, future-use
  layers, new services, or general test infrastructure instead of stopping to ask about them.
- Ask only when a consequential choice about behavior, compatibility, or data remains open,
  or the next action exceeds existing authorization; keep doing independent work while waiting.
  This skill grants no permission to discard user work, rewrite history, or mutate production.
- Include repairs needed for the requested workflow and update the plan. Record unrelated
  defects separately; fix them only when they fall within the user's authorized scope.
- If work starts growing fallback paths, workaround stacks, duplicate implementations, or
  unstated tests, find the cause and shrink the plan back to what the task needs.
- Remove code, callers, and configuration this task made obsolete; keep an old path only for
  an identified compatibility obligation. Read the actual diff before pruning, especially where
  user changes share a file. Commit only when asked; push only within the user's authorization.
  A push to `master` can publish an unreleased package through CI; do not push tags manually.

## Prove the whole outcome, then stop

- Run the narrowest relevant existing checks while working, and every required completion check
  at the end. Extend existing tests before adding files or infrastructure. Add a test only where
  changed observable behavior, an acceptance criterion, or a concrete regression risk is not
  already covered, never to restate the implementation or add unrelated coverage.
- Match proof to the claim. `python3 build.py --check` checks Lua syntax only. For runtime
  changes, use focused scenarios while iterating, then `python3 scripts/mudlet_suite.py` and
  inspect the screenshots and Errors view as described in
  [docs/LINUX_DEVELOPMENT.md](../../../docs/LINUX_DEVELOPMENT.md). Record visual review against
  the run directory; an automated pass does not establish visual correctness.
- Check the real command, alias, trigger, UI interaction, or GMCP event path when acceptance
  depends on it. A helper test does not prove reachability, and `ui off` / `ui on` does not load
  edited sources. Use a fresh or correctly reinstalled candidate in the isolated test profile.
- Offline Mudlet 5.0+ fixtures do not prove live negotiation, Mudlet 4.19.1 compatibility, or
  physical desktop DPI. Live checks use a separate profile. State unverified claims explicitly
  and record affected runtime checks in the [testing log](../../../docs/ongoing-projects/mudlet-local-testing.md).
- Reuse valid results. Repeat or widen verification only for relevant changes, failures,
  unresolved risks, or required gates. Repository-only documentation or skill changes need
  relevant content validation, not a new package build or Mudlet run.

Done means every original requirement and accepted scope change is satisfied with appropriate
proof; the final diff contains only necessary work; and no task-created debug, backup, or scratch
files remain. Preserve unrelated work and useful test evidence. Report the outcome, useful
simplifications, verification commands and results, and any limitations or unverified behavior.
Passing tests justify neither extra scope nor a missing requirement.
