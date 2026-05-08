import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/environment_generated_placement_hover_resolver.dart';

void main() {
  group('Environment generated placement hover preview', () {
    test('resolves the generated placement that would be added by a click', () {
      final ctx = _previewContext();

      final preview = resolveEnvironmentGeneratedPlacementAddPreview(
        map: ctx.map,
        manifest: ctx.manifest,
        activeLayerId: 'env',
        selectedAreaId: 'area one',
        pos: const GridPos(x: 2, y: 1),
      );

      expect(preview, isNotNull);
      expect(preview!.placed.id, 'env_gen_area_one_2_1_tree_large');
      expect(preview.placed.layerId, 'tiles');
      expect(preview.placed.elementId, 'tree_large');
      expect(preview.placed.pos, const GridPos(x: 2, y: 1));
      expect(preview.placed.applyCollision, isTrue);
      expect(preview.element.id, 'tree_large');
    });

    test('previews add as invalid when the element footprint leaves the map',
        () {
      final ctx = _previewContext();

      final preview = resolveEnvironmentGeneratedPlacementAddPreview(
        map: ctx.map,
        manifest: ctx.manifest,
        activeLayerId: 'env',
        selectedAreaId: 'area one',
        pos: const GridPos(x: 4, y: 4),
      );

      expect(preview, isNotNull);
      expect(preview!.isValid, isFalse);
      expect(preview.invalidReason, contains('Position hors carte'));
    });

    test('resolves the topmost generated placement that delete would remove',
        () {
      final ctx = _previewContext();
      final map = ctx.map.copyWith(
        placedElements: const [
          MapPlacedElement(
            id: 'manual_tree',
            layerId: 'tiles',
            elementId: 'tree_large',
            pos: GridPos(x: 2, y: 2),
          ),
          MapPlacedElement(
            id: 'generated_bottom',
            layerId: 'tiles',
            elementId: 'tree_large',
            pos: GridPos(x: 1, y: 1),
          ),
          MapPlacedElement(
            id: 'generated_top',
            layerId: 'tiles',
            elementId: 'tree_large',
            pos: GridPos(x: 2, y: 2),
          ),
        ],
      );

      final target = resolveEnvironmentGeneratedPlacementDeleteTarget(
        map: map,
        manifest: ctx.manifest,
        activeLayerId: 'env',
        selectedAreaId: 'area one',
        pos: const GridPos(x: 2, y: 2),
      );

      expect(target, isNotNull);
      expect(target!.placed.id, 'generated_top');
      expect(target.element?.id, 'tree_large');
    });

    test('resolves delete target from active TileLayer attachment', () {
      final ctx = _previewContext();
      final map = ctx.map.copyWith(
        placedElements: const [
          MapPlacedElement(
            id: 'manual_tree',
            layerId: 'tiles',
            elementId: 'tree_large',
            pos: GridPos(x: 2, y: 2),
          ),
          MapPlacedElement(
            id: 'generated_bottom',
            layerId: 'tiles',
            elementId: 'tree_large',
            pos: GridPos(x: 1, y: 1),
          ),
          MapPlacedElement(
            id: 'generated_top',
            layerId: 'tiles',
            elementId: 'tree_large',
            pos: GridPos(x: 2, y: 2),
          ),
        ],
      );

      final target = resolveEnvironmentGeneratedPlacementDeleteTarget(
        map: map,
        manifest: ctx.manifest,
        activeLayerId: 'tiles',
        selectedAreaId: 'area one',
        pos: const GridPos(x: 2, y: 2),
      );

      expect(target, isNotNull);
      expect(target!.placed.id, 'generated_top');
      expect(target.element?.id, 'tree_large');
    });
  });
}

({MapData map, ProjectManifest manifest}) _previewContext() {
  final area = EnvironmentArea(
    id: 'area one',
    name: 'Forest',
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: 5,
      height: 5,
      cells: List<bool>.filled(25, true),
    ),
    seed: 1,
    generatedPlacementIds: const ['generated_bottom', 'generated_top'],
  );
  final env = MapLayer.environment(
    id: 'env',
    name: 'Environment',
    content: EnvironmentLayerContent(
      targetTileLayerId: 'tiles',
      areas: [area],
    ),
  );
  const tile = TileLayer(
    id: 'tiles',
    name: 'Tiles',
    tilesetId: 'nature',
    tiles: [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ],
  );
  final map = MapData(
    id: 'm',
    name: 'Map',
    size: const GridSize(width: 5, height: 5),
    tilesetId: 'nature',
    layers: [env, tile],
  );
  final manifest = ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree_large',
        name: 'Large Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
          ),
        ],
      ),
      ProjectElementEntry(
        id: 'wrong_tileset_tree',
        name: 'Wrong Tileset Tree',
        tilesetId: 'other',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
          ),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forest',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'wrong_tileset_tree', weight: 1),
          EnvironmentPaletteItem(elementId: 'tree_large', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 1,
          variation: 0,
          edgeDensity: 1,
          minSpacingCells: 0,
        ),
        sortOrder: 0,
      ),
    ],
  );
  return (map: map, manifest: manifest);
}
