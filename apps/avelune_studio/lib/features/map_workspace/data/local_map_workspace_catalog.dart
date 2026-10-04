part of 'local_map_workspace_adapter.dart';

class _ProjectDocument {
  const _ProjectDocument(this.root, this.manifest, this.revision);

  final String root;
  final ProjectManifest manifest;
  final String revision;
}

extension LocalMapWorkspaceCatalog on LocalMapWorkspaceAdapter {
  Future<void> acceptResourceMutation(
    ProjectSession session,
    ResourceMutationReceipt receipt, {
    bool allowMapOrganization = false,
  }) async {
    final project = _project(session);
    if (project.manifest == receipt.manifest &&
        project.revision == receipt.revision) {
      await _requireProjectRevision(session, project);
      return;
    }
    final originalMaps = project.manifest.maps;
    final updatedMaps = receipt.manifest.maps;
    final mapsMatch = allowMapOrganization
        ? originalMaps.length == updatedMaps.length &&
              [
                for (var index = 0; index < originalMaps.length; index++)
                  originalMaps[index].copyWith(
                        groupId: updatedMaps[index].groupId,
                        sortOrder: updatedMaps[index].sortOrder,
                      ) ==
                      updatedMaps[index],
              ].every((unchanged) => unchanged)
        : jsonEncode(originalMaps) == jsonEncode(updatedMaps);
    if (project.revision != receipt.beforeRevision ||
        project.manifest != receipt.before ||
        !mapsMatch) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le reçu ne correspond pas au catalogue ouvert.',
      );
    }
    final next = _ProjectDocument(
      project.root,
      receipt.manifest,
      receipt.revision,
    );
    await _requireProjectRevision(session, next);
    _projects[session.sessionId] = next;
  }

  Future<void> acceptCatalogMutation(
    ProjectSession session,
    MapCatalogReceipt receipt,
  ) async {
    final previous = _project(session);
    final baselineMatches =
        previous.manifest == receipt.before &&
        previous.revision == receipt.beforeRevision;
    final alreadyAccepted =
        previous.manifest == receipt.manifest &&
        previous.revision == receipt.revision;
    if ((!baselineMatches && !alreadyAccepted) ||
        receipt.manifest.copyWith(
              maps: receipt.before.maps,
              groups: receipt.before.groups,
            ) !=
            receipt.before) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'La mutation ne correspond pas au catalogue ouvert.',
      );
    }
    final next = _ProjectDocument(
      previous.root,
      receipt.manifest,
      receipt.revision,
    );
    await _requireRoot(session);
    await _requireProjectRevision(session, next);
    final paths = <String, String>{};
    for (final document in receipt.documents.values) {
      final entry = receipt.manifest.maps.singleWhere(
        (entry) => entry.id == document.mapId,
      );
      final bytes = await _reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: entry.relativePath,
      );
      if (narrativeEventBytesFingerprint(bytes) != document.revision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'La carte publiée a changé avant sa relecture.',
        );
      }
      paths[entry.id] = await _mapPath(session, entry);
    }
    if (!identical(_project(session), previous)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'La session a changé pendant la relecture du catalogue.',
      );
    }
    _projects[session.sessionId] = next;
    _loadedPaths.removeWhere(
      (key, _) =>
          key.$1 == session.sessionId &&
          !receipt.manifest.maps.any((entry) => entry.id == key.$2),
    );
    for (final entry in paths.entries) {
      _loadedPaths[(session.sessionId, entry.key)] = entry.value;
    }
  }

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
