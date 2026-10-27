import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import '../catalog_storage/catalog_generation_retention.dart';
import '../catalog_storage/catalog_history_compatibility.dart';
import '../catalog_storage/catalog_storage_store.dart';
import '../security/authoring_permission.dart';
import '../support/authoring_fingerprint.dart';
import '../workspace/catalog/catalog_metadata_documents.dart';
import 'authoring_history.dart';
import 'content_blob_store.dart';
import 'file_history_store.dart';
import 'history_store.dart';

final class CatalogHistoryRetentionPreview {
  CatalogHistoryRetentionPreview._({
    required this.projectId,
    required this.currentRootSha256,
    required this.operationLimit,
    required this.byteLimit,
    required this.retainedEntries,
    required this.expiredEntries,
    required this.undoCursor,
    required this.retainedLogicalBytes,
    required this.fingerprint,
    required this.operationCosts,
    this.catalogConversions = const {},
    this.metadataOnlyExpiredEntryIds = const [],
    this.blockedReason,
    this.legacyBarrierEntryId,
    List<_ValidatedHistoricalGeneration> validatedAdmissions = const [],
  }) : _validatedAdmissions = validatedAdmissions;

  final String projectId;
  final String currentRootSha256;
  final int operationLimit;
  final int byteLimit;
  final List<AuthoringHistoryEntry> retainedEntries;
  final List<AuthoringHistoryEntry> expiredEntries;
  final int undoCursor;
  final int retainedLogicalBytes;
  final String fingerprint;
  final String? blockedReason;
  final String? legacyBarrierEntryId;
  final Map<String, Map<String, Object?>> operationCosts;
  final List<_ValidatedHistoricalGeneration> _validatedAdmissions;
  final Map<String, AuthoringHistoryCatalogConversion> catalogConversions;
  final List<String> metadataOnlyExpiredEntryIds;

  List<String> get retainedEntryIds =>
      retainedEntries.map((entry) => entry.entryId).toList(growable: false);
  List<String> get expiredEntryIds =>
      expiredEntries.map((entry) => entry.entryId).toList(growable: false);

  Map<String, Object?> toJson() => {
        'projectId': projectId,
        'currentRootSha256': currentRootSha256,
        'operationLimit': operationLimit,
        'byteLimit': byteLimit,
        'retainedEntryIds': retainedEntryIds,
        'expiredEntryIds': expiredEntryIds,
        'undoCursor': undoCursor,
        'retainedLogicalBytes': retainedLogicalBytes,
        'reservedLogicalBytes': retainedLogicalBytes,
        'budgetAccounting': 'sum_of_operation_reservations',
        'fingerprint': fingerprint,
        'catalogConversions': {
          for (final row in catalogConversions.entries)
            row.key: row.value.toJson()
        },
        'metadataOnlyExpiredEntryIds': metadataOnlyExpiredEntryIds,
        if (blockedReason != null) 'blockedReason': blockedReason,
        if (legacyBarrierEntryId != null)
          'legacyBarrierEntryId': legacyBarrierEntryId,
      };
}

final class CatalogHistoryRetentionResult {
  const CatalogHistoryRetentionResult({
    required this.preview,
    required this.collection,
    required this.deletedHistoryBlobs,
    required this.deletedHistoryBlobBytes,
    this.preparedHistoricalGenerations = 0,
    this.historicalGenerationsRequiringPreparation = const [],
    this.validatedHistoricalGenerations = 0,
    this.convertedHistoricalGenerations = 0,
  });

  final CatalogHistoryRetentionPreview preview;
  final CatalogCollectionResult collection;
  final int deletedHistoryBlobs;
  final int deletedHistoryBlobBytes;
  final int preparedHistoricalGenerations;
  final int validatedHistoricalGenerations;
  final int convertedHistoricalGenerations;
  final List<String> historicalGenerationsRequiringPreparation;
  List<String> get expiredEntryIds => preview.expiredEntryIds;

  Map<String, Object?> toJson() => {
        ...preview.toJson(),
        'retainedCatalogObjects': collection.retainedObjects,
        'deletedCatalogObjects': collection.deletedObjects,
        'deletedCatalogBytes': collection.deletedBytes,
        'reclaimedLeases': collection.reclaimedLeases,
        'deletedHistoryBlobs': deletedHistoryBlobs,
        'deletedHistoryBlobBytes': deletedHistoryBlobBytes,
        'validatedHistoricalGenerations': validatedHistoricalGenerations,
        'convertedHistoricalGenerations': convertedHistoricalGenerations,
        'preparedHistoricalGenerations': preparedHistoricalGenerations,
        'historicalGenerationsRequiringPreparation':
            historicalGenerationsRequiringPreparation,
      };
}

final class CatalogHistoryRetention {
  CatalogHistoryRetention({
    required this.store,
    required this.history,
    required this.blobs,
  });

  static const defaultOperationLimit = 50;
  static const defaultByteLimit = 200 * 1024 * 1024;
  final CatalogStorageStore store;
  final FileAuthoringHistoryStore history;
  final AuthoringContentBlobStore blobs;

  Future<CatalogHistoryRetentionPreview> preview({
    required String projectId,
    String? expectedRootSha256,
    int maxOperations = defaultOperationLimit,
    int maxBytes = defaultByteLimit,
  }) =>
      store.gateway.withExclusiveWriteLock(() => _preview(
          projectId: projectId,
          expectedRootSha256: expectedRootSha256,
          maxOperations: maxOperations,
          maxBytes: maxBytes,
          readObject: _MaintenanceObjectReads(store).read));

  Future<void> prepareNavigableAdmissions(
          {required String projectId,
          bool requirePreparedMetadataIndex = false}) =>
      store.gateway.withExclusiveWriteLock(() async {
        safeAuthoringSecurityIdentifier(projectId, 'projectId');
        if (await store.readProjectId() != projectId) {
          throw const CatalogStorageException('catalog.project_mismatch',
              'The catalog belongs to a different project.');
        }
        if (requirePreparedMetadataIndex) {
          final root = await store.readHead();
          if (root == null) {
            throw const CatalogStorageException(
                'catalog.missing', 'There is no current catalog generation.');
          }
          await store.requireMetadataIndexAdmission(
              (await store.openRoot(root)).snapshot);
        }
        final generations = CatalogGenerationRetention(store: store);
        await generations.requireNoPendingTransactionsUnderLock();
        await generations.requireNoPreparedGenerationsUnderLock();
        final current = await store.readHead();
        if (current == null) {
          throw const CatalogStorageException(
              'catalog.missing', 'There is no current catalog generation.');
        }
        final window = await history.localWindow(projectId);
        if (window == null) {
          throw const AuthoringHistoryException('history.preparation_required',
              'Prepare a bounded undo window before its catalog contexts.');
        }
        final fingerprint = computeAuthoringJsonFingerprint(window.toJson(),
            logicalName: 'catalog-context-history-window.json');
        final inventory = _RetentionInventory(
            store, blobs, _MaintenanceObjectReads(store).read,
            existingConversions: window.catalogConversions);
        final entries = <AuthoringHistoryEntry>[];
        for (final id in window.entryIds) {
          final entry =
              await history.getLocalEntry(projectId: projectId, entryId: id);
          if (entry == null || entry.nonUndoableReason != null) {
            throw const AuthoringHistoryException('history.entry_missing',
                'A navigable undo operation is unavailable.');
          }
          entries.add(entry);
        }
        final prepared = <CatalogObjectReference>{};
        Future<void> prepare(CatalogObjectReference root) async {
          if (!prepared.add(root)) return;
          final snapshot = (await store.openRoot(root)).snapshot;
          try {
            await store.restoreIndexAdmission(snapshot);
            if (await store.metadataContextRevision(snapshot) != null) {
              if (await store.metadataIndexPrepared(snapshot)) return;
              final conversion =
                  window.catalogConversions[root.sha256]?.conversion;
              if (conversion != null) {
                await store.requireHistoryConversion(conversion);
                final target =
                    (await store.openRoot(conversion.target)).snapshot;
                await store.restoreIndexAdmission(target);
                if (await store.metadataIndexPrepared(target) &&
                    await store.metadataContextRevision(target) != null) {
                  return;
                }
              }
            }
          } on CatalogStorageException catch (error) {
            if (error.code != 'catalog.preparation_required') rethrow;
          }
          await inventory._graph(root);
        }

        await prepare(current);
        for (final entry in entries) {
          for (final change in entry.changes) {
            if (change.storageKey != CatalogStorageStore.headStorageKey) {
              continue;
            }
            for (final retained in [
              (change.beforeBlobId, change.beforeRevision),
              (change.afterBlobId, change.afterRevision)
            ]) {
              if (retained.$1 == null || retained.$2 == null) {
                throw const AuthoringHistoryException('history.blob_missing',
                    'A navigable catalog transition is incomplete.');
              }
              await prepare(await inventory._head(retained.$1!, retained.$2!));
            }
          }
        }
        final conversions = {
          ...window.catalogConversions,
          ...inventory.conversionsFor(entries),
        };
        await history.prepareCatalogConversions(
            projectId: projectId,
            expectedWindowFingerprint: fingerprint,
            catalogConversions: conversions,
            dryRun: true);
        Future<void> publish(_ValidatedHistoricalGeneration admission) async {
          await store.publishIndexAdmissionUnderLock(admission.snapshot);
          await store.prepareMetadataContextUnderLock(admission.snapshot);
          if (admission.conversion != null) {
            await admission.conversion!.publishUnderLock(store,
                metadataContextRequired: true,
                publishMetadataContext:
                    admission.conversion!.targetSnapshot.root != current);
          } else if (admission.metadataPrepared) {
            await store
                .publishMetadataIndexAdmissionUnderLock(admission.snapshot);
          }
        }

        for (final admission in inventory._admissions.values) {
          if (admission.snapshot.root != current) await publish(admission);
        }
        if (await store.readHead() != current) {
          throw const AuthoringHistoryException('history.retention_stale',
              'The catalog changed while preparing metadata contexts.');
        }
        await history.prepareCatalogConversions(
            projectId: projectId,
            expectedWindowFingerprint: fingerprint,
            catalogConversions: conversions);
        final active = inventory._admissions[current.sha256];
        if (active != null) await publish(active);
        final observed = await history.localWindow(projectId);
        if (await store.readHead() != current ||
            observed == null ||
            canonicalAuthoringJson(observed.catalogConversions
                    .map((key, value) => MapEntry(key, value.toJson()))) !=
                canonicalAuthoringJson(conversions
                    .map((key, value) => MapEntry(key, value.toJson()))) ||
            observed.generation != window.generation ||
            observed.cursor != window.cursor ||
            canonicalAuthoringJson(observed.entryIds) !=
                canonicalAuthoringJson(window.entryIds)) {
          throw const AuthoringHistoryException('history.retention_stale',
              'The undo window changed during metadata context publication.');
        }
      });

  Future<CatalogHistoryRetentionResult> apply({
    required String projectId,
    required String expectedFingerprint,
    String? expectedRootSha256,
    int maxOperations = defaultOperationLimit,
    int maxBytes = defaultByteLimit,
  }) =>
      store.gateway.withExclusiveWriteLock(() async {
        final readObject = _MaintenanceObjectReads(store).read;
        final preview = await _preview(
            projectId: projectId,
            expectedRootSha256: expectedRootSha256,
            maxOperations: maxOperations,
            maxBytes: maxBytes,
            readObject: readObject);
        if (preview.fingerprint != expectedFingerprint) {
          throw const AuthoringHistoryException('history.retention_stale',
              'The project or history changed after the maintenance preview.');
        }
        if (preview.blockedReason != null) {
          throw AuthoringHistoryException(preview.blockedReason!,
              'The nearest operation exceeds the undo budget. No history was expired.');
        }
        final preparedObjects = <String, List<int>>{
          for (final admission in preview._validatedAdmissions)
            ...?admission.conversion?.objects,
        };
        Future<List<int>> maintenanceRead(
                CatalogObjectReference reference) async =>
            preparedObjects[reference.sha256] ?? await readObject(reference);
        final conversionRoots = [
          for (final row in preview.catalogConversions.values) ...[
            row.conversion.source,
            row.conversion.target,
          ],
        ];
        final view = _RetentionHistoryView(preview.retainedEntries);
        final collector = CatalogGenerationRetention(store: store);
        await collector.collectUnderLock(
            projectId: projectId,
            history: view,
            blobs: blobs,
            dryRun: true,
            readObject: maintenanceRead,
            additionalRoots: conversionRoots);
        var preparedHistoricalGenerations = 0;
        var convertedHistoricalGenerations = 0;
        final requiringPreparation = <String>[];
        for (final admission in preview._validatedAdmissions) {
          if (admission.conversion != null) {
            await admission.conversion!.publishUnderLock(store);
            convertedHistoricalGenerations++;
            preparedHistoricalGenerations++;
            continue;
          }
          if (!admission.metadataPrepared) {
            requiringPreparation.add(admission.snapshot.root.sha256);
            continue;
          }
          await store.publishIndexAdmissionUnderLock(admission.snapshot);
          await store
              .publishMetadataIndexAdmissionUnderLock(admission.snapshot);
          preparedHistoricalGenerations++;
        }
        final retainedBlobs = {
          for (final entry in preview.retainedEntries)
            for (final change in entry.changes) ...change.retainedBlobIds,
        };
        var deletedHistoryBlobBytes = 0;
        for (final id in await blobs.listIds()) {
          final payload = await blobs.get(id);
          if (payload == null) {
            throw const AuthoringHistoryException('history.blob_missing',
                'History changed while preparing maintenance.');
          }
          if (!retainedBlobs.contains(id)) {
            deletedHistoryBlobBytes += payload.byteLength;
          }
        }
        await history.expireEntries(
            projectId: projectId,
            entryFingerprints: {
              for (final entry in preview.expiredEntries)
                entry.entryId: computeAuthoringJsonFingerprint(entry.toJson(),
                    logicalName: 'authoring-history-entry.json'),
            },
            maxOperations: maxOperations,
            maxBytes: maxBytes,
            cursor: preview.undoCursor,
            catalogConversions: preview.catalogConversions,
            retainedCosts:
                _flattenCosts(preview.retainedEntries, preview.operationCosts));
        final collection = await collector.collectUnderLock(
            projectId: projectId,
            history: view,
            blobs: blobs,
            readObject: maintenanceRead,
            additionalRoots: conversionRoots);
        final deletedHistoryBlobs = await blobs.prune(retainIds: retainedBlobs);
        return CatalogHistoryRetentionResult(
            preview: preview,
            collection: collection,
            deletedHistoryBlobs: deletedHistoryBlobs,
            deletedHistoryBlobBytes: deletedHistoryBlobBytes,
            validatedHistoricalGenerations: preview._validatedAdmissions.length,
            convertedHistoricalGenerations: convertedHistoricalGenerations,
            preparedHistoricalGenerations: preparedHistoricalGenerations,
            historicalGenerationsRequiringPreparation:
                List.unmodifiable(requiringPreparation));
      });

  Future<CatalogHistoryRetentionPreview> _preview({
    required String projectId,
    required String? expectedRootSha256,
    required int maxOperations,
    required int maxBytes,
    required CatalogObjectReader readObject,
  }) async {
    safeAuthoringSecurityIdentifier(projectId, 'projectId');
    if (maxOperations < 1 ||
        maxOperations > defaultOperationLimit ||
        maxBytes < 1 ||
        maxBytes > defaultByteLimit) {
      throw const AuthoringHistoryException('history.retention_policy_invalid',
          'The undo policy must stay within 50 operations and 200 MiB.');
    }
    final identity = await store.readProjectId();
    if (identity != projectId) {
      throw const CatalogStorageException('catalog.project_mismatch',
          'The catalog belongs to a different project.');
    }
    final generations = CatalogGenerationRetention(store: store);
    await generations.requireNoPendingTransactionsUnderLock();
    await generations.requireNoPreparedGenerationsUnderLock();
    final current = await store.readHead();
    if (current == null) {
      throw const CatalogStorageException(
          'catalog.missing', 'There is no current catalog generation.');
    }
    if (expectedRootSha256 != null && current.sha256 != expectedRootSha256) {
      throw const AuthoringHistoryException('history.retention_stale',
          'The project changed before history maintenance.');
    }
    final entries = await _entries(projectId);
    final window = await history.localWindow(projectId);
    final byId = {for (final entry in entries) entry.entryId: entry};
    final logical = window == null
        ? _logicalWindow(entries)
        : (
            entries: [
              for (final id in window.entryIds)
                if (byId[id] != null && byId[id]!.nonUndoableReason == null)
                  byId[id]!
                else
                  throw const AuthoringHistoryException(
                      'history.branch_unavailable',
                      'A retained undo operation is unavailable.'),
            ],
            cursor: window.cursor,
            barrierEntryId: null,
          );
    final end =
        (logical.cursor + maxOperations).clamp(0, logical.entries.length);
    final start = (end - maxOperations).clamp(0, logical.cursor);
    final cache = _RetentionInventory(store, blobs, readObject,
        existingConversions: window?.catalogConversions ?? const {});
    var selected = logical.entries.sublist(start, end);
    await cache.budget(selected);
    var selectedCursor = logical.cursor - start;
    final metadataOnlyExpiredEntryIds = <String>[];
    final useful = <AuthoringHistoryEntry>[];
    for (var index = 0; index < selected.length; index++) {
      final entry = selected[index];
      if (await cache.metadataOnlyNoop(entry)) {
        metadataOnlyExpiredEntryIds.add(entry.entryId);
        if (index < logical.cursor - start) selectedCursor--;
      } else {
        useful.add(entry);
      }
    }
    selected = useful;
    Future<
        ({
          int bytes,
          int originalBytes,
          int recordBytes,
          Map<String, Map<String, Object?>> operationCosts,
          Map<String, AuthoringHistoryCatalogConversion> conversions
        })> selectedBudget() async {
      final inventory = await cache.budget(selected);
      final conversions = cache.conversionsFor(selected);
      final costs = _flattenCosts(selected, inventory.operationCosts);
      final metrics = await history.retentionWindowMetrics(
          projectId: projectId,
          entryIds: selected.map((entry) => entry.entryId).toList(),
          cursor: selectedCursor,
          maxOperations: maxOperations,
          maxBytes: maxBytes,
          costs: costs,
          catalogConversions: conversions);
      final originalMetrics = await history.retentionWindowMetrics(
          projectId: projectId,
          entryIds: selected.map((entry) => entry.entryId).toList(),
          cursor: selectedCursor,
          maxOperations: maxOperations,
          maxBytes: maxBytes,
          costs: costs,
          catalogConversions: const {});
      return (
        bytes: metrics.logicalBytes,
        originalBytes: originalMetrics.logicalBytes,
        recordBytes: metrics.recordBytes,
        operationCosts: inventory.operationCosts,
        conversions: conversions
      );
    }

    var budget = await selectedBudget();
    String? blockedReason;
    while ((budget.bytes > maxBytes ||
            budget.recordBytes >
                FileAuthoringHistoryStore.maxRetentionRecordBytes) &&
        selected.isNotEmpty) {
      if (budget.conversions.isNotEmpty && budget.originalBytes <= maxBytes) {
        blockedReason = 'history.conversion_exceeds_budget';
        break;
      }
      if (selected.length == 1) {
        blockedReason = 'history.operation_exceeds_budget';
        break;
      }
      if (selectedCursor > 0) {
        selected.removeAt(0);
        selectedCursor--;
      } else {
        selected.removeLast();
      }
      budget = await selectedBudget();
    }
    if (selected.isEmpty &&
        (budget.bytes > maxBytes ||
            budget.recordBytes >
                FileAuthoringHistoryStore.maxRetentionRecordBytes)) {
      blockedReason = 'history.retention_metadata_exceeds_budget';
    }
    final retainedIds = selected.map((entry) => entry.entryId).toSet();
    final expired = entries
        .where((entry) =>
            entry.nonUndoableReason == null &&
            !retainedIds.contains(entry.entryId))
        .toList(growable: false);
    final fingerprint = computeAuthoringJsonFingerprint({
      'projectId': projectId,
      'root': current.toJson(),
      'operationLimit': maxOperations,
      'byteLimit': maxBytes,
      'history': [
        for (final entry in entries)
          {
            'entryId': entry.entryId,
            'fingerprint': computeAuthoringJsonFingerprint(entry.toJson(),
                logicalName: 'authoring-history-entry.json'),
          }
      ],
      'retained': retainedIds.toList(),
      'cursor': selectedCursor,
      'catalogConversions': {
        for (final row in budget.conversions.entries)
          row.key: row.value.toJson()
      },
      'metadataOnlyExpiredEntryIds': metadataOnlyExpiredEntryIds,
      'retainedLogicalBytes': budget.bytes,
    }, logicalName: 'authoring-history-retention-preview.json');
    return CatalogHistoryRetentionPreview._(
        projectId: projectId,
        currentRootSha256: current.sha256,
        operationLimit: maxOperations,
        byteLimit: maxBytes,
        retainedEntries: List.unmodifiable(selected),
        expiredEntries: List.unmodifiable(expired),
        undoCursor: selectedCursor,
        catalogConversions: budget.conversions,
        metadataOnlyExpiredEntryIds:
            List.unmodifiable(metadataOnlyExpiredEntryIds),
        retainedLogicalBytes: budget.bytes,
        fingerprint: fingerprint,
        operationCosts: Map.unmodifiable(budget.operationCosts),
        validatedAdmissions: cache.admissionsFor(selected),
        legacyBarrierEntryId: logical.barrierEntryId,
        blockedReason: blockedReason);
  }

  Future<List<AuthoringHistoryEntry>> _entries(String projectId) async {
    final entries = (await history.entriesForMaintenance()).toList();
    if (entries.length > 4096) {
      throw const AuthoringHistoryException('history.retention_limit',
          'The history exceeds the explicit maintenance safety limit.');
    }
    final identities = <String>{};
    for (final entry in entries) {
      if (!identities.add(entry.entryId)) {
        throw const AuthoringHistoryException('history.identity_conflict',
            'Project history contains conflicting operation identities.');
      }
    }
    entries.sort((a, b) {
      final time = a.committedAt.compareTo(b.committedAt);
      return time != 0 ? time : a.entryId.compareTo(b.entryId);
    });
    return entries;
  }
}

Map<String, Map<String, int>> _flattenCosts(List<AuthoringHistoryEntry> entries,
        Map<String, Map<String, Object?>> operationCosts) =>
    {
      for (final entry in entries)
        entry.entryId: {
          for (final item
              in (operationCosts[entry.entryId]!['objects'] as Map<String, int>)
                  .entries)
            'catalog:${item.key}': item.value,
          for (final item
              in (operationCosts[entry.entryId]!['blobs'] as Map<String, int>)
                  .entries)
            'blob:${item.key.substring(7)}': item.value,
          'entry:${computeAuthoringJsonFingerprint(entry.toJson(), logicalName: 'authoring-history-entry.json').substring(7)}':
              operationCosts[entry.entryId]!['entryBytes'] as int,
        }
    };

({List<AuthoringHistoryEntry> entries, int cursor, String? barrierEntryId})
    _logicalWindow(List<AuthoringHistoryEntry> entries) {
  final stack = <AuthoringHistoryEntry>[];
  var cursor = 0;
  String? barrierEntryId;
  for (final entry in entries) {
    switch (entry.kind) {
      case AuthoringHistoryKind.mutation:
      case AuthoringHistoryKind.revert:
        if (entry.nonUndoableReason != null) {
          stack.clear();
          cursor = 0;
          continue;
        }
        stack.removeRange(cursor, stack.length);
        stack.add(entry);
        cursor++;
      case AuthoringHistoryKind.undo:
        if (cursor > 0 && stack[cursor - 1].entryId == entry.targetEntryId) {
          cursor--;
        } else if (entry.nonUndoableReason == null) {
          stack.clear();
          cursor = 0;
          barrierEntryId = entry.entryId;
        }
      case AuthoringHistoryKind.redo:
        if (cursor < stack.length &&
            stack[cursor].entryId == entry.targetEntryId) {
          cursor++;
        } else if (entry.nonUndoableReason == null) {
          stack.clear();
          cursor = 0;
          barrierEntryId = entry.entryId;
        }
    }
  }
  return (entries: stack, cursor: cursor, barrierEntryId: barrierEntryId);
}

final class _ValidatedHistoricalGeneration {
  const _ValidatedHistoricalGeneration(
      this.snapshot, this.metadataPrepared, this.conversion);
  final CatalogSnapshot snapshot;
  final bool metadataPrepared;
  final CatalogPreparedHistoryConversion? conversion;
}

bool _metadataPrepared(List<CatalogDefinitionUnit> units) {
  final expected = {
    for (final unit in CatalogMetadataDocuments.initialize(units))
      unit.key: unit
  };
  final actual = {
    for (final unit in units)
      if (unit.key.kind == CatalogDefinitionKind.workspaceState &&
          unit.key.id != 'workspace')
        unit.key: unit
  };
  return actual.length == expected.length &&
      expected.entries.every((entry) =>
          actual[entry.key] != null &&
          canonicalAuthoringJson(actual[entry.key]!.toJson()) ==
              canonicalAuthoringJson(entry.value.toJson()));
}

final class _MaintenanceObjectReads {
  _MaintenanceObjectReads(this.store);
  static const _maxBytes = 64 * 1024 * 1024;
  final CatalogStorageStore store;
  final _values = <CatalogObjectReference, Uint8List>{};
  var _storedBytes = 0;

  Future<List<int>> read(CatalogObjectReference reference) async {
    final cached = _values.remove(reference);
    if (cached != null) {
      _values[reference] = cached;
      return cached;
    }
    final bytes = Uint8List.fromList(await store.readObject(reference))
        .asUnmodifiableView();
    if (bytes.length > _maxBytes) return bytes;
    final previous = _values.remove(reference);
    if (previous != null) _storedBytes -= previous.length;
    while (_storedBytes + bytes.length > _maxBytes && _values.isNotEmpty) {
      final oldest = _values.keys.first;
      _storedBytes -= _values.remove(oldest)!.length;
    }
    _values[reference] = bytes;
    _storedBytes += bytes.length;
    return bytes;
  }
}

final class _RetentionInventory {
  _RetentionInventory(this.store, this.blobs, this.readObject,
      {required this.existingConversions});
  final CatalogStorageStore store;
  final AuthoringContentBlobStore blobs;
  final CatalogObjectReader readObject;
  final Map<String, AuthoringHistoryCatalogConversion> existingConversions;
  final _admissions = <String, _ValidatedHistoricalGeneration>{};
  final Map<String, Map<String, int>> _objects = {};
  final Map<String, int> _blobBytes = {};
  final Map<String, CatalogObjectReference> _heads = {};

  Future<({int bytes, Map<String, Map<String, Object?>> operationCosts})>
      budget(List<AuthoringHistoryEntry> entries) async {
    final retainedBlobs = <String>{};
    final operationCosts = <String, Map<String, Object?>>{};
    var metadataBytes = 0;
    for (final entry in entries) {
      final entryBytes =
          utf8.encode(canonicalAuthoringJson(entry.toJson())).length;
      metadataBytes += entryBytes;
      final operationRoots = <CatalogObjectReference>[];
      final operationBlobs = <String, int>{};
      for (final change in entry.changes) {
        for (final id in change.retainedBlobIds) {
          final size = await _blobSize(id);
          retainedBlobs.add(id);
          operationBlobs[id] = size;
        }
        if (change.storageKey != CatalogStorageStore.headStorageKey) continue;
        for (final retained in [
          (change.beforeBlobId, change.beforeRevision),
          (change.afterBlobId, change.afterRevision)
        ]) {
          if (retained.$1 == null || retained.$2 == null) continue;
          final root = await _head(retained.$1!, retained.$2!);
          operationRoots.add(root);
        }
      }
      final variable = <String, int>{};
      if (operationRoots.isNotEmpty && operationRoots.length != 2) {
        throw const AuthoringHistoryException(
            'history.retention_inventory_invalid',
            'A retained catalog operation must have exactly one complete HEAD transition.');
      }
      if (operationRoots.length == 2) {
        final before = await _graph(operationRoots[0]);
        final after = await _graph(operationRoots[1]);
        for (final id in {...before.keys, ...after.keys}) {
          if (before.containsKey(id) != after.containsKey(id)) {
            variable[id] = before[id] ?? after[id]!;
          }
        }
      }
      operationCosts[entry.entryId] = {
        'objects': variable,
        'blobs': operationBlobs,
        'entryBytes': entryBytes,
      };
    }
    final union = <String, int>{};
    for (final cost in operationCosts.values) {
      for (final item in (cost['objects'] as Map<String, int>).entries) {
        union[item.key] = item.value;
      }
    }
    var bytes =
        metadataBytes + union.values.fold<int>(0, (sum, size) => sum + size);
    for (final id in retainedBlobs) {
      bytes += _blobBytes[id]!;
    }
    return (bytes: bytes, operationCosts: operationCosts);
  }

  Future<Map<String, int>> _graph(CatalogObjectReference root) async {
    final known = _objects[root.sha256];
    if (known != null) return known;
    final snapshot =
        (await store.openRoot(root, readObject: readObject)).snapshot;
    final metadata = <CatalogDefinitionUnit>[];
    final references = await snapshot.objectReferences(onUnit: (unit) {
      if (unit.key.kind == CatalogDefinitionKind.catalogMetadata ||
          unit.key.kind == CatalogDefinitionKind.workspaceState) {
        metadata.add(unit);
      }
    });
    final ready = _metadataPrepared(metadata);
    final conversion = ready
        ? null
        : await CatalogHistoryCompatibility.prepare(
            store: store, source: snapshot, metadataUnits: metadata);
    final existing = existingConversions[root.sha256];
    if (existing != null &&
        (conversion == null ||
            canonicalAuthoringJson(existing.conversion.toJson()) !=
                canonicalAuthoringJson(conversion.conversion.toJson()))) {
      throw const AuthoringHistoryException('history.retention_stale',
          'The retained catalog conversion differs from its canonical source.');
    }
    _admissions[root.sha256] =
        _ValidatedHistoricalGeneration(snapshot, ready, conversion);
    final graph = {for (final ref in references) ref.sha256: ref.byteLength};
    _objects[root.sha256] = graph;
    return graph;
  }

  CatalogObjectReference effectiveRoot(CatalogObjectReference root) =>
      _admissions[root.sha256]?.conversion?.conversion.target ?? root;

  Future<bool> metadataOnlyNoop(AuthoringHistoryEntry entry) async {
    if (entry.changes.length != 1) return false;
    final change = entry.changes.single;
    if (change.storageKey != CatalogStorageStore.headStorageKey ||
        change.beforeBlobId == null ||
        change.afterBlobId == null ||
        change.beforeRevision == null ||
        change.afterRevision == null) {
      return false;
    }
    final before = await _head(change.beforeBlobId!, change.beforeRevision!);
    final after = await _head(change.afterBlobId!, change.afterRevision!);
    return effectiveRoot(before) == effectiveRoot(after);
  }

  Map<String, AuthoringHistoryCatalogConversion> conversionsFor(
      List<AuthoringHistoryEntry> entries) {
    final converted = <String, CatalogHistoryRootConversion>{};
    final links = <String, Set<String>>{};
    for (final entry in entries) {
      for (final change in entry.changes) {
        if (change.storageKey != CatalogStorageStore.headStorageKey) continue;
        for (final retained in [
          (change.beforeBlobId, change.beforeRevision),
          (change.afterBlobId, change.afterRevision)
        ]) {
          final root = _heads['${retained.$1}:${retained.$2}'];
          final conversion = _admissions[root?.sha256]?.conversion?.conversion;
          if (conversion != null) {
            converted[conversion.source.sha256] = conversion;
            links
                .putIfAbsent(conversion.source.sha256, () => {})
                .add(entry.entryId);
          }
        }
      }
    }
    return Map.unmodifiable({
      for (final item in converted.entries)
        item.key: AuthoringHistoryCatalogConversion(
            conversion: item.value, entryIds: links[item.key]!)
    });
  }

  List<_ValidatedHistoricalGeneration> admissionsFor(
      List<AuthoringHistoryEntry> entries) {
    final selected = <String, _ValidatedHistoricalGeneration>{};
    for (final entry in entries) {
      for (final change in entry.changes) {
        if (change.storageKey != CatalogStorageStore.headStorageKey) continue;
        for (final retained in [
          (change.beforeBlobId, change.beforeRevision),
          (change.afterBlobId, change.afterRevision)
        ]) {
          final root = _heads['${retained.$1}:${retained.$2}'];
          final admission = root == null ? null : _admissions[root.sha256];
          if (admission != null) selected[root!.sha256] = admission;
        }
      }
    }
    return List.unmodifiable(selected.values);
  }

  Future<int> _blobSize(String id) async {
    final cached = _blobBytes[id];
    if (cached != null) return cached;
    final payload = await blobs.get(id);
    if (payload == null) {
      throw const AuthoringHistoryException('history.blob_missing',
          'A retained operation payload is unavailable.');
    }
    return _blobBytes[id] = payload.byteLength;
  }

  Future<CatalogObjectReference> _head(String id, String revision) async {
    final key = '$id:$revision';
    final cached = _heads[key];
    if (cached != null) return cached;
    final payload = await blobs.get(id);
    if (payload == null ||
        payload.byteLength > CatalogStorageStore.maximumHeadBytes) {
      throw const AuthoringHistoryException(
          'history.blob_missing', 'A retained catalog head is unavailable.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in payload.openRead()) {
      if (bytes.length + chunk.length > CatalogStorageStore.maximumHeadBytes) {
        throw const FormatException(
            'history.retention: oversized catalog head');
      }
      bytes.add(chunk);
    }
    final head = bytes.takeBytes();
    if (computeAuthoringBytesFingerprint(head,
            logicalName: CatalogStorageStore.headStorageKey) !=
        revision) {
      throw const AuthoringHistoryException('history.blob_revision_mismatch',
          'A retained catalog head differs from its recorded revision.');
    }
    final value = jsonDecode(utf8.decode(head));
    if (value is! Map<String, dynamic> ||
        value.length != 2 ||
        value['schemaVersion'] != 1 ||
        value['root'] is! Map) {
      throw const FormatException('history.retention: invalid catalog head');
    }
    return _heads[key] = CatalogObjectReference.fromJson(
        Map<String, Object?>.from(value['root'] as Map));
  }
}

final class _RetentionHistoryView implements AuthoringHistoryStore {
  _RetentionHistoryView(this.entries);
  final List<AuthoringHistoryEntry> entries;

  @override
  Future<AuthoringHistoryPage> list(
      {required String projectId,
      required int limit,
      AuthoringHistoryCursor? cursor}) async {
    final start = cursor == null
        ? 0
        : int.parse(utf8
            .decode(base64Url.decode(base64Url.normalize(cursor.wireValue))));
    final eligible = entries;
    final end = (start + limit).clamp(0, eligible.length);
    return AuthoringHistoryPage(
        entries: eligible.sublist(start, end),
        nextCursor: end == eligible.length
            ? null
            : AuthoringHistoryCursor.fromWireValue(base64Url
                .encode(utf8.encode(end.toString().padLeft(18, '0')))));
  }

  @override
  Future<AuthoringHistoryEntry?> get(
          {required String projectId, required String entryId}) async =>
      entries
          .where((entry) =>
              entry.projectId == projectId && entry.entryId == entryId)
          .firstOrNull;

  @override
  Future<void> append(AuthoringHistoryEntry entry) =>
      throw UnsupportedError('read-only retention view');

  @override
  Future<AuthoringHistoryEntry> markNonUndoable(
          {required String projectId,
          required String entryId,
          required String reason}) =>
      throw UnsupportedError('read-only retention view');
}
