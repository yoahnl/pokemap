part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readSurfWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  final configuration = parameters['configuration'];
  final activeCondition =
      configuration is Map && configuration['accessMode'] == 'condition'
          ? configuration['condition']
          : null;
  final itemIds =
      CatalogWorkshopSelection._referenceIds(activeCondition, {'itemId'});
  final selected = await reader
      .withMetadataFields({'settings', if (itemIds.isNotEmpty) 'pokemon'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final ids = <String, Set<String>>{};
    final candidates = [activeCondition];
    for (final entry in const {
      'facts': {'factId'},
      'badges': {'badgeId'},
      'maps': {'mapId'},
    }.entries) {
      final references =
          CatalogWorkshopSelection._referenceIds(candidates, entry.value);
      if (references.isNotEmpty) ids[entry.key] = references;
    }
    for (final id
        in CatalogWorkshopSelection._referenceIds(candidates, {'stepId'})) {
      final owners = await CatalogMetadataDocuments.readStorylineIdsForStep(
          snapshot: catalog.snapshot, stepId: id);
      if (owners.isNotEmpty) {
        ids.putIfAbsent('storylines', () => {}).addAll(owners);
      }
    }
    final documents = await CatalogMetadataDocuments.readDocuments(
        snapshot: catalog.snapshot, project: catalog.projectMetadata, ids: ids);
    final manifest = documents.project;
    final revisions = <String, String?>{};
    List<int>? itemBytes;
    List<int>? mediaBytes;
    List<int>? assetBytes;
    if (parameters['binding'] case final Map binding when binding['source'] == 'custom') {
      for (final entry in {
        projectMediaCatalogResourceIdentity: projectMediaCatalogStorageKey,
        assetCatalogResourceIdentity: assetCatalogStorageKey,
      }.entries) {
        final payload = await reader.store.gateway.captureResourcePayload(entry.value);
        revisions[entry.value] = payload?.resourceRevision;
        if (payload == null) continue;
        try {
          final value = await payload.readBytes();
          if (entry.key == projectMediaCatalogResourceIdentity) { mediaBytes = value; } else { assetBytes = value; }
        } finally { await payload.release(); }
      }
    }
    final itemPath =
        itemIds.isEmpty ? null : manifest.pokemon.catalogFiles['items'];
    if (itemPath != null) {
      final payload =
          await reader.store.gateway.captureResourcePayload(itemPath);
      revisions[itemPath] = payload?.resourceRevision;
      if (payload != null) {
        try {
          itemBytes = await payload.readBytes();
        } finally {
          await payload.release();
        }
      }
    }
    final bytes = utf8.encode(jsonEncode(manifest.toJson()));
    final snapshot = ProjectSnapshot(
      materializedCatalogProject: true,
      projectHandle: projectHandle,
      revision:
          CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
      manifest: manifest,
      maps: const [],
      availableProjectSections: {'settings', ...ids.keys},
      availableProjectDocuments: ids,
      resourceBytes: {
        'project': bytes,
        if (mediaBytes != null) projectMediaCatalogResourceIdentity: mediaBytes,
        if (assetBytes != null) assetCatalogResourceIdentity: assetBytes,
        if (itemBytes != null) itemCatalogResourceIdentity: itemBytes
      },
      resourceStorageKeys: {
        'project': 'project.json',
        if (mediaBytes != null) projectMediaCatalogResourceIdentity: projectMediaCatalogStorageKey,
        if (assetBytes != null) assetCatalogResourceIdentity: assetCatalogStorageKey,
        if (itemBytes != null) itemCatalogResourceIdentity: itemPath!
      },
      resourceFingerprints: {
        'project': computeAuthoringBytesFingerprint(bytes,
            logicalName: 'project.json'),
        if (mediaBytes != null) projectMediaCatalogResourceIdentity: revisions[projectMediaCatalogStorageKey]!,
        if (assetBytes != null) assetCatalogResourceIdentity: revisions[assetCatalogStorageKey]!,
        if (itemBytes != null) itemCatalogResourceIdentity: revisions[itemPath]!
      },
      itemCatalog: itemBytes == null
          ? null
          : decodeProjectItemCatalog(Map<String, dynamic>.from(
              jsonDecode(utf8.decode(itemBytes)) as Map)),
    );
    final result = CatalogWorkshopSelection._(
        selected, snapshot, {'settings'}, revisions,
        metadataDocuments: documents);
    await result.requireCurrent();
    return result;
  });
}
