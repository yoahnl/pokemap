# PMCP-020 — Full created-file contents

This appendix is part of the PMCP-020 Evidence Pack and reproduces every production, test, and planning file created by the lot. The evidence report and this appendix exclude themselves to avoid recursive content.

## `pokemap_authoring_api_mcp_phase_3_implementation_plan.md`

~~~~~~~~markdown
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
~~~~~~~~

## `packages/map_authoring/lib/src/support/authoring_fingerprint.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/json_contract_support.dart';

/// Computes the same framed SHA-256 form used by project snapshots.
///
/// [logicalName] is part of the fingerprint domain. Callers must therefore use
/// the same stable logical name when comparing two revisions of one resource.
String computeAuthoringBytesFingerprint(
  List<int> bytes, {
  required String logicalName,
}) {
  return computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: logicalName,
      bytes: bytes,
    ),
  ]);
}

/// Encodes contract-safe JSON with recursively sorted object keys.
///
/// Dart map insertion order is not a protocol identity. Sorting here ensures
/// idempotency payloads and generated planning IDs remain stable across
/// transports that deserialize the same JSON with a different key order.
String canonicalAuthoringJson(Object? value) {
  final frozen = freezeContractJsonValue(value, field: 'value');
  return jsonEncode(_canonicalize(frozen));
}

String computeAuthoringJsonFingerprint(
  Object? value, {
  required String logicalName,
}) {
  return computeAuthoringBytesFingerprint(
    utf8.encode(canonicalAuthoringJson(value)),
    logicalName: logicalName,
  );
}

Object? _canonicalize(Object? value) {
  if (value is List<Object?>) {
    return [for (final item in value) _canonicalize(item)];
  }
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  return value;
}
~~~~~~~~
## `packages/map_authoring/lib/src/transactions/action_planner.dart`

~~~~~~~~dart
import 'dart:async';
import 'dart:math';

import '../contracts/authoring_request.dart';
import '../support/authoring_fingerprint.dart';
import '../workspace/project_snapshot.dart';
import 'authoring_plan.dart';
import 'plan_store.dart';

typedef AuthoringPlanTokenFactory = String Function(String prefix);
typedef AuthoringPlanSeedFactory = int Function();
typedef AuthoringMutationBuilder = FutureOr<AuthoringMutationDraft> Function(
  AuthoringPlanningContext context,
);
typedef ProjectedStateValidator = void Function(
  ProjectSnapshot snapshot,
  AuthoringMutationDraft draft,
);

/// Deterministic ID allocation available only during the pure planning pass.
final class AuthoringPlanningContext {
  AuthoringPlanningContext({
    required this.snapshot,
    required this.request,
    required this.planId,
    required this.seed,
  });

  final ProjectSnapshot snapshot;
  final AuthoringRequest request;
  final String planId;
  final int seed;
  final Map<String, int> _nextIndexByNamespace = {};

  String generateId(String namespace) {
    final normalized = namespace.trim();
    if (!RegExp(r'^[a-z][a-zA-Z0-9_]*$').hasMatch(normalized)) {
      throw ArgumentError.value(
        namespace,
        'namespace',
        'must be a stable lower-camel identifier',
      );
    }
    final index = _nextIndexByNamespace.update(
      normalized,
      (value) => value + 1,
      ifAbsent: () => 0,
    );
    final fingerprint = computeAuthoringJsonFingerprint(
      {
        'planId': planId,
        'seed': seed,
        'namespace': normalized,
        'index': index,
      },
      logicalName: 'generated-id.json',
    );
    return '${normalized}_${fingerprint.substring(7, 23)}';
  }
}

/// Builds and validates a plan without receiving any filesystem write port.
final class AuthoringActionPlanner {
  AuthoringActionPlanner({
    required AuthoringPlanStore store,
    AuthoringPlanTokenFactory? tokenFactory,
    AuthoringPlanSeedFactory? seedFactory,
  })  : _store = store,
        _tokenFactory = tokenFactory ?? _secureToken,
        _seedFactory = seedFactory ?? _secureSeed;

  final AuthoringPlanStore _store;
  final AuthoringPlanTokenFactory _tokenFactory;
  final AuthoringPlanSeedFactory _seedFactory;

  Future<AuthoringPlan> plan({
    required AuthoringRequest request,
    required ProjectSnapshot snapshot,
    required AuthoringMutationBuilder build,
    ProjectedStateValidator? validateProjectedState,
  }) async {
    final expectedRevision = request.expectedRevision;
    if (expectedRevision == null) {
      throw AuthoringPlanException(
        code: 'plan.expected_revision_required',
        message: 'Mutation planning requires an expected project revision.',
        remediation: const [
          'Reload the project and plan against its current revision.',
        ],
      );
    }
    if (expectedRevision != snapshot.revision) {
      throw AuthoringPlanException(
        code: 'plan.stale',
        message: 'The requested revision is not the current project revision.',
        remediation: const [
          'Create a new plan from the latest project revision.',
        ],
      );
    }

    final planId = _nextUniquePlanId();
    final receiptId = _validatedToken('receipt_');
    final seed = _seedFactory();
    if (seed < 0) {
      throw ArgumentError.value(seed, 'seedFactory', 'must not be negative');
    }
    final createdAt = _store.now;
    final context = AuthoringPlanningContext(
      snapshot: snapshot,
      request: request,
      planId: planId,
      seed: seed,
    );
    final draft = await build(context);
    validateProjectedState?.call(snapshot, draft);
    final plan = AuthoringPlan(
      planId: planId,
      receiptId: receiptId,
      request: request,
      baseRevision: snapshot.revision,
      seed: seed,
      createdAt: createdAt,
      expiresAt: createdAt.add(_store.ttl),
      changeSet: draft.changeSet,
      preview: draft.preview,
      referenceImpact: draft.referenceImpact,
      artifacts: draft.artifacts,
    );
    _store.save(plan);
    return plan;
  }

  String _nextUniquePlanId() {
    for (var attempt = 0; attempt < 32; attempt++) {
      final planId = _validatedToken('plan_');
      if (!_store.contains(planId)) return planId;
    }
    throw StateError('Unable to allocate a unique authoring plan identity.');
  }

  String _validatedToken(String prefix) {
    final rawValue = _tokenFactory(prefix);
    final value = rawValue.trim();
    if (value != rawValue ||
        !value.startsWith(prefix) ||
        value.length <= prefix.length) {
      throw ArgumentError.value(
        value,
        'tokenFactory',
        'must return a nonblank token beginning with $prefix',
      );
    }
    return value;
  }
}

String _secureToken(String prefix) {
  final random = Random.secure();
  final body = List.generate(
    24,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$prefix$body';
}

int _secureSeed() {
  final random = Random.secure();
  return random.nextInt(1 << 31);
}
~~~~~~~~

## `packages/map_authoring/lib/src/transactions/authoring_plan.dart`

~~~~~~~~dart
import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../contracts/json_contract_support.dart';
import 'change_set.dart';

/// Fully frozen output of one pure planning pass.
final class AuthoringPlan {
  AuthoringPlan({
    required String planId,
    required String receiptId,
    required this.request,
    required String baseRevision,
    required this.seed,
    required DateTime createdAt,
    required DateTime expiresAt,
    required this.changeSet,
    Map<String, Object?> preview = const {},
    Map<String, Object?> referenceImpact = const {},
    Iterable<AuthoringArtifactRef> artifacts = const [],
  })  : planId = _nonBlank(planId, 'planId'),
        receiptId = _nonBlank(receiptId, 'receiptId'),
        baseRevision = _revision(baseRevision, 'baseRevision'),
        createdAt = createdAt.toUtc(),
        expiresAt = expiresAt.toUtc(),
        preview = freezeContractJsonObject(preview, field: 'preview'),
        referenceImpact = freezeContractJsonObject(
          referenceImpact,
          field: 'referenceImpact',
        ),
        artifacts = _sortedArtifacts(artifacts) {
    if (!this.expiresAt.isAfter(this.createdAt)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'must be after createdAt',
      );
    }
    if (seed < 0) {
      throw ArgumentError.value(seed, 'seed', 'must not be negative');
    }
  }

  final String planId;
  final String receiptId;
  final AuthoringRequest request;
  final String baseRevision;
  final int seed;
  final DateTime createdAt;
  final DateTime expiresAt;
  final AuthoringChangeSet changeSet;
  final Map<String, Object?> preview;
  final Map<String, Object?> referenceImpact;
  final List<AuthoringArtifactRef> artifacts;

  String get projectedRevision => changeSet.projectedRevision;

  AuthoringReceipt toPlannedReceipt() {
    return AuthoringReceipt(
      receiptId: receiptId,
      requestId: request.requestId,
      actionId: request.actionId,
      actionVersion: request.actionVersion,
      status: AuthoringReceiptStatus.planned,
      beforeRevision: baseRevision,
      afterRevision: projectedRevision,
      createdAtUtc: createdAt.toIso8601String(),
      diff: changeSet.diff,
      artifacts: artifacts,
      extensions: {
        'planId': planId,
        'seed': seed,
        if (preview.isNotEmpty) 'preview': preview,
        if (referenceImpact.isNotEmpty) 'referenceImpact': referenceImpact,
      },
    );
  }

  Map<String, Object?> toJson() => {
        'planId': planId,
        'receiptId': receiptId,
        'requestId': request.requestId,
        'actionId': request.actionId,
        'actionVersion': request.actionVersion,
        'workspaceHandle': request.workspaceHandle,
        'baseRevision': baseRevision,
        'projectedRevision': projectedRevision,
        'seed': seed,
        'createdAtUtc': createdAt.toIso8601String(),
        'expiresAtUtc': expiresAt.toIso8601String(),
        'changeSet': changeSet.toJson(),
        'preview': preview,
        'referenceImpact': referenceImpact,
        'artifacts': [for (final artifact in artifacts) artifact.toJson()],
      };
}

/// Pure action-specific output before it is assigned an opaque plan identity.
final class AuthoringMutationDraft {
  AuthoringMutationDraft({
    required this.changeSet,
    Map<String, Object?> preview = const {},
    Map<String, Object?> referenceImpact = const {},
    Iterable<AuthoringArtifactRef> artifacts = const [],
  })  : preview = freezeContractJsonObject(preview, field: 'preview'),
        referenceImpact = freezeContractJsonObject(
          referenceImpact,
          field: 'referenceImpact',
        ),
        artifacts = _sortedArtifacts(artifacts);

  final AuthoringChangeSet changeSet;
  final Map<String, Object?> preview;
  final Map<String, Object?> referenceImpact;
  final List<AuthoringArtifactRef> artifacts;
}

List<AuthoringArtifactRef> _sortedArtifacts(
  Iterable<AuthoringArtifactRef> artifacts,
) {
  final byId = <String, AuthoringArtifactRef>{};
  for (final artifact in artifacts) {
    if (byId.containsKey(artifact.id)) {
      throw ArgumentError.value(
        artifact.id,
        'artifacts',
        'artifact identities must be unique',
      );
    }
    byId[artifact.id] = artifact;
  }
  return List.unmodifiable(
    byId.values.toList()..sort((left, right) => left.id.compareTo(right.id)),
  );
}

String _nonBlank(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized != value) {
    throw ArgumentError.value(value, field, 'must be nonblank and trimmed');
  }
  return normalized;
}

String _revision(String value, String field) {
  final normalized = _nonBlank(value, field);
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      field,
      'must be a lowercase SHA-256 fingerprint',
    );
  }
  return normalized;
}
~~~~~~~~

## `packages/map_authoring/lib/src/transactions/change_set.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';

import '../contracts/authoring_diff.dart';
import '../contracts/resource_ref.dart';
import '../support/authoring_fingerprint.dart';

/// Frozen before/after payloads for one opaque resource mutation.
///
/// [storageKey] is an internal project-relative capability used by the future
/// transaction gateway. It is deliberately omitted from public JSON so a
/// resource reference never becomes a filesystem API.
final class AuthoringResourceChange {
  AuthoringResourceChange({
    required this.resource,
    required String storageKey,
    required Iterable<int> beforeBytes,
    required Iterable<int> afterBytes,
    String? beforeRevision,
    String? afterRevision,
  })  : storageKey = _safeStorageKey(storageKey),
        beforeBytes = _freezeBytes(beforeBytes, 'beforeBytes'),
        afterBytes = _freezeBytes(afterBytes, 'afterBytes') {
    if (_bytesEqual(this.beforeBytes, this.afterBytes)) {
      throw ArgumentError.value(
        afterBytes,
        'afterBytes',
        'must differ from beforeBytes',
      );
    }
    final computedBefore = computeAuthoringBytesFingerprint(
      this.beforeBytes,
      logicalName: this.storageKey,
    );
    final computedAfter = computeAuthoringBytesFingerprint(
      this.afterBytes,
      logicalName: this.storageKey,
    );
    this.beforeRevision = _verifiedRevision(
      beforeRevision,
      computedBefore,
      'beforeRevision',
    );
    this.afterRevision = _verifiedRevision(
      afterRevision,
      computedAfter,
      'afterRevision',
    );
    if (resource.revision != null && resource.revision != this.beforeRevision) {
      throw ArgumentError.value(
        resource.revision,
        'resource.revision',
        'must match the frozen before revision',
      );
    }
  }

  final AuthoringResourceRef resource;
  final String storageKey;
  final List<int> beforeBytes;
  final List<int> afterBytes;
  late final String beforeRevision;
  late final String afterRevision;

  Map<String, Object?> toJson() => {
        'resource': resource.toJson(),
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'beforeByteLength': beforeBytes.length,
        'afterByteLength': afterBytes.length,
      };
}

/// Deterministically ordered resource payloads plus their structured diff.
final class AuthoringChangeSet {
  AuthoringChangeSet({
    required Iterable<AuthoringResourceChange> changes,
    required this.diff,
  }) : changes = _sortedChanges(changes) {
    if (this.changes.isEmpty) {
      throw ArgumentError.value(changes, 'changes', 'must not be empty');
    }
    final resources = <String>{};
    final storageKeys = <String>{};
    for (final change in this.changes) {
      if (!resources.add(_resourceKey(change.resource))) {
        throw ArgumentError.value(
          change.resource.toJson(),
          'changes',
          'resource changes must be unique',
        );
      }
      if (!storageKeys.add(change.storageKey)) {
        throw ArgumentError.value(
          change.storageKey,
          'changes',
          'storage keys must be unique',
        );
      }
    }
    final diffResources = {
      for (final resource in diff.affectedResources) _resourceKey(resource),
    };
    if (!_setsEqual(resources, diffResources)) {
      throw ArgumentError.value(
        diff.toJson(),
        'diff',
        'must describe every changed resource and no others',
      );
    }
    affectedResources = List.unmodifiable([
      for (final change in this.changes) change.resource,
    ]);
    // This revision covers the post-images of touched resources. It is a
    // deterministic preview identity, not a claim of multi-file atomicity.
    projectedRevision = computeNarrativeProjectFingerprint([
      for (final change in this.changes)
        NarrativeProjectFingerprintEntry(
          relativePath: change.storageKey,
          bytes: change.afterBytes,
        ),
    ]);
  }

  final List<AuthoringResourceChange> changes;
  final AuthoringDiff diff;
  late final List<AuthoringResourceRef> affectedResources;
  late final String projectedRevision;

  Map<String, Object?> toJson() => {
        'changes': [for (final change in changes) change.toJson()],
        'diff': diff.toJson(),
        'projectedRevision': projectedRevision,
      };
}

List<AuthoringResourceChange> _sortedChanges(
  Iterable<AuthoringResourceChange> changes,
) {
  final sorted = changes.toList()
    ..sort((left, right) {
      final resourceOrder =
          _resourceKey(left.resource).compareTo(_resourceKey(right.resource));
      return resourceOrder != 0
          ? resourceOrder
          : left.storageKey.compareTo(right.storageKey);
    });
  return List.unmodifiable(sorted);
}

String _safeStorageKey(String value) {
  final normalized = value.trim();
  final segments = normalized.split('/');
  if (normalized.isEmpty ||
      normalized != value ||
      normalized.startsWith('/') ||
      normalized.startsWith('./') ||
      RegExp(r'^[a-zA-Z]:/').hasMatch(normalized) ||
      normalized.contains('://') ||
      normalized.contains(r'\') ||
      normalized.contains('\u0000') ||
      segments.any(
          (segment) => segment.isEmpty || segment == '.' || segment == '..') ||
      segments.first == '.pokemap') {
    throw ArgumentError.value(
      value,
      'storageKey',
      'must be a safe project-relative resource key',
    );
  }
  return normalized;
}

List<int> _freezeBytes(Iterable<int> values, String field) {
  final bytes = values.toList(growable: false);
  if (bytes.any((value) => value < 0 || value > 255)) {
    throw ArgumentError.value(values, field, 'must contain bytes');
  }
  return List.unmodifiable(bytes);
}

String _verifiedRevision(
  String? supplied,
  String computed,
  String field,
) {
  if (supplied != null && supplied != computed) {
    throw ArgumentError.value(
      supplied,
      field,
      'does not match the frozen resource bytes',
    );
  }
  return computed;
}

String _resourceKey(AuthoringResourceRef resource) =>
    '${resource.kind}\u0000${resource.id}';

bool _setsEqual(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
~~~~~~~~

## `packages/map_authoring/lib/src/transactions/plan_store.dart`

~~~~~~~~dart
import 'authoring_plan.dart';

typedef AuthoringPlanClock = DateTime Function();

final class AuthoringPlanException implements Exception {
  AuthoringPlanException({
    required this.code,
    required this.message,
    Iterable<String> remediation = const [],
  }) : remediation = List.unmodifiable(remediation);

  final String code;
  final String message;
  final List<String> remediation;

  @override
  String toString() => 'AuthoringPlanException($code): $message';
}

/// In-memory store for opaque, short-lived plans.
///
/// Persistence starts only once a write journal is prepared. Keeping preview
/// plans ephemeral ensures an expired client proposal cannot become a latent
/// write intent after the project has changed.
final class AuthoringPlanStore {
  AuthoringPlanStore({
    AuthoringPlanClock? clock,
    this.ttl = const Duration(minutes: 10),
  }) : _clock = clock ?? _systemClock {
    if (ttl <= Duration.zero) {
      throw ArgumentError.value(ttl, 'ttl', 'must be positive');
    }
  }

  final AuthoringPlanClock _clock;
  final Duration ttl;
  final Map<String, AuthoringPlan> _plans = {};

  int get length => _plans.length;
  DateTime get now => _clock().toUtc();

  bool contains(String planId) => _plans.containsKey(planId);

  void save(AuthoringPlan plan) {
    if (_plans.containsKey(plan.planId)) {
      throw ArgumentError.value(
        plan.planId,
        'plan',
        'plan identity already exists',
      );
    }
    if (!plan.expiresAt.isAfter(now)) {
      throw ArgumentError.value(
        plan.expiresAt,
        'plan',
        'cannot save an expired plan',
      );
    }
    _plans[plan.planId] = plan;
  }

  AuthoringPlan resolve(
    String planId, {
    required String currentProjectRevision,
  }) {
    final plan = _plans[planId];
    if (plan == null) {
      throw AuthoringPlanException(
        code: 'plan.unknown',
        message: 'The requested authoring plan is unknown.',
        remediation: const ['Create a new plan before applying the mutation.'],
      );
    }
    if (!now.isBefore(plan.expiresAt)) {
      throw AuthoringPlanException(
        code: 'plan.expired',
        message: 'The requested authoring plan has expired.',
        remediation: const [
          'Create a new plan before applying the mutation.',
        ],
      );
    }
    if (currentProjectRevision != plan.baseRevision) {
      throw AuthoringPlanException(
        code: 'plan.stale',
        message: 'The project changed after this plan was created.',
        remediation: const [
          'Create a new plan from the latest project revision.',
        ],
      );
    }
    return plan;
  }

  bool discard(String planId) => _plans.remove(planId) != null;
}

DateTime _systemClock() => DateTime.now().toUtc();
~~~~~~~~

## `packages/map_authoring/test/transactions/action_planner_test.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringActionPlanner', () {
    test('plans a real-project change without writing fixture bytes', () async {
      final fixtureManifest = File(_fixtureManifestPath());
      final beforeFixtureBytes = await fixtureManifest.readAsBytes();
      final snapshot = _snapshot();
      final store = AuthoringPlanStore(
        clock: () => DateTime.utc(2026, 7, 31, 12),
      );
      var token = 0;
      final planner = AuthoringActionPlanner(
        store: store,
        tokenFactory: (prefix) => '$prefix${token++}',
        seedFactory: () => 73,
      );

      final plan = await planner.plan(
        request: _request(snapshot.revision),
        snapshot: snapshot,
        build: _draft,
        validateProjectedState: (snapshot, draft) {
          expect(snapshot.manifest.name, 'Planning Fixture');
          expect(draft.changeSet.changes, hasLength(1));
        },
      );

      expect(await fixtureManifest.readAsBytes(), beforeFixtureBytes);
      expect(plan.planId, 'plan_0');
      expect(plan.receiptId, 'receipt_1');
      expect(plan.seed, 73);
      expect(plan.baseRevision, snapshot.revision);
      expect(plan.changeSet.diff.entries, hasLength(1));
      expect(plan.changeSet.affectedResources.single.id, startsWith('map_'));
      expect(plan.referenceImpact, {
        'runtimeBlocking': false,
        'directDependents': <Object?>[],
      });
      expect(plan.artifacts.single.uri, 'artifact://preview/plan');
      expect(plan.toJson()['workspaceHandle'], 'workspace:fixture');
      expect(plan.toJson(), isNot(containsPair('projectHandle', anything)));
      expect(plan.toPlannedReceipt().status, AuthoringReceiptStatus.planned);
      expect(plan.toPlannedReceipt().afterRevision, plan.projectedRevision);
    });

    test('stores generated IDs seed diff impact and artifacts exactly once',
        () async {
      final snapshot = _snapshot();
      final store = AuthoringPlanStore(
        clock: () => DateTime.utc(2026, 7, 31, 12),
      );
      var builds = 0;
      final planner = AuthoringActionPlanner(
        store: store,
        tokenFactory: (prefix) => '${prefix}stable',
        seedFactory: () => 991,
      );

      final planned = await planner.plan(
        request: _request(snapshot.revision),
        snapshot: snapshot,
        build: (context) {
          builds++;
          return _draft(context);
        },
      );
      final first = store.resolve(
        planned.planId,
        currentProjectRevision: snapshot.revision,
      );
      final second = store.resolve(
        planned.planId,
        currentProjectRevision: snapshot.revision,
      );

      expect(builds, 1);
      expect(first, same(planned));
      expect(second, same(planned));
      expect(second.toJson(), first.toJson());
      expect(second.seed, 991);
      expect(
        second.preview['generatedId'],
        first.changeSet.affectedResources.single.id,
      );
      expect(second.toPlannedReceipt().toJson(),
          first.toPlannedReceipt().toJson());
    });

    test('validates projected state before publishing a plan', () async {
      final snapshot = _snapshot();
      final store = AuthoringPlanStore(
        clock: () => DateTime.utc(2026, 7, 31, 12),
      );
      final planner = AuthoringActionPlanner(
        store: store,
        tokenFactory: (prefix) => '${prefix}invalid',
        seedFactory: () => 1,
      );

      await expectLater(
        () => planner.plan(
          request: _request(snapshot.revision),
          snapshot: snapshot,
          build: _draft,
          validateProjectedState: (_, __) {
            throw const FormatException('invalid projected project');
          },
        ),
        throwsA(isA<FormatException>()),
      );
      expect(store.length, 0);
    });
  });

  group('AuthoringChangeSet', () {
    test('rejects duplicate resources and storage keys', () {
      final first = _change('first', 'maps/shared.json');
      final sameResource = _change('first', 'maps/other.json');
      final sameStorage = _change('second', 'maps/shared.json');

      expect(
        () => AuthoringChangeSet(
          changes: [first, sameResource],
          diff: _diffFor([first, sameResource]),
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringChangeSet(
          changes: [first, sameStorage],
          diff: _diffFor([first, sameStorage]),
        ),
        throwsArgumentError,
      );
    });

    test('rejects unsafe storage keys and inconsistent fingerprints', () {
      for (final storageKey in [
        '../project.json',
        '/tmp/project.json',
        r'maps\outside.json',
        'C:/tmp/project.json',
        './maps/map.json',
        '.pokemap/authoring/private.json',
      ]) {
        expect(
          () => _change('unsafe', storageKey),
          throwsArgumentError,
          reason: storageKey,
        );
      }

      expect(
        () => AuthoringResourceChange(
          resource: AuthoringResourceRef(kind: 'map', id: 'wrong-hash'),
          storageKey: 'maps/wrong-hash.json',
          beforeBytes: utf8.encode('{"value":0}'),
          afterBytes: utf8.encode('{"value":1}'),
          beforeRevision: 'sha256:${List.filled(64, 'a').join()}',
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResourceChange(
          resource: AuthoringResourceRef(
            kind: 'map',
            id: 'stale-ref',
            revision: 'sha256:${List.filled(64, 'a').join()}',
          ),
          storageKey: 'maps/stale-ref.json',
          beforeBytes: utf8.encode('{"value":0}'),
          afterBytes: utf8.encode('{"value":1}'),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a diff that does not describe every changed resource', () {
      final change = _change('changed', 'maps/changed.json');
      final other = AuthoringResourceRef(kind: 'map', id: 'other');

      expect(
        () => AuthoringChangeSet(
          changes: [change],
          diff: AuthoringDiff([
            AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource: other,
              path: r'$.name',
              before: 'Before',
              after: 'After',
            ),
          ]),
        ),
        throwsArgumentError,
      );
    });
  });
}

AuthoringMutationDraft _draft(AuthoringPlanningContext context) {
  final generatedId = context.generateId('map');
  final change = _change(generatedId, 'maps/$generatedId.json');
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [change],
      diff: _diffFor([change]),
    ),
    preview: {'generatedId': generatedId},
    referenceImpact: const {
      'runtimeBlocking': false,
      'directDependents': <Object?>[],
    },
    artifacts: [
      AuthoringArtifactRef(
        id: 'preview',
        mediaType: 'application/json',
        uri: 'artifact://preview/plan',
      ),
    ],
  );
}

AuthoringResourceChange _change(String id, String storageKey) {
  return AuthoringResourceChange(
    resource: AuthoringResourceRef(kind: 'map', id: id),
    storageKey: storageKey,
    beforeBytes: utf8.encode('{"id":"$id","name":"Before"}'),
    afterBytes: utf8.encode('{"id":"$id","name":"After"}'),
  );
}

AuthoringDiff _diffFor(Iterable<AuthoringResourceChange> changes) {
  return AuthoringDiff([
    for (final change in changes)
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: change.resource,
        path: r'$.name',
        before: 'Before',
        after: 'After',
      ),
  ]);
}

AuthoringRequest _request(String revision) {
  return AuthoringRequest(
    requestId: 'req-plan',
    actionId: 'maps.update',
    actionVersion: 1,
    workspaceHandle: 'workspace:fixture',
    parameters: const {'mapId': 'map-a'},
    expectedRevision: revision,
    idempotencyKey: 'idem-plan',
    dryRun: true,
  );
}

ProjectSnapshot _snapshot() {
  final revision = computeAuthoringBytesFingerprint(
    utf8.encode('planning snapshot'),
    logicalName: 'snapshot',
  );
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_planning'),
    revision: revision,
    manifest: ProjectManifest(
      name: 'Planning Fixture',
      maps: const [],
      tilesets: const [],
    ),
    maps: const [],
    resourceFingerprints: {'project': revision},
  );
}

String _fixtureManifestPath() {
  return [
    Directory.current.parent.parent.path,
    'examples',
    'playable_runtime_host',
    'p3_narrative_smoke_slice',
    'project.json',
  ].join(Platform.pathSeparator);
}
~~~~~~~~

## `packages/map_authoring/test/transactions/stale_plan_test.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringPlanStore', () {
    late DateTime now;
    late AuthoringPlanStore store;
    late ProjectSnapshot snapshot;
    late AuthoringActionPlanner planner;

    setUp(() {
      now = DateTime.utc(2026, 7, 31, 12);
      store = AuthoringPlanStore(
        clock: () => now,
        ttl: const Duration(minutes: 5),
      );
      snapshot = _snapshot('base');
      planner = AuthoringActionPlanner(
        store: store,
        tokenFactory: (prefix) => '${prefix}stale-test',
        seedFactory: () => 17,
      );
    });

    test('refuses a plan after an external project revision change', () async {
      final plan = await planner.plan(
        request: _request(snapshot.revision),
        snapshot: snapshot,
        build: _draft,
      );

      expect(
        () => store.resolve(
          plan.planId,
          currentProjectRevision: _snapshot('changed').revision,
        ),
        throwsA(
          isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'plan.stale')
              .having(
                (error) => error.remediation,
                'remediation',
                contains('Create a new plan from the latest project revision.'),
              ),
        ),
      );
    });

    test('refuses an expired plan with useful remediation', () async {
      final plan = await planner.plan(
        request: _request(snapshot.revision),
        snapshot: snapshot,
        build: _draft,
      );
      now = now.add(const Duration(minutes: 5));

      expect(
        () => store.resolve(
          plan.planId,
          currentProjectRevision: snapshot.revision,
        ),
        throwsA(
          isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'plan.expired')
              .having(
                (error) => error.remediation,
                'remediation',
                contains('Create a new plan before applying the mutation.'),
              ),
        ),
      );
    });

    test('rejects a stale expected revision before invoking the builder', () {
      var built = false;

      expect(
        () => planner.plan(
          request: _request(_snapshot('old-client').revision),
          snapshot: snapshot,
          build: (context) {
            built = true;
            return _draft(context);
          },
        ),
        throwsA(
          isA<AuthoringPlanException>().having(
            (error) => error.code,
            'code',
            'plan.stale',
          ),
        ),
      );
      expect(built, isFalse);
      expect(store.length, 0);
    });

    test('reports unknown opaque plan identifiers without leaking state', () {
      expect(
        () => store.resolve(
          'plan_missing',
          currentProjectRevision: snapshot.revision,
        ),
        throwsA(
          isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'plan.unknown')
              .having(
                (error) => error.toString(),
                'safe error',
                isNot(contains(DirectoryLikeAbsolutePath.marker)),
              ),
        ),
      );
    });
  });
}

abstract final class DirectoryLikeAbsolutePath {
  static const marker = '/Users/';
}

AuthoringMutationDraft _draft(AuthoringPlanningContext context) {
  final id = context.generateId('map');
  final resource = AuthoringResourceRef(kind: 'map', id: id);
  final change = AuthoringResourceChange(
    resource: resource,
    storageKey: 'maps/$id.json',
    beforeBytes: utf8.encode('{"name":"Before"}'),
    afterBytes: utf8.encode('{"name":"After"}'),
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [change],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resource,
          path: r'$.name',
          before: 'Before',
          after: 'After',
        ),
      ]),
    ),
  );
}

AuthoringRequest _request(String expectedRevision) {
  return AuthoringRequest(
    requestId: 'req-stale',
    actionId: 'maps.update',
    actionVersion: 1,
    workspaceHandle: 'workspace:test',
    expectedRevision: expectedRevision,
    idempotencyKey: 'idem-stale',
    dryRun: true,
  );
}

ProjectSnapshot _snapshot(String value) {
  final revision = computeAuthoringBytesFingerprint(
    utf8.encode(value),
    logicalName: 'snapshot',
  );
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_stale'),
    revision: revision,
    manifest: ProjectManifest(
      name: 'Stale Plan Fixture',
      maps: const [],
      tilesets: const [],
    ),
    maps: const [],
    resourceFingerprints: {'project': revision},
  );
}
~~~~~~~~
