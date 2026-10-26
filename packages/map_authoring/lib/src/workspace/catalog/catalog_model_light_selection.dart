part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readModelLightWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  const action = 'model3d.configure';
  if (!parameters.containsKey('light') ||
      parameters['modelId'] is! String ||
      parameters.keys.any((key) => !{'modelId', 'light'}.contains(key))) {
    CatalogWorkshopSelection.unsupported(
        action, 'a light-only model configuration');
  }
  final id = parameters['modelId']! as String;
  final selected = await reader.withMetadataFields({'settings'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final unit = await catalog.lookup(
      CatalogDefinitionKey(CatalogDefinitionKind.model3d, id),
    );
    if (unit == null) throw const FormatException('Unknown model identity.');
    final model = ProjectModel3dEntry.fromJson(
      Map<String, dynamic>.from(unit.payload['value']! as Map),
    );
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
        tileHeight: settings.tileHeight,
      ),
      maps: const [],
      tilesets: const [],
      models3d: [model],
    );
    final bytes = utf8.encode(jsonEncode(manifest.toJson()));
    final snapshot = ProjectSnapshot(
        projectHandle: projectHandle,
        revision: selected.revision,
        materializedCatalogProject: true,
        manifest: manifest,
        maps: const [],
        availableProjectSections: {
          'settings',
          'models3d'
        },
        availableProjectDocuments: {
          'models3d': {id}
        },
        resourceBytes: {
          'project': bytes
        },
        resourceStorageKeys: {
          'project': 'project.json'
        },
        resourceFingerprints: {
          'project': computeAuthoringBytesFingerprint(bytes,
              logicalName: 'project.json')
        });
    final result =
        CatalogWorkshopSelection._(selected, snapshot, {'models3d'}, {});
    await result.requireCurrent();
    return result;
  });
}
