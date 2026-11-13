import '../../contracts/map_edit_operation.dart';
import '../../domains/maps/trigger_zone_actions.dart';
import '../../domains/assets/model3d_actions.dart';
import '../../domains/gameplay/pokemon_media_storage_path.dart';
import '../../ports/transaction_file_gateway.dart';
import '../../references/exterior_decoration_references.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../contracts/artifact_ref.dart';
import '../../ports/artifact_store.dart';

import 'package:map_core/map_core.dart';

import '../../api/authoring_mutation_contracts.dart';
import '../../application/map_mutation_dispatcher.dart';
import '../../contracts/authoring_receipt.dart';
import '../../workspace/project_snapshot.dart';
import 'catalog_working_mutation.dart';
import 'catalog_targeted_map_edit.dart';
import 'catalog_spatial_map_selection.dart';
import 'catalog_model_source_selection.dart';
import 'catalog_workshop_selection.dart';
import 'catalog_resource_usage_index.dart';
import 'catalog_resource_index_snapshot.dart';
import 'catalog_scoped_working_mutation.dart';
import '../../catalog_storage/catalog_editing_session.dart';
import '../../catalog_storage/catalog_storage_store.dart';
import '../../catalog_storage/catalog_generation_retention.dart';
import 'catalog_action_contracts.dart';
import '../../contracts/authoring_request.dart';
import '../../contracts/json_contract_support.dart';
import '../../support/authoring_fingerprint.dart';
import '../../history/history_store.dart';
import '../../history/content_blob_store.dart';
import '../../history/file_history_store.dart';
import '../../history/catalog_history_retention.dart';
import '../../security/authoring_permission.dart';
import '../../security/audit_record.dart';
import '../../security/authorization_policy.dart';
import '../../security/confirmation_token.dart';
import '../../transactions/journaled_transaction.dart';
import '../../transactions/recovery_service.dart';
import '../../transactions/transaction_journal.dart';
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
      this.artifactStore,
      required this.inspectHistoryReplay,
      required this.loadProject,
      this.acceptObservedCatalogRevision,
      required this.buildProjectPlan,
      required this.buildScopedProjectPlan,
      required this.projectHandle,
      required this.discardProjectPlan,
      required this.inspectReplay,
      required this.prepareApply,
      required this.requirePlanPreconditions,
      this.requireScopedMediaReconciled,
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
  final ArtifactStore? artifactStore;
  final AuthoringActionDescriptor Function(String actionId) resolveAction;
  final Future<AuthoringReceipt?> Function(
      String operationId, String actionId, String entryId) inspectHistoryReplay;
  final Future<ProjectSnapshot> Function() loadProject;
  final Future<bool> Function(String? expectedRevision, String catalogRevision, Map<String, String?> resources)? acceptObservedCatalogRevision;
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
  final Future<void> Function()? requireScopedMediaReconciled;
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
  ({String requestKey, String revision, CatalogModelSourceSelection selection})?
      _modelSourceSelection;
  ({String requestKey, CatalogWorkshopSelection selection})?
      _workshopSelection;
  final Map<String, CatalogEditingPlan> _plans = {};
  final Map<String, String> _operations = {};
  final Map<String, Map<String, String>> _battleGifs = {};
  final Map<String, Map<String, String>> _historyBattleGifs = {};

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
    if ((request.extensions.containsKey('battleGifArtifacts') ||
            request.extensions.containsKey('battleCryArtifact') ||
            request.extensions.containsKey('pokemonPngArtifacts')) &&
        (request.actionId != 'pokemon.media.write' ||
            request.extensions['workshopScope'] != true)) {
      throw const FormatException('Battle media imports require a scoped media write.');
    }

    if (request.actionId == 'map3d.edit_batch' &&
        !CatalogSpatialMapSelection.supports(request.actionId,parameters:request.parameters)) {
      throw AuthoringPlanException(code:'map3d.edit_batch.scope_unsupported',
          message:'The batch is not supported by the targeted map scope.');
    }
    if (request.workspaceHandle != workspaceHandle.value) {
      throw const WorkspaceHandleException('workspace.project_mismatch',
          'The request does not belong to this workspace.');
    }
    await requireUnusedExteriorReferences(
        exteriorDeletedDefinitions(request.actionId, request.parameters),
        reader.store.gateway);
    if (request.actionId == 'map.save') return _planMap(request);
    if (request.actionId == 'map.update_metadata') return _planWorkshop(request);
    if (request.actionId == 'map.create') {
      final current = (await CatalogProjectReader.open(store: reader.store,
          descriptor: reader.descriptor, metadataFields: {'settings'}))!;
      if (current.catalog.projectMetadata.settings.dimension == ProjectDimension.threeD) {
        return _planWorkshop(request);
      }
    }
    if (CatalogModelSourceSelection.supports(request.actionId)) {
      final scope = request.extensions['sourceReplacementScope'];
      if (request.extensions.containsKey('sourceReplacementScope') &&
          !const {'local', 'project'}.contains(scope)) {
        throw const FormatException('sourceReplacementScope must be local or project.');
      }
      return scope == 'project' ? _planProject(request) : _planModelSource(request);
    }
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
      'placementContext',
      'category'
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
    if (args.containsKey('category')) {
      if (!ResourceLibraryCatalog.resourceKinds.contains(resourceKind)) {
        throw const FormatException(
            'catalog.definition: category requires a library resource');
      }
      resourceUsageCategoryFromJson(args['category']);
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
              args.containsKey('placementContext') ||
              args.containsKey('category'))) {
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
        for (final field in ['description', 'placementContext', 'category']) {
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
            entry.placementContext != null ||
            entry.category != null) {
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
    _modelSourceSelection = null;
    _workshopSelection = null;
    if (actionId == 'map3d.edit_batch' &&
        !CatalogSpatialMapSelection.supports(actionId,parameters:parameters)) {
      throw AuthoringPlanException(code:'map3d.edit_batch.scope_unsupported',
          message:'The batch is not supported by the targeted map scope.');
    }
    final requestKey = CatalogModelSourceSelection.supports(actionId)
        ? _modelSourceRequestKey(actionId, parameters)
        : null;
    final current = (await CatalogProjectReader.open(store: reader.store,
        descriptor: reader.descriptor, metadataFields: {}))!;
    if (CatalogModelSourceSelection.supports(actionId)) {
      if (readDependencies.isNotEmpty) throw const FormatException('catalog.model_source: external read dependencies are unsupported');
      final selection = await CatalogModelSourceSelection.read(reader: current,
          projectHandle: projectHandle, actionId: actionId, parameters: parameters);
      _modelSourceSelection = (
        requestKey: requestKey!,
        revision: selection.snapshot.revision,
        selection: selection
      );
      return selection.snapshot;
    }
    if (actionId != 'map.update_metadata' && CatalogSpatialMapSelection.supports(actionId, parameters: parameters)) {
      if (readDependencies.isNotEmpty) throw const FormatException('catalog.spatial: external read dependencies are unsupported');
      try {
        return (await CatalogSpatialMapSelection.read(reader: current, projectHandle: projectHandle, actionId: actionId, parameters: parameters)).snapshot;
      } on ProjectSnapshotException catch (error) {
        if (error.code != 'project.field_traversal_scope_required') rethrow;
      }
    }
    final selection = await CatalogWorkshopSelection.read(reader: current,
        projectHandle: projectHandle, actionId: actionId,
        parameters: parameters, readDependencies: readDependencies);
    if (actionId == 'model3d.prune_unused' ||
        _reusableWorkshopActions.contains(actionId)) {
      _workshopSelection = (
        requestKey: _workshopRequestKey(actionId, parameters, readDependencies),
        selection: selection,
      );
    }
    return selection.snapshot;
  }

  Future<void> prepareWorkshopCatalog({String? scope}) async {
    _authorize(AuthoringSecurityOperation.plan);
    if (scope == 'resourceIndexes') {
      final editing = await _editing();
      if (await CatalogResourceUsageIndex.prepared(editing.snapshot) &&
          await CatalogReverseReferences.prepared(editing.snapshot)) {
        return;
      }
      final root = editing.snapshot.root;
      final project = await CatalogResourceIndexSnapshot.read(catalog: editing.snapshot,
          store: reader.store, projectHandle: projectHandle);
      if (await reader.store.readHead() != root) {
        throw const CatalogStorageException('catalog.revision_conflict',
            'The project changed while preparing its resource indexes.');
      }
      await editing.prepareResourceIndexes(project.snapshot, currentRevision: project.currentRevision);
      return;
    }
    if (scope == 'dialogueCreation') {
      await (await _editing()).prepareDialogueCreation();
      return;
    }
    await preparePendingTransactionJournals(reader.store.gateway);
    if (scope == 'assetImport' || scope == 'nativeResources') {
      await (await _editing()).prepareAssetImport(nativeResources: scope == 'nativeResources');
      return;
    }
    if (scope == 'mapCreation') {
      await (await _editing()).prepareMapCreation();
      return;
    }
    if (scope == 'metadataContext') {
      final store = reader.store;
      final history = await FileAuthoringHistoryStore.open(
          projectRoot: store.projectRoot, incrementalWrites: true);
      await history.requireExistingLocalWindow();
      final root = await store.readHead();
      if (root == null) {
        throw const CatalogStorageException('catalog.missing',
            'There is no current catalog generation.');
      }
      await store.requireMetadataIndexAdmission(
          (await store.openRoot(root)).snapshot);
      final blobs = await FileAuthoringContentBlobStore.open(
          projectRoot: store.projectRoot);
      await CatalogHistoryRetention(store: store, history: history, blobs: blobs)
          .prepareNavigableAdmissions(projectId: reader.projectId,
              requirePreparedMetadataIndex: true);
      return;
    }
    if (scope != null) throw const FormatException('catalog.preparation_scope_unsupported');
    final currentGenerationPrepared = await reader.store.prepareLocalEditing();
    await reader.store.gateway.withExclusiveWriteLock(() =>
        CatalogGenerationRetention(store: reader.store)
            .bindProjectUnderLock(reader.projectId));
    final editing = await _editing();
    final history = editing.history;
    if (history is FileAuthoringHistoryStore) {
      await reader.store.gateway
          .withExclusiveWriteLock(() => history.prepareLocalHistory());
    }
    await editing.prepareFinalizedJournals();
    await editing.prepareMetadataDocuments(force: currentGenerationPrepared);
  }

  Future<Map<String, Object?>> maintainHistory(
      {required String expectedRevision,
      bool apply = false,
      String? expectedFingerprint,
      int maxOperations = 50,
      int maxBytes = 200 * 1024 * 1024}) async {
    _authorize(apply
        ? AuthoringSecurityOperation.apply
        : AuthoringSecurityOperation.plan);
    if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(expectedRevision) ||
        maxOperations < 1 ||
        maxOperations > 50 ||
        maxBytes < 1 ||
        maxBytes > 200 * 1024 * 1024 ||
        (apply && (expectedFingerprint == null || expectedFingerprint.isEmpty))) {
      throw const FormatException('history.maintenance: invalid parameters');
    }
    await reader.store.prepareLocalEditing();
    final editing = await _editing();
    final history = editing.history;
    if (history is! FileAuthoringHistoryStore) {
      throw const AuthoringHistoryException('history.maintenance_unsupported',
          'Explicit history maintenance requires canonical local history.');
    }
    final retention = CatalogHistoryRetention(
        store: reader.store, history: history, blobs: editing.blobs);
    if (apply) {
      return (await retention.apply(
              projectId: reader.projectId,
              expectedRootSha256: expectedRevision.substring(7),
              expectedFingerprint: expectedFingerprint!,
              maxOperations: maxOperations,
              maxBytes: maxBytes))
          .toJson();
    }
    return (await retention.preview(
            projectId: reader.projectId,
            expectedRootSha256: expectedRevision.substring(7),
            maxOperations: maxOperations,
            maxBytes: maxBytes))
        .toJson();
  }

  Future<AuthoringMutationPlanResult> _planWorkshop(AuthoringRequest request) async {
    final previous = _workshopSelection;
    _workshopSelection = null;
    final mediaArtifacts = {
      ...await _prepareBattleGifs(request),
      ...await _prepareBattleCry(request),
      ...await _preparePokemonPngs(request),
    };
    final current = (await CatalogProjectReader.open(store: reader.store,
        descriptor: reader.descriptor, metadataFields: {}))!;
    final readDependencies = Map<String, String>.from(
        request.extensions['workshopReadDependencies'] as Map? ?? const {});
    final reusable = previous != null &&
        previous.requestKey ==
            _workshopRequestKey(
                request.actionId, request.parameters, readDependencies) &&
        previous.selection.snapshot.revision == request.expectedRevision;
    final CatalogWorkshopSelection selection;
    if (request.actionId == 'model3d.prune_unused' && reusable) {
      selection = previous.selection;
      if (current.catalog.snapshot.root !=
          selection.reader.catalog.snapshot.root) {
        throw AuthoringPlanException(
            code: 'plan.stale', message: 'The library changed after its audit.');
      }
      await selection.requireCurrent();
    } else if (reusable &&
        _reusableWorkshopActions.contains(request.actionId) &&
        current.catalog.snapshot.root ==
            previous.selection.reader.catalog.snapshot.root) {
      selection = previous.selection;
      await selection.requireCurrent();
    } else {
      selection = await CatalogWorkshopSelection.read(reader: current,
          projectHandle: projectHandle, actionId: request.actionId,
          parameters: request.parameters, readDependencies: readDependencies);
    }
    selection.requireSafeParameters(request);
    var scopedRequest = request;
    if (request.expectedRevision != selection.snapshot.revision &&
        await acceptObservedCatalogRevision?.call(request.expectedRevision, current.revision, selection.resourceRevisions) == true) {
      scopedRequest = AuthoringRequest(requestId: request.requestId,
          actionId: request.actionId, actionVersion: request.actionVersion,
          workspaceHandle: request.workspaceHandle, parameters: request.parameters,
          expectedRevision: selection.snapshot.revision, idempotencyKey: request.idempotencyKey,
          dryRun: request.dryRun, extensions: request.extensions);
    }
    final publicRevision = scopedRequest == request ? selection.snapshot.revision : request.expectedRevision!;
    Future<String> currentRevision() async {
      final revision = await selection.currentRevision();
      return revision == selection.snapshot.revision ? publicRevision : revision;
    }
    final built = await buildScopedProjectPlan(scopedRequest, selection.snapshot);
    if (!built.applicable) return built;
    AuthoringPlan? publicPlan;
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
      publicPlan = built.plan.reframeChangeSet(
          changeSet: built.plan.changeSet, request: request, baseRevision: publicRevision);
      final prepared = await editing.planPatch(upserts: mutation.upserts,
          removals: mutation.removals,
          additionalChanges: mutation.additionalChanges,
          workspaceFingerprint: mutation.workspaceFingerprint,
          publicBaseRevision: publicRevision,
          publicDiff: mutation.diff, publicPlan: publicPlan,
          currentProjectRevision: currentRevision,
          idempotencyKey: request.idempotencyKey!, request: request);
      _plans[prepared.plan.planId] = prepared;
      if (mediaArtifacts.isNotEmpty) _battleGifs[prepared.plan.planId] = mediaArtifacts;
      final receipt = prepared.plan.toPlannedReceipt();
      return AuthoringMutationPlanResult(plan: prepared.plan,
          snapshotRevision: publicRevision, receipt: receipt,
          projectedProject: mutation.projectedProject,
          publicProjection: await projections?.preparePlan(plan: prepared.plan,
              receipt: receipt, snapshotRevision: publicRevision));
    } finally {
      await publicPlan?.releasePayloads();
      await discardProjectPlan(built.planId);
    }
  }

  Future<Map<String, String>> _prepareBattleGifs(
      AuthoringRequest request) async {
    final raw = request.extensions['battleGifArtifacts'];
    if (!request.extensions.containsKey('battleGifArtifacts')) return const {};
    final artifacts = artifactStore;
    if (artifacts == null) {
      throw const FormatException('Battle GIF artifacts are unavailable.');
    }
    const roles = {
      'frontAnimated',
      'backAnimated',
      'frontShinyAnimated',
      'backShinyAnimated'
    };
    if (raw is! Map ||
        raw.isEmpty ||
        raw.length > roles.length ||
        raw.keys.any((key) => key is! String || !roles.contains(key)) ||
        raw.values.any((value) => value is! String)) {
      throw const FormatException('Invalid battle GIF selection.');
    }
    final document = request.parameters['document'];
    if (document is! Map ||
        document['defaultFormId'] is! String ||
        document['variants'] is! Map) {
      throw const FormatException('Invalid battle GIF media document.');
    }
    final form = (document['variants'] as Map)[document['defaultFormId']];
    if (form is! Map) {
      throw const FormatException('Missing default media form.');
    }
    final beforeText = request.parameters['beforeBytesBase64'];
    final before = beforeText is String
        ? jsonDecode(utf8.decode(base64Decode(beforeText)))
        : null;
    if (before is Map && before['defaultFormId'] != document['defaultFormId']) {
      throw const FormatException('A battle GIF import cannot change the default form.');
    }
    final oldForms = before is Map ? before['variants'] : null;
    final oldForm =
        oldForms is Map ? oldForms[document['defaultFormId']] : null;
    final output = <String, String>{};
    var total = 0;
    for (final entry in raw.entries) {
      final role = entry.key as String;
      final handle = entry.value as String;
      final ref = artifacts.inspect(handle);
      if (ref == null ||
          ref.mediaType != 'image/gif' ||
          ref.byteLength < 1 ||
          ref.byteLength > PokemonGifInspector.maxEncodedBytes) {
        throw const FormatException('A battle GIF artifact is unavailable.');
      }
      final bytes = await artifacts.read(handle);
      total += bytes.length;
      if (total > 64 * 1024 * 1024 ||
          ContentArtifactRef.fromBytes(bytes, mediaType: ref.mediaType) !=
              ref) {
        throw const FormatException(
            'A battle GIF artifact changed or is too large.');
      }
      const PokemonGifInspector(maxFrames: 500, maxCanvasPixels: 16777216)
          .inspect(Uint8List.fromList(bytes));
      final path = 'assets/pokemon/battle-gifs/${sha256.convert(bytes)}.gif';
      final previous = oldForm is Map ? oldForm[role] : null;
      if (form[role] != path || (previous != null && previous != path)) {
        throw const FormatException(
            'A battle GIF selection would replace an existing media choice.');
      }
      output[path] = handle;
    }
    return output;
  }

  Future<Map<String, String>> _prepareBattleCry(AuthoringRequest request) async {
    if (!request.extensions.containsKey('battleCryArtifact')) return const {};
    final handle = request.extensions['battleCryArtifact'];
    final artifacts = artifactStore;
    if (handle is! String || artifacts == null) {
      throw const FormatException('The Pokemon cry artifact is unavailable.');
    }
    final document = request.parameters['document'];
    if (document is! Map || document['defaultFormId'] is! String ||
        document['variants'] is! Map) {
      throw const FormatException('Invalid Pokemon cry media document.');
    }
    final form = (document['variants'] as Map)[document['defaultFormId']];
    if (form is! Map) throw const FormatException('Missing default media form.');
    final beforeText = request.parameters['beforeBytesBase64'];
    final before = beforeText is String
        ? jsonDecode(utf8.decode(base64Decode(beforeText)))
        : null;
    if (before is Map && before['defaultFormId'] != document['defaultFormId']) {
      throw const FormatException('A cry import cannot change the default form.');
    }
    final oldForms = before is Map ? before['variants'] : null;
    final oldForm = oldForms is Map ? oldForms[document['defaultFormId']] : null;
    final ref = artifacts.inspect(handle);
    if (ref == null || !const {'audio/wav', 'audio/mpeg'}.contains(ref.mediaType) ||
        ref.byteLength < 1 || ref.byteLength > maxBattleRecipeSoundBytes) {
      throw const FormatException('The Pokemon cry artifact is unavailable.');
    }
    final bytes = await artifacts.read(handle);
    if (ContentArtifactRef.fromBytes(bytes, mediaType: ref.mediaType) != ref) {
      throw const FormatException('The Pokemon cry artifact changed.');
    }
    _validateCryAudio(bytes, ref.mediaType);
    final suffix = ref.mediaType == 'audio/wav' ? 'wav' : 'mp3';
    final path = 'assets/pokemon/battle-cries/${sha256.convert(bytes)}.$suffix';
    final previous = oldForm is Map ? oldForm['cry'] : null;
    if (form['cry'] != path ||
        (previous != null && previous != path &&
            (previous is! String || previous.trim().isNotEmpty))) {
      throw const FormatException('A cry import cannot replace an existing media choice.');
    }
    return {path: handle};
  }

  Future<Map<String, String>> _preparePokemonPngs(AuthoringRequest request) async {
    if (!request.extensions.containsKey('pokemonPngArtifacts')) return const {};
    final raw = request.extensions['pokemonPngArtifacts'];
    final artifacts = artifactStore;
    const roles = {
      'frontStatic', 'backStatic', 'frontShinyStatic', 'backShinyStatic',
      'icon', 'party', 'portrait', 'overworld', 'overworldShiny',
    };
    if (artifacts == null || raw is! Map || raw.isEmpty ||
        raw.length > roles.length ||
        raw.keys.any((key) => key is! String || !roles.contains(key)) ||
        raw.values.any((value) => value is! String)) {
      throw const FormatException('Invalid Pokemon PNG selection.');
    }
    final document = request.parameters['document'];
    if (document is! Map || document['defaultFormId'] is! String ||
        document['variants'] is! Map) {
      throw const FormatException('Invalid Pokemon PNG media document.');
    }
    final form = (document['variants'] as Map)[document['defaultFormId']];
    if (form is! Map) throw const FormatException('Missing default media form.');
    final beforeText = request.parameters['beforeBytesBase64'];
    final before = beforeText is String
        ? jsonDecode(utf8.decode(base64Decode(beforeText)))
        : null;
    if (before is Map && before['defaultFormId'] != document['defaultFormId']) {
      throw const FormatException('A PNG import cannot change the default form.');
    }
    final oldForms = before is Map ? before['variants'] : null;
    final oldForm = oldForms is Map ? oldForms[document['defaultFormId']] : null;
    final output = <String, String>{};
    var total = 0;
    for (final entry in raw.entries) {
      final role = entry.key as String;
      final handle = entry.value as String;
      final ref = artifacts.inspect(handle);
      if (ref == null || ref.mediaType != 'image/png' ||
          ref.byteLength < 1 || ref.byteLength > 8 * 1024 * 1024) {
        throw const FormatException('A Pokemon PNG artifact is unavailable.');
      }
      final bytes = await artifacts.read(handle);
      total += bytes.length;
      final dimensions = decodeRasterImageDimensions(bytes, mediaType: 'image/png');
      if (total > 64 * 1024 * 1024 ||
          ContentArtifactRef.fromBytes(bytes, mediaType: ref.mediaType) != ref ||
          dimensions == null || dimensions.width * dimensions.height > 16777216) {
        throw const FormatException('A Pokemon PNG is invalid or too large.');
      }
      final decoder = validatedStaticPngDecoder(Uint8List.fromList(bytes),
          maxDimension: 16384, maxPixels: 16777216);
      if (decoder.decodeFrame(0) == null) {
        throw const FormatException('A Pokemon PNG is invalid or too large.');
      }
      final path = 'assets/pokemon/images/${sha256.convert(bytes)}.png';
      final previous = oldForm is Map ? oldForm[role] : null;
      if (form[role] != path ||
          (previous != null && previous != path &&
              (previous is! String || previous.trim().isNotEmpty))) {
        throw const FormatException('A PNG import cannot replace an existing media choice.');
      }
      output[path] = handle;
    }
    return output;
  }

  void _validateCryAudio(List<int> bytes, String mediaType) {
    inspectBattleRecipeSound(Uint8List.fromList(bytes), mediaType);
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
        store: reader.store,
        descriptor: reader.descriptor,
        metadataFields: catalogMapValidationMetadataFields))!;
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
              store: reader.store,
              descriptor: reader.descriptor,
              metadataFields: const {}))!;
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

  String _modelSourceRequestKey(
          String actionId, Map<String, Object?> parameters) =>
      canonicalAuthoringJson({'actionId': actionId, 'parameters': parameters});

  static const _reusableWorkshopActions = {
    'event_v2.record_upsert',
    'event_v2.record_upsert_batch',
  };

  String _workshopRequestKey(String actionId, Map<String, Object?> parameters,
          Map<String, String> readDependencies) =>
      canonicalAuthoringJson({
        'actionId': actionId,
        'parameters': parameters,
        'readDependencies': readDependencies,
      });

  Future<AuthoringMutationPlanResult> _planModelSource(AuthoringRequest request) async {
    final previous = _modelSourceSelection;
    _modelSourceSelection = null;
    final current = (await CatalogProjectReader.open(store: reader.store,
        descriptor: reader.descriptor, metadataFields: {}))!;
    final CatalogModelSourceSelection selection;
    if (previous != null &&
        previous.requestKey ==
            _modelSourceRequestKey(request.actionId, request.parameters) &&
        previous.revision == request.expectedRevision) {
      selection = previous.selection;
      if (current.catalog.snapshot.root !=
              selection.reader.catalog.snapshot.root ||
          await selection.currentRevision() != previous.revision) {
        throw AuthoringPlanException(
            code: 'plan.stale',
            message: 'The model source selection changed before planning.');
      }
      for (final unit in selection.units.values) {
        final fresh = await current.catalog.lookup(unit.key);
        if (fresh == null ||
            canonicalAuthoringJson(fresh.toJson()) !=
                canonicalAuthoringJson(unit.toJson())) {
          throw AuthoringPlanException(
              code: 'plan.stale',
              message: 'A selected model changed before planning.');
        }
      }
    } else {
      selection = await CatalogModelSourceSelection.read(reader: current,
          projectHandle: projectHandle, actionId: request.actionId, parameters: request.parameters);
    }
    final built = await buildScopedProjectPlan(request, selection.snapshot);
    if (!built.applicable) return built;
    try {
      final mutation = await selection.translate(built.plan);
      final editing = await _editing();
      if (editing.snapshot.root != current.catalog.snapshot.root) {
        throw AuthoringPlanException(code: 'plan.stale', message: 'The catalog changed during model source planning.');
      }
      final prepared = await editing.planPatch(upserts: mutation.upserts,
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

  Future<AuthoringMutationPlanResult> _planSpatialMap(
      AuthoringRequest request) async {
    final current = (await CatalogProjectReader.open(
        store: reader.store,
        descriptor: reader.descriptor,
        metadataFields: {}))!;
    final CatalogSpatialMapSelection selection;
    try {
      selection = await CatalogSpatialMapSelection.read(reader: current,
          projectHandle: projectHandle, actionId: request.actionId, parameters: request.parameters);
    } on ProjectSnapshotException catch (error) {
      if (error.code != 'project.field_traversal_scope_required') rethrow;
      return request.extensions['workshopScope'] == true || CatalogWorkshopSelection.supports(request.actionId, parameters: request.parameters)
          ? _planWorkshop(request) : _planProject(request);
    }
    var scopedRequest = request;
    if ((const {'map3d.camera.configure', 'warp.create', 'connection.upsert', 'connection.create_bidirectional_apply', 'connection.update_bidirectional_apply', 'connection.delete_bidirectional_apply'}.contains(request.actionId) || TriggerZoneActions.fieldTraversalActions.contains(request.actionId)) && request.expectedRevision != selection.snapshot.revision &&
        await acceptObservedCatalogRevision?.call(request.expectedRevision, current.revision,
            selection.snapshot.scopedStorageRevisions!) == true) {
      scopedRequest = AuthoringRequest(requestId: request.requestId,
          actionId: request.actionId, actionVersion: request.actionVersion,
          workspaceHandle: request.workspaceHandle, parameters: request.parameters,
          expectedRevision: selection.snapshot.revision, idempotencyKey: request.idempotencyKey,
          dryRun: request.dryRun, extensions: request.extensions);
    }
    final publicRevision = scopedRequest == request ? selection.snapshot.revision : request.expectedRevision!;
    Future<String> currentRevision() async {
      final revision = await selection.currentRevision();
      return revision == selection.snapshot.revision ? publicRevision : revision;
    }
    final built = await buildScopedProjectPlan(scopedRequest, selection.snapshot);
    if (!built.applicable) { return built; }
    AuthoringPlan? publicPlan;
    try {
      final mutation = await selection.translate(built.plan);
      final editing = await _editing();
      if ('sha256:${editing.snapshot.root.sha256}' != selection.catalogRevision) {
        throw AuthoringPlanException(
            code: 'plan.stale',
            message: 'The catalog changed during spatial map planning.'); }
      publicPlan = built.plan.reframeChangeSet(
          changeSet: built.plan.changeSet, request: request, baseRevision: publicRevision);
      final prepared = await editing.planPatch(
          additionalChanges: mutation.changes,
          validatedMaps: mutation.validatedMaps,
          workspaceFingerprint: mutation.fingerprint,
          publicBaseRevision: publicRevision,
          publicDiff: mutation.diff,
          publicPlan: publicPlan,
          currentProjectRevision: currentRevision,
          idempotencyKey: request.idempotencyKey!,
          request: request);
      _plans[prepared.plan.planId] = prepared;
      final receipt = prepared.plan.toPlannedReceipt();
      return AuthoringMutationPlanResult(
          plan: prepared.plan,
          snapshotRevision: publicRevision,
          receipt: receipt,
          publicProjection: await projections?.preparePlan(
              plan: prepared.plan,
              receipt: receipt,
              snapshotRevision: publicRevision));
    } finally {
      await publicPlan?.releasePayloads();
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

  bool _onlyCatalogHeadChanges(AuthoringHistoryEntry entry) =>
      entry.changes.isNotEmpty && entry.changes.every((change) =>
          change.storageKey == CatalogStorageStore.headStorageKey);

  Future<bool> _isCatalogOnlyReceipt(AuthoringReceipt receipt,
      {AuthoringHistoryEntry? historyEntry}) async {
    if (historyEntry != null && _onlyCatalogHeadChanges(historyEntry)) {
      return true;
    }
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
            await _isCatalogOnlyReceipt(entry.receipt, historyEntry: entry);
      }
    }
    final stored = historyEntry ?? await (await _editing()).history.get(
        projectId: reader.projectId, entryId: receipt.receiptId);
    return stored != null && _onlyCatalogHeadChanges(stored);
  }

  Future<String> _catalogRevisionForReceipt(AuthoringReceipt receipt,
      {AuthoringHistoryEntry? historyEntry}) async {
    final mediaChanges = historyEntry?.receipt.actionId == 'pokemon.media.write'
        ? historyEntry!.changes
            .where((change) =>
                change.resource.kind == 'pokemonDocument' &&
                change.resource.id.startsWith('media:') &&
                change.resource.extensions[scopedPokemonMediaHistoryKey] ==
                    true)
            .toList()
        : const <AuthoringHistoryResourceChange>[];
    if (mediaChanges.isNotEmpty) {
      if (mediaChanges.length != 1) {
        throw const AuthoringHistoryException(
            'history.pokemon_media_path_changed',
            'The media history target is no longer valid.');
      }
      final requireReconciled = requireScopedMediaReconciled;
      if (requireReconciled == null) {
        throw const AuthoringHistoryException(
            'history.pokemon_media_precondition_unavailable',
            'The media recovery precondition is unavailable.');
      }
      await requireReconciled();
      await reader.store.requireProjectDescriptor(reader.descriptor);
    }
    final current = (await CatalogProjectReader.open(
        store: reader.store, descriptor: reader.descriptor, metadataFields: {}))!;
    if (mediaChanges.isNotEmpty) {
      final change = mediaChanges.single;
      final metadata = await current.readMetadata({'pokemon'});
      if (!isCanonicalPokemonMediaStoragePath(
          metadata.pokemon.mediaDir,
          change.storageKey,
          change.resource.id.substring('media:'.length))) {
        throw const AuthoringHistoryException(
            'history.pokemon_media_path_changed',
            'The configured media directory no longer matches this history entry.');
      }
    }
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
      return (await CatalogTargetedMapSelection.readRevision(
              reader: current, mapId: maps.single))
          .snapshotRevision;
    }
    return current.revision;
  }

  Future<AuthoringMutationResult> _result(AuthoringReceipt receipt,
      {bool? catalogOnly}) async {
    final rawMapEdit = receipt.extensions['mapEdit'];
    if (receipt.actionId == 'map3d.edit_batch' && rawMapEdit is Map) {
      final binding = MapEditBinding.fromJson(Map<String, dynamic>.from(rawMapEdit));
      return AuthoringMutationResult(receipt: receipt,
          snapshotRevision: binding.snapshotRevision,
          publicProjection: await projections?.prepareCommittedMutation(
              receipt: receipt, snapshotRevision: binding.snapshotRevision));
    }
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
        await _requireNoBattleGifWrites(
            prepared.plan.changeSet.changes.map((change) => change.storageKey));
        final historyGifs = _historyBattleGifs[planId];
        if (historyGifs != null) {
          await _requireBattleGifRevisions(historyGifs);
        }
        final gifs = _battleGifs[planId];
        if (gifs != null) {
          final gateway = reader.store.gateway;
          final revisions = <String, String?>{
            'project.json': await gateway.readResourceRevision('project.json'),
          };
          if (revisions['project.json'] == null) {
            throw const FormatException('The project descriptor is missing.');
          }
          final stageId =
              'battle_gif_${sha256.convert(utf8.encode(operationId))}';
          if (await gateway.readJournal(stageId) != null) {
            throw const FormatException('The GIF staging identity is in use.');
          }
          try {
            for (final entry in gifs.entries) {
              final store = artifactStore;
              final reference = store?.inspect(entry.value);
              final isCry = entry.key.startsWith('assets/pokemon/battle-cries/');
              final isPng = entry.key.startsWith('assets/pokemon/images/');
              final cryType = entry.key.endsWith('.wav') ? 'audio/wav' : 'audio/mpeg';
              if (store == null || reference == null ||
                  reference.mediaType != (isCry ? cryType : isPng ? 'image/png' : 'image/gif') ||
                  reference.byteLength < 1 ||
                  reference.byteLength > (isCry ? maxBattleRecipeSoundBytes : isPng ? 8 * 1024 * 1024 : PokemonGifInspector.maxEncodedBytes)) {
                throw const FormatException('A battle media artifact is unavailable.');
              }
              final bytes = await store.read(entry.value);
              final expectedPath = isCry
                  ? 'assets/pokemon/battle-cries/${sha256.convert(bytes)}.${cryType == 'audio/wav' ? 'wav' : 'mp3'}'
                  : isPng
                  ? 'assets/pokemon/images/${sha256.convert(bytes)}.png'
                  : 'assets/pokemon/battle-gifs/${sha256.convert(bytes)}.gif';
              if (expectedPath != entry.key ||
                  ContentArtifactRef.fromBytes(bytes, mediaType: reference.mediaType) != reference) {
                throw const FormatException('A battle media artifact changed.');
              }
              if (isCry) _validateCryAudio(bytes, cryType);
              final expected = computeAuthoringBytesFingerprint(bytes,
                  logicalName: entry.key);
              final current = await gateway.readResourceRevision(entry.key);
              final marker = _battleGifMarker(entry.key)!;
              final markerBytes = utf8.encode(canonicalAuthoringJson({
                'schemaVersion': 1,
                'path': entry.key,
              }));
              final markerRevision = computeAuthoringBytesFingerprint(markerBytes, logicalName: marker);
              final existingMarker = await gateway.readResourceRevision(marker);
              if (existingMarker == null && current != null) {
                throw const FormatException('An existing file cannot be adopted as an immutable battle GIF.');
              }
              if (existingMarker != null && existingMarker != markerRevision) {
                throw const FormatException('A battle GIF ownership marker is invalid.');
              }
              if (existingMarker == null) {
                await gateway.stagePayload(operationId: stageId, storageKey: marker, kind: TransactionPayloadKind.after, bytes: markerBytes);
                await gateway.promoteStaged(operationId: stageId, storageKey: marker, kind: TransactionPayloadKind.after, expectedCurrentRevision: null);
              }
              if (current == null) {
                await gateway.stagePayload(
                    operationId: stageId,
                    storageKey: entry.key,
                    kind: TransactionPayloadKind.after,
                    bytes: bytes);
                await gateway.promoteStaged(
                    operationId: stageId,
                    storageKey: entry.key,
                    kind: TransactionPayloadKind.after,
                    expectedCurrentRevision: null);
              } else if (current != expected) {
                throw const FormatException(
                    'A retained battle GIF differs from its content address.');
              }
              if (await gateway.readResourceRevision(entry.key) != expected) {
                throw const FormatException(
                    'A published battle GIF failed verification.');
              }
              revisions[entry.key] = expected;
            }
          } finally {
            await gateway.deleteTransaction(stageId);
          }
          if (prepared.plan.mediaRecoveryDependencies == null) {
            prepared.plan.bindMediaRecoveryDependencies(revisions);
          } else if (canonicalAuthoringJson(
                  prepared.plan.mediaRecoveryDependencies) !=
              canonicalAuthoringJson(revisions)) {
            throw const FormatException('The battle GIF dependencies changed.');
          }
        }
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
    _battleGifs.remove(planId);
    _historyBattleGifs.remove(planId);
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
        entry != null && await _isCatalogOnlyReceipt(entry.receipt, historyEntry: entry);
    final revision = catalogOnly
        ? await _catalogRevisionForReceipt(entry.receipt, historyEntry: entry)
        : (await loadProject()).revision;
    return projectHistory(
        operation: 'undo',
        entryId: entryId,
        operationId: idempotencyKey,
        expectedRevision: revision,
        requireBulkOrigin: false,
        catalogOnly: catalogOnly);
  }

  Future<AuthoringMutationResult> redo(
      {required String entryId, required String idempotencyKey}) async {
    requireRead();
    if (reader.readOnly) _authorize(AuthoringSecurityOperation.apply);
    final editing = await _editing();
    final entry = await editing.history
        .get(projectId: reader.projectId, entryId: entryId);
    final catalogOnly =
        entry != null && await _isCatalogOnlyReceipt(entry.receipt, historyEntry: entry);
    final revision = catalogOnly
        ? await _catalogRevisionForReceipt(entry.receipt, historyEntry: entry)
        : (await loadProject()).revision;
    return projectHistory(
        operation: 'redo',
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
        ? await _catalogRevisionForReceipt(entry.receipt, historyEntry: entry)
        : (await loadProject()).revision;
    if (observed != expectedRevision) {
      throw const AuthoringHistoryException(
          'history.project_stale', 'The expected project revision differs.');
    }
    if (requireBulkOrigin && entry?.bulkCapability == null) {
      throw const AuthoringHistoryException('history.bulk_origin_required',
          'A canonical pack history entry is required.');
    }
    final captureMediaRecoveryRevision =
        entry?.receipt.actionId == 'pokemon.media.write' &&
            entry!.changes.any((change) =>
                change.resource.kind == 'pokemonDocument' &&
                change.resource.extensions[scopedPokemonMediaHistoryKey] ==
                    true);
    final request = AuthoringRequest(
        requestId: operationId,
        actionId: 'history.$operation',
        actionVersion: 1,
        workspaceHandle: workspaceHandle.value,
        expectedRevision: expectedRevision,
        idempotencyKey: operationId,
        extensions: {
          if (captureMediaRecoveryRevision) 'captureRecoveryReadRevision': true,
        });
    _authorize(AuthoringSecurityOperation.plan, request: request);
    final CatalogEditingPlan prepared;
    Future<String> Function()? maintenanceRedoRevision;
    if (operation == 'redo' && entry?.receipt.actionId == 'model3d.prune_unused') {
      final modelDiff = entry!.receipt.diff.entries.singleWhere((diff) => diff.path == '/models3d');
      final ids = Model3dActions.pruneModelIds(Map<String, Object?>.from(modelDiff.before as Map));
      final current = (await CatalogProjectReader.open(store: reader.store,
          descriptor: reader.descriptor, metadataFields: {}))!;
      final audit = await CatalogWorkshopSelection.read(reader: current,
          projectHandle: projectHandle, actionId: 'model3d.prune_unused',
          parameters: {'modelIds': ids.toList()});
      final inspected = Model3dActions.inspectPrune(audit.snapshot, ids);
      final removedSources = entry.changes.where((change) =>
          change.resource.kind == 'asset' && change.afterRevision == null)
          .map((change) => change.resource.id).toSet();
      if (inspected.retainedSources.keys.any(removedSources.contains)) {
        throw AuthoringPlanException(code: 'model3d.prune_source_in_use',
            message: 'A source removed by the original maintenance is now referenced.');
      }
      maintenanceRedoRevision = () async {
        if (await audit.currentRevision() != audit.snapshot.revision) {
          throw const AuthoringHistoryException('history.project_stale',
              'A library reference document changed before maintenance redo.');
        }
        return expectedRevision;
      };
    }
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
              ? () => _catalogRevisionForReceipt(entry!.receipt,
                  historyEntry: entry)
              : () async => (await loadProject()).revision);
    } else {
      prepared = await editing.planRedo(
          entryId: entryId,
          idempotencyKey: operationId,
          operationId: operationId,
          request: request,
          publicBaseRevision: expectedRevision,
          currentProjectRevision: maintenanceRedoRevision ?? (catalogOnly
              ? () => _catalogRevisionForReceipt(entry!.receipt,
                  historyEntry: entry)
              : () async => (await loadProject()).revision));
    }
    if (operation == 'redo' && entry != null) {
      final gifs = _battleGifRevisions(entry.receipt);
      if (gifs.isNotEmpty) {
        final projectRevision =
            await reader.store.gateway.readResourceRevision('project.json');
        if (projectRevision == null) {
          throw const AuthoringHistoryException(
              'history.pokemon_media_path_changed',
              'The project descriptor is missing.');
        }
        prepared.plan.bindMediaRecoveryDependencies(
            {'project.json': projectRevision, ...gifs});
        _historyBattleGifs[prepared.plan.planId] = gifs;
      }
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
    final receipt = await editing.reconcile(operationId,
        precondition: () => _requireScopedMediaRecovery(operationId, editing));
    if (receipt == null) {
      throw const CatalogStorageException('catalog.operation_discarded',
          'The unreserved catalog operation was discarded.');
    }
    return _result(receipt);
  }

  Future<void> _requireScopedMediaRecovery(
      String operationId, CatalogEditingSession editing) async {
    final gateway = reader.store.gateway;
    final journal = await gateway.readJournal(operationId);
    if (journal != null && journal.entries.any((entry) =>
        _battleGifMarker(entry.storageKey.toLowerCase()) != null)) {
      final state = await editing.recovery.inspectOperation(
          operationId: operationId, scope: journal.scope);
      if (state?.disposition != AuthoringRecoveryDisposition.completed) {
        await _requireNoBattleGifWrites(
            journal.entries.map((entry) => entry.storageKey));
      }
    }
    if (journal == null ||
        !const {'pokemon.media.write', 'history.undo', 'history.redo'}
            .contains(journal.scope.actionId)) {
      return;
    }
    final mediaChanges = journal.entries
        .where((entry) =>
            entry.resource.kind == 'pokemonDocument' &&
            entry.resource.id.startsWith('media:') &&
            entry.resource.extensions[scopedPokemonMediaHistoryKey] == true)
        .toList();
    if (mediaChanges.isEmpty) return;
    if (mediaChanges.length != 1) {
      throw const AuthoringHistoryException(
          'history.pokemon_media_path_changed',
          'The media history target is no longer valid.');
    }
    final inspection = await editing.recovery.inspectOperation(
        operationId: operationId, scope: journal.scope);
    if (inspection?.disposition == AuthoringRecoveryDisposition.completed) {
      return;
    }
    if (inspection == null ||
        inspection.disposition == AuthoringRecoveryDisposition.blocked) {
      throw const AuthoringRecoveryException('recovery.journal_inconsistent',
          'The media transaction cannot be recovered safely in its current state.');
    }
    final pending =
        await readPendingTransactionJournals(gateway, requirePrepared: true);
    if (pending.any((entry) => entry.operationId != operationId)) {
      throw const AuthoringRecoveryException(
          'resource_pack.recovery_required',
          'Reconcile the other pending transactions before recovering this operation.');
    }
    await reader.store.requireProjectDescriptor(reader.descriptor);
    await _requireBattleGifRevisions(_battleGifRevisions(journal.intendedReceipt));
    await _requireScopedMediaRecoveryDependencies(journal);
    final head = await reader.store.readHead();
    if (head == null) {
      throw const CatalogStorageException(
          'catalog.head_unavailable', 'The catalog head is unavailable.');
    }
    final snapshot = (await reader.store.openRoot(head)).snapshot;
    final catalog = await PortableProjectCatalog.fromSnapshot(snapshot,
        metadataFields: {'pokemon'});
    final change = mediaChanges.single;
    if (!isCanonicalPokemonMediaStoragePath(
        catalog.projectMetadata.pokemon.mediaDir,
        change.storageKey,
        change.resource.id.substring('media:'.length))) {
      throw const AuthoringHistoryException(
          'history.pokemon_media_path_changed',
          'The configured media directory no longer matches this history entry.');
    }
  }

  Map<String, String> _battleGifRevisions(AuthoringReceipt receipt) {
    final raw = receipt.extensions['mediaRecoveryDependencies'];
    if (raw is! Map) return const {};
    final result = <String, String>{};
    for (final entry in raw.entries) {
      final path = entry.key;
      if (path is! String ||
          (!path.startsWith('assets/pokemon/battle-gifs/') &&
              !path.startsWith('assets/pokemon/battle-cries/') &&
              !path.startsWith('assets/pokemon/images/'))) {
        continue;
      }
      if (!RegExp(r'^assets/pokemon/(?:battle-gifs/[0-9a-f]{64}\.gif|battle-cries/[0-9a-f]{64}\.(?:wav|mp3)|images/[0-9a-f]{64}\.png)$')
              .hasMatch(path) ||
          entry.value is! String ||
          !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(entry.value as String)) {
        throw const FormatException('Invalid battle GIF dependency.');
      }
      result[path] = entry.value as String;
    }
    return result;
  }

  String? _battleGifMarker(String path) {
    final match = RegExp(r'^assets/pokemon/battle-gifs/([0-9a-f]{64})\.gif$').firstMatch(path);
    if (match != null) return 'catalog/battle-gif-ownership/${match.group(1)}.json';
    final png = RegExp(r'^assets/pokemon/images/([0-9a-f]{64})\.png$').firstMatch(path);
    if (png != null) return 'catalog/pokemon-image-ownership/${png.group(1)}.json';
    final cry = RegExp(r'^assets/pokemon/battle-cries/([0-9a-f]{64})\.(wav|mp3)$').firstMatch(path);
    return cry == null ? null : 'catalog/battle-cry-ownership/${cry.group(1)}.${cry.group(2)}.json';
  }

  Future<void> _requireNoBattleGifWrites(Iterable<String> paths) async {
    for (final path in paths) {
      final canonicalPath = path.toLowerCase();
      final marker = _battleGifMarker(canonicalPath);
      if (marker == null ||
          await reader.store.gateway.readResourceRevision(marker) == null) {
        continue;
      }
      var same = canonicalPath == path;
      if (!same) {
        try {
          same = await FileSystemEntity.identical(
              '${reader.store.projectRoot}/$path',
              '${reader.store.projectRoot}/$canonicalPath');
        } on FileSystemException {
          same = !await File('${reader.store.projectRoot}/$path').exists();
        }
      }
      if (same) {
        throw const FormatException('An imported battle GIF cannot be changed in place.');
      }
    }
  }

  Future<void> _requireBattleGifRevisions(Map<String, String> revisions) async {
    for (final entry in revisions.entries) {
      if (await reader.store.gateway.readResourceRevision(entry.key) !=
          entry.value) {
        throw const AuthoringHistoryException('history.pokemon_gif_changed',
            'A referenced battle GIF is missing or changed.');
      }
    }
  }

  Future<void> _requireScopedMediaRecoveryDependencies(
      AuthoringTransactionJournal journal) async {
    final inventories = journal.intendedReceipt.diff.entries
        .where((entry) =>
            entry.path == '/workshopRevision' &&
            entry.resource.kind == 'catalogHead' &&
            entry.resource.extensions['workshopResourcePaths'] is List)
        .toList();
    if (inventories.length != 1) {
      throw const AuthoringRecoveryException('recovery.dependency_unavailable',
          'The media operation has no recoverable dependency inventory.');
    }
    final expected = journal.scope.actionId == 'pokemon.media.write'
        ? inventories.single.before
        : journal.intendedReceipt.extensions['recoveryReadRevision'];
    if (expected is! String) {
      throw const AuthoringRecoveryException('recovery.dependency_unavailable',
          'The media operation has no retained dependency revision.');
    }
    final rawPaths = inventories.single.resource
        .extensions['workshopResourcePaths'] as List;
    if (rawPaths.any((path) => path is! String) ||
        rawPaths.toSet().length != rawPaths.length) {
      throw const AuthoringRecoveryException('recovery.dependency_unavailable',
          'The media operation has an invalid dependency inventory.');
    }
    final headEntries = journal.entries
        .where((entry) => entry.storageKey == CatalogStorageStore.headStorageKey)
        .toList();
    if (headEntries.length != 1) {
      throw const AuthoringRecoveryException('recovery.dependency_unavailable',
          'The media operation has no recoverable catalog head.');
    }
    final staged = await reader.store.gateway.readStagedPayload(
      operationId: journal.operationId,
      storageKey: CatalogStorageStore.headStorageKey,
      kind: TransactionPayloadKind.before,
    );
    final payload = staged.payload;
    if (payload == null) {
      throw const AuthoringRecoveryException('recovery.dependency_unavailable',
          'The media operation has no valid retained catalog head.');
    }
    final CatalogObjectReference root;
    try {
      if (payload.byteLength > CatalogStorageStore.maximumHeadBytes ||
          payload.resourceRevision != headEntries.single.beforeRevision) {
        throw const FormatException();
      }
      final bytes = await payload.readBytes();
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map || decoded['root'] is! Map) {
        throw const FormatException();
      }
      root = CatalogObjectReference.fromJson(
          Map<String, dynamic>.from(decoded['root'] as Map));
      final canonical = CatalogStorageStore.encodeHead(root);
      if (bytes.length != canonical.length ||
          Iterable<int>.generate(bytes.length)
              .any((index) => bytes[index] != canonical[index])) {
        throw const FormatException();
      }
    } on FormatException {
      throw const AuthoringRecoveryException('recovery.dependency_unavailable',
          'The media operation has no valid retained catalog head.');
    } on TypeError {
      throw const AuthoringRecoveryException('recovery.dependency_unavailable',
          'The media operation has no valid retained catalog head.');
    } finally {
      await payload.release();
    }
    final revisions = <String, String?>{};
    for (final path in rawPaths.cast<String>()) {
      final changes = journal.entries
          .where((entry) => entry.storageKey == path)
          .toList();
      if (changes.length > 1) {
        throw const AuthoringRecoveryException('recovery.dependency_unavailable',
            'The media operation has an ambiguous dependency inventory.');
      }
      revisions[path] = changes.isEmpty
          ? await reader.store.gateway.readResourceRevision(path)
          : changes.single.beforeRevision;
    }
    final current = CatalogWorkshopSelection.fingerprint(
        'sha256:${root.sha256}', revisions);
    if (current != expected) {
      throw const AuthoringRecoveryException('recovery.dependency_changed',
          'A media dependency changed before the operation could be recovered.');
    }
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
    _modelSourceSelection = null;
    _workshopSelection = null;
    _plans.clear();
    _operations.clear();
    _battleGifs.clear();
    _historyBattleGifs.clear();
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
