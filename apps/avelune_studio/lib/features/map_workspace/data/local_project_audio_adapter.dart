part of 'local_map_workspace_adapter.dart';

extension _LocalProjectAudioAdapter on LocalMapWorkspaceAdapter {
  Future<ProjectAudioState> _loadAudio(ProjectSession session) =>
      LocalWorkshopReader(session, reader: _reader).read(
        metadataFields: {'settings'},
        operation: (project, _, revision) async => ProjectAudioState(
          configuration: project.settings.audio,
          revision: revision,
        ),
      );
  Future<ProjectAudioState> _saveAudioCue(
    ProjectSession session,
    ProjectSoundCue cue,
    ProjectSoundBinding? binding,
    String expectedRevision,
  ) async {
    final value = await _configureProjectSettings(
      session,
      'project.audio.cue.configure',
      {'cueId': cue.wireName, 'binding': binding?.toJson()},
      expectedRevision,
      (current, projected) => current.copyWith(audio: projected.audio),
    );
    return ProjectAudioState(
      configuration: value.settings.audio,
      revision: value.revision,
    );
  }

  Future<ProjectAudioPage> _queryAudio(
    ProjectSession session, {
    String query = '',
    String? cursor,
  }) => _withSurfAuthoring(session, (_, opened, _, reads) async {
    final page = await reads.queryProject(
      opened.projectHandle,
      AuthoringQueryRequest(
        resourceKind: 'presentationMedia',
        operation: query.trim().isEmpty
            ? AuthoringQueryOperation.list
            : AuthoringQueryOperation.search,
        filters: const {'kind': 'audio'},
        searchTerm: query,
        pageSize: 50,
        cursor: cursor,
      ),
    );
    return ProjectAudioPage(
      entries: [
        for (final item in page.items)
          ProjectAudioEntry(
            id: item['id'] as String,
            label: (item['name'] ?? item['label']) as String,
          ),
      ],
      nextCursor: page.nextCursor,
    );
  });
  Future<ProjectAudioPage> _queryLegacyAudio(
    ProjectSession session, {
    String query = '',
    String? cursor,
  }) => _withSurfAuthoring(session, (_, opened, _, reads) async {
    final page = await reads.queryProject(
      opened.projectHandle,
      AuthoringQueryRequest(
        resourceKind: 'asset',
        operation: query.trim().isEmpty
            ? AuthoringQueryOperation.list
            : AuthoringQueryOperation.search,
        filters: const {'audioOnly': true},
        searchTerm: query,
        pageSize: 50,
        cursor: cursor,
      ),
    );
    return ProjectAudioPage(
      entries: [
        for (final item in page.items)
          ProjectAudioEntry(
            id: item['id'] as String,
            label: p.basename(item['name'] as String),
          ),
      ],
      nextCursor: page.nextCursor,
    );
  });

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

  Future<ProjectAudioFile> _resolveAudio(
    ProjectSession session,
    String mediaId,
  ) => _withSurfAuthoring(session, (_, opened, _, reads) async {
    final page = await reads.queryProject(
      opened.projectHandle,
      AuthoringQueryRequest(
        resourceKind: 'presentationMedia',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: [mediaId],
        pageSize: 1,
      ),
    );
    if (page.items.length != 1) {
      throw StateError('Ce son est absent ou ambigu.');
    }
    final media = ProjectMediaAsset.fromJson(
      {...page.items.single}
        ..remove('resourceKind')
        ..remove('name'),
    );
    if (media.kind != ProjectMediaKind.audio) {
      throw StateError('Cette ressource n’est pas un son.');
    }
    final assets = await reads.queryProject(
      opened.projectHandle,
      AuthoringQueryRequest(
        resourceKind: 'asset',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: [media.sourceAssetId],
        pageSize: 1,
      ),
    );
    if (assets.items.length != 1) {
      throw StateError('Le fichier de ce son est absent ou ambigu.');
    }
    final asset = AssetRecord.fromJson(
      {...assets.items.single}
        ..remove('name')
        ..remove('resourceKind')
        ..remove('unused')
        ..remove('preview'),
    );
    final metadata = media.technicalMetadata;
    if (metadata == null ||
        !projectAudioSourceMimeMatches(
          asset.artifact.mediaType,
          metadata.mediaType,
        ) ||
        asset.artifact.byteLength != metadata.sizeBytes ||
        metadata.sizeBytes > maximumAuthoringArtifactBytesV1) {
      throw StateError(
        'Les métadonnées de ce son ne correspondent pas à sa source audio.',
      );
    }
    final root = await Directory(session.directoryPath).resolveSymbolicLinks();
    final file = File(p.join(root, assetBlobStorageKey(asset.artifact)));
    final resolved = await file.resolveSymbolicLinks();
    if (!p.isWithin(root, resolved) ||
        await FileSystemEntity.type(resolved, followLinks: false) !=
            FileSystemEntityType.file) {
      throw StateError('Le son doit rester dans le projet.');
    }
    final selectedFile = File(resolved);
    if (await selectedFile.length() != metadata.sizeBytes) {
      throw StateError('Le fichier de ce son a changé depuis son import.');
    }
    final inspected = probeProjectAudioSourceBytes(
      await selectedFile.readAsBytes(),
      artifact: asset.artifact,
      media: media,
    );
    return ProjectAudioFile(path: resolved, mimeType: inspected.mediaType);
  });
}
