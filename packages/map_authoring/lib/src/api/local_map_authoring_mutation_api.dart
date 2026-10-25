import '../documents/map_element_order_authoring.dart';
import '../documents/map_editor_authoring.dart';
import '../domains/maps/map_lifecycle_atmosphere.dart';
import '../domains/assets/resource_pack_import_preparer.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:map_core/map_core.dart'
    show
        ProjectManifest,
        ProjectPokemonConfig,
        PokemonRulesetProfile,
        MapEditorState;

import '../contracts/action_descriptor.dart';
import '../catalog_storage/catalog_storage_store.dart';
import '../ports/project_file_reader.dart';
import '../workspace/catalog/catalog_project_reader.dart';
import '../workspace/catalog/catalog_authoring_session.dart';
import '../workspace/catalog/catalog_partition_action.dart';
import '../contracts/artifact_ref.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../contracts/resource_ref.dart';
import '../application/map_mutation_dispatcher.dart';
import '../domains/assets/tiled_image_collection_packer.dart';
import '../history/content_blob_store.dart';
import '../history/file_history_store.dart';
import '../history/history_store.dart';
import '../history/undo_service.dart';
import '../history/revision_revert_service.dart';
import '../history/authoring_history.dart';
import '../parity/full_authoring_parity.dart';
import '../ports/idempotency_store.dart';
import '../ports/artifact_store.dart';
import '../security/audit_log.dart';
import '../security/authoring_permission.dart';
import '../security/authorization_policy.dart';
import '../security/confirmation_token.dart';
import '../security/secure_mutation_executor.dart';
import '../security/secure_recovery_executor.dart';
import '../support/authoring_fingerprint.dart';
import '../support/authoring_timeline.dart';
import '../support/authoring_performance_observer.dart';
import '../transactions/action_planner.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/file_idempotency_store.dart';
import '../transactions/idempotency_ledger.dart';
import '../transactions/journaled_transaction.dart';
import '../transactions/local_transaction_file_gateway.dart';
import '../transactions/plan_store.dart';
import '../transactions/recovery_service.dart';
import '../transactions/revision_set.dart';
import '../transactions/transaction_journal.dart';
import '../workspace/project_snapshot.dart';
import '../workspace/project_snapshot_cache.dart';
import '../workspace/project_snapshot_loader.dart';
import '../workspace/workspace_handle_store.dart';
import '../workspace/workspace_policy.dart';
import 'authoring_mutation_contracts.dart';
import 'authoring_mutation_api.dart';
import 'authoring_result_projection.dart';
import '../infrastructure/local_resource_pack_store.dart';
import '../ports/file_backed_payload_store.dart';

/// Filesystem composition root for secure map mutation sessions.
///
/// Canonical roots are captured only by server-side adapters. They never enter
/// action contracts, receipts, errors, audit records, or JSONL responses.
const _nativeLocalWorkshopActions = {
  'pokemon.ruleset.set', 'campaign.encounter_table.upsert', 'campaign.trainer.upsert',
  'campaign.shop.upsert', 'bag.capacity.set', 'item.create', 'item.update',
  'event_v2.template.apply', 'narrative.publish_document',
};

final class LocalMapAuthoringMutationApi
    implements
        AuthoringMutationApiPort,
        AuthoringWorkshopPort,
        AuthoringMapEditorStatePort,
        AuthoringMapElementOrderPort,
        AuthoringArtifactStagingPort,
        AuthoringMutationServicePort,
        AuthoringArtifactStagingServicePort,
        AuthoringRecoveryStatusPort,
        AuthoringIncompletePreparationDiscardPort,
        AuthoringResultProjectionPort {
  LocalMapAuthoringMutationApi({
    required WorkspacePolicy policy,
    required ProjectSnapshotLoader snapshotLoader,
    MapMutationDispatcher? dispatcher,
    ArtifactStore? artifactStore,
    Iterable<String> resourcePackSourceRoots = const [],
    TiledImageCollectionRasterCodec? tiledImageCollectionRasterCodec,
    AuthoringActor? actor,
    AuthoringSecurityLimits authorizationLimits =
        const AuthoringSecurityLimits(),
    DateTime Function()? clock,
    AuthoringTransactionFaultInjector? faultInjector,
    AuthoringPerformanceObserver? performanceObserver,
    bool retainUndoHistory = true,
    ProjectFileReader catalogFileReader = const LocalProjectFileReader(),
  })  : _catalogFileReader = catalogFileReader,
        _policy = policy,
        _snapshotLoader = snapshotLoader,
        _actor = actor ?? _localActor,
        _authorizationLimits = authorizationLimits,
        _clock = clock ?? _systemClock,
        _faultInjector = faultInjector,
        _retainUndoHistory = retainUndoHistory,
        _resourcePackSourceRoots = List.unmodifiable(resourcePackSourceRoots) {
    artifacts = artifactStore ??
        MemoryArtifactStore(
          maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
        );
    _dispatcher = dispatcher ??
        MapMutationDispatcher.canonical(
          artifactStore: artifacts,
          projectCatalogPartitionBuilder: (context) =>
              _partitionAction(context.snapshot.projectHandle).build(context),
          preparedResourcePackImportResolver: (context, handle) =>
              _session(context.snapshot.projectHandle)
                  ._resourcePacks
                  .buildDraft(context, handle),
          retainedAssetBlobReader: (snapshot, artifact) => _snapshotLoader
              .readRetainedAssetBlob(snapshot.projectHandle, artifact),
          tiledImageCollectionRasterCodec: tiledImageCollectionRasterCodec,
          performanceObserver: performanceObserver,
        );
    _performanceObserver = performanceObserver;
  }

  late final LocalMapEditorAuthoring _mapEditor =
      LocalMapEditorAuthoring(policy: _policy, actor: _actor);

  @override
  Future<MapEditorSnapshot> inspectMapEditor({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
  }) =>
      _mapEditor.inspect(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
      );

  @override
  Future<MapEditorMutation> setMapEditor({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String expectedRevision,
    required MapEditorState state,
    required String operationId,
  }) =>
      _mapEditor.set(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        state: state,
        operationId: operationId,
      );

  @override
  Future<MapEditorMutation> undoMapEditor({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String receiptId,
    required String expectedRevision,
    required String operationId,
  }) =>
      _mapEditor.undoReceipt(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        receiptId: receiptId,
        expectedRevision: expectedRevision,
        operationId: operationId,
      );

  late final LocalMapElementOrderAuthoring _mapElementOrder =
      LocalMapElementOrderAuthoring(policy: _policy, actor: _actor);

  @override
  Future<MapElementOrderSnapshot> inspectMapElementOrder({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
  }) =>
      _mapElementOrder.inspect(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath);

  @override
  Future<MapElementOrderMutation> reorderMapElements({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String expectedRevision,
    required String kind,
    required List<String> frontFirstIds,
    String? layerId,
    required String operationId,
  }) =>
      _mapElementOrder.reorder(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          expectedRevision: expectedRevision,
          kind: kind,
          frontFirstIds: frontFirstIds,
          layerId: layerId,
          operationId: operationId);

  @override
  Future<MapElementOrderMutation> undoMapElementOrder({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String receiptId,
    required String expectedRevision,
    required String operationId,
  }) =>
      _mapElementOrder.undoReceipt(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          receiptId: receiptId,
          expectedRevision: expectedRevision,
          operationId: operationId);

  final List<String> _resourcePackSourceRoots;
  final WorkspacePolicy _policy;
  final ProjectFileReader _catalogFileReader;
  final ProjectSnapshotLoader _snapshotLoader;
  late final MapMutationDispatcher _dispatcher;
  late final ArtifactStore artifacts;
  final AuthoringActor _actor;
  final AuthoringSecurityLimits _authorizationLimits;
  final DateTime Function() _clock;
  final AuthoringTransactionFaultInjector? _faultInjector;
  final bool _retainUndoHistory;
  late final AuthoringPerformanceObserver? _performanceObserver;
  final Map<ProjectHandle, _LocalMapAuthoringSession> _sessions = {};
  final Map<ProjectHandle, CatalogAuthoringSession> _catalogSessions = {};
  final Map<ProjectHandle, CatalogPartitionAction> _partitionActions = {};
  CatalogPartitionAction _partitionAction(ProjectHandle handle) =>
      _partitionActions[handle] ??
      (throw AuthoringPlanException(
          code: "catalog.already_partitioned",
          message: "The project already uses a partitioned catalog."));
  bool isCatalogProject(ProjectHandle handle) =>
      _catalogSessions.containsKey(handle);
  Future<ProjectSnapshot> readWorkshopSnapshot(ProjectHandle handle,
      {required String actionId,
      Map<String, Object?> parameters = const {},
      Map<String, String> readDependencies = const {}}) {
    final session = _catalogSession(handle);
    if (session == null) {
      _session(handle).requireProjectionRead();
      return _snapshotLoader.loadWorkshop(handle, actionId: actionId, parameters: parameters, readDependencies: readDependencies);
    }
    return session.readWorkshopSnapshot(
        actionId: actionId,
        parameters: parameters,
        readDependencies: readDependencies);
  }

  Future<void> prepareWorkshopCatalog(ProjectHandle handle) async {
    final session = _catalogSession(handle);
    if (session == null) {
      await _session(handle).prepareLocalWorkshop();
      return;
    }
    session.requirePreparationAuthorization();
    await _session(handle)._idempotencyStore.prepareIncrementalStorage();
    await session.prepareWorkshopCatalog();
  }

  @override
  Future<Map<String, Object?>> readWorkshopDocument(ProjectHandle projectHandle,
      {required String actionId,
      Map<String, Object?> parameters = const {},
      Map<String, String> readDependencies = const {},
      bool includeDocuments = true}) async {
    final snapshot = await readWorkshopSnapshot(projectHandle,
        actionId: actionId,
        parameters: parameters,
        readDependencies: readDependencies);
    return {
      'snapshotRevision': snapshot.revision,
      if (includeDocuments) 'project': snapshot.manifest.copyWith(settings: snapshot.manifest.settings.copyWith(mistralApiKey: null)).toJson(),
      if (includeDocuments) 'maps': [for (final map in snapshot.maps) map.toJson()],
      'resourceRevisions': snapshot.resourceFingerprints,
      'availableProjectSections': snapshot.availableProjectSections?.toList(),
      'availableProjectDocuments': {
        for (final entry in snapshot.availableProjectDocuments?.entries ??
            const <MapEntry<String, Set<String>>>[])
          entry.key: entry.value.toList()
      },
      'planExtensions': {
        'workshopScope': true,
        if (readDependencies.isNotEmpty)
          'workshopReadDependencies': readDependencies
      },
    };
  }

  @override
  Future<Map<String, Object?>> prepareWorkshopDocument(
      ProjectHandle projectHandle) async {
    await prepareWorkshopCatalog(projectHandle);
    final catalog = _catalogSession(projectHandle);
    final current = catalog == null ? null : await CatalogProjectReader.open(
        store: catalog.reader.store, descriptor: catalog.reader.descriptor, metadataFields: {});
    return {'prepared': true, if (current != null) 'snapshotRevision': current.revision,
      'scope': catalog == null ? 'explicitLocalDocumentHistoryAndIdempotency' : 'explicitCatalogAdmissionAndLocalEditingIndexes'};
  }

  Future<bool> catalogProjectReadOnly(ProjectHandle handle) async {
    final session = _catalogSession(handle);
    if (session == null) return false;
    session.requireRead();
    return session.reader.readOnly ||
        (await session.reader.store.gateway.listJournals()).any((journal) =>
            journal.status != AuthoringTransactionStatus.committed &&
            journal.status != AuthoringTransactionStatus.compensated &&
            journal.entries.any((entry) =>
                entry.storageKey == CatalogStorageStore.headStorageKey));
  }

  CatalogAuthoringSession? _catalogSession(ProjectHandle handle) {
    _snapshotLoader.requireActiveProject(handle);
    return _catalogSessions[handle];
  }

  final Map<WorkspaceHandle, ProjectHandle> _projectsByWorkspace = {};
  final Set<(ProjectHandle, String)> _modelBatchStagingPlans = {};

  String resourcePackInitialRevision(ProjectHandle projectHandle) =>
      _session(projectHandle).initialRevision;

  void requireResourcePackRead(ProjectHandle projectHandle) =>
      _session(projectHandle).requireProjectionRead();

  void requireResourcePackExport(ProjectHandle projectHandle) {
    final session = _session(projectHandle);
    session.requireProjectionRead();
    if (!session._actor.allows(AuthoringPermissionScope.exportRun)) {
      throw const AuthoringAuthorizationException(
        code: 'authorization.permission_denied',
        message: 'Resource pack export requires export.run permission.',
      );
    }
  }

  ResourcePackImportPreparer resourcePackImports(ProjectHandle projectHandle) =>
      _session(projectHandle)._resourcePacks;
  LocalResourcePackStore resourcePackPayloadStore(
          ProjectHandle projectHandle) =>
      _session(projectHandle)._projectionPayloadStore;

  @override
  AuthoringMutationDescription describeMutationContracts() =>
      AuthoringMutationDescription(
        commands: const [
          AuthoringMutationCommandDescriptor(
            id: 'apply',
            summary: 'Apply a frozen mutation plan.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'confirm',
            summary: 'Confirm one destructive plan.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'history',
            summary: 'List committed history entries.',
          ),
          AuthoringMutationCommandDescriptor(
              id: 'workshop_snapshot',
              summary:
                  'Read only the canonical documents and dependencies needed for a local catalog mutation.'),
          AuthoringMutationCommandDescriptor(
              id: 'workshop_prepare',
              summary:
                  'Explicitly prepare catalog admission, metadata indexes and retained local history before editing an older or copied project.'),
          AuthoringMutationCommandDescriptor(
            id: 'plan',
            summary: 'Plan and preview a map mutation.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'projection',
            summary:
                'Read receipt by receiptId, diff by diffRef (limit 1..200, default 200), or payload by payloadRef (offset >= 0; byteLength 1..131072, default 131072); responses are bounded to 262144 bytes.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'recover',
            summary: 'Resume a recoverable transaction.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'discard_preparation',
            summary:
                'Discard an uncommitted incomplete preparation without changing project data.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'recovery_status',
            summary: 'Inspect a durable operation without reapplying it.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'stage_artifact',
            summary: 'Securely stage a local file for an asset mutation.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'undo',
            summary: 'Undo one committed history entry.',
          ),
        ],
        actions: _dispatcher.descriptors,
        fullParity: AuthoringFullParityCatalog.canonical(),
      );

  @override
  Map<String, Object?> describeMutations() =>
      describeMutationContracts().toJson();

  @override
  Future<AuthoringArtifactStageResult> stageArtifactFile({
    required String sourcePath,
    String? declaredMediaType,
  }) async {
    final store = artifacts;
    if (store is! ArtifactFileStager) {
      throw const ArtifactStoreException(
        'artifact.file_staging_unsupported',
        'The configured artifact store cannot stage local files.',
      );
    }
    final stager = store as ArtifactFileStager;
    final stored = await stager.importFile(
      sourcePath,
      declaredMediaType: declaredMediaType,
    );
    return AuthoringArtifactStageResult(
      reference: stored.reference,
      deduplicated: stored.deduplicated,
    );
  }

  @override
  Future<Map<String, Object?>> stageArtifact({
    required String sourcePath,
    String? declaredMediaType,
  }) async =>
      (await stageArtifactFile(
        sourcePath: sourcePath,
        declaredMediaType: declaredMediaType,
      ))
          .toJson();

  @override
  Future<void> attachProject({
    required String projectRootPath,
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
  }) async {
    if (_sessions.containsKey(projectHandle) ||
        _catalogSessions.containsKey(projectHandle) ||
        _projectsByWorkspace.containsKey(workspaceHandle)) {
      throw const WorkspaceHandleException(
        'workspace.mutation_session_exists',
        'A mutation session is already attached to these handles.',
      );
    }
    final canonicalRoot = await _policy.authorizeProjectRoot(projectRootPath);
    await _snapshotLoader.requireMutationRoot(projectHandle, canonicalRoot);
    final manifestFile = File(_joinAll([canonicalRoot, 'project.json']));
    if (await manifestFile.length() <= 4096) {
      final manifestBytes = await manifestFile.readAsBytes();
      final json = jsonDecode(utf8.decode(manifestBytes));
      if (json is Map &&
          const {'avelune.working-catalog', 'avelune.portable-catalog'}
              .contains(json['format'])) {
        if (!_retainUndoHistory) _requireFreshBootstrap();
        if (await _snapshotLoader.resourcePackManifestRevision(projectHandle) !=
            computeAuthoringBytesFingerprint(manifestBytes,
                logicalName: 'project.json')) {
          throw const WorkspaceHandleException(
              'workspace.mutation_binding_mismatch',
              'The catalog root differs from the opened project.');
        }
        final reader = await CatalogProjectReader.open(
            store: CatalogStorageStore(
                projectRoot: canonicalRoot,
                reader: _catalogFileReader,
                gateway: await LocalTransactionFileGateway.open(
                    projectRoot: canonicalRoot,
                    performanceObserver: _performanceObserver)),
            descriptor: Map<String, Object?>.from(json),
            allowRecoveryBootstrap: true,
            metadataFields: {});
        if (!reader!.readOnly) {
          _sessions[projectHandle] = await _LocalMapAuthoringSession.open(
              canonicalProjectRoot: canonicalRoot,
              resourcePackSourceRoots: _resourcePackSourceRoots,
              initialRevision: reader.revision,
              projectId: reader.projectId,
              workspaceHandle: workspaceHandle,
              projectHandle: projectHandle,
              snapshotLoader: _snapshotLoader,
              dispatcher: _dispatcher,
              actor: _actor,
              authorizationLimits: _authorizationLimits,
              clock: _clock,
              retainUndoHistory: _retainUndoHistory,
              maintainIdempotencyOnOpen: false,
              faultInjector: _faultInjector,
              performanceObserver: _performanceObserver);
        }
        _catalogSessions[projectHandle] = CatalogAuthoringSession(
            reader: reader,
            projectHandle: projectHandle,
            workspaceHandle: workspaceHandle,
            actor: _actor,
            requireActive: () =>
                _snapshotLoader.requireActiveProject(projectHandle),
            dispatcher: _dispatcher,
            resolveAction: (id) => _resolveHistoryOrAction(_dispatcher, id),
            inspectHistoryReplay: (operationId, actionId, entryId) =>
                _inspectCatalogHistoryReplay(
                    projectHandle, operationId, actionId, entryId),
            loadProject: () => _snapshotLoader.load(projectHandle),
            buildProjectPlan: (request) =>
                _session(projectHandle).planMutation(request),
            buildScopedProjectPlan: (request, snapshot) =>
                _session(projectHandle)
                    .planMutation(request, suppliedSnapshot: snapshot),
            discardProjectPlan: (planId) =>
                _session(projectHandle)._plans.discard(planId),
            inspectReplay: (planId, operationId) =>
                _inspectCatalogReplay(projectHandle, planId, operationId),
            prepareApply: (plan, operationId) async {
              if (plan.request.actionId == 'resource_pack.import') {
                await _session(projectHandle)._resourcePacks.certifyCatalogPlan(
                    plan: plan,
                    actorId: _actor.actorId,
                    projectId: reader.projectId,
                    operationId: operationId,
                    store: reader.store);
              }
            },
            requirePlanPreconditions: (plan) async {
              if (plan.request.actionId == 'resource_pack.import') {
                await _session(projectHandle)
                    ._resourcePacks
                    .requireCatalogPlanPreconditions(plan, store: reader.store);
              }
            },
            projections:
                reader.readOnly ? null : _session(projectHandle)._projections,
            auditOutcome: (plan, decision, receipt, error, details) =>
                _session(projectHandle)._executor.auditMutationOutcome(
                    actor: _actor,
                    projectId: reader.projectId,
                    action: _resolveHistoryOrAction(_dispatcher, plan.request.actionId),
                    plan: plan,
                    decision: decision,
                    receipt: receipt,
                    error: error,
                    details: details),
            clock: _clock,
            limits: _authorizationLimits,
            faultInjector: _faultInjector);
        _projectsByWorkspace[workspaceHandle] = projectHandle;
        return;
      }
    }
    if (!_retainUndoHistory) await _requireFreshBootstrapRoot(canonicalRoot);
    final initialGateway = await LocalTransactionFileGateway.open(
      projectRoot: canonicalRoot,
    );
    final initialRevision = await _snapshotLoader.resourcePackManifestRevision(projectHandle);
    if (await initialGateway.readResourceRevision('project.json') != initialRevision) {
      throw const WorkspaceHandleException('workspace.mutation_binding_mismatch',
          'The mutation root differs from the opened project.');
    }
    final projectId = _projectIdentity(canonicalRoot);
    final session = await traceAuthoringPhase(
      'authoring.session.open',
      () => _LocalMapAuthoringSession.open(
        canonicalProjectRoot: canonicalRoot,
        resourcePackSourceRoots: _resourcePackSourceRoots,
        initialRevision: initialRevision,
        projectId: projectId,
        workspaceHandle: workspaceHandle,
        projectHandle: projectHandle,
        snapshotLoader: _snapshotLoader,
        dispatcher: _dispatcher,
        actor: _actor,
        authorizationLimits: _authorizationLimits,
        clock: _clock,
        faultInjector: _faultInjector,
        performanceObserver: _performanceObserver,
        retainUndoHistory: _retainUndoHistory,
      ),
    );
    _sessions[projectHandle] = session;
    _partitionActions[projectHandle] = CatalogPartitionAction(
        store: await CatalogStorageStore.open(projectRoot: canonicalRoot),
        projectId: projectId);
    _projectsByWorkspace[workspaceHandle] = projectHandle;
  }

  Future<AuthoringReceipt?> _inspectCatalogReplay(
      ProjectHandle handle, String planId, String operationId) async {
    final session = _session(handle);
    return session._executor.inspectDurableReplay(
        actor: _actor,
        projectId: session.projectId,
        planId: planId,
        operationId: operationId,
        lookup: () => session._idempotencyStore.lookupOperation(
            actorId: _actor.actorId,
            projectId: session.projectId,
            operationId: operationId,
            now: session._plans.now),
        readHistory: (entryId) => session._history
            .get(projectId: session.projectId, entryId: entryId),
        resolveAction: (id) => _resolveHistoryOrAction(_dispatcher, id));
  }

  Future<AuthoringReceipt?> _inspectCatalogHistoryReplay(ProjectHandle handle,
      String operationId, String actionId, String entryId) async {
    final session = _session(handle);
    final found = await session._idempotencyStore.lookupOperation(
        actorId: _actor.actorId,
        projectId: session.projectId,
        operationId: operationId,
        now: session._plans.now);
    if (found == null) return null;
    final receipt = found.completed?.receipt;
    if (receipt == null) {
      throw const AuthoringRecoveryException('idempotency.recovery_required',
          'This historical operation requires canonical recovery.');
    }
    final context = AuthoringHistoryContext.fromExtensions(receipt.extensions);
    if (receipt.actionId != actionId || context.targetEntryId != entryId) {
      throw const AuthoringHistoryException('history.replay_context_mismatch',
          'The historical operation identity differs.');
    }
    return _inspectCatalogReplay(
        handle, receipt.extensions['planId'] as String, operationId);
  }

  @override
  Future<bool> detachWorkspace(WorkspaceHandle workspaceHandle) async {
    final projectHandle = _projectsByWorkspace.remove(workspaceHandle);
    if (projectHandle == null) return false;
    await _sessions.remove(projectHandle)?.dispose();
    await _partitionActions.remove(projectHandle)?.close();
    await _catalogSessions.remove(projectHandle)?.close();
    return true;
  }

  @override
  Future<AuthoringMutationPlanResult> planMutation(
    ProjectHandle projectHandle,
    AuthoringRequest request,
  ) async {
    final catalog = _catalogSession(projectHandle);
    if (catalog != null) return catalog.plan(request);
    final result = await _session(projectHandle)
        .planMutation(request)
        .whenComplete(() =>
            _partitionActions[projectHandle]?.flushRetired() ??
            Future<void>.value());
    if ({
          'model3d.import_batch',
          'model3d.source.replace_batch',
          'smart_tile.preset.draft.import'
        }.contains(request.actionId) &&
        result.applicable &&
        !result.plan.appliedPayloadReleased) {
      _modelBatchStagingPlans.add((projectHandle, result.planId));
    }
    return result;
  }

  @override
  Future<Map<String, Object?>> plan(
    ProjectHandle projectHandle,
    AuthoringRequest request,
  ) async =>
      (await planMutation(projectHandle, request)).toJson();

  @override
  Future<AuthoringMutationConfirmationResult> confirmMutation(
    ProjectHandle projectHandle, {
    required String planId,
  }) async {
    final catalog = _catalogSession(projectHandle);
    return catalog != null
        ? catalog.confirm(planId)
        : _session(projectHandle).confirmMutation(planId);
  }

  @override
  Future<Map<String, Object?>> confirm(
    ProjectHandle projectHandle, {
    required String planId,
  }) async =>
      (await confirmMutation(projectHandle, planId: planId)).toJson();

  @override
  Future<AuthoringMutationResult> applyMutation(
    ProjectHandle projectHandle, {
    required String planId,
    required String operationId,
    String? confirmationToken,
    AuthoringTransactionPrecondition? precondition,
    void Function()? beforeReservation,
    void Function()? preparationCheck,
  }) async {
    final catalog = _catalogSession(projectHandle);
    if (catalog != null) {
      return catalog.apply(
          planId: planId,
          operationId: operationId,
          confirmationToken: confirmationToken,
          precondition: precondition,
          beforeReservation: beforeReservation,
          preparationCheck: preparationCheck);
    }
    final partition = _partitionActions[projectHandle];
    final result = await _session(projectHandle).applyMutation(
      planId: planId,
      operationId: operationId,
      confirmationToken: confirmationToken,
      precondition: () async {
        if (partition?.containsPlan(planId) ?? false) {
          await partition!.requireApply(planId, operationId);
        }
        await precondition?.call();
      },
      beforeReservation: beforeReservation,
      preparationCheck: preparationCheck,
    );
    await partition?.flushRetired();
    if (result.receipt.actionId == 'project.catalog.partition') {
      await partition?.releaseOperation(operationId);
      await _session(projectHandle)._idempotencyStore.prepareIncrementalStorage();
      final history = _session(projectHandle)._history;
      if (history is FileAuthoringHistoryStore) await history.prepareLocalHistory();
    }
    await _releasePresentationMediaStaging(projectHandle, result);
    return result;
  }

  @override
  Future<Map<String, Object?>> apply(
    ProjectHandle projectHandle, {
    required String planId,
    required String operationId,
    String? confirmationToken,
  }) async =>
      (await applyMutation(
        projectHandle,
        planId: planId,
        operationId: operationId,
        confirmationToken: confirmationToken,
      ))
          .toJson();

  Future<Map<String, Object?>> resourcePackExportPayload(
    ProjectHandle projectHandle,
    StoredFilePayload payload, {
    void Function()? checkCancelled,
  }) {
    final session = _session(projectHandle);
    session.requireProjectionRead();
    return session._projections.projectBinaryPayload(
      payload,
      checkCancelled: checkCancelled,
    );
  }

  Future<bool> resourcePackReleaseExportPayload(
    ProjectHandle projectHandle,
    String ref,
  ) =>
      _sessions[projectHandle]?._projections.releasePayload(ref) ??
      Future.value(false);

  Future<AuthoringMutationResult> resourcePackHistory(
    ProjectHandle projectHandle, {
    required String operation,
    required String entryId,
    required String operationId,
    required String expectedRevision,
    String? expectedHeadEntryId,
    void Function()? beforeReservation,
    void Function()? preparationCheck,
  }) async {
    final catalog = _catalogSession(projectHandle);
    if (catalog != null) {
      return catalog.projectHistory(
          operation: operation,
          entryId: entryId,
          operationId: operationId,
          expectedRevision: expectedRevision,
          expectedHeadEntryId: expectedHeadEntryId,
          beforeReservation: beforeReservation,
          preparationCheck: preparationCheck);
    }
    return _session(projectHandle).resourcePackHistory(
        operation: operation,
        entryId: entryId,
        operationId: operationId,
        expectedRevision: expectedRevision,
        expectedHeadEntryId: expectedHeadEntryId,
        beforeReservation: beforeReservation,
        preparationCheck: preparationCheck);
  }

  Future<List<AuthoringRecoveryInspection>> resourcePackPending(
    ProjectHandle projectHandle,
  ) =>
      _session(projectHandle)._recovery.inspect();

  @override
  Future<Map<String, Object?>> recoveryStatus(
    ProjectHandle projectHandle, {
    required String operationId,
  }) async {
    _snapshotLoader.requireActiveProject(projectHandle);
    final catalog = _catalogSession(projectHandle);
    if (catalog != null) catalog.requireRead();
    if (catalog?.reader.readOnly ?? false) {
      return catalog!.recoveryStatus(operationId);
    }
    final session = _session(projectHandle);
    final identity = _safeIdentity(operationId, 'operationId');
    session.requireProjectionRead();
    final found = await session._idempotencyStore.lookupOperation(
      actorId: _actor.actorId,
      projectId: session.projectId,
      operationId: identity,
      now: session._plans.now,
    );
    if (found == null) {
      return {'operationId': identity, 'disposition': 'notFound'};
    }
    final inspection = await session._recovery.inspectOperation(
      operationId: identity,
      scope: found.scope,
    );
    if (inspection != null) return inspection.toJson();
    final receipt = found.completed?.receipt;
    return {
      'operationId': identity,
      'disposition': receipt == null ? 'blocked' : 'completed',
      'committed': receipt == null
          ? null
          : receipt.extensions['recoveryOutcome'] != 'compensated',
      'recoverable': false,
      'finalized': receipt != null,
      if (receipt != null) 'receiptId': receipt.receiptId,
    };
  }

  @override
  Future<AuthoringIncompletePreparationDiscardResult>
      discardIncompletePreparation(
    ProjectHandle projectHandle, {
    required String operationId,
  }) =>
          _session(projectHandle).discardIncompletePreparation(operationId);

  Future<bool> resourcePackRequiresJob(
    ProjectHandle projectHandle, {
    required String operation,
    String? planId,
    String? operationId,
    String? entryId,
  }) async {
    final catalog = _catalogSession(projectHandle);
    if (catalog?.reader.readOnly ?? false) return false;
    if (catalog != null && operation == 'apply') {
      final session = _session(projectHandle);
      final found = await session._idempotencyStore.lookupOperation(
          actorId: _actor.actorId,
          projectId: session.projectId,
          operationId: _safeIdentity(operationId!, 'operationId'),
          now: session._plans.now);
      if (found == null) {
        final plan = catalog.activePlan(_safeIdentity(planId!, 'planId'));
        return plan.request.actionId == 'resource_pack.import' ||
            plan.bulkCapability != null;
      }
    }
    return _session(projectHandle).resourcePackRequiresJob(
        operation: operation,
        planId: planId,
        operationId: operationId,
        entryId: entryId);
  }

  Future<AuthoringMutationResult> resourcePackRecover(
    ProjectHandle projectHandle, {
    required String operationId,
    void Function()? beforeRecovery,
  }) async {
    final catalog = _catalogSession(projectHandle);
    if (catalog != null) {
      beforeRecovery?.call();
      return catalog.recover(operationId);
    }
    return _session(projectHandle)
        .recoverMutation(operationId, beforeRecovery: beforeRecovery);
  }

  @override
  Future<AuthoringMutationResult> undoMutation(
    ProjectHandle projectHandle, {
    required String entryId,
    required String idempotencyKey,
  }) async {
    final catalog = _catalogSession(projectHandle);
    return catalog != null
        ? catalog.undo(entryId: entryId, idempotencyKey: idempotencyKey)
        : _session(projectHandle)
            .undoMutation(entryId: entryId, idempotencyKey: idempotencyKey);
  }

  @override
  Future<Map<String, Object?>> undo(
    ProjectHandle projectHandle, {
    required String entryId,
    required String idempotencyKey,
  }) async =>
      (await undoMutation(
        projectHandle,
        entryId: entryId,
        idempotencyKey: idempotencyKey,
      ))
          .toJson();

  @override
  Future<AuthoringMutationHistoryResult> listMutationHistory(
    ProjectHandle projectHandle, {
    required int limit,
    String? cursor,
  }) async {
    final catalog = _catalogSession(projectHandle);
    return catalog != null
        ? catalog.history(limit: limit, cursor: cursor)
        : _session(projectHandle)
            .listMutationHistory(limit: limit, cursor: cursor);
  }

  @override
  Future<Map<String, Object?>> history(
    ProjectHandle projectHandle, {
    required int limit,
    String? cursor,
  }) async =>
      (await listMutationHistory(
        projectHandle,
        limit: limit,
        cursor: cursor,
      ))
          .toJson();

  @override
  Future<AuthoringMutationResult> recoverMutation(
    ProjectHandle projectHandle, {
    required String operationId,
  }) async {
    final catalog = _catalogSession(projectHandle);
    if (catalog != null) return catalog.recover(operationId);
    final result = await _session(projectHandle).recoverMutation(operationId);
    if (result.receipt.actionId == 'project.catalog.partition') {
      final session = _session(projectHandle);
      final found = await session._idempotencyStore.lookupOperation(
          actorId: _actor.actorId,
          projectId: session.projectId,
          operationId: operationId,
          now: session._plans.now);
      if (found != null) {
        await session._executor.cleanupRecoveredMutation(
            scope: found.scope,
            planId: result.receipt.extensions['planId'] as String,
            operationId: operationId,
            receipt: result.receipt);
      }
      await _partitionActions[projectHandle]?.releaseOperation(operationId);
    }
    await _releasePresentationMediaStaging(projectHandle, result);
    return result;
  }

  @override
  Future<Map<String, Object?>> recover(
    ProjectHandle projectHandle, {
    required String operationId,
  }) async =>
      (await recoverMutation(projectHandle, operationId: operationId)).toJson();

  @override
  Future<Map<String, Object?>> reprojectMutationReceipt(
      ProjectHandle projectHandle,
      {required String receiptId}) async {
    final session = _session(projectHandle);
    session.requireProjectionRead();
    final entry = await session._history
        .get(projectId: session.projectId, entryId: receiptId);
    if (entry == null) {
      throw const AuthoringProjectionException('projection.receipt_unavailable',
          'The canonical mutation receipt is unavailable.');
    }
    return (await session._mutationResult(entry.receipt)).toJson();
  }

  @override
  Future<Map<String, Object?>> readMutationDiffPage(ProjectHandle projectHandle,
      {required String diffRef,
      String? cursor,
      int limit = authoringProjectionMaxRows}) {
    final session = _session(projectHandle);
    session.requireProjectionRead();
    return session._projections
        .readDiffPage(diffRef: diffRef, cursor: cursor, limit: limit);
  }

  @override
  Future<AuthoringProjectionChunk> readMutationPayloadChunk(
      ProjectHandle projectHandle,
      {required String payloadRef,
      required int offset,
      int byteLength = authoringProjectionMaxChunkBytes}) {
    final session = _session(projectHandle);
    session.requireProjectionRead();
    return session._projections.readPayloadChunk(
        payloadRef: payloadRef, offset: offset, byteLength: byteLength);
  }

  _LocalMapAuthoringSession _session(ProjectHandle projectHandle) {
    final session = _sessions[projectHandle];
    if (session == null) {
      throw const WorkspaceHandleException(
        'workspace.mutation_session_unknown',
        'The requested mutation session is unknown.',
      );
    }
    _snapshotLoader.requireActiveProject(projectHandle);
    return session;
  }

  Future<void> _releasePresentationMediaStaging(
    ProjectHandle projectHandle,
    AuthoringMutationResult result,
  ) async {
    if (!{
      'presentationMedia.import',
      'model3d.import',
      'model3d.import_batch',
      'model3d.source.replace',
      'model3d.source.replace_batch',
      'smart_tile.preset.draft.import',
    }.contains(result.receipt.actionId)) {
      return;
    }
    if ({
      'model3d.import_batch',
      'model3d.source.replace_batch',
      'smart_tile.preset.draft.import'
    }.contains(result.receipt.actionId)) {
      final planId = result.receipt.extensions['planId'];
      if (planId is! String ||
          !_modelBatchStagingPlans.remove((projectHandle, planId))) {
        return;
      }
    }
    for (final artifact in result.receipt.artifacts) {
      await artifacts.release(artifact.uri);
    }
  }


}

Never _requireFreshBootstrap() => throw const WorkspaceHandleException(
    'workspace.undo_history_requires_fresh_bootstrap',
    'Disabling undo history requires an untouched empty project created by the canonical project service.');

Future<void> _requireFreshBootstrapRoot(String root) async {
  try {
    const directories = {
      '.pokemap',
      '.pokemap/authoring',
      '.pokemap/authoring/transactions'
    };
    const files = {
      'project.json',
      '.pokemap/authoring/idempotency.jsonl',
      '.pokemap/authoring/idempotency.jsonl.lock',
      '.pokemap/authoring/transactions/write.lock'
    };
    await for (final entry
        in Directory(root).list(recursive: true, followLinks: false)) {
      final relative = entry.path
          .substring(root.length + 1)
          .split(Platform.pathSeparator)
          .join('/');
      if (!(entry is Directory && directories.contains(relative)) &&
          !(entry is File && files.contains(relative))) {
        _requireFreshBootstrap();
      }
    }
    final manifestBytes =
        await File(_joinAll([root, 'project.json'])).readAsBytes();
    final manifest = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>);
    final empty = ProjectManifest(
        name: manifest.name,
        version: manifest.version,
        maps: const [],
        tilesets: const [],
        settings: manifest.settings,
        pokemon: const ProjectPokemonConfig(
            enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1));
    if (manifest != empty) _requireFreshBootstrap();
    final ledger =
        File(_joinAll([root, '.pokemap', 'authoring', 'idempotency.jsonl']));
    if (await ledger.length() > 65536) _requireFreshBootstrap();
    final lines = await ledger.readAsLines();
    if (lines.length != 2) _requireFreshBootstrap();
    final records = <AuthoringIdempotencyRecord>[];
    for (final line in lines) {
      final event = jsonDecode(line) as Map<String, dynamic>;
      if (event.length != 3 ||
          event['schemaVersion'] != 1 ||
          event['event'] != 'put') {
        _requireFreshBootstrap();
      }
      records.add(AuthoringIdempotencyRecord.fromJson(
          Map<String, dynamic>.from(event['record'] as Map)));
    }
    final pending = records.first, completed = records.last;
    final receipt = completed.receipt;
    if (pending.status != AuthoringIdempotencyStatus.pending ||
        completed.status != AuthoringIdempotencyStatus.completed ||
        pending.scope.storageKey != completed.scope.storageKey ||
        pending.operationId != completed.operationId ||
        pending.payloadFingerprint != completed.payloadFingerprint ||
        completed.scope.actorId != 'project-creator' ||
        completed.scope.actionId != 'project.create' ||
        completed.scope.actionVersion != 1 ||
        !completed.scope.matchesKey(completed.operationId) ||
        receipt == null ||
        receipt.status != AuthoringReceiptStatus.applied ||
        receipt.actionId != 'project.create' ||
        receipt.actionVersion != 1 ||
        receipt.requestId != completed.operationId ||
        receipt.extensions['operationId'] != completed.operationId ||
        receipt.diff.entries.length != 1 ||
        receipt.diff.entries.single.resource.kind != 'project' ||
        receipt.diff.entries.single.resource.id != completed.scope.projectId) {
      _requireFreshBootstrap();
    }
    final current = AuthoringRevisionSet([
      AuthoringResourceRevision(
          resource: AuthoringResourceRef(
              kind: 'project', id: completed.scope.projectId),
          revision: computeAuthoringBytesFingerprint(manifestBytes,
              logicalName: 'project.json'))
    ]);
    if (receipt.afterRevision != current.fingerprint) _requireFreshBootstrap();
  } on WorkspaceHandleException {
    rethrow;
  } on Object {
    _requireFreshBootstrap();
  }
}

final class _LocalMapAuthoringSession {
  _LocalMapAuthoringSession._({
    required this.projectId,
    required this.initialRevision,
    required this.workspaceHandle,
    required this.projectHandle,
    required ProjectSnapshotLoader snapshotLoader,
    required MapMutationDispatcher dispatcher,
    required AuthoringActor actor,
    required AuthoringPlanStore plans,
    required AuthoringActionPlanner planner,
    required AuthoringAuthorizationPolicy policy,
    required AuthoringConfirmationStore confirmations,
    required SecureAuthoringMutationExecutor executor,
    required AuthoringUndoService undoService,
    required AuthoringRevisionRevertService revertService,
    required AuthoringRecoveryService recovery,
    required AuthoringHistoryStore history,
    required AuthoringContentBlobStore historyBlobs,
    required SecureAuthoringRecoveryExecutor recoveryExecutor,
    required AuthoringPerformanceObserver? performanceObserver,
    required AuthoringResultProjectionStore projections,
    required LocalResourcePackStore projectionPayloadStore,
    required LocalTransactionFileGateway mapAtmosphereGateway,
    required MapAtmosphereResourceProbe mapAtmosphereProbe,
    required ResourcePackImportPreparer resourcePacks,
    required FileIdempotencyStore idempotencyStore,
  })  : _snapshotLoader = snapshotLoader,
        _dispatcher = dispatcher,
        _actor = actor,
        _plans = plans,
        _planner = planner,
        _policy = policy,
        _confirmations = confirmations,
        _executor = executor,
        _undoService = undoService,
        _revertService = revertService,
        _recovery = recovery,
        _history = history,
        _historyBlobs = historyBlobs,
        _recoveryExecutor = recoveryExecutor,
        _performanceObserver = performanceObserver,
        _projections = projections,
        _projectionPayloadStore = projectionPayloadStore,
        _mapAtmosphereGateway = mapAtmosphereGateway,
        _mapAtmosphereProbe = mapAtmosphereProbe,
        _resourcePacks = resourcePacks,
        _idempotencyStore = idempotencyStore;

  static Future<_LocalMapAuthoringSession> open({
    required String canonicalProjectRoot,
    required List<String> resourcePackSourceRoots,
    required String initialRevision,
    required String projectId,
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
    required ProjectSnapshotLoader snapshotLoader,
    required MapMutationDispatcher dispatcher,
    required AuthoringActor actor,
    required AuthoringSecurityLimits authorizationLimits,
    required DateTime Function() clock,
    AuthoringTransactionFaultInjector? faultInjector,
    AuthoringPerformanceObserver? performanceObserver,
    bool retainUndoHistory = true,
    bool maintainIdempotencyOnOpen = false,
  }) async {
    final gateway = await LocalTransactionFileGateway.open(
      projectRoot: canonicalProjectRoot,
      performanceObserver: performanceObserver,
    );
    Future<ProjectResourceProbe> mapAtmosphereProbe(String path) =>
        const LocalProjectFileReader().probeResource(
          projectRoot: canonicalProjectRoot,
          relativePath: path,
        );
    final history = await FileAuthoringHistoryStore.open(
      projectRoot: canonicalProjectRoot,
      incrementalWrites: !maintainIdempotencyOnOpen,
    );
    final blobs = await FileAuthoringContentBlobStore.open(
      projectRoot: canonicalProjectRoot,
    );
    final recorder = retainUndoHistory
        ? AuthoringHistoryRecorder(store: history, blobs: blobs)
        : null;
    final audit = await FileAuthoringAuditLog.open(
      projectRoot: canonicalProjectRoot,
    );
    final plans = AuthoringPlanStore(clock: clock);
    final planner = AuthoringActionPlanner(
        store: plans,
        tokenFactory: maintainIdempotencyOnOpen ? null : _catalogPlanIdentity);
    final idempotencyStore = FileIdempotencyStore(
        incrementalWrites: !maintainIdempotencyOnOpen,
        filePath: _joinAll([
          canonicalProjectRoot,
          '.pokemap',
          'authoring',
          'idempotency.jsonl'
        ]),
        performanceObserver: performanceObserver);
    final idempotency =
        AuthoringIdempotencyLedger(store: idempotencyStore, clock: clock);
    // The ledger is append-only, so nothing reclaims a completed reservation
    // unless maintenance runs. Opening a project is the one moment that is
    // already off the interactive path; a failure here must not deny the open.
    if (maintainIdempotencyOnOpen) {
      try {
        await traceAuthoringPhase(
          'authoring.session.prune_idempotency',
          idempotency.pruneExpired,
        );
      } on Object {
        // Maintenance is best effort: a locked or unreadable ledger is reported
        // by the first real mutation, not by refusing to open the project.
      }
    }
    final transaction = JournaledAuthoringTransaction(
      plans: plans,
      gateway: gateway,
      idempotency: idempotency,
      clock: clock,
      faultInjector: faultInjector,
      commitHook: recorder,
    );
    final confirmations = AuthoringConfirmationStore(clock: clock);
    final policy = AuthoringAuthorizationPolicy(
      confirmations: confirmations,
      limits: authorizationLimits,
      clock: clock,
    );
    final executor = SecureAuthoringMutationExecutor(
      transaction: transaction,
      policy: policy,
      auditLog: audit,
      clock: clock,
      auditIdFactory: () => _secureIdentity('audit_'),
    );
    final undoService = AuthoringUndoService(
      history: history,
      blobs: blobs,
      gateway: gateway,
      planner: planner,
      policy: policy,
      executor: executor,
      tokenFactory: _secureIdentity,
    );
    final recovery = AuthoringRecoveryService(
      gateway: gateway,
      idempotency: idempotency,
      clock: clock,
      commitHook: recorder,
      mutationGuard: () => snapshotLoader.requireActiveProject(projectHandle),
    );
    final recoveryExecutor = SecureAuthoringRecoveryExecutor(
      discardPreparation: (operationId) =>
          recovery.discardIncompletePreparation(
        operationId,
        expectedActorId: actor.actorId,
        expectedProjectId: projectId,
        precondition: () => snapshotLoader.requireActiveProject(projectHandle),
      ),
      recover: (operationId) async {
        final found = await idempotencyStore.lookupOperation(
          actorId: actor.actorId,
          projectId: projectId,
          operationId: operationId,
          now: clock().toUtc(),
        );
        if (found?.completed?.receipt != null) {
          final receipt = found!.completed!.receipt!;
          final replay = await executor.inspectDurableReplay(
            actor: actor,
            projectId: projectId,
            planId: receipt.extensions['planId'] as String,
            operationId: operationId,
            lookup: () async => found,
            readHistory: (entryId) =>
                history.get(projectId: projectId, entryId: entryId),
            resolveAction: (id) => _resolveHistoryOrAction(dispatcher, id),
          );
          if (replay != null) return replay;
        }
        return recovery.resume(operationId, precondition: () async {
          final journal = await gateway.readJournal(operationId);
          if (journal != null &&
              mapAtmosphereLifecycleActions
                  .contains(journal.intendedReceipt.actionId)) {
            await requireMapLifecycleAtmosphereGuards(
              journal.intendedReceipt.diff,
              gateway: gateway,
              probeResource: mapAtmosphereProbe,
            );
          }
        });
      },
      policy: policy,
      auditLog: audit,
      clock: clock,
      auditIdFactory: () => _secureIdentity('audit_'),
    );
    final projectionPayloadStore = LocalResourcePackStore(
      cacheDirectory:
          '${Directory.systemTemp.path}${Platform.pathSeparator}pokemap-authoring-projections',
      allowedSourceRoots: resourcePackSourceRoots,
      performanceObserver: performanceObserver,
      clock: clock,
    );
    final projections = AuthoringResultProjectionStore(
        store: projectionPayloadStore,
        scope: FileBackedPayloadScope(
            sessionId: workspaceHandle.value, projectId: projectId));
    final resourcePacks = ResourcePackImportPreparer(
        store: projectionPayloadStore,
        scope: FileBackedPayloadScope(
            sessionId: workspaceHandle.value, projectId: projectId),
        workspaceHandle: workspaceHandle.value,
        clock: clock,
        loadSnapshot: () => snapshotLoader.load(projectHandle),
        probeResource: (path) =>
            snapshotLoader.probeResource(projectHandle, path));
    return _LocalMapAuthoringSession._(
      initialRevision: initialRevision,
      resourcePacks: resourcePacks,
      idempotencyStore: idempotencyStore,
      projections: projections,
      projectionPayloadStore: projectionPayloadStore,
      mapAtmosphereGateway: gateway,
      mapAtmosphereProbe: mapAtmosphereProbe,
      projectId: projectId,
      workspaceHandle: workspaceHandle,
      projectHandle: projectHandle,
      snapshotLoader: snapshotLoader,
      dispatcher: dispatcher,
      actor: actor,
      plans: plans,
      planner: planner,
      policy: policy,
      confirmations: confirmations,
      executor: executor,
      undoService: undoService,
      revertService: AuthoringRevisionRevertService(
        history: history,
        blobs: blobs,
        gateway: gateway,
        planner: planner,
        policy: policy,
        executor: executor,
        tokenFactory: _secureIdentity,
      ),
      recovery: recovery,
      history: history,
      historyBlobs: blobs,
      recoveryExecutor: recoveryExecutor,
      performanceObserver: performanceObserver,
    );
  }

  final AuthoringResultProjectionStore _projections;
  final LocalResourcePackStore _projectionPayloadStore;
  final LocalTransactionFileGateway _mapAtmosphereGateway;
  final MapAtmosphereResourceProbe _mapAtmosphereProbe;
  final ResourcePackImportPreparer _resourcePacks;
  final FileIdempotencyStore _idempotencyStore;

  Future<void> dispose() async {
    _workshopPlans.clear();
    _workshopPreconditions.clear();
    try {
      await _plans.dispose();
      await _resourcePacks.dispose();
    } finally {
      try {
        await _projections.dispose();
      } finally {
        await _projectionPayloadStore.close();
      }
    }
  }

  void requireProjectionRead() {
    _snapshotLoader.requireActiveProject(projectHandle);
    if (!_actor.allows(AuthoringPermissionScope.projectRead)) {
      throw const AuthoringAuthorizationException(
          code: 'authorization.permission_denied',
          message:
              'Reading mutation projections requires project.read permission.');
    }
  }

  final String initialRevision;
  final String projectId;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ProjectSnapshotLoader _snapshotLoader;
  final MapMutationDispatcher _dispatcher;
  final AuthoringActor _actor;
  final AuthoringPlanStore _plans;
  final AuthoringActionPlanner _planner;
  final AuthoringAuthorizationPolicy _policy;
  final AuthoringConfirmationStore _confirmations;
  final SecureAuthoringMutationExecutor _executor;
  final AuthoringUndoService _undoService;
  final AuthoringRevisionRevertService _revertService;
  final AuthoringRecoveryService _recovery;
  final AuthoringHistoryStore _history;
  final AuthoringContentBlobStore _historyBlobs;
  final SecureAuthoringRecoveryExecutor _recoveryExecutor;
  final AuthoringPerformanceObserver? _performanceObserver;
  final Map<String, AuthoringRequest> _workshopPlans = {};
  final Map<String, Map<String, String?>> _workshopPreconditions = {};

  Future<void> prepareLocalWorkshop() async {
    requireProjectionRead();
    _policy.authorize(AuthoringAuthorizationRequest(actor: _actor, projectId: projectId,
        operation: AuthoringSecurityOperation.plan, actionId: 'workshop_prepare', actionVersion: 1,
        riskLevel: AuthoringRiskLevel.low, requestBytes: 0, touchedResources: 0,
        additionalPermissions: const [AuthoringPermissionScope.projectWrite]));
    await _idempotencyStore.prepareIncrementalStorage();
    final history = _history;
    if (history is FileAuthoringHistoryStore) await history.prepareLocalHistory();
    await _executor.prepareFinalizedJournals(requireHistory: (journal) =>
        requireFinalizedJournalHistory(journal: journal, history: history, blobs: _historyBlobs));
  }

  Future<AuthoringMutationHistoryResult> listMutationHistory({
    required int limit,
    String? cursor,
  }) async {
    final page = await _history.list(
      projectId: projectId,
      limit: limit,
      cursor:
          cursor == null ? null : AuthoringHistoryCursor.fromWireValue(cursor),
    );
    return AuthoringMutationHistoryResult(page,
        publicProjection: await _projections.prepareHistory(page));
  }

  Future<AuthoringMutationPlanResult> planMutation(AuthoringRequest request,
      {ProjectSnapshot? suppliedSnapshot}) async {
    _requireWorkspace(request.workspaceHandle);
    final idempotencyKey = request.idempotencyKey;
    if (idempotencyKey == null) {
      throw AuthoringPlanException(
        code: 'plan.idempotency_key_required',
        message: 'Mutation planning requires an idempotency key.',
      );
    }
    await _requireReconciled();
    final descriptor = _dispatcher.descriptor(request.actionId);
    if (descriptor.version != request.actionVersion) {
      throw AuthoringPlanException(
        code: 'plan.action_version_unsupported',
        message: 'The requested action version is unsupported.',
      );
    }
    _policy.authorize(
      AuthoringAuthorizationRequest(
        actor: _actor,
        projectId: projectId,
        operation: AuthoringSecurityOperation.plan,
        actionId: descriptor.id,
        actionVersion: descriptor.version,
        riskLevel: descriptor.riskLevel,
        requestBytes:
            utf8.encode(canonicalAuthoringJson(request.toJson())).length,
        touchedResources: 0,
        additionalPermissions: descriptor.requiredPermissions.map(
          _permissionScope,
        ),
      ),
    );
    final snapshot = suppliedSnapshot ??
        await _loadSnapshot(
          cacheValidation: ProjectSnapshotCacheValidation.session,
          repairRequest:
              _nativeLocalWorkshopActions.contains(request.actionId) || request.actionId == 'pokemon.catalog.write' ? request : null,
        );
    final span = _performanceObserver?.startSpan(
      AuthoringPerformanceSpanName.plan,
    );
    late final AuthoringPlan plan;
    ProjectManifest? projectedProject;
    try {
      final planner = suppliedSnapshot == null
          ? _planner
          : AuthoringActionPlanner(
              store: _plans, tokenFactory: _catalogPlanIdentity);
      plan = await planner.plan(
        request: request,
        snapshot: snapshot,
        build: (context) async {
          final draft = await _dispatcher.build(context);
          projectedProject = draft.projectedProject;
          return includeMapLifecycleAtmosphere(context, draft,
              readResource: _mapAtmosphereGateway.readResource,
              probeResource: _mapAtmosphereProbe);
        },
      );
    } finally {
      span?.finish();
    }
    if (suppliedSnapshot == null && _nativeLocalWorkshopActions.contains(request.actionId)) {
      _workshopPlans[plan.planId] = request;
      _workshopPreconditions[plan.planId] = snapshot.scopedStorageRevisions ?? const {};
    }
    final receipt = plan.toPlannedReceipt();
    try {
      final projection = await _projections.preparePlan(
          plan: plan, receipt: receipt, snapshotRevision: snapshot.revision);
      return AuthoringMutationPlanResult(
          plan: plan,
          snapshotRevision: snapshot.revision,
          receipt: receipt,
          publicProjection: projection,
          projectedProject: projectedProject);
    } on Object {
      _workshopPlans.remove(plan.planId);
      _workshopPreconditions.remove(plan.planId);
      await _plans.discard(plan.planId);
      rethrow;
    }
  }

  Future<AuthoringMutationConfirmationResult> confirmMutation(
    String planId,
  ) async {
    final snapshot = await _loadSnapshot(
      cacheValidation: ProjectSnapshotCacheValidation.session,
      repairRequest: (await _plans.resolveActive(planId)).request,
    );
    final plan = await _plans.resolve(
      _safeIdentity(planId, 'planId'),
      currentProjectRevision: snapshot.revision,
    );
    _requireApplicablePlan(plan);
    final token = _confirmations.issue(
      AuthoringConfirmationBinding.forPlan(
        actorId: _actor.actorId,
        projectId: projectId,
        plan: plan,
      ),
    );
    return AuthoringMutationConfirmationResult(
      planId: plan.planId,
      confirmationToken: token.wireValue,
      expiresInSeconds: _confirmations.lifetime.inSeconds,
    );
  }

  Future<AuthoringMutationResult> applyMutation({
    required String planId,
    required String operationId,
    String? confirmationToken,
    AuthoringTransactionPrecondition? precondition,
    void Function()? beforeReservation,
    void Function()? preparationCheck,
  }) async {
    final safePlanId = _safeIdentity(planId, 'planId');
    final safeOperationId = _safeIdentity(operationId, 'operationId');
    _snapshotLoader.requireActiveProject(projectHandle);
    final replay = await traceAuthoringPhase(
      'authoring.apply.replay_lookup',
      () => _executor.inspectDurableReplay(
        actor: _actor,
        projectId: projectId,
        planId: safePlanId,
        operationId: safeOperationId,
        lookup: () => _idempotencyStore.lookupOperation(
          actorId: _actor.actorId,
          projectId: projectId,
          operationId: safeOperationId,
          now: _plans.now,
        ),
        readHistory: (entryId) =>
            _history.get(projectId: projectId, entryId: entryId),
        resolveAction: _dispatcher.descriptor,
      ),
    );
    if (replay != null) return _mutationResult(replay);
    await traceAuthoringPhase(
      'authoring.apply.recovery',
      _requireReconciled,
    );
    final plan = await _plans.resolveActive(safePlanId);
    _requireApplicablePlan(plan);
    _requireWorkspace(plan.request.workspaceHandle);
    final key = plan.request.idempotencyKey;
    if (key == null) {
      throw AuthoringPlanException(
        code: 'plan.idempotency_key_required',
        message: 'Mutation apply requires an idempotency key.',
      );
    }
    final snapshot = await traceAuthoringPhase(
      'authoring.apply.snapshot_before',
      () => _loadSnapshot(repairRequest: plan.request),
    );
    final descriptor = _dispatcher.descriptor(plan.request.actionId);
    if (plan.request.actionId == 'resource_pack.import') {
      if (plan.appliedPayloadReleased) {
        throw AuthoringPlanException(
          code: 'plan.already_applied',
          message:
              'This import plan was applied under another operation identity.',
        );
      }
      _resourcePacks.certifyPlan(
        plan: plan,
        actorId: _actor.actorId,
        projectId: projectId,
        operationId: safeOperationId,
      );
    }
    final payloadWasReleased = plan.appliedPayloadReleased;
    final changes = payloadWasReleased ? null : plan.changeSet.changes;
    final span = _performanceObserver?.startSpan(
      AuthoringPerformanceSpanName.apply,
    );
    late final AuthoringReceipt receipt;
    ProjectSnapshot? projected;
    var refreshUnavailable = false;
    try {
      receipt = await traceAuthoringPhase(
        'authoring.apply.commit',
        () => _executor.apply(
          actor: _actor,
          projectId: projectId,
          action: descriptor,
          plan: plan,
          currentProjectRevision: snapshot.revision,
          scope: AuthoringIdempotencyScope(
            actorId: _actor.actorId,
            projectId: projectId,
            actionId: descriptor.id,
            actionVersion: descriptor.version,
            key: key,
          ),
          operationId: safeOperationId,
          confirmationToken: confirmationToken == null
              ? null
              : AuthoringConfirmationToken.fromWireValue(confirmationToken),
          precondition: _lockedResourcePrecondition(plan, precondition),
          beforeReservation: beforeReservation,
          preparationCheck: preparationCheck,
        ),
      );
      refreshUnavailable = plan.payloadCleanupFailed;
      try {
        if (_workshopPlans.containsKey(plan.planId)) {
          projected = await _loadSnapshot(repairRequest: _workshopPlans[plan.planId]);
        } else {
        projected = !refreshUnavailable &&
                receipt.status == AuthoringReceiptStatus.applied &&
                changes != null &&
                receipt.extensions['planId'] == plan.planId &&
                !plan.changeSet.diff.entries.any(
                  (entry) =>
                      entry.resource.kind == 'project' &&
                      const [
                        '/models3d',
                        '/resourceLibraryCatalog',
                        '/environmentPresets',
                        '/smartTileCatalog',
                        '/borderCatalog',
                      ].any(
                        (path) =>
                            entry.path == path ||
                            entry.path.startsWith('$path/'),
                      ),
                )
            ? await traceAuthoringPhase(
                'authoring.apply.adopt_snapshot',
                () => _snapshotLoader.adoptAppliedChanges(
                  projectHandle,
                  baseRevision: plan.baseRevision,
                  changes: changes,
                ),
              )
            : null;
        }
      } on Object {
        refreshUnavailable = true;
        _snapshotLoader.invalidate(projectHandle);
      }
      if (receipt.status == AuthoringReceiptStatus.applied) {
        try {
          await traceAuthoringPhase(
            'authoring.apply.release_payload',
            plan.releaseAppliedPayload,
          );
        } on Object {
          refreshUnavailable = true;
          _snapshotLoader.invalidate(projectHandle);
        }
      }
    } finally {
      span?.finish();
    }
    try {
      return await _mutationResult(
        receipt,
        snapshot: projected,
        refreshUnavailable: refreshUnavailable,
      );
    } finally {
      _workshopPlans.remove(safePlanId);
      _workshopPreconditions.remove(safePlanId);
    }
  }

  Future<void> _requireReconciled() async {
    final pending = await _recovery.inspect();
    if (pending.any(
      (entry) =>
          entry.disposition == AuthoringRecoveryDisposition.resumable ||
          entry.disposition == AuthoringRecoveryDisposition.blocked,
    )) {
      throw const AuthoringRecoveryException(
        'resource_pack.recovery_required',
        'Reconcile the canonical pending transaction before editing this project.',
      );
    }
  }

  Future<bool> resourcePackRequiresJob({
    required String operation,
    String? planId,
    String? operationId,
    String? entryId,
  }) async {
    requireProjectionRead();
    if (operation == 'undo') {
      final entry = await _history.get(
        projectId: projectId,
        entryId: _safeIdentity(entryId!, 'entryId'),
      );
      return entry?.bulkCapability != null;
    }
    final found = await _idempotencyStore.lookupOperation(
      actorId: _actor.actorId,
      projectId: projectId,
      operationId: _safeIdentity(operationId!, 'operationId'),
      now: _plans.now,
    );
    if (found != null) {
      if (found.scope.actionId == 'resource_pack.import') return true;
      final receipt = found.completed?.receipt;
      if (receipt != null) {
        final entry = await _history.get(
          projectId: projectId,
          entryId: receipt.receiptId,
        );
        if (entry?.bulkCapability != null) return true;
      }
      return _recovery
          .isResourcePackOperation(_safeIdentity(operationId, 'operationId'));
    }
    if (operation == 'recover') {
      return _recovery.isResourcePackOperation(
        _safeIdentity(operationId, 'operationId'),
      );
    }
    final plan = await _plans.resolveActive(_safeIdentity(planId!, 'planId'));
    return plan.request.actionId == 'resource_pack.import' ||
        plan.bulkCapability != null;
  }

  Future<AuthoringMutationResult> resourcePackHistory({
    required String operation,
    required String entryId,
    required String operationId,
    required String expectedRevision,
    String? expectedHeadEntryId,
    void Function()? beforeReservation,
    void Function()? preparationCheck,
  }) async {
    final safeOperation = _safeIdentity(operationId, 'operationId');
    final found = await _idempotencyStore.lookupOperation(
      actorId: _actor.actorId,
      projectId: projectId,
      operationId: safeOperation,
      now: _plans.now,
    );
    if (found != null) {
      final receipt = found.completed?.receipt;
      if (receipt == null) {
        throw const AuthoringRecoveryException(
          'idempotency.recovery_required',
          'This historical operation requires canonical recovery.',
        );
      }
      final context = AuthoringHistoryContext.fromExtensions(
        receipt.extensions,
      );
      if (receipt.actionId != 'history.$operation' ||
          context.targetEntryId != entryId) {
        throw const AuthoringHistoryException(
          'history.replay_context_mismatch',
          'The historical operation identity differs.',
        );
      }
      final replay = await _executor.inspectDurableReplay(
        actor: _actor,
        projectId: projectId,
        planId: receipt.extensions['planId'] as String,
        operationId: safeOperation,
        lookup: () async => found,
        readHistory: (id) => _history.get(projectId: projectId, entryId: id),
        resolveAction: (id) => _resolveHistoryOrAction(_dispatcher, id),
      );
      return _mutationResult(replay!);
    }
    await _requireReconciled();
    final snapshot = await _loadSnapshot();
    if (snapshot.revision != expectedRevision) {
      throw const AuthoringHistoryException(
        'history.project_stale',
        'The expected project revision differs.',
      );
    }
    final entry = await _history.get(
      projectId: projectId,
      entryId: _safeIdentity(entryId, 'entryId'),
    );
    if (entry == null || entry.bulkCapability == null) {
      throw const AuthoringHistoryException(
        'history.bulk_origin_required',
        'A canonical pack history entry is required.',
      );
    }

    final AuthoringPreparedHistoryMutation prepared;
    if (operation == 'undo') {
      prepared = await _undoService.planUndo(
        actor: _actor,
        projectId: projectId,
        entryId: entryId,
        snapshot: snapshot,
        workspaceHandle: workspaceHandle.value,
        idempotencyKey: safeOperation,
        operationId: safeOperation,
      );
    } else if (operation == 'redo') {
      prepared = await _undoService.planRedo(
        actor: _actor,
        projectId: projectId,
        entryId: entryId,
        snapshot: snapshot,
        workspaceHandle: workspaceHandle.value,
        idempotencyKey: safeOperation,
        operationId: safeOperation,
      );
    } else if (operation == 'revert' && expectedHeadEntryId != null) {
      prepared = await _revertService.planRevert(
        actor: _actor,
        projectId: projectId,
        targetEntryId: entryId,
        expectedHeadEntryId: _safeIdentity(
          expectedHeadEntryId,
          'expectedHeadEntryId',
        ),
        snapshot: snapshot,
        workspaceHandle: workspaceHandle.value,
        idempotencyKey: safeOperation,
        operationId: safeOperation,
      );
    } else {
      throw const AuthoringHistoryException(
        'history.operation_invalid',
        'Unsupported history operation.',
      );
    }
    final receipt = await _undoService.apply(
      prepared,
      beforeReservation: beforeReservation,
      preparationCheck: preparationCheck,
    );
    var refreshUnavailable = prepared.plan.payloadCleanupFailed;
    try {
      await prepared.plan.releaseAppliedPayload();
    } on Object {
      refreshUnavailable = true;
      _snapshotLoader.invalidate(projectHandle);
    }
    return _mutationResult(receipt, refreshUnavailable: refreshUnavailable);
  }

  Future<AuthoringMutationResult> undoMutation({
    required String entryId,
    required String idempotencyKey,
  }) async {
    await _requireReconciled();
    final snapshot = await _snapshotLoader.loadHistorySnapshot(projectHandle);
    final prepared = await _undoService.planUndo(
      actor: _actor,
      projectId: projectId,
      entryId: _safeIdentity(entryId, 'entryId'),
      snapshot: snapshot,
      workspaceHandle: workspaceHandle.value,
      idempotencyKey: _safeIdentity(idempotencyKey, 'idempotencyKey'),
    );
    final receipt = await _undoService.apply(prepared);
    try {
      await prepared.plan.releaseAppliedPayload();
    } on Object {
      _snapshotLoader.invalidate(projectHandle);
    }
    return _mutationResult(receipt, refreshUnavailable: true);
  }

  Future<AuthoringMutationResult> recoverMutation(
    String operationId, {
    void Function()? beforeRecovery,
  }) async {
    final safeOperationId = _safeIdentity(operationId, 'operationId');
    final receipt = await _recoveryExecutor.recover(
      actor: _actor,
      projectId: projectId,
      operationId: safeOperationId,
      beforeRecovery: beforeRecovery,
    );
    return _mutationResult(receipt);
  }

  Future<AuthoringIncompletePreparationDiscardResult>
      discardIncompletePreparation(
    String operationId,
  ) =>
          _recoveryExecutor.discardPreparation(
            actor: _actor,
            projectId: projectId,
            operationId: _safeIdentity(operationId, 'operationId'),
            beforeDiscard: () =>
                _snapshotLoader.requireActiveProject(projectHandle),
          );

  Future<AuthoringMutationResult> _mutationResult(
    AuthoringReceipt receipt, {
    ProjectSnapshot? snapshot,
    bool refreshUnavailable = false,
  }) async {
    String? snapshotRevision;
    AuthoringSnapshotRefreshDiagnostic? diagnostic;
    final scopedRequest = _workshopPlans[receipt.extensions['planId']];
    if (snapshot == null && scopedRequest == null && _nativeLocalWorkshopActions.contains(receipt.actionId)) {
      refreshUnavailable = true;
    }
    if (!refreshUnavailable) {
      try {
        final resolvedSnapshot = snapshot ??
            await traceAuthoringPhase<ProjectSnapshot>(
              'authoring.result.snapshot',
              () => _loadSnapshot(repairRequest: scopedRequest),
            );
        snapshotRevision = resolvedSnapshot.revision;
      } on Object {
        _snapshotLoader.invalidate(projectHandle);
      }
    }
    if (snapshotRevision == null) {
      diagnostic = const AuthoringSnapshotRefreshDiagnostic();
    }
    final projection = await traceAuthoringPhase(
      'authoring.result.projection',
      () => _projections.prepareCommittedMutation(
        receipt: receipt,
        snapshotRevision: snapshotRevision,
        diagnostic: diagnostic?.toJson(),
      ),
    );
    return AuthoringMutationResult(
        receipt: receipt,
        snapshotRevision: snapshotRevision,
        diagnostic: diagnostic,
        publicProjection: projection);
  }

  void _requireWorkspace(String value) {
    if (value != workspaceHandle.value) {
      throw const WorkspaceHandleException(
        'workspace.mutation_handle_mismatch',
        'The request workspace does not own this mutation session.',
      );
    }
  }

  AuthoringTransactionPrecondition? _lockedResourcePrecondition(
    AuthoringPlan plan,
    AuthoringTransactionPrecondition? supplied,
  ) {
    final scoped = _workshopPreconditions[plan.planId];
    if (scoped != null) {
      return () async {
        await supplied?.call();
        for (final entry in scoped.entries) {
          if (await _mapAtmosphereGateway.readResourceRevision(entry.key) != entry.value) {
            throw AuthoringPlanException(code: 'plan.stale',
                message: 'A workshop dependency changed before publication.');
          }
        }
      };
    }
    const guarded = {
      'resource_pack.import',
      'model3d.delete',
      'tileset.source.replace',
      'tileset.remove',
      'element.duplicate',
      'element.delete',
      'smart_tile.preset.rename',
      'smart_tile.preset.duplicate',
      'smart_tile.preset.delete',
      'smart_tile.preset.draft.delete',
      'environment.preset.delete',
      'border.blueprint.delete',
      'border.blueprint.set_deprecated',
      'border_layer.feature_create',
      'border_layer.stroke_add',
      'border_layer.region_fill',
      'border_layer.feature_set_blueprint',
      'border_layer.relink_apply',
      'characterStudio.character.delete',
    };
    final retained =
        (plan.referenceImpact['retainedBlobDigests'] as List?) ?? const [];
    final atmosphereGuards =
        mapAtmosphereLifecycleActions.contains(plan.request.actionId);
    if (!guarded.contains(plan.request.actionId) &&
        retained.isEmpty &&
        !atmosphereGuards) {
      return supplied;
    }
    return () async {
      await supplied?.call();
      if (atmosphereGuards) {
        await requireMapLifecycleAtmosphereGuards(
          plan.changeSet.diff,
          gateway: _mapAtmosphereGateway,
          probeResource: _mapAtmosphereProbe,
        );
      }
      if (plan.request.actionId == 'resource_pack.import') {
        await _resourcePacks.requirePlanPreconditions(plan);
      }
      if (guarded.contains(plan.request.actionId)) {
        final current = await _loadSnapshot(repairRequest: plan.request);
        if (current.revision != plan.baseRevision) {
          throw AuthoringPlanException(
            code: 'plan.stale',
            message: 'Resource dependencies changed before publication.',
            remediation: const [
              'Reanalyze the resource before applying changes.'
            ],
          );
        }
      }
      for (final digest in retained) {
        final artifact =
            plan.artifacts.singleWhere((value) => value.id == digest);
        final bytes = await _snapshotLoader.readRetainedAssetBlob(
          projectHandle,
          ContentArtifactRef(
            digest: artifact.sha256!,
            mediaType: artifact.mediaType,
            byteLength: artifact.byteLength!,
          ),
        );
        if (bytes == null) {
          throw AuthoringPlanException(
            code: 'plan.stale',
            message: 'A retained asset blob disappeared before publication.',
          );
        }
      }
    };
  }

  Future<ProjectSnapshot> _loadSnapshot({
    ProjectSnapshotCacheValidation cacheValidation =
        ProjectSnapshotCacheValidation.canonical,
    AuthoringRequest? repairRequest,
  }) async {
    final span = _performanceObserver?.startSpan(
      AuthoringPerformanceSpanName.snapshot,
    );
    try {
      if (repairRequest != null && _nativeLocalWorkshopActions.contains(repairRequest.actionId)) {
        return await _snapshotLoader.loadWorkshop(projectHandle, actionId: repairRequest.actionId,
            parameters: repairRequest.parameters, readDependencies: Map<String, String>.from(
                repairRequest.extensions['workshopReadDependencies'] as Map? ?? const {}));
      }
      final snapshot = await _snapshotLoader.load(
        projectHandle,
        cacheValidation: cacheValidation,
        policy: repairRequest == null
            ? ProjectSnapshotLoadPolicy.strict
            : ProjectSnapshotLoadPolicy.editorReadProjection,
      );
      if (snapshot.loadDiagnostics.isNotEmpty) {
        final repairsItems =
            repairRequest?.actionId == 'pokemon.catalog.write' &&
                repairRequest?.parameters['relativePath'] ==
                    snapshot.manifest.pokemon.catalogFiles['items'] &&
                snapshot.loadDiagnostics.every((diagnostic) =>
                    diagnostic.code == 'project.item_catalog_invalid');
        if (!repairsItems) {
          throw ProjectSnapshotException(snapshot.loadDiagnostics.first.code,
              'Repair the invalid resource before applying other changes.');
        }
      }
      return snapshot;
    } finally {
      span?.finish();
    }
  }
}

void _requireApplicablePlan(AuthoringPlan plan) {
  if (plan.applicable) return;
  if (plan.nonApplicableReason == 'no_changes') {
    throw AuthoringPlanException(
      code: 'plan.no_changes',
      message:
          'This preview preserves every existing choice and has no changes to apply.',
      remediation: const ['Review the preserved choices in the preview.'],
    );
  }
  throw AuthoringPlanException(
    code: 'plan.dry_run_not_applicable',
    message:
        'This plan is a dry-run preview and cannot be confirmed or applied.',
    remediation: const [
      'Create a new plan with dryRun set to false before requesting apply.',
    ],
  );
}

AuthoringPermissionScope _permissionScope(AuthoringPermission permission) =>
    AuthoringPermissionScope.fromWireName(permission.wireName);

String _projectIdentity(String canonicalRoot) {
  final fingerprint = computeAuthoringJsonFingerprint(
    canonicalRoot,
    logicalName: 'local-project-root.json',
  );
  return 'local_project_${fingerprint.substring(7)}';
}

String _safeIdentity(String value, String field) {
  try {
    return safeAuthoringSecurityIdentifier(value, field);
  } on ArgumentError {
    throw FormatException('$field must be a safe opaque identity.');
  }
}

String _secureIdentity(String prefix) {
  final random = Random.secure();
  final body = List.generate(
    24,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$prefix$body';
}

String _catalogPlanIdentity(String prefix) => prefix == 'receipt_'
    ? 'receipt_document_${_secureIdentity('').substring(0, 32)}'
    : _secureIdentity(prefix);

String _joinAll(List<String> segments) => segments.join(Platform.pathSeparator);

DateTime _systemClock() => DateTime.now().toUtc();

final AuthoringActor _localActor = AuthoringActor(
  actorId: 'local_cli',
  permissions: const [
    AuthoringPermissionScope.projectRead,
    AuthoringPermissionScope.projectWrite,
    AuthoringPermissionScope.projectDestructive,
    AuthoringPermissionScope.assetRead,
    AuthoringPermissionScope.assetWrite,
    AuthoringPermissionScope.importRun,
    AuthoringPermissionScope.exportRun,
    AuthoringPermissionScope.recoveryApply,
    AuthoringPermissionScope.renderRun,
  ],
);

AuthoringActionDescriptor _resolveHistoryOrAction(
  MapMutationDispatcher dispatcher,
  String id,
) {
  if (id == 'history.undo' || id == 'history.redo') {
    return AuthoringUndoService.descriptor(id);
  }
  if (id == 'history.revert') return AuthoringRevisionRevertService.descriptor;
  return dispatcher.descriptor(id);
}
