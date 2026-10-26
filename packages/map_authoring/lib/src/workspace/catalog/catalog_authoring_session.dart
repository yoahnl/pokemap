import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../api/authoring_mutation_contracts.dart';
import '../../application/map_mutation_dispatcher.dart';
import '../../contracts/authoring_receipt.dart';
import '../../workspace/project_snapshot.dart';
import 'catalog_working_mutation.dart';
import 'catalog_targeted_map_edit.dart';
import 'catalog_spatial_map_selection.dart';
import 'catalog_workshop_selection.dart';
import 'catalog_scoped_working_mutation.dart';
import '../../catalog_storage/catalog_editing_session.dart';
import '../../catalog_storage/catalog_storage_store.dart';
import '../../catalog_storage/catalog_generation_retention.dart';
import 'catalog_action_contracts.dart';
import '../../contracts/authoring_request.dart';
import '../../contracts/json_contract_support.dart';
import '../../history/history_store.dart';
import '../../history/file_history_store.dart';
import '../../security/authoring_permission.dart';
import '../../security/audit_record.dart';
import '../../security/authorization_policy.dart';
import '../../security/confirmation_token.dart';
import '../../transactions/journaled_transaction.dart';
import '../../transactions/plan_store.dart';
import '../../transactions/authoring_plan.dart';
import '../../api/authoring_result_projection.dart';
import '../../contracts/action_descriptor.dart';
import '../../history/authoring_history.dart';
import '../workspace_handle_store.dart';
import 'catalog_project_reader.dart';

final class CatalogAuthoringSession {
  CatalogAuthoringSession(
      {required this.reader,
      required this.workspaceHandle,
      required this.actor,
      required this.requireActive,
      required this.dispatcher,
      required this.resolveAction,
      required this.inspectHistoryReplay,
      required this.loadProject,
      required this.buildProjectPlan,
      required this.buildScopedProjectPlan,
      required this.projectHandle,
      required this.discardProjectPlan,
      required this.inspectReplay,
      required this.prepareApply,
      required this.requirePlanPreconditions,
      required this.projections,
      required this.auditOutcome,
      required DateTime Function() clock,
      required AuthoringSecurityLimits limits,
      this.faultInjector})
      : _clock = clock,
        _confirmations = AuthoringConfirmationStore(clock: clock) {
    _policy = AuthoringAuthorizationPolicy(
        confirmations: _confirmations, clock: clock, limits: limits);
  }

  final CatalogProjectReader reader;
  final WorkspaceHandle workspaceHandle;
  final AuthoringActor actor;
  final void Function() requireActive;
  final MapMutationDispatcher dispatcher;
  final AuthoringActionDescriptor Function(String actionId) resolveAction;
  final Future<AuthoringReceipt?> Function(
      String operationId, String actionId, String entryId) inspectHistoryReplay;
  final Future<ProjectSnapshot> Function() loadProject;
  final Future<AuthoringMutationPlanResult> Function(AuthoringRequest)
      buildProjectPlan;
  final Future<AuthoringMutationPlanResult> Function(AuthoringRequest, ProjectSnapshot)
      buildScopedProjectPlan;
  final ProjectHandle projectHandle;
  final Future<void> Function(String) discardProjectPlan;
  final Future<AuthoringReceipt?> Function(String planId, String operationId)
      inspectReplay;
  final Future<void> Function(AuthoringPlan plan, String operationId)
      prepareApply;
  final Future<void> Function(AuthoringPlan plan) requirePlanPreconditions;
  final AuthoringResultProjectionStore? projections;
  final Future<void> Function(
      AuthoringPlan plan,
      AuthoringAuditDecision decision,
      AuthoringReceipt? receipt,
      Object? error,
      Map<String, Object?> details) auditOutcome;
  final DateTime Function() _clock;
  final AuthoringConfirmationStore _confirmations;
  final AuthoringTransactionFaultInjector? faultInjector;
  late final AuthoringAuthorizationPolicy _policy;
  Future<CatalogEditingSession>? _editingFuture;
  final Map<String, CatalogEditingPlan> _plans = {};
  final Map<String, String> _operations = {};

  bool _closed = false;

  Future<CatalogEditingSession> _editing() {
    if (_closed) throw StateError('The catalog authoring session is closed.');
    final existing = _editingFuture;
    if (existing != null) return existing;
    late final Future<CatalogEditingSession> opening;
    opening = CatalogEditingSession.open(store: reader.store,
        projectId: reader.projectId, actorId: actor.actorId,
        incrementalHistory: true, clock: _clock, faultInjector: faultInjector)
      .catchError((Object error, StackTrace stack) {
        if (identical(_editingFuture, opening)) _editingFuture = null;
        Error.throwWithStackTrace(error, stack);
      });
    _editingFuture = opening;
    return opening;
  }

  void requirePreparationAuthorization() => _authorize(AuthoringSecurityOperation.plan);

  void requireRead() {
    if (_closed) throw StateError('The catalog authoring session is closed.');
    requireActive();
    if (!actor.allows(AuthoringPermissionScope.projectRead)) {
      throw const AuthoringAuthorizationException(
          code: 'authorization.permission_denied',
          message:
              'Reading catalog operations requires project.read permission.');
    }
  }

  AuthoringAuthorizationDecision _authorize(
      AuthoringSecurityOperation operation,
      {AuthoringRequest? request,
      int touched = 0,
      CatalogEditingPlan? prepared,
      String? operationId,
      String? confirmationToken}) {
    requireRead();
    if (reader.readOnly) {
      throw const AuthoringAuthorizationException(
          code: 'catalog.read_only',
          message: 'Portable catalog publications are read-only.');
    }
    final descriptor = resolveAction(
        request?.actionId ?? catalogDefinitionUpdateDescriptor.id);
    final plan = prepared?.plan;
    final binding = plan == null || plan.appliedPayloadReleased
        ? null
        : AuthoringConfirmationBinding.forPlan(
            actorId: actor.actorId, projectId: reader.projectId, plan: plan);
    return _policy.authorize(AuthoringAuthorizationRequest(
        actor: actor,
        projectId: reader.projectId,
        operation: operation,
        actionId: descriptor.id,
        actionVersion: descriptor.version,
        riskLevel: descriptor.riskLevel,
        requestBytes: request == null
            ? 0
            : utf8.encode(jsonEncode(request.toJson())).length,
        touchedResources: touched,
        additionalPermissions: [
          AuthoringPermissionScope.projectWrite,
          ...descriptor.requiredPermissions.map((permission) =>
              AuthoringPermissionScope.fromWireName(permission.wireName))
        ],
        planId: plan?.planId,
        diffFingerprint: binding?.diffFingerprint,
        operationId: operationId,
        bulkCapability: plan?.bulkCapability,
        destructive: plan != null &&
            !plan.appliedPayloadReleased &&
            plan.changeSet.changes
                .any((change) => change.beforePayload != null),
        confirmationToken: confirmationToken == null
            ? null
            : AuthoringConfirmationToken.fromWireValue(confirmationToken)));
  }

  Future<AuthoringMutationPlanResult> plan(AuthoringRequest request) async {
    _authorize(AuthoringSecurityOperation.plan, request: request);
    if (request.workspaceHandle != workspaceHandle.value) {
      throw const WorkspaceHandleException('workspace.project_mismatch',
          'The request does not belong to this workspace.');
    }
    if (request.actionId == 'map.save') return _planMap(request);
    if (CatalogSpatialMapSelection.supports(request.actionId, parameters: request.parameters)) return _planSpatialMap(request);
    if (request.actionId != catalogDefinitionUpdateDescriptor.id) {
      return request.extensions['workshopScope'] == true || CatalogWorkshopSelection.supports(request.actionId,parameters:request.parameters)
          ? _planWorkshop(request) : _planProject(request);
    }
    if (request.actionVersion != 1) {
      throw AuthoringPlanException(
          code: 'plan.action_version_unsupported',
          message: 'The requested catalog action version is unsupported.');
    }
    if (request.idempotencyKey == null) {
      throw AuthoringPlanException(
          code: 'plan.idempotency_key_required',
          message: 'Mutation planning requires an idempotency key.');
    }
    final args = Map<String, dynamic>.from(request.parameters);
    rejectUnknownContractKeys(args, const {
      'resourceKind',
      'id',
      'name',
      'description',
      'tags',
      'placementContext'
    });
    final resourceKind =
        requireContractString(args['resourceKind'], 'resourceKind');
    final kind = catalogResourceKinds[resourceKind];
    if (kind == null) {
      throw const FormatException(
          'catalog.definition: unsupported resource kind');
    }
    final key =
        CatalogDefinitionKey(kind, requireContractString(args['id'], 'id'));
    if (args.length <= 2) {
      throw const FormatException('catalog.definition: no metadata changes');
    }
    if (args.containsKey('name')) requireContractString(args['name'], 'name');
    if (args.containsKey('description') && args['description'] != null) {
      requireContractString(args['description'], 'description');
    }
    if (args.containsKey('tags')) readContractStringList(args['tags'], 'tags');
    if (args.containsKey('placementContext') &&
        !const {null, 'interior', 'exterior', 'both'}
            .contains(args['placementContext'])) {
      throw const FormatException(
          'catalog.definition: invalid placement context');
    }
    final current = await CatalogProjectReader.open(
        store: reader.store, descriptor: reader.descriptor, metadataFields: {});
    if (current!.revision != request.expectedRevision) {
      throw AuthoringPlanException(
          code: 'plan.stale', message: 'The catalog changed before planning.');
    }
    final updated = await current.read((catalog) async {
      final unit = await catalog.lookup(key);
      if (unit == null) {
        throw AuthoringPlanException(
            code: 'catalog.definition_missing',
            message: 'The requested catalog definition was not found.');
      }
      final changes = <CatalogDefinitionUnit>[];
      final value = Map<String, Object?>.from(unit.payload['value'] as Map);
      final classified =
          ResourceLibraryCatalog.resourceKinds.contains(resourceKind);
      final fields = classified
          ? const ['name', 'tags']
          : const ['name', 'description', 'tags', 'placementContext'];
      if (fields.any(args.containsKey)) {
        for (final field in fields) {
          if (args.containsKey(field)) {
            if (field == 'name' && resourceKind == 'borderBlueprint') {
              final draft = Map<String, Object?>.from(value['draft'] as Map);
              final definition =
                  Map<String, Object?>.from(draft['definition'] as Map);
              definition['name'] = args[field];
              draft['definition'] = definition;
              value['draft'] = draft;
            } else {
              value[field] = args[field];
            }
          }
        }
        changes.add(catalog.replaceDefinitionValue(unit, value));
      }
      if (classified &&
          (args.containsKey('description') ||
              args.containsKey('placementContext'))) {
        final classificationKey = CatalogDefinitionKey(
            CatalogDefinitionKind.resourceLibraryEntry,
            '$resourceKind:${key.id}');
        final classification = await catalog.lookup(classificationKey);
        final metadata = classification == null
            ? <String, Object?>{
                'resourceKind': resourceKind,
                'resourceId': key.id
              }
            : Map<String, Object?>.from(classification.payload['value'] as Map);
        for (final field in ['description', 'placementContext']) {
          if (!args.containsKey(field)) continue;
          if (args[field] == null) {
            metadata.remove(field);
          } else {
            metadata[field] = args[field];
          }
        }
        final entry = ResourceLibraryEntry.fromJson(metadata);
        if (classification != null) {
          changes.add(
              catalog.replaceDefinitionValue(classification, entry.toJson()));
        } else if (entry.description != null ||
            entry.placementContext != null) {
          var position = 0;
          String? cursor;
          do {
            final page = await catalog.snapshot.page(
                kind: CatalogDefinitionKind.resourceLibraryEntry,
                limit: catalog.snapshot.limits.indexPageSize,
                cursor: cursor);
            position += page.items.length;
            cursor = page.nextCursor;
          } while (cursor != null);
          changes.add(catalog.createResourceLibraryEntryUnit(entry,
              position: position));
        }
      }
      return changes;
    });
    final editing = await _editing();
    if ('sha256:${editing.snapshot.root.sha256}' != request.expectedRevision) {
      throw AuthoringPlanException(
          code: 'plan.stale', message: 'The catalog changed before planning.');
    }
    final prepared = await editing.planPatch(
        upserts: updated,
        idempotencyKey: request.idempotencyKey!,
        request: request);
    _plans[prepared.plan.planId] = prepared;
    return AuthoringMutationPlanResult(
        plan: prepared.plan,
        snapshotRevision: request.expectedRevision!,
        receipt: prepared.plan.toPlannedReceipt(),
        publicProjection: await projections?.preparePlan(
            plan: prepared.plan,
            receipt: prepared.plan.toPlannedReceipt(),
            snapshotRevision: request.expectedRevision!));
  }

  Future<ProjectSnapshot> readWorkshopSnapshot({required String actionId,
      Map<String, Object?> parameters = const {},
      Map<String, String> readDependencies = const {}}) async {
    requireRead();
    final current = (await CatalogProjectReader.open(store: reader.store,
        descriptor: reader.descriptor, metadataFields: {}))!;
    if (CatalogSpatialMapSelection.supports(actionId, parameters: parameters)) {
      if (readDependencies.isNotEmpty) throw const FormatException('catalog.spatial: external read dependencies are unsupported');
      return (await CatalogSpatialMapSelection.read(reader: current, projectHandle: projectHandle, actionId: actionId, parameters: parameters)).snapshot;
    }
    return (await CatalogWorkshopSelection.read(reader: current,
        projectHandle: projectHandle, actionId: actionId,
        parameters: parameters, readDependencies: readDependencies)).snapshot;
  }

  Future<void> prepareWorkshopCatalog() async {
    _authorize(AuthoringSecurityOperation.plan);
    final prepareRetainedGenerations = await reader.store.prepareLocalEditing();
    await reader.store.gateway.withExclusiveWriteLock(() =>
        CatalogGenerationRetention(store: reader.store)
            .bindProjectUnderLock(reader.projectId));
    final editing = await _editing();
    final history = editing.history;
    if (history is FileAuthoringHistoryStore) {
      await reader.store.gateway.withExclusiveWriteLock(() => history.prepareLocalHistory(
          force: prepareRetainedGenerations,
          prepareEntry: editing.prepareRetainedGenerationAdmissions));
    }
    await editing.prepareFinalizedJournals();
    await editing.prepareMetadataDocuments(force: prepareRetainedGenerations);
  }

  Future<AuthoringMutationPlanResult> _planWorkshop(AuthoringRequest request) async {
    final current = (await CatalogProjectReader.open(store: reader.store,
        descriptor: reader.descriptor, metadataFields: {}))!;
    final selection = await CatalogWorkshopSelection.read(reader: current,
        projectHandle: projectHandle, actionId: request.actionId,
        parameters: request.parameters, readDependencies: Map<String, String>.from(
            request.extensions['workshopReadDependencies'] as Map? ?? const {}));
    selection.requireSafeParameters(request);
    final built = await buildScopedProjectPlan(request, selection.snapshot);
    if (!built.applicable) return built;
    try {
      final mutation = await CatalogScopedWorkingMutation.translate(
          selection: selection, publicPlan: built.plan);
      if (await reader.store.readProjectId() == null) {
        CatalogWorkshopSelection.unsupported(request.actionId,
            'explicit catalog identity preparation before the first targeted edit');
      }
      final editing = await _editing();
      if (editing.snapshot.root != current.catalog.snapshot.root) {
        throw AuthoringPlanException(code: 'plan.stale',
            message: 'The catalog changed while planning this workshop edit.');
      }
      final prepared = await editing.planPatch(upserts: mutation.upserts,
          removals: mutation.removals,
          additionalChanges: mutation.additionalChanges,
          workspaceFingerprint: mutation.workspaceFingerprint,
          publicBaseRevision: selection.snapshot.revision,
          publicDiff: mutation.diff, publicPlan: built.plan,
          currentProjectRevision: selection.currentRevision,
          idempotencyKey: request.idempotencyKey!, request: request);
      _plans[prepared.plan.planId] = prepared;
      final receipt = prepared.plan.toPlannedReceipt();
      return AuthoringMutationPlanResult(plan: prepared.plan,
          snapshotRevision: selection.snapshot.revision, receipt: receipt,
          projectedProject: mutation.projectedProject,
          publicProjection: await projections?.preparePlan(plan: prepared.plan,
              receipt: receipt, snapshotRevision: selection.snapshot.revision));
    } finally {
      await discardProjectPlan(built.planId);
    }
  }

  Future<AuthoringMutationPlanResult> _planMap(AuthoringRequest request) async {
    if (request.extensions.isNotEmpty) {
      throw const FormatException(
          'catalog.map: request extensions are unsupported');
    }
    if (request.idempotencyKey == null) {
      throw AuthoringPlanException(
          code: 'plan.idempotency_key_required',
          message: 'Mutation planning requires an idempotency key.');
    }
    final current = (await CatalogProjectReader.open(
        store: reader.store, descriptor: reader.descriptor))!;
    final edit =
        await CatalogTargetedMapEdit.prepare(reader: current, request: request);
    final editing = await _editing();
    final prepared = await editing.planPatch(
        additionalChanges: edit.draft.changeSet.changes,
        workspaceFingerprint: edit.workspaceFingerprint,
        publicBaseRevision: edit.selection.snapshotRevision,
        publicDiff: edit.diff,
        currentProjectRevision: () async {
          if (await reader.store.gateway
                  .readResourceRevision(edit.selection.storageKey) !=
              edit.selection.mapRevision) {
            throw AuthoringPlanException(
                code: 'plan.stale',
                message: 'The map changed before publication.');
          }
          final current = (await CatalogProjectReader.open(
              store: reader.store, descriptor: reader.descriptor))!;
          if (current.revision != edit.selection.catalogRevision) {
            throw AuthoringPlanException(
                code: 'plan.stale',
                message: 'The catalog changed before map publication.');
          }
          return edit.selection.snapshotRevision;
        },
        idempotencyKey: request.idempotencyKey!,
        request: request);
    _plans[prepared.plan.planId] = prepared;
    final receipt = prepared.plan.toPlannedReceipt();
    return AuthoringMutationPlanResult(
        plan: prepared.plan,
        snapshotRevision: edit.selection.snapshotRevision,
        receipt: receipt,
        publicProjection: await projections?.preparePlan(
            plan: prepared.plan,
            receipt: receipt,
            snapshotRevision: edit.selection.snapshotRevision));
  }

  Future<AuthoringMutationPlanResult> _planSpatialMap(
      AuthoringRequest request) async {
    final current = (await CatalogProjectReader.open(
        store: reader.store,
        descriptor: reader.descriptor,
        metadataFields: {}))!;
    final selection = await CatalogSpatialMapSelection.read(
        reader: current,
        projectHandle: projectHandle,
        actionId: request.actionId,
        parameters: request.parameters);
    final built = await buildScopedProjectPlan(request, selection.snapshot);
    if (!built.applicable) { return built; }
    try {
      final mutation = await selection.translate(built.plan);
      final editing = await _editing();
      if ('sha256:${editing.snapshot.root.sha256}' != selection.catalogRevision) {
        throw AuthoringPlanException(
            code: 'plan.stale',
            message: 'The catalog changed during spatial map planning.'); }
      final prepared = await editing.planPatch(
          additionalChanges: mutation.changes,
          workspaceFingerprint: mutation.fingerprint,
          publicBaseRevision: selection.snapshot.revision,
          publicDiff: mutation.diff,
          publicPlan: built.plan,
          currentProjectRevision: selection.currentRevision,
          idempotencyKey: request.idempotencyKey!,
          request: request);
      _plans[prepared.plan.planId] = prepared;
      final receipt = prepared.plan.toPlannedReceipt();
      return AuthoringMutationPlanResult(
          plan: prepared.plan,
          snapshotRevision: selection.snapshot.revision,
          receipt: receipt,
          publicProjection: await projections?.preparePlan(
              plan: prepared.plan,
              receipt: receipt,
              snapshotRevision: selection.snapshot.revision));
    } finally {
      await discardProjectPlan(built.planId);
    }
  }

  Future<AuthoringMutationPlanResult> _planProject(
      AuthoringRequest request) async {
    final built = await buildProjectPlan(request);
    if (!built.applicable) return built;
    try {
      final snapshot = await loadProject();
      if (snapshot.revision != request.expectedRevision) {
        throw AuthoringPlanException(
            code: 'plan.stale',
            message:
                'The project changed while preparing its catalog mutation.');
      }
      final current = await CatalogProjectReader.open(
          store: reader.store, descriptor: reader.descriptor);
      final mutation = await current!.read((catalog) =>
          CatalogWorkingMutation.translate(
              catalog: catalog, snapshot: snapshot, publicPlan: built.plan));
      final editing = await _editing();
      if (editing.snapshot.root != current.catalog.snapshot.root) {
        throw AuthoringPlanException(
            code: 'plan.stale',
            message:
                'The catalog changed while preparing its project mutation.');
      }
      final prepared = await editing.planPatch(
          upserts: mutation.upserts,
          removals: mutation.removals,
          additionalChanges: mutation.additionalChanges,
          workspaceFingerprint: mutation.workspaceFingerprint,
          publicBaseRevision: snapshot.revision,
          publicDiff: mutation.diff,
          publicPlan: built.plan,
          currentProjectRevision: () async => (await loadProject()).revision,
          idempotencyKey: request.idempotencyKey!,
          request: request);
      _plans[prepared.plan.planId] = prepared;
      return AuthoringMutationPlanResult(
          plan: prepared.plan,
          snapshotRevision: snapshot.revision,
          receipt: prepared.plan.toPlannedReceipt(),
          projectedProject: mutation.projectedProject,
          publicProjection: await projections?.preparePlan(
              plan: prepared.plan,
              receipt: prepared.plan.toPlannedReceipt(),
              snapshotRevision: snapshot.revision));
    } finally {
      await discardProjectPlan(built.planId);
    }
  }

  Future<bool> _isCatalogOnlyReceipt(AuthoringReceipt receipt) async {
    if (receipt.diff.entries.any((entry) =>
        (entry.resource.extensions.containsKey('workshopResourcePaths') || entry.resource.extensions.containsKey('nativeMapResourcePath')))) {
      return true;
    }
    if (const {'catalog.definition.update', 'map.save'}
        .contains(receipt.actionId)) {
      return true;
    }
    if (receipt.actionId.startsWith('history.')) {
      final target = AuthoringHistoryContext.fromExtensions(receipt.extensions)
          .targetEntryId;
      if (target != null) {
        final entry = await (await _editing())
            .history
            .get(projectId: reader.projectId, entryId: target);
        return entry != null &&
            await _isCatalogOnlyReceipt(entry.receipt);
      }
    }
    return false;
  }

  Future<String> _catalogRevisionForReceipt(AuthoringReceipt receipt) async {
    final current = (await CatalogProjectReader.open(
        store: reader.store, descriptor: reader.descriptor, metadataFields: {}))!;
    for (final entry in receipt.diff.entries) {
      final nativePath = entry.resource.extensions['nativeMapResourcePath'];
      if (nativePath is String) {
        final revision = await reader.store.gateway.readResourceRevision(nativePath);
        if (revision == null) throw const FormatException('catalog.spatial: selected map missing');
        return CatalogSpatialMapSelection.fingerprint(current.revision, entry.resource.id, revision);
      }
      final paths = entry.resource.extensions['workshopResourcePaths'];
      if (paths is List) {
        return CatalogWorkshopSelection.fingerprint(current.revision, {
          for (final path in paths.cast<String>())
            path: await reader.store.gateway.readResourceRevision(path),
        });
      }
    }
    final maps = receipt.diff.entries
        .where((entry) => entry.resource.kind == 'map')
        .map((entry) => entry.resource.id)
        .toSet();
    if (maps.length == 1) {
      return (await CatalogTargetedMapSelection.read(
              reader: await current.withMetadataFields({
                'maps',
                'groups',
                'settings',
                'newGame',
                'scenes',
                'eventRegistry',
                'cinematics',
                'trainers',
                'scenarios',
                'pokemon',
                'dialogues',
                'encounterTables',
                'scripts',
                'regionalMap',
              }), mapId: maps.single))
          .snapshotRevision;
    }
    return current.revision;
  }

  Future<AuthoringMutationResult> _result(AuthoringReceipt receipt,
      {bool? catalogOnly}) async {
    String? revision;
    try {
      revision = (catalogOnly ?? await _isCatalogOnlyReceipt(receipt))
          ? await _catalogRevisionForReceipt(receipt)
          : (await loadProject()).revision;
    } on Object {
      revision = null;
    }
    final diagnostic =
        revision == null ? const AuthoringSnapshotRefreshDiagnostic() : null;
    return AuthoringMutationResult(
        receipt: receipt,
        snapshotRevision: revision,
        diagnostic: diagnostic,
        publicProjection: await projections?.prepareCommittedMutation(
            receipt: receipt,
            snapshotRevision: revision,
            diagnostic: diagnostic?.toJson()));
  }

  CatalogEditingPlan _plan(String planId) {
    requireRead();
    final plan = _plans[planId];
    if (plan == null) {
      throw AuthoringPlanException(
          code: 'plan.unknown',
          message: 'The requested catalog plan is unknown.');
    }
    if (!plan.plan.applicable) {
      throw AuthoringPlanException(
          code: 'plan.not_applicable',
          message: 'This catalog plan cannot be applied.');
    }
    if (!_clock().toUtc().isBefore(plan.plan.expiresAt)) {
      throw AuthoringPlanException(
          code: 'plan.expired', message: 'The catalog plan has expired.');
    }
    return plan;
  }

  Future<AuthoringMutationConfirmationResult> confirm(String planId) async {
    final plan = _plan(planId).plan;
    final token = _confirmations.issue(AuthoringConfirmationBinding.forPlan(
        actorId: actor.actorId, projectId: reader.projectId, plan: plan));
    return AuthoringMutationConfirmationResult(
        planId: planId,
        confirmationToken: token.wireValue,
        expiresInSeconds: _confirmations.lifetime.inSeconds);
  }

  Future<AuthoringMutationResult> apply(
      {required String planId,
      required String operationId,
      String? confirmationToken,
      AuthoringTransactionPrecondition? precondition,
      void Function()? beforeReservation,
      void Function()? preparationCheck}) async {
    requireRead();
    if (reader.readOnly) _authorize(AuthoringSecurityOperation.apply);
    safeAuthoringSecurityIdentifier(planId, 'planId');
    safeAuthoringSecurityIdentifier(operationId, 'operationId');
    if (!reader.readOnly) {
      final replay = await inspectReplay(planId, operationId);
      if (replay != null) return _result(replay);
    }
    final prepared = _plan(planId);
    final previous = _operations[planId];
    if (previous != null && previous != operationId) {
      throw AuthoringPlanException(
          code: 'plan.operation_mismatch',
          message: 'The catalog plan is bound to another operation.');
    }
    _operations[planId] = operationId;
    final touched = prepared.plan.changeSet.changes.length;
    AuthoringAuthorizationDecision? authorization;
    var denied = false;
    late final AuthoringReceipt receipt;
    try {
      receipt = await (await _editing())
          .apply(prepared, operationId: operationId, precondition: () async {
        try {
          await prepareApply(prepared.plan, operationId);
          prepared.plan.bulkCapability?.requirePlan(prepared.plan,
              actorId: actor.actorId,
              projectId: reader.projectId,
              operationId: operationId);
          authorization = _authorize(AuthoringSecurityOperation.apply,
              request: prepared.plan.request,
              touched: touched,
              prepared: prepared,
              operationId: operationId,
              confirmationToken: confirmationToken);
        } on Object {
          denied = true;
          rethrow;
        }
        await requirePlanPreconditions(prepared.plan);
        await precondition?.call();
      },
              beforeReservation: beforeReservation,
              preparationCheck: preparationCheck);
    } on Object catch (error, stack) {
      await auditOutcome(
          prepared.plan,
          denied
              ? AuthoringAuditDecision.denied
              : AuthoringAuditDecision.failed,
          null,
          error,
          const {});
      Error.throwWithStackTrace(error, stack);
    }
    await auditOutcome(
        prepared.plan, AuthoringAuditDecision.succeeded, receipt, null, {
      'confirmationConsumed': authorization?.confirmationConsumed ?? false,
      'requiredPermissions': [
        for (final permission in authorization?.requiredPermissions ??
            <AuthoringPermissionScope>{})
          permission.wireName
      ],
      'touchedResources': touched,
    });
    return _result(receipt);
  }

  Future<AuthoringMutationHistoryResult> history(
      {required int limit, String? cursor}) async {
    requireRead();
    if (reader.readOnly) {
      throw const AuthoringAuthorizationException(
          code: 'catalog.read_only',
          message: 'Portable catalog publications have no editable history.');
    }
    final editing = await _editing();
    final page = await editing.history.list(
        projectId: reader.projectId,
        limit: limit,
        cursor: cursor == null
            ? null
            : AuthoringHistoryCursor.fromWireValue(cursor));
    return AuthoringMutationHistoryResult(page,
        publicProjection: await projections?.prepareHistory(page));
  }

  Future<AuthoringMutationResult> undo(
      {required String entryId, required String idempotencyKey}) async {
    requireRead();
    if (reader.readOnly) _authorize(AuthoringSecurityOperation.apply);
    final editing = await _editing();
    final entry = await editing.history
        .get(projectId: reader.projectId, entryId: entryId);
    final catalogOnly =
        entry != null && await _isCatalogOnlyReceipt(entry.receipt);
    final revision = catalogOnly
        ? await _catalogRevisionForReceipt(entry.receipt)
        : (await loadProject()).revision;
    return projectHistory(
        operation: 'undo',
        entryId: entryId,
        operationId: idempotencyKey,
        expectedRevision: revision,
        requireBulkOrigin: false,
        catalogOnly: catalogOnly);
  }

  Future<AuthoringMutationResult> projectHistory(
      {required String operation,
      required String entryId,
      required String operationId,
      required String expectedRevision,
      String? expectedHeadEntryId,
      void Function()? beforeReservation,
      void Function()? preparationCheck,
      bool requireBulkOrigin = true,
      bool catalogOnly = false}) async {
    requireRead();
    if (reader.readOnly) _authorize(AuthoringSecurityOperation.apply);
    if (!const {'undo', 'redo', 'revert'}.contains(operation)) {
      throw const AuthoringHistoryException('history.operation_unsupported',
          'This catalog history operation is not yet supported.');
    }
    final replay =
        await inspectHistoryReplay(operationId, 'history.$operation', entryId);
    if (replay != null) return _result(replay);
    final editing = await _editing();
    final entry = await editing.history
        .get(projectId: reader.projectId, entryId: entryId);
    final observed = catalogOnly && entry != null
        ? await _catalogRevisionForReceipt(entry.receipt)
        : (await loadProject()).revision;
    if (observed != expectedRevision) {
      throw const AuthoringHistoryException(
          'history.project_stale', 'The expected project revision differs.');
    }
    if (requireBulkOrigin && entry?.bulkCapability == null) {
      throw const AuthoringHistoryException('history.bulk_origin_required',
          'A canonical pack history entry is required.');
    }
    final request = AuthoringRequest(
        requestId: operationId,
        actionId: 'history.$operation',
        actionVersion: 1,
        workspaceHandle: workspaceHandle.value,
        expectedRevision: expectedRevision,
        idempotencyKey: operationId);
    _authorize(AuthoringSecurityOperation.plan, request: request);
    final CatalogEditingPlan prepared;
    if (operation == 'revert') {
      if (expectedHeadEntryId == null) {
        throw const AuthoringHistoryException('history.head_required',
            'Reverting a retained state requires the expected history head.');
      }
      final before = await loadProject();
      if (before.revision != expectedRevision) {
        throw const AuthoringHistoryException(
            'history.project_stale', 'The expected project revision differs.');
      }
      prepared = await editing.planRevert(
          entryId: entryId,
          expectedHeadEntryId: expectedHeadEntryId,
          idempotencyKey: operationId,
          operationId: operationId,
          request: request,
          publicBaseRevision: expectedRevision,
          currentProjectRevision: () async => (await loadProject()).revision,
          validateProjection: (projected, changes) =>
              CatalogWorkingMutation.validateProjection(
                  projected: projected,
                  changes: changes,
                  store: reader.store,
                  before: before));
    } else if (operation == 'undo') {
      prepared = await editing.planUndo(
          entryId: entryId,
          idempotencyKey: operationId,
          operationId: operationId,
          request: request,
          publicBaseRevision: expectedRevision,
          currentProjectRevision: catalogOnly
              ? () => _catalogRevisionForReceipt(entry!.receipt)
              : () async => (await loadProject()).revision);
    } else {
      prepared = await editing.planRedo(
          entryId: entryId,
          idempotencyKey: operationId,
          operationId: operationId,
          request: request,
          publicBaseRevision: expectedRevision,
          currentProjectRevision: catalogOnly
              ? () => _catalogRevisionForReceipt(entry!.receipt)
              : () async => (await loadProject()).revision);
    }
    _plans[prepared.plan.planId] = prepared;
    return apply(
        planId: prepared.plan.planId,
        operationId: operationId,
        beforeReservation: beforeReservation,
        preparationCheck: preparationCheck);
  }

  Future<AuthoringMutationResult> recover(String operationId) async {
    _authorize(AuthoringSecurityOperation.recover, touched: 1);
    final editing = await _editing();
    final receipt = await editing.reconcile(operationId);
    if (receipt == null) {
      throw const CatalogStorageException('catalog.operation_discarded',
          'The unreserved catalog operation was discarded.');
    }
    return _result(receipt);
  }

  Future<Map<String, Object?>> recoveryStatus(String operationId) async {
    requireRead();
    if (reader.readOnly) {
      throw const AuthoringAuthorizationException(
          code: 'catalog.read_only',
          message:
              'Portable catalog publications have no recoverable mutations.');
    }
    final editing = await _editing();
    final pending = await editing.recovery.inspect();
    final matching = pending.where((entry) => entry.operationId == operationId);
    return matching.isEmpty
        ? {'operationId': operationId, 'disposition': 'notFound'}
        : matching.first.toJson();
  }

  AuthoringPlan activePlan(String planId) => _plan(planId).plan;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final opening = _editingFuture;
    _editingFuture = null;
    _plans.clear();
    _operations.clear();
    if (opening == null) return;
    final CatalogEditingSession editing;
    try {
      editing = await opening;
    } on Object {
      return;
    }
    await editing.close();
  }
}
