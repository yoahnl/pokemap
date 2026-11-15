part of 'local_map_catalog_adapter.dart';

extension _LocalMapCatalogHistory on LocalMapCatalogAdapter {
  Future<MapCatalogReceipt> _restoreHistory(
    ProjectSession session,
    MapCatalogReceipt step, {
    required bool redo,
    required ProjectManifest expectedManifest,
  }) => mapAdapter.withResourceMutation(() async {
    final entryId = step.historyEntryId;
    if (entryId == null) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Cette action n’a pas d’historique : elle ne peut pas être rejouée.',
      );
    }
    final before = await mapAdapter.resourceBaseline(session);
    if (!mapCatalogLibraryMatches(
      before.manifest,
      expectedManifest,
      libraryOnly:
          session.storage == ProjectSessionStorage.workingCatalog &&
          before.manifest.settings.dimension == ProjectDimension.threeD,
    )) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé depuis son ouverture. Rien n’a été modifié.',
      );
    }
    await _replayHistory(session, entryId, redo: redo);
    final manifest = mapCatalogScopedManifest(
      before.manifest,
      redo ? step.before : step.manifest,
      redo ? step.manifest : step.before,
    );
    final documents = <String, MapWorkspaceDocument>{};
    for (final id in {...step.documents.keys, ?step.createdMapId}) {
      final entry = manifest.maps.where((map) => map.id == id).firstOrNull;
      if (entry == null) continue;
      if (step.replacesContent) {
        documents[id] = (await mapAdapter.readSavedMap(session, id))!;
        continue;
      }
      final bytes = await fileReader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: entry.relativePath,
      );
      documents[id] = mapCatalogDocument(bytes, entry.relativePath, manifest);
    }
    return MapCatalogReceipt(
      before: before.manifest,
      manifest: manifest,
      beforeRevision: before.revision,
      revision: await mapAdapter.resourceRevision(session),
      changedPaths: step.changedPaths,
      documents: Map.unmodifiable(documents),
      createdMapId: redo ? step.createdMapId : null,
      historyEntryId: entryId,
      replacesContent: step.replacesContent,
    );
  });

  Future<void> _replayHistory(
    ProjectSession session,
    String entryId, {
    required bool redo,
  }) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: fileReader,
    );
    final handles = WorkspaceHandleStore();
    final catalog = session.storage == ProjectSessionStorage.workingCatalog;
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: fileReader,
      handles: handles,
      catalogMetadataFields: catalog ? const {} : null,
    ).openProject(session.directoryPath);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: catalog
          ? ProjectSnapshotLoader(handles: handles)
          : ProjectSnapshotLoader(
              handles: handles,
              snapshotCache: snapshotCache,
              fingerprintCache: fingerprintCache,
              profileSink: profileSink,
            ),
      catalogFileReader: fileReader,
    );
    var attached = false;
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      final key =
          'catalog_history_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      if (redo) {
        await api.redoMutation(
          opened.projectHandle,
          entryId: entryId,
          idempotencyKey: key,
        );
      } else {
        await api.undoMutation(
          opened.projectHandle,
          entryId: entryId,
          idempotencyKey: key,
        );
      }
    } on AuthoringHistoryException catch (failure) {
      throw MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        _historyRefusal(failure.code, redo: redo),
      );
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }

  static String _historyRefusal(String code, {required bool redo}) {
    final done = redo ? 'rétablie' : 'annulée';
    return switch (code) {
      'history.redo_branch_diverged' => 'D’autres modifications ont été enregistrées depuis : cette action de la bibliothèque ne peut plus être rétablie. Rien n’a été modifié.',
      'history.resource_changed' || 'history.project_stale' =>
        'Le projet a changé depuis cette action de la bibliothèque : elle ne peut plus être $done. Rien n’a été modifié.',
      _ =>
        'Cette action de la bibliothèque ne peut plus être $done ($code). Rien n’a été modifié.',
    };
  }
}
