import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_delta.dart';
import 'package:map_editor/src/application/models/map_history_entry.dart';
import 'package:map_editor/src/application/services/map_history_coordinator.dart';

import '../../../tools/performance/benchmark_support.dart';

const int _largeHistoryOperationP95BudgetUs = 50000;

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{
        'warmups',
        'samples',
        'entries',
        'operations',
        'tile-extent',
        'output',
      },
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 2);
    final samples = cli.positiveInt('samples', fallback: 10);
    final entries = cli.positiveInt('entries', fallback: 10000);
    final operations = cli.positiveInt('operations', fallback: 10000);
    final tileExtent = cli.positiveInt('tile-extent', fallback: 1024);
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_editor');

    final before = _fixture(entries);
    final instances = List<MapPlacedElement>.from(before.placedElements);
    instances[entries ~/ 2] = instances[entries ~/ 2].copyWith(
      pos: const GridPos(x: 127, y: 127),
    );
    final after = before.copyWith(placedElements: instances);
    final delta = MapHistoryDelta.between(before, after);
    if (delta.applyBackward(after) != before ||
        delta.applyForward(before) != after) {
      throw StateError('map history delta round-trip failed');
    }

    final construct = _profile(
      warmups: warmups,
      samples: samples,
      operation: () => MapHistoryDelta.between(before, after),
    );
    final undo = _profile(
      warmups: warmups,
      samples: samples,
      operation: () => delta.applyBackward(after),
    );
    final redo = _profile(
      warmups: warmups,
      samples: samples,
      operation: () => delta.applyForward(before),
    );
    const coordinator = MapHistoryCoordinator(
      maxEntries: 10000,
      maxRetainedBytes: 256 * 1024,
      checkpointInterval: 0,
    );
    final recorded = coordinator.recordMutation(
      before: before,
      after: after,
      selectionBefore: const MapHistorySelection(),
      undoStack: const <MapHistoryEntry>[],
      redoStack: const <MapHistoryEntry>[],
    );
    final longSession = _longSession(operations);
    final tileBefore = _tileFixture(tileExtent);
    final tileCells = List<int>.from(
      (tileBefore.layers.single as TileLayer).cells,
    )..[_tileCellsIndex(tileExtent)] = 1;
    final tileAfter = tileBefore.copyWith(
      layers: <MapLayer>[
        (tileBefore.layers.single as TileLayer).copyWith(cells: tileCells),
      ],
    );
    final tileDelta = MapHistoryDelta.between(tileBefore, tileAfter);
    final tileConstruct = _profile(
      warmups: warmups,
      samples: samples,
      operation: () => MapHistoryDelta.between(tileBefore, tileAfter),
    );
    final tileUndo = _profile(
      warmups: warmups,
      samples: samples,
      operation: () => tileDelta.applyBackward(tileAfter),
    );
    final tileRedo = _profile(
      warmups: warmups,
      samples: samples,
      operation: () => tileDelta.applyForward(tileBefore),
    );
    for (final profile in <Map<String, Object?>>[
      construct,
      undo,
      redo,
      tileConstruct,
      tileUndo,
      tileRedo,
    ]) {
      _requireLargeHistoryBudget(profile);
    }
    final receipt = await performanceReceipt(
      benchmark: 'map_history_delta_scaling',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>[
        'benchmark/map_history_delta_scaling.dart',
        ...arguments,
      ],
      metadata: <String, Object?>{
        'entries': entries,
        'operations': operations,
        'tileExtent': tileExtent,
        'changedValues': delta.changedValueCount,
        'deltaRetainedBytes': delta.retainedBytes,
        'legacySnapshotRetainedBytes': estimateMapDataSnapshotBytes(before),
        'tileChangedValues': tileDelta.changedValueCount,
        'tileDeltaRetainedBytes': tileDelta.retainedBytes,
        'tileLegacySnapshotRetainedBytes': estimateMapDataSnapshotBytes(
          tileBefore,
        ),
        'largeHistoryOperationP95BudgetUs': _largeHistoryOperationP95BudgetUs,
        'historyBudgetBytes': 256 * 1024,
        'historyRetainedBytes': coordinator.retainedBytes(recorded.undoStack),
        'rssBytes': ProcessInfo.currentRss,
        'longSession': longSession,
      },
      results: <Map<String, Object?>>[
        <String, Object?>{'operation': 'construct', ...construct},
        <String, Object?>{'operation': 'undo', ...undo},
        <String, Object?>{'operation': 'redo', ...redo},
        <String, Object?>{'operation': 'tile_construct', ...tileConstruct},
        <String, Object?>{'operation': 'tile_undo', ...tileUndo},
        <String, Object?>{'operation': 'tile_redo', ...tileRedo},
      ],
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_editor',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('map_history_delta_scaling: ${error.message}');
    exitCode = 64;
  }
}

int _tileCellsIndex(int extent) => extent * extent - 1;

void _requireLargeHistoryBudget(Map<String, Object?> profile) {
  if ((profile['p95Us']! as int) >= _largeHistoryOperationP95BudgetUs) {
    throw StateError('map history operation exceeded its P95 budget');
  }
}

Map<String, Object?> _longSession(int operations) {
  const coordinator = MapHistoryCoordinator(
    maxEntries: 10000,
    maxRetainedBytes: 256 * 1024,
    checkpointInterval: 0,
  );
  var map = _fixture(100);
  var undo = const <MapHistoryEntry>[];
  var redo = const <MapHistoryEntry>[];
  final rssBefore = ProcessInfo.currentRss;
  final stopwatch = Stopwatch()..start();
  for (var operation = 0; operation < operations; operation++) {
    final index = operation % map.placedElements.length;
    final instances = List<MapPlacedElement>.from(map.placedElements);
    instances[index] = instances[index].copyWith(
      pos: GridPos(x: (operation + 1) % 128, y: (operation ~/ 128) % 128),
    );
    final next = map.copyWith(placedElements: instances);
    final recorded = coordinator.recordMutation(
      before: map,
      after: next,
      selectionBefore: const MapHistorySelection(),
      undoStack: undo,
      redoStack: redo,
    );
    map = next;
    undo = recorded.undoStack;
    redo = recorded.redoStack;
  }
  stopwatch.stop();
  final retainedBytes = coordinator.retainedBytes(undo);
  if (retainedBytes > coordinator.maxRetainedBytes || redo.isNotEmpty) {
    throw StateError('map history long session exceeded its budget');
  }
  return <String, Object?>{
    'elapsedUs': stopwatch.elapsedMicroseconds,
    'rssBeforeBytes': rssBefore,
    'rssAfterBytes': ProcessInfo.currentRss,
    'historyEntries': undo.length,
    'historyRetainedBytes': retainedBytes,
    'historyBudgetBytes': coordinator.maxRetainedBytes,
  };
}

Map<String, Object?> _profile({
  required int warmups,
  required int samples,
  required Object Function() operation,
}) {
  for (var index = 0; index < warmups; index++) {
    operation();
  }
  final values = <int>[];
  var checksum = 0;
  for (var index = 0; index < samples; index++) {
    final stopwatch = Stopwatch()..start();
    final result = operation();
    stopwatch.stop();
    values.add(stopwatch.elapsedMicroseconds);
    checksum ^= result.hashCode;
  }
  values.sort();
  return <String, Object?>{
    'samplesUs': values,
    'p50Us': _percentile(values, 0.50),
    'p95Us': _percentile(values, 0.95),
    'p99Us': _percentile(values, 0.99),
    'maxUs': values.last,
    'checksum': '$checksum',
  };
}

int _percentile(List<int> sorted, double percentile) {
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index];
}

MapData _fixture(int count) {
  return MapData(
    id: 'history_fixture',
    name: 'History fixture',
    size: const GridSize(width: 128, height: 128),
    layers: const <MapLayer>[TileLayer(id: 'ground', name: 'Ground')],
    placedElements: List<MapPlacedElement>.generate(
      count,
      (index) => MapPlacedElement(
        id: 'instance_$index',
        layerId: 'ground',
        elementId: 'element_${index % 20}',
        pos: GridPos(x: index % 128, y: (index ~/ 128) % 128),
      ),
    ),
  );
}

MapData _tileFixture(int extent) {
  return MapData(
    id: 'tile_history_fixture',
    name: 'Tile history fixture',
    size: GridSize(width: extent, height: extent),
    layers: <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Ground',
        cells: List<int>.filled(extent * extent, 0),
      ),
    ],
  );
}
