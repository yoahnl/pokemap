part of 'local_map_workspace_adapter.dart';

Future<ProjectResourceLibrary> _readProjectResourceLibrary(
  ProjectFileReader reader,
  ProjectSession session,
) => _readScopedCatalogWith(reader, session, (catalog, _) async {
  final snapshot = catalog.snapshot;
  Stream<CatalogIndexEntry> entries(CatalogDefinitionKind kind) async* {
    String? cursor;
    do {
      final page = await snapshot.page(
        kind: kind,
        limit: snapshot.limits.indexPageSize,
        cursor: cursor,
      );
      yield* Stream.fromIterable(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
  }

  final families = <ResourceFamily>[];
  await for (final index in entries(CatalogDefinitionKind.resourceFamily)) {
    final unit = await catalog.lookup(index.key);
    if (unit == null) {
      throw FormatException(
        'catalog.selection: missing definition ${index.key}',
      );
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
    await for (final index in entries(_catalogFamily(kind))) {
      final info = classifications['$kind:${index.key.id}'];
      items.add(
        ProjectLibraryItem(
          kind: kind,
          id: index.key.id,
          name: index.summary.name,
          tags: index.summary.tags,
          familyId: info?.familyId,
          mapId: info?.mapId,
          description: info?.description,
          role: info?.role == ResourceLibraryRole.component.name
              ? ResourceLibraryRole.component
              : ResourceLibraryRole.standard,
        ),
      );
    }
  }
  return ProjectResourceLibrary(
    ResourceLibraryCatalog(families: families),
    items,
  );
}, metadataFields: const {});
