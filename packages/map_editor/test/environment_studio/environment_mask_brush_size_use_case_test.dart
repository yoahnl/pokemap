import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/environment_mask_use_cases.dart';

void main() {
  group('PaintEnvironmentAreaMaskBrushStrokeUseCase', () {
    test('brush size 1 peint exactement la cellule centrale', () {
      final map = _map();

      final updated = PaintEnvironmentAreaMaskBrushStrokeUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'area',
        center: const GridPos(x: 2, y: 2),
        brushSize: 1,
        isActive: true,
      );

      expect(_activePositions(updated), const [GridPos(x: 2, y: 2)]);
    });

    test('brush size 3 peint un carré 3x3', () {
      final map = _map(width: 5, height: 5);

      final updated = PaintEnvironmentAreaMaskBrushStrokeUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'area',
        center: const GridPos(x: 2, y: 2),
        brushSize: 3,
        isActive: true,
      );

      expect(
        _activePositions(updated),
        const [
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
          GridPos(x: 1, y: 3),
          GridPos(x: 2, y: 3),
          GridPos(x: 3, y: 3),
        ],
      );
    });

    test('brush size 5 peint un carré 5x5', () {
      final map = _map(width: 7, height: 7);

      final updated = PaintEnvironmentAreaMaskBrushStrokeUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'area',
        center: const GridPos(x: 3, y: 3),
        brushSize: 5,
        isActive: true,
      );

      expect(_activePositions(updated).length, 25);
      expect(_area(updated).mask.isActiveAt(1, 1), isTrue);
      expect(_area(updated).mask.isActiveAt(5, 5), isTrue);
      expect(_area(updated).mask.isActiveAt(0, 0), isFalse);
      expect(_area(updated).mask.isActiveAt(6, 6), isFalse);
    });

    test('brush size 7 peint un carré 7x7', () {
      final map = _map(width: 9, height: 9);

      final updated = PaintEnvironmentAreaMaskBrushStrokeUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'area',
        center: const GridPos(x: 4, y: 4),
        brushSize: 7,
        isActive: true,
      );

      expect(_activePositions(updated).length, 49);
      expect(_area(updated).mask.isActiveAt(1, 1), isTrue);
      expect(_area(updated).mask.isActiveAt(7, 7), isTrue);
      expect(_area(updated).mask.isActiveAt(0, 0), isFalse);
      expect(_area(updated).mask.isActiveAt(8, 8), isFalse);
    });

    test('brush en bord de map clippe correctement', () {
      final map = _map(width: 5, height: 5);

      final updated = PaintEnvironmentAreaMaskBrushStrokeUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'area',
        center: const GridPos(x: 0, y: 0),
        brushSize: 5,
        isActive: true,
      );

      expect(_activePositions(updated).length, 9);
      expect(_area(updated).mask.isActiveAt(0, 0), isTrue);
      expect(_area(updated).mask.isActiveAt(2, 2), isTrue);
      expect(_area(updated).mask.isActiveAt(3, 0), isFalse);
      expect(_area(updated).mask.isActiveAt(0, 3), isFalse);
    });

    test('brush hors map ne crash pas et ne peint rien', () {
      final map = _map(width: 5, height: 5);

      final updated = PaintEnvironmentAreaMaskBrushStrokeUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'area',
        center: const GridPos(x: -1, y: 2),
        brushSize: 3,
        isActive: true,
      );

      expect(identical(updated, map), isTrue);
      expect(_activePositions(updated), isEmpty);
    });

    test('erase avec size 3 remet les cellules à false', () {
      final cells = List<bool>.filled(25, true);
      final map = _map(width: 5, height: 5, cells: cells);

      final updated = PaintEnvironmentAreaMaskBrushStrokeUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'area',
        center: const GridPos(x: 2, y: 2),
        brushSize: 3,
        isActive: false,
      );

      expect(_area(updated).mask.activeCellCount, 16);
      expect(_area(updated).mask.isActiveAt(2, 2), isFalse);
      expect(_area(updated).mask.isActiveAt(1, 1), isFalse);
      expect(_area(updated).mask.isActiveAt(0, 0), isTrue);
    });

    test('refuse brush size invalide', () {
      final map = _map();
      for (final size in [0, 2, 4, 8]) {
        expect(
          () => PaintEnvironmentAreaMaskBrushStrokeUseCase().execute(
            map,
            environmentLayerId: 'env',
            areaId: 'area',
            center: const GridPos(x: 1, y: 1),
            brushSize: size,
            isActive: true,
          ),
          throwsA(isA<EditorValidationException>()),
        );
      }
    });

    test('préserve les autres areas layers et placedElements', () {
      final map = _map(
        width: 5,
        height: 5,
        extraArea: true,
        placedElements: const [
          MapPlacedElement(
            id: 'tree',
            layerId: 'tiles',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );

      final updated = PaintEnvironmentAreaMaskBrushStrokeUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'area',
        center: const GridPos(x: 2, y: 2),
        brushSize: 3,
        isActive: true,
      );

      final env = updated.layers.whereType<EnvironmentLayer>().single;
      expect(env.content.areas, hasLength(2));
      expect(env.content.areaById('other')!.mask.activeCellCount, 0);
      expect(updated.layers.whereType<TileLayer>().single.id, 'tiles');
      expect(updated.placedElements, map.placedElements);
    });
  });
}

MapData _map({
  int width = 5,
  int height = 5,
  List<bool>? cells,
  bool extraArea = false,
  List<MapPlacedElement> placedElements = const [],
}) {
  final area = EnvironmentArea(
    id: 'area',
    name: 'Forêt',
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: width,
      height: height,
      cells: cells ?? List<bool>.filled(width * height, false),
    ),
    seed: 1,
  );
  final areas = [
    area,
    if (extraArea)
      EnvironmentArea(
        id: 'other',
        name: 'Autre',
        presetId: 'forest',
        mask: EnvironmentAreaMask(
          width: width,
          height: height,
          cells: List<bool>.filled(width * height, false),
        ),
        seed: 2,
      ),
  ];
  return MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: width, height: height),
    layers: [
      TileLayer(
        id: 'tiles',
        name: 'Sol',
        tiles: List<int>.filled(width * height, 0),
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: areas,
        ),
      ),
    ],
    placedElements: placedElements,
  );
}

EnvironmentArea _area(MapData map) {
  return map.layers.whereType<EnvironmentLayer>().single.content.areas.first;
}

List<GridPos> _activePositions(MapData map) {
  final mask = _area(map).mask;
  final positions = <GridPos>[];
  for (var y = 0; y < mask.height; y++) {
    for (var x = 0; x < mask.width; x++) {
      if (mask.isActiveAt(x, y)) {
        positions.add(GridPos(x: x, y: y));
      }
    }
  }
  return positions;
}
