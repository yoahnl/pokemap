part of 'local_map_workspace_adapter.dart';

Future<ProjectResourceLibrary> _readProjectResourceLibraryInBackground(
  LocalProjectFileReader reader,
  ProjectSession session, {
  required bool includeCompositeDimensions,
}) => Isolate.run(
  () => _readProjectResourceLibrary(
    reader,
    session,
    includeCompositeDimensions: includeCompositeDimensions,
  ),
);

Stream<List<CatalogIndexEntry>> _libraryIndexPages(
  CatalogSnapshot snapshot,
  CatalogDefinitionKind kind,
) async* {
  String? cursor;
  do {
    final page = await snapshot.page(
      kind: kind,
      limit: snapshot.limits.indexPageSize,
      cursor: cursor,
    );
    yield page.items;
    cursor = page.nextCursor;
  } while (cursor != null);
}

Future<ProjectResourceLibrary> _readProjectResourceLibrary(
  ProjectFileReader reader,
  ProjectSession session, {
  required bool includeCompositeDimensions,
}) => _readScopedCatalogWith(reader, session, (catalog, revision) async {
  final snapshot = catalog.snapshot;
  Stream<CatalogIndexEntry> entries(CatalogDefinitionKind kind) async* {
    await for (final page in _libraryIndexPages(snapshot, kind)) {
      yield* Stream.fromIterable(page);
    }
  }

  final families = <ResourceFamily>[];
  await for (final index in entries(CatalogDefinitionKind.resourceFamily)) {
    final unit = await catalog.lookup(index.key);
    if (unit == null) {
      throw const FormatException('Une famille du catalogue est introuvable.');
    }
    families.add(catalog.definitionValue(unit) as ResourceFamily);
  }
  final classifications = {
    await for (final index in entries(
      CatalogDefinitionKind.resourceLibraryEntry,
    ))
      index.key.id: index.summary,
  };
  final items = <ProjectLibraryItem>[];
  for (final kind in ResourceLibraryCatalog.resourceKinds) {
    final catalogKind = _catalogFamily(kind);
    final loadDimensions =
        includeCompositeDimensions &&
        _libraryCompositeKinds.containsKey(catalogKind);
    await for (final page in _libraryIndexPages(snapshot, catalogKind)) {
      final dimensions = loadDimensions
          ? await _readLibraryDimensionPage(catalog, kind, page)
          : const <String, Set<ProjectDimension>>{};
      for (final index in page) {
        final identity = '$kind:${index.key.id}';
        items.add(
          _projectLibraryItem(
            kind,
            index,
            classifications[identity],
            compatibleDimensions: dimensions[identity],
          ),
        );
      }
    }
  }
  return ProjectResourceLibrary(
    ResourceLibraryCatalog(families: families),
    items,
    revision: revision,
  );
}, metadataFields: const {});

ProjectLibraryItem _projectLibraryItem(
  String kind,
  CatalogIndexEntry index,
  CatalogDefinitionSummary? info, {
  Set<ProjectDimension>? compatibleDimensions,
}) => ProjectLibraryItem(
  kind: kind,
  id: index.key.id,
  name: index.summary.name,
  tags: index.summary.tags,
  familyId: info?.familyId,
  mapId: info?.mapId,
  description: info?.description ?? index.summary.description,
  placementContext: ResourcePlacementContext.values
      .where(
        (context) =>
            context.name ==
            (info?.placementContext ?? index.summary.placementContext),
      )
      .firstOrNull,
  category: ResourceUsageCategory.values
      .where((category) => category.name == info?.category)
      .firstOrNull,
  role: info?.role == ResourceLibraryRole.component.name
      ? ResourceLibraryRole.component
      : ResourceLibraryRole.standard,
  compatibleDimensions: compatibleDimensions,
);

const _libraryCompositeKinds = {
  CatalogDefinitionKind.borderRecord: 'borderBlueprint',
  CatalogDefinitionKind.environmentPreset: 'environmentPreset',
  CatalogDefinitionKind.smartTilePreset: 'smartTilePreset',
};

Future<Set<ProjectDimension>> _readLibraryDimensions(
  PortableProjectCatalog catalog,
  CatalogIndexEntry index,
) async {
  final key = index.key;
  final compositeKind = _libraryCompositeKinds[key.kind];
  final unit = compositeKind == null ? null : await catalog.lookup(key);
  return resourceCompatibleDimensions(
    compositeKind ?? key.kind.name,
    definition: unit == null ? null : catalog.definitionValue(unit),
  );
}

Future<Map<String, Set<ProjectDimension>>> _readLibraryDimensionPage(
  PortableProjectCatalog catalog,
  String kind,
  List<CatalogIndexEntry> page,
) async => Map.fromEntries(
  await Future.wait(
    page.map(
      (entry) async => MapEntry(
        '$kind:${entry.key.id}',
        await _readLibraryDimensions(catalog, entry),
      ),
    ),
  ),
);

Future<Map<String, Set<ProjectDimension>>?>
_readProjectResourceLibraryDimensions(
  ProjectFileReader reader,
  ProjectSession session,
  String revision,
) {
  Future<Map<String, Set<ProjectDimension>>?> read() =>
      _readScopedCatalogWith(reader, session, (catalog, currentRevision) async {
        if (currentRevision != revision) return null;
        final dimensions = <String, Set<ProjectDimension>>{};
        for (final entry in _libraryCompositeKinds.entries) {
          await for (final page in _libraryIndexPages(
            catalog.snapshot,
            entry.key,
          )) {
            dimensions.addAll(
              await _readLibraryDimensionPage(catalog, entry.value, page),
            );
          }
        }
        return dimensions;
      }, metadataFields: const {});

  if (session.storage == ProjectSessionStorage.manifest) {
    return Future.value(null);
  }
  return reader is LocalProjectFileReader ? Isolate.run(read) : read();
}

Future<Map<String, Set<String>>?> _readProjectResourceLibraryMapUsages(
  ProjectFileReader reader,
  ProjectSession session,
  String revision,
  Iterable<String> identities,
) {
  Future<Map<String, Set<String>>?> read() =>
      _readScopedCatalogWith(reader, session, (catalog, currentRevision) async {
        if (currentRevision != revision) return null;
        final maps = catalog.projectMetadata.maps;
        return readCatalogResourceLibraryMapUsages(
          catalog.snapshot,
          identities: identities,
          mapIds: {for (final map in maps) map.id},
          exteriorMapTargets: await readExteriorDecorationResourceReferences(
            projectRoot: session.directoryPath,
            maps: maps,
            reader: reader,
          ),
        );
      }, metadataFields: const {'maps'});

  if (session.storage == ProjectSessionStorage.manifest) {
    return Future.value(null);
  }
  return reader is LocalProjectFileReader ? Isolate.run(read) : read();
}

Future<ProjectLibraryRelations?> _readProjectResourceLibraryRelations(
  ProjectFileReader reader,
  ProjectSession session,
  CatalogDefinitionKey key,
  String revision,
) {
  Future<ProjectLibraryRelations?> read() => _readScopedCatalogWith(
    reader,
    session,
    (catalog, observed) async => observed == revision
        ? readCatalogResourceLibraryRelations(catalog.snapshot, key)
        : null,
    metadataFields: const {},
  );

  if (session.storage == ProjectSessionStorage.manifest) {
    return Future.value(null);
  }
  return reader is LocalProjectFileReader ? Isolate.run(read) : read();
}
