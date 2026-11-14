part of 'local_map_workspace_adapter.dart';

extension _LocalMapWorkspaceBaseline on LocalMapWorkspaceAdapter {
  Future<void> _acceptModelLight(
    ProjectSession session,
    ProjectModel3dEntry model,
    String beforeRevision,
    String afterRevision,
  ) async {
    final current = _projects[session.sessionId];
    if (current == null) return;
    if ((current.revision != beforeRevision &&
            current.revision != afterRevision) ||
        await resourceRevision(session) != afterRevision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'La lumière est enregistrée, mais le catalogue ouvert a changé.',
      );
    }
    ProjectManifest update(ProjectManifest value) {
      final entries = value.models3d;
      if (entries is! ProjectModel3dEntries) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.invalidDocument,
          'Rechargez le catalogue des modèles avant de régler sa lumière.',
        );
      }
      final item = entries.lookup(model.id);
      if (item == null) return value;
      return value.copyWith(
        models3d: entries.replaceSelected([
          item.copyWith(light: model.light, clearLight: model.light == null),
        ]),
      );
    }

    final manifest = update(current.manifest);
    final projections = [
      for (final cache in [
        _resourceSelections,
        _onDemandSelections,
        _activeMapDefinitions,
        _workshopCharacterDefinitions,
      ])
        if (cache[session.sessionId] case final value?)
          (cache: cache, manifest: update(value)),
    ];
    _projects[session.sessionId] = _ProjectDocument(
      current.root,
      manifest,
      afterRevision,
      complete: current.complete,
      metadataFields: current.metadataFields,
    );
    for (final projection in projections) {
      projection.cache[session.sessionId] = projection.manifest;
    }
  }

  Future<String?> _readExternalMapRevision(
    ProjectSession session,
    String mapId,
  ) async {
    final entries = _project(session).manifest.maps as ProjectMapEntries;
    final entry = entries.lookup(mapId);
    if (entry == null) return null;
    await _mapPath(session, entry);
    final bytes = await _reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: entry.relativePath,
    );
    return narrativeEventBytesFingerprint(bytes);
  }

  Future<MapWorkspaceCatalog> _refreshExternalBaseline(
    ProjectSession session, {
    required Set<({String kind, String id})> resources,
  }) => withResourceMutation(() async {
    final current = _project(session);
    await _requireRoot(session);
    if (resources.any(
      (resource) => const {
        'model3d',
        'tileset',
        'element',
        'character',
        'environmentPreset',
        'smartTilePreset',
        'smartTileMaterial',
        'smartTilePattern',
        'smartTileAtlas',
        'smartTileAnimation',
        'borderBlueprint',
        'borderRecord',
      }.contains(resource.kind),
    )) {
      _resourceSelections.remove(session.sessionId);
      _onDemandSelections.remove(session.sessionId);
    }
    if (resources.any((resource) => resource.kind == 'character')) {
      _workshopCharacterDefinitions.remove(session.sessionId);
    }
    final projectChanged = resources.any(
      (resource) => resource.kind == 'project',
    );
    final settingsChanged = resources.any(
      (resource) => resource.kind == 'projectSettings',
    );
    final mapIds = {
      for (final resource in resources)
        if (resource.kind == 'map' || resource.kind == 'mapMetadata')
          resource.id,
    };
    final metadataChanged =
        projectChanged || settingsChanged || mapIds.isNotEmpty;
    if (metadataChanged && session.storage == ProjectSessionStorage.manifest) {
      final bytes = await _reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: 'project.json',
      );
      final manifest = ProjectManifest.fromJson(
        Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
      );
      final revision = narrativeEventBytesFingerprint(bytes);
      final next = _ProjectDocument(current.root, manifest, revision);
      await _requireProjectRevision(session, next);
      _projects[session.sessionId] = next;
      return MapWorkspaceCatalog(metadata: next.manifest, revision: revision);
    }
    if (metadataChanged && session.storage != ProjectSessionStorage.manifest) {
      final fields = projectChanged
          ? (current.metadataFields ?? _mapCatalogMetadataFields).difference({
              'maps',
            })
          : settingsChanged
          ? const {'settings'}
          : const <String>{};
      final result = await _readScopedCatalog(session, (
        catalog,
        revision,
      ) async {
        final selected = mapIds.isEmpty
            ? (
                entries: const <ProjectMapEntry>[],
                positions: const <String, int>{},
              )
            : await CatalogTargetedMapSelection.readMapMetadata(
                catalog: catalog,
                mapIds: mapIds,
              );
        final maps = selected.entries;
        final presentIds = {for (final map in maps) map.id};
        final entries = current.manifest.maps as ProjectMapEntries;
        final metadata = mergeProjectMetadataSections(
          current.manifest,
          catalog.projectMetadata,
          fields,
        );
        return MapWorkspaceCatalog(
          metadata: metadata.copyWith(
            maps: entries.applySelected(
              upserts: maps,
              removedIds: mapIds.difference(presentIds),
              positions: selected.positions,
              onNodeCopied: onMapMetadataNodeCopied,
            ),
          ),
          revision: revision,
        );
      }, metadataFields: fields);
      _projects[session.sessionId] = _ProjectDocument(
        current.root,
        result.metadata,
        result.revision,
        complete: false,
        metadataFields: current.metadataFields ?? _mapCatalogMetadataFields,
      );
      return result;
    }
    final revision = await resourceRevision(session);
    final next = _ProjectDocument(
      current.root,
      current.manifest,
      revision,
      complete:
          session.storage == ProjectSessionStorage.manifest && current.complete,
      metadataFields: current.metadataFields ?? _mapCatalogMetadataFields,
    );
    await _requireProjectRevision(session, next);
    _projects[session.sessionId] = next;
    return MapWorkspaceCatalog(metadata: next.manifest, revision: revision);
  });

  Future<MapWorkspaceCatalog> _loadCatalog(ProjectSession session) async {
    if (session.storage != ProjectSessionStorage.manifest) {
      return _loadScopedCatalog(session);
    }
    await loadProject(session);
    final project = _project(session);
    return MapWorkspaceCatalog(
      metadata: project.manifest,
      revision: project.revision,
    );
  }

  Future<MapWorkspaceSelection> _loadMapPreviewSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final project = _project(session);
    if (!project.complete) return _loadScopedPreviewSelection(session, entry);
    final document = await loadMap(session, entry);
    return MapWorkspaceSelection(
      document: document,
      definitions: project.manifest,
      catalogRevision: project.revision,
      snapshotRevision: project.revision,
    );
  }

  Future<MapWorkspaceSelection> _loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final project = _project(session);
    if (!project.complete) return _loadScopedMapSelection(session, entry);
    final document = await loadMap(session, entry);
    return MapWorkspaceSelection(
      document: document,
      definitions: project.manifest,
      catalogRevision: project.revision,
      snapshotRevision: project.revision,
    );
  }
}
