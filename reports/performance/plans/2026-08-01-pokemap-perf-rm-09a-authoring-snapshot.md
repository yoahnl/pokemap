# PERF-RM-09A Authoring Snapshot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans` task by task. Every production change follows red → green → refactor.

**Goal:** Reduce authoring snapshot latency and transient memory without changing snapshot bytes, fingerprints, diagnostics, ordering, CAS authority, handle lifetime, or workspace security.

**Architecture:** First repair the benchmark so `selbrume` means the canonical root fixture. Then profile the existing two-observation loader, replace copy-producing fingerprint wrappers with the existing streaming builder, and remove redundant byte copies only at internal ownership boundaries. `ProjectSnapshot.resourceBytes` stays eager and exact in Phase A.

**Tech Stack:** Dart 3.12, `map_core`, `map_authoring`, AOT benchmark receipts, PMCP parity tests.

---

### Task 1: Lock the canonical Selbrume benchmark fixture

**Files:**
- Modify: `packages/map_authoring/benchmark/authoring_snapshot_open.dart`
- Modify: `packages/map_authoring/test/benchmark/authoring_snapshot_open_cli_test.dart`

- [ ] Add a CLI regression that runs only `selbrume` and asserts `fixturePath == "selbrume"`, `mapCount == 10`, `resourceCount == 35`, and `resourceBytes == 4753256`.
- [ ] Run `dart test test/benchmark/authoring_snapshot_open_cli_test.dart` and retain the expected red result proving the slice is selected today.
- [ ] Point `_resolveFixture('selbrume')` to the repository-root `selbrume/` directory and make the first allowed root the canonical fixture itself.
- [ ] Populate `resourceCount` and `resourceBytes` from the production `ProjectSnapshot`, not from a parallel filesystem scan.
- [ ] Re-run the CLI regression green and capture three isolated AOT receipts before changing the loader.

### Task 2: Add concurrency and byte-identity characterization

**Files:**
- Create: `packages/map_authoring/test/workspace/project_snapshot_concurrency_test.dart`
- Modify: `packages/map_authoring/test/workspace/project_snapshot_test.dart`
- Modify: `packages/map_core/test/narrative_project_fingerprint_test.dart`

- [ ] Add a reader that mutates one map between first and second observation and assert `project.changed_during_snapshot`.
- [ ] Add disappearance, expired-handle, missing-required-resource, editor-projection diagnostic, and exact read-count cases.
- [ ] Compare aggregate and per-resource fingerprints to `computeNarrativeProjectFingerprint` and compare every `resourceBytes(identity)` byte-for-byte.
- [ ] Run the new file and confirm it passes against the pre-optimization implementation.

### Task 3: Instrument production stages without changing the snapshot contract

**Files:**
- Modify: `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`
- Modify: `packages/map_authoring/benchmark/authoring_snapshot_open.dart`
- Modify: `packages/map_authoring/test/workspace/project_snapshot_test.dart`

- [ ] Add immutable stage metrics for initial reads, decode/model construction, second observation, fingerprinting, projection, total resources, and total resource bytes.
- [ ] Inject an optional metrics sink into `ProjectSnapshotLoader`; the default path must remain allocation-light and behaviorally identical.
- [ ] Emit stage percentiles in the benchmark receipt and test their schema and non-negative accounting.
- [ ] Run targeted tests before moving to optimization.

### Task 4: Stream fingerprints and remove redundant internal copies

**Files:**
- Modify: `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`
- Modify only when characterization proves necessary: `packages/map_authoring/lib/src/workspace/project_open_service.dart`
- Modify only when ownership remains exact: `packages/map_authoring/lib/src/workspace/workspace_handle_store.dart`
- Modify only when the eager API can stay immutable: `packages/map_authoring/lib/src/workspace/project_snapshot.dart`
- Modify only for a synchronous no-copy helper: `packages/map_core/lib/src/operations/narrative_project_fingerprint.dart`

- [ ] Build aggregate and individual fingerprints directly with `NarrativeProjectFingerprintBuilder`; never materialize `NarrativeProjectFingerprintEntry` copies inside the loader.
- [ ] Preserve sorted normalized paths and the canonical `path + length + bytes` framing.
- [ ] Keep exactly two loader observations and all existing rejection diagnostics.
- [ ] Keep one immutable eager pre-image per returned resource; do not introduce lazy `resourceBytes` or a schema/API migration.
- [ ] Re-run fingerprint, snapshot, concurrency, open-service, path-security, stale-plan, and full authoring parity tests.

### Task 5: Calibrate and decide the lot

- [ ] Compile the benchmark once, then run canonical Selbrume alone in three fresh AOT processes before and after.
- [ ] Compare fixture fingerprint, snapshot checksum, stage p50/p95, and externally sampled peak RSS on the same runner.
- [ ] Require mean below 400 ms, p95 at most 1 s, bit-identical fingerprints/bytes, and at least 30% peak-RSS reduction to propose `DONE`.
- [ ] Otherwise report `PARTIAL` with the measured limiting stage; do not weaken coherence or workspace roots.

**Verification:**

```bash
cd packages/map_core && dart test test/narrative_project_fingerprint_test.dart && dart test && dart analyze
cd packages/map_authoring && dart test test/workspace/project_snapshot_test.dart test/workspace/project_snapshot_concurrency_test.dart test/workspace/project_open_service_test.dart test/workspace/workspace_path_security_test.dart test/transactions/stale_plan_test.dart test/benchmark/authoring_snapshot_open_cli_test.dart
cd packages/map_authoring && dart run tool/pmcp085_conformance.dart && dart test test/parity/full_authoring_parity_test.dart && dart test && dart analyze
cd tools/pokemap_mcp && npm run check && npm test
```

**Non-goals:** lazy snapshot bytes, schema changes, removal of the second observation, broader workspace roots, editor state refactors, or codec offload from `RM-09B`.
