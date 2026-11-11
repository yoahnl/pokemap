import 'package:map_core/map_core.dart';

import 'resource_catalog.dart';

enum ResourceUsageCategory {
  vegetation('Végétation', 'environmentPreset'),
  ground('Sols', 'smartTilePreset'),
  path('Chemins', 'smartTilePreset'),
  water('Eau', 'smartTilePreset'),
  relief('Reliefs et parois', 'borderBlueprint'),
  building('Bâtiments', 'model3d'),
  furniture('Mobilier', 'model3d'),
  object('Objets', 'model3d');

  const ResourceUsageCategory(this.label, this.spatialKind);

  final String label;
  final String spatialKind;

  String loadedKind(ProjectDimension dimension) =>
      dimension == ProjectDimension.twoD && spatialKind == 'model3d'
      ? 'element'
      : spatialKind;
}

ResourceUsageCategory? derivedResourceUsageCategory(
  ResourceItem item,
  ProjectManifest project,
) => switch (item.canonicalKind) {
  'environmentPreset' => ResourceUsageCategory.vegetation,
  'borderBlueprint' => ResourceUsageCategory.relief,
  'smartTilePreset' => _terrainCategory(item.terrain!, project),
  _ => null,
};

ResourceUsageCategory _terrainCategory(
  ProjectSmartTilePreset preset,
  ProjectManifest project,
) => switch (preset.usage) {
  SmartTileUsage.terrain ||
  SmartTileUsage.forestSurface => ResourceUsageCategory.ground,
  SmartTileUsage.path =>
    project.smartTileCatalog.materials
                .where((material) => material.id == preset.defaultMaterialId)
                .firstOrNull
                ?.pathSurfaceKind ==
            PathSurfaceKind.water
        ? ResourceUsageCategory.water
        : ResourceUsageCategory.path,
};

ResourceUsageCategory? resourceUsageCategory(
  ResourceItem item,
  ProjectManifest project,
) =>
    derivedResourceUsageCategory(item, project) ??
    switch (item.canonicalKind) {
      'model3d' || 'element' => ResourceUsageCategory.object,
      _ => null,
    };

bool resourceAwaitsUsageCategory(ResourceItem item, ProjectManifest project) =>
    derivedResourceUsageCategory(item, project) == null &&
    resourceUsageCategory(item, project) != null;
