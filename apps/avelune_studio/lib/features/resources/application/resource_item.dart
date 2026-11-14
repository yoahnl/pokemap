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

  bool compatibleWith(ProjectDimension dimension) => switch (canonicalKind) {
    'model3d' => dimension == ProjectDimension.threeD,
    'smartTilePreset' =>
      dimension == ProjectDimension.threeD ||
          terrain?.rules.every(
                (rule) => rule.candidates.every(
                  (candidate) => candidate.parts.every(
                    (part) => part.source is! SmartTileModel3dSource,
                  ),
                ),
              ) ==
              true,
    'environmentPreset' =>
      environment?.isSpatial == (dimension == ProjectDimension.threeD),
    'borderBlueprint' =>
      (border?.latestPublished?.definition.isSpatial ??
              border?.draft.definition.isSpatial) ==
          (dimension == ProjectDimension.threeD),
    'element' || 'tileset' => dimension == ProjectDimension.twoD,
    _ => true,
  };

  ResourceLibraryEntry? metadata(ProjectManifest project) =>
      _catalogEntry(project.resourceLibraryCatalog, identity);
}
