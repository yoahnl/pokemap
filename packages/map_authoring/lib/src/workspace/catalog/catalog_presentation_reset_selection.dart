part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readPresentationResetWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
}) async {
  final selected = await reader.withMetadataFields({'presentation'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final manifest = catalog.projectMetadata;
    final bytes = utf8.encode(jsonEncode(manifest.toJson()));
    final snapshot = ProjectSnapshot(
      projectHandle: projectHandle,
      revision: selected.revision,
      materializedCatalogProject: true,
      manifest: manifest,
      maps: const [],
      availableProjectSections: {'presentation'},
      resourceBytes: {'project': bytes},
      resourceStorageKeys: {'project': 'project.json'},
      resourceFingerprints: {
        'project': computeAuthoringBytesFingerprint(bytes,
            logicalName: 'project.json'),
      },
    );
    final result =
        CatalogWorkshopSelection._(selected, snapshot, {'presentation'}, {});
    await result.requireCurrent();
    return result;
  });
}
