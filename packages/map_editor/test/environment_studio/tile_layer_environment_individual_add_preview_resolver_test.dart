import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/environment_generated_placement_hover_resolver.dart';

void main() {
  group('TileLayer generated placement add preview resolver', () {
    test('retourne un preview valide depuis le TileLayer actif', () {
      final ctx = _context();

      final preview = resolveEnvironmentGeneratedPlacementAddPreview(
        map: ctx.map,
        manifest: ctx.manifest,
        activeLayerId: 'tiles',
        selectedAreaId: 'area',
        selectedElementId: 'bush',
        pos: const GridPos(x: 1, y: 2),
      );

      expect(preview, isNotNull);
      expect(preview!.isValid, isTrue);
      expect(preview.invalidReason, isNull);
      expect(preview.placed.layerId, 'tiles');
      expect(preview.placed.elementId, 'bush');
      expect(preview.placed.pos, const GridPos(x: 1, y: 2));
      expect(preview.footprint, const GridSize(width: 1, height: 1));
    });

    test('utilise un élément implicite quand un seul item valide existe', () {
      final ctx = _context(
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
        ],
      );

      final preview = resolveEnvironmentGeneratedPlacementAddPreview(
        map: ctx.map,
        manifest: ctx.manifest,
        activeLayerId: 'tiles',
        selectedAreaId: 'area',
        selectedElementId: null,
        pos: const GridPos(x: 0, y: 0),
      );

      expect(preview, isNotNull);
      expect(preview!.isValid, isTrue);
      expect(preview.placed.elementId, 'tree');
      expect(preview.footprint, const GridSize(width: 2, height: 2));
    });

    test('ne choisit pas arbitrairement si plusieurs items valides existent',
        () {
      final ctx = _context();

      final preview = resolveEnvironmentGeneratedPlacementAddPreview(
        map: ctx.map,
        manifest: ctx.manifest,
        activeLayerId: 'tiles',
        selectedAreaId: 'area',
        selectedElementId: null,
        pos: const GridPos(x: 0, y: 0),
      );

      expect(preview, isNull);
    });

    test('retourne null si l’élément sélectionné est absent de la palette', () {
      final ctx = _context();

      final preview = resolveEnvironmentGeneratedPlacementAddPreview(
        map: ctx.map,
        manifest: ctx.manifest,
        activeLayerId: 'tiles',
        selectedAreaId: 'area',
        selectedElementId: 'rock',
        pos: const GridPos(x: 0, y: 0),
      );

      expect(preview, isNull);
    });

    test('retourne null si l’élément sélectionné est absent du manifest', () {
      final ctx = _context(
        palette: [
          EnvironmentPaletteItem(elementId: 'ghost_tree', weight: 1),
        ],
      );

      final preview = resolveEnvironmentGeneratedPlacementAddPreview(
        map: ctx.map,
        manifest: ctx.manifest,
        activeLayerId: 'tiles',
        selectedAreaId: 'area',
        selectedElementId: 'ghost_tree',
        pos: const GridPos(x: 0, y: 0),
      );

      expect(preview, isNull);
    });

    test('retourne un preview invalide si le footprint sort de la map', () {
      final ctx = _context();

      final preview = resolveEnvironmentGeneratedPlacementAddPreview(
        map: ctx.map,
        manifest: ctx.manifest,
        activeLayerId: 'tiles',
        selectedAreaId: 'area',
        selectedElementId: 'tree',
        pos: const GridPos(x: 3, y: 3),
      );

      expect(preview, isNotNull);
      expect(preview!.isValid, isFalse);
      expect(preview.invalidReason, contains('Position hors carte'));
      expect(preview.placed.elementId, 'tree');
      expect(preview.footprint, const GridSize(width: 2, height: 2));
    });

    test('ne mute pas la MapData', () {
      final ctx = _context();
      final beforeLayers = ctx.map.layers.toList(growable: false);
      final beforePlaced = ctx.map.placedElements.toList(growable: false);

      resolveEnvironmentGeneratedPlacementAddPreview(
        map: ctx.map,
        manifest: ctx.manifest,
        activeLayerId: 'tiles',
        selectedAreaId: 'area',
        selectedElementId: 'bush',
        pos: const GridPos(x: 1, y: 2),
      );

      expect(ctx.map.layers, beforeLayers);
      expect(ctx.map.placedElements, beforePlaced);
      expect(_area(ctx.map).generatedPlacementIds, const ['generated_tree']);
    });
  });
}

({MapData map, ProjectManifest manifest}) _context({
  List<EnvironmentPaletteItem>? palette,
}) {
  final area = EnvironmentArea(
    id: 'area',
    name: 'Zone',
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: 4,
      height: 4,
      cells: List<bool>.filled(16, true),
    ),
    seed: 7,
    generatedPlacementIds: const ['generated_tree'],
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 4),
    tilesetId: 'nature',
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'generated_tree',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 0),
      ),
    ],
  );
  final manifest = ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
          ),
        ],
      ),
      ProjectElementEntry(
        id: 'bush',
        name: 'Bush',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 2, y: 0)),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest',
        palette: palette ??
            [
              EnvironmentPaletteItem(elementId: 'tree', weight: 1),
              EnvironmentPaletteItem(elementId: 'bush', weight: 1),
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

EnvironmentArea _area(MapData map) {
  return map.layers.whereType<EnvironmentLayer>().single.content.areas.single;
}
