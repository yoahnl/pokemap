import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/map_cell_stroke_buffer.dart';

import '../../../tools/performance/benchmark_support.dart';

const _strokeSamplesByExtent = <int, int>{
  128: 1,
  256: 10,
  512: 100,
  1024: 1000,
};
const _pointerSamplesP95BudgetUs = 8000;

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{'warmups', 'samples', 'extents', 'output'},
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 2);
    final samples = cli.positiveInt('samples', fallback: 10);
    final extents = cli.positiveInts(
      'extents',
      fallback: _strokeSamplesByExtent.keys.join(','),
      singularLabel: 'extent',
    );
    for (final extent in extents) {
      if (!_strokeSamplesByExtent.containsKey(extent)) {
        throw FormatException(
          'extent must be one of ${_strokeSamplesByExtent.keys.join(', ')}',
        );
      }
    }
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_editor');

    final results = <Map<String, Object?>>[];
    for (final extent in extents) {
      final strokeSamples = _strokeSamplesByExtent[extent]!;
      final tilePointerSamples = _profile(
        warmups: warmups,
        samples: samples,
        measure: () => _measureTileSamples(extent, strokeSamples),
      );
      final collisionPointerSamples = _profile(
        warmups: warmups,
        samples: samples,
        measure: () => _measureCollisionSamples(extent, strokeSamples),
      );
      _requirePointerBudget(tilePointerSamples);
      _requirePointerBudget(collisionPointerSamples);
      results.add(<String, Object?>{
        'extent': extent,
        'strokeSamples': strokeSamples,
        'tilePointerSamples': tilePointerSamples,
        'tileCommit': _profile(
          warmups: warmups,
          samples: samples,
          measure: () => _measureTileCommit(extent, strokeSamples),
        ),
        'collisionPointerSamples': collisionPointerSamples,
        'collisionCommit': _profile(
          warmups: warmups,
          samples: samples,
          measure: () => _measureCollisionCommit(extent, strokeSamples),
        ),
        'workCounts': <String, Object?>{
          'legacyFullLayerCopiesDuringGesture': strokeSamples,
          'legacyMapMaterializationsDuringGesture': strokeSamples,
          'legacyValidationsDuringGesture': strokeSamples,
          'legacyLayerCellSlotsAllocated': extent * extent * strokeSamples,
          'touchedCellsBeforeCommit': strokeSamples,
          'fullLayerCopiesBeforeCommit': 0,
          'mapMaterializationsBeforeCommit': 0,
          'validationsBeforeCommit': 0,
          'sparseOverrideUpperBound': strokeSamples,
          'fullLayerCopiesAtCommit': 1,
          'mapMaterializationsAtCommit': 1,
          'validationsAtCommit': 1,
          'layerCellSlotsAllocatedAtCommit': extent * extent,
        },
        'rssBytesAfterSamples': ProcessInfo.currentRss,
      });
    }

    final receipt = await performanceReceipt(
      benchmark: 'map_cell_stroke_scaling',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>[
        'benchmark/map_cell_stroke_scaling.dart',
        ...arguments,
      ],
      metadata: <String, Object?>{
        'extents': extents,
        'strokeSamplesByExtent': <String, int>{
          for (final extent in extents)
            '$extent': _strokeSamplesByExtent[extent]!,
        },
        'allocationEvidence': 'deterministic-work-counts',
        'pointerSamplesP95BudgetUs': _pointerSamplesP95BudgetUs,
      },
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_editor',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('map_cell_stroke_scaling: ${error.message}');
    exitCode = 64;
  }
}

void _requirePointerBudget(Map<String, Object?> profile) {
  if ((profile['p95Us']! as int) >= _pointerSamplesP95BudgetUs) {
    throw StateError('Pointer sample batch exceeded the PERF-003 budget.');
  }
}

Map<String, Object?> _profile({
  required int warmups,
  required int samples,
  required _Measurement Function() measure,
}) {
  for (var index = 0; index < warmups; index++) {
    measure();
  }
  final measured = <_Measurement>[
    for (var index = 0; index < samples; index++) measure(),
  ];
  final checksum = measured.first.checksum;
  if (measured.any((sample) => sample.checksum != checksum)) {
    throw StateError('Benchmark operation produced an unstable checksum.');
  }
  return <String, Object?>{
    ...percentileFields(
      measured.map((sample) => sample.elapsedUs).toList(growable: false),
    ),
    'checksum': checksum,
  };
}

_Measurement _measureTileSamples(int extent, int samples) {
  final buffer = MapCellStrokeBuffer.tile(
    sourceMap: _tileMap(extent),
    layerId: 'ground',
  );
  final stopwatch = Stopwatch()..start();
  _applyTileSamples(buffer, samples);
  stopwatch.stop();
  _requireSparse(buffer, samples);
  return _Measurement(
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(<Object?>[
      buffer.touchedCellCount,
      buffer.tileAt(samples - 1)?.localTileId,
      buffer.revision,
    ]),
  );
}

_Measurement _measureTileCommit(int extent, int samples) {
  final buffer = MapCellStrokeBuffer.tile(
    sourceMap: _tileMap(extent),
    layerId: 'ground',
  );
  _applyTileSamples(buffer, samples);
  final stopwatch = Stopwatch()..start();
  final committed = buffer.commit(validate: MapValidator.validate);
  stopwatch.stop();
  _requireCommitted(buffer);
  final layer = committed.layers.single as TileLayer;
  return _Measurement(
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(<Object?>[
      buffer.touchedCellCount,
      layer.cells.first,
      layer.cells[samples - 1],
      layer.cells.length,
    ]),
  );
}

_Measurement _measureCollisionSamples(int extent, int samples) {
  final buffer = MapCellStrokeBuffer.collision(
    sourceMap: _collisionMap(extent),
    layerId: 'collision',
  );
  final stopwatch = Stopwatch()..start();
  _applyCollisionSamples(buffer, samples);
  stopwatch.stop();
  _requireSparse(buffer, samples);
  return _Measurement(
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(<Object?>[
      buffer.touchedCellCount,
      buffer.collisionAt(samples - 1),
      buffer.revision,
    ]),
  );
}

_Measurement _measureCollisionCommit(int extent, int samples) {
  final buffer = MapCellStrokeBuffer.collision(
    sourceMap: _collisionMap(extent),
    layerId: 'collision',
  );
  _applyCollisionSamples(buffer, samples);
  final stopwatch = Stopwatch()..start();
  final committed = buffer.commit(validate: MapValidator.validate);
  stopwatch.stop();
  _requireCommitted(buffer);
  final layer = committed.layers.single as CollisionLayer;
  return _Measurement(
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(<Object?>[
      buffer.touchedCellCount,
      layer.collisions.first,
      layer.collisions[samples - 1],
      layer.collisions.length,
    ]),
  );
}

void _applyTileSamples(MapCellStrokeBuffer buffer, int samples) {
  for (var x = 0; x < samples; x++) {
    buffer.paintTiles(
      origin: GridPos(x: x, y: 0),
      patternSize: const GridSize(width: 1, height: 1),
      tiles: const <TileLayerPaletteEntry?>[
        TileLayerPaletteEntry(tilesetId: 'world', localTileId: 6),
      ],
    );
  }
}

void _applyCollisionSamples(MapCellStrokeBuffer buffer, int samples) {
  for (var x = 0; x < samples; x++) {
    buffer.setCollisions(
      origin: GridPos(x: x, y: 0),
      patternSize: const GridSize(width: 1, height: 1),
      value: true,
    );
  }
}

void _requireSparse(MapCellStrokeBuffer buffer, int touchedCells) {
  if (buffer.touchedCellCount != touchedCells ||
      buffer.fullLayerCopyCount != 0 ||
      buffer.mapMaterializationCount != 0 ||
      buffer.validationCount != 0) {
    throw StateError('Pointer samples escaped the sparse stroke contract.');
  }
}

void _requireCommitted(MapCellStrokeBuffer buffer) {
  if (buffer.fullLayerCopyCount != 1 ||
      buffer.mapMaterializationCount != 1 ||
      buffer.validationCount != 1) {
    throw StateError('Stroke commit escaped the single-publication contract.');
  }
}

MapData _tileMap(int extent) => MapData(
  id: 'tile-$extent',
  name: 'Tile $extent',
  size: GridSize(width: extent, height: extent),
  layers: <MapLayer>[
    MapLayer.tile(
      id: 'ground',
      name: 'Ground',
      cells: List<int>.filled(extent * extent, 0, growable: false),
    ),
  ],
);

MapData _collisionMap(int extent) => MapData(
  id: 'collision-$extent',
  name: 'Collision $extent',
  size: GridSize(width: extent, height: extent),
  layers: <MapLayer>[
    MapLayer.collision(
      id: 'collision',
      name: 'Collision',
      collisions: List<bool>.filled(extent * extent, false, growable: false),
    ),
  ],
);

final class _Measurement {
  const _Measurement({required this.elapsedUs, required this.checksum});

  final int elapsedUs;
  final String checksum;
}
