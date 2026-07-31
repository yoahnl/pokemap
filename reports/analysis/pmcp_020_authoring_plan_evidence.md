# PMCP-020 — Safe Mutation Planning Evidence Pack

Date: 2026-07-31
Lot: `PMCP-020 — Plan, dry-run et diff structuré`
Verdict proposed: `DONE`

## Executive summary

PokeMap now has a pure-Dart mutation planning boundary. It converts an
immutable `ProjectSnapshot` and an `AuthoringRequest` into a short-lived opaque
`AuthoringPlan` without receiving any filesystem write capability.

The plan freezes its plan/receipt identities, seed, generated resource IDs,
before/after payloads and fingerprints, structured diff, affected resources,
projected touched-resource revision, reference-impact summary, preview data,
and artifact references. Resolution refuses unknown, expired, or stale plans.
Projected-state validation runs before publication in the store.

This lot does not apply changes. CAS application, durable idempotency,
journaling, authorization, and history remain assigned to PMCP-021 through
PMCP-024.

## Initial audit

Initial branch and state:

```text
6cc96b86b (HEAD -> main) feat(authoring): add read-only JSONL CLI
<clean working tree>
```

Audit findings:

1. `map_authoring` already owns protocol-neutral orchestration and depends only
   on `map_core`; no Flutter/editor type is needed for planning.
2. `ProjectSnapshot` supplies a coherent base revision and per-resource
   fingerprints, while `AuthoringRequest` already carries the expected
   revision and dry-run intent.
3. Existing `AuthoringDiff`, `AuthoringResourceRef`, `AuthoringArtifactRef`, and
   `AuthoringReceipt` contracts can be composed without a schema rewrite.
4. Existing editor persistence demonstrates atomic-per-file and recoverable
   multi-file patterns, but importing it would violate package direction.
5. The Phase 2 JSONL worker must remain read-only; no mutation command was
   registered by this lot.

Architecture decisions:

- planning callbacks receive only a snapshot, request, opaque plan identity,
  seed, and deterministic ID allocator;
- internal storage keys are validated project-relative capabilities and are
  omitted from public JSON;
- bytes are copied into unmodifiable lists and their optional declared
  revisions must match their canonical fingerprints;
- a resource reference revision, when supplied, must match the frozen
  pre-image;
- the structured diff must describe exactly the changed resource set;
- `projectedRevision` covers touched post-images and explicitly does not claim
  multi-file atomicity or a full-project on-disk revision;
- plan expiry is inclusive (`now >= expiresAt` is expired);
- validation failure leaves the plan store untouched.

## Named pass verdicts

No sub-agent was launched because delegation was not requested. Independent
passes were executed inline:

| Pass | Verdict | Evidence |
|---|---|---|
| Audit / Architecture | `PASS` | contracts, package boundary, editor transaction precedents, and roadmaps inspected first |
| Implementation | `PASS_WITH_FIXES`, then `PASS` | corrected `workspaceHandle` label; tightened Windows/URI storage paths, token trimming, and resource revision consistency |
| Tests | `PASS` | missing Phase 3 types observed RED; 10 focused positive/negative/guard tests green |
| Build / Validation | `PASS_WITH_COMMAND_FIX`, then `PASS` | 109 package tests, analyzer and formatter green; unsupported `--help` smoke replaced by a real read-only stdin session |
| Critique finale | `PASS` | no write port, path disclosure, stale-plan bypass, mutable byte alias, or atomicity overclaim remains |

## File inventory and precise changed zones

### Modified file

`packages/map_authoring/lib/map_authoring.dart`

- Zone: canonical public exports after reference services and before workspace
  services.
- Change: exports fingerprint support and the four PMCP-020 transaction types.

Exact diff:

```diff
+export 'src/support/authoring_fingerprint.dart';
+export 'src/transactions/action_planner.dart';
+export 'src/transactions/authoring_plan.dart';
+export 'src/transactions/change_set.dart';
+export 'src/transactions/plan_store.dart';
```

### Created production files

`packages/map_authoring/lib/src/support/authoring_fingerprint.dart`

- framed SHA-256 byte fingerprint using the existing `map_core` primitive;
- recursively key-sorted canonical contract JSON and JSON fingerprints.

`packages/map_authoring/lib/src/transactions/change_set.dart`

- immutable before/after bytes and verified revisions;
- safe private storage keys, deterministic ordering, exact diff coverage;
- touched post-image projected revision.

`packages/map_authoring/lib/src/transactions/authoring_plan.dart`

- frozen plan/draft models, safe public projection, planned receipt creation;
- immutable preview, reference impact, and deterministic artifact ordering.

`packages/map_authoring/lib/src/transactions/plan_store.dart`

- opaque in-memory TTL store;
- stable unknown/expired/stale failures with remediation.

`packages/map_authoring/lib/src/transactions/action_planner.dart`

- expected-revision guard before the builder;
- injected identities/seed for deterministic tests;
- stable generated IDs and validation-before-publication ordering.

### Created tests

`packages/map_authoring/test/transactions/action_planner_test.dart`

- real fixture byte preservation;
- plan replay stability, generated IDs/seed/diff/impact/artifacts;
- projected-state publication guard;
- duplicate/unsafe/inconsistent change-set rejection.

`packages/map_authoring/test/transactions/stale_plan_test.dart`

- stale external revision, exact TTL expiry, stale-at-creation builder guard,
  unknown opaque identifier and safe error text.

### Created planning artifact

`pokemap_authoring_api_mcp_phase_3_implementation_plan.md`

- audited five-lot execution plan, TDD/validation commands, commit boundaries,
  and Phase 3 exit contract.

### Full-content appendix

`reports/analysis/pmcp_020_created_files_full_content.md` reproduces the full
contents of all eight production, test, and planning files created by this
lot. The evidence report and appendix exclude themselves to avoid recursion.

## TDD evidence

Initial RED:

```text
Command:
dart test test/transactions/action_planner_test.dart \
  test/transactions/stale_plan_test.dart

Representative result:
Error: Type 'AuthoringMutationDraft' not found.
Error: Type 'AuthoringPlanningContext' not found.
Error: Method not found: 'AuthoringPlanStore'.
Error: Method not found: 'AuthoringActionPlanner'.
Error: Method not found: 'AuthoringChangeSet'.
+0 -2: Some tests failed.
Exit code: 1
```

First focused GREEN:

```text
Command:
dart test test/transactions/action_planner_test.dart \
  test/transactions/stale_plan_test.dart

Result:
+10: All tests passed!
Exit code: 0
```

Critical-review fixes added guard coverage for:

- Windows drive and URI-like storage keys;
- a resource reference revision inconsistent with frozen pre-image bytes;
- correct `workspaceHandle` serialization and absence of a mislabeled
  `projectHandle` member.

Focused result after review:

```text
Command:
dart test test/transactions

Result:
+10: All tests passed!
Exit code: 0
```

## Final commands and exact results

Diff hygiene and analysis:

```text
Command:
git diff --check && dart analyze

Result:
Analyzing map_authoring...
No issues found!
Exit code: 0
```

Full package tests:

```text
Command:
dart test

Result:
+109: All tests passed!
Exit code: 0
```

Static analysis:

```text
Command:
dart analyze

Result:
Analyzing map_authoring...
No issues found!
Exit code: 0
```

Formatting:

```text
Command:
dart format --output=none --set-exit-if-changed lib test

Result:
Formatted 55 files (0 changed) in 0.08 seconds.
Exit code: 0
```

Initial CLI smoke-plan correction:

```text
Command:
dart run bin/pokemap_authoring.dart --help

Result:
Unknown command-line option.
Usage: pokemap_authoring --root <allowed-root> ...
Exit code: 64
```

This was a validation-command error, not a product failure: the existing
Phase 2 CLI intentionally has no `--help` switch. No CLI behavior was changed.
The implementation plan now uses a real allowed root with closed stdin.

Final read-only executable smoke:

```text
Command:
dart run bin/pokemap_authoring.dart \
  --root ../../examples/playable_runtime_host/p3_narrative_smoke_slice \
  </dev/null

Result:
<no stdout or stderr>
Exit code: 0
```

Fixture immutability proof:

```text
Test:
AuthoringActionPlanner plans a real-project change without writing fixture bytes

Assertion:
project.json bytes read before planning equal bytes read after planning.
Result: PASS
```

## Final Git state before commit

```text
 M packages/map_authoring/lib/map_authoring.dart
?? packages/map_authoring/lib/src/support/authoring_fingerprint.dart
?? packages/map_authoring/lib/src/transactions/action_planner.dart
?? packages/map_authoring/lib/src/transactions/authoring_plan.dart
?? packages/map_authoring/lib/src/transactions/change_set.dart
?? packages/map_authoring/lib/src/transactions/plan_store.dart
?? packages/map_authoring/test/transactions/action_planner_test.dart
?? packages/map_authoring/test/transactions/stale_plan_test.dart
?? pokemap_authoring_api_mcp_phase_3_implementation_plan.md
?? reports/analysis/pmcp_020_authoring_plan_evidence.md
?? reports/analysis/pmcp_020_created_files_full_content.md
```

Only PMCP-020 files are present. The requested commit is performed after this
evidence pack is generated and rechecked.

## Critique finale and known limits

Strengths:

- no write capability exists in the planner constructor or planning context;
- bytes, JSON projections, artifacts, and resource lists are frozen;
- IDs and random seed are allocated exactly once and stored with the plan;
- stale/expiry checks precede any future apply boundary;
- storage paths are private, relative, and reject traversal, backslashes,
  absolute Windows/POSIX paths, URI forms, nulls, and internal `.pokemap` data;
- errors are stable and path-free;
- the CLI remains read-only.

Limits intentionally deferred:

- plans are process-local and expire in memory; durable write intent begins in
  PMCP-022, not during preview;
- a caller-provided planning closure could capture an external side effect.
  The canonical API does not grant one, and future mutation-registry admission
  will constrain registered handlers, but Dart cannot prove closure purity;
- `projectedRevision` fingerprints touched post-images, not untouched project
  resources or a committed disk state;
- per-resource CAS, idempotency, apply, crash recovery, authorization, audit,
  and undo are not claimed by PMCP-020.

No blocker remains against starting PMCP-021. The roadmap files were not
modified because the user requested implementation, not roadmap status edits.
