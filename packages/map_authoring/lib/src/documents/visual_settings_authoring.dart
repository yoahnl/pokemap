import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:isolate';
import '../support/map_authoring_worker_trace.dart';
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

final class VisualSettingsSnapshot {
  const VisualSettingsSnapshot(
      {required this.revision, required this.settings});
  final String revision;
  final SpatialVisualPatch settings;
  Map<String, Object?> toJson() =>
      {'revision': revision, 'settings': settings.toJson()};
}

final class VisualSettingsMutation {
  const VisualSettingsMutation(
      {required this.beforeRevision,
      required this.afterRevision,
      required this.beforeSettings,
      required this.afterSettings,
      required this.receipt});
  final String beforeRevision, afterRevision;
  final SpatialVisualPatch beforeSettings, afterSettings;
  final AuthoringReceipt receipt;
  factory VisualSettingsMutation.fromReceipt(AuthoringReceipt receipt) {
    final diff = receipt.diff.entries.single;
    return VisualSettingsMutation(
        beforeRevision: diff.extensions['documentBeforeRevision']! as String,
        afterRevision: diff.extensions['documentAfterRevision']! as String,
        beforeSettings: SpatialVisualPatch.fromJson(
            Map<String, dynamic>.from(diff.before! as Map)),
        afterSettings: SpatialVisualPatch.fromJson(
            Map<String, dynamic>.from(diff.after! as Map)),
        receipt: receipt);
  }
  Map<String, Object?> toJson() => {
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'beforeSettings': beforeSettings.toJson(),
        'afterSettings': afterSettings.toJson(),
        'receipt': receipt.toJson()
      };
}

final class LocalVisualSettingsAuthoring {
  static const projectScopeId = _projectVisualScope;
  LocalVisualSettingsAuthoring(
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
      id: 'visual.settings.set',
      version: 1,
      summary: 'Save the bounded atmosphere document for one map',
      inputSchemaId: 'pokemap.authoring.visual.settings.set.input.v1',
      outputSchemaId: 'pokemap.authoring.visual.settings.set.output.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const [
        'visualSettings'
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
      extensions: {
        'documentSchemaVersions': [1, 2, 3, 4, 5, 6, 7],
        'effects': [
          'waterAnimated',
          'windowsLit',
          'fireflies',
          'halosEnabled',
          'depthFogEnabled',
          'depthOfFieldEnabled'
        ],
        'depthOfFieldStrength': {'minimum': 0, 'maximum': 1},
        'depthOfFieldFocusRange': {
          'minimum': 2,
          'maximum': 40,
          'unit': 'worldCells',
          'meaning': 'fullSharpZoneDepthExtent'
        },
        'haloBindings': 'instanceLocalPosition',
        'settingsFields': [
          for (final field in SpatialVisualParameter.values) field.name
        ],
        'revisionScope': 'visualSettingsDocument',
        'storagePattern': ['project.visual.json', 'maps/<mapId>.visual.json'],
        'maximumDocumentBytes': SpatialVisualDocument.maxBytes,
        'loadsProject': false,
        'extendedWeatherCapability': SpatialWeatherCapabilities.extendedCapabilityId,
        'capability': SpatialVisualDocument.capabilityId,
        'extendedLightingCapability':
            SpatialLightWorkshopCapabilities.capabilityId,
        'weatherCapability': SpatialWeatherCapabilities.capabilityId,
        'weatherSoundCapability': SpatialWeatherCapabilities.soundCapabilityId,
        'worldEnvironmentCapability': WorldEnvironmentCapabilities.capabilityId,
        'weatherEpisodesCapability': WorldEnvironmentCapabilities.weatherEpisodesCapabilityId,
        'weatherModes': [for (final mode in WorldWeatherMode.values) mode.name],
        'realWeatherCapability': WorldEnvironmentCapabilities.realWeatherCapabilityId,
        'weatherKinds': [for (final kind in SpatialWeatherKind.values) kind.name],
        'parameterTypes': {
          for (final parameter in SpatialVisualParameter.values)
            parameter.name: parameter.isSequence ? {'type': 'array', 'items': {'type': 'string', 'enum': [for (final kind in SpatialWeatherKind.values) kind.name]}, 'minItems': 1, 'maxItems': 20, 'uniqueItems': true} : parameter.isChoice
                ? {'type': 'string', 'enum': parameter.choices}
                : parameter.isBoolean
                ? {'type': 'boolean'}
                : {'type': 'number', 'minimum': parameter.minimum, 'maximum': parameter.maximum},
        },
        'fireflyPalette': 'normalizedWithinDensityBudget',
        'missingDocument': 'inheritExistingBehavior',
        'olderHost': 'requiresVisualProfileCapability'
      });
  Future<VisualSettingsSnapshot> inspect(
          {required String projectRoot,
          String mapId = _projectVisualScope,
          String? mapRelativePath}) async =>
      _read(await _context(projectRoot, mapId, mapRelativePath), mapId);
  Future<VisualSettingsMutation> set(
      {required String projectRoot,
      String mapId = _projectVisualScope,
      String? mapRelativePath,
      required String expectedRevision,
      required SpatialVisualPatch settings,
      required String operationId,
      FutureOr<void> Function()? precondition}) {
    if (runInWorker) {
      if (precondition != null) {
        throw ArgumentError('Worker edits require local data preconditions.');
      }
      return _runWorker(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          expectedRevision: expectedRevision,
          settings: settings,
          operationId: operationId);
    }
    return _set(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        settings: settings,
        operationId: operationId,
        precondition: precondition);
  }

  Future<VisualSettingsMutation> _runWorker(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String expectedRevision,
      SpatialVisualPatch? settings,
      String? receiptId,
      required String operationId}) async {
    if (_reader is! LocalProjectFileReader || _faultInjector != null) {
      throw ArgumentError(
          'Worker edits require the local reader without fault injection.');
    }
    final root = await _policy.authorizeProjectRoot(projectRoot);
    final request = (
      root: root,
      mapId: mapId,
      mapRelativePath: mapRelativePath,
      expectedRevision: expectedRevision,
      settings: settings?.toJson(),
      receiptId: receiptId,
      operationId: operationId,
      actorId: _actor.actorId,
      permissions: _actor.permissions,
      diagnosticsPort: diagnosticsPort
    );
    return withLocalProjectWriteQueue(
        root, () => Isolate.run(() => _runVisualSettingsWorker(request)));
  }

  Future<VisualSettingsMutation> _set(
      {required String projectRoot,
      String mapId = _projectVisualScope,
      String? mapRelativePath,
      required String expectedRevision,
      required SpatialVisualPatch settings,
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
        : utf8.encode(jsonEncode(
            SpatialVisualDocument(mapId: _visualMapId(mapId), profile: settings)
                .toJson()));
    if ((afterBytes?.length ?? 0) > SpatialVisualDocument.maxBytes) {
      throw const FormatException(
          'Atmosphere document exceeds its byte limit.');
    }
    final request = AuthoringRequest(
        requestId: operationId,
        actionId: descriptor.id,
        actionVersion: 1,
        workspaceHandle: context.projectId,
        parameters: {
          'scope': mapId == _projectVisualScope ? 'project' : 'map',
          if (mapId != _projectVisualScope) 'mapId': mapId,
          'mapRelativePath': context.mapPath,
          'settings': settings.toJson(),
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
            message: 'This operation owns a different atmosphere intent.');
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
        throw const FormatException('Invalid atmosphere replay receipt.');
      }
      final replay = VisualSettingsMutation.fromReceipt(receipt);
      if (replay.beforeRevision != expectedRevision ||
          replay.afterSettings != settings ||
          receipt.diff.entries.single.resource.id != context.storageKey) {
        throw const FormatException('Atmosphere replay intent mismatch.');
      }
      await context.gateway.deleteTransaction(operationId);
      await _auditReplay(context, receipt);
      return replay;
    }
    final before = await _read(context, mapId);
    if (before.revision != expectedRevision) {
      throw const FormatException(
          'visual.settings_revision_conflict: Atmosphere changed before this edit.');
    }
    final beforeBytes = await context.gateway.readResource(context.storageKey);
    final beforeRevision = beforeBytes == null
        ? _absentRevision(mapId)
        : computeAuthoringBytesFingerprint(beforeBytes,
            logicalName: context.storageKey);
    if (beforeRevision != expectedRevision) {
      throw const FormatException(
          'visual.settings_revision_conflict: Atmosphere changed during preparation.');
    }
    final afterRevision = afterBytes == null
        ? _absentRevision(mapId)
        : computeAuthoringBytesFingerprint(afterBytes,
            logicalName: context.storageKey);
    if (afterRevision == beforeRevision) {
      throw const FormatException(
          'visual.settings_no_changes: Atmosphere already has these settings.');
    }
    final resource =
        AuthoringResourceRef(kind: 'visualSettings', id: context.storageKey);
    final diff = AuthoringDiff([
      AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resource,
          path: '/visualSettings',
          before: before.settings.toJson(),
          after: settings.toJson(),
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
                    'visual.settings_recovery_required: Recover the pending map atmosphere operation.');
              }
            }
          });
      return VisualSettingsMutation.fromReceipt(receipt);
    } finally {
      await plan.releaseAppliedPayload();
    }
  }

  Future<VisualSettingsMutation> undo(
          {required String projectRoot,
          String mapId = _projectVisualScope,
          String? mapRelativePath,
          required VisualSettingsMutation mutation,
          required String operationId}) =>
      undoReceipt(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          receiptId: mutation.receipt.receiptId,
          expectedRevision: mutation.afterRevision,
          operationId: operationId);

  Future<VisualSettingsMutation> undoReceipt(
      {required String projectRoot,
      String mapId = _projectVisualScope,
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
          operationId: operationId);
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
        entry.receipt.diff.entries.single.resource.id != context.storageKey ||
        entry.nonUndoableReason != null) {
      throw const FormatException('The atmosphere receipt cannot be undone.');
    }
    final mutation = VisualSettingsMutation.fromReceipt(entry.receipt);
    if (expectedRevision != mutation.afterRevision) {
      throw const FormatException(
          'visual.settings_revision_conflict: Undo must target the current atmosphere revision.');
    }
    return _set(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        settings: mutation.beforeSettings,
        removeDocument: entry.receipt.diff.entries.single
                .extensions['documentBeforePresent'] ==
            false,
        operationId: operationId,
        historyContext: AuthoringHistoryContext(
            kind: AuthoringHistoryKind.undo, targetEntryId: receiptId));
  }

  Future<_VisualSettingsContext> _context(
      String projectRoot, String mapId, String? mapRelativePath) async {
    if (!_actor.allows(AuthoringPermissionScope.projectRead)) {
      throw const FormatException('project.read permission is required.');
    }
    final storageKey = _visualStorageKey(mapId);
    final root = await _policy.authorizeProjectRoot(projectRoot);
    final mapPath = mapRelativePath ??
        (_visualMapId(mapId) == null ? 'project.json' : 'maps/$mapId.json');
    final segments = validateProjectRelativePath(mapPath);
    if (segments.join('/') != mapPath ||
        segments.first == '.pokemap' ||
        mapPath == storageKey ||
        !mapPath.endsWith('.json')) {
      throw const FormatException('Invalid atmosphere map path.');
    }
    final context = _VisualSettingsContext(
        root,
        storageKey,
        mapPath,
        'local_project_${computeAuthoringJsonFingerprint(root, logicalName: 'local-project-root.json').substring(7)}',
        await LocalTransactionFileGateway.open(
            projectRoot: root,
            expectedProjectRoot: root,
            transactionNamespace:
                'visual_${computeAuthoringJsonFingerprint(storageKey, logicalName: 'visual-scope.json').substring(7)}'));
    await _verifyMap(context);
    return context;
  }

  Future<void> _verifyMap(_VisualSettingsContext context) async {
    final reader = _reader;
    if (reader is! ProjectResourceProbeReader) {
      throw const FormatException(
          'Atmosphere authoring requires a metadata-only resource probe.');
    }
    final probe = await (reader as ProjectResourceProbeReader).probeResource(
        projectRoot: context.root, relativePath: context.mapPath);
    if (probe.status != ProjectResourceProbeStatus.exists) {
      throw const FormatException('The atmosphere map is missing or unsafe.');
    }
  }

  Future<VisualSettingsSnapshot> _read(
      _VisualSettingsContext context, String mapId) async {
    final reader = _reader;
    if (reader is! ProjectResourceProbeReader) {
      throw const FormatException(
          'Atmosphere authoring requires a metadata-only resource probe.');
    }
    final probe = await (reader as ProjectResourceProbeReader).probeResource(
        projectRoot: context.root, relativePath: context.storageKey);
    if (probe.status == ProjectResourceProbeStatus.missing) {
      return VisualSettingsSnapshot(
          revision: _absentRevision(mapId), settings: SpatialVisualPatch());
    }
    if (probe.status != ProjectResourceProbeStatus.exists ||
        probe.identity!.byteLength > SpatialVisualDocument.maxBytes) {
      throw const FormatException(
          'The atmosphere document is unsafe or oversized.');
    }
    final bytes = await context.gateway.readResource(context.storageKey);
    if (bytes == null || bytes.length > SpatialVisualDocument.maxBytes) {
      throw const FormatException(
          'The atmosphere document changed during reading.');
    }
    final raw = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Invalid atmosphere document.');
    }
    final document = SpatialVisualDocument.fromJson(raw);
    if (document.mapId != _visualMapId(mapId)) {
      throw const FormatException('Atmosphere map identity mismatch.');
    }
    return VisualSettingsSnapshot(
        revision: computeAuthoringBytesFingerprint(bytes,
            logicalName: context.storageKey),
        settings: document.profile);
  }

  Future<void> _auditReplay(
      _VisualSettingsContext context, AuthoringReceipt receipt) async {
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

final class _VisualSettingsContext {
  const _VisualSettingsContext(
      this.root, this.storageKey, this.mapPath, this.projectId, this.gateway);
  final String root, storageKey, mapPath, projectId;
  final LocalTransactionFileGateway gateway;
}

String _identity(String prefix) =>
    '$prefix${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

String _absentRevision(String mapId) => computeAuthoringJsonFingerprint({
      'scope': mapId == _projectVisualScope ? 'project' : 'map',
      if (mapId != _projectVisualScope) 'mapId': mapId,
      'present': false
    }, logicalName: 'map-atmosphere-absence.json');

const _projectVisualScope = '\u0001project';
String? _visualMapId(String scope) =>
    scope == _projectVisualScope ? null : scope;
String _visualStorageKey(String scope) => scope == _projectVisualScope
    ? SpatialVisualDocument.projectRelativePath
    : SpatialVisualDocument.relativePathForMap(scope);

typedef _VisualSettingsWorkerRequest = ({
  String root,
  String mapId,
  String? mapRelativePath,
  String expectedRevision,
  Map<String, dynamic>? settings,
  String? receiptId,
  String operationId,
  String actorId,
  List<AuthoringPermissionScope> permissions,
  SendPort? diagnosticsPort
});

Future<VisualSettingsMutation> _runVisualSettingsWorker(
    _VisualSettingsWorkerRequest request) async {
  final port = request.diagnosticsPort;
  if (port == null) return _runVisualSettingsWorkerDirect(request);
  final trace = MapAuthoringWorkerTrace(request.root);
  try {
    return await trace.run(() => _runVisualSettingsWorkerDirect(request));
  } finally {
    port.send(trace.snapshot());
  }
}

Future<VisualSettingsMutation> _runVisualSettingsWorkerDirect(
    _VisualSettingsWorkerRequest request) async {
  const reader = LocalProjectFileReader();
  if (await reader.canonicalizeDirectory(request.root) != request.root) {
    throw const FormatException('The authorized visual settings root changed.');
  }
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [request.root], fileReader: reader);
  final service = LocalVisualSettingsAuthoring(
      policy: policy,
      actor: AuthoringActor(
          actorId: request.actorId, permissions: request.permissions));
  if (request.receiptId case final receiptId?) {
    return service.undoReceipt(
        projectRoot: request.root,
        mapId: request.mapId,
        mapRelativePath: request.mapRelativePath,
        receiptId: receiptId,
        expectedRevision: request.expectedRevision,
        operationId: request.operationId);
  }
  return service.set(
      projectRoot: request.root,
      mapId: request.mapId,
      mapRelativePath: request.mapRelativePath,
      expectedRevision: request.expectedRevision,
      settings: SpatialVisualPatch.fromJson(request.settings!),
      operationId: request.operationId);
}
