part of 'local_map_workspace_adapter.dart';

typedef _FamilyRead = ({String revision, Future<MapWorkspaceCatalog> read});

extension _LocalResourceFamilies on LocalMapWorkspaceAdapter {
  Future<MapWorkspaceCatalog> _loadResourceKind(
    ProjectSession session,
    String canonicalKind,
    bool placeableOnly,
  ) async {
    final before = _project(session);
    final result = await _familyRead(
      session,
      canonicalKind,
      placeableOnly,
      before.revision,
    );
    final latest = _project(session);
    if (latest.revision != result.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé pendant le chargement de cette famille.',
      );
    }
    _resourceSelections[session.sessionId] = result.metadata;
    final selection = combineResourceVisuals(
      _activeMapDefinitions[session.sessionId] ?? latest.manifest,
      _workshopCharacterDefinitions[session.sessionId] == null
          ? result.metadata
          : combineResourceVisuals(
              result.metadata,
              _workshopCharacterDefinitions[session.sessionId]!,
            ),
    );
    final borders = _borderSelections[session.sessionId];
    final merged = mergeResourceSelection(
      latest.manifest,
      borders == null ? selection : combineResourceVisuals(selection, borders),
      library: result.metadata.resourceLibraryCatalog,
    );
    _projects[session.sessionId] = _ProjectDocument(
      latest.root,
      merged.copyWith(models3d: ProjectModel3dEntries.prepare(merged.models3d)),
      result.revision,
      complete: false,
      metadataFields: latest.metadataFields,
    );
    return result;
  }

  Future<void> _prefetchResourceKind(
    ProjectSession session,
    String canonicalKind,
    bool placeableOnly,
  ) async {
    final document = _projects[session.sessionId];
    if (document == null) return;
    try {
      await _familyRead(
        session,
        canonicalKind,
        placeableOnly,
        document.revision,
      );
    } catch (_) {
      return;
    }
  }

  Future<MapWorkspaceCatalog> _familyRead(
    ProjectSession session,
    String canonicalKind,
    bool placeableOnly,
    String revision,
  ) {
    final reads = _resourceKindReads.putIfAbsent(session.sessionId, () => {});
    final key = placeableOnly ? '$canonicalKind:placeable' : canonicalKind;
    final current = reads[key];
    if (current != null && current.revision == revision) return current.read;
    final kind = _catalogFamily(canonicalKind);
    final reader = _reader;
    final read = reader is LocalProjectFileReader
        ? _readFamilyInBackground(
            reader,
            session,
            kind,
            canonicalKind,
            placeableOnly,
            revision,
          )
        : _readFamily(
            reader,
            session,
            kind,
            canonicalKind,
            placeableOnly,
            revision,
          );
    reads[key] = (revision: revision, read: read);
    read.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(reads[key]?.read, read)) reads.remove(key);
      },
    );
    return read;
  }
}

CatalogDefinitionKind _catalogFamily(String canonicalKind) =>
    switch (canonicalKind) {
      'tileset' => CatalogDefinitionKind.tileset,
      'element' => CatalogDefinitionKind.element,
      'model3d' => CatalogDefinitionKind.model3d,
      'character' => CatalogDefinitionKind.character,
      'environmentPreset' => CatalogDefinitionKind.environmentPreset,
      'smartTilePreset' => CatalogDefinitionKind.smartTilePreset,
      'borderBlueprint' => CatalogDefinitionKind.borderRecord,
      _ => throw const FormatException('Famille de ressources inconnue.'),
    };

Future<MapWorkspaceCatalog> _readFamilyInBackground(
  LocalProjectFileReader reader,
  ProjectSession session,
  CatalogDefinitionKind kind,
  String canonicalKind,
  bool placeableOnly,
  String revision,
) => Isolate.run(
  () => _readFamily(
    reader,
    session,
    kind,
    canonicalKind,
    placeableOnly,
    revision,
  ),
);

Future<MapWorkspaceCatalog> _readFamily(
  ProjectFileReader reader,
  ProjectSession session,
  CatalogDefinitionKind kind,
  String canonicalKind,
  bool placeableOnly,
  String expectedRevision,
) => _readScopedCatalogWith(
  reader,
  session,
  (catalog, revision) async {
    if (revision != expectedRevision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé avant le chargement de cette famille.',
      );
    }
    final roots = <CatalogDefinitionKey>[];
    String? cursor;
    do {
      final page = await catalog.snapshot.page(
        kind: kind,
        limit: catalog.snapshot.limits.indexPageSize,
        cursor: cursor,
      );
      roots.addAll(page.items.map((entry) => entry.key));
      cursor = page.nextCursor;
    } while (cursor != null);
    if (placeableOnly) {
      final components = await _componentResources(catalog);
      final resourceKind = kind == CatalogDefinitionKind.borderRecord
          ? 'borderBlueprint'
          : kind.name;
      roots.removeWhere(
        (key) => components.contains('$resourceKind:${key.id}'),
      );
    }
    final manifest = await ProjectCatalogSelection(catalog).resolve(roots);
    return MapWorkspaceCatalog(
      metadata: manifest.copyWith(
        models3d: ProjectModel3dEntries.prepare(manifest.models3d),
      ),
      revision: revision,
    );
  },
  metadataFields: {
    ..._mapCatalogMetadataFields,
    ...MapWorkspaceWorkshop.resources.metadataFields,
    if (canonicalKind == 'character') 'characterStudioCatalog',
  },
);

Future<Set<String>> _componentResources(PortableProjectCatalog catalog) async {
  final components = <String>{};
  String? cursor;
  do {
    final page = await catalog.snapshot.page(
      kind: CatalogDefinitionKind.resourceLibraryEntry,
      limit: catalog.snapshot.limits.indexPageSize,
      cursor: cursor,
    );
    for (final entry in page.items) {
      if (entry.summary.role == ResourceLibraryRole.component.name) {
        components.add(entry.key.id);
      }
    }
    cursor = page.nextCursor;
  } while (cursor != null);
  return components;
}
