part of 'local_map_workspace_adapter.dart';

extension _LocalMapWorkspaceDocuments on LocalMapWorkspaceAdapter {
  Future<ProjectManifest> _loadProject(ProjectSession session) async {
    try {
      _projects.clear();
      _loadedPaths.clear();
      await _requireRoot(session);
      if (session.storage != ProjectSessionStorage.manifest) {
        final loaded = await _readCatalogProject(session);
        _projects[session.sessionId] = loaded;
        return loaded.manifest;
      }
      final bytes = await _reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: 'project.json',
      );
      final value = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
      if (value is! Map<String, dynamic>) throw const FormatException();
      final decoded = ProjectManifest.fromJson(value);
      final project = decoded.copyWith(
        models3d: ProjectModel3dEntries.prepare(decoded.models3d),
      );
      final ids = <String>{};
      final paths = <String>{};
      for (final entry in project.maps) {
        if (!ids.add(entry.id) || !paths.add(entry.relativePath)) {
          throw const FormatException();
        }
      }
      _projects[session.sessionId] = _ProjectDocument(
        session.directoryPath,
        project,
        narrativeEventBytesFingerprint(bytes),
      );
      return project;
    } on MapWorkspaceFailure {
      rethrow;
    } on Object {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.invalidDocument,
        'Le catalogue du projet ne peut pas être chargé.',
      );
    }
  }

  Future<MapWorkspaceDocument> _loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    try {
      final project = _project(session);
      if (!project.complete) {
        return (await loadMapSelection(session, entry)).document;
      }
      if (!project.manifest.maps.contains(entry)) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unsafePath,
          'Cette carte ne figure pas dans le projet ouvert.',
        );
      }
      final path = await _mapPath(session, entry);
      await _requireProjectRevision(session, project);
      final bytes = await _reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: entry.relativePath,
      );
      final map = decodeValidatedMapDocument(
        bytes,
        entry.relativePath,
        validateMap: (map) => MapValidator.validate(
          map,
          projectDialogueContext: project.manifest,
        ),
      );
      if (map.id != entry.id ||
          !buildMapVisualCompositionPlan(map).canCompose) {
        throw const FormatException();
      }
      requireMapDocumentRetention(bytes, map);
      _loadedPaths[(session.sessionId, entry.id)] = path;
      return MapWorkspaceDocument(
        map: map,
        revision: narrativeEventBytesFingerprint(bytes),
        mapId: entry.id,
      );
    } on MapWorkspaceFailure {
      rethrow;
    } on Object {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.invalidDocument,
        'Cette carte est absente, invalide ou utilise un format non pris en charge.',
      );
    }
  }

  Future<String> _saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async {
    try {
      if (session.storage == ProjectSessionStorage.portableCatalog) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unavailable,
          'Ce projet publié est en lecture seule.',
        );
      }
      if (base.map.spatialScene != null &&
          current.spatialScene != null &&
          jsonEncode(
                base.map.spatialScene!.platforms
                    .map((value) => value.toJson())
                    .toList(),
              ) !=
              jsonEncode(
                current.spatialScene!.platforms
                    .map((value) => value.toJson())
                    .toList(),
              )) {
        return await _saveSpatialPlatformChange(session, base, current);
      }
      final project = _project(session);
      final entry = project.manifest.maps.singleWhere(
        (e) => e.id == base.mapId,
      );
      final path = await _mapPath(session, entry);
      if (_loadedPaths[(session.sessionId, entry.id)] != path ||
          base.map.id != entry.id ||
          current.id != entry.id) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unsafePath,
          'La destination de la carte a changé. Votre travail reste ouvert.',
        );
      }
      await _requireProjectRevision(session, project);
      if (!buildMapVisualCompositionPlan(current).canCompose) {
        throw const FormatException();
      }
      if (project.complete) {
        MapValidator.validate(
          current,
          projectDialogueContext: project.manifest,
        );
      }
      final bytes = encodeMapDocumentBytes(current);
      if (session.storage == ProjectSessionStorage.workingCatalog) {
        return await _saveWorkingMap(session, project, base, current);
      }
      return await _persistence.write(
        path,
        bytes,
        precondition: MapDocumentWritePrecondition.revision(base.revision),
      );
    } on MapWorkspaceFailure {
      rethrow;
    } on EditorConflictException {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'La carte ou le projet a changé sur le disque. Rien n’a été écrasé ; votre travail reste ouvert.',
      );
    } on Object {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.writeFailed,
        'La carte n’a pas pu être enregistrée. Votre travail reste ouvert.',
      );
    }
  }

  Future<void> _requireProjectRevision(
    ProjectSession session,
    _ProjectDocument project,
  ) async {
    final bytes = await _reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: 'project.json',
    );
    final head = session.storage == ProjectSessionStorage.workingCatalog
        ? await _reader.readBytes(
            projectRoot: session.directoryPath,
            relativePath: 'catalog/HEAD.json',
          )
        : null;
    if (studioProjectDocumentRevision(
          descriptorBytes: bytes,
          headBytes: head,
        ) !=
        project.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le projet a changé sur le disque. Votre travail reste ouvert ; rouvrez le projet pour utiliser sa nouvelle version.',
      );
    }
  }

  _ProjectDocument _project(ProjectSession session) {
    final project = _projects[session.sessionId];
    if (project == null || project.root != session.directoryPath) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Le projet doit être ouvert avant de charger une carte.',
      );
    }
    return project;
  }

  Future<void> _requireRoot(ProjectSession session) async {
    final root = session.directoryPath;
    if (root != root.trim() || !p.isAbsolute(root)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'Le chemin du projet ne peut pas être préservé.',
      );
    }
    final resolved = await Directory(root).resolveSymbolicLinks();
    if (resolved != root || resolved != resolved.trim()) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'Le dossier du projet a changé depuis son ouverture.',
      );
    }
  }

  Future<String> _mapPath(ProjectSession session, ProjectMapEntry entry) async {
    await _requireRoot(session);
    final relative = entry.relativePath;
    if (relative != relative.trim() ||
        p.isAbsolute(relative) ||
        relative.contains('\\') ||
        relative
            .split('/')
            .any((part) => part.isEmpty || part == '..' || part == '.') ||
        relative.contains('\u0000')) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'Le chemin de cette carte n’est pas sûr.',
      );
    }
    final file = File(p.join(session.directoryPath, relative));
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'La carte doit être un fichier ordinaire du projet.',
      );
    }
    final canonical = await file.resolveSymbolicLinks();
    if (!p.isWithin(session.directoryPath, canonical)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'La carte pointe en dehors du projet ouvert.',
      );
    }
    return canonical;
  }
}
