import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/editor_performance_telemetry.dart';
import 'package:map_editor/src/application/use_cases/collision_use_cases.dart';
import 'package:map_editor/src/application/use_cases/paint_use_cases.dart';

void main() {
  test('tile and collision hot paths record only incremental validation', () {
    final recorder = EditorPerformanceRecorder();
    final recording = EditorPerformanceTelemetry.startRecording(recorder);
    addTearDown(recording.close);
    final source = _map(1024);

    final painted = PaintTileOnMapUseCase().execute(
      source,
      layerId: 'ground',
      pos: const GridPos(x: 1000, y: 1000),
      tile: const TileLayerPaletteEntry(tilesetId: 'world', localTileId: 8),
    );
    PaintCollisionOnMapUseCase().execute(
      painted,
      layerId: 'collision',
      pos: const GridPos(x: 1000, y: 1000),
    );

    final snapshot = recorder.snapshot();
    expect(
      snapshot.spanSamples(EditorPerformanceSpanName.mapIncrementalValidation),
      hasLength(2),
    );
    expect(
      snapshot.spanSamples(EditorPerformanceSpanName.mapFullValidation),
      isEmpty,
    );
  });

  test('fully clipped patterns remain valid no-op mutations', () {
    final source = _map(4);

    final tile = PaintTilePatternOnMapUseCase().execute(
      source,
      layerId: 'ground',
      pos: const GridPos(x: 8, y: 8),
      patternSize: const GridSize(width: 2, height: 2),
      tiles: const <TileLayerPaletteEntry?>[
        TileLayerPaletteEntry(tilesetId: 'world', localTileId: 1),
        null,
        null,
        null,
      ],
    );
    final collision = PaintCollisionPatternOnMapUseCase().execute(
      source,
      layerId: 'collision',
      pos: const GridPos(x: 8, y: 8),
      patternSize: const GridSize(width: 2, height: 2),
    );

    expect(tile, source);
    expect(collision, source);
  });
}

MapData _map(int extent) {
  final cellCount = extent * extent;
  return MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: extent, height: extent),
    layers: <MapLayer>[
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        cells: List<int>.filled(cellCount, 0),
      ),
      MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: List<bool>.filled(cellCount, false),
      ),
    ],
  );
}
