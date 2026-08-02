import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_gameplay/src/collision/world_collision_storage.dart';
import 'package:map_gameplay/src/gameplay_world_state.dart'
    show GameplayWorldStateCollisionStorageDiagnostics;

import '../../../tools/performance/benchmark_support.dart'
    show sourceTreeFingerprint;

const _schemaVersion = 2;
const _generatorVersion = 1;

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final outputFile =
        options.child ? null : _validatedOutputFile(options.outputPath!);
    final results = <Map<String, Object?>>[
      for (final size in options.sizes)
        _measureSize(
          size,
          warmups: options.warmups,
          samples: options.samples,
        ),
    ];
    final maskResults = <Map<String, Object?>>[
      for (final size in options.sizes)
        _measureSparseMaskSize(
          size,
          warmups: options.warmups,
          samples: options.samples,
        ),
    ];
    final isolatedResults = options.child || options.isolatedSize == null
        ? const <Map<String, Object?>>[]
        : await _measureIsolated(options);
    final status = await _gitValue(<String>['status', '--porcelain=v1']);
    final output = <String, Object?>{
      'schemaVersion': _schemaVersion,
      'generatorVersion': _generatorVersion,
      'benchmark': 'world_collision_scaling',
      'executionMode': const bool.fromEnvironment('dart.vm.product')
          ? 'dart-aot'
          : 'dart-jit',
      'sdk': Platform.version,
      'toolchain': <String, Object?>{
        'dart': Platform.version,
        'flutter': Platform.environment['POKEMAP_FLUTTER_VERSION'] ??
            'not-applicable-pure-dart',
        'flame': Platform.environment['POKEMAP_FLAME_VERSION'] ??
            'not-applicable-pure-dart',
      },
      'os': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'architecture': _architectureLabel(),
      'commit': await _gitValue(<String>['rev-parse', 'HEAD']),
      'treeState': status.isEmpty ? 'clean' : 'dirty',
      'treeFingerprint': await sourceTreeFingerprint(status: status),
      'warmups': options.warmups,
      'sampleCount': options.samples,
      'command': <String>[
        Platform.resolvedExecutable,
        'benchmark/world_collision_scaling.dart',
        ...arguments,
      ],
      'memory': <String, Object?>{
        'rssBytes': ProcessInfo.currentRss,
        'heapBytes': null,
        'heapAvailability': 'not exposed by dart:io',
      },
      'scenario': 'no-mask-one-dynamic-entity',
      'results': results,
      'maskScenario': 'sparse-64px-four-chunk-boundary-mask',
      'maskResults': maskResults,
      if (isolatedResults.isNotEmpty) 'isolatedResults': isolatedResults,
    };
    if (!options.child) {
      final resolvedOutput = outputFile!;
      await resolvedOutput.parent.create(recursive: true);
      await resolvedOutput.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(output)}\n',
      );
    }
    stdout.writeln(jsonEncode(output));
  } on FormatException catch (error) {
    stderr.writeln('world_collision_scaling: ${error.message}');
    exitCode = 64;
  }
}

Map<String, Object?> _measureSparseMaskSize(
  int size, {
  required int warmups,
  required int samples,
}) {
  final mask = _sparseBoundaryMask();
  for (var index = 0; index < warmups; index += 1) {
    _buildSparseMaskStorage(size, mask);
  }
  final builds = <({int elapsedUs, WorldCollisionStorage storage})>[
    for (var index = 0; index < samples; index += 1)
      _buildSparseMaskStorage(size, mask),
  ];
  final buildSamples =
      builds.map((build) => build.elapsedUs).toList(growable: false)..sort();
  final retained = builds.last.storage;
  final queryMeasurements = <({int elapsedUs, String resultChecksum})>[
    for (var index = 0; index < samples; index += 1)
      _measureSparseMaskQueries(retained),
  ];
  final queryChecksum = queryMeasurements.first.resultChecksum;
  if (queryMeasurements.any(
    (measurement) => measurement.resultChecksum != queryChecksum,
  )) {
    throw StateError('Unstable sparse-mask checksum for size $size.');
  }
  final querySamples = queryMeasurements
      .map((measurement) => measurement.elapsedUs)
      .toList(growable: false)
    ..sort();
  return <String, Object?>{
    'sizeCells': size,
    'generatorVersion': _generatorVersion,
    'datasetFingerprint': '${_fixtureFingerprint(size)}-mask64',
    'allocatedPixelMaskChunks': retained.allocatedPixelMaskChunkCount,
    'allocatedPixelMaskWords': retained.allocatedPixelMaskWordCount,
    'build': _distribution(buildSamples),
    'queries': <String, Object?>{
      ..._distribution(querySamples),
      'resultChecksum': queryChecksum,
    },
  };
}

({int elapsedUs, WorldCollisionStorage storage}) _buildSparseMaskStorage(
  int size,
  ElementCollisionPixelMask mask,
) {
  final stopwatch = Stopwatch()..start();
  final builder = WorldCollisionStorageBuilder(
    widthCells: size,
    heightCells: size,
    tileWidthPx: 16,
    tileHeightPx: 16,
    tileCollisionCells: List<bool>.filled(size * size, false),
    placedElementCollisionCells: List<bool>.filled(size * size, false),
  );
  builder.stampPackedMask(
    leftPx: 0,
    topPx: 0,
    mask: mask,
    transform: QuarterTurnPixelTransform(
      sourcePixelSize: const GridSize(width: 64, height: 64),
      destinationPixelSize: const GridSize(width: 64, height: 64),
      quarterTurns: 0,
    ),
  );
  final storage = builder.build();
  stopwatch.stop();
  return (elapsedUs: stopwatch.elapsedMicroseconds, storage: storage);
}

ElementCollisionPixelMask _sparseBoundaryMask() {
  final pixels = List<bool>.filled(64 * 64, false);
  for (final point in const <(int, int)>[
    (31, 31),
    (32, 31),
    (31, 32),
    (32, 32),
  ]) {
    pixels[point.$2 * 64 + point.$1] = true;
  }
  return ElementCollisionPixelMask(
    widthPx: 64,
    heightPx: 64,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: 64,
      heightPx: 64,
      solidPixels: pixels,
    ),
  );
}

({int elapsedUs, String resultChecksum}) _measureSparseMaskQueries(
  WorldCollisionStorage storage,
) {
  var checksum = 0x811c9dc5;
  final stopwatch = Stopwatch()..start();
  for (final point in const <(int, int)>[
    (31, 31),
    (32, 31),
    (31, 32),
    (32, 32),
    (30, 30),
  ]) {
    final blocked = storage.collidesPixelRect(
      PixelRect(
        leftPx: point.$1,
        topPx: point.$2,
        widthPx: 1,
        heightPx: 1,
      ),
      isDynamicCellBlocked: (_) => false,
    );
    checksum = ((checksum ^ (blocked ? 1 : 0)) * 0x01000193) & 0xffffffff;
  }
  stopwatch.stop();
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    resultChecksum: checksum.toRadixString(16).padLeft(8, '0'),
  );
}

Map<String, Object?> _measureSize(
  int size, {
  required int warmups,
  required int samples,
}) {
  final fixture = _fixture(size);
  for (var i = 0; i < warmups; i += 1) {
    _measureBuild(fixture);
    _measureMove(fixture);
    _measureQueries(fixture);
  }
  final buildSamples = <int>[
    for (var i = 0; i < samples; i += 1) _measureBuild(fixture),
  ]..sort();
  final moveSamples = <int>[
    for (var i = 0; i < samples; i += 1) _measureMove(fixture),
  ]..sort();
  final queryMeasurements = <({int elapsedUs, String resultChecksum})>[
    for (var i = 0; i < samples; i += 1) _measureQueries(fixture),
  ];
  final queryChecksum = queryMeasurements.first.resultChecksum;
  if (queryMeasurements.any(
    (measurement) => measurement.resultChecksum != queryChecksum,
  )) {
    throw StateError('Unstable collision query checksum for size $size.');
  }
  final querySamples = queryMeasurements
      .map((measurement) => measurement.elapsedUs)
      .toList(growable: false)
    ..sort();
  final rssBefore = ProcessInfo.currentRss;
  final retainedWorld = GameplayWorldState.initial(
    map: fixture,
    playerPos: const GridPos(x: 0, y: 0),
  );
  final rssAfter = ProcessInfo.currentRss;

  return <String, Object?>{
    'sizeCells': size,
    'cellCount': size * size,
    'generatorVersion': _generatorVersion,
    'datasetFingerprint': _fixtureFingerprint(size),
    'pixelWidth': size * 16,
    'pixelHeight': size * 16,
    'allocatedPixelMaskChunks': retainedWorld.debugAllocatedPixelMaskChunkCount,
    'allocatedPixelMaskWords': retainedWorld.debugAllocatedPixelMaskWordCount,
    'rssBeforeRetainedBuildBytes': rssBefore,
    'rssAfterRetainedBuildBytes': rssAfter,
    'rssDeltaBytes': rssAfter - rssBefore,
    'build': _distribution(buildSamples),
    'move': _distribution(moveSamples),
    'queries1000': <String, Object?>{
      ..._distribution(querySamples),
      'resultChecksum': queryChecksum,
    },
  };
}

String _fixtureFingerprint(int size) {
  final specification =
      'v$_generatorVersion|$size:$size|tile=16:16|cells=false|npc=1:1';
  var hash = 0x811c9dc5;
  for (final codeUnit in specification.codeUnits) {
    hash = ((hash ^ codeUnit) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

int _measureBuild(MapData fixture) {
  final stopwatch = Stopwatch()..start();
  final world = GameplayWorldState.initial(
    map: fixture,
    playerPos: const GridPos(x: 0, y: 0),
  );
  stopwatch.stop();
  if (world.debugAllocatedPixelMaskChunkCount < 0) {
    throw StateError('Unreachable collision storage count.');
  }
  return stopwatch.elapsedMicroseconds;
}

int _measureMove(MapData fixture) {
  final world = GameplayWorldState.initial(
    map: fixture,
    playerPos: const GridPos(x: 0, y: 0),
  );
  final target = GridPos(
    x: fixture.size.width - 2,
    y: fixture.size.height - 2,
  );
  final stopwatch = Stopwatch()..start();
  final moved = world.withEntityPosition('npc', target);
  stopwatch.stop();
  if (!moved.isCellCenterBlockedLegacyForGridIndexedSystems(
    target.x,
    target.y,
  )) {
    throw StateError('Moved entity disappeared from collision occupancy.');
  }
  return stopwatch.elapsedMicroseconds;
}

({int elapsedUs, String resultChecksum}) _measureQueries(MapData fixture) {
  final world = GameplayWorldState.initial(
    map: fixture,
    playerPos: const GridPos(x: 0, y: 0),
  );
  var checksum = 0x811c9dc5;
  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < 1000; i += 1) {
    final x = (i * 17) % fixture.size.width;
    final y = (i * 31) % fixture.size.height;
    final blocked = world.isCellCenterBlockedLegacyForGridIndexedSystems(x, y);
    checksum = ((checksum ^ (blocked ? 1 : 0)) * 0x01000193) & 0xffffffff;
  }
  stopwatch.stop();
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    resultChecksum: checksum.toRadixString(16).padLeft(8, '0'),
  );
}

MapData _fixture(int size) {
  return MapData(
    id: 'collision-$size',
    name: 'Collision $size',
    size: GridSize(width: size, height: size),
    layers: <MapLayer>[
      CollisionLayer(
        id: 'collision',
        name: 'Collision',
        collisions: List<bool>.filled(size * size, false),
      ),
    ],
    entities: const <MapEntity>[
      MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        npc: MapEntityNpcData(),
        blocksMovement: true,
      ),
    ],
  );
}

Map<String, Object?> _distribution(List<int> sortedSamples) =>
    <String, Object?>{
      'samplesUs': sortedSamples,
      'p50Us': _percentile(sortedSamples, 0.50),
      'p95Us': _percentile(sortedSamples, 0.95),
      'p99Us': _percentile(sortedSamples, 0.99),
    };

int _percentile(List<int> sortedSamples, double percentile) {
  final index = (percentile * sortedSamples.length).ceil() - 1;
  return sortedSamples[index.clamp(0, sortedSamples.length - 1)];
}

Future<List<Map<String, Object?>>> _measureIsolated(_Options options) async {
  final size = options.isolatedSize!;
  final results = <Map<String, Object?>>[];
  for (var run = 0; run < options.isolatedRuns; run += 1) {
    final invocation = _selfInvocation(<String>[
      '--child',
      'true',
      '--warmups',
      '${options.warmups}',
      '--samples',
      '${options.samples}',
      '--sizes',
      '$size',
    ]);
    final process = await Process.run(invocation.executable, invocation.args);
    if (process.exitCode != 0) {
      throw FormatException(
        'isolated run ${run + 1} failed: ${process.stderr}',
      );
    }
    final lines = '${process.stdout}'
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    final child = jsonDecode(lines.last) as Map<String, Object?>;
    results.add(<String, Object?>{
      'run': run + 1,
      'result': (child['results'] as List<Object?>).single,
    });
  }
  return List<Map<String, Object?>>.unmodifiable(results);
}

({String executable, List<String> args}) _selfInvocation(
  List<String> benchmarkArguments,
) {
  if (const bool.fromEnvironment('dart.vm.product')) {
    return (executable: Platform.resolvedExecutable, args: benchmarkArguments);
  }
  return (
    executable: Platform.resolvedExecutable,
    args: <String>[Platform.script.toFilePath(), ...benchmarkArguments],
  );
}

File _validatedOutputFile(String path) {
  final packageRoot = Directory(Directory.current.resolveSymbolicLinksSync());
  final requested = File.fromUri(
    packageRoot.uri.resolveUri(Uri.file(path)),
  ).absolute;
  var existingAncestor = requested.parent;
  final missingDirectories = <String>[];
  while (!existingAncestor.existsSync()) {
    final segments = existingAncestor.uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty ||
        existingAncestor.parent.path == existingAncestor.path) {
      throw const FormatException('output parent cannot be resolved');
    }
    missingDirectories.add(segments.last);
    existingAncestor = existingAncestor.parent;
  }
  final canonicalAncestor =
      Directory(existingAncestor.resolveSymbolicLinksSync());
  if (!_isWithin(packageRoot.uri, canonicalAncestor.uri)) {
    throw const FormatException(
        'output must stay inside packages/map_gameplay');
  }
  var canonicalParent = canonicalAncestor.uri;
  for (final directory in missingDirectories.reversed) {
    canonicalParent = canonicalParent.resolve('$directory/');
  }
  final fileName = requested.uri.pathSegments.last;
  final canonicalFile = File.fromUri(canonicalParent.resolve(fileName));
  if (!_isWithin(packageRoot.uri, canonicalFile.uri)) {
    throw const FormatException(
        'output must stay inside packages/map_gameplay');
  }
  if (FileSystemEntity.typeSync(
        canonicalFile.path,
        followLinks: false,
      ) ==
      FileSystemEntityType.link) {
    throw const FormatException('output must not be a symbolic link');
  }
  return canonicalFile;
}

bool _isWithin(Uri root, Uri candidate) =>
    candidate.path == root.path || candidate.path.startsWith(root.path);

Future<String> _gitValue(List<String> arguments) async {
  final result = await Process.run('git', arguments);
  return result.exitCode == 0 ? '${result.stdout}'.trim() : 'unknown';
}

String _architectureLabel() {
  final executable = Platform.resolvedExecutable.toLowerCase();
  if (executable.contains('arm64')) return 'arm64';
  if (executable.contains('x64') || executable.contains('x86_64')) return 'x64';
  return Platform.version.contains('arm64') ? 'arm64' : 'unknown';
}

final class _Options {
  const _Options({
    required this.warmups,
    required this.samples,
    required this.sizes,
    required this.isolatedSize,
    required this.isolatedRuns,
    required this.outputPath,
    required this.child,
  });

  final int warmups;
  final int samples;
  final List<int> sizes;
  final int? isolatedSize;
  final int isolatedRuns;
  final String? outputPath;
  final bool child;

  static _Options parse(List<String> arguments) {
    final values = <String, String>{};
    for (var i = 0; i < arguments.length; i += 1) {
      final argument = arguments[i];
      if (!argument.startsWith('--') || i + 1 >= arguments.length) {
        throw FormatException('invalid argument: $argument');
      }
      final key = argument.substring(2);
      if (values.containsKey(key)) {
        throw FormatException('duplicate option --$key');
      }
      values[key] = arguments[++i];
    }
    const allowed = <String>{
      'warmups',
      'samples',
      'sizes',
      'isolated-size',
      'isolated-runs',
      'output',
      'child',
    };
    final unknown = values.keys.where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw FormatException('unknown option --${unknown.first}');
    }
    final warmups = int.tryParse(values['warmups'] ?? '5');
    final samples = int.tryParse(values['samples'] ?? '30');
    final sizes = _positiveInts(values['sizes'] ?? '32,64,128,256');
    final isolatedSize = values['isolated-size'] == null
        ? null
        : int.tryParse(values['isolated-size']!);
    final isolatedRuns = int.tryParse(values['isolated-runs'] ?? '3');
    final child = switch (values['child'] ?? 'false') {
      'true' => true,
      'false' => false,
      final value => throw FormatException('invalid child flag: $value'),
    };
    if (warmups == null || warmups < 0) {
      throw const FormatException('warmups must be non-negative');
    }
    if (samples == null || samples <= 0) {
      throw const FormatException('samples must be positive');
    }
    if (isolatedSize != null && isolatedSize <= 1) {
      throw const FormatException('isolated-size must be greater than one');
    }
    if (isolatedRuns == null || isolatedRuns < 0) {
      throw const FormatException('isolated-runs must be non-negative');
    }
    if (isolatedSize != null && isolatedRuns == 0) {
      throw const FormatException(
        'isolated-runs must be positive with isolated-size',
      );
    }
    final output = values['output'];
    if (!child && (output == null || output.trim().isEmpty)) {
      throw const FormatException('--output is required');
    }
    return _Options(
      warmups: warmups,
      samples: samples,
      sizes: sizes,
      isolatedSize: isolatedSize,
      isolatedRuns: isolatedRuns,
      outputPath: output,
      child: child,
    );
  }

  static List<int> _positiveInts(String raw) {
    final values = <int>[];
    for (final token in raw.split(',')) {
      final value = int.tryParse(token);
      if (value == null || value <= 1) {
        throw FormatException('invalid size: $token');
      }
      values.add(value);
    }
    if (values.isEmpty) {
      throw const FormatException('sizes must not be empty');
    }
    return List<int>.unmodifiable(values);
  }
}
