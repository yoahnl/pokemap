part of 'local_map_workspace_adapter.dart';

extension _LocalScopedMapCatalog on LocalMapWorkspaceAdapter {
  Future<MapWorkspaceCatalog> _loadScopedCatalog(ProjectSession session) async {
    await _requireRoot(session);
    _resourceSelections.remove(session.sessionId);
    _resourceKindReads.remove(session.sessionId);
    _onDemandSelections.remove(session.sessionId);
    _workshopCharacterDefinitions.remove(session.sessionId);
    final result = await _readScopedCatalog(session, (catalog, revision) async {
      return MapWorkspaceCatalog(
        metadata: catalog.projectMetadata.copyWith(
          models3d: ProjectModel3dEntries.prepare(catalog.projectMetadata.models3d),
        ),
        revision: revision,
      );
    });
    _projects[session.sessionId] = _ProjectDocument(
      session.directoryPath,
      result.metadata,
      result.revision,
      complete: false,
      metadataFields: _mapCatalogMetadataFields,
      onMapEntryRead: onMapMetadataEntryRead,
    );
    return MapWorkspaceCatalog(metadata: _project(session).manifest, revision: result.revision);
  }

  Future<MapWorkspaceCatalog> _loadWorkshop(
    ProjectSession session,
    MapWorkspaceWorkshop workshop,
  ) async {
    final current = _project(session);
    final projection = await _readScopedCatalog(
      session,
      (catalog, revision) async {
        if (revision != current.revision) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'Le catalogue a changé avant l’ouverture de cet atelier.',
          );
        }
        var manifest = catalog.projectMetadata;
        if (workshop == MapWorkspaceWorkshop.dialogue ||
            workshop == MapWorkspaceWorkshop.cinematic) {
          final roots = <CatalogDefinitionKey>[];
          String? cursor;
          do {
            final page = await catalog.snapshot.page(
              kind: CatalogDefinitionKind.character,
              limit: catalog.snapshot.limits.indexPageSize,
              cursor: cursor,
            );
            roots.addAll(page.items.map((entry) => entry.key));
            cursor = page.nextCursor;
          } while (cursor != null);
          manifest = await ProjectCatalogSelection(catalog).resolve(roots);
        }
        return MapWorkspaceCatalog(metadata: manifest, revision: revision);
      },
      metadataFields: workshop == MapWorkspaceWorkshop.resources
          ? {'settings', ...workshop.metadataFields}
          : {..._mapCatalogMetadataFields, ...workshop.metadataFields},
    );
    if (workshop == MapWorkspaceWorkshop.dialogue ||
        workshop == MapWorkspaceWorkshop.cinematic) {
      _workshopCharacterDefinitions[session.sessionId] = projection.metadata.copyWith(
        models3d: ProjectModel3dEntries.prepare(projection.metadata.models3d),
      );
    }
    final latest = _project(session);
    if (latest.revision != projection.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé pendant l’ouverture de cet atelier.',
      );
    }
    final merged = workshop.merge(latest.manifest, projection.metadata);
    _projects[session.sessionId] = _ProjectDocument(
      latest.root,
      merged.copyWith(models3d: ProjectModel3dEntries.prepare(merged.models3d)),
      projection.revision,
      complete: false,
      metadataFields: {
        ...?latest.metadataFields,
        ..._mapCatalogMetadataFields,
        ...workshop.metadataFields,
      },
    );
    return projection;
  }

  Future<MapWorkspaceCatalog> _loadOnDemandSelection(
    ProjectSession session,
    CatalogDefinitionKey? root,
  ) async {
    final before = _project(session);
    final result = await _readScopedCatalog(
      session,
      (catalog, revision) async {
        if (revision != before.revision) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'Le catalogue a changé avant le chargement de ces ressources.',
          );
        }
        final ProjectManifest manifest;
        if (root != null) {
          manifest = await ProjectCatalogSelection(catalog).resolve([root]);
        } else {
          final units = <CatalogDefinitionUnit>[];
          for (final kind in const [
            CatalogDefinitionKind.borderRecord,
            CatalogDefinitionKind.resourceFamily,
          ]) {
            String? cursor;
            do {
              final page = await catalog.snapshot.page(
                kind: kind,
                limit: catalog.snapshot.limits.indexPageSize,
                cursor: cursor,
              );
              for (final entry in page.items) {
                units.add((await catalog.lookup(entry.key))!);
                if (kind != CatalogDefinitionKind.borderRecord) continue;
                final classification = await catalog.lookup(
                  CatalogDefinitionKey(
                    CatalogDefinitionKind.resourceLibraryEntry,
                    'borderBlueprint:${entry.key.id}',
                  ),
                );
                if (classification != null) units.add(classification);
              }
              cursor = page.nextCursor;
            } while (cursor != null);
          }
          manifest = catalog.projectWithDefinitions(units);
        }
        return MapWorkspaceCatalog(
          metadata: manifest.copyWith(
            models3d: ProjectModel3dEntries.prepare(manifest.models3d),
          ),
          revision: revision,
        );
      },
      metadataFields: const {'settings', 'globalProperties'},
    );
    final latest = _project(session);
    if (latest.revision != result.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé pendant le chargement de ces ressources.',
      );
    }
    final previous = _onDemandSelections[session.sessionId];
    _onDemandSelections[session.sessionId] = previous == null
        ? result.metadata
        : combineResourceVisuals(previous, result.metadata);
    final merged = mergeBorderSelection(latest.manifest, result.metadata);
    _projects[session.sessionId] = _ProjectDocument(
      latest.root,
      merged.copyWith(models3d: ProjectModel3dEntries.prepare(merged.models3d)),
      result.revision,
      complete: false,
      metadataFields: latest.metadataFields,
    );
    return result;
  }
}

