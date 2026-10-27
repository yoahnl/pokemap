part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readMapMetadataWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  if (parameters.containsKey('escapeRopeDungeonId')) {
    CatalogWorkshopSelection.unsupported('map.update_metadata',
        'local map properties without dungeon reassignment');
  }
  final spatial = await CatalogSpatialMapSelection.read(
      reader: reader,
      projectHandle: projectHandle,
      actionId: 'map.update_metadata',
      parameters: parameters);
  final source = spatial.snapshot;
  final documents = await spatial.reader.read((catalog) =>
      CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot,
          project: source.manifest,
          ids: {'maps': source.manifest.maps.map((map) => map.id).toSet()}));
  final revisions = {spatial.storageKey: spatial.mapRevision};
  final snapshot = ProjectSnapshot(
      projectHandle: projectHandle,
      materializedCatalogProject: true,
      revision: CatalogWorkshopSelection.fingerprint(
          spatial.reader.revision, revisions),
      manifest: source.manifest,
      maps: source.maps,
      availableProjectSections: const {'maps'},
      scopedStorageRevisions: revisions,
      resourceBytes: {
        for (final key in source.resourceStorageKeys.keys)
          key: source.resourceBytes(key)
      },
      resourceStorageKeys: source.resourceStorageKeys,
      resourceFingerprints: source.resourceFingerprints);
  final selection = CatalogWorkshopSelection._(
      spatial.reader, snapshot, {'maps'}, revisions,
      metadataDocuments: documents);
  await selection.requireCurrent();
  return selection;
}
