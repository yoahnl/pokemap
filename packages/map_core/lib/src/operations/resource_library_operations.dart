import '../models/project_manifest.dart';

bool resourceLibraryResourceExists(
  ProjectManifest project,
  String kind,
  String id,
) => switch (kind) {
  'element' => project.elements.any((entry) => entry.id == id),
  'model3d' => project.models3d.any((entry) => entry.id == id),
  'smartTilePreset' => project.smartTileCatalog.presets.any(
    (entry) => entry.id == id,
  ),
  'tileset' => project.tilesets.any((entry) => entry.id == id),
  'borderBlueprint' => project.borderCatalog.records.any(
    (entry) => entry.id == id,
  ),
  'environmentPreset' => project.environmentPresets.any(
    (entry) => entry.id == id,
  ),
  'character' => project.characters.any((entry) => entry.id == id),
  _ => false,
};

void validateResourceLibraryTargets(ProjectManifest project) {
  for (final entry in project.resourceLibraryCatalog.entries) {
    if (!resourceLibraryResourceExists(
      project,
      entry.resourceKind,
      entry.resourceId,
    )) {
      throw ArgumentError.value(
        entry.identity,
        'resourceLibraryCatalog',
        'unknown resource',
      );
    }
    if (entry.mapId != null &&
        !project.maps.any((map) => map.id == entry.mapId)) {
      throw ArgumentError.value(
        entry.mapId,
        'resourceLibraryCatalog',
        'unknown map scope',
      );
    }
  }
}
