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
import '../ports/transaction_file_gateway.dart';
import '../security/authoring_permission.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/authoring_payload.dart';
import '../transactions/change_set.dart';
import '../transactions/file_idempotency_store.dart';
import '../transactions/idempotency_ledger.dart';
import '../transactions/journaled_transaction.dart';
import '../transactions/plan_store.dart';
import '../transactions/recovery_service.dart';
import '../transactions/revision_set.dart';
import '../workspace/catalog/catalog_metadata_documents.dart';
import 'catalog_generation_retention.dart';
import 'catalog_history_compatibility.dart';
import 'catalog_history_transition.dart';
import 'catalog_revert_merge.dart';
import 'catalog_storage_store.dart';

final class CatalogEditingPlan {
  CatalogEditingPlan._(this.plan, this.scope, this._operationId, this.root,
      this._lease, this._patch, this._owner, this._currentProjectRevision);

  final AuthoringPlan plan;
  final AuthoringIdempotencyScope scope;
  String _operationId;
  String get operationId => _operationId;
  final CatalogObjectReference root;
  CatalogStoragePatch? _patch;
  Map<String, int>? _retentionCosts;
  List<AuthoringHistoryResourceChange>? _retentionChanges;
  final Object _owner;
  final Future<String> Function()? _currentProjectRevision;
  bool _settled = false;
  bool _invalidated = false;
  CatalogGenerationLease _lease;
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
    required bool incrementalHistory,
  })  : _clock = clock,
        _incrementalHistory = incrementalHistory,
        _plans = AuthoringPlanStore(clock: clock),
        _reader = reader,
        _snapshot = reader.snapshot {
    final recorder = AuthoringHistoryRecorder(
        store: history, blobs: blobs, catalogStore: store);
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
    bool incrementalHistory = false,
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
      await store.restoreIndexAdmission(reader.snapshot);
      final historyStore = history ??
          await FileAuthoringHistoryStore.open(
              projectRoot: store.projectRoot,
              incrementalWrites: incrementalHistory);
      if (historyStore is FileAuthoringHistoryStore) {
        await historyStore.ensureRetentionWindowIfEmpty(projectId);
      }
      return CatalogEditingSession._(
          store: store,
          projectId: projectId,
          actorId: actorId,
          incrementalHistory: incrementalHistory,
          history: historyStore,
          blobs: blobs ??
              await FileAuthoringContentBlobStore.open(
                  projectRoot: store.projectRoot),
          retention: retention,
          idempotency: idempotency ??
              AuthoringIdempotencyLedger(
                  store: FileIdempotencyStore(
                      incrementalWrites: incrementalHistory,
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
  final bool _incrementalHistory;
  final AuthoringPlanStore _plans;
  final Map<String, CatalogEditingPlan> _prepared = {};
  final Object _owner = Object();
  final Set<CatalogObjectReference> _preparedRetainedGenerations = {};
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
          {bool compensate = false,
          AuthoringTransactionPrecondition? precondition}) =>
      _serialize(() => _reconcile(operationId,
          compensate: compensate, precondition: precondition));

  Future<AuthoringReceipt?> _reconcile(String operationId,
      {required bool compensate,
      AuthoringTransactionPrecondition? precondition}) async {
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
          ? await recovery.compensate(operationId, precondition: precondition)
          : await recovery.resume(operationId, precondition: precondition);
      await _transaction.cleanupCompletedReplay(
          scope: journal.scope,
          planId: journal.planId,
          operationId: operationId,
          receipt: receipt);
    }
    final reader = await retention.openSnapshot();
    try {
      await store.restoreIndexAdmission(reader.snapshot);
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

  Future<void> prepareRetainedGenerationAdmissions(
      AuthoringHistoryEntry entry) async {
    if (entry.projectId != projectId || entry.nonUndoableReason != null) return;
    for (final change in entry.changes) {
      if (change.storageKey != CatalogStorageStore.headStorageKey) continue;
      for (final retained in [
        (change.beforeBlobId, change.beforeRevision),
        (change.afterBlobId, change.afterRevision)
      ]) {
        if (retained.$1 == null || retained.$2 == null) continue;
        final root = await _historyRoot(retained.$1!, retained.$2!);
        if (_preparedRetainedGenerations.contains(root)) continue;
        final historical = (await store.openRoot(root)).snapshot;
        List<CatalogDefinitionUnit>? units;
        try {
          await store.restoreIndexAdmission(historical);
        } on CatalogStorageException catch (error) {
          if (error.code != 'catalog.preparation_required') rethrow;
          units = await historical.readAllUnits();
          await store.publishIndexAdmissionUnderLock(historical);
        }
        if (!await store.metadataIndexPrepared(historical)) {
          units ??= await historical.readAllUnits();
          final initialized = CatalogMetadataDocuments.initialize(units);
          if (_metadataIndexesMatch(units, initialized)) {
            await store.publishMetadataIndexAdmissionUnderLock(historical);
          }
        }
        _preparedRetainedGenerations.add(root);
      }
    }
  }

  static bool _metadataIndexesMatch(Iterable<CatalogDefinitionUnit> units,
      Iterable<CatalogDefinitionUnit> initialized) {
    final byKey = {for (final unit in units) unit.key: unit};
    return initialized.every((unit) =>
        byKey[unit.key] != null &&
        canonicalAuthoringJson(byKey[unit.key]!.toJson()) ==
            canonicalAuthoringJson(unit.toJson()));
  }

  Future<void> prepareFinalizedJournals() => _serialize(() async {
        _requireOpen();
        await _transaction.prepareFinalizedJournals(
            requireHistory: (journal) => requireFinalizedJournalHistory(
                journal: journal, history: history, blobs: blobs));
      });

  Future<void> prepareMetadataDocuments({bool force = false}) =>
      _serialize(() async {
        _requireOpen();
        var prepared = !force && await store.metadataIndexPrepared(snapshot);
        if (prepared) {
          for (final field in CatalogMetadataDocuments.fields) {
            final marker =
                await snapshot.lookup(CatalogMetadataDocuments.fieldKey(field));
            if (marker?.payload['valid'] != true ||
                (field == 'trainers' &&
                    marker?.payload['trainerReferencesVersion'] != 1) ||
                (field == 'scenes' &&
                    marker?.payload['sceneDialogueReferencesVersion'] != 1) ||
                (field == 'storylines' &&
                    marker?.payload['stepReferencesVersion'] != 1)) {
              prepared = false;
              break;
            }
          }
        }
        if (prepared &&
            !await CatalogMetadataDocuments.narrativeEventIndexPrepared(
                snapshot)) {
          prepared = false;
        }
        if (prepared) return;
        final units = await snapshot.readAllUnits();
        final initialized = CatalogMetadataDocuments.initialize(units);
        if (_metadataIndexesMatch(units, initialized)) {
          await store.gateway.withExclusiveWriteLock(() async {
            await _requireAdmission(snapshot.root);
            await store.publishMetadataIndexAdmissionUnderLock(snapshot);
          });
          return;
        }
        final plan = await _planPatch(
            upserts: initialized,
            removals: const [],
            additionalChanges: const [],
            workspaceFingerprint: null,
            publicBaseRevision: null,
            publicDiff: null,
            publicPlan: null,
            currentProjectRevision: null,
            idempotencyKey: _token('metadata_prepare_'),
            request: null,
            prepareMetadataDocuments: true);
        await _apply(plan);
      });

  Future<CatalogEditingPlan> planPatch({
    Iterable<CatalogDefinitionUnit> upserts = const [],
    Iterable<CatalogDefinitionKey> removals = const [],
    Iterable<AuthoringResourceChange> additionalChanges = const [],
    String? workspaceFingerprint,
    String? publicBaseRevision,
    AuthoringDiff? publicDiff,
    AuthoringPlan? publicPlan,
    Future<String> Function()? currentProjectRevision,
    required String idempotencyKey,
    AuthoringRequest? request,
  }) =>
      _serialize(() => _planPatch(
          upserts: upserts,
          removals: removals,
          additionalChanges: additionalChanges,
          workspaceFingerprint: workspaceFingerprint,
          publicBaseRevision: publicBaseRevision,
          publicDiff: publicDiff,
          publicPlan: publicPlan,
          currentProjectRevision: currentProjectRevision,
          request: request,
          idempotencyKey: idempotencyKey));

  Future<CatalogEditingPlan> _planPatch({
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
    required Iterable<AuthoringResourceChange> additionalChanges,
    required String? workspaceFingerprint,
    required String? publicBaseRevision,
    required AuthoringDiff? publicDiff,
    required AuthoringPlan? publicPlan,
    required Future<String> Function()? currentProjectRevision,
    required String idempotencyKey,
    required AuthoringRequest? request,
    bool prepareMetadataDocuments = false,
  }) async {
    _requireOpen();
    final base = snapshot;
    final additional = additionalChanges.toList(growable: false);
    for (final change in additional) {
      _requireAdditionalPath(change.storageKey);
      if (change.resource.kind == 'catalogHead') {
        throw const CatalogStorageException('catalog.reserved_resource',
            'Catalog head resources are owned by the catalog transaction.');
      }
    }
    final units = upserts.toList();
    final deleted = removals.toList();
    if (!prepareMetadataDocuments &&
        (units.any((unit) =>
                unit.key.kind == CatalogDefinitionKind.workspaceState ||
                unit.references.any((key) =>
                    key.kind == CatalogDefinitionKind.workspaceState)) ||
            deleted.any(
                (key) => key.kind == CatalogDefinitionKind.workspaceState))) {
      throw const CatalogStorageException('catalog.reserved_resource',
          'Workspace state is owned by the catalog transaction.');
    }
    final revision = publicBaseRevision ??
        publicPlan?.baseRevision ??
        'sha256:${base.root.sha256}';
    if (additional.isNotEmpty &&
        (workspaceFingerprint == null || currentProjectRevision == null)) {
      throw const CatalogStorageException('catalog.workspace_state_required',
          'External resource edits require a canonical inventory fingerprint and revision guard.');
    }
    if (revision != 'sha256:${base.root.sha256}' &&
        currentProjectRevision == null) {
      throw const CatalogStorageException(
          'catalog.project_revision_guard_required',
          'A public project revision requires its canonical revision reader.');
    }
    if (workspaceFingerprint != null) {
      if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(workspaceFingerprint)) {
        throw const FormatException(
            'catalog.workspace: invalid inventory fingerprint');
      }
      final key = CatalogDefinitionKey(
          CatalogDefinitionKind.workspaceState, 'workspace');
      final existing = await base.lookup(key);
      if (additional.isNotEmpty &&
          existing?.payload['fingerprint'] == workspaceFingerprint) {
        throw const CatalogStorageException(
            'catalog.workspace_fingerprint_unchanged',
            'Changed resources must produce a changed canonical inventory fingerprint.');
      }
      units.add(CatalogDefinitionUnit(
          key: key,
          payload: {'id': 'workspace', 'fingerprint': workspaceFingerprint}));
    }
    units.addAll(await CatalogMetadataDocuments.maintain(
        lookup: base.lookup, upserts: units, removals: deleted));
    final patch = await base.patch(upserts: units, removals: deleted);
    if (patch.isEmpty) {
      throw const CatalogStorageException('catalog.no_changes',
          'The catalog edit does not change any definition.');
    }
    return store.gateway.withExclusiveWriteLock(() async {
      await _requireAdmission(base.root);
      await _requireProjectRevision(currentProjectRevision, revision);
      final operationId = _token('operation_');
      final lease = await retention.protectUnderLock(
          roots: [patch.beforeRoot, patch.root],
          ownerId: operationId,
          purpose: CatalogLeasePurpose.preparation);
      CatalogEditingPlan? prepared;
      try {
        final next = await patch.nextSnapshot(
            readObject: (reference) async =>
                patch.objects[reference.sha256] ??
                await lease.readObject(reference));
        prepared = _prepare(
            before: base.root,
            next: next,
            operationId: operationId,
            lease: lease,
            idempotencyKey: idempotencyKey,
            actionId: 'catalog.units.patch',
            context: AuthoringHistoryContext(),
            publicRequest: request,
            publicBaseRevision: revision,
            publicPlan: publicPlan,
            diff: publicDiff,
            additionalChanges: additional,
            currentProjectRevision: currentProjectRevision,
            patch: patch);
        await _checkRetentionCosts(prepared, projected: next);
        await store.publishObjectsUnderLock(patch.objects);
        await store.publishIndexAdmissionUnderLock(next);
        if (prepareMetadataDocuments ||
            await store.metadataIndexPrepared(base)) {
          await store.publishMetadataIndexAdmissionUnderLock(next);
        }
        return prepared;
      } on Object {
        if (prepared != null) {
          prepared._invalidated = true;
          _prepared.remove(prepared.plan.planId);
          await _plans.discard(prepared.plan.planId);
        }
        await retention.releaseUnderLock(lease.id);
        rethrow;
      }
    });
  }

  Future<AuthoringReceipt> apply(CatalogEditingPlan prepared,
          {String? operationId,
          AuthoringTransactionPrecondition? precondition,
          void Function()? beforeReservation,
          void Function()? preparationCheck}) =>
      _serialize(() => _apply(prepared,
          operationId: operationId,
          precondition: precondition,
          beforeReservation: beforeReservation,
          preparationCheck: preparationCheck));

  Future<AuthoringReceipt> _apply(CatalogEditingPlan prepared,
      {String? operationId,
      AuthoringTransactionPrecondition? precondition,
      void Function()? beforeReservation,
      void Function()? preparationCheck}) async {
    _requireOpen();
    if (!identical(prepared._owner, _owner) ||
        prepared._invalidated ||
        (!prepared._settled &&
            !identical(_prepared[prepared.plan.planId], prepared))) {
      throw const CatalogStorageException('catalog.plan_unknown',
          'The prepared edit does not belong to this session.');
    }
    if (operationId != null && operationId != prepared.operationId) {
      safeAuthoringSecurityIdentifier(operationId, 'operationId');
      if (prepared._settled) {
        throw const CatalogStorageException('catalog.operation_mismatch',
            'A completed plan cannot change its operation identity.');
      }
      await store.gateway.withExclusiveWriteLock(() async {
        await _requireAdmission(_decodeHead(
            _headChange(prepared.plan.changeSet.changes).beforeBytes!));
        if (await store.gateway.readJournal(operationId) != null) {
          throw const CatalogStorageException('catalog.operation_mismatch',
              'The operation identity is already in use.');
        }
        final lease = await retention.protectUnderLock(
            roots: prepared._lease.roots,
            ownerId: operationId,
            purpose: CatalogLeasePurpose.preparation);
        await retention.releaseUnderLock(prepared._lease.id);
        prepared._lease = lease;
        prepared._operationId = operationId;
      });
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
        _decodeHead(_headChange(prepared.plan.changeSet.changes).beforeBytes!);
    final context = AuthoringHistoryContext.fromExtensions(
        prepared.plan.request.extensions);
    final currentRevision = prepared._currentProjectRevision == null
        ? 'sha256:${snapshot.root.sha256}'
        : await prepared._currentProjectRevision();
    await _checkRetentionCosts(prepared);
    final receipt = await _transaction.apply(
        planId: prepared.plan.planId,
        request: prepared.plan.request,
        currentProjectRevision: currentRevision,
        scope: prepared.scope,
        operationId: prepared.operationId,
        beforeReservation: beforeReservation,
        preparationCheck: preparationCheck,
        precondition: () async {
          if (prepared._invalidated ||
              prepared._settled ||
              !identical(_prepared[prepared.plan.planId], prepared)) {
            throw const CatalogStorageException('catalog.plan_unknown',
                'The prepared edit is no longer active.');
          }
          await _requireAdmission(before, ownOperationId: prepared.operationId);
          await _requireProjectRevision(
              prepared._currentProjectRevision, prepared.plan.baseRevision);
          await _checkRetentionCosts(prepared);
          await precondition?.call();
          if (context.expectedHeadEntryId != null) {
            final head = await readAuthoringHistoryHead(history, projectId);
            if (head?.entryId != context.expectedHeadEntryId) {
              throw AuthoringHistoryException(
                  context.kind == AuthoringHistoryKind.redo
                      ? 'history.redo_branch_diverged'
                      : 'history.head_stale',
                  'The history branch changed after this plan was prepared.');
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
        await store.restoreIndexAdmission(next);
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
    prepared._retentionCosts = null;
    prepared._retentionChanges = null;
    _prepared.remove(prepared.plan.planId);
    await _plans.discard(prepared.plan.planId);
  }

  Future<void> _checkRetentionCosts(CatalogEditingPlan prepared,
      {CatalogSnapshot? projected}) async {
    final context = AuthoringHistoryContext.fromExtensions(
        prepared.plan.request.extensions);
    if (context.kind == AuthoringHistoryKind.undo ||
        context.kind == AuthoringHistoryKind.redo) {
      return;
    }
    final historyStore = history;
    if (historyStore is! FileAuthoringHistoryStore ||
        await historyStore.localWindow(projectId) == null) {
      return;
    }
    if (prepared._retentionCosts == null) {
      final next = projected ?? (await store.openRoot(prepared.root)).snapshot;
      final delta = await next.deltaFrom(snapshot);
      prepared.plan.bindCatalogDelta(delta);
      final costs = <String, int>{
        for (final reference in [
          ...delta.addedObjects,
          ...delta.removedObjects
        ])
          'catalog:${reference.sha256}': reference.byteLength
      };
      final changes = <AuthoringHistoryResourceChange>[];
      for (final change in prepared.plan.changeSet.changes) {
        Future<String?> blobId(AuthoringPayload? payload) async {
          if (payload == null) return null;
          final inspected = await inspectAuthoringPayload(payload.openRead(),
              storageKey: 'authoring-history-blob',
              byteLength: payload.byteLength);
          costs['blob:${inspected.resourceRevision.substring(7)}'] =
              inspected.byteLength;
          return inspected.resourceRevision;
        }

        changes.add(AuthoringHistoryResourceChange(
            resource: change.resource,
            storageKey: change.storageKey,
            beforeRevision: change.beforeRevision,
            afterRevision: change.afterRevision,
            beforeBlobId: await blobId(change.beforePayload),
            afterBlobId: await blobId(change.afterPayload)));
      }
      prepared._retentionCosts = Map.unmodifiable(costs);
      prepared._retentionChanges = List.unmodifiable(changes);
    }
    final plan = prepared.plan;
    final now = _clock().toUtc();
    final receipt = AuthoringReceipt(
        receiptId: plan.receiptId,
        requestId: plan.request.requestId,
        actionId: plan.request.actionId,
        actionVersion: plan.request.actionVersion,
        status: AuthoringReceiptStatus.applied,
        beforeRevision:
            AuthoringRevisionSet.beforeChangeSet(plan.changeSet).fingerprint,
        afterRevision:
            AuthoringRevisionSet.afterChangeSet(plan.changeSet).fingerprint,
        createdAtUtc: now.toIso8601String(),
        diff: plan.changeSet.diff,
        artifacts: plan.artifacts,
        extensions: {
          if (plan.nativeCreationCapability != null)
            'inventoryFingerprint':
                plan.nativeCreationCapability!.inventoryFingerprint,
          'planId': plan.planId,
          'operationId': prepared.operationId,
          'multiFileGuarantee': 'recoverable',
          'history': context.toJson(),
        });
    final entry = AuthoringHistoryEntry(
        entryId: plan.receiptId,
        projectId: projectId,
        actorId: actorId,
        planId: plan.planId,
        operationId: prepared.operationId,
        kind: context.kind,
        targetEntryId: context.targetEntryId,
        receipt: receipt,
        committedAt: now,
        changes: prepared._retentionChanges!,
        bulkCapability: plan.bulkCapability);
    final bytes = utf8.encode(canonicalAuthoringJson(entry.toJson()));
    await historyStore.checkRetentionCosts(projectId: projectId, costs: {
      ...prepared._retentionCosts!,
      'entry:${computeAuthoringBytesFingerprint(bytes, logicalName: 'history-preflight-entry.json').substring(7)}':
          bytes.length + 1024,
    });
  }

  Future<CatalogEditingPlan> planUndo(
          {required String entryId,
          required String idempotencyKey,
          String? operationId,
          AuthoringRequest? request,
          String? publicBaseRevision,
          Future<String> Function()? currentProjectRevision}) =>
      _serialize(() => _planHistory(entryId, idempotencyKey,
          redo: false,
          operationId: operationId,
          request: request,
          publicBaseRevision: publicBaseRevision,
          currentProjectRevision: currentProjectRevision));

  Future<CatalogEditingPlan> planRedo(
          {required String entryId,
          required String idempotencyKey,
          String? operationId,
          AuthoringRequest? request,
          String? publicBaseRevision,
          Future<String> Function()? currentProjectRevision}) =>
      _serialize(() => _planHistory(entryId, idempotencyKey,
          redo: true,
          operationId: operationId,
          request: request,
          publicBaseRevision: publicBaseRevision,
          currentProjectRevision: currentProjectRevision));

  Future<AuthoringReceipt> undo(
          {required String entryId,
          required String idempotencyKey,
          String? operationId,
          AuthoringRequest? request,
          String? publicBaseRevision,
          Future<String> Function()? currentProjectRevision,
          AuthoringTransactionPrecondition? precondition,
          void Function()? beforeReservation,
          void Function()? preparationCheck}) =>
      _serialize(() async => _apply(
          await _planHistory(entryId, idempotencyKey,
              redo: false,
              operationId: operationId,
              request: request,
              publicBaseRevision: publicBaseRevision,
              currentProjectRevision: currentProjectRevision),
          operationId: operationId,
          precondition: precondition,
          beforeReservation: beforeReservation,
          preparationCheck: preparationCheck));

  Future<AuthoringReceipt> redo(
          {required String entryId,
          required String idempotencyKey,
          String? operationId,
          AuthoringRequest? request,
          String? publicBaseRevision,
          Future<String> Function()? currentProjectRevision,
          AuthoringTransactionPrecondition? precondition,
          void Function()? beforeReservation,
          void Function()? preparationCheck}) =>
      _serialize(() async => _apply(
          await _planHistory(entryId, idempotencyKey,
              redo: true,
              operationId: operationId,
              request: request,
              publicBaseRevision: publicBaseRevision,
              currentProjectRevision: currentProjectRevision),
          operationId: operationId,
          precondition: precondition,
          beforeReservation: beforeReservation,
          preparationCheck: preparationCheck));

  Future<CatalogEditingPlan> _planHistory(String entryId, String key,
      {required bool redo,
      String? operationId,
      AuthoringRequest? request,
      String? publicBaseRevision,
      Future<String> Function()? currentProjectRevision}) async {
    _requireOpen();
    return store.gateway.withExclusiveWriteLock(() async {
      await _requireAdmission(snapshot.root);
      final entry =
          _incrementalHistory && history is AuthoringLocalHistoryReader
              ? await (history as AuthoringLocalHistoryReader)
                  .getLocalEntry(projectId: projectId, entryId: entryId)
              : await history.get(projectId: projectId, entryId: entryId);
      if (entry == null ||
          (!redo && entry.nonUndoableReason != null) ||
          entry.changes
                  .where((change) =>
                      change.storageKey == CatalogStorageStore.headStorageKey)
                  .length !=
              1) {
        throw const AuthoringHistoryException('history.entry_missing',
            'The selected entry is not an undoable catalog edit.');
      }
      final latest = await readAuthoringHistoryHead(history, projectId);
      final window = history is FileAuthoringHistoryStore
          ? await (history as FileAuthoringHistoryStore).localWindow(projectId)
          : null;
      final targetIndex = window == null
          ? null
          : redo
              ? window.cursor
              : window.cursor - 1;
      if (window != null &&
          (targetIndex! < 0 ||
              targetIndex >= window.entryIds.length ||
              window.entryIds[targetIndex] != entryId)) {
        throw AuthoringHistoryException(
            redo ? 'history.redo_branch_diverged' : 'history.head_stale',
            'The selected operation is not at the current history cursor.');
      }
      if (redo &&
          window == null &&
          (latest?.kind != AuthoringHistoryKind.undo ||
              latest?.targetEntryId != entryId)) {
        throw const AuthoringHistoryException('history.redo_branch_diverged',
            'Redo is unsafe because the history branch changed.');
      }
      if (entry.nonUndoableReason != null) {
        throw const AuthoringHistoryException('history.entry_missing',
            'The selected entry is not an undoable catalog edit.');
      }
      final change = entry.changes.singleWhere(
          (change) => change.storageKey == CatalogStorageStore.headStorageKey);
      if (change.beforeBlobId == null ||
          change.afterBlobId == null ||
          change.beforeRevision == null ||
          change.afterRevision == null) {
        throw const AuthoringHistoryException('history.blob_missing',
            'The retained catalog heads are unavailable.');
      }
      final originalBefore =
          await _historyRoot(change.beforeBlobId!, change.beforeRevision!);
      final originalAfter =
          await _historyRoot(change.afterBlobId!, change.afterRevision!);
      final conversions = <CatalogHistoryRootConversion>[];
      Future<CatalogObjectReference> resolve(
          CatalogObjectReference root) async {
        final conversion = window?.catalogConversions[root.sha256]?.conversion;
        if (conversion == null) return root;
        if (conversion.source != root) {
          throw const FormatException(
              'catalog.history: conversion source differs');
        }
        await store.requireHistoryConversion(conversion);
        conversions.add(conversion);
        return conversion.target;
      }

      final convertedBefore = await resolve(originalBefore);
      final convertedAfter = await resolve(originalAfter);
      final expected = redo ? convertedBefore : convertedAfter;
      final originalExpected = redo ? originalBefore : originalAfter;
      final currentRoot = snapshot.root;
      final currentHeadRevision = computeAuthoringBytesFingerprint(
          CatalogStorageStore.encodeHead(currentRoot),
          logicalName: CatalogStorageStore.headStorageKey);
      if (currentRoot != expected && currentRoot != originalExpected) {
        throw const AuthoringHistoryException('history.resource_changed',
            'The catalog changed after the selected history entry.');
      }
      if (await store.gateway
              .readResourceRevision(CatalogStorageStore.headStorageKey) !=
          currentHeadRevision) {
        throw const AuthoringHistoryException('history.resource_changed',
            'The catalog changed after the selected history entry.');
      }
      final target = redo ? convertedAfter : convertedBefore;
      final effectiveBefore = redo ? currentRoot : target;
      final effectiveAfter = redo ? target : currentRoot;
      final usedConversions = conversions
          .where((conversion) =>
              conversion.source == originalBefore &&
                  effectiveBefore != originalBefore ||
              conversion.source == originalAfter &&
                  effectiveAfter != originalAfter)
          .toSet();
      final transition = usedConversions.isEmpty
          ? null
          : await CatalogHistoryTransitionAttestation.verify(
              store: store,
              originalBeforeRoot: originalBefore,
              originalAfterRoot: originalAfter,
              effectiveBeforeRoot: effectiveBefore,
              effectiveAfterRoot: effectiveAfter,
              conversions: usedConversions);
      final next = (await store.openRoot(target)).snapshot;
      await _admitHistoricalSnapshot(next);
      final additional = <AuthoringResourceChange>[];
      final payloads = <AuthoringPayload>[];
      try {
        for (final resource in entry.changes) {
          if (resource.storageKey == CatalogStorageStore.headStorageKey) {
            continue;
          }
          _requireAdditionalPath(resource.storageKey);
          final beforeRevision =
              redo ? resource.beforeRevision : resource.afterRevision;
          final afterRevision =
              redo ? resource.afterRevision : resource.beforeRevision;
          if (await store.gateway.readResourceRevision(resource.storageKey) !=
              beforeRevision) {
            throw const AuthoringHistoryException('history.resource_changed',
                'A resource changed after the selected catalog transaction.');
          }
          Future<AuthoringPayload?> capture(
              String? id, String? revision) async {
            if (id == null) return null;
            final payload =
                await blobs.capturePayload(id, storageKey: resource.storageKey);
            if (payload == null) {
              throw const AuthoringHistoryException('history.blob_missing',
                  'A retained transaction resource is unavailable.');
            }
            payloads.add(payload);
            if (payload.resourceRevision != revision) {
              throw const AuthoringHistoryException(
                  'history.blob_revision_mismatch',
                  'A retained transaction resource does not match history.');
            }
            return payload;
          }

          additional.add(AuthoringResourceChange.withPayloads(
              resource: AuthoringResourceRef(
                  kind: resource.resource.kind,
                  id: resource.resource.id,
                  revision: beforeRevision,
                  extensions: resource.resource.extensions),
              storageKey: resource.storageKey,
              beforePayload: await capture(
                  redo ? resource.beforeBlobId : resource.afterBlobId,
                  beforeRevision),
              afterPayload: await capture(
                  redo ? resource.afterBlobId : resource.beforeBlobId,
                  afterRevision)));
        }
        final revision = publicBaseRevision ?? 'sha256:${snapshot.root.sha256}';
        if (revision != 'sha256:${snapshot.root.sha256}' &&
            currentProjectRevision == null) {
          throw const CatalogStorageException(
              'catalog.project_revision_guard_required',
              'A public project revision requires its canonical revision reader.');
        }
        await _requireProjectRevision(currentProjectRevision, revision);
        final selectedOperation = operationId ?? _token('operation_');
        safeAuthoringSecurityIdentifier(selectedOperation, 'operationId');
        final lease = await retention.protectUnderLock(
            roots: [snapshot.root, target],
            ownerId: selectedOperation,
            purpose: CatalogLeasePurpose.preparation);
        try {
          final prepared = _prepare(
              before: snapshot.root,
              next: next,
              operationId: selectedOperation,
              lease: lease,
              idempotencyKey: key,
              actionId: redo ? 'history.redo' : 'history.undo',
              additionalChanges: additional,
              publicRequest: request,
              publicBaseRevision: publicBaseRevision,
              currentProjectRevision: currentProjectRevision,
              context: AuthoringHistoryContext(
                  kind: redo
                      ? AuthoringHistoryKind.redo
                      : AuthoringHistoryKind.undo,
                  targetEntryId: entryId,
                  expectedHeadEntryId:
                      redo || window != null ? latest!.entryId : null),
              diff: catalogHistoryTransitionDiff(entry.receipt.diff,
                  redo: redo, attestation: transition));
          try {
            if (transition != null) {
              prepared.plan.bindCatalogHistory(transition);
            }
            await bindCanonicalBulkHistoryPlan(
                history: history,
                plan: prepared.plan,
                actorId: actorId,
                projectId: projectId,
                operationId: selectedOperation,
                catalogHistory: transition);
            return prepared;
          } on Object {
            prepared._invalidated = true;
            _prepared.remove(prepared.plan.planId);
            await _plans.discard(prepared.plan.planId);
            rethrow;
          }
        } on Object {
          await retention.releaseUnderLock(lease.id);
          rethrow;
        }
      } on Object {
        await releaseAuthoringPayloads(payloads);
        rethrow;
      }
    });
  }

  Future<void> _admitHistoricalSnapshot(CatalogSnapshot next) async {
    try {
      await store.restoreIndexAdmission(next);
      return;
    } on CatalogStorageException catch (error) {
      if (error.code != 'catalog.preparation_required') rethrow;
    }
    final delta = await next.admitFrom(snapshot);
    if (await store.metadataIndexPrepared(snapshot)) {
      final expected = await CatalogMetadataDocuments.maintain(
          lookup: snapshot.lookup,
          upserts: delta.upserts,
          removals: delta.removals);
      final expectedByKey = {for (final unit in expected) unit.key: unit};
      for (final unit in delta.upserts) {
        if (unit.key.kind != CatalogDefinitionKind.workspaceState ||
            unit.key.id == 'workspace') {
          continue;
        }
        final canonical = expectedByKey[unit.key];
        if (canonical == null ||
            canonicalAuthoringJson(unit.toJson()) !=
                canonicalAuthoringJson(canonical.toJson())) {
          throw const CatalogStorageException('catalog.preparation_required',
              'The selected historical document indexes need explicit preparation.');
        }
      }
      for (final unit in expected) {
        final actual = await next.lookup(unit.key);
        if (actual == null ||
            canonicalAuthoringJson(actual.toJson()) !=
                canonicalAuthoringJson(unit.toJson())) {
          throw const CatalogStorageException('catalog.preparation_required',
              'The selected historical document indexes differ from their changes.');
        }
      }
      await store.publishMetadataIndexAdmissionUnderLock(next);
    }
    await store.publishIndexAdmissionUnderLock(next);
  }

  Future<CatalogEditingPlan> planRevert({
    required String entryId,
    required String expectedHeadEntryId,
    required String idempotencyKey,
    required Future<String> Function(
            CatalogSnapshot projected, List<AuthoringResourceChange> changes)
        validateProjection,
    required Future<String> Function() currentProjectRevision,
    String? operationId,
    AuthoringRequest? request,
    String? publicBaseRevision,
  }) =>
      _serialize(() => _planRevert(
          entryId: entryId,
          expectedHeadEntryId: expectedHeadEntryId,
          idempotencyKey: idempotencyKey,
          validateProjection: validateProjection,
          currentProjectRevision: currentProjectRevision,
          operationId: operationId,
          request: request,
          publicBaseRevision: publicBaseRevision));

  Future<CatalogEditingPlan> _planRevert({
    required String entryId,
    required String expectedHeadEntryId,
    required String idempotencyKey,
    required Future<String> Function(
            CatalogSnapshot projected, List<AuthoringResourceChange> changes)
        validateProjection,
    required Future<String> Function() currentProjectRevision,
    String? operationId,
    AuthoringRequest? request,
    String? publicBaseRevision,
  }) async {
    _requireOpen();
    final selectedOperation = operationId ?? _token('operation_');
    safeAuthoringSecurityIdentifier(selectedOperation, 'operationId');
    return store.gateway.withExclusiveWriteLock(() async {
      await _requireAdmission(snapshot.root);
      final latest = await readAuthoringHistoryHead(history, projectId);
      if (latest?.entryId != expectedHeadEntryId) {
        throw const AuthoringHistoryException('history.head_stale',
            'The current history head differs from the expected head.');
      }
      final target = await history.get(projectId: projectId, entryId: entryId);
      final heads = target?.changes
          .where((change) =>
              change.storageKey == CatalogStorageStore.headStorageKey)
          .toList();
      if (target == null ||
          target.nonUndoableReason != null ||
          heads?.length != 1 ||
          heads!.single.beforeBlobId == null ||
          heads.single.afterBlobId == null) {
        throw const AuthoringHistoryException('history.entry_missing',
            'The selected entry is not a retained catalog mutation.');
      }
      final beforeRoot = await _historyRoot(
          heads.single.beforeBlobId!, heads.single.beforeRevision!);
      final afterRoot = await _historyRoot(
          heads.single.afterBlobId!, heads.single.afterRevision!);
      final before = (await store.openRoot(beforeRoot)).snapshot;
      final after = (await store.openRoot(afterRoot)).snapshot;
      final delta = await CatalogRevertDelta.between(
          before: before, after: after, current: snapshot);
      final upserts = delta.upserts;
      final removals = delta.removals;
      final additional = <AuthoringResourceChange>[];
      final payloads = <AuthoringPayload>[];
      try {
        for (final resource in target.changes) {
          if (resource.storageKey == CatalogStorageStore.headStorageKey) {
            continue;
          }
          _requireAdditionalPath(resource.storageKey);
          final currentRevision =
              await store.gateway.readResourceRevision(resource.storageKey);
          if (currentRevision == resource.afterRevision) continue;
          final current =
              await store.gateway.captureResourcePayload(resource.storageKey);
          if (current != null) payloads.add(current);
          final desired = resource.afterBlobId == null
              ? null
              : await blobs.capturePayload(resource.afterBlobId!,
                  storageKey: resource.storageKey);
          if (desired != null) payloads.add(desired);
          if (current?.resourceRevision != currentRevision ||
              desired?.resourceRevision != resource.afterRevision) {
            throw const AuthoringHistoryException(
                'history.blob_revision_mismatch',
                'A retained or current resource does not match its revision.');
          }
          additional.add(AuthoringResourceChange.withPayloads(
              resource: AuthoringResourceRef(
                  kind: resource.resource.kind,
                  id: resource.resource.id,
                  revision: currentRevision,
                  extensions: resource.resource.extensions),
              storageKey: resource.storageKey,
              beforePayload: current,
              afterPayload: desired));
        }
        if (upserts.isEmpty && removals.isEmpty && additional.isEmpty) {
          throw const AuthoringHistoryException(
              'history.revert_noop', 'The selected state is already current.');
        }
        final revision = publicBaseRevision ?? await currentProjectRevision();
        await _requireProjectRevision(currentProjectRevision, revision);
        final candidate =
            await snapshot.patch(upserts: upserts, removals: removals);
        Future<List<int>> candidateRead(
                CatalogObjectReference reference) async =>
            candidate.objects[reference.sha256] ??
            await store.readObject(reference);
        final projected =
            await candidate.nextSnapshot(readObject: candidateRead);
        final fingerprint =
            await validateProjection(projected, List.unmodifiable(additional));
        if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(fingerprint)) {
          throw const FormatException(
              'catalog.workspace: invalid inventory fingerprint');
        }
        final stateKey = CatalogDefinitionKey(
            CatalogDefinitionKind.workspaceState, 'workspace');
        if (additional.isNotEmpty &&
            (await snapshot.lookup(stateKey))?.payload['fingerprint'] ==
                fingerprint) {
          throw const CatalogStorageException(
              'catalog.workspace_fingerprint_unchanged',
              'Changed resources must produce a changed canonical inventory fingerprint.');
        }
        final patch = await snapshot.patch(upserts: [
          ...upserts,
          CatalogDefinitionUnit(
              key: stateKey,
              payload: {'id': 'workspace', 'fingerprint': fingerprint}),
        ], removals: removals);
        final lease = await retention.protectUnderLock(
            roots: [snapshot.root, patch.root],
            ownerId: selectedOperation,
            purpose: CatalogLeasePurpose.preparation);
        try {
          final next = await patch.nextSnapshot(
              readObject: (reference) async =>
                  patch.objects[reference.sha256] ??
                  await lease.readObject(reference));
          final prepared = _prepare(
              before: snapshot.root,
              next: next,
              operationId: selectedOperation,
              lease: lease,
              idempotencyKey: idempotencyKey,
              actionId: 'history.revert',
              context: AuthoringHistoryContext(
                  kind: AuthoringHistoryKind.revert,
                  targetEntryId: entryId,
                  expectedHeadEntryId: expectedHeadEntryId),
              publicRequest: request,
              publicBaseRevision: revision,
              currentProjectRevision: currentProjectRevision,
              additionalChanges: additional,
              patch: patch);
          try {
            final attestation = target.bulkCapability == null
                ? null
                : await CatalogRevertMergeAttestation.verify(
                    current: snapshot,
                    targetBefore: before,
                    targetAfter: after,
                    result: next);
            await bindCanonicalBulkHistoryPlan(
                history: history,
                plan: prepared.plan,
                actorId: actorId,
                projectId: projectId,
                operationId: selectedOperation,
                catalogRevert: attestation);
            await _checkRetentionCosts(prepared, projected: next);
            await store.publishObjectsUnderLock(patch.objects);
            await store.publishIndexAdmissionUnderLock(next);
            return prepared;
          } on Object {
            prepared._invalidated = true;
            _prepared.remove(prepared.plan.planId);
            await _plans.discard(prepared.plan.planId);
            rethrow;
          }
        } on Object {
          await retention.releaseUnderLock(lease.id);
          rethrow;
        }
      } on Object {
        await releaseAuthoringPayloads(payloads);
        rethrow;
      }
    });
  }

  Future<CatalogObjectReference> _historyRoot(
      String blobId, String revision) async {
    final payload = await blobs.get(blobId);
    if (payload == null ||
        payload.byteLength > CatalogStorageStore.maximumHeadBytes) {
      throw const AuthoringHistoryException(
          'history.blob_missing', 'The retained catalog head is unavailable.');
    }
    final bytes = <int>[];
    await for (final chunk in payload.openRead()) {
      bytes.addAll(chunk);
      if (bytes.length > CatalogStorageStore.maximumHeadBytes) {
        throw const AuthoringHistoryException('history.blob_revision_mismatch',
            'The retained catalog head exceeds its budget.');
      }
    }
    if (computeAuthoringBytesFingerprint(bytes,
            logicalName: CatalogStorageStore.headStorageKey) !=
        revision) {
      throw const AuthoringHistoryException('history.blob_revision_mismatch',
          'The retained catalog head does not match history.');
    }
    return _decodeHead(bytes);
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
      AuthoringRequest? publicRequest,
      String? publicBaseRevision,
      AuthoringPlan? publicPlan,
      List<AuthoringResourceChange> additionalChanges = const [],
      Future<String> Function()? currentProjectRevision,
      CatalogStoragePatch? patch}) {
    final revision = publicBaseRevision ?? 'sha256:${before.sha256}';
    publicRequest ??= publicPlan?.request;
    if (publicRequest != null &&
        (publicRequest.idempotencyKey != idempotencyKey ||
            (publicRequest.expectedRevision != null &&
                publicRequest.expectedRevision != revision))) {
      throw const CatalogStorageException('catalog.request_mismatch',
          'The public request does not match the catalog edit.');
    }
    final request = publicRequest == null
        ? AuthoringRequest(
            requestId: _token('request_'),
            actionId: actionId,
            actionVersion: 1,
            workspaceHandle: 'catalog-session',
            expectedRevision: revision,
            idempotencyKey: idempotencyKey,
            parameters: {
                'beforeRoot': before.toJson(),
                'root': next.root.toJson()
              },
            extensions: {
                'history': context.toJson()
              })
        : AuthoringRequest(
            requestId: publicRequest.requestId,
            actionId: publicRequest.actionId,
            actionVersion: publicRequest.actionVersion,
            workspaceHandle: publicRequest.workspaceHandle,
            expectedRevision: publicRequest.expectedRevision,
            idempotencyKey: publicRequest.idempotencyKey,
            parameters: publicRequest.parameters,
            dryRun: publicRequest.dryRun,
            extensions: {
                ...publicRequest.extensions,
                'history': context.toJson()
              });
    final resource = AuthoringResourceRef(kind: 'catalogHead', id: 'catalog');
    final change = AuthoringResourceChange(
        resource: resource,
        storageKey: CatalogStorageStore.headStorageKey,
        beforeBytes: CatalogStorageStore.encodeHead(before),
        afterBytes: CatalogStorageStore.encodeHead(next.root));
    final now = _clock().toUtc();
    final suppliedDiff = diff ?? publicPlan?.changeSet.diff;
    final headDiff = revisionHistoryDiff(resource,
        beforeRevision: change.beforeRevision,
        afterRevision: change.afterRevision);
    final changeSet = AuthoringChangeSet(
        changes: [change, ...additionalChanges],
        diff: suppliedDiff == null
            ? AuthoringDiff([
                headDiff,
                for (final extra in additionalChanges)
                  revisionHistoryDiff(extra.resource,
                      beforeRevision: extra.beforeRevision,
                      afterRevision: extra.afterRevision),
              ])
            : AuthoringDiff([
                ...suppliedDiff.entries,
                if (!suppliedDiff.entries.any((entry) =>
                    entry.resource.kind == 'catalogHead' &&
                    entry.resource.id == 'catalog'))
                  headDiff,
              ]));
    if (publicPlan != null && publicPlan.baseRevision != revision) {
      throw const CatalogStorageException('catalog.request_mismatch',
          'The public plan has a different base revision.');
    }
    final plan = publicPlan?.reframeChangeSet(
            changeSet: changeSet, request: request, baseRevision: revision) ??
        AuthoringPlan(
            planId: _token('plan_'),
            receiptId:
                _token(_incrementalHistory ? 'receipt_document_' : 'receipt_'),
            request: request,
            baseRevision: revision,
            seed: 0,
            createdAt: now,
            expiresAt: now.add(const Duration(minutes: 10)),
            changeSet: changeSet);
    _plans.save(plan);
    final prepared = CatalogEditingPlan._(
        plan,
        AuthoringIdempotencyScope(
            actorId: actorId,
            projectId: projectId,
            actionId: request.actionId,
            actionVersion: request.actionVersion,
            key: idempotencyKey),
        operationId,
        next.root,
        lease,
        patch,
        _owner,
        currentProjectRevision);
    _prepared[plan.planId] = prepared;
    return prepared;
  }

  static AuthoringResourceChange _headChange(
          Iterable<AuthoringResourceChange> changes) =>
      changes.singleWhere(
          (change) => change.storageKey == CatalogStorageStore.headStorageKey);

  static void _requireAdditionalPath(String path) {
    final normalized = path.toLowerCase();
    if (normalized == 'project.json' ||
        normalized == 'catalog' ||
        normalized.startsWith('catalog/') ||
        normalized == '.pokemap' ||
        normalized.startsWith('.pokemap/')) {
      throw const CatalogStorageException('catalog.reserved_resource',
          'Catalog storage and the working descriptor are transaction-owned resources.');
    }
  }

  static Future<void> _requireProjectRevision(
      Future<String> Function()? read, String expected) async {
    if (read != null && await read() != expected) {
      throw const CatalogStorageException('catalog.project_revision_conflict',
          'The project resources changed before the catalog transaction.');
    }
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
