import '../models/project_manifest.dart';

bool resourceLibraryResourceExists(
  ProjectManifest project,
  String kind,
  String id,
) => _resourceLibraryIds(project, kind).contains(id);

Iterable<String> _resourceLibraryIds(
  ProjectManifest project,
  String kind,
) => switch (kind) {
  'element' => project.elements.map((entry) => entry.id),
  'model3d' => project.models3d.map((entry) => entry.id),
  'smartTilePreset' => project.smartTileCatalog.presets.map(
    (entry) => entry.id,
  ),
  'tileset' => project.tilesets.map((entry) => entry.id),
  'borderBlueprint' => project.borderCatalog.records.map((entry) => entry.id),
  'environmentPreset' => project.environmentPresets.map((entry) => entry.id),
  'character' => project.characters.map((entry) => entry.id),
  _ => const [],
};

void validateResourceLibraryTargets(ProjectManifest project) {
  final resources = <String, Set<String>>{};
  final maps = project.maps.map((map) => map.id).toSet();
  for (final entry in project.resourceLibraryCatalog.entries) {
    final ids = resources.putIfAbsent(
      entry.resourceKind,
      () => _resourceLibraryIds(project, entry.resourceKind).toSet(),
    );
    if (!ids.contains(entry.resourceId)) {
      throw ArgumentError.value(
        entry.identity,
        'resourceLibraryCatalog',
        'unknown resource',
      );
    }
    if (entry.mapId != null && !maps.contains(entry.mapId)) {
      throw ArgumentError.value(
        entry.mapId,
        'resourceLibraryCatalog',
        'unknown map scope',
      );
    }
  }
}
