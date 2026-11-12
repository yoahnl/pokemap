part of 'catalog_workshop_selection.dart';

const _usageReplacementMapLimit = 128;

Future<CatalogWorkshopSelection> _readUsageReplacementWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  const action = 'resource.usages.replace';
  final modelId = parameters['resourceId'];
  final replacementId = parameters['replacementId'];
  if (parameters['family'] != 'models3d' ||
      modelId is! String ||
      replacementId is! String ||
      parameters.length != 3) {
    CatalogWorkshopSelection.unsupported(action, 'a 3D model replacement');
  }
  final selected = await reader.withMetadataFields({'settings'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final snapshot = catalog.snapshot;
    final mapIds = <String>{};
    final borderIds = <String>{};
    for (final owner in await CatalogResourceUsageIndex.consumerOwners(
        snapshot, 'model3d:$modelId')) {
      if (owner.startsWith('map:')) {
        mapIds.add(owner.substring(4));
      } else if (owner.startsWith('border:')) {
        borderIds.add(owner.substring(7));
      } else {
        CatalogWorkshopSelection.unsupported(
            action, 'map placements and Border pieces only ($owner)');
      }
    }
    for (final id in borderIds) {
      for (final owner in await CatalogResourceUsageIndex.consumerOwners(
          snapshot, 'border:$id')) {
        if (!owner.startsWith('map:')) {
          CatalogWorkshopSelection.unsupported(
              action, 'Borders used only by maps ($owner)');
        }
        mapIds.add(owner.substring(4));
      }
    }
    if (mapIds.length > _usageReplacementMapLimit) {
      throw AuthoringPlanException(
          code: 'resource.usages.scope_too_large',
          message:
              'This replacement touches ${mapIds.length} maps; at most $_usageReplacementMapLimit are supported at once.');
    }
    final documents = await CatalogMetadataDocuments.readDocuments(
        snapshot: snapshot,
        project: catalog.projectMetadata,
        ids: {'maps': mapIds});
    final maps = <MapData>[];
    final values = <String, List<int>>{};
    final paths = <String, String>{};
    final fingerprints = <String, String>{};
    final revisions = <String, String?>{};
    for (final entry in documents.project.maps) {
      if (!mapIds.contains(entry.id)) continue;
      final payload =
          await reader.store.gateway.captureResourcePayload(entry.relativePath);
      if (payload == null) {
        throw const ProjectSnapshotException('project.map_missing',
            'A map using the replaced model is missing.');
      }
      try {
        final bytes = await payload.readBytes();
        final map = MapData.fromJson(
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
        if (map.id != entry.id) {
          throw const FormatException(
              'catalog.usage_replacement: map identity');
        }
        maps.add(map);
        values['map:${entry.id}'] = bytes;
        paths['map:${entry.id}'] = entry.relativePath;
        fingerprints['map:${entry.id}'] = payload.resourceRevision;
        revisions[entry.relativePath] = payload.resourceRevision;
      } finally {
        await payload.release();
      }
    }
    if (maps.length != mapIds.length) {
      throw const ProjectSnapshotException('project.map_missing',
          'A map using the replaced model is not declared.');
    }
    final roots = <CatalogDefinitionKey>{
      CatalogDefinitionKey(CatalogDefinitionKind.model3d, modelId),
      CatalogDefinitionKey(CatalogDefinitionKind.model3d, replacementId),
      for (final id in borderIds)
        CatalogDefinitionKey(CatalogDefinitionKind.borderRecord, id),
    };
    for (final id in [modelId, replacementId]) {
      final key = CatalogDefinitionKey(
          CatalogDefinitionKind.resourceLibraryEntry, 'model3d:$id');
      if (await snapshot.indexEntry(key) != null) roots.add(key);
    }
    final candidates = [for (final map in maps) map.toJson()];
    for (final (kind, keys) in const [
      (
        CatalogDefinitionKind.borderRecord,
        {'blueprintId', 'targetBlueprintId'}
      ),
      (CatalogDefinitionKind.model3d, {'modelId', 'sourceModelId'}),
      (CatalogDefinitionKind.element, {'elementId', 'sourceElementId'}),
      (CatalogDefinitionKind.tileset, {'tilesetId'}),
      (CatalogDefinitionKind.environmentPreset, {'presetId'}),
      (CatalogDefinitionKind.smartTileAtlas, {'atlasId'}),
      (
        CatalogDefinitionKind.smartTileMaterial,
        {'materialId', 'defaultMaterialId', 'allowedMaterialIds'}
      ),
      (CatalogDefinitionKind.smartTileAnimation, {'animationId'}),
      (CatalogDefinitionKind.smartTilePattern, {'patternId'}),
      (
        CatalogDefinitionKind.smartTilePreset,
        {'presetId', 'targetPresetId', 'sourceSmartTilePresetId'}
      ),
    ]) {
      for (final id
          in CatalogWorkshopSelection._referenceIds(candidates, keys)) {
        final key = CatalogDefinitionKey(kind, id);
        if (await snapshot.indexEntry(key) != null) roots.add(key);
      }
    }
    final definitions = await ProjectCatalogSelection(catalog).resolve(roots);
    final models = {for (final model in definitions.models3d) model.id};
    if (!models.contains(modelId) || !models.contains(replacementId)) {
      throw const FormatException(
          'catalog.usage_replacement: unknown model identity');
    }
    final settings = catalog.projectMetadata.settings;
    final manifest = definitions.copyWith(
        name: catalog.projectMetadata.name,
        settings: settings,
        maps: [
          for (final entry in documents.project.maps)
            if (mapIds.contains(entry.id)) entry
        ]);
    final bytes = utf8.encode(jsonEncode(manifest.toJson()));
    final count = await CatalogResourcePositions.read(
        snapshot, CatalogDefinitionKind.borderRecord);
    final projectSnapshot = ProjectSnapshot(
        projectHandle: projectHandle,
        materializedCatalogProject: true,
        revision:
            CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
        manifest: manifest,
        maps: maps,
        availableProjectSections: const {
          'settings',
          'maps',
          'models3d',
          'borderCatalog'
        },
        availableProjectDocuments: {'maps': mapIds},
        scopedStorageRevisions: revisions,
        resourceBytes: {...values, 'project': bytes},
        resourceStorageKeys: {...paths, 'project': 'project.json'},
        resourceFingerprints: {
          ...fingerprints,
          'project': computeAuthoringBytesFingerprint(bytes,
              logicalName: 'project.json'),
        });
    final result = CatalogWorkshopSelection._(
        selected, projectSnapshot, {'borderCatalog'}, revisions,
        resourceCounts: {CatalogDefinitionKind.borderRecord: count},
        resourceReplacements: {
          for (final id in borderIds)
            CatalogDefinitionKey(CatalogDefinitionKind.borderRecord, id)
        });
    await result.requireCurrent();
    return result;
  });
}
