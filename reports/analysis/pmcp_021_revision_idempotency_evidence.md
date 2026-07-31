# PMCP-021 — Revision CAS and Durable Idempotency Evidence Pack

Date: 2026-07-31
Lot: `PMCP-021 — Révisions CAS et idempotence durable`
Verdict proposed: `DONE`

## Executive summary

PokeMap now has deterministic per-resource revision sets and a durable,
scoped idempotency ledger. Expected and current revisions represent both
content fingerprints and explicit absence, so update, create, and delete
operations can all be protected by compare-and-swap.

The idempotency boundary reserves actor/project/action/version/key identity in
a locked, flushed JSONL ledger before invoking an apply callback. The raw
client key and ephemeral workspace handle are never persisted. An exact retry
returns the original receipt after process-level reconstruction, a different
payload is refused, and an unfinished reservation blocks automatic replay
until PMCP-022 recovery resolves its outcome.

Completed entries have bounded retention. Pruning first flushes durable remove
events, then rewrites only live entries through a recoverable compact/backup
promotion. Pending entries are intentionally retained because deleting an
uncertain write intent could permit a duplicate mutation.

## Initial audit

Initial branch and state:

```text
a1817a440 (HEAD -> main) feat(authoring): add safe mutation planning
<clean working tree>
```

Dependencies consumed:

- `AuthoringChangeSet` and frozen resource payloads from PMCP-020;
- canonical recursively sorted JSON and framed SHA-256 fingerprints;
- canonical request, resource, diff, and receipt contracts;
- package ownership rule limiting production dependencies to `map_core`.

Audit decisions:

1. Revision identity belongs to opaque resource references, never filesystem
   paths.
2. A null revision is an explicit expected absence, while an omitted entry is
   unknown and therefore conflicts.
3. Current and expected sets must contain exactly the same touched resource
   identities; unexpected or missing entries fail closed.
4. Create/delete support requires nullable pre/post images in
   `AuthoringResourceChange`; two absent images and identical existing images
   remain invalid.
5. Idempotency scope includes actor, durable project identity, action ID,
   action version, and a hash of the caller key. Request ID and workspace
   handle are excluded so a legitimate retry after reopening can replay.
6. Canonical payload identity includes parameters, expected revision, dry-run
   bit, and extensions. Action/project/actor/key are already in the scope.
7. A callback exception leaves the flushed reservation pending. The kernel
   cannot know whether an external write became visible.
8. Cooperative processes serialize reserve/complete/prune through a separate
   lock file. Each JSONL event is newline-terminated and flushed before return.
9. A truncated final event is ignored; an invalid complete event fails closed
   with a path-free corruption error.
10. Completed retention compaction preserves an old tombstoned backup until a
    fully flushed compact log is promoted.

## Named pass verdicts

No sub-agent was launched because delegation was not requested. Independent
passes were executed inline:

| Pass | Verdict | Evidence |
|---|---|---|
| Audit / Architecture | `PASS` | revision, receipt, plan, package, and editor durability precedents inspected before implementation |
| Implementation | `PASS_WITH_FIXES`, then `PASS` | added explicit absence, raw-key hashing, conservative pending state, and recoverable physical compaction |
| Tests | `PASS` | initial missing-type RED; 14 focused positive/negative/concurrency/recovery tests green |
| Durability / Security | `PASS_WITH_FIXES`, then `PASS` | critical RED exposed unbounded log and resource-revision mismatch; both fixed and covered |
| Build / Validation | `PASS` | 123 full-package tests, analyzer, formatter, and real read-only CLI smoke green |
| Critique finale | `PASS` | no duplicate retry path, stale callback execution, raw key/path leak, or silent pending cleanup remains |

## File inventory and precise changed zones

### Modified files

`packages/map_authoring/lib/map_authoring.dart`

- Zone: canonical ports and transaction exports.
- Change: exports the idempotency port/store/ledger and revision-set API.

Exact diff:

```diff
+export 'src/ports/idempotency_store.dart';
+export 'src/transactions/file_idempotency_store.dart';
+export 'src/transactions/idempotency_ledger.dart';
+export 'src/transactions/revision_set.dart';
```

`packages/map_authoring/lib/src/transactions/change_set.dart`

- Constructor zone: pre/post byte images become nullable so absence can be
  CAS-checked for create/delete operations.
- Invariant zone: rejects two absent images, identical present images,
  supplied fingerprints for absent images, and resource-ref/pre-image
  revision mismatch.
- Projection zone: before/after revisions and lengths explicitly serialize
  null absence.
- Projected-revision zone: hashes sorted resource identities and nullable
  post-image revisions, preserving deterministic preview identity for delete.

Representative exact diff:

```diff
-    required Iterable<int> beforeBytes,
-    required Iterable<int> afterBytes,
+    required Iterable<int>? beforeBytes,
+    required Iterable<int>? afterBytes,

+    if (this.beforeBytes == null && this.afterBytes == null) {
+      throw ArgumentError.value(
+        null,
+        'beforeBytes/afterBytes',
+        'at least one resource image must exist',
+      );
+    }

-  final List<int> beforeBytes;
-  final List<int> afterBytes;
-  late final String beforeRevision;
-  late final String afterRevision;
+  final List<int>? beforeBytes;
+  final List<int>? afterBytes;
+  late final String? beforeRevision;
+  late final String? afterRevision;
```

### Created production files

`packages/map_authoring/lib/src/transactions/revision_set.dart`

- deterministic revision entries and set fingerprint;
- strict JSON round trip and declared-fingerprint verification;
- explicit absence, exact-set comparison, structured conflict details, and
  callback guard.

`packages/map_authoring/lib/src/ports/idempotency_store.dart`

- scoped identity with raw-key hash-at-boundary semantics;
- pending/completed durable record invariants and strict JSON decoding;
- atomic reserve, complete, read, and prune port contract.

`packages/map_authoring/lib/src/transactions/file_idempotency_store.dart`

- cooperative exclusive lock, flushed append-only events, strict folding;
- safe partial-tail behavior and path-free corruption/I/O errors;
- durable tombstones plus compact/backup recovery state machine.

`packages/map_authoring/lib/src/transactions/idempotency_ledger.dart`

- request/scope validation and canonical payload hashing;
- reserve-before-apply ordering, exact receipt replay, conflict and
  recovery-required failures, retention cleanup.

### Created tests

`packages/map_authoring/test/transactions/revision_conflict_test.dart`

- ordering/round-trip determinism;
- explicit create/delete absence;
- duplicate/malformed/inconsistent revision rejection;
- stale, unexpected-presence, and missing-current callback guards.

`packages/map_authoring/test/transactions/idempotency_contract_test.dart`

- exact replay after reopen and one apply;
- different-payload refusal and complete scope isolation;
- pending failure/recovery requirement and concurrent retry;
- retention compaction, no raw key/workspace persistence;
- interrupted compaction recovery from backup or compact state;
- path-like scope rejection and path-free corruption failure.

### Full-content appendix

`reports/analysis/pmcp_021_created_files_full_content.md` reproduces the full
contents of all six production and test files created by this lot. Modified
files are represented by the exact zones above and the staged Git diff. The
evidence report and appendix exclude themselves to avoid recursion.

## TDD evidence

Initial RED:

```text
Command:
dart test test/transactions/revision_conflict_test.dart \
  test/transactions/idempotency_contract_test.dart

Representative result:
Error: Method not found: 'AuthoringRevisionSet'.
Error: Method not found: 'AuthoringResourceRevision'.
Error: Type 'AuthoringIdempotencyLedger' not found.
Error: Method not found: 'FileIdempotencyStore'.
Error: Null cannot be assigned to required Iterable<int> pre/post images.
+0 -2: Some tests failed.
Exit code: 1
```

First focused GREEN:

```text
Command:
dart test test/transactions/revision_conflict_test.dart \
  test/transactions/idempotency_contract_test.dart

Result:
+12: All tests passed!
Exit code: 0
```

Critical-review RED:

```text
Resource revision consistency:
Expected: throws ArgumentError
Actual: returned AuthoringResourceRevision

Bounded retention:
Expected compacted JSONL length: 1
Actual length: 4 (pending/completed/pending/remove events)

+10 -2: Some tests failed.
Exit code: 1
```

Fixes:

- explicit resource-ref revision must equal the revision entry;
- prune flushes tombstones, removes expired records from the live map, and
  promotes a flushed compact log through a recoverable backup boundary;
- reopen tests cover backup-only and compact-plus-backup interrupted states;
- corruption returns `idempotency.store_corrupt` without the store path.

Final focused result:

```text
Command:
dart test test/transactions/revision_conflict_test.dart \
  test/transactions/idempotency_contract_test.dart

Result:
+14: All tests passed!
Exit code: 0
```

PMCP-020 transaction regression:

```text
Command:
dart test test/transactions

Result before the two final recovery guards:
+22: All tests passed!
Exit code: 0
```

## Final commands and exact results

Full package tests:

```text
Command:
dart test

Result:
+123: All tests passed!
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
Formatted 61 files (0 changed) in 0.08 seconds.
Exit code: 0
```

Read-only executable smoke:

```text
Command:
dart run bin/pokemap_authoring.dart \
  --root ../../examples/playable_runtime_host/p3_narrative_smoke_slice \
  </dev/null

Result:
<no stdout or stderr>
Exit code: 0
```

Diff hygiene:

```text
Command:
git diff --check

Result:
<no output>
Exit code: 0
```

## Final Git state before commit

```text
 M packages/map_authoring/lib/map_authoring.dart
 M packages/map_authoring/lib/src/transactions/change_set.dart
?? packages/map_authoring/lib/src/ports/idempotency_store.dart
?? packages/map_authoring/lib/src/transactions/file_idempotency_store.dart
?? packages/map_authoring/lib/src/transactions/idempotency_ledger.dart
?? packages/map_authoring/lib/src/transactions/revision_set.dart
?? packages/map_authoring/test/transactions/idempotency_contract_test.dart
?? packages/map_authoring/test/transactions/revision_conflict_test.dart
?? reports/analysis/pmcp_021_revision_idempotency_evidence.md
?? reports/analysis/pmcp_021_created_files_full_content.md
```

Only PMCP-021 files are present. The requested commit is performed after this
evidence pack and its appendix pass exact-content and staged-diff checks.

## Critique finale and known limits

Strengths:

- CAS identifies every touched resource and distinguishes absent from unknown;
- the callback is unreachable after any revision conflict;
- reserve is locked and flushed before apply;
- successful retries return the exact original durable receipt, even with a
  new request ID and workspace handle;
- concurrent retries cannot invoke apply twice;
- pending outcomes never expire automatically;
- completed retention is logically and physically compacted;
- raw idempotency keys, workspace handles, paths, and exception internals are
  absent from durable events and public failures.

Limits intentionally retained:

- the caller must supply a stable durable `projectId`; Phase 2 opaque workspace
  handles are intentionally unsuitable after restart, and the adapter that
  chooses project identity is not part of this lot;
- locks coordinate well-behaved processes using the same lock file, not a
  hostile process that edits ledger bytes directly;
- ordering is process-crash safe after Dart flushes, but this pure-Dart layer
  cannot promise storage-controller power-loss durability or directory fsync;
- the key is hashed, not HMACed or encrypted. High-entropy client keys remain
  recommended because low-entropy values could be dictionary-guessed from the
  ledger hash;
- pending records can accumulate until PMCP-022 recovery completes or an
  operator resolves them; pruning them automatically would be unsafe;
- this lot guards a callback but does not yet journal or promote project files.

No blocker remains against PMCP-022. Roadmap files remain unchanged because
the user requested implementation, not a roadmap status edit.
