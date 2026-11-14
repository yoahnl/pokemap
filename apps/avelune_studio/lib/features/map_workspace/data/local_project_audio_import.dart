part of 'local_map_workspace_adapter.dart';

extension _LocalProjectAudioImport on LocalMapWorkspaceAdapter {
  Future<ProjectAudioImport> _adoptAudioAsset(
    ProjectSession session,
    String assetId,
    String mediaId,
    String label,
    String expectedRevision,
  ) async {
    if (session.storage == ProjectSessionStorage.portableCatalog) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Créez une copie de travail pour ajouter ce son à la bibliothèque.',
      );
    }
    return _withSurfAuthoring(session, (_, opened, api, reads) async {
      if (_project(session).revision != expectedRevision ||
          await resourceRevision(session) != expectedRevision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le projet a changé. Vos sons restent en brouillon.',
        );
      }
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      const action = 'project.audio.media.adopt_asset';
      final parameters = <String, Object?>{
        'assetId': assetId,
        'mediaId': mediaId,
        'label': label,
      };
      final scoped = await reads.queryProject(
        opened.projectHandle,
        AuthoringQueryRequest(
          resourceKind: 'projectAudio',
          operation: AuthoringQueryOperation.get,
          ids: const ['project'],
          extensions: {'actionId': action, 'parameters': parameters},
        ),
      );
      final id =
          'studio_adopt_${DateTime.now().microsecondsSinceEpoch}_${_settingsOperations++}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: id,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: scoped.snapshotRevision,
          idempotencyKey: id,
        ),
      );
      final existing = planned.plan.preview['existingMediaId'];
      final noOp = planned.plan.preview['noOp'] == true;
      if (noOp && existing is! String) {
        throw StateError(
          'La bibliothèque n’a pas renvoyé le son déjà enregistré.',
        );
      }
      if (!noOp) {
        await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: id,
          precondition: () async {
            if (await resourceRevision(session) != expectedRevision) {
              throw const MapWorkspaceFailure(
                MapWorkspaceProblem.conflict,
                'Le projet a changé pendant l’ajout du son.',
              );
            }
          },
        );
      }
      final selectedId = noOp ? existing as String : mediaId;
      final result = await reads.queryProject(
        opened.projectHandle,
        AuthoringQueryRequest(
          resourceKind: 'presentationMedia',
          operation: AuthoringQueryOperation.get,
          ids: [selectedId],
          pageSize: 1,
        ),
      );
      final item = result.items.single;
      final revision = await resourceRevision(session);
      if (noOp && revision != expectedRevision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le projet a changé pendant la sélection du son existant. Vos réglages restent en brouillon.',
        );
      }
      final current = _project(session);
      _projects[session.sessionId] = _ProjectDocument(
        current.root,
        current.manifest,
        revision,
        complete: current.complete,
        metadataFields: current.metadataFields,
      );
      return ProjectAudioImport(
        entry: ProjectAudioEntry(
          id: selectedId,
          label: (item['name'] ?? item['label']) as String,
        ),
        beforeRevision: expectedRevision,
        revision: revision,
      );
    });
  }

  Future<ProjectAudioImport> _importAudio(
    ProjectSession session,
    String sourcePath,
    String label,
    String expectedRevision,
  ) async {
    if (session.storage == ProjectSessionStorage.portableCatalog) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Créez une copie de travail pour importer un son.',
      );
    }
    final artifacts = LocalArtifactStore(
      allowedSourceRoots: [session.directoryPath],
      maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
    );
    String? stagedHandle;
    try {
      await artifacts.authorizeSourceFile(sourcePath);
      return await _withSurfAuthoring(session, (_, opened, api, _) async {
        final before = _project(session);
        if (before.revision != expectedRevision ||
            await resourceRevision(session) != expectedRevision) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'Le projet a changé. Le son n’a pas été importé.',
          );
        }
        await api.attachProject(
          projectRootPath: session.directoryPath,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle,
        );
        final staged = await api.stageArtifactFile(sourcePath: sourcePath);
        stagedHandle = staged.reference.handle;
        final id =
            'audio_${DateTime.now().microsecondsSinceEpoch}_${_settingsOperations++}';
        final parameters = <String, Object?>{
          'artifactHandle': stagedHandle,
          'assetId': 'asset_$id',
          'mediaId': id,
          'label': label,
          'kind': 'audio',
          'logicalPath':
              'assets/audio/$id${p.extension(sourcePath).toLowerCase()}',
        };
        final snapshot = await api.readWorkshopSnapshot(
          opened.projectHandle,
          actionId: 'presentationMedia.import',
          parameters: parameters,
        );
        final plan = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: id,
            actionId: 'presentationMedia.import',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            parameters: parameters,
            expectedRevision: snapshot.revision,
            idempotencyKey: id,
          ),
        );
        await api.applyMutation(
          opened.projectHandle,
          planId: plan.planId,
          operationId: id,
          precondition: () async {
            if (await resourceRevision(session) != expectedRevision) {
              throw const MapWorkspaceFailure(
                MapWorkspaceProblem.conflict,
                'Le projet a changé pendant l’import.',
              );
            }
          },
        );
        final revision = await resourceRevision(session);
        final current = _project(session);
        _projects[session.sessionId] = _ProjectDocument(
          current.root,
          current.manifest,
          revision,
          complete: current.complete,
          metadataFields: current.metadataFields,
        );
        return ProjectAudioImport(
          entry: ProjectAudioEntry(id: id, label: label),
          beforeRevision: expectedRevision,
          revision: revision,
        );
      }, artifactStore: artifacts);
    } finally {
      if (stagedHandle case final handle?) await artifacts.release(handle);
    }
  }
}
