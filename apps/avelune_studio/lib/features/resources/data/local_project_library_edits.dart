part of 'local_resource_adapter.dart';

ProjectManifest _mergeImportedLibraryResource(
  ProjectManifest before,
  ProjectManifest imported, {
  required String? modelId,
}) => before.copyWith(
  tilesets: imported.tilesets.isEmpty
      ? before.tilesets
      : [...before.tilesets, ...imported.tilesets],
  models3d: modelId == null
      ? before.models3d
      : ProjectModel3dEntries.prepare([
          ...before.models3d,
          imported.models3d.singleWhere((model) => model.id == modelId),
        ]),
  smartTileCatalog: imported.smartTileCatalog.presets.isEmpty
      ? before.smartTileCatalog
      : _mergeImportedTerrains(
          before.smartTileCatalog,
          imported.smartTileCatalog,
        ),
  resourceLibraryCatalog: modelId == null
      ? before.resourceLibraryCatalog
      : mergeResourceLibraryCatalogs(
          before.resourceLibraryCatalog,
          ResourceLibraryCatalog(
            families: imported.resourceLibraryCatalog.families,
            entries: imported.resourceLibraryCatalog.entries.where(
              (entry) => entry.resourceId == modelId,
            ),
          ),
        ),
);

ProjectSmartTileCatalog _mergeImportedTerrains(
  ProjectSmartTileCatalog previous,
  ProjectSmartTileCatalog imported,
) => ProjectSmartTileCatalog(
  categories: previous.categories,
  atlases: [...previous.atlases, ...imported.atlases],
  materials: [...previous.materials, ...imported.materials],
  animations: previous.animations,
  presets: [...previous.presets, ...imported.presets],
  patterns: previous.patterns,
  drafts: previous.drafts,
);

extension _LocalProjectLibraryEdits on LocalResourceAdapter {
  void _requireLibraryEditing() {
    _requireAvailable();
    if (session.storage != ProjectSessionStorage.workingCatalog) {
      throw const ResourceFailure(
        'Ce projet ne possède pas de catalogue de travail.',
      );
    }
  }

  Future<String> _projectedLibraryRevision(AuthoringPlan plan) {
    final head = plan.changeSet.changes
        .where(
          (change) => change.storageKey == CatalogStorageStore.headStorageKey,
        )
        .firstOrNull
        ?.afterBytes;
    if (head == null) {
      throw const ResourceFailure(
        'La révision de publication est indisponible.',
      );
    }
    return mapAdapter.resourceRevision(session, projectedCatalogHead: head);
  }

  Future<ProjectLibraryEdit> _readLibraryEdit(
    String kind,
    String id,
    ResourceMutationReceipt receipt,
  ) async {
    try {
      return (
        item: await mapAdapter.readResourceLibraryItem(
          session,
          kind,
          id,
          expectedRevision: receipt.revision,
        ),
        receipt: receipt,
      );
    } on Object {
      if (receipt.noChange) rethrow;
      throw ResourceFailure(
        'La modification est enregistrée. Actualisez la bibliothèque pour relire la fiche.',
        partialReceipt: receipt,
      );
    }
  }

  Future<ProjectLibraryEdit> _importLibraryResource(
    PickedProjectLibraryFile file,
    String name,
    LibraryImageSize? tileSize,
    String expectedRevision,
  ) async {
    _requireLibraryEditing();
    final title = _libraryName(name);
    if (file.imageSize != null) {
      if (tileSize == null) {
        throw const ResourceFailure('Indiquez la taille des tuiles.');
      }
      final receipt = await _importResourceImage(
        this,
        ResourceImageImport(
          sourcePath: file.path,
          name: title,
          tileWidth: tileSize.width,
          tileHeight: tileSize.height,
        ),
        expectedBeforeRevision: expectedRevision,
        expectedSource: file.artifact,
      );
      return _readLibraryEdit('tileset', receipt.createdTilesetId!, receipt);
    }
    final id = _identity('model');
    final receipt = await _run(
      'model3d.import',
      (_) => {'modelId': id, 'name': title},
      sourcePath: file.path,
      sourceMediaType: 'model/gltf-binary',
      expectedBeforeRevision: expectedRevision,
      expectedSource: file.artifact,
    );
    return _readLibraryEdit('model3d', id, receipt);
  }

  Future<ProjectLibraryEdit> _classifyLibraryResource(
    ProjectLibraryItem item,
    String? familyId,
    ResourceLibraryRole role,
    String expectedRevision,
  ) => _publishLibraryClassification(item, {
    'familyId': familyId,
    'role': role.name,
  }, expectedRevision);

  Future<ProjectLibraryEdit> _publishLibraryClassification(
    ProjectLibraryItem item,
    Map<String, Object?> fields,
    String expectedRevision,
  ) async {
    _requireLibraryEditing();
    final preparation = await _prepareCatalogClassification(
      this,
      'resource.classify',
      {'resourceKind': item.kind, 'resourceId': item.id, ...fields},
      expectedRevision,
    );
    final receipt = await _applyScopedClassification(this, preparation);
    if (receipt == null) {
      throw const ResourceFailure(
        'La préparation du catalogue est incomplète. Rouvrez le projet puis réessayez.',
      );
    }
    return _readLibraryEdit(item.kind, item.id, receipt);
  }

  Future<ProjectLibraryEdit> _renameLibraryResource(
    ProjectLibraryItem item,
    String name,
    String expectedRevision,
  ) async => _readLibraryEdit(
    item.kind,
    item.id,
    await _publishLibraryDefinition('catalog.definition.update', {
      'resourceKind': item.kind,
      'id': item.id,
      'name': _libraryName(name),
    }, expectedRevision),
  );
}

String _libraryName(String value) {
  final name = value.trim();
  if (name.isEmpty) throw const ResourceFailure('Saisissez un nom.');
  return name;
}

ResourceFailure _libraryImportFailure(Object error) =>
    ResourceFailure(switch (error) {
      ArtifactStoreException(
        code: 'artifact.source_changed_after_authorization' ||
            'artifact.source_changed_during_read' ||
            'artifact.mime_mismatch',
      ) =>
        'Le fichier choisi a changé. Sélectionnez-le à nouveau.',
      ArtifactStoreException(code: 'artifact.too_large') =>
        'Le fichier choisi dépasse la taille maximale d’import.',
      ArtifactStoreException() =>
        'Le fichier choisi est inaccessible. Sélectionnez-le à nouveau.',
      AuthoringPlanException(code: 'plan.stale') ||
      CatalogStorageException(
        code: 'catalog.revision_conflict',
      ) => 'Le catalogue a changé. Actualisez la bibliothèque puis réessayez.',
      CatalogStorageException(code: 'catalog.preparation_required') ||
      FormatException(
        message: 'catalog.resource_positions.preparation_required',
      ) => 'Le catalogue doit être préparé. Rouvrez le projet puis réessayez.',
      _ => 'L’import a échoué. Vérifiez la source et réessayez.',
    });
