import 'dart:isolate';
import '../support/map_authoring_worker_trace.dart';
import '../references/exterior_decoration_references.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:map_core/map_core.dart';
import '../contracts/action_descriptor.dart';
import '../contracts/authoring_diff.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../contracts/resource_ref.dart';
import '../history/authoring_history.dart';
import '../history/content_blob_store.dart';
import '../history/file_history_store.dart';
import '../history/history_store.dart';
import '../ports/idempotency_store.dart';
import '../ports/project_file_reader.dart';
import '../security/audit_log.dart';
import '../security/audit_record.dart';
import '../security/authoring_permission.dart';
import '../security/authorization_policy.dart';
import '../security/confirmation_token.dart';
import '../security/secure_mutation_executor.dart';
import '../support/authoring_fingerprint.dart';
import '../support/authoring_performance_observer.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/change_set.dart';
import '../transactions/file_idempotency_store.dart';
import '../transactions/idempotency_ledger.dart';
import '../transactions/journaled_transaction.dart';
import '../transactions/local_transaction_file_gateway.dart';
import '../transactions/plan_store.dart';
import '../transactions/recovery_service.dart';
import '../transactions/transaction_journal.dart';
import '../workspace/workspace_policy.dart';
import '../catalog_storage/catalog_storage_store.dart';
import '../workspace/catalog/catalog_project_reader.dart';
import '../workspace/catalog/catalog_metadata_documents.dart';
import '../domains/maps/semantic_map_action_support.dart'
    show SemanticParameters;
import '../editing/exterior_decoration_native_editing.dart';
part 'map_exterior_decoration_border_authoring.dart';
part 'map_exterior_decoration_batch_authoring.dart';
part 'map_exterior_decoration_native_authoring.dart';
part 'map_exterior_decoration_reference_admission.dart';
part 'map_exterior_decoration_dependency_guard.dart';
part 'map_exterior_decoration_reference_index.dart';
part 'map_exterior_decoration_worker.dart';

final class MapExteriorDecorationSnapshot {
  MapExteriorDecorationSnapshot(
      {required this.revision,
      required this.decoration,
      required Iterable<String> sectorIds,
      required Map<String, String> sectorRevisions,
      Iterable<String> borderIds = const [],
      Map<String, String> borderRevisions = const {}})
      : sectorIds = List.unmodifiable(sectorIds),
        borderIds = List.unmodifiable(borderIds),
        borderRevisions = Map.unmodifiable(borderRevisions),
        sectorRevisions = Map.unmodifiable(sectorRevisions);
  final String revision;
  final MapExteriorDecoration? decoration;
  final List<String> sectorIds, borderIds;
  final Map<String, String> borderRevisions;
  final Map<String, String> sectorRevisions;
  Map<String, Object?> toJson() => {
        'revision': revision,
        'decoration': decoration?.toJson(),
        'sectorIds': sectorIds,
        'sectorRevisions': sectorRevisions,
        'borderIds': borderIds,
        'borderRevisions': borderRevisions
      };
}

final class MapExteriorDecorationMutation {
  const MapExteriorDecorationMutation(
      {required this.beforeRevision,
      required this.afterRevision,
      required this.receipt});
  final String beforeRevision, afterRevision;
  final AuthoringReceipt receipt;
  factory MapExteriorDecorationMutation.fromReceipt(AuthoringReceipt receipt) {
    final entry = receipt.diff.entries.firstWhere(
        (v) => v.resource.kind == 'mapExteriorDecoration',
        orElse: () => receipt.diff.entries.first);
    return MapExteriorDecorationMutation(
        beforeRevision: entry.extensions['documentBeforeRevision']! as String,
        afterRevision: entry.extensions['documentAfterRevision']! as String,
        receipt: receipt);
  }
  Map<String, Object?> toJson() => {
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'receipt': receipt.toJson()
      };
}

final class LocalMapExteriorDecorationAuthoring {
  LocalMapExteriorDecorationAuthoring(
      {required WorkspacePolicy policy,
      ProjectFileReader? reader,
      AuthoringActor? actor,
      AuthoringTransactionFaultInjector? faultInjector,
      AuthoringPerformanceObserver? performanceObserver,
      this.runInWorker = false,
      this.diagnosticsPort})
      : _policy = policy,
        _reader = reader ?? const LocalProjectFileReader(),
        _actor = actor ??
            AuthoringActor(actorId: 'local_cli', permissions: const [
              AuthoringPermissionScope.projectRead,
              AuthoringPermissionScope.projectWrite,
              AuthoringPermissionScope.recoveryApply
            ]),
        _faultInjector = faultInjector,
        _observer = performanceObserver;
  final bool runInWorker;
  final SendPort? diagnosticsPort;
  final WorkspacePolicy _policy;
  final ProjectFileReader _reader;
  final AuthoringActor _actor;
  final AuthoringTransactionFaultInjector? _faultInjector;
  final AuthoringPerformanceObserver? _observer;
  final Map<String, (ProjectResourceIdentity, MapData)> _maps = {};
  final Set<String> _referenceAdmissions = {};
  static final prepareReferencesDescriptor = _descriptor(
      'map.exteriorDecoration.references.prepare',
      'Explicitly prepare incoming references for one exterior decoration map');
  static const maximumDefinitionBytes = 131072;
  static const maximumSectorBytes = 2097152;
  static const maximumBorderBytes = 8388608;
  static final configureDescriptor = _descriptor(
      'map.exteriorDecoration.configure',
      'Configure the exterior visual margins of one map');
  static final sectorSetDescriptor = _descriptor(
      'map.exteriorDecoration.sector.set',
      'Save one native exterior decoration sector');
  static final sectorBatchDescriptor = _descriptor(
      'map.exteriorDecoration.sector.batch',
      'Save one native exterior brush gesture across affected sectors atomically');
  static final sectorRemoveDescriptor = _descriptor(
      'map.exteriorDecoration.sector.remove',
      'Remove one recoverable exterior decoration sector');
  static final borderSetDescriptor = _descriptor(
      'map.exteriorDecoration.border.set',
      'Save one complete native exterior Border contour');
  static final borderRemoveDescriptor = _descriptor(
      'map.exteriorDecoration.border.remove',
      'Remove one recoverable native exterior Border contour');
  static final nativeEditDescriptor = _descriptor(
      'map.exteriorDecoration.native.edit',
      'Paint native Terrain and Paths, generate Environment or resolve one complete Border against exterior visual data');
  static final descriptors = List<AuthoringActionDescriptor>.unmodifiable([
    prepareReferencesDescriptor,
    configureDescriptor,
    sectorSetDescriptor,
    sectorBatchDescriptor,
    sectorRemoveDescriptor,
    borderSetDescriptor,
    borderRemoveDescriptor,
    nativeEditDescriptor
  ]);

  static AuthoringActionDescriptor _descriptor(String id, String summary) =>
      AuthoringActionDescriptor(
          id: id,
          version: 1,
          summary: summary,
          inputSchemaId: 'pokemap.authoring.$id.input.v1',
          outputSchemaId: 'pokemap.authoring.$id.output.v1',
          riskLevel: AuthoringRiskLevel.low,
          resourceKinds: const [
            'mapExteriorDecoration',
            'exteriorDecorationSector'
          ],
          requiredPermissions: [
            AuthoringPermission.projectWrite,
            if (id == 'map.exteriorDecoration.references.prepare')
              AuthoringPermission.recoveryApply
          ],
          guarantees: [
            AuthoringGuarantee.atomic,
            AuthoringGuarantee.idempotent,
            AuthoringGuarantee.revisionChecked,
            if (id != 'map.exteriorDecoration.references.prepare')
              AuthoringGuarantee.undoable
          ],
          extensions: const {
            'documentSchemaVersions': [1],
            'revisionScope': 'mapExteriorDecorationDefinition',
            'storagePattern': 'maps/<mapId>.decoration.json',
            'sectorStoragePattern': 'maps/<mapId>.decoration/<sectorId>.json',
            'maximumDefinitionBytes': maximumDefinitionBytes,
            'maximumSectorBytes': maximumSectorBytes,
            'maximumBorderBytes': maximumBorderBytes,
            'maximumBorders': 64,
            'maximumMargin': 64,
            'maximumSectors': 256,
            'maximumSectorSize': 32,
            'maximumInstances': 10000,
            'maximumResourceReferences': 1024,
            'loadsProject': false,
            'gameplayMutable': false,
            'multiFileAtomicity': 'journalRecoverable',
            'nativeFamilies': ['terrain', 'path', 'border', 'environment'],
            'nativeEditKinds': [
              'terrain.paint',
              'environment.generate',
              'border.draw',
              'border.erase'
            ]
          });

  Future<MapExteriorDecorationSnapshot> inspect(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      Iterable<String>? sectorIds,
      Iterable<String>? borderIds}) async {
    if (runInWorker) {
      return await _runWorker(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          command: 'inspect',
          parameters: {
            'sectorIds': sectorIds?.toList(),
            'borderIds': borderIds?.toList()
          }) as MapExteriorDecorationSnapshot;
    }
    final context = await _context(projectRoot, mapId, mapRelativePath);
    await _requireNoPending(context);
    final index = await _readIndex(context);
    final admissionKey = '${context.root}/${context.map.id}';
    if (index.definition != null &&
        !_referenceAdmissions.contains(admissionKey)) {
      final admission = await context.gateway
          .readResource(exteriorReferenceAdmissionPath(context.map.id));
      if (admission != null) {
        if (!_referenceAdmissionMatches(admission, context.map.id)) {
          throw const FormatException(
              'exterior.reference_index_recovery_required: invalid map admission.');
        }
        _referenceAdmissions.add(admissionKey);
      }
    }
    final selected = sectorIds?.toSet() ?? index.sectors.keys.toSet();
    if (!index.sectors.keys.toSet().containsAll(selected)) {
      throw const FormatException('Unknown exterior decoration sector.');
    }
    final sectors = <ExteriorDecorationSector>[];
    for (final id in selected) {
      sectors.add(await _readSector(context, index.sectors[id]!));
    }
    final selectedBorders = borderIds?.toSet() ?? index.borders.keys.toSet();
    if (!index.borders.keys.toSet().containsAll(selectedBorders)) {
      throw const FormatException('Unknown exterior decoration Border.');
    }
    final borders = <ExteriorDecorationBorder>[];
    for (final id in selectedBorders) {
      borders.add(await _readBorder(context, index.borders[id]!));
    }
    return MapExteriorDecorationSnapshot(
        revision: index.revision(context.map.id),
        decoration: index.definition == null
            ? null
            : _withVisuals(index.definition!, sectors, borders),
        sectorIds: index.sectors.keys,
        borderIds: index.borders.keys,
        borderRevisions: {
          for (final value in index.borders.values) value.id: value.revision
        },
        sectorRevisions: {
          for (final v in index.sectors.values) v.id: v.revision
        });
  }

  Future<MapExteriorDecorationMutation> configure(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String expectedRevision,
      required MapExteriorDecoration? decoration,
      required String operationId,
      FutureOr<void> Function()? precondition}) {
    if (decoration?.sectors.isNotEmpty == true ||
        decoration?.borders.isNotEmpty == true) {
      throw const FormatException(
          'Configure margins separately from sector edits.');
    }
    return _mutate(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        operationId: operationId,
        descriptor: configureDescriptor,
        parameters: {'decoration': decoration?.toJson()},
        precondition: precondition,
        prepare: (context, index) async {
          if (decoration == null) {
            if (index.sectors.isNotEmpty || index.borders.isNotEmpty) {
              throw const FormatException(
                  'Remove exterior sectors before clearing their definition.');
            }
            return {context.storageKey: null};
          }
          decoration.validateForMap(context.map);
          final next = _DecorationIndex(decoration, index.sectors,
              borders: index.borders);
          next.validate();
          return {context.storageKey: next.toJson()};
        });
  }

  Future<MapExteriorDecorationMutation> setSector(
          {required String projectRoot,
          required String mapId,
          String? mapRelativePath,
          required String expectedRevision,
          required ExteriorDecorationSector sector,
          required String operationId,
          FutureOr<void> Function()? precondition}) =>
      _mutate(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          expectedRevision: expectedRevision,
          operationId: operationId,
          descriptor: sectorSetDescriptor,
          parameters: {'sector': sector.toJson()},
          precondition: precondition,
          prepare: (context, index) async {
            final definition = index.definition;
            if (definition == null) {
              throw const FormatException(
                  'Configure exterior decoration before editing sectors.');
            }
            _withSectors(definition, [sector]).validateForMap(context.map);
            _safeId(sector.id);
            final json = sector.toJson();
            final bytes = _encode(json, maximumSectorBytes);
            final summary = _SectorSummary.fromSector(
                sector,
                computeAuthoringBytesFingerprint(bytes,
                    logicalName: _sectorPath(mapId, sector.id)));
            final next = _DecorationIndex(
                definition, {...index.sectors, sector.id: summary},
                borders: index.borders);
            next.validate();
            if (index.sectors.containsKey(sector.id)) {
              await _readSector(context, index.sectors[sector.id]!);
            } else if (await _readBytes(context, _sectorPath(mapId, sector.id),
                    maximumSectorBytes) !=
                null) {
              throw const FormatException(
                  'An unindexed exterior decoration sector requires explicit recovery.');
            }
            return {
              context.storageKey: next.toJson(),
              _sectorPath(mapId, sector.id): json
            };
          });

  Future<MapExteriorDecorationMutation> removeSector(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String expectedRevision,
      required String sectorId,
      required String operationId,
      FutureOr<void> Function()? precondition}) {
    _safeId(sectorId);
    return _mutate(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        operationId: operationId,
        descriptor: sectorRemoveDescriptor,
        parameters: {'sectorId': sectorId},
        precondition: precondition,
        prepare: (context, index) async {
          final summary = index.sectors[sectorId];
          if (summary == null) {
            throw const FormatException('Unknown exterior decoration sector.');
          }
          await _readSector(context, summary);
          final next = _DecorationIndex(
              index.definition, {...index.sectors}..remove(sectorId),
              borders: index.borders);
          return {
            context.storageKey: next.toJson(),
            _sectorPath(mapId, sectorId): null
          };
        });
  }

  Future<MapExteriorDecorationMutation> undo(
          {required String projectRoot,
          required String mapId,
          String? mapRelativePath,
          required MapExteriorDecorationMutation mutation,
          required String operationId}) =>
      undoReceipt(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          receiptId: mutation.receipt.receiptId,
          expectedRevision: mutation.afterRevision,
          operationId: operationId);

  Future<MapExteriorDecorationMutation> undoReceipt(
          {required String projectRoot,
          required String mapId,
          String? mapRelativePath,
          required String receiptId,
          required String expectedRevision,
          required String operationId}) =>
      _restoreReceipt(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          receiptId: receiptId,
          expectedRevision: expectedRevision,
          operationId: operationId);

  Future<MapExteriorDecorationMutation> redoReceipt(
          {required String projectRoot,
          required String mapId,
          String? mapRelativePath,
          required String receiptId,
          required String expectedRevision,
          required String operationId}) =>
      _restoreReceipt(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          receiptId: receiptId,
          expectedRevision: expectedRevision,
          operationId: operationId,
          redo: true);

  Future<MapExteriorDecorationMutation> _restoreReceipt(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String receiptId,
      required String expectedRevision,
      required String operationId,
      bool redo = false}) async {
    if (runInWorker) {
      return await _runWorker(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          command: redo ? 'redo' : 'undo',
          parameters: {'receiptId': receiptId},
          expectedRevision: expectedRevision,
          operationId: operationId) as MapExteriorDecorationMutation;
    }
    final context = await _context(projectRoot, mapId, mapRelativePath);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: context.root, incrementalWrites: true);
    final entry = await history.getDocumentEntry(
        projectId: context.projectId, entryId: receiptId);
    if (entry != null &&
        entry.actorId == _actor.actorId &&
        entry.kind == AuthoringHistoryKind.undo &&
        entry.targetEntryId != null &&
        !redo) {
      return redoReceipt(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          receiptId: entry.targetEntryId!,
          expectedRevision: expectedRevision,
          operationId: operationId);
    }
    if (entry == null ||
        entry.actorId != _actor.actorId ||
        entry.nonUndoableReason != null ||
        entry.receipt.actionId == prepareReferencesDescriptor.id ||
        !descriptors.any((v) => v.id == entry.receipt.actionId) ||
        entry.receipt.diff.entries.any((v) => v.extensions['mapId'] != mapId)) {
      throw const FormatException(
          'The exterior decoration receipt cannot be undone.');
    }
    final mutation = MapExteriorDecorationMutation.fromReceipt(entry.receipt);
    if ((redo ? mutation.beforeRevision : mutation.afterRevision) !=
        expectedRevision) {
      throw const FormatException('map.exteriorDecoration_revision_conflict');
    }
    String? expectedHeadEntryId;
    if (redo) {
      final head = await readAuthoringHistoryHead(history, context.projectId);
      if (head == null ||
          head.targetEntryId != receiptId ||
          !(head.kind == AuthoringHistoryKind.undo ||
              head.kind == AuthoringHistoryKind.redo &&
                  head.operationId == operationId)) {
        throw const FormatException(
            'Exterior decoration redo history diverged.');
      }
      expectedHeadEntryId = head.kind == AuthoringHistoryKind.redo
          ? AuthoringHistoryContext.fromExtensions(head.receipt.extensions)
              .expectedHeadEntryId
          : head.entryId;
    }
    final images = <String, List<int>?>{};
    final blobs =
        await FileAuthoringContentBlobStore.open(projectRoot: context.root);
    for (final change in entry.changes) {
      if (change.storageKey.startsWith('$exteriorReferenceNamespace/')) {
        continue;
      }
      final blobId = redo ? change.afterBlobId : change.beforeBlobId;
      if (blobId == null) {
        images[change.storageKey] = null;
        continue;
      }
      final payload =
          await blobs.capturePayload(blobId, storageKey: change.storageKey);
      if (payload == null ||
          payload.byteLength > (_storageLimit(context, change.storageKey))) {
        throw const FormatException(
            'Retained exterior decoration undo bytes are missing or oversized.');
      }
      try {
        final bytes = await payload.readBytes();
        if (computeAuthoringBytesFingerprint(bytes,
                logicalName: change.storageKey) !=
            (redo ? change.afterRevision : change.beforeRevision)) {
          throw const FormatException(
              'Retained exterior decoration undo bytes changed.');
        }
        images[change.storageKey] = bytes;
      } finally {
        await payload.release();
      }
    }
    return _mutate(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        operationId: operationId,
        descriptor:
            descriptors.singleWhere((v) => v.id == entry.receipt.actionId),
        parameters: {'restoreReceipt': receiptId, 'redo': redo},
        restoredBytes: images,
        historyContext: AuthoringHistoryContext(
            kind: redo ? AuthoringHistoryKind.redo : AuthoringHistoryKind.undo,
            targetEntryId: receiptId,
            expectedHeadEntryId: expectedHeadEntryId),
        prepare: (context, index) async => {
              for (final image in images.entries)
                image.key: image.value == null ? null : _decode(image.value!)
            });
  }

  Future<MapExteriorDecorationMutation> _mutate(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String expectedRevision,
      required String operationId,
      required AuthoringActionDescriptor descriptor,
      required Map<String, Object?> parameters,
      required Future<Map<String, Map<String, dynamic>?>> Function(
              _DecorationContext, _DecorationIndex)
          prepare,
      FutureOr<void> Function()? precondition,
      Map<String, List<int>?>? restoredBytes,
      AuthoringHistoryContext? historyContext,
      bool prepareReferences = false}) async {
    if (runInWorker) {
      if (precondition != null && descriptor.id != nativeEditDescriptor.id ||
          restoredBytes != null) {
        throw ArgumentError(
            'Worker mutations require local data preconditions.');
      }
      return await _runWorker(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          command: descriptor.id,
          parameters: parameters,
          expectedRevision: expectedRevision,
          operationId: operationId) as MapExteriorDecorationMutation;
    }
    final context = await _context(projectRoot, mapId, mapRelativePath);
    if (!_actor.allows(AuthoringPermissionScope.projectWrite)) {
      throw const FormatException('project.write permission is required.');
    }
    if (prepareReferences &&
        !_actor.allows(AuthoringPermissionScope.recoveryApply)) {
      throw const FormatException(
          'recovery.apply permission is required for explicit reference preparation.');
    }
    safeAuthoringSecurityIdentifier(operationId, 'operationId');
    final request = AuthoringRequest(
        requestId: operationId,
        actionId: descriptor.id,
        actionVersion: 1,
        workspaceHandle: context.projectId,
        parameters: {
          'mapId': mapId,
          'mapRelativePath': context.mapPath,
          ...parameters
        },
        expectedRevision: expectedRevision,
        idempotencyKey: operationId,
        extensions: {
          'history': (historyContext ?? AuthoringHistoryContext()).toJson()
        });
    final scope = AuthoringIdempotencyScope(
        actorId: _actor.actorId,
        projectId: context.projectId,
        actionId: descriptor.id,
        actionVersion: 1,
        key: operationId);
    final store = await FileIdempotencyStore.forScope(
        filePath: '${context.root}/.pokemap/authoring/idempotency.jsonl',
        scope: scope);
    final ledger = AuthoringIdempotencyLedger(store: store);
    final recorder = descriptor.id == prepareReferencesDescriptor.id
        ? null
        : AuthoringHistoryRecorder(
            store: await FileAuthoringHistoryStore.open(
                projectRoot: context.root, incrementalWrites: true),
            blobs: await FileAuthoringContentBlobStore.open(
                projectRoot: context.root));
    final existing = await store.read(scope);
    if (existing != null) {
      if (existing.payloadFingerprint !=
              computeAuthoringIdempotencyPayloadFingerprint(request) ||
          existing.operationId != operationId) {
        throw AuthoringIdempotencyException(
            code: 'idempotency.payload_conflict',
            message: 'This operation owns another exterior decoration intent.');
      }
      var receipt = existing.receipt;
      if (existing.status != AuthoringIdempotencyStatus.completed) {
        if (!_actor.allows(AuthoringPermissionScope.recoveryApply)) {
          throw const FormatException('recovery.apply permission is required.');
        }
        await _guardReplayedBorderTerrainDependencies(
            context,
            existing.receipt ??
                (await context.gateway.readJournal(operationId))!
                    .intendedReceipt);
        final verifyReferences = await _admitVisualReferences(context, {
          for (final diff in existing.receipt?.diff.entries ??
              (await context.gateway.readJournal(operationId))!
                  .intendedReceipt
                  .diff
                  .entries)
            diff.extensions['storageKey']! as String: diff.after == null
                ? null
                : Map<String, dynamic>.from(diff.after! as Map)
        });
        receipt = await AuthoringRecoveryService(
                gateway: context.gateway,
                idempotency: ledger,
                clock: DateTime.now,
                commitHook: recorder)
            .resume(operationId, precondition: () async {
          await _verifyMap(context);
          await precondition?.call();
          await verifyReferences();
          await _verifyMap(context);
        });
      }
      if (receipt == null ||
          receipt.actionId != descriptor.id ||
          receipt.requestId != operationId ||
          receipt.diff.entries.any((v) => v.extensions['mapId'] != mapId)) {
        throw const FormatException(
            'Invalid exterior decoration replay receipt.');
      }
      final replay = MapExteriorDecorationMutation.fromReceipt(receipt);
      if (replay.beforeRevision != expectedRevision) {
        throw const FormatException(
            'Exterior decoration replay revision mismatch.');
      }
      await context.gateway.deleteTransaction(operationId);
      await _auditReplay(context, descriptor, receipt);
      return replay;
    }
    await _requireNoPending(context, operationId: operationId);
    final index = await _readIndex(context);
    if (index.revision(mapId) != expectedRevision) {
      throw const FormatException('map.exteriorDecoration_revision_conflict');
    }
    final after = await prepare(context, index);
    if (!after.containsKey(context.storageKey)) {
      throw const FormatException(
          'Exterior decoration mutation must update its definition.');
    }
    if (after[context.storageKey] != null) {
      _DecorationIndex.fromJson(after[context.storageKey]!)
          .validateForMap(context.map);
    }
    await _guardBorderTerrainDependencies(context, index, after);
    final verifyVisualReferences = await _admitVisualReferences(context, after);
    final changes = <AuthoringResourceChange>[];
    final diffs = <AuthoringDiffEntry>[];
    final afterIndexBytes =
        restoredBytes != null && restoredBytes.containsKey(context.storageKey)
            ? restoredBytes[context.storageKey]
            : after[context.storageKey] == null
                ? null
                : _encode(after[context.storageKey]!, maximumDefinitionBytes);
    final afterRevision = _revision(afterIndexBytes, context.storageKey, mapId);
    for (final item in after.entries) {
      final isIndex = item.key == context.storageKey;
      final isBorder = item.key.startsWith('maps/$mapId.decoration/borders/');
      final id = isIndex
          ? mapId
          : item.key
              .substring(item.key.lastIndexOf('/') + 1, item.key.length - 5);
      if (!isIndex &&
          item.key !=
              (isBorder ? _borderPath(mapId, id) : _sectorPath(mapId, id))) {
        throw const FormatException('Invalid exterior sector storage key.');
      }
      final before =
          await _readBytes(context, item.key, _storageLimit(context, item.key));
      if (isIndex && _revision(before, item.key, mapId) != expectedRevision) {
        throw const FormatException('map.exteriorDecoration_revision_conflict');
      }
      final bytes = restoredBytes != null && restoredBytes.containsKey(item.key)
          ? restoredBytes[item.key]
          : isIndex
              ? afterIndexBytes
              : item.value == null
                  ? null
                  : _encode(item.value!, _storageLimit(context, item.key));
      if (_sameBytes(before, bytes)) continue;
      final resource = AuthoringResourceRef(
          kind: isIndex
              ? 'mapExteriorDecoration'
              : isBorder
                  ? 'exteriorDecorationBorder'
                  : 'exteriorDecorationSector',
          id: isIndex ? mapId : '$mapId:$id');
      changes.add(AuthoringResourceChange(
          resource: resource,
          storageKey: item.key,
          beforeBytes: before,
          afterBytes: bytes));
      diffs.add(AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resource,
          path: isIndex
              ? '/exteriorDecoration'
              : '/exteriorDecoration/${isBorder ? 'borders' : 'sectors'}/$id',
          before: before == null ? null : _decode(before),
          after: item.value,
          extensions: {
            'mapId': mapId,
            'storageKey': item.key,
            'documentBeforeRevision': expectedRevision,
            'documentAfterRevision': afterRevision
          }));
    }
    await _prepareIncomingChanges(
        context, index, after, changes, diffs, expectedRevision, afterRevision,
        repairing: prepareReferences, operationId: operationId);
    if (changes.isEmpty) {
      throw const FormatException('map.exteriorDecoration_no_changes');
    }
    if (!prepareReferences &&
        !changes.any((v) => v.storageKey == context.storageKey)) {
      throw const FormatException(
          'Exterior decoration revision must include the sector mutation.');
    }
    final prior = await context.gateway.readJournal(operationId);
    if (prior != null) {
      if (!_actor.allows(AuthoringPermissionScope.recoveryApply) ||
          prior.scope.storageKey != scope.storageKey ||
          prior.intendedReceipt.actionId != descriptor.id ||
          computeAuthoringJsonFingerprint(prior.intendedReceipt.diff.toJson(),
                  logicalName: 'decoration-retry.json') !=
              computeAuthoringJsonFingerprint(AuthoringDiff(diffs).toJson(),
                  logicalName: 'decoration-retry.json')) {
        throw const FormatException(
            'The pending exterior decoration intent differs from this retry.');
      }
      await AuthoringRecoveryService(
              gateway: context.gateway,
              idempotency: ledger,
              clock: DateTime.now)
          .discardUnreserved(operationId);
    }
    final plans = AuthoringPlanStore();
    final plan = AuthoringPlan(
        planId: _identity('plan_document_'),
        receiptId: _identity('receipt_document_'),
        request: request,
        baseRevision: expectedRevision,
        seed: 0,
        createdAt: plans.now,
        expiresAt: plans.now.add(plans.ttl),
        changeSet:
            AuthoringChangeSet(changes: changes, diff: AuthoringDiff(diffs)));
    plans.save(plan);
    final executor = SecureAuthoringMutationExecutor(
        transaction: JournaledAuthoringTransaction(
            plans: plans,
            gateway: context.gateway,
            idempotency: ledger,
            clock: DateTime.now,
            commitHook: recorder,
            faultInjector: _faultInjector),
        policy: AuthoringAuthorizationPolicy(
            confirmations: AuthoringConfirmationStore(clock: DateTime.now),
            clock: DateTime.now),
        auditLog: await FileAuthoringAuditLog.open(
            projectRoot: context.root, incrementalWrites: true),
        clock: DateTime.now,
        auditIdFactory: () => _identity('audit_document_'));
    try {
      final receipt = await executor.apply(
          actor: _actor,
          projectId: context.projectId,
          action: descriptor,
          plan: plan,
          currentProjectRevision: expectedRevision,
          scope: scope,
          operationId: operationId,
          precondition: () async {
            await _verifyMap(context);
            await precondition?.call();
            await verifyVisualReferences();
            await _verifyMap(context);
            await _requireNoPending(context, operationId: operationId);
          });
      _referenceAdmissions.add('${context.root}/${context.map.id}');
      return MapExteriorDecorationMutation.fromReceipt(receipt);
    } finally {
      await plan.releaseAppliedPayload();
    }
  }

  Future<_DecorationContext> _context(
      String projectRoot, String mapId, String? mapRelativePath) async {
    if (!_actor.allows(AuthoringPermissionScope.projectRead)) {
      throw const FormatException('project.read permission is required.');
    }
    _safeId(mapId);
    final root = await _policy.authorizeProjectRoot(projectRoot);
    final mapPath = mapRelativePath ?? 'maps/$mapId.json';
    if (validateProjectRelativePath(mapPath).join('/') != mapPath ||
        !mapPath.endsWith('.json') ||
        mapPath.split('/').first == '.pokemap' ||
        (mapPath == 'maps/$mapId.decoration.json' ||
            mapPath.startsWith('maps/$mapId.decoration/'))) {
      throw const FormatException('Invalid exterior decoration map path.');
    }
    final probe = await _probe(root, mapPath);
    if (probe.status != ProjectResourceProbeStatus.exists) {
      throw const FormatException(
          'The exterior decoration map is missing or unsafe.');
    }
    final identity = probe.identity!;
    final key = '$root/$mapPath';
    var cached = _maps[key];
    if (cached == null || cached.$1 != identity) {
      final bytes =
          await _reader.readBytes(projectRoot: root, relativePath: mapPath);
      _observer?.incrementCounter(AuthoringPerformanceCounterName.jsonDecode);
      final map = MapData.fromJson(_decode(bytes));
      if (map.id != mapId || map.spatialScene == null) {
        throw const FormatException(
            'Exterior decoration requires the identified spatial map.');
      }
      cached = (identity, map);
      _maps[key] = cached;
    }
    return _DecorationContext(
        root,
        'maps/$mapId.decoration.json',
        mapPath,
        'local_project_${computeAuthoringJsonFingerprint(root, logicalName: 'local-project-root.json').substring(7)}',
        cached.$2,
        identity,
        await LocalTransactionFileGateway.open(
            projectRoot: root,
            expectedProjectRoot: root,
            performanceObserver: _observer,
            transactionNamespace: 'exterior-decoration'));
  }

  Future<void> _verifyMap(_DecorationContext context) async {
    final probe = await _probe(context.root, context.mapPath);
    if (probe.status != ProjectResourceProbeStatus.exists ||
        probe.identity != context.mapIdentity) {
      throw const FormatException(
          'The playable map changed during decoration editing.');
    }
  }

  Future<ProjectResourceProbe> _probe(String root, String path) async {
    if (_reader is! ProjectResourceProbeReader) {
      throw const FormatException(
          'Exterior decoration requires a metadata-only resource probe.');
    }
    return (_reader as ProjectResourceProbeReader)
        .probeResource(projectRoot: root, relativePath: path);
  }

  Future<List<int>?> _readBytes(
      _DecorationContext context, String key, int maxBytes) async {
    final probe = await _probe(context.root, key);
    if (probe.status == ProjectResourceProbeStatus.missing) return null;
    if (probe.status != ProjectResourceProbeStatus.exists ||
        probe.identity!.byteLength > maxBytes) {
      throw const FormatException(
          'Exterior decoration resource is unsafe or oversized.');
    }
    final bytes = await context.gateway.readResource(key);
    if (bytes == null || bytes.length > maxBytes) {
      throw const FormatException(
          'Exterior decoration changed during reading.');
    }
    return bytes;
  }

  Future<_DecorationIndex> _readIndex(_DecorationContext context) async {
    final bytes =
        await _readBytes(context, context.storageKey, maximumDefinitionBytes);
    if (bytes == null) return _DecorationIndex(null, const {});
    final index = _DecorationIndex.fromJson(_decode(bytes), bytes: bytes);
    index.validateForMap(context.map);
    return index;
  }

  Future<ExteriorDecorationSector> _readSector(
      _DecorationContext context, _SectorSummary summary) async {
    final path = _sectorPath(context.map.id, summary.id);
    final bytes = await _readBytes(context, path, maximumSectorBytes);
    if (bytes == null ||
        computeAuthoringBytesFingerprint(bytes, logicalName: path) !=
            summary.revision) {
      throw const FormatException(
          'Required exterior decoration sector is missing or changed.');
    }
    _observer?.incrementCounter(AuthoringPerformanceCounterName.jsonDecode);
    final sector = ExteriorDecorationSector.fromJson(_decode(bytes));
    if (jsonEncode(
            _SectorSummary.fromSector(sector, summary.revision).toJson()) !=
        jsonEncode(summary.toJson())) {
      throw const FormatException(
          'Exterior decoration sector summary mismatch.');
    }
    return sector;
  }

  Future<void> _requireNoPending(_DecorationContext context,
      {String? operationId}) async {
    for (final journal in await context.gateway.listJournals()) {
      if (journal.operationId != operationId &&
          journal.status != AuthoringTransactionStatus.committed &&
          journal.status != AuthoringTransactionStatus.compensated) {
        throw const FormatException('map.exteriorDecoration_recovery_required');
      }
    }
  }

  Future<void> _auditReplay(_DecorationContext context,
      AuthoringActionDescriptor descriptor, AuthoringReceipt receipt) async {
    final log = await FileAuthoringAuditLog.open(
        projectRoot: context.root, incrementalWrites: true);
    await log.append(AuthoringAuditRecord(
        auditId: _identity('audit_document_'),
        actorId: _actor.actorId,
        projectId: context.projectId,
        operation: AuthoringSecurityOperation.apply,
        decision: AuthoringAuditDecision.succeeded,
        requestId: receipt.requestId,
        actionId: descriptor.id,
        actionVersion: 1,
        riskLevel: descriptor.riskLevel,
        planId: receipt.extensions['planId'] as String?,
        receiptId: receipt.receiptId,
        code: 'mutation.succeeded',
        timestamp: DateTime.now(),
        details: const {'idempotentReplay': true}));
  }
}

final class _DecorationContext {
  const _DecorationContext(this.root, this.storageKey, this.mapPath,
      this.projectId, this.map, this.mapIdentity, this.gateway);
  final String root, storageKey, mapPath, projectId;
  final MapData map;
  final ProjectResourceIdentity mapIdentity;
  final LocalTransactionFileGateway gateway;
}

final class _DecorationIndex {
  _DecorationIndex(this.definition, Map<String, _SectorSummary> sectors,
      {Map<String, _SectorSummary> borders = const {}, this.bytes})
      : sectors = Map.unmodifiable(sectors),
        borders = Map.unmodifiable(borders);
  final MapExteriorDecoration? definition;
  final Map<String, _SectorSummary> sectors, borders;
  final List<int>? bytes;
  factory _DecorationIndex.fromJson(Map<String, dynamic> json,
      {List<int>? bytes}) {
    if (json.keys.toSet().difference(
            {'schemaVersion', 'definition', 'sectors', 'borders'}).isNotEmpty ||
        json['schemaVersion'] != 1 ||
        json['definition'] is! Map<String, dynamic> ||
        json['sectors'] is! List ||
        json.containsKey('borders') && json['borders'] is! List) {
      throw const FormatException(
          'Invalid exterior decoration storage definition.');
    }
    final definition = MapExteriorDecoration.fromJson(
        json['definition'] as Map<String, dynamic>);
    if (definition.sectors.isNotEmpty || definition.borders.isNotEmpty) {
      throw const FormatException(
          'Exterior visual units require independent storage.');
    }
    Map<String, _SectorSummary> summaries(List raw, int maxSize) {
      final result = <String, _SectorSummary>{};
      for (final item in raw) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid exterior visual summary.');
        }
        final summary = _SectorSummary.fromJson(item, maximumSize: maxSize);
        if (result.containsKey(summary.id)) {
          throw const FormatException('Duplicate exterior visual identity.');
        }
        result[summary.id] = summary;
      }
      return result;
    }

    final index = _DecorationIndex(
        definition, summaries(json['sectors'] as List, 32),
        borders: summaries(json['borders'] as List? ?? const [], 384),
        bytes: bytes);
    index.validate();
    return index;
  }
  String revision(String mapId) => _revision(
      bytes ??
          (definition == null
              ? null
              : _encode(toJson(),
                  LocalMapExteriorDecorationAuthoring.maximumDefinitionBytes)),
      'maps/$mapId.decoration.json',
      mapId);
  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'definition': definition!.toJson(),
        'sectors': [for (final value in sectors.values) value.toJson()],
        if (borders.isNotEmpty)
          'borders': [for (final value in borders.values) value.toJson()]
      };
  void validateForMap(MapData map) {
    definition?.validateForMap(map);
    validate();
  }

  void validate() {
    final units = [...sectors.values, ...borders.values];
    if (sectors.length > 256 ||
        borders.length > 64 ||
        units.fold<int>(0, (sum, v) => sum + v.instances) > 10000 ||
        units.expand((v) => v.resourceIds).toSet().length > 1024) {
      throw const FormatException('Exterior decoration quota exceeded.');
    }
    final d = definition;
    if (d == null) {
      if (units.isNotEmpty) {
        throw const FormatException('Exterior visuals require a definition.');
      }
      return;
    }
    for (final s in units) {
      if (s.x < -d.west ||
          s.z < -d.north ||
          s.x + s.width > d.playableWidth + d.east ||
          s.z + s.depth > d.playableDepth + d.south) {
        throw const FormatException('Exterior visual exceeds its margins.');
      }
    }
    final values = sectors.values.toList();
    for (var i = 0; i < values.length; i++) {
      final s = values[i];
      for (var j = 0; j < i; j++) {
        final t = values[j];
        if (s.x < t.x + t.width &&
            t.x < s.x + s.width &&
            s.z < t.z + t.depth &&
            t.z < s.z + s.depth) {
          throw const FormatException('Exterior sectors overlap.');
        }
      }
    }
  }
}

final class _SectorSummary {
  factory _SectorSummary.fromBorder(
          ExteriorDecorationBorder border, String revision) =>
      _SectorSummary(
          border.id,
          border.originX,
          border.originZ,
          border.width,
          border.depth,
          border.instances.length,
          revision,
          border.resourceReferenceIds);
  _SectorSummary(this.id, this.x, this.z, this.width, this.depth,
      this.instances, this.revision, Iterable<String> resourceIds)
      : resourceIds = List.unmodifiable(resourceIds.toList()..sort());
  factory _SectorSummary.fromSector(
          ExteriorDecorationSector sector, String revision) =>
      _SectorSummary(
          sector.id,
          sector.originX,
          sector.originZ,
          sector.scene.width,
          sector.scene.depth,
          sector.scene.instances.length,
          revision,
          sector.resourceReferenceIds);
  factory _SectorSummary.fromJson(Map<String, dynamic> json,
      {int maximumSize = 32}) {
    const keys = {
      'id',
      'originX',
      'originZ',
      'width',
      'depth',
      'instances',
      'revision',
      'resourceIds'
    };
    final refs = json['resourceIds'];
    if (json.keys.toSet().difference(keys).isNotEmpty ||
        !json.keys.toSet().containsAll(keys) ||
        json['id'] is! String ||
        json['revision'] is! String ||
        !RegExp(r'^sha256:[a-f0-9]{64}$')
            .hasMatch(json['revision'] as String) ||
        ['originX', 'originZ', 'width', 'depth', 'instances']
            .any((v) => json[v] is! int) ||
        refs is! List ||
        refs.length > MapExteriorDecoration.maxResourceReferences ||
        refs.any((v) => v is! String || v.isEmpty || v.length > 512) ||
        refs.toSet().length != refs.length) {
      throw const FormatException(
          'Invalid exterior decoration sector summary.');
    }
    _safeId(json['id'] as String);
    final s = _SectorSummary(
        json['id'] as String,
        json['originX'] as int,
        json['originZ'] as int,
        json['width'] as int,
        json['depth'] as int,
        json['instances'] as int,
        json['revision'] as String,
        refs.cast<String>());
    if (s.width < 1 ||
        s.width > maximumSize ||
        s.depth < 1 ||
        s.depth > maximumSize ||
        s.instances < 0 ||
        s.instances > MapExteriorDecoration.maxInstances) {
      throw const FormatException(
          'Exterior decoration summary quota exceeded.');
    }
    return s;
  }
  final String id, revision;
  final int x, z, width, depth, instances;
  final List<String> resourceIds;
  Map<String, dynamic> toJson() => {
        'id': id,
        'originX': x,
        'originZ': z,
        'width': width,
        'depth': depth,
        'instances': instances,
        'revision': revision,
        'resourceIds': resourceIds
      };
}

int _storageLimit(_DecorationContext context, String key) =>
    key == context.storageKey
        ? LocalMapExteriorDecorationAuthoring.maximumDefinitionBytes
        : key.startsWith('maps/${context.map.id}.decoration/borders/')
            ? LocalMapExteriorDecorationAuthoring.maximumBorderBytes
            : LocalMapExteriorDecorationAuthoring.maximumSectorBytes;
MapExteriorDecoration _withVisuals(
        MapExteriorDecoration d,
        Iterable<ExteriorDecorationSector> sectors,
        Iterable<ExteriorDecorationBorder> borders) =>
    MapExteriorDecoration(
        mapId: d.mapId,
        playableWidth: d.playableWidth,
        playableDepth: d.playableDepth,
        west: d.west,
        east: d.east,
        north: d.north,
        south: d.south,
        sectors: sectors,
        borders: borders);
MapExteriorDecoration _withSectors(
        MapExteriorDecoration d, Iterable<ExteriorDecorationSector> sectors) =>
    MapExteriorDecoration(
        mapId: d.mapId,
        playableWidth: d.playableWidth,
        playableDepth: d.playableDepth,
        west: d.west,
        east: d.east,
        north: d.north,
        south: d.south,
        sectors: sectors);
void _safeId(String id) {
  if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id)) {
    throw const FormatException('Unsafe exterior decoration identity.');
  }
}

String _sectorPath(String mapId, String id) {
  _safeId(id);
  return 'maps/$mapId.decoration/$id.json';
}

List<int> _encode(Map<String, dynamic> json, int max) {
  final bytes = utf8.encode(jsonEncode(json));
  if (bytes.length > max) {
    throw const FormatException(
        'Exterior decoration resource exceeds its byte limit.');
  }
  return bytes;
}

Map<String, dynamic> _decode(List<int> bytes) {
  final raw = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('Invalid exterior decoration JSON object.');
  }
  return raw;
}

String _revision(List<int>? bytes, String key, String mapId) => bytes == null
    ? computeAuthoringJsonFingerprint({'mapId': mapId, 'present': false},
        logicalName: 'map-exterior-decoration-absence.json')
    : computeAuthoringBytesFingerprint(bytes, logicalName: key);
bool _sameBytes(List<int>? a, List<int>? b) {
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _identity(String prefix) =>
    '$prefix${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

Future<MapExteriorDecoration?> loadMapExteriorDecoration({
  required String projectRoot,
  required MapData map,
  ProjectFileReader? reader,
  String? mapRelativePath,
}) async {
  final files = reader ?? const LocalProjectFileReader();
  if (mapRelativePath == 'maps/${map.id}.decoration.json') return null;
  if (map.id.contains('/') || map.id.contains(r'\') || map.id == '..') {
    return null;
  }
  final definitionBytes = await _readExteriorDecorationResource(
      files,
      projectRoot,
      'maps/${map.id}.decoration.json',
      LocalMapExteriorDecorationAuthoring.maximumDefinitionBytes);
  if (definitionBytes == null) return null;
  _safeId(map.id);
  final index = _DecorationIndex.fromJson(_decode(definitionBytes),
      bytes: definitionBytes);
  index.validateForMap(map);
  final sectors = <ExteriorDecorationSector>[];
  for (final summary in index.sectors.values) {
    final path = _sectorPath(map.id, summary.id);
    final bytes = await _readExteriorDecorationResource(files, projectRoot,
        path, LocalMapExteriorDecorationAuthoring.maximumSectorBytes);
    if (bytes == null ||
        computeAuthoringBytesFingerprint(bytes, logicalName: path) !=
            summary.revision) {
      throw const FormatException(
          'Required exterior decoration sector is missing or changed.');
    }
    final sector = ExteriorDecorationSector.fromJson(_decode(bytes));
    if (jsonEncode(
            _SectorSummary.fromSector(sector, summary.revision).toJson()) !=
        jsonEncode(summary.toJson())) {
      throw const FormatException(
          'Exterior decoration sector summary mismatch.');
    }
    sectors.add(sector);
  }
  final borders = <ExteriorDecorationBorder>[];
  for (final summary in index.borders.values) {
    final path = _borderPath(map.id, summary.id);
    final bytes = await _readExteriorDecorationResource(files, projectRoot,
        path, LocalMapExteriorDecorationAuthoring.maximumBorderBytes);
    if (bytes == null ||
        computeAuthoringBytesFingerprint(bytes, logicalName: path) !=
            summary.revision) {
      throw const FormatException(
          'Required exterior Border is missing or changed.');
    }
    final border = ExteriorDecorationBorder.fromJson(_decode(bytes));
    if (jsonEncode(
            _SectorSummary.fromBorder(border, summary.revision).toJson()) !=
        jsonEncode(summary.toJson())) {
      throw const FormatException('Exterior Border summary mismatch.');
    }
    borders.add(border);
  }
  return _withVisuals(index.definition!, sectors, borders);
}

Future<List<int>?> _readExteriorDecorationResource(
    ProjectFileReader reader, String root, String path, int maxBytes) async {
  if (reader is! ProjectResourceProbeReader) {
    throw const FormatException(
        'Exterior decoration loading requires a metadata-only resource probe.');
  }
  final probe = await (reader as ProjectResourceProbeReader)
      .probeResource(projectRoot: root, relativePath: path);
  if (probe.status == ProjectResourceProbeStatus.missing) return null;
  if (probe.status != ProjectResourceProbeStatus.exists ||
      probe.identity!.byteLength > maxBytes) {
    throw const FormatException(
        'Exterior decoration resource is unsafe or oversized.');
  }
  final bytes = await reader.readBytes(projectRoot: root, relativePath: path);
  if (bytes.length > maxBytes) {
    throw const FormatException('Exterior decoration resource is oversized.');
  }
  return bytes;
}
