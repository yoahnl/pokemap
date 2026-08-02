import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../../tools/performance/benchmark_support.dart';

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{
        'warmups',
        'samples',
        'sizes',
        'stroke-lengths',
        'output',
      },
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 5);
    final samples = cli.positiveInt('samples', fallback: 30);
    final sizes = cli.positiveInts(
      'sizes',
      fallback: '128,256,512,1024',
      singularLabel: 'size',
    );
    final strokeLengths = cli.positiveInts(
      'stroke-lengths',
      fallback: '1,100,1000',
      singularLabel: 'stroke length',
    );
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_core');
    final results = <Map<String, Object?>>[];

    for (final size in sizes) {
      for (final strokeLength in strokeLengths) {
        final cells = _strokeCells(size, strokeLength);
        final fingerprint = stableFingerprint(<String, Object?>{
          'mapSize': size,
          'strokeLength': strokeLength,
          'cells': cells,
        });
        for (var index = 0; index < warmups; index += 1) {
          _measure(size, cells);
        }
        final measured = <({int elapsedUs, String checksum, int placements})>[
          for (var index = 0; index < samples; index += 1)
            _measure(size, cells),
        ];
        final checksum = measured.first.checksum;
        if (measured.any((sample) => sample.checksum != checksum)) {
          throw StateError('Unstable paint result for $size/$strokeLength.');
        }
        results.add(<String, Object?>{
          'operation': 'pure-core-surface-paint',
          'mapSize': size,
          'strokeLength': strokeLength,
          'datasetFingerprint': fingerprint,
          'paintChecksum': checksum,
          'paintedPlacementCount': measured.first.placements,
          'rssBytesAfterSamples': ProcessInfo.currentRss,
          ...percentileFields(
            measured.map((sample) => sample.elapsedUs).toList(growable: false),
          ),
        });
      }
    }

    final receipt = await performanceReceipt(
      benchmark: 'map_paint_gesture',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>['benchmark/map_paint_gesture.dart', ...arguments],
      metadata: <String, Object?>{
        'sizes': sizes,
        'strokeLengths': strokeLengths,
        'measurementScope': 'pure-dart-model-operation',
      },
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_core',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('map_paint_gesture: ${error.message}');
    exitCode = 64;
  }
}

// Keep this path pure map_core: Flutter frames and rebuilds are measured by the
// separate editor journey, so the two costs cannot be accidentally conflated.
({int elapsedUs, String checksum, int placements}) _measure(
  int size,
  List<Map<String, int>> cells,
) {
  MapLayer layer = const MapLayer.surface(id: 'surface', name: 'Surface');
  final stopwatch = Stopwatch()..start();
  for (final cell in cells) {
    layer = paintSurfacePlacement(
      layer: layer,
      mapSize: GridSize(width: size, height: size),
      x: cell['x']!,
      y: cell['y']!,
      surfacePresetId: cell['preset']!.isEven ? 'water' : 'mud',
    );
  }
  stopwatch.stop();
  final placements = getSurfacePlacements(layer);
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(
      placements.map((placement) => placement.toJson()).toList(growable: false),
    ),
    placements: placements.length,
  );
}

List<Map<String, int>> _strokeCells(int size, int length) =>
    List<Map<String, int>>.generate(length, (index) {
      final offset = (index * 17 + index ~/ 7) % (size * size);
      return <String, int>{
        'x': offset % size,
        'y': offset ~/ size,
        'preset': index,
      };
    }, growable: false);
