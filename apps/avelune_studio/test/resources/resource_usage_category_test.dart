import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_usage_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

ProjectSmartTilePreset _surface(
  String id,
  SmartTileUsage usage,
  String material,
) => ProjectSmartTilePreset(
  id: id,
  name: id,
  usage: usage,
  topology: SmartTileTopology.uniform,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: const SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: const SmartTileTransformPolicy(),
  defaultMaterialId: material,
  allowedMaterialIds: [material],
);

void main() {
  final project = workspaceProject.copyWith(
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: const [
        ProjectSmartTileMaterial(
          id: 'sea',
          name: 'Mer',
          connectionGroupId: 'sea',
          pathSurfaceKind: PathSurfaceKind.water,
        ),
        ProjectSmartTileMaterial(
          id: 'dirt',
          name: 'Terre',
          connectionGroupId: 'dirt',
          pathSurfaceKind: PathSurfaceKind.path,
        ),
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Herbe',
          connectionGroupId: 'grass',
        ),
      ],
    ),
  );

  ResourceItem terrain(ProjectSmartTilePreset preset) => ResourceItem(
    id: preset.id,
    name: preset.name,
    kind: ResourceKind.terrains,
    terrain: preset,
  );

  test('terrains split into ground, path and water from their material', () {
    for (final (preset, category) in [
      (
        _surface('grass', SmartTileUsage.terrain, 'grass'),
        ResourceUsageCategory.ground,
      ),
      (
        _surface('forest', SmartTileUsage.forestSurface, 'grass'),
        ResourceUsageCategory.ground,
      ),
      (
        _surface('path', SmartTileUsage.path, 'dirt'),
        ResourceUsageCategory.path,
      ),
      (
        _surface('sea', SmartTileUsage.path, 'sea'),
        ResourceUsageCategory.water,
      ),
      (
        _surface('unknown', SmartTileUsage.path, 'missing'),
        ResourceUsageCategory.path,
      ),
    ]) {
      final item = terrain(preset);
      expect(resourceUsageCategory(item, project), category, reason: preset.id);
      expect(resourceAwaitsUsageCategory(item, project), isFalse);
    }
  });

  test('objects wait for a stored category and fall back to Objets', () {
    const item = ResourceItem(
      id: 'tree',
      name: 'Arbre',
      kind: ResourceKind.decors,
      element: workspaceElement,
    );

    expect(derivedResourceUsageCategory(item, project), isNull);
    expect(resourceUsageCategory(item, project), ResourceUsageCategory.object);
    expect(resourceAwaitsUsageCategory(item, project), isTrue);
  });

  test('characters and images belong to no construction category', () {
    const image = ResourceItem(
      id: 'atlas',
      name: 'Exemple',
      kind: ResourceKind.images,
      tileset: ProjectTilesetEntry(
        id: 'atlas',
        name: 'Exemple',
        relativePath: 'atlas.png',
      ),
    );

    expect(resourceUsageCategory(image, project), isNull);
    expect(resourceAwaitsUsageCategory(image, project), isFalse);
  });

  test(
    'each category loads one resource kind, objects use 2D decors in 2D',
    () {
      expect(
        ResourceUsageCategory.water.loadedKind(ProjectDimension.threeD),
        'smartTilePreset',
      );
      expect(
        ResourceUsageCategory.furniture.loadedKind(ProjectDimension.threeD),
        'model3d',
      );
      expect(
        ResourceUsageCategory.furniture.loadedKind(ProjectDimension.twoD),
        'element',
      );
      expect(
        ResourceUsageCategory.relief.loadedKind(ProjectDimension.twoD),
        'borderBlueprint',
      );
    },
  );
}
