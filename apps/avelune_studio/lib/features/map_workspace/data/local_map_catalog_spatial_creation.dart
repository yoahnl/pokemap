part of 'local_map_catalog_adapter.dart';

const mapCatalogScopedActions = {
  'map.create',
  'map.update_metadata',
  'map.library.reorganize',
  'map.duplicate',
};

extension _LocalMapCatalogScopedMutation on LocalMapCatalogAdapter {
  Future<MapCatalogReceipt> _mutateScoped(
    ProjectSession session,
    ({ProjectManifest manifest, String revision}) before,
    String actionId,
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
        actionId: actionId,
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
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
          extensions: const {'workshopScope': true},
        ),
      );
      final manifest = mapCatalogScopedManifest(
        before.manifest,
        snapshot.manifest,
        planned.projectedProject!,
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
        actionId,
        projectedProject: manifest,
        projectedRevision: studioProjectDocumentRevision(
          descriptorBytes: descriptor,
          headBytes: head.afterBytes,
        ),
      );
      String? entryId;
      try {
        final problem = validateBeforeApply?.call();
        if (problem != null) {
          throw MapWorkspaceFailure(MapWorkspaceProblem.conflict, problem);
        }
        entryId = (await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: id,
          precondition: mapCatalogTransactionPrecondition(
            beforeTransactionPrecondition,
            validateBeforeApply,
          ),
        )).receipt.receiptId;
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
        entryId = recovered.receipt.receiptId;
      }
      if (await mapAdapter.resourceRevision(session) != receipt.revision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le catalogue a été publié mais sa révision a changé. Rouvrez le projet sans relancer la publication.',
        );
      }
      return receipt.recordedAs(entryId);
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }
}
