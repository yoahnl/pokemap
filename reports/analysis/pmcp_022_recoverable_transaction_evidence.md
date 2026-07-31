# PMCP-022 — Recoverable Multi-file Transaction Evidence Pack

Date: 2026-07-31

Phase: PokeMap Authoring API/MCP phase 3

Lot: PMCP-022
Proposed status: `DONE`

## Executive summary

PMCP-022 adds a project-local, journaled write state machine to
`package:map_authoring`. It provides deterministic multi-resource promotion,
verified before/after staging, touched-resource compare-and-swap checks,
durable idempotency integration, crash inspection, forward recovery, and
revision-gated compensation.

The guarantee is deliberately **recoverable multi-file execution with atomic
replacement per individual file**. The implementation does not claim a
filesystem-level atomic commit spanning multiple files.

Fresh evidence at the end of the lot:

- focused crash/recovery suite: `+20: All tests passed!`;
- all transaction tests: `+44: All tests passed!`;
- full `map_authoring` package: `+143: All tests passed!`;
- analyzer: `No issues found!`;
- formatter verification: 69 files, 0 changed;
- real read-only CLI smoke: exit 0 with an empty stdin session;
- `git diff --check`: exit 0.

## Initial audit

The lot started from a clean tree at:

```text
87c46a66d feat(authoring): add revision and idempotency guards
```

Existing PMCP-020 and PMCP-021 contracts already supplied:

- frozen `AuthoringPlan` and `AuthoringChangeSet` values;
- explicit present/absent resource revisions;
- deterministic plan receipts and structured diffs;
- a durable, locked JSONL idempotency store;
- scoped keys with pending/completed records.

The missing layer was the write boundary itself. There was no durable intent
journal, staged payload verification, ordered promotion API, crash recovery,
or compensation service. The audit therefore kept the work inside the pure
Dart `map_authoring` package and did not move gameplay rules into runtime or
editor packages.

This is authoring infrastructure rather than a fangame-mechanics change. No
`FG-*` lot was changed and `pokemap_roadmap_mecaniques_fangame.md` was not
modified.

## Named pass verdicts

No sub-agent was dispatched; repository/session instructions did not authorize
delegation. The implementation used explicit local review passes instead:

| Pass | Verdict | Evidence |
|---|---|---|
| TDD contract pass | PASS | Initial focused suite failed because transaction gateway/journal/recovery types did not exist; final focused suite is +20. |
| Durable-ordering pass | PASS | Journal intent precedes staging and reservation; reservation precedes promotion; each promotion is followed by a flushed checkpoint. |
| Crash-boundary pass | PASS | Fault injection covers preparation, staging, reservation, prepared state, per-resource promotion/checkpoint, and committed-journal boundaries. |
| Recovery pass | PASS | Reconstructed gateway/service instances resume or compensate using actual resource revisions and verified stages. |
| Idempotency pass | PASS | Completed retries return the original receipt even after plan eviction; pending records require explicit recovery; recovery completes the durable record once. |
| Filesystem-safety pass | PASS | Logical paths, operation identifiers, regular-file checks, symlink-parent rejection, and path-free public errors are tested. |
| Critical self-review | PASS after fix | Lock acquisition errors remain sanitized, while callback/domain/fault-injection exceptions are no longer swallowed as generic `transaction.io`. |
| Regression pass | PASS | All 143 package tests and static analysis pass. |

## File inventory and precise changed zones

### Modified files

- `packages/map_authoring/lib/map_authoring.dart`
  - lines 25 and 40–45: exports the transaction gateway, journal, executor,
    local adapter, and recovery service.
- `packages/map_authoring/lib/src/transactions/idempotency_ledger.dart`
  - line 54: centralizes request payload fingerprinting;
  - lines 102–175: adds completed-receipt preflight, recovery record lookup,
    and durable recovery completion;
  - lines 216–229: validates recovery receipts against their durable scope.
- `packages/map_authoring/lib/src/transactions/plan_store.dart`
  - lines 66–99: separates active-plan lookup from project-revision checking,
    allowing idempotent replay to complete before a now-stale plan lookup.

### Created production files

- `packages/map_authoring/lib/src/ports/transaction_file_gateway.dart`
  - path-free filesystem port, staged payload contract, project write lock,
    journal CRUD, and atomic-per-file promotion contract.
- `packages/map_authoring/lib/src/transactions/transaction_journal.dart`
  - strict journal schema, states, ordered entries, receipt/revision
    invariants, and round-trip JSON validation.
- `packages/map_authoring/lib/src/transactions/local_transaction_file_gateway.dart`
  - safe logical-path implementation, verified staging, locked project-local
    artifacts, flushed temp files, per-file rename, and strict journal reads.
- `packages/map_authoring/lib/src/transactions/journaled_transaction.dart`
  - plan/request checks, durable ordering, deterministic promotion, crash
    checkpoints, and exact receipt creation.
- `packages/map_authoring/lib/src/transactions/recovery_service.dart`
  - inspection dispositions, forward resume, reverse compensation, unreserved
    intent discard, stage verification, and recovered receipt finalization.

### Created tests and support

- `packages/map_authoring/test/support/transaction_test_fixture.dart`
  - filesystem-backed update/create/delete plan and service reconstruction.
- `packages/map_authoring/test/transactions/crash_boundary_test.dart`
  - normal apply/replay, all crash boundaries, stale gates, request/plan
    mismatch, second CAS, unsafe parent, and operation-ID checks.
- `packages/map_authoring/test/transactions/recovery_idempotence_test.dart`
  - forward recovery, compensation, external edits, committed-but-unreceipted
    recovery, create/delete rollback, corrupt stages, and repeatability.

### Reporting artifacts

- `reports/analysis/pmcp_022_recoverable_transaction_evidence.md`
  - this Evidence Pack.
- `reports/analysis/pmcp_022_created_files_full_content.md`
  - exact full content of all eight created source/test/support files.

The exhaustive source appendix is:

```text
reports/analysis/pmcp_022_created_files_full_content.md
```

It intentionally excludes the two reporting artifacts themselves to avoid
recursive self-inclusion.

## Durable protocol and crash boundaries

The apply path is ordered as follows:

1. acquire the cooperative project write lock;
2. perform idempotency preflight before plan lookup;
3. validate the active plan, exact request semantics, project revision, and
   touched-resource before revisions;
4. persist a `preparing` journal before any reservation or visible resource
   change;
5. stage and hash-verify every before/after payload;
6. persist the `staged` journal;
7. flush the pending idempotency reservation;
8. persist `prepared`, then `promoting`;
9. for each storage key in deterministic order, perform a second CAS, atomically
   replace that file, verify the result, and persist the entry checkpoint;
10. persist the committed receipt in the journal;
11. complete the idempotency record.

| Injected checkpoint | Durable interpretation after restart |
|---|---|
| `afterJournalPreparing` | Unreserved intent; safe to discard if all targets still match before state. |
| `afterPayloadsStaged` | Payloads may exist but journal remains preparing; still unreserved. |
| `afterJournalStaged` | Verified, unreserved staged intent; safe discard remains revision-gated. |
| `afterReservation` | Pending key plus staged transaction; explicit recovery required. |
| `afterJournalPrepared` | Pending, verified transaction; resume or compensate. |
| `beforeResourcePromotion` | No assumption; actual before/after revision decides recovery. |
| `afterResourcePromoted` | Resource may be after while checkpoint is old; actual revision reconciles it. |
| `afterResourceJournaled` | Checkpoint and actual state agree for that entry. |
| `afterJournalCommitted` | Resources and final journal are committed; recovery finalizes the pending ledger. |

Recovery never trusts the boolean entry checkpoint as proof that bytes were
written. It re-reads each touched resource and accepts only the exact staged
before or after fingerprint. Compensation applies in reverse deterministic
order and only changes a target that still matches the transaction's after
revision.

## Decisions and non-goals

- Staged `null` means intentional absence, so create and delete are first-class
  transaction changes rather than special cases.
- A standalone lock file is retained outside operation directories so deleting
  or retaining an operation cannot invalidate the active lock descriptor.
- Transaction artifacts are retained after completion; PMCP-024 consumes them
  for history/undo before a retention policy is introduced.
- Public errors contain stable codes and generic messages, never project paths
  or raw filesystem exceptions.
- The service does not invoke network access, Flutter, Flame, runtime internals,
  or editor UI.
- Multi-file atomicity, distributed locking, and writes made by tools that do
  not cooperate with PokeMap's lock are non-goals for this lot.

## TDD evidence

### Initial RED

Command:

```bash
cd packages/map_authoring
dart test test/transactions/crash_boundary_test.dart \
  test/transactions/recovery_idempotence_test.dart
```

Initial result: exit 1, `+0 -2`; compilation failed because the transaction
gateway, journal, executor, checkpoint, and recovery contracts did not yet
exist. This established that the new tests exercised missing behavior rather
than existing implementation.

### Intermediate critical RED and fix

The first implementation wrapped the entire exclusive-lock callback in its
lock-acquisition error sanitizer. Fault-injection and domain exceptions were
therefore incorrectly converted to generic `transaction.io` errors. The lock
scope was split so only acquisition failures are mapped; callback exceptions
now propagate while `finally` still unlocks and closes the descriptor.

### Final focused GREEN

Command:

```bash
cd packages/map_authoring
dart test test/transactions/crash_boundary_test.dart \
  test/transactions/recovery_idempotence_test.dart
```

Exact result:

```text
+20: All tests passed!
```

## Final commands and exact results

```bash
cd packages/map_authoring
dart test test/transactions
```

```text
+44: All tests passed!
```

```bash
cd packages/map_authoring
dart test
```

```text
+143: All tests passed!
```

```bash
cd packages/map_authoring
dart analyze
```

```text
Analyzing map_authoring...
No issues found!
```

```bash
cd packages/map_authoring
dart format --output=none --set-exit-if-changed lib test
```

```text
Formatted 69 files (0 changed) in 0.12 seconds.
```

```bash
cd packages/map_authoring
dart run bin/pokemap_authoring.dart \
  --root ../../examples/playable_runtime_host/p3_narrative_smoke_slice \
  </dev/null
```

```text
exit 0; stdout empty; stderr empty
```

```bash
git diff --check
```

```text
exit 0; no output
```

## Final Git state before commit

Expected staged scope is limited to the following paths:

```text
 M packages/map_authoring/lib/map_authoring.dart
 M packages/map_authoring/lib/src/transactions/idempotency_ledger.dart
 M packages/map_authoring/lib/src/transactions/plan_store.dart
?? packages/map_authoring/lib/src/ports/transaction_file_gateway.dart
?? packages/map_authoring/lib/src/transactions/journaled_transaction.dart
?? packages/map_authoring/lib/src/transactions/local_transaction_file_gateway.dart
?? packages/map_authoring/lib/src/transactions/recovery_service.dart
?? packages/map_authoring/lib/src/transactions/transaction_journal.dart
?? packages/map_authoring/test/support/transaction_test_fixture.dart
?? packages/map_authoring/test/transactions/crash_boundary_test.dart
?? packages/map_authoring/test/transactions/recovery_idempotence_test.dart
?? reports/analysis/pmcp_022_created_files_full_content.md
?? reports/analysis/pmcp_022_recoverable_transaction_evidence.md
```

No unrelated pre-existing change was present or absorbed.

## Critique finale and known limits

- The file lock coordinates PokeMap writers on the same filesystem; an external
  writer that ignores the lock can still race. A second touched-resource CAS is
  performed immediately before each promotion, but a small external race
  remains between that check and rename because the filesystem exposes no
  portable content-CAS primitive.
- File payloads and metadata are flushed before rename. This supports process
  crash recovery but is not a formal hardware power-loss guarantee: directory
  `fsync` is not exposed portably here.
- Completed journals and stages are intentionally retained and can grow until
  PMCP-024 adds history/blob retention and pruning.
- The durable scope depends on a stable caller-supplied project ID; deriving and
  persisting canonical project identity belongs to a later integration layer.
- `currentProjectRevision` must come from a trusted fresh snapshot. The
  touched-resource revision set remains the authoritative write gate in this
  lot.
- A compensation receipt retains the original forward structured diff and adds
  `recoveryOutcome: compensated`; consumers must inspect that outcome rather
  than interpreting the diff as a second forward apply.
- Journal and ledger records are strictly validated but not cryptographically
  authenticated against deliberate local tampering.

Given the explicit guarantee boundary and the fresh validation above, PMCP-022
can be proposed as `DONE`. PMCP-023 should add authorization, confirmation,
redaction, resource/rate limits, and append-only audit around this transaction
entry point.
