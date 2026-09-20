part of 'local_map_workspace_adapter.dart';

extension LocalMapWorkspaceCatalog on LocalMapWorkspaceAdapter {
  Future<_ProjectDocument> _refreshCatalog(
    ProjectSession session,
    _ProjectDocument project,
  ) async {
    final bytes = await _reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: 'project.json',
    );
    final revision = narrativeEventBytesFingerprint(bytes);
    if (revision == project.revision) return project;
    final manifest = ProjectManifest.fromJson(
      decodeNarrativeEventJsonStrict(utf8.decode(bytes))
          as Map<String, dynamic>,
    );
    if (jsonEncode(manifest.maps) != jsonEncode(project.manifest.maps)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue des cartes a changé. Rouvrez le projet ; vos brouillons restent ouverts.',
      );
    }
    if (!identical(_project(session), project)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'La session du projet a changé pendant la lecture.',
      );
    }
    final refreshed = _ProjectDocument(project.root, manifest, revision);
    _projects[session.sessionId] = refreshed;
    return refreshed;
  }
}
