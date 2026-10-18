import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:map_core/map_core.dart';

import '../contracts/authoring_diff.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../contracts/resource_ref.dart';
import '../history/authoring_history.dart';
import '../history/content_blob_store.dart';
import '../history/file_history_store.dart';
import '../history/history_store.dart';
import '../ports/idempotency_store.dart';
import '../security/authoring_permission.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/change_set.dart';
import '../transactions/file_idempotency_store.dart';
import '../transactions/idempotency_ledger.dart';
import '../transactions/journaled_transaction.dart';
import '../transactions/plan_store.dart';
import '../transactions/recovery_service.dart';
import 'catalog_generation_retention.dart';
import 'catalog_storage_store.dart';

final class CatalogEditingPlan {
  CatalogEditingPlan._(this.plan, this.scope, this.operationId, this.root,
      this._lease, this._patch, this._owner);

  final AuthoringPlan plan;
  final AuthoringIdempotencyScope scope;
  final String operationId;
  final CatalogObjectReference root;
  CatalogStoragePatch? _patch;
  final Object _owner;
  bool _settled = false;
  bool _invalidated = false;
  final CatalogGenerationLease _lease;
}

final class CatalogEditingSession {
  CatalogEditingSession._({
    required this.store,
    required this.projectId,
    required this.actorId,
    required this.history,
    required this.blobs,
    required this.retention,
    required AuthoringIdempotencyLedger idempotency,
    required AuthoringTransactionFaultInjector? faultInjector,
    required DateTime Function() clock,
    required LeasedCatalogSnapshot reader,
  })  : _clock = clock,
        _plans = AuthoringPlanStore(clock: clock),
        _reader = reader,
        _snapshot = reader.snapshot {
    final recorder = AuthoringHistoryRecorder(store: history, blobs: blobs);
    _transaction = JournaledAuthoringTransaction(
        plans: _plans,
        gateway: store.gateway,
        idempotency: idempotency,
        clock: clock,
        faultInjector: faultInjector,
        commitHook: recorder);
    recovery = AuthoringRecoveryService(
        gateway: store.gateway,
        idempotency: idempotency,
        clock: clock,
        commitHook: recorder);
  }

  static Future<CatalogEditingSession> open({
    required CatalogStorageStore store,
    required String projectId,
    required String actorId,
    AuthoringHistoryStore? history,
    AuthoringContentBlobStore? blobs,
    AuthoringIdempotencyLedger? idempotency,
    AuthoringTransactionFaultInjector? faultInjector,
    DateTime Function()? clock,
  }) async {
    safeAuthoringSecurityIdentifier(actorId, 'actorId');
    safeAuthoringSecurityIdentifier(projectId, 'projectId');
    AuthoringIdempotencyScope(
        actorId: actorId,
        projectId: projectId,
        actionId: 'catalog.units.patch',
        actionVersion: 1,
        key: 'catalog-session-admission');
    final retention = CatalogGenerationRetention(store: store);
    await store.gateway.withExclusiveWriteLock(
        () => retention.bindProjectUnderLock(projectId));
    final reader = await retention.openSnapshot();
    try {
      await reader.snapshot.validate();
      return CatalogEditingSession._(
          store: store,
          projectId: projectId,
          actorId: actorId,
          history: history ??
              await FileAuthoringHistoryStore.open(
                  projectRoot: store.projectRoot),
          blobs: blobs ??
              await FileAuthoringContentBlobStore.open(
                  projectRoot: store.projectRoot),
          retention: retention,
          idempotency: idempotency ??
              AuthoringIdempotencyLedger(
                  store: FileIdempotencyStore(
                      filePath:
                          '${store.projectRoot}/.pokemap/authoring/idempotency.jsonl')),
          faultInjector: faultInjector,
          clock: clock ?? () => DateTime.now().toUtc(),
          reader: reader);
    } on Object {
      await reader.close();
      rethrow;
    }
  }

  final CatalogStorageStore store;
  final String projectId;
  final String actorId;
  final AuthoringHistoryStore history;
  final AuthoringContentBlobStore blobs;
  final CatalogGenerationRetention retention;
  final DateTime Function() _clock;
  final AuthoringPlanStore _plans;
  final Map<String, CatalogEditingPlan> _prepared = {};
  final Object _owner = Object();
  late final JournaledAuthoringTransaction _transaction;
  late final AuthoringRecoveryService recovery;
  LeasedCatalogSnapshot _reader;
  CatalogSnapshot _snapshot;
  bool _closed = false;
  Future<void> _pending = Future.value();

  CatalogSnapshot get snapshot {
    _requireOpen();
    return _snapshot;
  }

  Future<LeasedCatalogSnapshot> openSnapshot() {
    _requireOpen();
    return retention.openSnapshot();
  }

  Future<AuthoringReceipt?> reconcile(String operationId,
          {bool compensate = false}) =>
      _serialize(() => _reconcile(operationId, compensate: compensate));

  Future<AuthoringReceipt?> _reconcile(String operationId,
      {required bool compensate}) async {
    _requireOpen();
    final journal = await store.gateway.readJournal(operationId);
    if (journal == null ||
        journal.scope.projectId != projectId ||
        !journal.entries.any((entry) =>
            entry.storageKey == CatalogStorageStore.headStorageKey)) {
      throw const CatalogStorageException('catalog.operation_unknown',
          'The requested operation is not a catalog edit for this project.');
    }
    final inspection = await recovery.inspectOperation(
        operationId: operationId, scope: journal.scope);
    AuthoringReceipt? receipt;
    if (inspection!.disposition ==
        AuthoringRecoveryDisposition.unreservedIntent) {
      await recovery.discardUnreserved(operationId);
    } else {
      receipt = compensate
          ? await recovery.compensate(operationId)
          : await recovery.resume(operationId);
      await _transaction.cleanupCompletedReplay(
          scope: journal.scope,
          planId: journal.planId,
          operationId: operationId,
          receipt: receipt);
    }
    final reader = await retention.openSnapshot();
    try {
      await reader.snapshot.validate();
    } on Object {
      await reader.close();
      rethrow;
    }
    final previous = _reader;
    _reader = reader;
    _snapshot = reader.snapshot;
    await previous.close();
    await store.gateway.withExclusiveWriteLock(() async {
      for (final prepared in _prepared.values
          .where((plan) => plan.operationId == operationId)
          .toList()) {
        prepared._invalidated = true;
        prepared._patch = null;
        _prepared.remove(prepared.plan.planId);
        await _plans.discard(prepared.plan.planId);
      }
      if (await store.gateway.readJournal(operationId) == null) {
        await retention.releaseOwnerUnderLock(operationId);
      }
    });
    return receipt;
  }

  Future<CatalogEditingPlan> planPatch({
    Iterable<CatalogDefinitionUnit> upserts = const [],
    Iterable<CatalogDefinitionKey> removals = const [],
    required String idempotencyKey,
  }) =>
      _serialize(() => _planPatch(
          upserts: upserts,
          removals: removals,
          idempotencyKey: idempotencyKey));

  Future<CatalogEditingPlan> _planPatch({
    Iterable<CatalogDefinitionUnit> upserts = const [],
    Iterable<CatalogDefinitionKey> removals = const [],
    required String idempotencyKey,
  }) async {
    _requireOpen();
    final base = snapshot;
    final patch = await base.patch(upserts: upserts, removals: removals);
    if (patch.isEmpty) {
      throw const CatalogStorageException('catalog.no_changes',
          'The catalog edit does not change any definition.');
    }
    return store.gateway.withExclusiveWriteLock(() async {
      await _requireAdmission(base.root);
      final operationId = _token('operation_');
      final lease = await retention.protectUnderLock(
          roots: [patch.beforeRoot, patch.root],
          ownerId: operationId,
          purpose: CatalogLeasePurpose.preparation);
      try {
        await store.publishObjectsUnderLock(patch.objects);
        final next = await patch.nextSnapshot(readObject: lease.readObject);
        return _prepare(
            before: base.root,
            next: next,
            operationId: operationId,
            lease: lease,
            idempotencyKey: idempotencyKey,
            actionId: 'catalog.units.patch',
            context: AuthoringHistoryContext(),
            patch: patch);
      } on Object {
        await retention.releaseUnderLock(lease.id);
        rethrow;
      }
    });
  }

  Future<AuthoringReceipt> apply(CatalogEditingPlan prepared) =>
      _serialize(() => _apply(prepared));

  Future<AuthoringReceipt> _apply(CatalogEditingPlan prepared) async {
    _requireOpen();
    if (!identical(prepared._owner, _owner) ||
        prepared._invalidated ||
        (!prepared._settled &&
            !identical(_prepared[prepared.plan.planId], prepared))) {
      throw const CatalogStorageException('catalog.plan_unknown',
          'The prepared edit does not belong to this session.');
    }
    final replay = await _transaction.inspectReplay(
        scope: prepared.scope, plan: prepared.plan);
    if (replay != null) {
      await _transaction.cleanupCompletedReplay(
          scope: prepared.scope,
          planId: prepared.plan.planId,
          operationId: prepared.operationId,
          receipt: replay);
      if (!prepared._settled) await _refreshAfterApply(prepared);
      return replay;
    }
    if (prepared._settled || prepared._lease.closed) {
      throw const CatalogStorageException(
          'catalog.plan_unknown', 'The prepared edit is no longer active.');
    }
    final before =
        _decodeHead(prepared.plan.changeSet.changes.single.beforeBytes!);
    final context = AuthoringHistoryContext.fromExtensions(
        prepared.plan.request.extensions);
    final receipt = await _transaction.apply(
        planId: prepared.plan.planId,
        request: prepared.plan.request,
        currentProjectRevision: 'sha256:${snapshot.root.sha256}',
        scope: prepared.scope,
        operationId: prepared.operationId,
        precondition: () async {
          if (prepared._invalidated ||
              prepared._settled ||
              !identical(_prepared[prepared.plan.planId], prepared)) {
            throw const CatalogStorageException('catalog.plan_unknown',
                'The prepared edit is no longer active.');
          }
          await _requireAdmission(before, ownOperationId: prepared.operationId);
          if (context.expectedHeadEntryId != null) {
            final head = (await history.list(projectId: projectId, limit: 1))
                .entries
                .firstOrNull;
            if (head?.entryId != context.expectedHeadEntryId) {
              throw const AuthoringHistoryException(
                  'history.redo_branch_diverged',
                  'Redo is unsafe because the history branch changed.');
            }
          }
        });
    await _refreshAfterApply(prepared);
    return receipt;
  }

  Future<void> _refreshAfterApply(CatalogEditingPlan prepared) async {
    final nextReader = await retention.openSnapshot();
    final patch = prepared._patch;
    late final CatalogSnapshot next;
    try {
      next = nextReader.snapshot.root == prepared.root && patch != null
          ? await patch.nextSnapshot(readObject: nextReader.lease.readObject)
          : nextReader.snapshot;
      if (patch == null || nextReader.snapshot.root != prepared.root) {
        await next.validate();
      }
    } on Object {
      await nextReader.close();
      rethrow;
    }
    final previousReader = _reader;
    _reader = nextReader;
    _snapshot = next;
    await previousReader.close();
    await store.gateway.withExclusiveWriteLock(() async {
      if (await store.gateway.readJournal(prepared.operationId) == null) {
        await retention.releaseUnderLock(prepared._lease.id);
      }
    });
    prepared._settled = true;
    prepared._patch = null;
    _prepared.remove(prepared.plan.planId);
    await _plans.discard(prepared.plan.planId);
  }

  Future<AuthoringReceipt> undo(
          {required String entryId, required String idempotencyKey}) =>
      _serialize(() async =>
          _apply(await _planHistory(entryId, idempotencyKey, redo: false)));

  Future<AuthoringReceipt> redo(
          {required String entryId, required String idempotencyKey}) =>
      _serialize(() async =>
          _apply(await _planHistory(entryId, idempotencyKey, redo: true)));

  Future<CatalogEditingPlan> _planHistory(String entryId, String key,
      {required bool redo}) async {
    _requireOpen();
    return store.gateway.withExclusiveWriteLock(() async {
      await _requireAdmission(snapshot.root);
      final entry = await history.get(projectId: projectId, entryId: entryId);
      if (entry == null ||
          entry.nonUndoableReason != null ||
          entry.changes.length != 1 ||
          entry.changes.single.storageKey !=
              CatalogStorageStore.headStorageKey) {
        throw const AuthoringHistoryException('history.entry_missing',
            'The selected entry is not an undoable catalog edit.');
      }
      final latest = (await history.list(projectId: projectId, limit: 1))
          .entries
          .firstOrNull;
      if (redo &&
          (latest?.kind != AuthoringHistoryKind.undo ||
              latest?.targetEntryId != entryId)) {
        throw const AuthoringHistoryException('history.redo_branch_diverged',
            'Redo is unsafe because the history branch changed.');
      }
      final change = entry.changes.single;
      final expected = redo ? change.beforeRevision : change.afterRevision;
      if (await store.gateway
              .readResourceRevision(CatalogStorageStore.headStorageKey) !=
          expected) {
        throw const AuthoringHistoryException('history.resource_changed',
            'The catalog changed after the selected history entry.');
      }
      final blobId = redo ? change.afterBlobId : change.beforeBlobId;
      final payload = blobId == null ? null : await blobs.get(blobId);
      if (payload == null ||
          payload.byteLength > CatalogStorageStore.maximumHeadBytes) {
        throw const AuthoringHistoryException('history.blob_missing',
            'The retained catalog head is unavailable.');
      }
      final bytes = <int>[];
      await for (final chunk in payload.openRead()) {
        bytes.addAll(chunk);
        if (bytes.length > CatalogStorageStore.maximumHeadBytes) {
          throw const AuthoringHistoryException(
              'history.blob_revision_mismatch',
              'The retained catalog head exceeds its budget.');
        }
      }
      final targetRevision =
          redo ? change.afterRevision : change.beforeRevision;
      if (computeAuthoringBytesFingerprint(bytes,
              logicalName: CatalogStorageStore.headStorageKey) !=
          targetRevision) {
        throw const AuthoringHistoryException('history.blob_revision_mismatch',
            'The retained catalog head does not match history.');
      }
      final target = _decodeHead(bytes);
      final next = (await store.openRoot(target)).snapshot;
      await next.validate();
      final operationId = _token('operation_');
      final lease = await retention.protectUnderLock(
          roots: [snapshot.root, target],
          ownerId: operationId,
          purpose: CatalogLeasePurpose.preparation);
      try {
        return _prepare(
            before: snapshot.root,
            next: next,
            operationId: operationId,
            lease: lease,
            idempotencyKey: key,
            actionId: redo ? 'history.redo' : 'history.undo',
            context: AuthoringHistoryContext(
                kind: redo
                    ? AuthoringHistoryKind.redo
                    : AuthoringHistoryKind.undo,
                targetEntryId: entryId,
                expectedHeadEntryId: redo ? latest!.entryId : null),
            diff: redo
                ? entry.receipt.diff
                : invertAuthoringHistoryDiff(entry.receipt.diff));
      } on Object {
        await retention.releaseUnderLock(lease.id);
        rethrow;
      }
    });
  }

  CatalogEditingPlan _prepare(
      {required CatalogObjectReference before,
      required CatalogSnapshot next,
      required String operationId,
      required CatalogGenerationLease lease,
      required String idempotencyKey,
      required String actionId,
      required AuthoringHistoryContext context,
      AuthoringDiff? diff,
      CatalogStoragePatch? patch}) {
    final revision = 'sha256:${before.sha256}';
    final request = AuthoringRequest(
        requestId: _token('request_'),
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'catalog-session',
        expectedRevision: revision,
        idempotencyKey: idempotencyKey,
        parameters: {'beforeRoot': before.toJson(), 'root': next.root.toJson()},
        extensions: {'history': context.toJson()});
    final resource = AuthoringResourceRef(kind: 'catalogHead', id: 'catalog');
    final change = AuthoringResourceChange(
        resource: resource,
        storageKey: CatalogStorageStore.headStorageKey,
        beforeBytes: CatalogStorageStore.encodeHead(before),
        afterBytes: CatalogStorageStore.encodeHead(next.root));
    final now = _clock().toUtc();
    final plan = AuthoringPlan(
        planId: _token('plan_'),
        receiptId: _token('receipt_'),
        request: request,
        baseRevision: revision,
        seed: 0,
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 10)),
        changeSet: AuthoringChangeSet(
            changes: [change],
            diff: diff ??
                AuthoringDiff([
                  revisionHistoryDiff(resource,
                      beforeRevision: change.beforeRevision,
                      afterRevision: change.afterRevision)
                ])));
    _plans.save(plan);
    final prepared = CatalogEditingPlan._(
        plan,
        AuthoringIdempotencyScope(
            actorId: actorId,
            projectId: projectId,
            actionId: actionId,
            actionVersion: 1,
            key: idempotencyKey),
        operationId,
        next.root,
        lease,
        patch,
        _owner);
    _prepared[plan.planId] = prepared;
    return prepared;
  }

  Future<void> _requireAdmission(CatalogObjectReference expected,
      {String? ownOperationId}) async {
    for (final journal in await store.gateway.listJournals()) {
      if (journal.operationId != ownOperationId &&
          journal.entries.any((entry) =>
              entry.storageKey == CatalogStorageStore.headStorageKey)) {
        throw const CatalogStorageException('catalog.recovery_required',
            'Recover or discard the pending catalog transaction before editing.');
      }
    }
    if (await store.readHead() != expected) {
      throw const CatalogStorageException('catalog.revision_conflict',
          'The catalog generation changed before this edit.');
    }
  }

  Future<void> close() => _serialize(_close);

  Future<void> _close() async {
    if (_closed) return;
    _closed = true;
    await store.gateway.withExclusiveWriteLock(() async {
      for (final plan in _prepared.values) {
        if (await store.gateway.readJournal(plan.operationId) == null) {
          await retention.releaseUnderLock(plan._lease.id);
        }
      }
    });
    await _plans.dispose();
    await _reader.close();
  }

  void _requireOpen() {
    if (_closed) throw StateError('The catalog editing session is closed.');
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final previous = _pending;
    final completion = Completer<void>();
    _pending = completion.future;
    return () async {
      await previous;
      try {
        return await operation();
      } finally {
        completion.complete();
      }
    }();
  }
}

CatalogObjectReference _decodeHead(List<int> bytes) {
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map ||
      decoded.length != 2 ||
      decoded['schemaVersion'] != 1 ||
      decoded['root'] is! Map) {
    throw const FormatException('Invalid retained catalog head.');
  }
  final root = CatalogObjectReference.fromJson(
      Map<String, dynamic>.from(decoded['root'] as Map));
  if (utf8.decode(CatalogStorageStore.encodeHead(root)) != utf8.decode(bytes)) {
    throw const FormatException('Noncanonical retained catalog head.');
  }
  return root;
}

String _token(String prefix) =>
    '$prefix${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
