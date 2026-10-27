part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readMapCreationWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  final mapId = parameters['mapId'];
  if (mapId is! String ||
      mapId.length > 64 ||
      !RegExp(r'^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$').hasMatch(mapId)) {
    throw const FormatException(
        'catalog.map_creation: canonical mapId required');
  }
  final selected = await reader.withMetadataFields({'settings'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final settings = catalog.projectMetadata.settings;
    if (settings.dimension != ProjectDimension.threeD) {
      CatalogWorkshopSelection.unsupported('map.create',
          'a targeted default-tileset selection for two-dimensional projects');
    }
    final path = 'maps/$mapId.json';
    final owners = await CatalogMetadataDocuments.readMapOwnerIds(
        snapshot: catalog.snapshot, mapId: mapId, relativePath: path);
    final ids = <String, Set<String>>{
      'maps': {mapId, ...owners},
      'groups': {
        if (parameters['groupId'] case final String groupId) groupId,
      },
    };
    final base = ProjectManifest(
        name: catalog.projectMetadata.name,
        version: ProjectVersion.v9,
        maps: const [],
        tilesets: const [],
        settings: ProjectSettings(
          dimension: settings.dimension,
          spatialCamera: settings.spatialCamera,
          tileWidth: settings.tileWidth,
          tileHeight: settings.tileHeight,
        ));
    var documents = await CatalogMetadataDocuments.readDocuments(
        snapshot: catalog.snapshot, project: base, ids: ids);
    while (true) {
      final parents = documents.project.groups
          .map((group) => group.parentGroupId)
          .whereType<String>()
          .toSet()
          .difference(ids['groups']!);
      if (parents.isEmpty) break;
      ids['groups']!.addAll(parents);
      documents = await CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot, project: base, ids: ids);
    }
    final revisions = <String, String?>{
      path: await reader.store.gateway.readResourceRevision(path),
    };
    final bytes = utf8.encode(jsonEncode(documents.project.toJson()));
    final snapshot = ProjectSnapshot(
        projectHandle: projectHandle,
        materializedCatalogProject: true,
        revision:
            CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
        manifest: documents.project,
        maps: const [],
        availableProjectSections: const {'settings', 'maps', 'groups'},
        availableProjectDocuments: ids,
        resourceBytes: {'project': bytes},
        resourceStorageKeys: {'project': 'project.json'},
        resourceFingerprints: {
          'project': computeAuthoringBytesFingerprint(bytes,
              logicalName: 'project.json'),
        });
    final result = CatalogWorkshopSelection._(
        selected, snapshot, {'maps'}, revisions,
        metadataDocuments: documents);
    await result.requireCurrent();
    return result;
  });
}
