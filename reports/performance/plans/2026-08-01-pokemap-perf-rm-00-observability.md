# PERF-RM-00 — Observability and comparable baselines implementation plan

> **For Codex:** execute this plan package by package with the repository's
> `executing-plans`, `test-driven-development`, and
> `verification-before-completion` workflows. Git write operations, worktrees,
> and commits are deliberately omitted because they are not authorized for this
> workspace.

**Goal:** establish a deterministic, versioned and non-blocking performance
observation layer for PokeMap before the remaining remediation phases continue.

**Architecture:** pure-Dart harnesses measure one operation at a time and emit a
shared JSON V2 envelope; Flutter profile journeys report frame timings without
mixing build and raster durations. CI only collects and uploads receipts. Local
three-run baselines remain evidence, not release gates.

**Tech stack:** Dart AOT executables, Flutter profile/driver integration,
`package:test`, `flutter_test`, GitHub Actions.

---

## Scope and acceptance contract

- Preserve and validate the existing `surface_role_scaling` and
  `world_collision_scaling` harnesses introduced by Phase 1.
- Add isolated AOT harnesses for map paint gestures, group hierarchy
  validation, JSON round trips, authoring snapshot open, and battle turns.
- Every pure-Dart receipt uses schema V2 metadata, explicit warmups/sample
  counts, fixture fingerprints, raw samples, and p50/p95/p99 values.
- Invalid fixtures, zero samples, malformed arguments, and output paths outside
  the package root fail explicitly.
- Extend runtime frame collection with build/raster distributions kept
  separate, plus frame-budget exceedance counts and rates.
- Add a macOS editor profile journey and a driver that writes a versioned JSON
  receipt to the explicitly configured package-local output path.
- Extend `pokemap_eval run` with versioned multi-run profile output while
  preserving existing CLI behavior.
- Add one non-blocking CI observation job with an explicit test manifest and
  uploaded artifacts; no performance threshold can fail the workflow.
- Capture three comparable local baseline runs when the host supports the
  relevant execution mode. Never compare JIT/debug values with AOT/profile.

## Task 1: Lock the JSON and percentile contracts with tests

**Files:**

- Create: `packages/map_core/test/benchmark/map_paint_gesture_cli_test.dart`
- Create: `packages/map_core/test/benchmark/group_hierarchy_scaling_cli_test.dart`
- Create: `packages/map_core/test/benchmark/json_roundtrip_scaling_cli_test.dart`
- Create: `packages/map_authoring/test/benchmark/authoring_snapshot_open_cli_test.dart`
- Create: `packages/map_battle/test/benchmark/battle_turn_baseline_cli_test.dart`
- Modify: `examples/playable_runtime_host/test/evaluation/interactive_frame_metrics_test.dart`
- Modify: `examples/playable_runtime_host/test/evaluation/pokemap_eval_cli_test.dart`

1. Add RED tests for valid V2 receipts and deterministic checksums/fingerprints.
2. Add RED tests for zero samples, unknown fixtures, malformed inputs, output
   escapes, zero-frame snapshots, unsorted frame data, and unknown schemas.
3. Run each focused test from its owning package and retain the failure signal.

## Task 2: Implement pure-Dart AOT harnesses

**Files:**

- Create: `packages/map_core/benchmark/map_paint_gesture.dart`
- Create: `packages/map_core/benchmark/group_hierarchy_scaling.dart`
- Create: `packages/map_core/benchmark/json_roundtrip_scaling.dart`
- Create: `packages/map_authoring/benchmark/authoring_snapshot_open.dart`
- Create: `packages/map_battle/benchmark/battle_turn_baseline.dart`

1. Parse only the documented command-line options.
2. Validate inputs before warmup or measurement.
3. Build deterministic synthetic/canonical fixtures and fingerprint their
   serialized input.
4. Run warmups outside the measured samples.
5. Record raw microsecond samples and nearest-rank p50/p95/p99.
6. Write atomically to a package-local output path and print the receipt.
7. Keep benchmark code outside public package barrels.

## Task 3: Upgrade runtime frame observability

**Files:**

- Modify: `examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_frame_metrics.dart`
- Modify: `examples/playable_runtime_host/test/evaluation/interactive/interactive_frame_metrics_test.dart`

1. Store individual build and raster durations during a recording window.
2. Report separate p50/p95/p99 distributions and max/average values.
3. Report frames over 16.67 ms and 33.3 ms as counts and rates, using total
   frame span without adding build and raster phases together.
4. Preserve the existing JSON fields for compatibility.
5. Reject unknown receipt schemas in the parsing/validation seam.

## Task 4: Add versioned runtime and editor profile journeys

**Files:**

- Modify: `examples/playable_runtime_host/tool/pokemap_eval.dart`
- Modify: `examples/playable_runtime_host/tool/src/pokemap_eval_cli.dart`
- Modify: `examples/playable_runtime_host/test/evaluation/pokemap_eval_cli_test.dart`
- Modify: `packages/map_editor/pubspec.yaml`
- Create: `packages/map_editor/integration_test/editor_project_journey_test.dart`
- Create: `packages/map_editor/test_driver/performance_driver.dart`

1. Add `--build-mode`, `--runs`, and `--json-output` to `pokemap_eval run`.
2. Require `profile` for performance receipts and aggregate repeated run frame
   metrics without changing ordinary evaluation receipts.
3. Make the editor journey execute open/select/paint/undo/save-equivalent UI
   work with stable keys already exposed by the application; if a production
   seam is unavailable, use the narrowest test-only journey and state it.
4. Write editor timings and rebuild/frame data as schema V2 JSON under the
   configured package-local output.

## Task 5: Add non-blocking CI observation

**Files:**

- Modify: `.github/workflows/pokemap_hub_product_certification.yml`

1. Add a dedicated performance-observation job with `continue-on-error: true`.
2. Compile/run an explicit, bounded AOT harness manifest.
3. Run only explicitly named editor performance tests; remove the global tag
   sweep from this lane.
4. Upload JSON receipts with `if: always()`.
5. Do not introduce threshold assertions or required-job dependencies.

## Task 6: Capture comparable local evidence

**Files:**

- Create under ignored build output:
  `*/build/performance/baseline/run-{1,2,3}/*.json`

1. Record commit, dirty-tree fingerprint, toolchain, OS, architecture, fixture
   fingerprint, execution mode, and command line in every run.
2. Compile the pure-Dart harnesses once per owning package, then execute three
   isolated runs with identical arguments.
3. Run runtime/editor profile journeys three times when the desktop/profile
   environment is available; otherwise record the exact blocker and do not
   substitute debug mode.
4. Validate all receipts against V2 invariants and compare fingerprints/modes.

## Task 7: Verification and Evidence Pack

**Files:**

- Create: `reports/performance/perf_rm_00_observability.md`

1. Run formatter, focused tests, package analyzers, AOT compilation, and the
   relevant macOS profile/build checks.
2. Execute separate named passes: Audit/Architecture, Implementation, Tests,
   Build/Validation, and Final Critique.
3. Record initial/final Git status, file inventory, precise changed zones,
   commands and exact results, full content of created files, risks, non-goals,
   and residual variance.
4. Propose `DONE` only if every required proof exists; otherwise use `PARTIAL`
   with explicit closure steps.

