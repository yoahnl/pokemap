part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readAssetImportWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required String actionId,
  required Map<String, Object?> parameters,
}) async {
  final model = actionId.startsWith('model3d.');
  final kind =
      model ? CatalogDefinitionKind.model3d : CatalogDefinitionKind.tileset;
  final inputs =
      actionId == 'model3d.import_batch' ? parameters['models'] : [parameters];
  if (inputs is! List || inputs.isEmpty || inputs.length > 50) {
    throw const FormatException(
        'catalog.asset_import: expected 1 to 50 imports');
  }
  final ids = <String>{};
  for (final input in inputs) {
    final id = input is Map ? input[model ? 'modelId' : 'tilesetId'] : null;
    if (id is! String ||
        !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) ||
        !ids.add(id)) {
      throw const FormatException(
          'catalog.asset_import: invalid or duplicate identity');
    }
  }
  final selected = await reader.withMetadataFields({'settings'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final count = await CatalogResourcePositions.read(catalog.snapshot, kind);
    for (final id in ids) {
      if (await catalog.snapshot.indexEntry(CatalogDefinitionKey(kind, id)) !=
          null) {
        throw const FormatException(
            'catalog.asset_import: identity already in use');
      }
    }
    final settings = catalog.projectMetadata.settings;
    final manifest = ProjectManifest(
        name: catalog.projectMetadata.name,
        version: settings.dimension == ProjectDimension.threeD
            ? ProjectVersion.v9
            : ProjectVersion.v8,
        settings: ProjectSettings(
            dimension: settings.dimension,
            spatialCamera: settings.spatialCamera,
            tileWidth: settings.tileWidth,
            tileHeight: settings.tileHeight),
        maps: const [],
        tilesets: const []);
    final values = <String, List<int>>{};
    final paths = <String, String>{};
    final revisions = <String, String?>{};
    Future<void> readFile(String identity, String path) async {
      if (revisions.containsKey(path)) return;
      final payload = await reader.store.gateway.captureResourcePayload(path);
      revisions[path] = payload?.resourceRevision;
      if (payload == null) return;
      try {
        values[identity] = await payload.readBytes();
        paths[identity] = path;
      } finally {
        await payload.release();
      }
    }

    await readFile(assetCatalogResourceIdentity, assetCatalogStorageKey);
    for (final input in inputs.cast<Map>()) {
      final id = input[model ? 'modelId' : 'tilesetId'] as String;
      final path = model ? 'assets/models3d/$id.glb' : 'assets/studio/$id.png';
      revisions[path] = await reader.store.gateway.readResourceRevision(path);
      if (revisions[path] != null) {
        throw const FormatException(
            'catalog.asset_import: destination already exists');
      }
      final handle = input['artifactHandle'];
      if (handle is String) {
        final match =
            RegExp(r'^artifact://sha256/([0-9a-f]{64})$').firstMatch(handle);
        if (match != null) {
          final digest = match.group(1)!;
          await readFile(assetBlobResourceIdentity('sha256:$digest'),
              'assets/.pokemap-store/$digest.blob');
        }
      }
    }
    final bytes = utf8.encode(jsonEncode(manifest.toJson()));
    final snapshot = ProjectSnapshot(
        projectHandle: projectHandle,
        materializedCatalogProject: true,
        revision:
            CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
        manifest: manifest,
        maps: const [],
        availableProjectSections: {
          'settings',
          CatalogResourcePositions.sections[kind]!
        },
        availableProjectDocuments: {
          CatalogResourcePositions.sections[kind]!: ids
        },
        resourceBytes: {
          ...values,
          'project': bytes
        },
        resourceStorageKeys: {
          ...paths,
          'project': 'project.json'
        },
        resourceFingerprints: {
          'project': computeAuthoringBytesFingerprint(bytes,
              logicalName: 'project.json'),
          for (final entry in paths.entries) entry.key: revisions[entry.value]!,
        });
    final result = CatalogWorkshopSelection._(selected, snapshot,
        {CatalogResourcePositions.sections[kind]!}, revisions,
        resourceCounts: {kind: count});
    await result.requireCurrent();
    return result;
  });
}
