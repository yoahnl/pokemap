part of 'catalog_workshop_selection.dart';

final _canonicalMapId = RegExp(r'^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$');

Future<CatalogWorkshopSelection> _readMapDuplicateWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  final sourceId = parameters['sourceMapId'];
  final targetId = parameters['targetMapId'];
  final requestedGroup = parameters['groupId'];
  if (sourceId is! String ||
      targetId is! String ||
      targetId.length > 64 ||
      !_canonicalMapId.hasMatch(targetId) ||
      (parameters.containsKey('groupId') &&
          requestedGroup != null &&
          requestedGroup is! String)) {
    CatalogWorkshopSelection.unsupported(
        'map.duplicate', 'an explicit canonical targetMapId');
  }
  final selected = await reader.withMetadataFields({'settings'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final targetPath = 'maps/$targetId.json';
    final owners = await CatalogMetadataDocuments.readMapOwnerIds(
        snapshot: catalog.snapshot, mapId: targetId, relativePath: targetPath);
    final settings = catalog.projectMetadata.settings;
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
    final ids = <String, Set<String>>{
      'maps': {sourceId, ...owners},
      'groups': {}
    };
    var documents = await CatalogMetadataDocuments.readDocuments(
        snapshot: catalog.snapshot, project: base, ids: ids);
    final entry =
        documents.project.maps.where((map) => map.id == sourceId).firstOrNull;
    if (entry == null) {
      CatalogWorkshopSelection.unsupported(
          'map.duplicate', 'a source map listed in the catalog');
    }
    final groupId = parameters.containsKey('groupId')
        ? requestedGroup as String?
        : entry.groupId;
    if (groupId != null) ids['groups']!.add(groupId);
    while (true) {
      documents = await CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot, project: base, ids: ids);
      final parents = documents.project.groups
          .map((group) => group.parentGroupId)
          .whereType<String>()
          .toSet()
          .difference(ids['groups']!);
      if (parents.isEmpty) break;
      ids['groups']!.addAll(parents);
    }
    final payload =
        await reader.store.gateway.captureResourcePayload(entry.relativePath);
    if (payload == null) {
      CatalogWorkshopSelection.unsupported(
          'map.duplicate', 'a readable source map document');
    }
    final List<int> mapBytes;
    try {
      mapBytes = await payload.readBytes();
    } finally {
      await payload.release();
    }
    final source = MapData.fromJson(
        Map<String, dynamic>.from(jsonDecode(utf8.decode(mapBytes)) as Map));
    if (source.id != sourceId) {
      throw const FormatException(
          'catalog.map_duplicate: source identity mismatch');
    }
    final revisions = <String, String?>{
      entry.relativePath: payload.resourceRevision,
      targetPath: await reader.store.gateway.readResourceRevision(targetPath),
    };
    final bytes = utf8.encode(jsonEncode(documents.project.toJson()));
    final snapshot = ProjectSnapshot(
        projectHandle: projectHandle,
        materializedCatalogProject: true,
        revision:
            CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
        manifest: documents.project,
        maps: [source],
        availableProjectSections: const {'settings', 'maps', 'groups'},
        availableProjectDocuments: ids,
        scopedStorageRevisions: revisions,
        resourceBytes: {'project': bytes, 'map:$sourceId': mapBytes},
        resourceStorageKeys: {
          'project': 'project.json',
          'map:$sourceId': entry.relativePath
        },
        resourceFingerprints: {
          'project': computeAuthoringBytesFingerprint(bytes,
              logicalName: 'project.json'),
          'map:$sourceId': payload.resourceRevision,
        });
    final result = CatalogWorkshopSelection._(
        selected, snapshot, {'maps'}, revisions,
        metadataDocuments: documents);
    await result.requireCurrent();
    return result;
  });
}
