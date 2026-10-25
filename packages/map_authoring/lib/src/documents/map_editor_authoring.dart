import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
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

final class MapEditorSnapshot {
  const MapEditorSnapshot({required this.revision, required this.state});
  final String revision;
  final MapEditorState state;
  Map<String, Object?> toJson() =>
      {'revision': revision, 'state': state.toJson()};
}

final class MapEditorMutation {
  const MapEditorMutation(
      {required this.beforeRevision,
      required this.afterRevision,
      required this.beforeState,
      required this.afterState,
      required this.receipt});
  final String beforeRevision, afterRevision;
  final MapEditorState beforeState, afterState;
  final AuthoringReceipt receipt;
  factory MapEditorMutation.fromReceipt(AuthoringReceipt receipt) {
    final diff = receipt.diff.entries.single;
    return MapEditorMutation(
        beforeRevision: diff.extensions['documentBeforeRevision']! as String,
        afterRevision: diff.extensions['documentAfterRevision']! as String,
        beforeState: MapEditorState.fromJson(
            Map<String, dynamic>.from(diff.before! as Map)),
        afterState: MapEditorState.fromJson(
            Map<String, dynamic>.from(diff.after! as Map)),
        receipt: receipt);
  }
  Map<String, Object?> toJson() => {
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'beforeState': beforeState.toJson(),
        'afterState': afterState.toJson(),
        'receipt': receipt.toJson()
      };
}

final class LocalMapEditorAuthoring {
  LocalMapEditorAuthoring(
      {required WorkspacePolicy policy,
      ProjectFileReader? reader,
      AuthoringActor? actor,
      this.runInWorker = false,
      this.diagnosticsPort,
      AuthoringTransactionFaultInjector? faultInjector})
      : _policy = policy,
        _reader = reader ?? const LocalProjectFileReader(),
        _actor = actor ??
            AuthoringActor(actorId: 'local_cli', permissions: const [
              AuthoringPermissionScope.projectRead,
              AuthoringPermissionScope.projectWrite,
              AuthoringPermissionScope.recoveryApply
            ]),
        _faultInjector = faultInjector;
  final WorkspacePolicy _policy;
  final ProjectFileReader _reader;
  final AuthoringActor _actor;
  final AuthoringTransactionFaultInjector? _faultInjector;
  final bool runInWorker;
  final SendPort? diagnosticsPort;
  static final descriptor = AuthoringActionDescriptor(
      id: 'map.editor.set',
      version: 1,
      summary: 'Save selection and movement locks for one map',
      inputSchemaId: 'pokemap.authoring.map.editor.set.input.v1',
      outputSchemaId: 'pokemap.authoring.map.editor.set.output.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const [
        'mapEditor'
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
        'documentSchemaVersions': [1],
        'stateFields': ['lockedElements', 'lockedFamilies'],
        'revisionScope': 'mapEditorDocument',
        'storagePattern': 'maps/<mapId>.editor.json',
        'maximumDocumentBytes': MapEditorDocument.maxBytes,
        'loadsProject': false,
        'editorOnly': true,
        'missingDocument': 'allElementsUnlocked'
      });
  Future<MapEditorSnapshot> inspect(
          {required String projectRoot,
          required String mapId,
          String? mapRelativePath}) async =>
      _read(await _context(projectRoot, mapId, mapRelativePath), mapId);
  Future<MapEditorMutation> set(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String expectedRevision,
      required MapEditorState state,
      required String operationId,
      FutureOr<void> Function()? precondition}) {
    if (runInWorker) {
      if (precondition != null) {
        throw ArgumentError(
            'Worker mutations require a local data precondition.');
      }
      return _runWorker(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        state: state,
        operationId: operationId,
      );
    }
    return _set(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        state: state,
        operationId: operationId,
        precondition: precondition);
  }

  Future<MapEditorMutation> _runWorker({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String expectedRevision,
    MapEditorState? state,
    String? receiptId,
    required String operationId,
  }) async {
    if (_reader is! LocalProjectFileReader || _faultInjector != null) {
      throw ArgumentError(
          'Worker mutations require the default local reader and no fault injection.');
    }
    final root = await _policy.authorizeProjectRoot(projectRoot);
    final request = _MapEditorWorkerRequest(
      root: root,
      mapId: mapId,
      mapRelativePath: mapRelativePath,
      expectedRevision: expectedRevision,
      state: state?.toJson(),
      receiptId: receiptId,
      operationId: operationId,
      actorId: _actor.actorId,
      permissions: _actor.permissions,
      diagnosticsPort: diagnosticsPort,
    );
    return withLocalProjectWriteQueue(
        root, () => Isolate.run(() => _runMapEditorWorker(request)));
  }

  Future<MapEditorMutation> _set(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String expectedRevision,
      required MapEditorState state,
      required String operationId,
      FutureOr<void> Function()? precondition,
      AuthoringHistoryContext? historyContext,
      bool removeDocument = false}) async {
    final context = await _context(projectRoot, mapId, mapRelativePath);
    if (!_actor.allows(AuthoringPermissionScope.projectWrite)) {
      throw const FormatException('project.write permission is required.');
    }
    safeAuthoringSecurityIdentifier(operationId, 'operationId');
    final afterBytes = removeDocument
        ? null
        : utf8.encode(
            jsonEncode(MapEditorDocument(mapId: mapId, state: state).toJson()));
    if ((afterBytes?.length ?? 0) > MapEditorDocument.maxBytes) {
      throw const FormatException('Editor document exceeds its byte limit.');
    }
    final request = AuthoringRequest(
        requestId: operationId,
        actionId: descriptor.id,
        actionVersion: 1,
        workspaceHandle: context.projectId,
        parameters: {
          'mapId': mapId,
          'mapRelativePath': context.mapPath,
          'state': state.toJson(),
          'documentPresent': !removeDocument
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
      final replay = MapEditorMutation.fromReceipt(receipt);
      if (replay.beforeRevision != expectedRevision ||
          replay.afterState != state ||
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
          'map.editor_revision_conflict: Editor changed before this edit.');
    }
    final beforeBytes = await context.gateway.readResource(context.storageKey);
    final beforeRevision = beforeBytes == null
        ? _absentRevision(mapId)
        : computeAuthoringBytesFingerprint(beforeBytes,
            logicalName: context.storageKey);
    if (beforeRevision != expectedRevision) {
      throw const FormatException(
          'map.editor_revision_conflict: Editor changed during preparation.');
    }
    final afterRevision = afterBytes == null
        ? _absentRevision(mapId)
        : computeAuthoringBytesFingerprint(afterBytes,
            logicalName: context.storageKey);
    if (afterRevision == beforeRevision) {
      throw const FormatException(
          'map.editor_no_changes: Editor already has these state.');
    }
    final resource = AuthoringResourceRef(kind: 'mapEditor', id: mapId);
    final diff = AuthoringDiff([
      AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resource,
          path: '/editor',
          before: before.state.toJson(),
          after: state.toJson(),
          extensions: {
            'documentBeforeRevision': beforeRevision,
            'documentAfterRevision': afterRevision,
            'documentBeforePresent': beforeBytes != null,
            'documentAfterPresent': afterBytes != null
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
                    'map.editor_recovery_required: Recover the pending map editor operation.');
              }
            }
          });
      return MapEditorMutation.fromReceipt(receipt);
    } finally {
      await plan.releaseAppliedPayload();
    }
  }

  Future<MapEditorMutation> undo(
          {required String projectRoot,
          required String mapId,
          String? mapRelativePath,
          required MapEditorMutation mutation,
          required String operationId}) =>
      undoReceipt(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          receiptId: mutation.receipt.receiptId,
          expectedRevision: mutation.afterRevision,
          operationId: operationId);

  Future<MapEditorMutation> undoReceipt(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String receiptId,
      required String expectedRevision,
      required String operationId}) async {
    if (runInWorker) {
      return _runWorker(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        receiptId: receiptId,
        operationId: operationId,
      );
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
    final mutation = MapEditorMutation.fromReceipt(entry.receipt);
    if (expectedRevision != mutation.afterRevision) {
      throw const FormatException(
          'map.editor_revision_conflict: Undo must target the current editor revision.');
    }
    return _set(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        state: mutation.beforeState,
        removeDocument: entry.receipt.diff.entries.single
                .extensions['documentBeforePresent'] ==
            false,
        operationId: operationId,
        historyContext: AuthoringHistoryContext(
            kind: AuthoringHistoryKind.undo, targetEntryId: receiptId));
  }

  Future<_EditorContext> _context(
      String projectRoot, String mapId, String? mapRelativePath) async {
    if (!_actor.allows(AuthoringPermissionScope.projectRead)) {
      throw const FormatException('project.read permission is required.');
    }
    final storageKey = MapEditorDocument.relativePathForMap(mapId);
    final root = await _policy.authorizeProjectRoot(projectRoot);
    final mapPath = mapRelativePath ?? 'maps/$mapId.json';
    final segments = validateProjectRelativePath(mapPath);
    if (segments.join('/') != mapPath ||
        segments.first == '.pokemap' ||
        mapPath == storageKey ||
        !mapPath.endsWith('.json')) {
      throw const FormatException('Invalid editor map path.');
    }
    final context = _EditorContext(
        root,
        storageKey,
        mapPath,
        'local_project_${computeAuthoringJsonFingerprint(root, logicalName: 'local-project-root.json').substring(7)}',
        await LocalTransactionFileGateway.open(
            projectRoot: root,
            expectedProjectRoot: root,
            transactionNamespace:
                'editor_${computeAuthoringJsonFingerprint(mapId, logicalName: 'editor-map.json').substring(7)}'));
    await _verifyMap(context);
    return context;
  }

  Future<void> _verifyMap(_EditorContext context) async {
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

  Future<MapEditorSnapshot> _read(_EditorContext context, String mapId) async {
    final reader = _reader;
    if (reader is! ProjectResourceProbeReader) {
      throw const FormatException(
          'Editor authoring requires a metadata-only resource probe.');
    }
    final probe = await (reader as ProjectResourceProbeReader).probeResource(
        projectRoot: context.root, relativePath: context.storageKey);
    if (probe.status == ProjectResourceProbeStatus.missing) {
      return MapEditorSnapshot(
          revision: _absentRevision(mapId), state: MapEditorState());
    }
    if (probe.status != ProjectResourceProbeStatus.exists ||
        probe.identity!.byteLength > MapEditorDocument.maxBytes) {
      throw const FormatException(
          'The editor document is unsafe or oversized.');
    }
    final bytes = await context.gateway.readResource(context.storageKey);
    if (bytes == null || bytes.length > MapEditorDocument.maxBytes) {
      throw const FormatException(
          'The editor document changed during reading.');
    }
    final raw = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Invalid editor document.');
    }
    final document = MapEditorDocument.fromJson(raw);
    if (document.mapId != mapId) {
      throw const FormatException('Editor map identity mismatch.');
    }
    return MapEditorSnapshot(
        revision: computeAuthoringBytesFingerprint(bytes,
            logicalName: context.storageKey),
        state: document.state);
  }

  Future<void> _auditReplay(
      _EditorContext context, AuthoringReceipt receipt) async {
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

final class _EditorContext {
  const _EditorContext(
      this.root, this.storageKey, this.mapPath, this.projectId, this.gateway);
  final String root, storageKey, mapPath, projectId;
  final LocalTransactionFileGateway gateway;
}

String _identity(String prefix) =>
    '$prefix${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

String _absentRevision(String mapId) =>
    computeAuthoringJsonFingerprint({'mapId': mapId, 'present': false},
        logicalName: 'map-editor-absence.json');

final class _MapEditorWorkerRequest {
  const _MapEditorWorkerRequest(
      {required this.root,
      required this.mapId,
      required this.mapRelativePath,
      required this.expectedRevision,
      required this.state,
      required this.receiptId,
      required this.operationId,
      required this.actorId,
      required this.permissions,
      this.diagnosticsPort});
  final String root, mapId, expectedRevision, operationId, actorId;
  final String? mapRelativePath, receiptId;
  final Map<String, dynamic>? state;
  final List<AuthoringPermissionScope> permissions;
  final SendPort? diagnosticsPort;
}

Future<MapEditorMutation> _runMapEditorWorker(
    _MapEditorWorkerRequest request) async {
  final port = request.diagnosticsPort;
  if (port != null) {
    final trace = MapAuthoringWorkerTrace(request.root);
    try {
      return await trace.run(() => _runMapEditorWorkerDirect(request));
    } finally {
      port.send(trace.snapshot());
    }
  }
  return _runMapEditorWorkerDirect(request);
}

Future<MapEditorMutation> _runMapEditorWorkerDirect(
    _MapEditorWorkerRequest request) async {
  const reader = LocalProjectFileReader();
  if (await reader.canonicalizeDirectory(request.root) != request.root) {
    throw const FormatException(
        'The authorized editor project root changed before worker execution.');
  }
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [request.root], fileReader: reader);
  final service = LocalMapEditorAuthoring(
      policy: policy,
      actor: AuthoringActor(
          actorId: request.actorId, permissions: request.permissions));
  final receiptId = request.receiptId;
  if (receiptId != null) {
    return service.undoReceipt(
        projectRoot: request.root,
        mapId: request.mapId,
        mapRelativePath: request.mapRelativePath,
        expectedRevision: request.expectedRevision,
        receiptId: receiptId,
        operationId: request.operationId);
  }
  return service.set(
      projectRoot: request.root,
      mapId: request.mapId,
      mapRelativePath: request.mapRelativePath,
      expectedRevision: request.expectedRevision,
      state: MapEditorState.fromJson(request.state!),
      operationId: request.operationId);
}
