import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'map_document_write_lock.dart';
import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;
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
import '../support/map_authoring_worker_trace.dart';
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

final class MapElementOrderSnapshot {
  const MapElementOrderSnapshot(
      {required this.revision,
      required this.map,
      required this.fileRevision,
      required Map<String, dynamic> json})
      : _json = json;
  final String revision, fileRevision;
  final MapData map;
  final Map<String, dynamic> _json;
  Map<String, Object?> toJson() =>
      {'revision': revision, 'fileRevision': fileRevision, 'map': _json};
}

final class MapElementOrderMutation {
  const MapElementOrderMutation(
      {required this.beforeRevision,
      required this.afterRevision,
      required this.beforeMap,
      required this.afterMap,
      required this.fileRevision,
      required this.receipt});
  final String beforeRevision, afterRevision, fileRevision;
  final MapData beforeMap, afterMap;
  final AuthoringReceipt receipt;
  factory MapElementOrderMutation.fromReceipt(AuthoringReceipt receipt) {
    final diff = receipt.diff.entries.single;
    return MapElementOrderMutation(
        beforeRevision: diff.extensions['documentBeforeRevision']! as String,
        afterRevision: diff.extensions['documentAfterRevision']! as String,
        fileRevision: diff.extensions['mapFileRevision']! as String,
        beforeMap:
            MapData.fromJson(Map<String, dynamic>.from(diff.before! as Map)),
        afterMap:
            MapData.fromJson(Map<String, dynamic>.from(diff.after! as Map)),
        receipt: receipt);
  }
  Map<String, Object?> toJson() => {
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'beforeMap': receipt.diff.entries.single.before,
        'afterMap': receipt.diff.entries.single.after,
        'fileRevision': fileRevision,
        'receipt': receipt.toJson()
      };
}

final class LocalMapElementOrderAuthoring {
  LocalMapElementOrderAuthoring(
      {required WorkspacePolicy policy,
      ProjectFileReader? reader,
      AuthoringActor? actor,
      AuthoringTransactionFaultInjector? faultInjector,
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
        _faultInjector = faultInjector;
  final bool runInWorker;
  final SendPort? diagnosticsPort;
  final WorkspacePolicy _policy;
  final ProjectFileReader _reader;
  final AuthoringActor _actor;
  final AuthoringTransactionFaultInjector? _faultInjector;
  static final descriptor = AuthoringActionDescriptor(
      id: 'map.elements.reorder',
      version: 1,
      summary:
          'Reorder map layers or decorations within one layer, front first',
      inputSchemaId: 'pokemap.authoring.map.elements.reorder.input.v1',
      outputSchemaId: 'pokemap.authoring.map.elements.reorder.output.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const [
        'map'
      ],
      requiredPermissions: const [
        AuthoringPermission.projectWrite
      ],
      guarantees: const [
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable
      ],
      extensions: const {
        'kinds': ['layers', 'decor'],
        'order': 'frontFirst',
        'decorScope': 'singleTileLayer',
        'revisionScope': 'selectedMapDocument',
        'maximumDocumentBytes': _maximumMapBytes,
        'loadsProject': false,
        'preservesUnknownFields': true
      });
  Future<MapElementOrderSnapshot> inspect(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath}) async {
    if (runInWorker) {
      return await _runWorker(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          command: 'inspect') as MapElementOrderSnapshot;
    }
    return _read(await _context(projectRoot, mapId, mapRelativePath), mapId);
  }

  Future<MapElementOrderMutation> reorder(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String expectedRevision,
      required String kind,
      required List<String> frontFirstIds,
      String? layerId,
      required String operationId,
      FutureOr<void> Function()? precondition}) async {
    if (runInWorker) {
      if (precondition != null) {
        throw ArgumentError(
            'Worker mutations require a local data precondition.');
      }
      return await _runWorker(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          command: 'reorder',
          expectedRevision: expectedRevision,
          kind: kind,
          frontFirstIds: frontFirstIds,
          layerId: layerId,
          operationId: operationId) as MapElementOrderMutation;
    }
    final context = await _context(projectRoot, mapId, mapRelativePath);
    final before = await _read(context, mapId);
    final raw = Map<String, dynamic>.from(before._json);
    var sameOrder = false;
    if (kind == 'layers') {
      if (layerId != null) {
        throw const FormatException(
            'Layer reordering does not take a layerId.');
      }
      _requirePermutation(
          frontFirstIds, before.map.layers.map((layer) => layer.id).toList());
      final ordered = mapPaintsFirstLayerInFront(before.map)
          ? frontFirstIds
          : frontFirstIds.reversed.toList();
      final layers = {
        for (final value in raw['layers'] as List)
          (value as Map)['id'] as String: value
      };
      raw['layers'] = [for (final id in ordered) layers[id]];
    } else if (kind == 'decor') {
      if (layerId == null ||
          !before.map.layers
              .any((layer) => layer.id == layerId && layer is TileLayer)) {
        throw const FormatException(
            'Decoration reordering requires an existing TileLayer.');
      }
      final elements = before.map.placedElements
          .where((element) => element.layerId == layerId)
          .toList();
      if (before.map.placedElements
              .map((element) => element.id)
              .toSet()
              .length !=
          before.map.placedElements.length) {
        throw const FormatException('Map decoration IDs must be unique.');
      }
      _requirePermutation(
          frontFirstIds, elements.map((element) => element.id).toList());
      sameOrder = const DeepCollectionEquality().equals(
        frontFirstIds,
        sortMapPlacedElementsForPainting(elements)
            .reversed
            .map((element) => element.id)
            .toList(),
      );
      final ranks = {
        for (final entry in frontFirstIds.indexed)
          entry.$2: frontFirstIds.length - entry.$1 - 1
      };
      raw['placedElements'] = [
        for (final value in raw['placedElements'] as List? ?? const [])
          if (ranks.containsKey((value as Map)['id']))
            {
              ...Map<String, dynamic>.from(value),
              'visualOrder': ranks[value['id']]
            }
          else
            value
      ];
    } else {
      throw const FormatException('Unsupported map element order kind.');
    }
    return _set(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        mapJson: raw,
        rejectNoChanges: sameOrder,
        intent: {
          'kind': kind,
          'frontFirstIds': frontFirstIds,
          if (layerId != null) 'layerId': layerId
        },
        operationId: operationId,
        precondition: precondition);
  }

  Future<MapElementOrderMutation> _set({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String expectedRevision,
    required Map<String, dynamic> mapJson,
    bool rejectNoChanges = false,
    Map<String, Object?>? intent,
    required String operationId,
    FutureOr<void> Function()? precondition,
    AuthoringHistoryContext? historyContext,
  }) async {
    final context = await _context(projectRoot, mapId, mapRelativePath);
    return withMapDocumentWriteLock(
      p.join(context.root, context.mapPath),
      (canonicalMapPath) async {
        final identity = narrativeEventBytesFingerprint(
          utf8.encode(p.normalize(canonicalMapPath)),
        ).substring(7, 31);
        final journal = File(p.join(
          p.dirname(canonicalMapPath),
          '.pokemap-map-$identity.journal.json',
        ));
        if (await journal.exists()) {
          throw const FormatException(
            'map.elements_recovery_required: Recover the pending native map save before reordering.',
          );
        }
        return _setLocked(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          expectedRevision: expectedRevision,
          mapJson: mapJson,
          rejectNoChanges: rejectNoChanges,
          intent: intent,
          operationId: operationId,
          precondition: precondition,
          historyContext: historyContext,
        );
      },
    );
  }

  Future<MapElementOrderMutation> _setLocked({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String expectedRevision,
    required Map<String, dynamic> mapJson,
    bool rejectNoChanges = false,
    Map<String, Object?>? intent,
    required String operationId,
    FutureOr<void> Function()? precondition,
    AuthoringHistoryContext? historyContext,
  }) async {
    final context = await _context(projectRoot, mapId, mapRelativePath);
    if (!_actor.allows(AuthoringPermissionScope.projectWrite)) {
      throw const FormatException('project.write permission is required.');
    }
    safeAuthoringSecurityIdentifier(operationId, 'operationId');
    final afterMap = MapData.fromJson(mapJson);
    if (afterMap.id != mapId) {
      throw const FormatException('Map order identity mismatch.');
    }
    final afterBytes = utf8.encode(jsonEncode(mapJson));
    if (afterBytes.length > _maximumMapBytes) {
      throw const FormatException('Map document exceeds its byte limit.');
    }
    final request = AuthoringRequest(
        requestId: operationId,
        actionId: descriptor.id,
        actionVersion: 1,
        workspaceHandle: context.projectId,
        parameters: {
          'mapId': mapId,
          'mapRelativePath': context.mapPath,
          'intent': intent ?? {'restoreMap': mapJson}
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
    final recorder = AuthoringHistoryRecorder(
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
            message: 'This operation owns a different editor intent.');
      }
      var receipt = existing.receipt;
      if (existing.status != AuthoringIdempotencyStatus.completed) {
        if (!_actor.allows(AuthoringPermissionScope.recoveryApply)) {
          throw const FormatException('recovery.apply permission is required.');
        }
        receipt = await AuthoringRecoveryService(
                gateway: context.gateway,
                idempotency: ledger,
                clock: DateTime.now,
                commitHook: recorder)
            .resume(operationId, precondition: () async {
          await _verifyMap(context);
          await precondition?.call();
        });
      }
      if (receipt == null ||
          receipt.actionId != descriptor.id ||
          receipt.requestId != operationId ||
          receipt.diff.entries.length != 1) {
        throw const FormatException('Invalid editor replay receipt.');
      }
      final replay = MapElementOrderMutation.fromReceipt(receipt);
      if (replay.beforeRevision != expectedRevision ||
          receipt.diff.entries.single.resource.id != mapId) {
        throw const FormatException('Editor replay intent mismatch.');
      }
      await context.gateway.deleteTransaction(operationId);
      await _auditReplay(context, receipt);
      return replay;
    }
    final before = await _read(context, mapId);
    if (before.revision != expectedRevision) {
      throw const FormatException(
          'map.elements_revision_conflict: Map changed before this edit.');
    }
    if (rejectNoChanges ||
        const DeepCollectionEquality().equals(before._json, mapJson)) {
      throw const FormatException(
          'map.elements_no_changes: Elements already have this order.');
    }
    final beforeBytes = await context.gateway.readResource(context.storageKey);
    final beforeRevision = beforeBytes == null
        ? _absentRevision(mapId)
        : computeAuthoringBytesFingerprint(beforeBytes,
            logicalName: context.storageKey);
    if (beforeRevision != expectedRevision) {
      throw const FormatException(
          'map.elements_revision_conflict: Map changed during preparation.');
    }
    final afterRevision = computeAuthoringBytesFingerprint(afterBytes,
        logicalName: context.storageKey);
    if (afterRevision == beforeRevision) {
      throw const FormatException(
          'map.elements_no_changes: Map already has this order.');
    }
    final resource = AuthoringResourceRef(kind: 'map', id: mapId);
    final diff = AuthoringDiff([
      AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resource,
          path: '/elementOrder',
          before: before._json,
          after: mapJson,
          extensions: {
            'documentBeforeRevision': beforeRevision,
            'documentAfterRevision': afterRevision,
            'documentBeforePresent': beforeBytes != null,
            'documentAfterPresent': true,
            'mapFileRevision': narrativeEventBytesFingerprint(afterBytes)
          })
    ]);
    final plans = AuthoringPlanStore();
    final plan = AuthoringPlan(
        planId: _identity('plan_document_'),
        receiptId: _identity('receipt_document_'),
        request: request,
        baseRevision: expectedRevision,
        seed: 0,
        createdAt: plans.now,
        expiresAt: plans.now.add(plans.ttl),
        changeSet: AuthoringChangeSet(changes: [
          AuthoringResourceChange(
              resource: resource,
              storageKey: context.storageKey,
              beforeBytes: beforeBytes,
              afterBytes: afterBytes)
        ], diff: diff));
    plans.save(plan);
    final transaction = JournaledAuthoringTransaction(
        plans: plans,
        gateway: context.gateway,
        idempotency: ledger,
        clock: DateTime.now,
        commitHook: recorder,
        faultInjector: _faultInjector);
    final executor = SecureAuthoringMutationExecutor(
        transaction: transaction,
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
            for (final journal in await context.gateway.listJournals()) {
              if (journal.operationId != operationId &&
                  journal.status != AuthoringTransactionStatus.committed &&
                  journal.status != AuthoringTransactionStatus.compensated) {
                throw const FormatException(
                    'map.elements_recovery_required: Recover the pending map editor operation.');
              }
            }
          });
      return MapElementOrderMutation.fromReceipt(receipt);
    } finally {
      await plan.releaseAppliedPayload();
    }
  }

  Future<MapElementOrderMutation> undo(
          {required String projectRoot,
          required String mapId,
          String? mapRelativePath,
          required MapElementOrderMutation mutation,
          required String operationId}) =>
      undoReceipt(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          receiptId: mutation.receipt.receiptId,
          expectedRevision: mutation.afterRevision,
          operationId: operationId);

  Future<MapElementOrderMutation> undoReceipt(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String receiptId,
      required String expectedRevision,
      required String operationId}) async {
    if (runInWorker) {
      return await _runWorker(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          command: 'undo',
          expectedRevision: expectedRevision,
          receiptId: receiptId,
          operationId: operationId) as MapElementOrderMutation;
    }
    final context = await _context(projectRoot, mapId, mapRelativePath);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: context.root, incrementalWrites: true);
    final entry = await history.getDocumentEntry(
        projectId: context.projectId, entryId: receiptId);
    if (entry == null ||
        entry.actorId != _actor.actorId ||
        entry.receipt.actionId != descriptor.id ||
        entry.receipt.diff.entries.length != 1 ||
        entry.receipt.diff.entries.single.resource.id != mapId ||
        entry.nonUndoableReason != null) {
      throw const FormatException('The editor receipt cannot be undone.');
    }
    final mutation = MapElementOrderMutation.fromReceipt(entry.receipt);
    if (expectedRevision != mutation.afterRevision) {
      throw const FormatException(
          'map.elements_revision_conflict: Undo must target the current editor revision.');
    }
    return _set(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        mapJson: Map<String, dynamic>.from(
            entry.receipt.diff.entries.single.before! as Map),
        operationId: operationId,
        historyContext: AuthoringHistoryContext(
            kind: AuthoringHistoryKind.undo, targetEntryId: receiptId));
  }

  Future<Object> _runWorker(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String command,
      String? expectedRevision,
      String? kind,
      List<String>? frontFirstIds,
      String? layerId,
      String? receiptId,
      String? operationId}) async {
    if (_reader is! LocalProjectFileReader || _faultInjector != null) {
      throw ArgumentError(
          'Worker operations require the default local reader and no fault injection.');
    }
    final context = await _context(projectRoot, mapId, mapRelativePath);
    final request = _MapOrderWorkerRequest(
        root: context.root,
        mapId: mapId,
        mapRelativePath: context.mapPath,
        command: command,
        expectedRevision: expectedRevision,
        kind: kind,
        frontFirstIds: frontFirstIds,
        layerId: layerId,
        receiptId: receiptId,
        operationId: operationId,
        actorId: _actor.actorId,
        permissions: _actor.permissions,
        diagnosticsPort: diagnosticsPort);
    if (command == 'inspect') {
      return Isolate.run(() => _runMapOrderWorker(request));
    }
    return withLocalMapDocumentWriteQueue(
        p.join(context.root, context.mapPath),
        (_) => withLocalProjectWriteQueue(context.root,
            () => Isolate.run(() => _runMapOrderWorker(request))));
  }

  Future<_ElementOrderContext> _context(
      String projectRoot, String mapId, String? mapRelativePath) async {
    if (!_actor.allows(AuthoringPermissionScope.projectRead)) {
      throw const FormatException('project.read permission is required.');
    }
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$').hasMatch(mapId) ||
        mapId.contains('..')) {
      throw const FormatException('Invalid map order map identity.');
    }
    final storageKey = mapRelativePath ?? 'maps/$mapId.json';
    final root = await _policy.authorizeProjectRoot(projectRoot);
    final mapPath = mapRelativePath ?? 'maps/$mapId.json';
    final segments = validateProjectRelativePath(mapPath);
    if (segments.join('/') != mapPath ||
        segments.first == '.pokemap' ||
        !mapPath.endsWith('.json')) {
      throw const FormatException('Invalid editor map path.');
    }
    final context = _ElementOrderContext(
        root,
        storageKey,
        mapPath,
        'local_project_${computeAuthoringJsonFingerprint(root, logicalName: 'local-project-root.json').substring(7)}',
        await LocalTransactionFileGateway.open(
            projectRoot: root,
            expectedProjectRoot: root,
            transactionNamespace:
                'element_order_${computeAuthoringJsonFingerprint(mapId, logicalName: 'element-order-map.json').substring(7)}'));
    await _verifyMap(context);
    return context;
  }

  Future<void> _verifyMap(_ElementOrderContext context) async {
    final reader = _reader;
    if (reader is! ProjectResourceProbeReader) {
      throw const FormatException(
          'Editor authoring requires a metadata-only resource probe.');
    }
    final probe = await (reader as ProjectResourceProbeReader).probeResource(
        projectRoot: context.root, relativePath: context.mapPath);
    if (probe.status != ProjectResourceProbeStatus.exists) {
      throw const FormatException('The editor map is missing or unsafe.');
    }
  }

  Future<MapElementOrderSnapshot> _read(
      _ElementOrderContext context, String mapId) async {
    final reader = _reader;
    if (reader is! ProjectResourceProbeReader) {
      throw const FormatException(
          'Editor authoring requires a metadata-only resource probe.');
    }
    final probe = await (reader as ProjectResourceProbeReader).probeResource(
        projectRoot: context.root, relativePath: context.storageKey);
    if (probe.status != ProjectResourceProbeStatus.exists ||
        probe.identity!.byteLength > _maximumMapBytes) {
      throw const FormatException(
          'The editor document is unsafe or oversized.');
    }
    final bytes = await context.gateway.readResource(context.storageKey);
    if (bytes == null || bytes.length > _maximumMapBytes) {
      throw const FormatException(
          'The editor document changed during reading.');
    }
    final raw = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Invalid editor document.');
    }
    final map = MapData.fromJson(raw);
    if (map.id != mapId) {
      throw const FormatException('Map order identity mismatch.');
    }
    return MapElementOrderSnapshot(
        revision: computeAuthoringBytesFingerprint(bytes,
            logicalName: context.storageKey),
        fileRevision: narrativeEventBytesFingerprint(bytes),
        map: map,
        json: raw);
  }

  Future<void> _auditReplay(
      _ElementOrderContext context, AuthoringReceipt receipt) async {
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

final class _ElementOrderContext {
  const _ElementOrderContext(
      this.root, this.storageKey, this.mapPath, this.projectId, this.gateway);
  final String root, storageKey, mapPath, projectId;
  final LocalTransactionFileGateway gateway;
}

String _identity(String prefix) =>
    '$prefix${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

String _absentRevision(String mapId) =>
    computeAuthoringJsonFingerprint({'mapId': mapId, 'present': false},
        logicalName: 'map-editor-absence.json');

const _maximumMapBytes = 64 * 1024 * 1024;
void _requirePermutation(List<String> requested, List<String> existing) {
  if (requested.length != existing.length ||
      requested.toSet().length != requested.length ||
      existing.toSet().length != existing.length ||
      !requested.toSet().containsAll(existing)) {
    throw const FormatException(
        'Order must be an exact permutation of existing element IDs.');
  }
}

final class _MapOrderWorkerRequest {
  const _MapOrderWorkerRequest(
      {required this.root,
      required this.mapId,
      required this.mapRelativePath,
      required this.command,
      required this.expectedRevision,
      required this.kind,
      required this.frontFirstIds,
      required this.layerId,
      required this.receiptId,
      required this.operationId,
      required this.actorId,
      required this.permissions,
      this.diagnosticsPort});
  final String root, mapId, mapRelativePath, command, actorId;
  final String? expectedRevision, kind, layerId, receiptId, operationId;
  final List<String>? frontFirstIds;
  final List<AuthoringPermissionScope> permissions;
  final SendPort? diagnosticsPort;
}

Future<Object> _runMapOrderWorker(_MapOrderWorkerRequest request) async {
  final port = request.diagnosticsPort;
  if (port != null) {
    final trace = MapAuthoringWorkerTrace(request.root);
    try {
      return await trace.run(() => _runMapOrderWorkerDirect(request));
    } finally {
      port.send(trace.snapshot());
    }
  }
  return _runMapOrderWorkerDirect(request);
}

Future<Object> _runMapOrderWorkerDirect(_MapOrderWorkerRequest request) async {
  const reader = LocalProjectFileReader();
  if (await reader.canonicalizeDirectory(request.root) != request.root) {
    throw const FormatException(
        'The authorized map project root changed before worker execution.');
  }
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [request.root], fileReader: reader);
  final service = LocalMapElementOrderAuthoring(
      policy: policy,
      actor: AuthoringActor(
          actorId: request.actorId, permissions: request.permissions));
  if (request.command == 'inspect') {
    return service.inspect(
        projectRoot: request.root,
        mapId: request.mapId,
        mapRelativePath: request.mapRelativePath);
  }
  if (request.command == 'undo') {
    return service.undoReceipt(
        projectRoot: request.root,
        mapId: request.mapId,
        mapRelativePath: request.mapRelativePath,
        expectedRevision: request.expectedRevision!,
        receiptId: request.receiptId!,
        operationId: request.operationId!);
  }
  return service.reorder(
      projectRoot: request.root,
      mapId: request.mapId,
      mapRelativePath: request.mapRelativePath,
      expectedRevision: request.expectedRevision!,
      kind: request.kind!,
      frontFirstIds: request.frontFirstIds!,
      layerId: request.layerId,
      operationId: request.operationId!);
}
