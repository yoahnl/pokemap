import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/catalog_storage/catalog_history_compatibility.dart';
import 'package:map_authoring/src/catalog_storage/catalog_history_transition.dart';
import 'package:map_authoring/src/security/resource_pack_bulk_capability.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'journal rejects substituted HEAD even with recalculated aggregate revisions',
      () {
    expect(() => _journal(after: _revision(_root('e'))), throwsFormatException);
  });

  test('journal accepts exact converted HEAD bindings for undo and redo', () {
    for (final redo in [false, true]) {
      final journal = _journal(redo: redo);
      expect(AuthoringTransactionJournal.fromJson(journal.toJson()).toJson(),
          journal.toJson());
    }
  });

  test('journal rejects incoherent action, context and missing expected head',
      () {
    for (final context in [
      {
        'kind': 'redo',
        'targetEntryId': 'origin',
        'expectedHeadEntryId': 'head'
      },
      {'kind': 'undo', 'targetEntryId': 'origin'},
    ]) {
      expect(() => _journal(context: context), throwsFormatException);
    }
    expect(
        () => _journal(action: 'catalog.units.patch'), throwsFormatException);
  });

  test('bulk and receipt transition proofs must be identical and both present',
      () {
    expect(_journal(bulkProof: _proof()).bulkCapability, isNotNull);
    expect(() => _journal(bulkProof: _proof(originalBefore: 'e')),
        throwsFormatException);
    expect(() => _journal(bulkProof: _proof(), omitReceiptProof: true),
        throwsFormatException);
    expect(
        () => _journal(bulkProof: _proof(), context: {
              'kind': 'undo',
              'targetEntryId': 'foreign-origin',
              'expectedHeadEntryId': 'head',
            }),
        throwsFormatException);
  });

  test('transition parser rejects unbound, duplicate, extra and future proofs',
      () {
    final original = _proof();
    for (final invalid in [
      {...original, 'version': 2},
      {...original, 'future': true},
      {...original, 'conversions': []},
      {
        ...original,
        'conversions': [
          CatalogHistoryRootConversion(
                  source: _root('e'), target: _root('f'), additionalBytes: 1)
              .toJson(),
        ]
      },
      {
        ...original,
        'conversions': [
          (original['conversions'] as List).first,
          (original['conversions'] as List).first,
        ]
      },
      {...original, 'effectiveBeforeRoot': _root('a').toJson()},
    ]) {
      expect(() => CatalogHistoryTransitionAttestation.fromJournalJson(invalid),
          throwsFormatException);
    }
  });
}

CatalogObjectReference _root(String value) =>
    CatalogObjectReference(sha256: value * 64, byteLength: 1);
String _revision(CatalogObjectReference root) =>
    computeAuthoringBytesFingerprint(CatalogStorageStore.encodeHead(root),
        logicalName: 'catalog/HEAD.json');

Map<String, dynamic> _proof({String originalBefore = 'a'}) => {
      'version': 1,
      'originalBeforeRoot': _root(originalBefore).toJson(),
      'originalAfterRoot': _root('b').toJson(),
      'effectiveBeforeRoot': _root('c').toJson(),
      'effectiveAfterRoot': _root('d').toJson(),
      'conversions': [
        CatalogHistoryRootConversion(
                source: _root(originalBefore),
                target: _root('c'),
                additionalBytes: 1)
            .toJson(),
        CatalogHistoryRootConversion(
                source: _root('b'), target: _root('d'), additionalBytes: 1)
            .toJson(),
      ],
    };

AuthoringTransactionJournal _journal(
    {bool redo = false,
    String? after,
    Map<String, Object?>? context,
    String? action,
    Map<String, dynamic>? bulkProof,
    bool omitReceiptProof = false}) {
  final actionId = action ?? (redo ? 'history.redo' : 'history.undo');
  final beforeRevision = _revision(_root(redo ? 'c' : 'd'));
  final expectedAfter = _revision(_root(redo ? 'd' : 'c'));
  final afterRevision = after ?? expectedAfter;
  final resource = AuthoringResourceRef(kind: 'catalogHead', id: 'catalog');
  final entry = AuthoringTransactionJournalEntry(
      resource: resource,
      storageKey: 'catalog/HEAD.json',
      beforeRevision: beforeRevision,
      afterRevision: afterRevision);
  final diff = AuthoringDiff([
    AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: r'$',
        before: beforeRevision,
        after: expectedAfter),
  ]);
  final beforeSet = AuthoringRevisionSet([
    AuthoringResourceRevision(resource: resource, revision: beforeRevision),
  ]);
  final afterSet = AuthoringRevisionSet([
    AuthoringResourceRevision(resource: resource, revision: afterRevision),
  ]);
  final receipt = AuthoringReceipt(
      receiptId: 'receipt',
      requestId: 'request',
      actionId: actionId,
      actionVersion: 1,
      status: AuthoringReceiptStatus.applied,
      beforeRevision: beforeSet.fingerprint,
      afterRevision: afterSet.fingerprint,
      createdAtUtc: '2026-10-26T00:00:00.000Z',
      diff: diff,
      extensions: {
        'history': context ??
            {
              'kind': redo ? 'redo' : 'undo',
              'targetEntryId': 'origin',
              'expectedHeadEntryId': 'head'
            },
        if (!omitReceiptProof) 'catalogHistory': _proof(),
      });
  ResourcePackBulkCapability? capability;
  if (bulkProof != null) {
    final inventory = [
      ResourcePackBulkInventoryEntry(
          resource: resource,
          storageKey: 'catalog/HEAD.json',
          beforeRevision: beforeRevision,
          afterRevision: afterRevision,
          role: 'metadata')
    ];
    capability = ResourcePackBulkCapability.fromJournalJson({
      'schemaVersion': 4,
      'logicalOutputLimit': 0,
      'actorId': 'actor',
      'projectId': 'project',
      'workspaceHandle': 'workspace',
      'planId': 'plan',
      'operationId': 'operation',
      'actionId': actionId,
      'actionVersion': 1,
      'originEntryId': 'origin',
      'catalogHistory': bulkProof,
      'inventory': inventory.map((item) => item.toJson()).toList(),
      'diffFingerprint': bulkDiffFingerprint(diff),
      'inventoryFingerprint': computeAuthoringJsonFingerprint(
          inventory.map((item) => item.toJson()).toList(),
          logicalName: 'resource-pack-bulk-inventory.json'),
      'logicalOutputCount': 0,
      'contentBlobCount': 0,
      'metadataCount': 1,
      'touchedResources': 1,
    });
  }
  final now = DateTime.utc(2026, 10, 26);
  return AuthoringTransactionJournal(
      operationId: 'operation',
      planId: 'plan',
      scope: AuthoringIdempotencyScope(
          actorId: 'actor',
          projectId: 'project',
          actionId: actionId,
          actionVersion: 1,
          key: 'key'),
      status: AuthoringTransactionStatus.prepared,
      createdAt: now,
      updatedAt: now,
      entries: [entry],
      intendedReceipt: receipt,
      bulkCapability: capability);
}
