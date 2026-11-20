import 'package:map_core/map_core_domain.dart';

import 'resource_catalog.dart';

final _catalogIndexes = Expando<Map<String, ResourceLibraryEntry>>();

ResourceLibraryEntry? _catalogEntry(
  ResourceLibraryCatalog catalog,
  String identity,
) {
  final index = _catalogIndexes[catalog] ??= Map.unmodifiable({
    for (final entry in catalog.entries) entry.identity: entry,
  });
  return index[identity];
}

const uncategorizedResourceCategory = '__uncategorized__';

class ResourceItem {
  const ResourceItem({
    required this.id,
    required this.name,
    required this.kind,
    this.element,
    this.model3d,
    this.terrain,
    this.tileset,
    this.border,
    this.environment,
    this.character,
    this.category = '',
    this.tags = const [],
  });
  final String id;
  final String name;
  final ResourceKind kind;
  final ProjectElementEntry? element;
  final ProjectModel3dEntry? model3d;
  final ProjectSmartTilePreset? terrain;
  final ProjectTilesetEntry? tileset;
  final BorderBlueprintRecord? border;
  final EnvironmentPreset? environment;
  final ProjectCharacterEntry? character;
  final String category;
  final List<String> tags;
  String get canonicalKind => switch (this) {
    ResourceItem(model3d: _?) => 'model3d',
    ResourceItem(element: _?) => 'element',
    ResourceItem(terrain: _?) => 'smartTilePreset',
    ResourceItem(tileset: _?) => 'tileset',
    ResourceItem(border: _?) => 'borderBlueprint',
    ResourceItem(environment: _?) => 'environmentPreset',
    ResourceItem(character: _?) => 'character',
    _ => kind.canonicalKind,
  };
  String get identity => '$canonicalKind:$id';
  Set<ResourceCatalogUsage> get usages => switch (canonicalKind) {
    'element' => {ResourceCatalogUsage.place, ResourceCatalogUsage.scatter},
    'model3d' => {
      ResourceCatalogUsage.place,
      ResourceCatalogUsage.paint,
      ResourceCatalogUsage.trace,
      ResourceCatalogUsage.scatter,
    },
    'character' => {ResourceCatalogUsage.place},
    'smartTilePreset' || 'tileset' => {ResourceCatalogUsage.paint},
    'borderBlueprint' => {ResourceCatalogUsage.trace},
    'environmentPreset' => {ResourceCatalogUsage.scatter},
    _ => {},
  };
  String get typeLabel => switch (canonicalKind) {
    'element' => 'Décor',
    'model3d' => 'Modèle 3D',
    'smartTilePreset' => 'Terrain automatique',
    'tileset' => 'Image et tuiles',
    'borderBlueprint' => 'Bordure',
    'environmentPreset' => 'Environnement',
    'character' => 'Personnage',
    _ => switch (kind) {
      ResourceKind.decors => 'Décor',
      ResourceKind.terrains => 'Terrain automatique',
      ResourceKind.images => 'Image et tuiles',
    },
  };

  bool usableIn(ProjectManifest project, {String? activeMapId}) {
    final entry = metadata(project);
    final mapId = entry?.mapId;
    return compatibleWith(project.settings.dimension) &&
        entry?.role != ResourceLibraryRole.component &&
        (mapId == null || activeMapId == null || mapId == activeMapId) &&
        (border == null ||
            (border!.latestPublished != null && !border!.isDeprecated));
  }

  Set<ProjectDimension> get compatibleDimensions =>
      resourceCompatibleDimensions(
        canonicalKind,
        definition: terrain ?? border ?? environment,
      );

  bool compatibleWith(ProjectDimension dimension) =>
      compatibleDimensions.contains(dimension);

  ResourceLibraryEntry? metadata(ProjectManifest project) =>
      _catalogEntry(project.resourceLibraryCatalog, identity);
}

const _planarDimensions = {ProjectDimension.twoD};
const _spatialDimensions = {ProjectDimension.threeD};
const _bothDimensions = {ProjectDimension.twoD, ProjectDimension.threeD};

Set<ProjectDimension> resourceCompatibleDimensions(
  String kind, {
  Object? definition,
}) => switch ((kind, definition)) {
  ('model3d', _) => _spatialDimensions,
  ('element' || 'tileset', _) => _planarDimensions,
  ('character', _) => _bothDimensions,
  ('smartTilePreset', final ProjectSmartTilePreset preset) =>
    preset.rules.any(
          (rule) => rule.candidates.any(
            (candidate) => candidate.parts.any(
              (part) => part.source is SmartTileModel3dSource,
            ),
          ),
        )
        ? _spatialDimensions
        : _bothDimensions,
  ('environmentPreset', final EnvironmentPreset preset) =>
    preset.isSpatial ? _spatialDimensions : _planarDimensions,
  ('borderBlueprint', final BorderBlueprintRecord border) =>
    (border.latestPublished?.definition ?? border.draft.definition).isSpatial
        ? _spatialDimensions
        : _planarDimensions,
  _ => const {},
};
