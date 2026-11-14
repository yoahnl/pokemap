part of 'local_map_catalog_adapter.dart';

extension _LocalMapCatalogMutation on LocalMapCatalogAdapter {
  static const _actions = {
    'map.create',
    'map.update_metadata',
    'map.library.reorganize',
    'map.delete_apply',
    'map.duplicate',
    'map.resize_apply',
  };

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
}
