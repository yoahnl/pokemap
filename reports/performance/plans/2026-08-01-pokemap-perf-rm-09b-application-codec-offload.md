# PERF-RM-09B Application Codec Offload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans` task by task. Start only after `PERF-RM-09A` has stable contracts and receipts.

**Goal:** Move expensive project and game-save JSON codec work off the UI isolate above a measured crossover while preserving every existing byte format and repository transaction boundary.

**Architecture:** Package-local codec executors own only pure model/JSON conversion. Repositories continue to own paths, locks, CAS checks, temp files, writes, recovery and error translation. Thresholds and executors are injectable so tests can force local/offloaded paths without timing assertions.

**Tech Stack:** Flutter compute/isolate workers, `map_core` models, editor/runtime repository tests, profile heartbeat harness.

---

### Task 1: Measure the crossover and freeze existing bytes

**Files:**
- Modify: `packages/map_editor/test/selbrume_editor_repository_roundtrip_test.dart`
- Modify: `packages/map_runtime/test/file_game_save_repository_test.dart`

- [ ] Record read, decode/model, validation, encode, and write durations for 1 KiB, 100 KiB, 2.4 MiB and 10 MiB fixtures in separate receipts.
- [ ] Save golden byte fingerprints for local project merge/encode and game-save encode/decode.
- [ ] Capture a UI heartbeat while codec work runs; do not infer frame health from total elapsed time.
- [ ] Select and document a byte threshold from the same runner; keep it injectable.

### Task 2: Add an editor persistence codec executor

**Files:**
- Create: `packages/map_editor/lib/src/infrastructure/repositories/editor_persistence_codec_executor.dart`
- Create: `packages/map_editor/test/infrastructure/editor_persistence_codec_executor_test.dart`
- Modify: `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

- [ ] Define an executor that decodes projects/maps and merges/validates/encodes project bytes without owning files or paths.
- [ ] Add a local implementation and a thresholded isolate implementation with identical typed results.
- [ ] Keep the pre-read, recovery gate, project write lock, before/live revision checks, event-registry preservation, and final write in the repository isolate.
- [ ] Test forced-local and forced-worker outputs byte-for-byte, worker failure translation, stale file CAS, recovery-required, and no-write-on-codec-error.

### Task 3: Add a game-save codec executor

**Files:**
- Create: `packages/map_runtime/lib/src/infrastructure/game_save_codec_executor.dart`
- Create: `packages/map_runtime/test/game_save_codec_executor_test.dart`
- Modify: `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
- Modify: `packages/map_runtime/test/file_game_save_repository_test.dart`
- Modify: `packages/map_runtime/test/playable_map_game_save_load_transaction_test.dart`

- [ ] Define `encode(GameState)` and `decode(List<int>)` executors with injectable threshold and worker runner.
- [ ] Preserve normalization before encode and after decode, exact indented JSON, activity-gate ordering, existing exception types, and unchanged file write semantics.
- [ ] Treat runtime file atomicity/CAS/recovery as `N/A — unchanged pre-existing contract`; do not claim guarantees absent from the repository.
- [ ] Test local/worker byte identity, malformed JSON, invalid state no-write, load transaction rollback/retry, and heartbeat progress.

### Task 4: Regress authoring parity and calibrate

- [ ] Run project round-trip, map CAS/recovery, runtime save/load, PMCP-085, MCP server tests and live catalog checks.
- [ ] Run three profile samples at the chosen threshold and compare total time plus maximum heartbeat gap.
- [ ] Require project save at most 250 ms with no frame over 33.3 ms on the 10 MiB fixture and game save/load at most 150 ms, without byte or recovery differences.
- [ ] If offload only moves total time and the heartbeat still stalls, report `PARTIAL`; do not skip validation or transaction checks.

**Verification:**

```bash
cd packages/map_editor && flutter test test/infrastructure/editor_persistence_codec_executor_test.dart test/selbrume_editor_repository_roundtrip_test.dart && flutter test && flutter analyze
cd packages/map_runtime && flutter test test/game_save_codec_executor_test.dart test/file_game_save_repository_test.dart test/playable_map_game_save_load_transaction_test.dart && flutter test && flutter analyze
cd packages/map_authoring && dart run tool/pmcp085_conformance.dart && dart test test/parity/full_authoring_parity_test.dart && dart analyze
cd tools/pokemap_mcp && npm run check && npm test
```

**Non-goals:** changing JSON formatting/schema, moving file I/O or locks into workers, adding runtime save atomicity, weakening CAS/recovery, offloading small payloads without measurement, or broadening workspace roots.
