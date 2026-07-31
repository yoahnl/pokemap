# PokeMap Authoring API — Phase 3 Implementation Plan

> Phase: **3 — Noyau d’écriture sûre**
> Lots: **PMCP-020 → PMCP-024**
> Execution: current `main` branch, one verified commit per lot, no push
> Initial Git state: clean at `6cc96b86b feat(authoring): add read-only JSONL CLI`

## Goal and exit contract

Phase 3 adds the protocol-neutral write kernel that later domain actions and
the MCP adapter will use. It does not expose mutation commands in the Phase 2
JSONL worker and does not implement map/NPC/dialogue domain actions yet.

The phase is complete only when fresh tests prove all of the following:

- every mutation follows `plan -> preview -> validate -> apply -> receipt`;
- planning is pure and a stored plan freezes generated IDs, seed, diff,
  affected resources, reference impact, and preview artifacts;
- stale or expired plans cannot be applied;
- every touched resource is guarded by an expected canonical revision;
- a retry with the same scoped idempotency key and payload returns the same
  receipt without applying twice, including after reopening the durable store;
- a key reused with a different payload is rejected;
- multi-file writes are described as **recoverable**, remain atomic only per
  file, and can resume safely after every tested crash boundary;
- unexpected post-crash revisions block recovery instead of overwriting data;
- read-only is the default, risky writes require explicit scopes, destructive
  writes require a one-use confirmation bound to the exact plan, and every
  decision is audited without leaking paths or secrets;
- history is pageable and durable; undo, redo, and revision revert are new
  revision-checked transactions; divergent edits invalidate unsafe redo;
- mutation registration is refused without complete contract evidence.

## Audit and architecture decisions

### Existing boundaries retained

- `map_authoring` remains pure Dart and keeps `map_core` as its only production
  package dependency. The Phase 1 package-boundary test remains authoritative.
- Flutter/editor persistence types are not imported into `map_authoring`.
  Existing editor writers are implementation evidence, not a dependency.
- `dart:io` adapters may live beside the existing local read adapter, while
  their interfaces remain protocol-neutral and testable in memory.
- Opaque workspace/project handles continue to hide canonical roots. No
  contract, error, receipt, audit record, or CLI response may expose an
  absolute path.
- Existing `AuthoringRequest`, `AuthoringDiff`, `AuthoringReceipt`, action
  descriptors, snapshots, and reference diagnostics are extended by
  composition rather than replaced.
- `AuthoringGuarantee.atomic` is not claimed for multi-file portable storage.
  Phase 3 uses the term `recoverable` and proves atomic replacement per file.

### Write-kernel shape

```text
immutable ProjectSnapshot
          |
          v
  AuthoringActionPlanner -----> expiring AuthoringPlanStore
          |                              |
          | pure change set              | plan id
          v                              v
  AuthoringChangeSet ----------> authorization + confirmation
                                         |
                                         v
                               idempotency reservation
                                         |
                                         v
                            JournaledAuthoringTransaction
                               | CAS | stage | promote
                                         |
                           durable receipt + audit + history
                                         |
                              undo / redo / revert / batch
```

An `AuthoringResourceChange` owns an opaque `AuthoringResourceRef`, a private
safe relative storage key, immutable before/after bytes, and canonical
before/after fingerprints. Public JSON contains resource identities and
fingerprints, never payload bytes or machine paths.

Canonical fingerprints reuse `map_core`'s exported SHA-256 project fingerprint
primitive with stable logical entry names. Canonical JSON encoding sorts object
keys recursively before hashing, so map insertion order cannot change request
or idempotency identity.

### Inline review passes

Sub-agents are not requested for this run. Each lot therefore records these
independent named passes as required by `codex_rule.md`:

1. **Audit / Architecture** — boundary and invariant review before edits;
2. **Implementation** — surgical diff review against the lot scope;
3. **Tests** — positive, negative, guard, non-regression, RED/GREEN evidence;
4. **Build / Validation** — focused tests, full package tests, analyzer,
   formatter, and executable help smoke;
5. **Critique finale** — security, durability, recovery, and overclaim audit.

## Lot PMCP-020 — Plan, dry-run, and structured diff

### Files

- Create `packages/map_authoring/lib/src/transactions/authoring_plan.dart`
- Create `packages/map_authoring/lib/src/transactions/change_set.dart`
- Create `packages/map_authoring/lib/src/transactions/plan_store.dart`
- Create `packages/map_authoring/lib/src/transactions/action_planner.dart`
- Create `packages/map_authoring/lib/src/support/authoring_fingerprint.dart`
- Create `packages/map_authoring/test/transactions/action_planner_test.dart`
- Create `packages/map_authoring/test/transactions/stale_plan_test.dart`
- Modify `packages/map_authoring/lib/map_authoring.dart`
- Create `reports/analysis/pmcp_020_authoring_plan_evidence.md`

### TDD steps

- [ ] Write failing tests proving:
  - planning never invokes a write capability and leaves real fixture bytes
    unchanged;
  - one stored plan returns the same plan ID, seed, generated ID, change set,
    structured diff, reference impact, and artifacts on repeated resolution;
  - change sets reject duplicate resources, duplicate storage keys, unsafe
    relative keys, and fingerprints inconsistent with frozen bytes;
  - resolving with a different current project revision raises
    `plan.stale` with remediation;
  - resolving after TTL raises `plan.expired` with remediation;
  - invalid projected state is rejected before the plan enters the store.
- [ ] Run RED:

  ```bash
  cd packages/map_authoring
  dart test test/transactions/action_planner_test.dart \
    test/transactions/stale_plan_test.dart
  ```

- [ ] Implement immutable plan/change-set contracts, injected clock/token/seed
  factories, pure planning context, projected-state validator callback, and
  expiring in-memory plan store.
- [ ] Run focused GREEN, then:

  ```bash
  cd packages/map_authoring
  dart test test/transactions
  dart test
  dart analyze
  dart format --output=none --set-exit-if-changed lib test
  dart run bin/pokemap_authoring.dart \
    --root ../../examples/playable_runtime_host/p3_narrative_smoke_slice \
    </dev/null
  ```

- [ ] Record exact RED/GREEN output, file inventory, created-file contents,
  changed zones, fixture fingerprints, pass verdicts, risks, and Git state in
  the PMCP-020 evidence report.
- [ ] Commit only PMCP-020:

  ```bash
  git add -- packages/map_authoring \
    pokemap_authoring_api_mcp_phase_3_implementation_plan.md \
    reports/analysis/pmcp_020_authoring_plan_evidence.md
  git commit -m "feat(authoring): add safe mutation planning"
  ```

## Lot PMCP-021 — Compare-and-swap revisions and durable idempotency

### Files

- Create `packages/map_authoring/lib/src/transactions/revision_set.dart`
- Create `packages/map_authoring/lib/src/ports/idempotency_store.dart`
- Create `packages/map_authoring/lib/src/transactions/idempotency_ledger.dart`
- Create `packages/map_authoring/lib/src/transactions/file_idempotency_store.dart`
- Create `packages/map_authoring/test/transactions/revision_conflict_test.dart`
- Create `packages/map_authoring/test/transactions/idempotency_contract_test.dart`
- Modify Phase 3 transaction types and public barrel as needed
- Create `reports/analysis/pmcp_021_revision_idempotency_evidence.md`

### TDD steps

- [ ] Write failing tests proving:
  - revision sets are deterministic, per-resource, and reject malformed or
    duplicate fingerprints;
  - an external change to any touched resource yields a structured conflict
    and cannot reach the mutation callback;
  - the same actor/project/action/version/key and canonical payload returns the
    exact original receipt and increments apply count once;
  - replay still works after reconstructing the ledger from disk;
  - the same scoped key with a different payload is refused;
  - different actors, projects, action versions, or keys do not collide;
  - a durable pending reservation is reported as recovery-required rather than
    silently re-executed;
  - bounded retention prunes only expired completed records.
- [ ] Run RED:

  ```bash
  cd packages/map_authoring
  dart test test/transactions/revision_conflict_test.dart \
    test/transactions/idempotency_contract_test.dart
  ```

- [ ] Implement canonical payload fingerprints, atomic scoped reservations,
  completed receipt replay, payload conflict detection, injected clock,
  retention cleanup, and a locked/flush/rename JSON file store.
- [ ] Run focused GREEN and the full PMCP-020 validation matrix.
- [ ] Document evidence and commit only PMCP-021:

  ```bash
  git add -- packages/map_authoring \
    pokemap_authoring_api_mcp_phase_3_implementation_plan.md \
    reports/analysis/pmcp_021_revision_idempotency_evidence.md
  git commit -m "feat(authoring): add revision and idempotency guards"
  ```

## Lot PMCP-022 — Recoverable multi-file transactions

### Files

- Create `packages/map_authoring/lib/src/ports/transaction_file_gateway.dart`
- Create `packages/map_authoring/lib/src/transactions/transaction_journal.dart`
- Create `packages/map_authoring/lib/src/transactions/journaled_transaction.dart`
- Create `packages/map_authoring/lib/src/transactions/recovery_service.dart`
- Create `packages/map_authoring/lib/src/transactions/local_transaction_file_gateway.dart`
- Create `packages/map_authoring/test/transactions/crash_boundary_test.dart`
- Create `packages/map_authoring/test/transactions/recovery_idempotence_test.dart`
- Create or extend test fakes under
  `packages/map_authoring/test/support/transaction_test_fixture.dart`
- Modify the public barrel and earlier transaction types as required
- Create `reports/analysis/pmcp_022_recoverable_transaction_evidence.md`

### TDD steps

- [ ] Write failing filesystem-backed tests proving:
  - journal intent is flushed before any visible resource replacement;
  - before and after payloads are hash-verified before promotion;
  - each final resource replacement is atomic per file and promotions follow a
    deterministic order;
  - simulated crashes after journal preparation, staging, each promotion, and
    commit evidence are inspectable and resumable after constructing a new
    gateway/service instance;
  - repeated recovery is idempotent and converges on the same receipt/revision;
  - an unexpected current revision blocks forward recovery;
  - compensation restores only resources still matching the transaction's
    after revision and refuses unrelated edits;
  - a completed idempotency reservation is finalized during recovery if the
    process stopped after commit but before ledger completion.
- [ ] Run RED:

  ```bash
  cd packages/map_authoring
  dart test test/transactions/crash_boundary_test.dart \
    test/transactions/recovery_idempotence_test.dart
  ```

- [ ] Implement a journal state machine, safe logical-path gateway, verified
  staging, ordered atomic-per-file rename, exact revision gates, recovery
  inspection/resume/compensation, and deterministic receipt reconstruction.
- [ ] Add useful comments at crash boundaries explaining durable ordering and
  why multi-file atomicity is not claimed.
- [ ] Run focused GREEN and the full package validation matrix.
- [ ] Document evidence and commit only PMCP-022:

  ```bash
  git add -- packages/map_authoring \
    pokemap_authoring_api_mcp_phase_3_implementation_plan.md \
    reports/analysis/pmcp_022_recoverable_transaction_evidence.md
  git commit -m "feat(authoring): add recoverable write transactions"
  ```

## Lot PMCP-023 — Permissions, confirmations, redaction, limits, and audit

### Files

- Create `packages/map_authoring/lib/src/security/authoring_permission.dart`
- Create `packages/map_authoring/lib/src/security/authorization_policy.dart`
- Create `packages/map_authoring/lib/src/security/confirmation_token.dart`
- Create `packages/map_authoring/lib/src/security/output_redaction.dart`
- Create `packages/map_authoring/lib/src/security/audit_record.dart`
- Create `packages/map_authoring/lib/src/security/audit_log.dart`
- Create `packages/map_authoring/lib/src/security/secure_mutation_executor.dart`
- Create `packages/map_authoring/test/security/authorization_policy_test.dart`
- Create `packages/map_authoring/test/security/output_redaction_test.dart`
- Create `packages/map_authoring/test/security/audit_log_test.dart`
- Modify public exports and transaction entry point as required
- Create `reports/analysis/pmcp_023_authorization_audit_evidence.md`

### TDD steps

- [ ] Write failing tests proving:
  - an actor is read-only by default and indirect writes are denied;
  - planning, applying, recovering, asset writing, and network access require
    separate explicit scopes;
  - high/critical destructive changes require both scope and a non-expired,
    one-use confirmation token bound to actor, project, action, plan, and diff;
  - token replay or use against another plan is refused;
  - request size, touched-resource count, and rate limits fail before writes;
  - recursive redaction removes secret-like fields, bearer credentials,
    absolute POSIX/Windows paths, and internal exception text;
  - append-only audit records link actor/request/plan/receipt, decision, risk,
    and timestamp, survive reopen, and contain no secrets or absolute paths;
  - denied and failed attempts are audited as well as successful writes.
- [ ] Run RED:

  ```bash
  cd packages/map_authoring
  dart test test/security
  ```

- [ ] Implement least-privilege policy, server-side opaque confirmation store,
  deterministic limits, recursive redactor, locked/flushed JSONL audit sink,
  and a secure executor that authorizes before delegating to the transaction.
- [ ] Run focused GREEN and the full package validation matrix.
- [ ] Document evidence and commit only PMCP-023:

  ```bash
  git add -- packages/map_authoring \
    pokemap_authoring_api_mcp_phase_3_implementation_plan.md \
    reports/analysis/pmcp_023_authorization_audit_evidence.md
  git commit -m "feat(authoring): add mutation authorization and audit"
  ```

## Lot PMCP-024 — History, undo/redo, revert, batch, and mutation gate

### Files

- Create `packages/map_authoring/lib/src/history/authoring_history.dart`
- Create `packages/map_authoring/lib/src/history/history_store.dart`
- Create `packages/map_authoring/lib/src/history/file_history_store.dart`
- Create `packages/map_authoring/lib/src/history/content_blob_store.dart`
- Create `packages/map_authoring/lib/src/history/undo_service.dart`
- Create `packages/map_authoring/lib/src/history/revision_revert_service.dart`
- Create `packages/map_authoring/lib/src/transactions/batch_executor.dart`
- Create `packages/map_authoring/lib/src/registry/mutation_registry.dart`
- Create `packages/map_authoring/test/history/undo_redo_contract_test.dart`
- Create `packages/map_authoring/test/history/history_retention_test.dart`
- Create `packages/map_authoring/test/contract_kit/mutation_gate_test.dart`
- Modify the transaction commit hook and public barrel as required
- Create `reports/analysis/pmcp_024_history_undo_evidence.md`

### TDD steps

- [ ] Write failing tests proving:
  - durable history pagination is stable and newest-first with opaque cursors;
  - committed transactions retain content-addressed before/after blobs and do
    not duplicate identical payloads;
  - undo creates a new authorized, CAS-checked, idempotent transaction and
    refuses a resource changed since the original receipt;
  - redo after undo creates another transaction, while any divergent branch
    invalidates redo;
  - revision revert is a forward transaction to retained target bytes and is
    refused when its expected current head is stale;
  - expired/pruned blobs make an entry explicitly non-undoable with a stable
    reason rather than guessing;
  - batch combination is deterministic and rejects overlapping incompatible
    resource changes;
  - mutation registry admission fails unless contract evidence covers plan,
    dry-run, stale CAS, idempotency, recovery, authorization, receipt, and
    undo/non-undoable policy.
- [ ] Run RED:

  ```bash
  cd packages/map_authoring
  dart test test/history \
    test/contract_kit/mutation_gate_test.dart
  ```

- [ ] Implement durable history and blob stores, transaction commit recording,
  undo/redo/revert orchestration through the existing secure transaction path,
  deterministic batch composition, and the mandatory mutation registry gate.
- [ ] Run focused GREEN, all transaction/security/history tests, and then:

  ```bash
  cd packages/map_authoring
  dart test
  dart analyze
  dart format --output=none --set-exit-if-changed lib test
  dart run bin/pokemap_authoring.dart \
    --root ../../examples/playable_runtime_host/p3_narrative_smoke_slice \
    </dev/null
  ```

- [ ] Document evidence and commit only PMCP-024:

  ```bash
  git add -- packages/map_authoring \
    pokemap_authoring_api_mcp_phase_3_implementation_plan.md \
    reports/analysis/pmcp_024_history_undo_evidence.md
  git commit -m "feat(authoring): add mutation history and undo"
  ```

## Final Phase 3 verification

- [ ] Require a clean tree after the fifth lot commit.
- [ ] Re-run fresh package-wide tests, analyzer, formatter, and CLI help.
- [ ] Inspect the five commits and verify each contains one lot only.
- [ ] Confirm the Phase 2 JSONL worker remains read-only.
- [ ] Confirm no Flutter/Flame/editor/runtime import or new production package
  dependency entered `map_authoring`.
- [ ] Propose PMCP-020 through PMCP-024 as `DONE` only when the five evidence
  reports and fresh commands support it. Do not edit either roadmap unless the
  user explicitly asks.
