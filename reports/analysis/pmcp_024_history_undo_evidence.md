# PMCP-024 — History, Undo/Redo, Revert, Batch, and Mutation Gate Evidence Pack

Date: 2026-07-31

Phase: PokeMap Authoring API/MCP phase 3

Lot: PMCP-024

Proposed status: `DONE`

## Executive summary

PMCP-024 completes the safe-write kernel with:

- a durable, newest-first, snapshot-paginated history whose opaque cursors are
  project-bound and integrity checked;
- a content-addressed retained-payload store that deduplicates identical bytes
  and makes pruning explicit;
- a transaction commit recorder whose history write precedes idempotency
  completion and remains exact across recovery;
- undo and redo implemented as new authorized, revision-checked, idempotent
  forward transactions rather than filesystem rollback;
- revision revert implemented as a new forward transaction against a retained
  target state and an expected history head;
- apply-time and recovery-time history-head guards, under the transaction
  lock, so a branch created after planning invalidates redo/revert safely;
- deterministic batch composition with exact-overlap deduplication and
  incompatible payload or semantic overlap refusal;
- a mutation admission registry that requires proof of planning, dry-run,
  stale CAS, idempotency, recovery, authorization, receipt, and either undo or
  an explicit stable non-undoable policy.

Fresh end-of-lot evidence:

- focused history and mutation-gate suite: `+16: All tests passed!`;
- transaction, security, history, and mutation-gate suites:
  `+75: All tests passed!`;
- full `map_authoring` package: `+174: All tests passed!`;
- analyzer: `No issues found!`;
- formatter verification: 90 files, 0 changed;
- real read-only CLI smoke: exit 0, no output;
- `git diff --check`: exit 0, no output.

## Initial audit

The lot started from a clean tree at:

```text
abbe4ef27 feat(authoring): add mutation authorization and audit
```

PMCP-020 through PMCP-023 already supplied immutable planning, resource CAS,
durable scoped idempotency, recoverable multi-file transactions, authorization,
confirmation, redaction, and audit. The missing PMCP-024 capabilities were
durable mutation history, retained before/after payloads, user-facing recovery
operations, deterministic batch composition, and an enforceable registration
gate preventing incomplete mutation contracts from shipping.

The audit retained these boundaries:

- `map_authoring` stays pure Dart with no Flutter, Flame, editor, or runtime
  import and no new production dependency;
- storage keys and bytes remain internal transaction/history data; receipts and
  diffs expose typed resources and fingerprints, not machine paths or payloads;
- undo, redo, and revert use the PMCP-023 secure executor and PMCP-022 journal;
- multi-file behavior remains described as recoverable, never falsely atomic;
- the Phase 2 JSONL worker remains read-only; PMCP-024 does not expose mutation
  commands through CLI or MCP.

This is authoring infrastructure rather than a fangame mechanic. No `FG-*` lot
or mechanics-roadmap status changed.

## Named pass verdicts

No sub-agent was dispatched because repository/session instructions did not
authorize delegation. The required independent named passes were performed
locally:

| Pass | Verdict | Evidence |
|---|---|---|
| Audit / Architecture | PASS | Existing plan, CAS, journal, authorization, and audit APIs were composed; package boundaries and read-only CLI stayed unchanged. |
| TDD contract | PASS | Initial focused run failed at load with `+0 -3`; final focused run is +16. |
| Durable history | PASS | Reopen, stable snapshot pagination, newest-first order, cursor transport/tamper/project binding, first-reason persistence, and hash-chain verification pass. |
| Blob retention | PASS | Identical bytes share one content ID; reads verify content; explicit pruning removes blobs and produces stable non-undoability. |
| Transaction integration | PASS after recovery hardening | Normal commit records before idempotency completion; a hook interruption and recovery retain one exact entry. Recovery deliberately reuses the frozen intended receipt. |
| Undo/redo | PASS | Apply is authorized, CAS-checked, idempotent, and creates new history entries; external edits and missing blobs fail closed. |
| Branch concurrency | PASS after review fix | Redo and revert revalidate the expected head under the transaction lock. Recovery repeats the durable guard; unchanged heads resume and divergent heads fail. |
| Revision revert | PASS | Stale heads are refused, retained target bytes are applied forward, and the resulting branch invalidates redo. |
| Batch | PASS | Input order is irrelevant; exact overlaps deduplicate; conflicting payloads or structured-diff semantics raise `batch.overlap_conflict`. |
| Mutation gate | PASS | Every missing mandatory proof is rejected, and undo or a stable explicit non-undoable reason is compulsory. |
| Build / Validation | PASS | Focused, subsystem, full package, analyzer, formatter, CLI, and diff checks are green. |
| Critique finale | PASS with explicit limits | Retention, scaling, local-filesystem trust, and current adapter exposure limits are documented below. |

## File inventory and precise changed zones

### Modified files

- `packages/map_authoring/lib/map_authoring.dart`
  - lines 23–28: exports the history, retained-blob, undo, and revert APIs;
  - line 33: exports the mutation admission registry;
  - line 51: exports deterministic batch composition.
- `packages/map_authoring/lib/src/security/secure_mutation_executor.dart`
  - line 48: accepts an optional transaction precondition;
  - line 108: forwards it into the journaled apply while retaining the same
    authorization and audit boundary.
- `packages/map_authoring/lib/src/transactions/journaled_transaction.dart`
  - line 44: defines the asynchronous apply-precondition contract;
  - lines 69–82: installs the optional commit-history hook;
  - lines 90–98: evaluates non-replay preconditions inside the exclusive write
    lock and before plan/CAS mutation work;
  - lines 125–145: freezes history kind, target, and expected-head context in
    the intended receipt;
  - lines 287–296: persists committed history before returning to idempotency
    completion.
- `packages/map_authoring/lib/src/transactions/recovery_service.dart`
  - lines 54–63: accepts the same commit/history hook;
  - lines 112 and 175: records committed normal or resumed journals;
  - lines 120–127: revalidates durable redo/revert head constraints before
    forward recovery;
  - lines 472–507: reconstructs exact before/after changes from staged payloads
    and records the frozen intended receipt idempotently.

### Created production files

- `packages/map_authoring/lib/src/history/authoring_history.dart`
  - strict history kinds/context, retained-change and entry contracts, commit
    event, commit hook, and optional recovery guard.
- `packages/map_authoring/lib/src/history/history_store.dart`
  - cursor/page/store ports plus the idempotent commit recorder and durable
    recovery-head validation.
- `packages/map_authoring/lib/src/history/file_history_store.dart`
  - project-local locked/flushed hash-chained JSONL store and integrity-bound
    snapshot cursor pagination.
- `packages/map_authoring/lib/src/history/content_blob_store.dart`
  - locked content-addressed blob storage, verification, deduplication,
    enumeration, and explicit pruning.
- `packages/map_authoring/lib/src/history/undo_service.dart`
  - undoability inspection and secure undo/redo planning/application.
- `packages/map_authoring/lib/src/history/revision_revert_service.dart`
  - expected-head checked planning and secure forward revision revert.
- `packages/map_authoring/lib/src/transactions/batch_executor.dart`
  - deterministic composition, exact deduplication, and overlap refusal.
- `packages/map_authoring/lib/src/registry/mutation_registry.dart`
  - mandatory mutation evidence model and admission registry.

### Created tests

- `packages/map_authoring/test/history/history_retention_test.dart`
  - stable pagination, cursor guards, reopening, durable first reason, blob
    dedup/prune, and exact once-only history recording after hook interruption.
- `packages/map_authoring/test/history/undo_redo_contract_test.dart`
  - secure/idempotent undo/redo, CAS conflicts, pruned blobs, permission denial,
    post-plan branches, guarded recovery, revert, and redo invalidation.
- `packages/map_authoring/test/contract_kit/mutation_gate_test.dart`
  - missing proof rejection, undo/non-undoable requirement, deterministic batch,
    exact deduplication, and payload/semantic overlap conflicts.

### Reporting artifacts

- `reports/analysis/pmcp_024_history_undo_evidence.md`
  - this Evidence Pack.
- `reports/analysis/pmcp_024_created_files_full_content.md`
  - exact full content of all eleven created source/test files.

The appendix intentionally excludes itself and this report to prevent recursive
reporting content.

## History and retention contract

History events live under project-local authoring metadata. Each JSONL event
contains a strict sequence, previous digest, event payload, and deterministic
digest. Every read rebuilds and verifies the chain; unknown fields, reordered
or missing sequences, invalid updates, malformed JSON, and digest mismatches
fail closed.

Pagination is newest-first and snapshot-bound. The first page freezes the
maximum event sequence. Its opaque base64url cursor carries the project ID,
snapshot maximum, next sequence boundary, and integrity digest. Appends after
the first page therefore never leak into subsequent pages. Cursors transported
through their wire value work; tampering or reuse against another project is
rejected as `history.cursor_invalid`.

Before and after payloads are written to a fixed-logical-name content-addressed
blob store before the history event is appended. An identical byte sequence
therefore has one ID across entries. Reads recompute and verify the ID. Pruning
is explicit through a retain-ID set. Once a required blob is absent, the entry
is durably marked with the first stable reason (`history.blob_missing`) and no
undo/revert path guesses at replacement content.

## Commit and recovery ordering

For a non-replay mutation, the relevant sequence is:

1. acquire the project transaction write lock;
2. return an already completed idempotent receipt, if present;
3. execute any history-head precondition under that lock;
4. resolve the frozen plan and compare all resource revisions;
5. reserve idempotency, stage, promote, and commit the journal;
6. retain before/after blobs and append the history event;
7. complete the idempotency record and return the exact receipt.

If step 6 persists history and then raises before step 7, recovery reads the
staged before/after images and replays the same entry idempotently. It always
uses `journal.intendedReceipt`, not a recovery-decorated receipt, so identity
and canonical JSON remain exact.

Redo and revert receipts durably retain their expected history head. A pending
forward recovery asks the recorder's recovery guard to revalidate that head
before promoting bytes. Tests prove both sides: an unchanged head resumes and a
new divergent branch raises `history.redo_branch_diverged` without promotion.

## Undo, redo, and revert behavior

Undo requires all retained blobs and exact equality between each current
resource revision and the selected entry's after revision. Planning inverses
the structured diff and freezes current-to-before payload changes. Apply goes
through the existing secure executor, so `project.write`, audit, plan TTL,
project revision, per-resource CAS, and scoped idempotency all remain active.

Redo is allowed only while the current history head is the undo entry targeting
the requested original entry. The same predicate is checked again inside the
transaction lock and during recovery. Any intervening branch invalidates redo,
including a branch created after planning.

Revision revert requires the exact expected history head and creates a forward
change set from current bytes to the selected entry's retained after bytes. It
does not rewrite or remove history. The revert itself becomes the newest entry,
which intentionally invalidates an earlier redo branch.

## Batch and mutation admission gate

`AuthoringBatchExecutor` is pure. It canonicalizes input changes through the
existing `AuthoringChangeSet` ordering. Non-overlapping changes compose
independently of input order. The exact same resource/storage/payload/diff can
be repeated and is retained once. A shared resource or storage key with
different bytes, revisions, identity, or structured diff raises
`batch.overlap_conflict` before any transaction exists.

`AuthoringMutationRegistry` requires this core proof set:

```text
plan
dryRun
staleCas
idempotency
recovery
authorization
receipt
```

Admission additionally requires either `undo` or `nonUndoablePolicy`; the
latter must carry a stable safe reason and cannot be combined with undo proof.
Read-only descriptors cannot enter the mutation registry, duplicate
action/version registration is rejected, and listing is deterministic.

## TDD evidence

### Initial RED

Command:

```bash
cd packages/map_authoring
dart test test/history test/contract_kit/mutation_gate_test.dart
```

Initial result: exit 1, `+0 -3`. All three files failed to load because the
history/blob stores, undo/revert services, batch executor, mutation gate, and
transaction commit hook did not yet exist.

### Intermediate failures and fixes

The first undo apply reached the real transaction and exposed a contract
mismatch: attaching the before revision to `AuthoringResourceRef` made the
after revision set reject the same reference. The focused run ended `+7 -2`.
History-generated changes now keep before/after revisions in their explicit
CAS fields and use the opaque resource identity without embedding one side's
revision. The focused suite then passed.

The concurrency review then identified a plan/apply time-of-check gap for
history heads. A read-only precondition was moved under the transaction write
lock, expected heads were frozen in receipt context, and recovery gained the
same durable guard. New tests cover post-plan divergence, post-crash divergence,
and successful recovery with an unchanged head.

### Final focused GREEN

```bash
cd packages/map_authoring
dart test test/history test/contract_kit/mutation_gate_test.dart
```

```text
+16: All tests passed!
```

## Final commands and exact results

```bash
cd packages/map_authoring
dart test test/transactions test/security test/history \
  test/contract_kit/mutation_gate_test.dart
```

```text
+75: All tests passed!
```

```bash
cd packages/map_authoring
dart test
```

```text
+174: All tests passed!
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
Formatted 90 files (0 changed) in 0.15 seconds.
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

## Git state

Initial state:

```text
clean at abbe4ef27 feat(authoring): add mutation authorization and audit
```

Expected lot-only state immediately before staging:

```text
 M packages/map_authoring/lib/map_authoring.dart
 M packages/map_authoring/lib/src/security/secure_mutation_executor.dart
 M packages/map_authoring/lib/src/transactions/journaled_transaction.dart
 M packages/map_authoring/lib/src/transactions/recovery_service.dart
?? packages/map_authoring/lib/src/history/authoring_history.dart
?? packages/map_authoring/lib/src/history/content_blob_store.dart
?? packages/map_authoring/lib/src/history/file_history_store.dart
?? packages/map_authoring/lib/src/history/history_store.dart
?? packages/map_authoring/lib/src/history/revision_revert_service.dart
?? packages/map_authoring/lib/src/history/undo_service.dart
?? packages/map_authoring/lib/src/registry/mutation_registry.dart
?? packages/map_authoring/lib/src/transactions/batch_executor.dart
?? packages/map_authoring/test/contract_kit/mutation_gate_test.dart
?? packages/map_authoring/test/history/history_retention_test.dart
?? packages/map_authoring/test/history/undo_redo_contract_test.dart
?? reports/analysis/pmcp_024_created_files_full_content.md
?? reports/analysis/pmcp_024_history_undo_evidence.md
```

No unrelated pre-existing change was present or absorbed.

## Critique finale and known limits

- History is rebuilt and hash-verified from the complete JSONL file for each
  operation. This favors simple correctness in the local editor; very large
  histories will need checkpoint/index compaction with equivalent integrity.
- Blob retention policy is explicit but not automatically scheduled. A future
  host must choose age/size retention, compute the retain-ID set, and surface
  non-undoable transitions before pruning.
- The history and blob digest schemes detect accidental or unprivileged edits;
  they are not keyed signatures against an attacker already controlling the
  project filesystem.
- A torn final history append is rejected as corruption rather than silently
  truncated. Operational repair/compaction remains a later maintenance tool.
- Revert restores the resources represented by the selected history entry. It
  is not a whole-project checkpoint mechanism.
- In-process queues plus OS file locks serialize cooperative local writers.
  Hostile concurrent filesystem replacement remains outside the local project
  trust model.
- The generic transaction API remains public for trusted internal composition.
  Agent-facing adapters must register mutations through the gate and call the
  secure executor; exposing the low-level transaction would bypass policy.
- PMCP-024 supplies infrastructure, not domain mutation actions. The Phase 2
  JSONL worker is intentionally still read-only, and no MCP server is claimed.

With these limits explicit and all fresh checks green, PMCP-024 can be proposed
as `DONE`. Together with the four preceding verified commits, Phase 3 can also
be proposed as complete. The next dependency-ready lot is `PMCP-030` — canonical
map lifecycle — followed by the remaining Phase 4 map lots. Neither roadmap is
edited here because this task did not request roadmap status mutation.
