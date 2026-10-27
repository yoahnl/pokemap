import 'dart:math';

import 'package:map_authoring/map_authoring.dart' show MapAuthoringException;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../../project_session/data/studio_project_document_revision.dart';
import '../domain/map_catalog_port.dart';
import '../domain/map_workspace_port.dart';
import 'local_map_workspace_adapter.dart';
import 'local_map_catalog_preparation.dart';
import 'local_map_catalog_receipt.dart';

final class LocalMapCatalogAdapter
    implements MapCatalogPort, MapCatalogPreparationPort {
  LocalMapCatalogAdapter(
    this.mapAdapter, {
    this.profileSink,
    this.beforeTransactionPrecondition,
    this.fileReader = const LocalProjectFileReader(),
  });

  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader fileReader;
  final ProjectSnapshotLoadProfileSink? profileSink;
  final Future<void> Function()? beforeTransactionPrecondition;
  final snapshotCache = ProjectSnapshotCache();
  final fingerprintCache = ProjectSnapshotFingerprintCache();
  static const _actions = {
    'map.create',
    'map.update_metadata',
    'map.library.reorganize',
    'map.delete_apply',
    'map.duplicate',
    'map.resize_apply',
  };

  @override
  Future<MapCatalogReceipt> mutate(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
  }) => _mutate(
    session,
    actionId,
    parameters,
    expectedMapRevisions: expectedMapRevisions,
    confirmDestructive: confirmDestructive,
    expectedManifest: expectedManifest,
  );

  Future<MapCatalogReceipt> _mutate(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
    String? expectedSnapshotRevision,
    String? Function()? validateBeforeApply,
    bool expectNoChange = false,
  }) => mapAdapter.withResourceMutation(() async {
    if (!_actions.contains(actionId)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Cette opération de catalogue n’est pas disponible.',
      );
    }
    final before = await mapAdapter.resourceBaseline(session);
    if (expectedManifest != null && before.manifest != expectedManifest) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé depuis son ouverture. Rien n’a été publié.',
      );
    }
    if (actionId == 'map.create' &&
        session.storage == ProjectSessionStorage.workingCatalog &&
        before.manifest.settings.dimension == ProjectDimension.threeD) {
      return _createSpatialMap(
        session,
        before,
        parameters,
        expectedMapRevisions: expectedMapRevisions,
        validateBeforeApply: validateBeforeApply,
      );
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(session.directoryPath);
    final snapshots = ProjectSnapshotLoader(
      handles: handles,
      snapshotCache: snapshotCache,
      fingerprintCache: fingerprintCache,
      profileSink: profileSink,
    );
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    var attached = false;
    try {
      final snapshot = await snapshots.load(
        opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection,
      );
      if (expectedSnapshotRevision != null &&
          snapshot.revision != expectedSnapshotRevision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le projet ou ses références ont changé depuis l’analyse. Relancez-la ; rien n’a été publié.',
        );
      }
      if (studioProjectSnapshotRevision(snapshot) != before.revision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le projet a changé. Aucune modification n’a été publiée.',
        );
      }
      for (final entry in expectedMapRevisions.entries) {
        if (narrativeEventBytesFingerprint(
              snapshot.resourceBytes('map:${entry.key}'),
            ) !=
            entry.value) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'La carte a changé sur le disque. Votre travail reste ouvert.',
          );
        }
      }
      final id =
          'catalog_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      if (expectNoChange) {
        final problem = validateBeforeApply?.call();
        if (problem != null) {
          throw MapWorkspaceFailure(MapWorkspaceProblem.conflict, problem);
        }
        final analysis = const MapLifecycleActions().analyze(
          AuthoringPlanningContext(
            snapshot: snapshot,
            request: AuthoringRequest(
              requestId: id,
              actionId: actionId,
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              parameters: parameters,
              expectedRevision: snapshot.revision,
              idempotencyKey: id,
            ),
            planId: id,
            seed: 0,
          ),
        );
        if (!analysis.noChange) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'L’analyse ne correspond plus à une opération sans modification. Relancez-la.',
          );
        }
        return MapCatalogReceipt(
          before: before.manifest,
          manifest: before.manifest,
          beforeRevision: before.revision,
          revision: before.revision,
          changedPaths: const [],
        );
      }
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: id,
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
        ),
      );
      final receipt = mapCatalogReceipt(
        before.manifest,
        before.revision,
        planned.plan,
        actionId,
        projectedProject: planned.projectedProject,
        projectedRevision: snapshot.materializedCatalogProject
            ? studioProjectPlanRevision(snapshot, planned.plan)
            : null,
      );
      try {
        final confirmation = confirmDestructive
            ? await api.confirmMutation(
                opened.projectHandle,
                planId: planned.planId,
              )
            : null;
        final problem = validateBeforeApply?.call();
        if (problem != null) {
          throw MapWorkspaceFailure(MapWorkspaceProblem.conflict, problem);
        }
        await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: id,
          confirmationToken: confirmation?.confirmationToken,
          precondition: mapCatalogTransactionPrecondition(
            beforeTransactionPrecondition,
            validateBeforeApply,
          ),
        );
      } on Object catch (failure, stack) {
        late final AuthoringMutationResult recovered;
        try {
          recovered = await api.recoverMutation(
            opened.projectHandle,
            operationId: id,
          );
        } on Object {
          Error.throwWithStackTrace(failure, stack);
        }
        if (recovered.receipt.status.name != 'applied' &&
            recovered.receipt.extensions['recoveryOutcome'] != 'resumed') {
          rethrow;
        }
      }
      if (snapshot.materializedCatalogProject) {
        final after = await snapshots.load(
          opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.editorReadProjection,
        );
        if (studioProjectSnapshotRevision(after) != receipt.revision ||
            after.manifest != receipt.manifest) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'Le catalogue a été publié mais sa relecture a changé. Rouvrez le projet sans relancer la publication.',
          );
        }
      }
      return receipt;
    } on MapAuthoringException catch (failure) {
      if (failure.code != 'map.no_change') rethrow;
      await mapAdapter.resourceBaseline(session);
      return MapCatalogReceipt(
        before: before.manifest,
        manifest: before.manifest,
        beforeRevision: before.revision,
        revision: before.revision,
        changedPaths: const [],
      );
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  });

  Future<MapCatalogReceipt> _createSpatialMap(
    ProjectSession session,
    ({ProjectManifest manifest, String revision}) before,
    Map<String, Object?> parameters, {
    required Map<String, String> expectedMapRevisions,
    String? Function()? validateBeforeApply,
  }) async {
    final reader = fileReader;
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: {},
    ).openProject(session.directoryPath);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      catalogFileReader: reader,
    );
    var attached = false;
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      final snapshot = await api.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: 'map.create',
        parameters: parameters,
      );
      if (await mapAdapter.resourceRevision(session) != before.revision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le catalogue a changé. Rien n’a été publié.',
        );
      }
      for (final entry in expectedMapRevisions.entries) {
        final metadata = before.manifest.maps
            .where((map) => map.id == entry.key)
            .firstOrNull;
        if (metadata == null ||
            narrativeEventBytesFingerprint(
                  await reader.readBytes(
                    projectRoot: session.directoryPath,
                    relativePath: metadata.relativePath,
                  ),
                ) !=
                entry.value) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'La carte a changé sur le disque. Votre travail reste ouvert.',
          );
        }
      }
      final id =
          'catalog_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: id,
          actionId: 'map.create',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
        ),
      );
      final selected = planned.projectedProject!;
      final created = selected.maps.where(
        (map) => !snapshot.manifest.maps.any((old) => old.id == map.id),
      );
      final manifest = before.manifest.copyWith(
        maps: [...before.manifest.maps, ...created],
      );
      final head = planned.plan.changeSet.changes.singleWhere(
        (change) => change.storageKey == CatalogStorageStore.headStorageKey,
      );
      final descriptor = await reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: 'project.json',
      );
      final receipt = mapCatalogReceipt(
        before.manifest,
        before.revision,
        planned.plan,
        'map.create',
        projectedProject: manifest,
        projectedRevision: studioProjectDocumentRevision(
          descriptorBytes: descriptor,
          headBytes: head.afterBytes,
        ),
      );
      try {
        final problem = validateBeforeApply?.call();
        if (problem != null) {
          throw MapWorkspaceFailure(MapWorkspaceProblem.conflict, problem);
        }
        await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: id,
          precondition: mapCatalogTransactionPrecondition(
            beforeTransactionPrecondition,
            validateBeforeApply,
          ),
        );
      } on Object catch (failure, stack) {
        late final AuthoringMutationResult recovered;
        try {
          recovered = await api.recoverMutation(
            opened.projectHandle,
            operationId: id,
          );
        } on Object {
          Error.throwWithStackTrace(failure, stack);
        }
        if (recovered.receipt.status.name != 'applied' &&
            recovered.receipt.extensions['recoveryOutcome'] != 'resumed') {
          rethrow;
        }
      }
      if (await mapAdapter.resourceRevision(session) != receipt.revision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le catalogue a été publié mais sa révision a changé. Rouvrez le projet sans relancer la publication.',
        );
      }
      return receipt;
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }

  @override
  Future<void> reconcile(ProjectSession session, MapCatalogReceipt receipt) =>
      mapAdapter.withResourceMutation(
        () => mapAdapter.acceptCatalogMutation(session, receipt),
      );

  @override
  Future<MapCatalogPreparation> prepare(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    ProjectManifest? expectedManifest,
  }) => prepareLocalMapCatalog(
    this,
    session,
    actionId,
    parameters,
    expectedMapRevisions: expectedMapRevisions,
    expectedManifest: expectedManifest,
  );

  @override
  Future<MapCatalogReceipt> applyPrepared(
    ProjectSession session,
    MapCatalogPreparation preparation, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
    String? Function()? validateBeforeApply,
  }) {
    final requestedTarget =
        preparation.parameters[preparation.actionId == 'map.duplicate'
            ? 'sourceMapId'
            : 'mapId'];
    if (preparation.sessionId != session.sessionId ||
        preparation.sourceMap.id != preparation.targetMapId ||
        requestedTarget != preparation.targetMapId ||
        (!preparation.canApply && !preparation.noChange)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Cette analyse appartient à une autre session ou refuse la publication.',
      );
    }
    return _mutate(
      session,
      preparation.actionId,
      preparation.parameters,
      expectedMapRevisions: expectedMapRevisions,
      confirmDestructive: confirmDestructive,
      expectedManifest: expectedManifest,
      expectedSnapshotRevision: preparation.snapshotRevision,
      validateBeforeApply: validateBeforeApply,
      expectNoChange: preparation.noChange,
    );
  }
}
