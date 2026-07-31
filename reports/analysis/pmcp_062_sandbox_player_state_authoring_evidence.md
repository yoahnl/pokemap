# PMCP-062 — Sandbox player-state authoring evidence

Date: 2026-07-31

## Scope and roadmap alignment

PMCP-062 adds an isolated player-state sandbox for authoring and playtest workflows. It covers save inspection and migration, deterministic state diffs, party recovery, PC deposit/withdraw, bag mutations, and shop purchase/sale without granting any production-save write capability.

Relevant fangame roadmap areas are FG-014 (save/load), FG-020–030 (party and PC), and FG-060–079 (bag, shops, and healing). This lot supplies authoring/playtest infrastructure only; it does not change their roadmap status and does not claim those broader mechanics as DONE.

## Initial audit

- Base commit: `e6ba3471 feat(authoring): add campaign content authoring`.
- `map_authoring` is intentionally independent from `map_gameplay`.
- Existing pure gameplay services already owned party, PC, bag, shop, and save operations.
- Production save persistence must remain outside the sandbox.
- Unrelated workspace changes under `examples/playable_runtime_host/pubspec.lock` and `.superpowers/brainstorm/` were excluded from this lot.

## Implementation verdict

PASS.

The sandbox engine lives in `map_gameplay`, while `map_authoring` exposes playtest-only action descriptors. Sandbox state is detached through JSON round-tripping, carries its own generation counter, exposes recursive JSON-pointer diffs, delegates save compatibility to the core codec/migration engine, and has no persistence port. Every descriptor requires `playtestControl`, none grants `projectWrite`, and the actions are deliberately absent from the canonical project mutation dispatcher.

An initial implementation attempted to add `map_gameplay` as a dependency of `map_authoring`. The package-boundary test rejected it. The dependency was removed and ownership was corrected before completion.

## Files changed

Created:

- `packages/map_gameplay/lib/src/sandbox_player_state.dart`
- `packages/map_gameplay/test/sandbox_player_state_service_test.dart`
- `packages/map_authoring/lib/src/domains/gameplay/sandbox_player_state_actions.dart`
- `packages/map_authoring/test/domains/gameplay/sandbox_player_state_actions_test.dart`
- `reports/analysis/pmcp_062_sandbox_player_state_authoring_evidence.md`
- `reports/analysis/pmcp_062_sandbox_player_state_authoring_evidence_appendix.md`

Modified:

- `packages/map_gameplay/lib/map_gameplay.dart`
- `packages/map_authoring/lib/map_authoring.dart`
- `packages/map_authoring/lib/src/registry/resource_kind_registry.dart`
- `packages/map_authoring/test/registry/action_registry_test.dart`

The complete contents of every created Dart file are recorded in the appendix. The precise modifications to existing files are the four small export/registry expectation additions listed above.

## Verification

Commands run from their package directories:

```text
packages/map_authoring:
dart test test/domains/gameplay/sandbox_player_state_actions_test.dart test/package_boundary_test.dart
Result: +4, all tests passed.

dart test
Result: +278, all tests passed.

dart analyze
Result: No issues found.

packages/map_gameplay:
dart test test/sandbox_player_state_service_test.dart
Result: +3, all tests passed.

dart test
Result: +441, all tests passed.

dart analyze
Result: No issues found.

packages/map_core:
dart test -r expanded test/game_state_persistence_test.dart test/save/game_state_save_envelope_mapper_test.dart test/save/save_compatibility_test.dart test/save/save_envelope_codec_test.dart test/save/save_migration_test.dart
Result: +37, all tests passed.

dart analyze
Result: No issues found.
```

The first package-boundary run failed because of the accidental `map_authoring -> map_gameplay` dependency. That failure drove the final package split; the corrected targeted boundary suite and the complete authoring suite both pass.

## Decisions and non-goals

- No production-save persistence interface is accepted by the sandbox service.
- No sandbox action is registered as a project mutation.
- No Flutter or Flame dependency was introduced.
- Save migrations reuse `map_core`; gameplay mutations reuse `map_gameplay`.
- This lot does not build editor UI, MCP transport, or runtime save menus.

## Final critique and risks

- Isolation is enforced structurally and by tests, but a future adapter could still misuse returned JSON outside this API; callers must preserve the no-production-write rule.
- Recursive diffs are intentionally structural and do not provide semantic grouping.
- The sandbox is in-memory; durable, explicitly separate test fixtures are a later concern.
- The action descriptors define a stable authorization surface, but the future MCP implementation must still enforce the same permission set server-side.

## Git evidence

Before the lot, HEAD was `e6ba3471`. The lot is staged and committed independently from unrelated workspace changes. The final commit identifier is recorded in Git history; the unrelated example lockfile and Smart Tiles prototype remain excluded.
