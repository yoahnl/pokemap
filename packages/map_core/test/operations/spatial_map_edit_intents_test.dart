import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final manifest = ProjectManifest(
    name: 'Intent test',
    maps: [],
    tilesets: [],
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: const [
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Herbe',
          connectionGroupId: 'land',
        ),
        ProjectSmartTileMaterial(
          id: 'sea',
          name: 'Mer',
          connectionGroupId: 'water',
        ),
        ProjectSmartTileMaterial(
          id: 'sea-other',
          name: 'Mer',
          connectionGroupId: 'water',
        ),
      ],
    ),
  );

  MapData map(List<int> cells, {List<int>? heights}) => MapData(
    version: ProjectVersion.v9,
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    spatialScene: MapSpatialScene(
      width: 3,
      depth: 3,
      heightLevels: heights ?? List.filled(9, 0),
    ),
    layers: [
      SmartTileLayer(
        id: 'terrain',
        name: 'Ground',
        presetId: 'ground',
        usage: SmartTileUsage.terrain,
        materialPalette: const ['', 'grass', 'sea'],
        field: SmartTileField.cell(semanticCells: cells),
      ),
    ],
  );

  test(
    'material names resolve exact IDs, normalize whitespace and expose ambiguity',
    () {
      expect(resolveMaterialByName(manifest, ' HERBE ').materialId, 'grass');
      expect(resolveMaterialByName(manifest, 'sea').materialId, 'sea');
      expect(
        resolveMaterialByName(manifest, 'mer').status,
        SpatialIntentResolutionState.ambiguous,
      );
      expect(
        resolveMaterialByName(manifest, 'unknown').status,
        SpatialIntentResolutionState.noSource,
      );
    },
  );

  test('ground suggestions group a unique neighbor vote and stay pure', () {
    final source = map([1, 1, 1, 1, 0, 1, 1, 1, 1]);
    final before = source.toJson();
    final result = suggestGroundFill(source, const [GridPos(x: 1, y: 1)]);
    expect(result.status, SpatialIntentResolutionState.resolved);
    expect(result.strokes.single.layerId, 'terrain');
    expect(result.strokes.single.materialId, 'grass');
    expect(result.strokes.single.cells, const [GridPos(x: 1, y: 1)]);
    expect(source.toJson(), before);
  });

  test('ties and missing neighbors do not invent ground', () {
    final tied = suggestGroundFill(map([1, 1, 1, 2, 0, 2, 1, 1, 1]), const [
      GridPos(x: 1, y: 1),
    ]);
    expect(tied.status, SpatialIntentResolutionState.ambiguous);
    expect(tied.ambiguousCells, const [GridPos(x: 1, y: 1)]);
    final empty = suggestGroundFill(map(List.filled(9, 0)), const [
      GridPos(x: 1, y: 1),
    ]);
    expect(empty.status, SpatialIntentResolutionState.noSource);
    final explicit = suggestGroundFill(
      map(List.filled(9, 0)),
      const [GridPos(x: 1, y: 1)],
      layerId: 'terrain',
      materialId: 'sea',
    );
    expect(explicit.status, SpatialIntentResolutionState.resolved);
    expect(explicit.strokes.single.materialId, 'sea');
  });

  test(
    'height steps use directed grid edges with the upper ground to the right',
    () {
      final source = map(
        List.filled(9, 1),
        heights: [0, 0, 0, 1, 1, 1, 1, 1, 1],
      );
      final result = computeHeightStepEdges(
        source,
        lowerHeight: 0,
        upperHeight: 1,
      );
      expect(result.status, SpatialIntentResolutionState.resolved);
      expect(result.strokes, const [
        [
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
        ],
      ]);
      expect(
        computeHeightStepEdges(source, lowerHeight: 0, upperHeight: 1).strokes,
        result.strokes,
      );
    },
  );

  test(
    'closed plateaus form a stable loop and equal heights have no source',
    () {
      final source = map(
        List.filled(9, 1),
        heights: [0, 0, 0, 0, 1, 0, 0, 0, 0],
      );
      final result = computeHeightStepEdges(
        source,
        lowerHeight: 0,
        upperHeight: 1,
      );
      expect(result.strokes.single.first, result.strokes.single.last);
      expect(result.strokes.single.length, 5);
      expect(
        computeHeightStepEdges(
          map(List.filled(9, 1)),
          lowerHeight: 0,
          upperHeight: 1,
        ).status,
        SpatialIntentResolutionState.noSource,
      );
      expect(
        () => computeHeightStepEdges(source, lowerHeight: 1, upperHeight: 0),
        throwsFormatException,
      );
    },
  );
}
