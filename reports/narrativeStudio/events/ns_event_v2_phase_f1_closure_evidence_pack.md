# NS-EVENT-V2 — Phase F1 Closure Evidence Pack

## 1. Identity

```text
Lot: NS-EVENT-V2 PHASE F1
Baseline: 2d9642d140d897831dcc0821baecca686eac52c0
Branch: main
Date: 2026-07-15
Verdict: CLOSED / ACCEPTED
```

## 2. Gate 0 exact

```text
pwd: /Users/karim/Project/pokemonProject
branch: main
status: <empty>
diff --stat: <empty>
diff --name-only: <empty>
diff --name-status: <empty>
diff --check: <empty>
tracked .dart_tool: <empty>
HEAD: 2d9642d1 fix(event-v2): close F1-ENTRY-TER Selbrume runtime contracts
```

Historique observé : `a47e2195`, `07f566fa`, `7ad2351c`, `a2ee6bbd`, `5bf62901`, `5d920469`, `e932d9a2`, `025bf9bc` après la baseline.

## 3. Files read

- Architecture decisions Event Builder V2.
- Roadmap Event Builder V2.
- Reports A, B, C, D, E, E-bis.
- Historical F1 blocker report.
- F1-PREREQ closure report and evidence.
- F1-ENTRY-TER closure report.
- Root `AGENTS.md`, `codex_rule.md`, skills index and verification/review workflows.
- Runtime/core/gameplay implementations containing all mandated symbols.

## 4. MCP symbols

Resolved with Dart MCP/LSP:

```text
NarrativeEventDefinition
NarrativeEventRecord
NarrativeEventRegistry
NarrativeEventSourceRef
NarrativeOutcomeRef
NarrativeEventCondition
NarrativeEventReusePolicy
NarrativeEventSourceIndex
ValidatedLegacyClaimIndex
LegacyClaimSourceResolution
LegacyClaimProvenanceResolution
NarrativeFactRuntimeState
NarrativeFactRuntimeResolver
GameState
SaveData
gameStateFromSaveData
saveDataFromGameState
normalizeLoadedGameState
FileGameSaveRepository
SceneRuntime
SceneRuntimeHostCallbacks
SceneConsequenceRuntimeWriter
```

## 5. Agents and incidents

| Pass | Scope | Final |
|---|---|---|
| A | Dispatch domain | PASS |
| B | Planner/conditions | PASS |
| C | Progress/codec | PASS |
| D | Lifecycle/atomic commit | PASS |
| E | Runtime gate | PASS |
| F | Outbox | PASS |
| G | Compatibility | PASS |
| H | Tests/performance/docs | PASS |
| R1 | Runtime integrity | PASS |
| R2 | Compatibility truthfulness | PASS |

Incident : worker core interrompu avant réponse finale. Travail inspecté, repris et revalidé par suites complètes. Deux commandes avec chemin répété ont été remplacées par des commandes correctes depuis les packages concernés.

## 6. Created production APIs

```text
map_core
  NarrativeEventOccurrence
  NarrativeOutcomeDelivery
  NarrativeEventProgress
  NarrativeEventDispatchAuthorityPreparation
  NarrativeEventDispatchAuthorityReady
  NarrativeEventDispatchAuthorityBlocked
  NarrativeEventDispatchDecision
  NarrativeEventDispatchHandled
  NarrativeEventDispatchClaimedButIneligible
  NarrativeEventDispatchNoMatch

map_gameplay
  NarrativeEventDispatchPlanner
  NarrativeEventExecutionCoordinator
  NarrativeEventStateTransactions
  NarrativeOutcomeOutboxProcessor
  typed scene, execution, dispatch and outbox results

map_runtime
  NarrativeRuntimeActivityGate
  NarrativeRuntimeActivityPort
  typed checkpoint/activity failures
```

## 7. Created file inventory

### map_core production

- `packages/map_core/lib/src/models/narrative_event_occurrence.dart` — 55 lines.
- `packages/map_core/lib/src/models/narrative_event_progress.dart` — 399 lines.
- `packages/map_core/lib/src/operations/narrative_event_dispatch_authority.dart` — 524 lines.

### map_core tests/support

- `packages/map_core/test/narrative_event_dispatch_authority_test.dart` — 639 lines.
- `packages/map_core/test/narrative_event_occurrence_test.dart` — 67 lines.
- `packages/map_core/test/narrative_event_progress_codec_test.dart` — 150 lines.
- `packages/map_core/test/narrative_event_progress_test.dart` — 111 lines.
- `packages/map_core/test/narrative_outcome_delivery_test.dart` — 93 lines.
- `packages/map_core/test/support/f1_runtime_catalog_fixture.dart` — 155 lines.

### map_gameplay production

- `packages/map_gameplay/lib/src/narrative_event_dispatch_planner.dart` — 15 lines.
- `packages/map_gameplay/lib/src/narrative_event_execution_coordinator.dart` — 337 lines.
- `packages/map_gameplay/lib/src/narrative_event_state_transactions.dart` — 82 lines.
- `packages/map_gameplay/lib/src/narrative_outcome_outbox_processor.dart` — 490 lines.

### map_gameplay tests/support

- `packages/map_gameplay/test/narrative_event_condition_eligibility_test.dart` — 205 lines.
- `packages/map_gameplay/test/narrative_event_dispatch_planner_test.dart` — 92 lines.
- `packages/map_gameplay/test/narrative_event_dispatch_truth_table_test.dart` — 226 lines.
- `packages/map_gameplay/test/narrative_event_execution_coordinator_test.dart` — 217 lines.
- `packages/map_gameplay/test/narrative_event_lifecycle_test.dart` — 223 lines.
- `packages/map_gameplay/test/narrative_event_runtime_performance_test.dart` — 479 lines.
- `packages/map_gameplay/test/narrative_event_transaction_concurrency_test.dart` — 120 lines.
- `packages/map_gameplay/test/narrative_outcome_outbox_processor_test.dart` — 294 lines.
- `packages/map_gameplay/test/narrative_outcome_outbox_reentrancy_test.dart` — 143 lines.
- `packages/map_gameplay/test/narrative_outcome_outbox_retry_test.dart` — 216 lines.
- `packages/map_gameplay/test/support/f1_runtime_catalog_fixture.dart` — 155 lines.

### map_runtime production/tests

- `packages/map_runtime/lib/src/application/narrative_runtime_activity_gate.dart` — 112 lines.
- `packages/map_runtime/lib/src/application/narrative_runtime_activity_port.dart` — 32 lines.
- `packages/map_runtime/test/narrative_event_progress_save_load_test.dart` — 93 lines.
- `packages/map_runtime/test/narrative_event_save_load_busy_gate_test.dart` — 207 lines.
- `packages/map_runtime/test/narrative_outcome_outbox_save_load_test.dart` — 75 lines.
- `packages/map_runtime/test/narrative_runtime_activity_gate_test.dart` — 144 lines.

The complete created-file contents are the canonical repository files listed above; this pack indexes their exact paths and sizes without duplicating thousands of source lines into engineering documentation.

## 8. Modified file inventory and precise zones

- `MVP Selbrume/road_map_event_builder_v2.md`: F1 CLOSED/ACCEPTED, V2-17/V2-18 PASS, F2 READY.
- `packages/map_core/lib/map_core.dart`: F1 exports.
- `packages/map_core/lib/src/models/game_state.dart` and generated: `narrativeEventProgress`.
- `packages/map_core/lib/src/models/save_data.dart` and generated: persisted `narrativeEventProgress`.
- `packages/map_core/lib/src/operations/game_state_persistence.dart`: bidirectional progress conversion.
- `packages/map_core/test/game_state_persistence_test.dart`: legacy/new round-trips.
- `packages/map_core/test/save_data_test.dart`: strict/default JSON coverage.
- `packages/map_gameplay/lib/map_gameplay.dart`: F1 public exports.
- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`: shared activity gate and explicit progress normalization.

## 9. Authority truth table

| Mode | Claim | Eligible | Result | Legacy |
|---|---|---:|---|---:|
| legacyOnly | any | any | noMatch | yes |
| dualRead | absent | yes | handled | no |
| dualRead | absent | no | noMatch | yes |
| dualRead | valid | yes | handled | no |
| dualRead | valid | no | claimedButIneligible | no |
| dualRead | tombstone | any | claimedButIneligible | no |
| v2Only | any | yes | handled | no |
| v2Only | any | no | noMatch | no |

## 10. Lifecycle matrix

| Policy/result | Scene | Consumed V2 | Consequences | Outbox | Commit |
|---|---|---:|---:|---:|---:|
| oneShot | success | yes | yes | yes | atomic |
| oneShot | failure | no | no | no | rollback |
| oneShot | cancel | no | no | no | rollback |
| reusable | success | no | yes | yes | atomic |
| claimedButIneligible | none | no | no | no | none |
| noMatch | none | no | no | no | none |

## 11. Persistence fixtures and old saves

- Missing `narrativeEventProgress` defaults to empty.
- Explicit malformed/null progress is rejected by strict decode where required.
- `consumedEventIds` remains unchanged and unmapped.
- Fact runtime state remains unchanged.
- Orphan consumed IDs survive round-trip.
- Pending delivery ID, outcome qualification, causation, correlation, depth and attempts survive round-trip.
- Wire duplicate/overlap states are rejected.

## 12. Concurrency evidence

- Global narrative commit serialization tested with two distinct Events.
- No stale snapshot overwrite.
- Same transaction authority shared by coordinator and outbox without deadlock.
- Two processors share outbox serialization and preserve FIFO heads.
- Pending deliveries added by a consumer are retained during finalization.
- Divergent current state terminalizes `dataInconsistency` rather than unsafe merge.

## 13. Busy gate evidence

| Activity | Save | Load |
|---|---:|---:|
| idle | allowed | allowed |
| dispatching | blocked | blocked |
| sceneActive | blocked | blocked |
| sceneSuspended | blocked | blocked |
| outboxProcessing | blocked | blocked |

Coordinator + runtime activity port + file repository share the same gate in a real composition test.

## 14. Outbox traces

```text
enqueue -> persist pending -> reload -> FIFO dispatch -> atomic finalize
retryable infrastructure failure -> same deliveryId -> attempt increment
third dispatch attempt failure -> terminal receipt -> no replay
depth 8 -> dispatch
depth 9 -> terminal depthExceeded without callback
pending + terminal in memory -> no dispatch -> pending removed -> dataInconsistency
pending + terminal on wire -> decode rejected
```

No bridge to Scene/Battle/legacyScenario producers was added.

## 15. Targeted gates

All requested F1-A/B/C/D command groups passed:

- occurrence + authority ;
- planner + truth table + condition eligibility ;
- progress + codec + persistence/save ;
- coordinator + lifecycle + concurrency ;
- runtime activity + save/load gate ;
- delivery + outbox processor + retry + reentrancy.

## 16. Complete suites

```text
cd packages/map_core && dart test --reporter=compact
Result: 2987 tests passed

cd packages/map_gameplay && dart test --reporter=compact
Result: 278 tests passed

cd packages/map_runtime && flutter test --reporter=compact
Result: 1645 passed, 1 historical skip, all other tests passed

cd examples/playable_runtime_host && flutter test --reporter=compact
Result: 48 tests passed
```

## 17. Analyze, generation and build

```text
map_core dart analyze: No issues found
map_gameplay dart analyze: No issues found
map_runtime flutter analyze --no-fatal-infos: exit 0, 348 infos
runtime host flutter analyze --no-fatal-infos: exit 0, 1 historical info
build_runner pass 1: 0 outputs
build_runner pass 2: 0 outputs, all skipped
runtime host flutter build macos --debug: PASS
```

Generated app: `examples/playable_runtime_host/build/macos/Build/Products/Debug/playable_runtime_host.app`.

## 18. Performance evidence

Environment:

```text
Apple M1 Pro, 32 GiB
macOS 27.0 build 26A5378j
Dart CLI 3.12.1 stable, macos_arm64
Flutter 3.46.0-0.3.pre, Dart 3.13.0 beta
Mode: JIT
```

The performance test prints mean, median, p95, iterations, warmup, mode, expected complexity and approximate fixture memory for required volumes. Representative 10k results:

```text
planner oneShot consumed: mean 3566.22us, median 2889us, p95 6393us
planner claim valid: mean 355.33us, median 157us, p95 1872us
planner tombstone: mean 0.11us, median 0us, p95 1us
progress consumed: mean 11828.86us, median 11869us, p95 12110us
progress pending: mean 37351us, median 35249us, p95 46658us
outbox 10k: mean 17085.43us, median 16568us, p95 20396us
```

No flaky threshold and no mutable global cache were introduced.

## 19. Compatibility and anti-drift

- No V2 read from legacy `consumedEventIds`.
- No story flag conversion.
- No eager migration.
- No registry mode or claim semantics rewrite.
- No production source bridge.
- No Event UI or editor change.
- No Selbrume/map/assets change.
- No runtime presentation change.
- No host source change.
- No lockfile or `.dart_tool` change.

## 20. Contradictory reviews

R1 initial blockers: incomplete catalog validation, outbox reentrancy, possible pending loss and weak concurrent rollback. Corrections: structural catalog validation, non-reentrant normal transactions, dedicated outbox serialization and current-state finalization.

R2 initial blockers: activity-gate composition and truthful F2 boundary. Corrections: required coordinator activity port, shared runtime adapter/repository gate tests, explicit no-bridge boundary.

Final:

```text
R1: PASS, no blocker
R2: PASS, no blocker
```

## 21. Final Git and anti-scope gate

Expected final status contains only the F1 roadmap, core/gameplay/runtime files and the two closure reports inventoried here. `git diff --check` and the anti-scope diff are empty. No Git write command was used.

## 22. F2 gate

```text
Phase F1: CLOSED / ACCEPTED
V2-17: PASS
V2-18: PASS
Phase F2: READY
V2-19..V2-22: NOT STARTED
```

F2 must use one fresh catalog/registry/claims snapshot, one shared transaction authority and one shared runtime activity gate. External idempotence remains the responsibility of source integrations.
