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
            path: item['name'] as String,
          ),
      ],
      nextCursor: page.nextCursor,
    );
  });

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
