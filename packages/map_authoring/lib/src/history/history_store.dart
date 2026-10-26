import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../catalog_storage/catalog_revert_merge.dart';
import '../catalog_storage/catalog_history_transition.dart';
import '../catalog_storage/catalog_storage_store.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_diff.dart';
import '../contracts/resource_ref.dart';
import '../security/resource_pack_bulk_capability.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/authoring_payload.dart';
import '../transactions/transaction_journal.dart';
import '../support/authoring_fingerprint.dart';
import '../ports/idempotency_store.dart';
import 'authoring_history.dart';
import 'content_blob_store.dart';
import 'file_history_store.dart';

final class AuthoringHistoryCursor {
  AuthoringHistoryCursor._(this.wireValue);

  factory AuthoringHistoryCursor.fromWireValue(String value) {
    if (value.length < 16 ||
        value.length > 2048 ||
        !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      throw const AuthoringHistoryException(
        'history.cursor_invalid',
        'The history cursor is invalid.',
      );
    }
    return AuthoringHistoryCursor._(value);
  }

  final String wireValue;

  @override
  String toString() =>
      'history-cursor:${wireValue.substring(0, wireValue.length.clamp(0, 12))}';
}

final class AuthoringHistoryPage {
  const AuthoringHistoryPage({required this.entries, this.nextCursor});

  final List<AuthoringHistoryEntry> entries;
  final AuthoringHistoryCursor? nextCursor;
}

abstract interface class AuthoringHistoryStore {
  Future<void> append(AuthoringHistoryEntry entry);

  Future<AuthoringHistoryEntry?> get({
    required String projectId,
    required String entryId,
  });

  Future<AuthoringHistoryPage> list({
    required String projectId,
    required int limit,
    AuthoringHistoryCursor? cursor,
  });

  Future<AuthoringHistoryEntry> markNonUndoable({
    required String projectId,
    required String entryId,
    required String reason,
  });
}

abstract interface class AuthoringLocalHistoryReader {
  Future<AuthoringHistoryEntry?> latestLocalEntry({required String projectId});
  Future<AuthoringHistoryEntry?> getLocalEntry(
      {required String projectId, required String entryId});
}

Future<AuthoringHistoryEntry?> readAuthoringHistoryHead(
    AuthoringHistoryStore store, String projectId) async {
  if (store is AuthoringLocalHistoryReader) {
    return (store as AuthoringLocalHistoryReader)
        .latestLocalEntry(projectId: projectId);
  }
  return (await store.list(projectId: projectId, limit: 1)).entries.firstOrNull;
}

/// Idempotent transaction commit hook that retains bytes before history entry.
final class AuthoringHistoryRecorder
    implements
        AuthoringTransactionCommitHook,
        AuthoringTransactionPreflightGuard,
        AuthoringTransactionRecoveryGuard,
        AuthoringBulkHistoryRecoveryGuard {
  const AuthoringHistoryRecorder({
    required AuthoringHistoryStore store,
    required AuthoringContentBlobStore blobs,
    CatalogStorageStore? catalogStore,
  })  : _store = store,
        _blobs = blobs,
        _catalogStore = catalogStore;

  final AuthoringHistoryStore _store;
  final AuthoringContentBlobStore _blobs;
  final CatalogStorageStore? _catalogStore;

  @override
  Future<void> record(AuthoringCommittedMutation mutation) async {
    final prepared = await _prepareEntry(mutation, persist: true);
    final history = _store;
    if (history is FileAuthoringHistoryStore &&
        await history.localWindow(mutation.scope.projectId,
                allowPending: true) !=
            null) {
      await history.appendWithRetention(prepared.entry, costs: prepared.costs);
    } else {
      await _store.append(prepared.entry);
    }
  }

  @override
  Future<void> requireCommitAllowed(AuthoringCommittedMutation mutation) async {
    final history = _store;
    if (history is! FileAuthoringHistoryStore) return;
    await history.ensureRetentionWindowIfEmpty(mutation.scope.projectId);
    if (await history.localWindow(mutation.scope.projectId) == null) return;
    final prepared = await _prepareEntry(mutation, persist: false);
    await history.checkRetentionEntry(prepared.entry, costs: prepared.costs);
  }

  Future<({AuthoringHistoryEntry entry, Map<String, int> costs})> _prepareEntry(
      AuthoringCommittedMutation mutation,
      {required bool persist}) async {
    final retained = <AuthoringHistoryResourceChange>[];
    final costs = <String, int>{};
    Future<AuthoringContentBlobRef?> retain(AuthoringPayload? payload) async {
      if (payload == null) return null;
      if (persist) return _blobs.putPayload(payload);
      final inspection = await inspectAuthoringPayload(payload.openRead(),
          storageKey: 'authoring-history-blob', byteLength: payload.byteLength);
      return AuthoringContentBlobRef(
          id: inspection.resourceRevision, byteLength: payload.byteLength);
    }

    for (final change in mutation.changes) {
      final before = await retain(change.beforePayload);
      final after = await retain(change.afterPayload);
      for (final blob in [before, after]) {
        if (blob != null) {
          costs['blob:${blob.id.substring(7)}'] = blob.byteLength;
        }
      }
      retained.add(
        AuthoringHistoryResourceChange(
          resource: change.resource,
          storageKey: change.storageKey,
          beforeRevision: change.beforeRevision,
          afterRevision: change.afterRevision,
          beforeBlobId: before?.id,
          afterBlobId: after?.id,
        ),
      );
    }
    final context = AuthoringHistoryContext.fromExtensions(
      mutation.receipt.extensions,
    );
    final entry = AuthoringHistoryEntry(
      entryId: mutation.receipt.receiptId,
      projectId: mutation.scope.projectId,
      actorId: mutation.scope.actorId,
      planId: mutation.planId,
      operationId: mutation.operationId,
      kind: context.kind,
      targetEntryId: context.targetEntryId,
      receipt: mutation.receipt,
      committedAt: DateTime.parse(mutation.receipt.createdAtUtc).toUtc(),
      changes: retained,
      bulkCapability: mutation.bulkCapability,
      nonUndoableReason:
          mutation.receipt.actionId == 'project.catalog.partition'
              ? 'catalog.partition_not_undoable'
              : null,
    );
    final history = _store;
    if (history is FileAuthoringHistoryStore &&
        await history.localWindow(mutation.scope.projectId,
                allowPending: true) !=
            null) {
      final catalogStore = _catalogStore;
      final head = mutation.changes
          .where((change) =>
              change.storageKey == CatalogStorageStore.headStorageKey)
          .firstOrNull;
      if (head != null) {
        if (catalogStore == null ||
            head.beforePayload == null ||
            head.afterPayload == null) {
          throw const AuthoringHistoryException(
              'history.retention_inventory_required',
              'Catalog undo requires its canonical object inventory.');
        }
        Future<CatalogSnapshot> snapshot(AuthoringPayload payload) async {
          final bytes = <int>[];
          await for (final chunk in payload.openRead()) {
            bytes.addAll(chunk);
            if (bytes.length > CatalogStorageStore.maximumHeadBytes) {
              throw const FormatException('history.retention: oversized head');
            }
          }
          final value = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
          return (await catalogStore.openRoot(CatalogObjectReference.fromJson(
                  Map<String, dynamic>.from(value['root'] as Map))))
              .snapshot;
        }

        var delta = mutation.catalogDelta;
        if (delta != null &&
            (computeAuthoringBytesFingerprint(
                        CatalogStorageStore.encodeHead(delta.beforeRoot),
                        logicalName: CatalogStorageStore.headStorageKey) !=
                    head.beforeRevision ||
                computeAuthoringBytesFingerprint(
                        CatalogStorageStore.encodeHead(delta.root),
                        logicalName: CatalogStorageStore.headStorageKey) !=
                    head.afterRevision)) {
          throw const AuthoringHistoryException(
              'history.retention_inventory_mismatch',
              'The verified catalog inventory does not match the frozen transaction.');
        }
        if (delta == null || !identical(delta.limits, catalogStore.limits)) {
          final before = await snapshot(head.beforePayload!);
          await catalogStore.restoreIndexAdmission(before);
          final after = await snapshot(head.afterPayload!);
          delta = await after.deltaFrom(before);
        }
        for (final object in [...delta.addedObjects, ...delta.removedObjects]) {
          costs['catalog:${object.sha256}'] = object.byteLength;
        }
      }
      final bytes = utf8.encode(canonicalAuthoringJson(entry.toJson()));
      costs['entry:${computeAuthoringJsonFingerprint(entry.toJson(), logicalName: 'authoring-history-entry.json').substring(7)}'] =
          bytes.length;
    }
    return (entry: entry, costs: costs);
  }

  @override
  Future<void> requireBulkHistoryRecoveryAllowed(
      {required ResourcePackBulkCapability capability,
      required AuthoringReceipt intendedReceipt}) async {
    final originId = capability.originEntryId;
    if (originId == null) return;
    final origin =
        await _store.get(projectId: capability.projectId, entryId: originId);
    if (origin == null ||
        origin.bulkCapability == null ||
        capability.logicalOutputLimit !=
            origin.bulkCapability!.logicalOutputLimit) {
      throw const AuthoringHistoryException('history.bulk_origin_invalid',
          'The canonical bulk origin is unavailable.');
    }
    final attestation = capability.catalogRevert;
    final transition = capability.catalogHistory;
    if ((attestation != null || transition != null) && _catalogStore == null) {
      throw const AuthoringHistoryException('history.bulk_origin_invalid',
          'Catalog merge recovery requires the canonical catalog store.');
    }
    final verified =
        attestation == null ? null : await attestation.reverify(_catalogStore!);
    final verifiedTransition = transition == null
        ? null
        : await transition.reverify(_catalogStore!, allowPreparation: true);
    verifyBulkHistoryMutation(
        origin: origin,
        actionId: capability.actionId,
        inventory: capability.inventory,
        diff: intendedReceipt.diff,
        catalogRevert: verified,
        catalogHistory: verifiedTransition);
  }

  @override
  Future<void> requireRecoveryAllowed({
    required AuthoringReceipt intendedReceipt,
    required AuthoringIdempotencyScope scope,
  }) async {
    final context = AuthoringHistoryContext.fromExtensions(
      intendedReceipt.extensions,
    );
    final expectedHead = context.expectedHeadEntryId;
    final conversionRecord = intendedReceipt.extensions['catalogHistory'];
    if (conversionRecord != null && expectedHead == null) {
      throw const AuthoringHistoryException('history.conversion_unbound',
          'A converted history transition requires its expected history head.');
    }
    if (expectedHead == null) return;
    final head = await readAuthoringHistoryHead(_store, scope.projectId);
    final alreadyRecorded = head?.entryId == intendedReceipt.receiptId &&
        canonicalAuthoringJson(head!.receipt.toJson()) ==
            canonicalAuthoringJson(intendedReceipt.toJson());
    if (!alreadyRecorded && head?.entryId != expectedHead) {
      final isRedo = context.kind == AuthoringHistoryKind.redo;
      throw AuthoringHistoryException(
        isRedo ? 'history.redo_branch_diverged' : 'history.head_stale',
        isRedo
            ? 'Redo is unsafe because the project history has diverged.'
            : 'The current history head differs from the expected head.',
      );
    }
    if (conversionRecord != null) {
      final catalogStore = _catalogStore;
      if (catalogStore == null ||
          conversionRecord is! Map ||
          !const {AuthoringHistoryKind.undo, AuthoringHistoryKind.redo}
              .contains(context.kind) ||
          intendedReceipt.actionId != 'history.${context.kind.wireName}') {
        throw const AuthoringHistoryException('history.conversion_unbound',
            'The converted history transition has no canonical origin.');
      }
      final transition = CatalogHistoryTransitionAttestation.fromJournalJson(
          Map<String, dynamic>.from(conversionRecord));
      final origin = await _store.get(
          projectId: scope.projectId, entryId: context.targetEntryId!);
      final heads = origin?.changes.where(
          (change) => change.storageKey == CatalogStorageStore.headStorageKey);
      if (origin == null ||
          heads!.length != 1 ||
          heads.single.beforeRevision != transition.originalBeforeRevision ||
          heads.single.afterRevision != transition.originalAfterRevision ||
          canonicalAuthoringJson(intendedReceipt.diff.toJson()) !=
              canonicalAuthoringJson(catalogHistoryTransitionDiff(
                      origin.receipt.diff,
                      redo: context.kind == AuthoringHistoryKind.redo,
                      attestation: transition)
                  .toJson())) {
        throw const AuthoringHistoryException('history.conversion_unbound',
            'The converted history transition differs from its origin.');
      }
      await transition.reverify(catalogStore, allowPreparation: true);
    }
  }
}

Future<void> requireFinalizedJournalHistory({
  required AuthoringTransactionJournal journal,
  required AuthoringHistoryStore history,
  required AuthoringContentBlobStore blobs,
}) async {
  final entry = await history.get(
      projectId: journal.scope.projectId,
      entryId: journal.intendedReceipt.receiptId);
  final expectedReceipt =
      canonicalAuthoringJson(journal.intendedReceipt.toJson());
  if (entry == null ||
      entry.projectId != journal.scope.projectId ||
      entry.actorId != journal.scope.actorId ||
      entry.planId != journal.planId ||
      entry.operationId != journal.operationId ||
      (canonicalAuthoringJson(entry.receipt.toJson()) != expectedReceipt &&
          canonicalAuthoringJson(entry.receipt.toJson()) !=
              canonicalAuthoringJson(journal.finalReceipt!.toJson())) ||
      canonicalAuthoringJson(entry.bulkCapability?.toJson()) !=
          canonicalAuthoringJson(journal.bulkCapability?.toJson()) ||
      entry.changes.length != journal.entries.length) {
    throw const AuthoringHistoryException(
        'history.preparation_evidence_required',
        'A completed transaction has no matching retained history. Preserve its recovery files and reconcile it explicitly.');
  }
  final changes = {
    for (final change in entry.changes) change.storageKey: change
  };
  for (final retained in journal.entries) {
    final change = changes[retained.storageKey];
    if (change == null ||
        change.beforeRevision != retained.beforeRevision ||
        change.afterRevision != retained.afterRevision ||
        canonicalAuthoringJson(change.resource.toJson()) !=
            canonicalAuthoringJson(retained.resource.toJson())) {
      throw const AuthoringHistoryException(
          'history.preparation_evidence_required',
          'The retained transaction and history inventories differ. Preserve the recovery files.');
    }
  }
  for (final blobId
      in entry.changes.expand((change) => change.retainedBlobIds).toSet()) {
    if (!await blobs.contains(blobId)) {
      throw const AuthoringHistoryException('history.preparation_blob_required',
          'A retained history payload is unavailable. Preserve the transaction recovery files and repair history explicitly.');
    }
  }
}

Future<void> bindCanonicalBulkHistoryPlan(
    {required AuthoringHistoryStore history,
    required AuthoringPlan plan,
    required String actorId,
    required String projectId,
    required String operationId,
    CatalogRevertMergeAttestation? catalogRevert,
    CatalogHistoryTransitionAttestation? catalogHistory}) async {
  final context =
      AuthoringHistoryContext.fromExtensions(plan.request.extensions);
  if (context.targetEntryId == null) return;
  final origin =
      await history.get(projectId: projectId, entryId: context.targetEntryId!);
  final certificate = origin?.bulkCapability;
  if (origin == null || certificate == null) return;
  final inventory = [
    for (final change in plan.changeSet.changes)
      ResourcePackBulkInventoryEntry.fromChange(change,
          role: certificate.roleFor(change.storageKey))
  ];
  verifyBulkHistoryMutation(
      origin: origin,
      actionId: plan.request.actionId,
      inventory: inventory,
      diff: plan.changeSet.diff,
      catalogRevert: catalogRevert,
      catalogHistory: catalogHistory);
  plan.bindBulkCapability(ResourcePackBulkAuthority.certifyHistory(
      plan: plan,
      actorId: actorId,
      projectId: projectId,
      operationId: operationId,
      originEntryId: origin.entryId,
      origin: certificate,
      verifiedInventory: inventory,
      catalogRevert: catalogRevert,
      catalogHistory: catalogHistory));
}

void verifyBulkHistoryMutation(
    {required AuthoringHistoryEntry origin,
    required String actionId,
    required Iterable<ResourcePackBulkInventoryEntry> inventory,
    required AuthoringDiff diff,
    CatalogRevertMergeAttestation? catalogRevert,
    CatalogHistoryTransitionAttestation? catalogHistory}) {
  final certificate = origin.bulkCapability;
  final actual = inventory.toList();
  if (certificate == null ||
      !const {'history.undo', 'history.redo', 'history.revert'}
          .contains(actionId)) {
    throw const AuthoringHistoryException('history.bulk_origin_invalid',
        'The bulk history origin is not certified.');
  }
  final sourceHead = origin.changes
      .where(
          (change) => change.storageKey == CatalogStorageStore.headStorageKey)
      .firstOrNull;
  if (catalogRevert != null &&
      (!catalogRevert.verified ||
          actionId != 'history.revert' ||
          sourceHead == null ||
          sourceHead.beforeRevision != catalogRevert.targetBeforeHeadRevision ||
          sourceHead.afterRevision != catalogRevert.targetAfterHeadRevision)) {
    throw const AuthoringHistoryException('history.bulk_origin_invalid',
        'The catalog merge is not bound to its canonical history origin.');
  }
  if (catalogHistory != null &&
      (!catalogHistory.verified ||
          catalogRevert != null ||
          !const {'history.undo', 'history.redo'}.contains(actionId) ||
          sourceHead == null ||
          sourceHead.beforeRevision != catalogHistory.originalBeforeRevision ||
          sourceHead.afterRevision != catalogHistory.originalAfterRevision)) {
    throw const AuthoringHistoryException('history.bulk_origin_invalid',
        'The catalog conversion is not bound to its canonical history origin.');
  }
  final byStorage = {
    for (final change in origin.changes) change.storageKey: change
  };
  final seen = <String>{};
  for (final item in actual) {
    final source = byStorage[item.storageKey];
    if (source == null ||
        !seen.add(item.storageKey) ||
        item.resource.kind != source.resource.kind ||
        item.resource.id != source.resource.id ||
        item.role != certificate.roleFor(item.storageKey) ||
        (item.storageKey == CatalogStorageStore.headStorageKey &&
                catalogHistory != null
            ? item.beforeRevision !=
                    (actionId == 'history.undo'
                        ? catalogHistory.effectiveAfterRevision
                        : catalogHistory.effectiveBeforeRevision) ||
                item.afterRevision !=
                    (actionId == 'history.undo'
                        ? catalogHistory.effectiveBeforeRevision
                        : catalogHistory.effectiveAfterRevision)
            : actionId == 'history.undo'
                ? item.beforeRevision != source.afterRevision ||
                    item.afterRevision != source.beforeRevision
                : item.storageKey == CatalogStorageStore.headStorageKey &&
                        catalogRevert != null
                    ? item.beforeRevision !=
                            catalogRevert.currentHeadRevision ||
                        item.afterRevision != catalogRevert.resultHeadRevision
                    : item.afterRevision != source.afterRevision ||
                        (actionId == 'history.redo' &&
                            item.beforeRevision != source.beforeRevision))) {
      throw const AuthoringHistoryException('history.bulk_origin_invalid',
          'The history mutation differs from its canonical origin.');
    }
  }
  if (actionId != 'history.revert' && actual.length != origin.changes.length) {
    throw const AuthoringHistoryException('history.bulk_origin_invalid',
        'The history mutation omits canonical resources.');
  }
  final expectedDiff = const {'history.undo', 'history.redo'}.contains(actionId)
      ? catalogHistoryTransitionDiff(origin.receipt.diff,
          redo: actionId == 'history.redo', attestation: catalogHistory)
      : AuthoringDiff([
          for (final item in actual)
            revisionHistoryDiff(item.resource,
                beforeRevision: item.beforeRevision,
                afterRevision: item.afterRevision)
        ]);
  if (canonicalAuthoringJson(expectedDiff.toJson()) !=
      canonicalAuthoringJson(diff.toJson())) {
    throw const AuthoringHistoryException('history.bulk_origin_invalid',
        'The history diff differs from its canonical origin.');
  }
}

AuthoringDiff catalogHistoryTransitionDiff(AuthoringDiff origin,
    {required bool redo, CatalogHistoryTransitionAttestation? attestation}) {
  final diff = redo ? origin : invertAuthoringHistoryDiff(origin);
  if (attestation == null) return diff;
  final before = redo
      ? attestation.effectiveBeforeRevision
      : attestation.effectiveAfterRevision;
  final after = redo
      ? attestation.effectiveAfterRevision
      : attestation.effectiveBeforeRevision;
  return AuthoringDiff([
    for (final entry in diff.entries)
      if (entry.resource.kind == 'catalogHead' &&
          entry.resource.id == 'catalog' &&
          entry.path == r'$')
        revisionHistoryDiff(entry.resource,
            beforeRevision: before, afterRevision: after)
      else
        entry,
  ]);
}

AuthoringDiff invertAuthoringHistoryDiff(AuthoringDiff diff) => AuthoringDiff([
      for (final item in diff.entries)
        AuthoringDiffEntry.fromJson({
          ...item.toJson(),
          'operation': switch (item.operation) {
            AuthoringDiffOperation.add => 'remove',
            AuthoringDiffOperation.remove => 'add',
            AuthoringDiffOperation.link => 'unlink',
            AuthoringDiffOperation.unlink => 'link',
            AuthoringDiffOperation.replace => 'replace',
            AuthoringDiffOperation.move => 'move',
          },
          if (item.hasAfter) 'before': item.after,
          if (item.hasBefore) 'after': item.before,
        }..removeWhere((key, value) =>
            (key == 'before' && !item.hasAfter) ||
            (key == 'after' && !item.hasBefore)))
    ]);

AuthoringDiffEntry revisionHistoryDiff(AuthoringResourceRef resource,
        {required String? beforeRevision, required String? afterRevision}) =>
    AuthoringDiffEntry.fromJson({
      'operation': beforeRevision == null
          ? 'add'
          : afterRevision == null
              ? 'remove'
              : 'replace',
      'resource': resource.toJson(),
      'path': r'$',
      if (beforeRevision != null) 'before': beforeRevision,
      if (afterRevision != null) 'after': afterRevision
    });
