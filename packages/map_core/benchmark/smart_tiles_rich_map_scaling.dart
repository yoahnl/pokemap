import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../../tools/performance/benchmark_support.dart';
import '../../../tools/performance/smart_tiles_rich_map_fixture.dart';

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
      fallback: smartTilesRichMapExtents.join(','),
      singularLabel: 'extent',
    );
    for (final extent in extents) {
      if (!smartTilesRichMapExtents.contains(extent)) {
        throw FormatException(
          'extent must be one of ${smartTilesRichMapExtents.join(', ')}',
        );
      }
    }
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_core');

    final results = <Map<String, Object?>>[];
    for (final extent in extents) {
      final fixture = generateSmartTilesRichMapFixture(extent: extent);
      final viewport = _Viewport.centered(
        mapWidth: extent,
        mapHeight: extent,
        width: 24,
        height: 18,
      );
      final profiles = <String, Object?>{
        'generation': _profile(
          warmups: warmups,
          samples: samples,
          measure: () => _measureGeneration(extent),
        ),
        'fullFieldResolve': _profile(
          warmups: warmups,
          samples: samples,
          measure: () => _measureResolution(fixture),
        ),
        'viewportResolve': _profile(
          warmups: warmups,
          samples: samples,
          measure: () => _measureResolution(fixture, viewport: viewport),
        ),
        'lineEdit': _profile(
          warmups: warmups,
          samples: samples,
          measure: () => _measureEdit(
            fixture,
            const _EditKind.line(),
          ),
        ),
        'rectangleEdit': _profile(
          warmups: warmups,
          samples: samples,
          measure: () => _measureEdit(
            fixture,
            const _EditKind.rectangle(),
          ),
        ),
        'floodFillEdit': _profile(
          warmups: warmups,
          samples: samples,
          measure: () => _measureEdit(
            fixture,
            const _EditKind.floodFill(),
          ),
        ),
        'jsonRoundtrip': _profile(
          warmups: warmups,
          samples: samples,
          measure: () => _measureJsonRoundtrip(fixture),
        ),
      };
      final viewportResolution = _resolve(fixture, viewport: viewport);
      results.add(<String, Object?>{
        'extent': extent,
        'fixtureChecksum': fixture.structuralChecksum,
        'rssBytesAfterSamples': ProcessInfo.currentRss,
        'workCounts': fixture.workCounts.toJson(),
        'viewportWorkCounts': <String, Object?>{
          'requestedCellCount': viewport.width * viewport.height,
          'resolvedVisualCount': viewportResolution.visualCount,
        },
        'profiles': profiles,
      });
    }

    final receipt = await performanceReceipt(
      benchmark: 'smart_tiles_rich_map_scaling',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>[
        'benchmark/smart_tiles_rich_map_scaling.dart',
        ...arguments,
      ],
      metadata: <String, Object?>{
        'extents': extents,
        'fixtureKind': 'native-smart-tiles-rich-map',
      },
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_core',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('smart_tiles_rich_map_scaling: ${error.message}');
    exitCode = 64;
  }
}

Map<String, Object?> _profile({
  required int warmups,
  required int samples,
  required _Measurement Function() measure,
}) {
  for (var index = 0; index < warmups; index += 1) {
    measure();
  }
  final measured = <_Measurement>[
    for (var index = 0; index < samples; index += 1) measure(),
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

_Measurement _measureGeneration(int extent) {
  final stopwatch = Stopwatch()..start();
  final fixture = generateSmartTilesRichMapFixture(extent: extent);
  stopwatch.stop();
  return _Measurement(
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: fixture.structuralChecksum,
  );
}

_Measurement _measureResolution(
  SmartTilesRichMapFixture fixture, {
  _Viewport? viewport,
}) {
  final stopwatch = Stopwatch()..start();
  final result = _resolve(fixture, viewport: viewport);
  stopwatch.stop();
  return _Measurement(
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: result.checksum,
  );
}

_Resolution _resolve(
  SmartTilesRichMapFixture fixture, {
  _Viewport? viewport,
}) {
  var visualCount = 0;
  final signatures = <Object?>[];
  for (final layer in fixture.map.layers.whereType<SmartTileLayer>()) {
    for (final pass in SmartTileVisualPass.values) {
      final visuals = resolveSmartTileLayerVisuals(
        map: fixture.map,
        layer: layer,
        catalog: fixture.manifest.smartTileCatalog,
        pass: pass,
        projectSeed: 811,
        elapsedMs: 470,
        startX: viewport?.startX ?? 0,
        startY: viewport?.startY ?? 0,
        endX: viewport?.endX,
        endY: viewport?.endY,
      );
      visualCount += visuals.length;
      signatures.add(<Object?>[
        layer.id,
        pass.name,
        visuals.length,
        if (visuals.isNotEmpty) _visualSignature(visuals.first),
        if (visuals.length > 1) _visualSignature(visuals.last),
      ]);
    }
  }
  return _Resolution(
    visualCount: visualCount,
    checksum: stableFingerprint(signatures),
  );
}

List<Object?> _visualSignature(SmartTileLayerVisual visual) => <Object?>[
      visual.cellX,
      visual.cellY,
      visual.ruleId,
      visual.candidateId,
      visual.channel.name,
      visual.tilesetId,
      visual.sourceRect.x,
      visual.sourceRect.y,
      visual.drawOrder,
    ];

_Measurement _measureEdit(
  SmartTilesRichMapFixture fixture,
  _EditKind kind,
) {
  final layer = fixture.map.layers.whereType<SmartTileLayer>().first;
  final extent = fixture.extent;
  final selection = switch (kind.name) {
    _EditName.line => SmartTileGestureSelection.line(
        start: GridPos(x: 0, y: extent ~/ 2),
        end: GridPos(x: extent - 1, y: extent ~/ 2),
      ),
    _EditName.rectangle => SmartTileGestureSelection.rectangle(
        start: GridPos(x: extent ~/ 4, y: extent ~/ 4),
        end: GridPos(x: extent ~/ 2, y: extent ~/ 2),
      ),
    _EditName.floodFill => const SmartTileGestureSelection.floodFill(
        seed: GridPos(x: 1, y: 1),
      ),
  };
  final stopwatch = Stopwatch()..start();
  final cells = compileSmartTileGestureSelection(
    layer,
    mapSize: fixture.map.size,
    selection: selection,
    maximumCellCount: extent * extent,
  );
  final edited = applySmartTileMaterialGesture(
    layer,
    mapSize: fixture.map.size,
    cells: cells,
    materialId: 'dirt',
  );
  stopwatch.stop();
  final semanticCells = smartTileSemanticCells(edited);
  return _Measurement(
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(<Object?>[
      kind.name.name,
      cells.length,
      edited.materialPalette,
      semanticCells.first,
      semanticCells[semanticCells.length ~/ 2],
      semanticCells.last,
    ]),
  );
}

_Measurement _measureJsonRoundtrip(SmartTilesRichMapFixture fixture) {
  final stopwatch = Stopwatch()..start();
  final encodedManifest = jsonEncode(fixture.manifest.toJson());
  final encodedMap = jsonEncode(fixture.map.toJson());
  final decodedManifest = ProjectManifest.fromJson(
    Map<String, dynamic>.from(jsonDecode(encodedManifest) as Map),
  );
  final decodedMap = MapData.fromJson(
    Map<String, dynamic>.from(jsonDecode(encodedMap) as Map),
  );
  stopwatch.stop();
  final smartLayers = decodedMap.layers.whereType<SmartTileLayer>().toList();
  return _Measurement(
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(<Object?>[
      decodedManifest.name,
      decodedManifest.smartTileCatalog.presets.length,
      decodedMap.id,
      decodedMap.size.width,
      decodedMap.size.height,
      decodedMap.layers.length,
      smartLayers.length,
      smartTileSemanticCells(smartLayers.first).last,
      encodedManifest.length,
      encodedMap.length,
    ]),
  );
}

final class _Measurement {
  const _Measurement({required this.elapsedUs, required this.checksum});

  final int elapsedUs;
  final String checksum;
}

final class _Resolution {
  const _Resolution({required this.visualCount, required this.checksum});

  final int visualCount;
  final String checksum;
}

final class _Viewport {
  const _Viewport({
    required this.startX,
    required this.startY,
    required this.width,
    required this.height,
  });

  factory _Viewport.centered({
    required int mapWidth,
    required int mapHeight,
    required int width,
    required int height,
  }) =>
      _Viewport(
        startX: (mapWidth - width) ~/ 2,
        startY: (mapHeight - height) ~/ 2,
        width: width,
        height: height,
      );

  final int startX;
  final int startY;
  final int width;
  final int height;

  int get endX => startX + width;
  int get endY => startY + height;
}

enum _EditName { line, rectangle, floodFill }

final class _EditKind {
  const _EditKind.line() : name = _EditName.line;
  const _EditKind.rectangle() : name = _EditName.rectangle;
  const _EditKind.floodFill() : name = _EditName.floodFill;

  final _EditName name;
}
