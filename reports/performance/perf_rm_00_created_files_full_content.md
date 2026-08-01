# PERF-RM-00 — Annexe des fichiers créés / repris intégralement

Cette annexe accompagne `perf_rm_00_observability.md`. Elle contient le contenu complet des fichiers d’implémentation créés par le lot ainsi que des deux harnais repris de la Phase 1 (`surface_role_scaling` et `world_collision_scaling`) afin que la preuve RM-00 soit autonome.

## `tool/performance/benchmark_support.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

const performanceSchemaVersion = 2;
const performanceGeneratorVersion = 1;

final class PerformanceCli {
  PerformanceCli._(this._values);

  final Map<String, String> _values;

  static PerformanceCli parse(
    List<String> arguments, {
    required Set<String> allowed,
  }) {
    final values = <String, String>{};
    for (var index = 0; index < arguments.length; index += 1) {
      final argument = arguments[index];
      if (!argument.startsWith('--') || index + 1 >= arguments.length) {
        throw FormatException('invalid argument: $argument');
      }
      final key = argument.substring(2);
      if (!allowed.contains(key)) {
        throw FormatException('unknown option --$key');
      }
      if (values.containsKey(key)) {
        throw FormatException('duplicate option --$key');
      }
      values[key] = arguments[++index];
    }
    return PerformanceCli._(values);
  }

  int nonNegativeInt(String key, {required int fallback}) {
    final value = int.tryParse(_values[key] ?? '$fallback');
    if (value == null || value < 0) {
      throw FormatException('$key must be non-negative');
    }
    return value;
  }

  int positiveInt(String key, {required int fallback}) {
    final value = int.tryParse(_values[key] ?? '$fallback');
    if (value == null || value <= 0) {
      throw FormatException('$key must be positive');
    }
    return value;
  }

  List<int> positiveInts(
    String key, {
    required String fallback,
    required String singularLabel,
  }) {
    final values = <int>[];
    for (final token in (_values[key] ?? fallback).split(',')) {
      final value = int.tryParse(token);
      if (value == null) {
        throw FormatException('invalid $singularLabel: $token');
      }
      values.add(value);
    }
    if (values.isEmpty || values.any((value) => value <= 0)) {
      throw FormatException('$key must contain positive integers');
    }
    return List<int>.unmodifiable(values);
  }

  List<String> strings(String key, {required String fallback}) =>
      List<String>.unmodifiable(
        (_values[key] ?? fallback)
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty),
      );

  String requiredValue(String key) {
    final value = _values[key];
    if (value == null || value.trim().isEmpty) {
      throw FormatException('--$key is required');
    }
    return value;
  }
}

/// Uses nearest-rank percentiles so every harness shares deterministic
/// small-sample semantics instead of relying on interpolated host libraries.
int nearestRankPercentile(List<int> sortedSamples, double percentile) {
  if (sortedSamples.isEmpty) {
    throw const FormatException('percentiles require at least one sample');
  }
  final index = (percentile * sortedSamples.length).ceil() - 1;
  return sortedSamples[index.clamp(0, sortedSamples.length - 1)];
}

Map<String, Object?> percentileFields(List<int> samples) {
  final sorted = List<int>.of(samples)..sort();
  return <String, Object?>{
    'samplesUs': sorted,
    'p50Us': nearestRankPercentile(sorted, 0.50),
    'p95Us': nearestRankPercentile(sorted, 0.95),
    'p99Us': nearestRankPercentile(sorted, 0.99),
  };
}

String stableFingerprint(Object? value) {
  return stableBytesFingerprint(utf8.encode(jsonEncode(value)));
}

String stableBytesFingerprint(List<int> bytes) {
  var hash = 0xcbf29ce484222325;
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
  }
  final unsignedHash = hash < 0
      ? BigInt.from(hash) + (BigInt.one << 64)
      : BigInt.from(hash);
  return unsignedHash.toRadixString(16).padLeft(16, '0');
}

Future<Map<String, Object?>> performanceReceipt({
  required String benchmark,
  required int warmups,
  required int sampleCount,
  required List<String> arguments,
  required List<Map<String, Object?>> results,
  Map<String, Object?> metadata = const <String, Object?>{},
}) async {
  final status = await _git(<String>['status', '--porcelain=v1']);
  return <String, Object?>{
    'schemaVersion': performanceSchemaVersion,
    'generatorVersion': performanceGeneratorVersion,
    'benchmark': benchmark,
    'executionMode': const bool.fromEnvironment('dart.vm.product')
        ? 'dart-aot'
        : 'dart-jit',
    'sdk': Platform.version,
    'toolchain': <String, Object?>{
      'dart': Platform.version,
      'flutter':
          Platform.environment['POKEMAP_FLUTTER_VERSION'] ??
          'not-applicable-pure-dart',
      'flame':
          Platform.environment['POKEMAP_FLAME_VERSION'] ??
          'not-applicable-pure-dart',
    },
    'os': Platform.operatingSystem,
    'osVersion': Platform.operatingSystemVersion,
    'architecture': _architectureLabel(),
    'commit': await _git(<String>['rev-parse', 'HEAD']),
    'treeState': status.isEmpty ? 'clean' : 'dirty',
    'treeFingerprint': await sourceTreeFingerprint(status: status),
    'warmups': warmups,
    'sampleCount': sampleCount,
    'command': <String>[Platform.resolvedExecutable, ...arguments],
    'memory': <String, Object?>{
      'rssBytes': ProcessInfo.currentRss,
      'heapBytes': null,
      'heapAvailability': 'not exposed by dart:io',
    },
    ...metadata,
    'results': results,
  };
}

Future<void> writePerformanceReceipt({
  required String outputPath,
  required String packageName,
  required Map<String, Object?> receipt,
}) async {
  final output = validatedPackageOutput(outputPath, packageName: packageName);
  await output.parent.create(recursive: true);
  final temporary = File('${output.path}.tmp-${pid.toString()}');
  await temporary.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(receipt)}\n',
    flush: true,
  );
  if (await output.exists()) await output.delete();
  await temporary.rename(output.path);
  stdout.writeln(jsonEncode(receipt));
}

/// Resolves the nearest existing ancestor before creating output directories.
/// This keeps a symlink inside a package from redirecting evidence elsewhere.
File validatedPackageOutput(String path, {required String packageName}) {
  final packageRoot = Directory(Directory.current.resolveSymbolicLinksSync());
  final requested = File.fromUri(
    packageRoot.uri.resolveUri(Uri.file(path)),
  ).absolute;
  var ancestor = requested.parent;
  final missing = <String>[];
  while (!ancestor.existsSync()) {
    if (ancestor.parent.path == ancestor.path) {
      throw const FormatException('output parent cannot be resolved');
    }
    missing.add(
      ancestor.uri.pathSegments.where((part) => part.isNotEmpty).last,
    );
    ancestor = ancestor.parent;
  }
  final canonicalAncestor = Directory(ancestor.resolveSymbolicLinksSync());
  if (!_isWithin(packageRoot.uri, canonicalAncestor.uri)) {
    throw FormatException('output must stay inside packages/$packageName');
  }
  var parentUri = canonicalAncestor.uri;
  for (final segment in missing.reversed) {
    parentUri = parentUri.resolve('$segment/');
  }
  final fileName = requested.uri.pathSegments.last;
  final output = File.fromUri(parentUri.resolve(fileName));
  if (!_isWithin(packageRoot.uri, output.uri)) {
    throw FormatException('output must stay inside packages/$packageName');
  }
  final type = FileSystemEntity.typeSync(output.path, followLinks: false);
  if (type == FileSystemEntityType.link ||
      (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.file)) {
    throw const FormatException('output must be a regular file');
  }
  return output;
}

bool _isWithin(Uri root, Uri candidate) {
  final rootPath = root.path.endsWith('/') ? root.path : '${root.path}/';
  return candidate.path == root.path || candidate.path.startsWith(rootPath);
}

String _architectureLabel() {
  final executable = Platform.resolvedExecutable.toLowerCase();
  if (executable.contains('arm64') || executable.contains('aarch64')) {
    return 'arm64';
  }
  if (executable.contains('x64') || executable.contains('x86_64')) return 'x64';
  return Platform.version.contains('arm64') ? 'arm64' : 'unknown';
}

Future<String> _git(List<String> arguments, {String? workingDirectory}) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
  );
  return result.exitCode == 0 ? '${result.stdout}'.trim() : 'unavailable';
}

/// Fingerprints the whole Git tree from its root, including untracked content.
/// Hashing only untracked path names would make edited benchmark sources look
/// comparable while this phase is still intentionally uncommitted.
Future<String> sourceTreeFingerprint({String? status}) async {
  final repositoryRoot = await _git(<String>['rev-parse', '--show-toplevel']);
  final effectiveStatus =
      status ??
      await _git(<String>[
        'status',
        '--porcelain=v1',
      ], workingDirectory: repositoryRoot);
  final diff = await _git(<String>[
    'diff',
    '--binary',
    'HEAD',
  ], workingDirectory: repositoryRoot);
  final untracked = await _git(<String>[
    'ls-files',
    '--others',
    '--exclude-standard',
  ], workingDirectory: repositoryRoot);
  final untrackedEntries = <Map<String, Object?>>[];
  final paths =
      untracked
          .split('\n')
          .where((path) => path.trim().isNotEmpty)
          .toList(growable: false)
        ..sort();
  for (final path in paths) {
    final file = File.fromUri(
      Uri.directory(repositoryRoot).resolveUri(Uri.file(path)),
    );
    try {
      untrackedEntries.add(<String, Object?>{
        'path': path,
        'bytes': await file.length(),
        'content': stableBytesFingerprint(await file.readAsBytes()),
      });
    } on FileSystemException {
      untrackedEntries.add(<String, Object?>{
        'path': path,
        'content': 'unavailable',
      });
    }
  }
  return stableFingerprint(<String, Object?>{
    'status': effectiveStatus,
    'diff': diff,
    'untracked': untrackedEntries,
  });
}
~~~~

## `packages/map_core/benchmark/surface_role_scaling.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import '../../../tool/performance/benchmark_support.dart'
    show sourceTreeFingerprint;

const _schemaVersion = 2;
const _generatorVersion = 1;
const _knownFixtures = <String>{'dense', 'hole', 'line', 'sparse', 'mixed'};
const _knownModes = <String>{'legacy', 'topology'};

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final outputFile = _validatedOutputFile(options.outputPath);
    final results = <Map<String, Object?>>[];
    for (final fixture in options.fixtures) {
      for (final size in options.sizes) {
        final placements = _placements(fixture, size);
        final fingerprint = _fingerprint(placements);
        String? expectedRoleChecksum;
        for (final mode in options.modes) {
          for (var i = 0; i < options.warmups; i += 1) {
            _measure(mode, placements);
          }
          final measurements = <({int elapsedUs, String roleChecksum})>[
            for (var i = 0; i < options.samples; i += 1)
              _measure(mode, placements),
          ];
          final roleChecksum = measurements.first.roleChecksum;
          if (measurements.any(
            (measurement) => measurement.roleChecksum != roleChecksum,
          )) {
            throw StateError('Unstable role checksum for $fixture/$size.');
          }
          expectedRoleChecksum ??= roleChecksum;
          if (expectedRoleChecksum != roleChecksum) {
            throw StateError(
              'Role mismatch between benchmark modes for $fixture/$size.',
            );
          }
          final samples = measurements
              .map((measurement) => measurement.elapsedUs)
              .toList(growable: false)
            ..sort();
          results.add(<String, Object?>{
            'mode': mode,
            'fixture': fixture,
            'generatorVersion': _generatorVersion,
            'datasetFingerprint': fingerprint,
            'roleChecksum': roleChecksum,
            'placementCount': placements.length,
            'rssBytesAfterSamples': ProcessInfo.currentRss,
            'samplesUs': samples,
            'p50Us': _percentile(samples, 0.50),
            'p95Us': _percentile(samples, 0.95),
            'p99Us': _percentile(samples, 0.99),
          });
        }
      }
    }

    final status = await _gitValue(<String>['status', '--porcelain=v1']);
    final output = <String, Object?>{
      'schemaVersion': _schemaVersion,
      'generatorVersion': _generatorVersion,
      'benchmark': 'surface_role_scaling',
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
        'benchmark/surface_role_scaling.dart',
        ...arguments,
      ],
      'memory': <String, Object?>{
        'rssBytes': ProcessInfo.currentRss,
        'heapBytes': null,
        'heapAvailability': 'not exposed by dart:io',
      },
      'measurementScope': 'pure-dart-surface-role-resolution',
      'fixtures': options.fixtures,
      'modes': options.modes,
      'results': results,
    };
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(output)}\n',
    );
    stdout.writeln(jsonEncode(output));
  } on FormatException catch (error) {
    stderr.writeln('surface_role_scaling: ${error.message}');
    exitCode = 64;
  }
}

({int elapsedUs, String roleChecksum}) _measure(
  String mode,
  List<SurfaceCellPlacement> placements,
) {
  final stopwatch = Stopwatch()..start();
  var checksum = 0x811c9dc5;
  if (mode == 'legacy') {
    for (final placement in placements) {
      final role = resolveSurfaceVariantRoleForPlacement(
        placements: placements,
        x: placement.x,
        y: placement.y,
        surfacePresetId: placement.surfacePresetId,
      );
      checksum = ((checksum ^ role.index) * 0x01000193) & 0xffffffff;
    }
  } else {
    final topology = SurfacePlacementTopology(placements);
    for (final placement in placements) {
      final role = topology.roleAt(
        x: placement.x,
        y: placement.y,
        surfacePresetId: placement.surfacePresetId,
      );
      checksum = ((checksum ^ role.index) * 0x01000193) & 0xffffffff;
    }
  }
  stopwatch.stop();
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    roleChecksum: checksum.toRadixString(16).padLeft(8, '0'),
  );
}

String _fingerprint(List<SurfaceCellPlacement> placements) {
  final encoded = placements
      .map((placement) =>
          '${placement.x}:${placement.y}:${placement.surfacePresetId}')
      .join('|');
  return sha256.convert(utf8.encode(encoded)).toString();
}

List<SurfaceCellPlacement> _placements(String fixture, int count) {
  final width = math.max(1, math.sqrt(count).ceil());
  final out = <SurfaceCellPlacement>[];
  for (var index = 0; index < count; index += 1) {
    final x = switch (fixture) {
      'line' => index,
      'sparse' => index * 2,
      _ => index % width,
    };
    final y = switch (fixture) {
      'line' || 'sparse' => 0,
      _ => index ~/ width,
    };
    if (fixture == 'hole' &&
        x == width ~/ 2 &&
        y == math.max(1, count ~/ width) ~/ 2) {
      // Move the center occupancy far away while retaining an exact count.
      out.add(
        SurfaceCellPlacement(
          x: width + index,
          y: width + index,
          surfacePresetId: 'water',
        ),
      );
      continue;
    }
    out.add(
      SurfaceCellPlacement(
        x: x,
        y: y,
        surfacePresetId: fixture == 'mixed' && index.isOdd ? 'lava' : 'water',
      ),
    );
  }
  // Reverse a stable subset so the index cannot rely on authoring order.
  return List<SurfaceCellPlacement>.unmodifiable(out.reversed);
}

int _percentile(List<int> sortedSamples, double percentile) {
  final index = (percentile * sortedSamples.length).ceil() - 1;
  return sortedSamples[index.clamp(0, sortedSamples.length - 1)];
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
    throw const FormatException('output must stay inside packages/map_core');
  }
  var canonicalParent = canonicalAncestor.uri;
  for (final directory in missingDirectories.reversed) {
    canonicalParent = canonicalParent.resolve('$directory/');
  }
  final fileName = requested.uri.pathSegments.last;
  final canonicalFile = File.fromUri(canonicalParent.resolve(fileName));
  if (!_isWithin(packageRoot.uri, canonicalFile.uri)) {
    throw const FormatException('output must stay inside packages/map_core');
  }
  if (FileSystemEntity.typeSync(
        canonicalFile.path,
        followLinks: false,
      ) ==
      FileSystemEntityType.link) {
    throw const FormatException('output must not be a symbolic link');
  }
  if (canonicalFile.existsSync()) {
    final canonicalExisting =
        Uri.file(canonicalFile.resolveSymbolicLinksSync());
    if (!_isWithin(packageRoot.uri, canonicalExisting)) {
      throw const FormatException('output symlink leaves packages/map_core');
    }
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
    required this.fixtures,
    required this.modes,
    required this.outputPath,
  });

  final int warmups;
  final int samples;
  final List<int> sizes;
  final List<String> fixtures;
  final List<String> modes;
  final String outputPath;

  static _Options parse(List<String> arguments) {
    final values = <String, String>{};
    for (var i = 0; i < arguments.length; i += 1) {
      final argument = arguments[i];
      if (!argument.startsWith('--') || i + 1 >= arguments.length) {
        throw FormatException('invalid argument: $argument');
      }
      values[argument.substring(2)] = arguments[++i];
    }
    const allowed = <String>{
      'warmups',
      'samples',
      'sizes',
      'fixtures',
      'modes',
      'output',
    };
    final unknown = values.keys.where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw FormatException('unknown option --${unknown.first}');
    }
    final warmups = int.tryParse(values['warmups'] ?? '5');
    final samples = int.tryParse(values['samples'] ?? '30');
    if (warmups == null || warmups < 0) {
      throw const FormatException('warmups must be non-negative');
    }
    if (samples == null || samples <= 0) {
      throw const FormatException('samples must be positive');
    }
    final sizes = _positiveInts(values['sizes'] ?? '100,400,1024,2500');
    final fixtures = (values['fixtures'] ?? 'dense,hole,line,sparse,mixed')
        .split(',')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (fixtures.isEmpty) {
      throw const FormatException('fixtures must not be empty');
    }
    for (final fixture in fixtures) {
      if (!_knownFixtures.contains(fixture)) {
        throw FormatException('unknown fixture: $fixture');
      }
    }
    final modes = (values['modes'] ?? 'topology')
        .split(',')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (modes.isEmpty) {
      throw const FormatException('modes must not be empty');
    }
    for (final mode in modes) {
      if (!_knownModes.contains(mode)) {
        throw FormatException('unknown mode: $mode');
      }
    }
    final output = values['output'];
    if (output == null || output.trim().isEmpty) {
      throw const FormatException('--output is required');
    }
    return _Options(
      warmups: warmups,
      samples: samples,
      sizes: sizes,
      fixtures: List<String>.unmodifiable(fixtures),
      modes: List<String>.unmodifiable(modes),
      outputPath: output,
    );
  }

  static List<int> _positiveInts(String raw) {
    final tokens = raw.split(',');
    final values = <int>[];
    for (final token in tokens) {
      final value = int.tryParse(token);
      if (value == null) {
        throw FormatException('invalid size: $token');
      }
      values.add(value);
    }
    if (values.isEmpty || values.any((value) => value <= 0)) {
      throw const FormatException('sizes must contain positive integers');
    }
    return List<int>.unmodifiable(values);
  }
}
~~~~

## `packages/map_core/benchmark/map_paint_gesture.dart`

~~~~dart
import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../../tool/performance/benchmark_support.dart';

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
~~~~

## `packages/map_core/benchmark/group_hierarchy_scaling.dart`

~~~~dart
import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../../tool/performance/benchmark_support.dart';

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{'warmups', 'samples', 'sizes', 'output'},
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 5);
    final samples = cli.positiveInt('samples', fallback: 30);
    final sizes = cli.positiveInts(
      'sizes',
      fallback: '10,100,400,800,1600,3200',
      singularLabel: 'size',
    );
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_core');
    final results = <Map<String, Object?>>[];

    for (final size in sizes) {
      final manifest = _manifest(size);
      final fingerprint = stableFingerprint(manifest.toJson());
      for (var index = 0; index < warmups; index += 1) {
        ProjectValidator.validate(manifest);
      }
      final measured = <({int elapsedUs, String checksum})>[
        for (var index = 0; index < samples; index += 1) _measure(manifest),
      ];
      final checksum = measured.first.checksum;
      if (measured.any((sample) => sample.checksum != checksum)) {
        throw StateError('Unstable hierarchy result for $size groups.');
      }
      results.add(<String, Object?>{
        'groupCount': size,
        'hierarchyShape': 'balanced-parent-chain',
        'datasetFingerprint': fingerprint,
        'validationChecksum': checksum,
        'rssBytesAfterSamples': ProcessInfo.currentRss,
        ...percentileFields(
          measured.map((sample) => sample.elapsedUs).toList(growable: false),
        ),
      });
    }

    final receipt = await performanceReceipt(
      benchmark: 'group_hierarchy_scaling',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>[
        'benchmark/group_hierarchy_scaling.dart',
        ...arguments,
      ],
      metadata: <String, Object?>{'sizes': sizes},
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_core',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('group_hierarchy_scaling: ${error.message}');
    exitCode = 64;
  }
}

// Validate the real manifest rather than timing fixture construction; the
// checksum prevents a future optimizer from turning the work into a no-op.
({int elapsedUs, String checksum}) _measure(ProjectManifest manifest) {
  final stopwatch = Stopwatch()..start();
  ProjectValidator.validate(manifest);
  stopwatch.stop();
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(
      manifest.groups.map((group) => group.id).toList(growable: false),
    ),
  );
}

ProjectManifest _manifest(int size) => ProjectManifest(
      name: 'Hierarchy benchmark $size',
      version: ProjectVersion.v3,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      groups: List<ProjectMapGroup>.generate(
        size,
        (index) => ProjectMapGroup(
          id: 'group-$index',
          name: 'Group $index',
          type: MapGroupType.route,
          parentGroupId: index == 0 ? null : 'group-${(index - 1) ~/ 2}',
          sortOrder: index,
        ),
        growable: false,
      ),
    );
~~~~

## `packages/map_core/benchmark/json_roundtrip_scaling.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../../tool/performance/benchmark_support.dart';

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{'warmups', 'samples', 'bytes', 'output'},
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 5);
    final samples = cli.positiveInt('samples', fallback: 30);
    final byteSizes = cli.positiveInts(
      'bytes',
      fallback: '1024,102400,2420033,10485760',
      singularLabel: 'byte size',
    );
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_core');
    final results = <Map<String, Object?>>[];

    for (final targetBytes in byteSizes) {
      final fixture = _fixture(targetBytes);
      final encodedFixture = jsonEncode(fixture.toJson());
      final actualBytes = utf8.encode(encodedFixture).length;
      final fingerprint = stableFingerprint(encodedFixture);
      for (var index = 0; index < warmups; index += 1) {
        _measure(fixture);
      }
      final measured = <({int elapsedUs, String checksum})>[
        for (var index = 0; index < samples; index += 1) _measure(fixture),
      ];
      final checksum = measured.first.checksum;
      if (measured.any((sample) => sample.checksum != checksum)) {
        throw StateError('Unstable JSON result for $targetBytes bytes.');
      }
      results.add(<String, Object?>{
        'targetBytes': targetBytes,
        'actualBytes': actualBytes,
        'datasetFingerprint': fingerprint,
        'roundtripChecksum': checksum,
        'rssBytesAfterSamples': ProcessInfo.currentRss,
        ...percentileFields(
          measured.map((sample) => sample.elapsedUs).toList(growable: false),
        ),
      });
    }

    final receipt = await performanceReceipt(
      benchmark: 'json_roundtrip_scaling',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>[
        'benchmark/json_roundtrip_scaling.dart',
        ...arguments
      ],
      metadata: <String, Object?>{'targetBytes': byteSizes},
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_core',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('json_roundtrip_scaling: ${error.message}');
    exitCode = 64;
  }
}

// The timed region deliberately covers both JSON directions and typed model
// reconstruction; encoded fixture sizing happens outside the measurement.
({int elapsedUs, String checksum}) _measure(ProjectManifest manifest) {
  final stopwatch = Stopwatch()..start();
  final encoded = jsonEncode(manifest.toJson());
  final decoded = ProjectManifest.fromJson(
    Map<String, dynamic>.from(jsonDecode(encoded) as Map),
  );
  stopwatch.stop();
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(<Object?>[
      decoded.name,
      decoded.version.name,
      decoded.globalProperties['payload'],
    ]),
  );
}

ProjectManifest _fixture(int targetBytes) {
  ProjectManifest build(String payload) => ProjectManifest(
        name: 'JSON round-trip benchmark',
        version: ProjectVersion.v3,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        globalProperties: <String, dynamic>{'payload': payload},
      );

  final emptyBytes = utf8.encode(jsonEncode(build('').toJson())).length;
  final payloadLength = (targetBytes - emptyBytes).clamp(0, targetBytes);
  return build(_deterministicPayload(payloadLength));
}

String _deterministicPayload(int length) {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final buffer = StringBuffer();
  for (var index = 0; index < length; index += 1) {
    buffer.write(alphabet[index % alphabet.length]);
  }
  return buffer.toString();
}
~~~~

## `packages/map_core/test/benchmark/surface_role_scaling_cli_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes comparable legacy and topology results for one dataset',
      () async {
    await Directory('build/test').create(recursive: true);
    final outputDirectory = await Directory('build/test').createTemp(
      'surface_role_cli_',
    );
    addTearDown(() => outputDirectory.delete(recursive: true));
    final outputPath = '${outputDirectory.path}/result.json';

    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--sizes',
      '9',
      '--fixtures',
      'dense',
      '--modes',
      'legacy,topology',
      '--output',
      outputPath,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode(await File(outputPath).readAsString())
        as Map<String, Object?>;
    final results = payload['results']! as List<Object?>;
    expect(payload['schemaVersion'], 2);
    expect(results, hasLength(2));
    final legacy = results.first as Map<String, Object?>;
    final topology = results.last as Map<String, Object?>;
    expect(legacy['mode'], 'legacy');
    expect(topology['mode'], 'topology');
    expect(legacy['datasetFingerprint'], topology['datasetFingerprint']);
    expect(legacy['roleChecksum'], isNotEmpty);
    expect(legacy['roleChecksum'], topology['roleChecksum']);
  });

  test('rejects malformed size tokens and output paths outside the package',
      () async {
    final malformed = await _run(const <String>[
      '--sizes',
      '9,bad',
      '--output',
      'build/test/malformed.json',
    ]);
    final escaped = await _run(const <String>[
      '--sizes',
      '9',
      '--output',
      '../surface-role-escape.json',
    ]);

    expect(malformed.exitCode, 64);
    expect('${malformed.stderr}', contains('invalid size: bad'));
    expect(escaped.exitCode, 64);
    expect('${escaped.stderr}', contains('must stay inside packages/map_core'));
  });
}

Future<ProcessResult> _run(List<String> arguments) {
  return Process.run(
    Platform.resolvedExecutable,
    <String>['run', 'benchmark/surface_role_scaling.dart', ...arguments],
    workingDirectory: Directory.current.path,
  );
}
~~~~

## `packages/map_core/test/benchmark/map_paint_gesture_cli_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes a versioned deterministic map paint receipt', () async {
    final output = await _temporaryOutput('map_paint');

    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--sizes',
      '8',
      '--stroke-lengths',
      '1,4',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'map_paint_gesture');
    expect(payload['sampleCount'], 1);
    final rows = payload['results']! as List<Object?>;
    expect(rows, hasLength(2));
    for (final row in rows.cast<Map<String, Object?>>()) {
      expect(row['datasetFingerprint'], isNotEmpty);
      expect(row['paintChecksum'], isNotEmpty);
      expect(row['samplesUs'], hasLength(1));
      expect(row['p50Us'], row['p95Us']);
      expect(row['p95Us'], row['p99Us']);
    }
  });

  test('rejects zero samples, malformed strokes, and escaped output', () async {
    final zero = await _run(const <String>[
      '--samples',
      '0',
      '--output',
      'build/test/map-paint-zero.json',
    ]);
    final malformed = await _run(const <String>[
      '--stroke-lengths',
      '1,bad',
      '--output',
      'build/test/map-paint-malformed.json',
    ]);
    final escaped = await _run(const <String>[
      '--output',
      '../map-paint-escape.json',
    ]);

    expect(zero.exitCode, 64);
    expect('${zero.stderr}', contains('samples must be positive'));
    expect(malformed.exitCode, 64);
    expect('${malformed.stderr}', contains('invalid stroke length: bad'));
    expect(escaped.exitCode, 64);
    expect('${escaped.stderr}', contains('must stay inside packages/map_core'));
  });
}

Future<File> _temporaryOutput(String prefix) async {
  await Directory('build/test').create(recursive: true);
  final directory = await Directory('build/test').createTemp('${prefix}_cli_');
  addTearDown(() => directory.delete(recursive: true));
  return File('${directory.path}/result.json');
}

Future<ProcessResult> _run(List<String> arguments) => Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'benchmark/map_paint_gesture.dart', ...arguments],
      workingDirectory: Directory.current.path,
    );
~~~~

## `packages/map_core/test/benchmark/group_hierarchy_scaling_cli_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes hierarchy validation percentiles and a stable checksum',
      () async {
    final output = await _temporaryOutput('group_hierarchy');
    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--sizes',
      '3,8',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'group_hierarchy_scaling');
    final rows =
        (payload['results']! as List<Object?>).cast<Map<String, Object?>>();
    expect(rows.map((row) => row['groupCount']), <Object?>[3, 8]);
    expect(
        rows.every((row) => '${row['datasetFingerprint']}'.isNotEmpty), isTrue);
    expect(
        rows.every((row) => '${row['validationChecksum']}'.isNotEmpty), isTrue);
  });

  test('rejects zero samples and output paths outside map_core', () async {
    final zero = await _run(const <String>[
      '--samples',
      '0',
      '--output',
      'build/test/group-zero.json',
    ]);
    final escaped = await _run(const <String>[
      '--output',
      '../group-escape.json',
    ]);

    expect(zero.exitCode, 64);
    expect('${zero.stderr}', contains('samples must be positive'));
    expect(escaped.exitCode, 64);
    expect('${escaped.stderr}', contains('must stay inside packages/map_core'));
  });
}

Future<File> _temporaryOutput(String prefix) async {
  await Directory('build/test').create(recursive: true);
  final directory = await Directory('build/test').createTemp('${prefix}_cli_');
  addTearDown(() => directory.delete(recursive: true));
  return File('${directory.path}/result.json');
}

Future<ProcessResult> _run(List<String> arguments) => Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'benchmark/group_hierarchy_scaling.dart', ...arguments],
      workingDirectory: Directory.current.path,
    );
~~~~

## `packages/map_core/test/benchmark/json_roundtrip_scaling_cli_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes JSON round-trip size and percentile evidence', () async {
    final output = await _temporaryOutput('json_roundtrip');
    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--bytes',
      '512,2048',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'json_roundtrip_scaling');
    final rows =
        (payload['results']! as List<Object?>).cast<Map<String, Object?>>();
    expect(rows.map((row) => row['targetBytes']), <Object?>[512, 2048]);
    expect(rows.every((row) => (row['actualBytes']! as int) >= 512), isTrue);
    expect(
        rows.every((row) => '${row['roundtripChecksum']}'.isNotEmpty), isTrue);
  });

  test('rejects malformed byte sizes, zero samples, and escaped output',
      () async {
    final malformed = await _run(const <String>[
      '--bytes',
      '1024,nope',
      '--output',
      'build/test/json-malformed.json',
    ]);
    final zero = await _run(const <String>[
      '--samples',
      '0',
      '--output',
      'build/test/json-zero.json',
    ]);
    final escaped = await _run(const <String>[
      '--output',
      '../json-escape.json',
    ]);

    expect(malformed.exitCode, 64);
    expect('${malformed.stderr}', contains('invalid byte size: nope'));
    expect(zero.exitCode, 64);
    expect('${zero.stderr}', contains('samples must be positive'));
    expect(escaped.exitCode, 64);
    expect('${escaped.stderr}', contains('must stay inside packages/map_core'));
  });
}

Future<File> _temporaryOutput(String prefix) async {
  await Directory('build/test').create(recursive: true);
  final directory = await Directory('build/test').createTemp('${prefix}_cli_');
  addTearDown(() => directory.delete(recursive: true));
  return File('${directory.path}/result.json');
}

Future<ProcessResult> _run(List<String> arguments) => Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'benchmark/json_roundtrip_scaling.dart', ...arguments],
      workingDirectory: Directory.current.path,
    );
~~~~

## `packages/map_gameplay/benchmark/world_collision_scaling.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_gameplay/src/collision/world_collision_storage.dart';
import 'package:map_gameplay/src/gameplay_world_state.dart'
    show GameplayWorldStateCollisionStorageDiagnostics;

import '../../../tool/performance/benchmark_support.dart'
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
~~~~

## `packages/map_gameplay/test/benchmark/world_collision_scaling_cli_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('child mode emits a fingerprinted no-mask result', () async {
    final result = await _run(const <String>[
      '--child',
      'true',
      '--warmups',
      '0',
      '--samples',
      '1',
      '--sizes',
      '8',
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode('${result.stdout}'.trim()) as Map<String, Object?>;
    final measured =
        (payload['results']! as List<Object?>).single as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(measured['generatorVersion'], 1);
    expect(measured['datasetFingerprint'], isNotEmpty);
    expect(measured['allocatedPixelMaskChunks'], 0);
    expect(
      (measured['queries1000']! as Map<String, Object?>)['resultChecksum'],
      isNotEmpty,
    );
    final maskMeasured = (payload['maskResults']! as List<Object?>).single
        as Map<String, Object?>;
    expect(maskMeasured['allocatedPixelMaskChunks'], 4);
    expect(
      (maskMeasured['queries']! as Map<String, Object?>)['resultChecksum'],
      isNotEmpty,
    );
  });

  test('rejects a zero isolated run count and output escape', () async {
    final invalidRuns = await _run(const <String>[
      '--sizes',
      '8',
      '--isolated-size',
      '16',
      '--isolated-runs',
      '0',
      '--output',
      'build/test/world-collision.json',
    ]);
    final escaped = await _run(const <String>[
      '--sizes',
      '8',
      '--output',
      '../world-collision-escape.json',
    ]);

    expect(invalidRuns.exitCode, 64);
    expect('${invalidRuns.stderr}', contains('isolated-runs must be positive'));
    expect(escaped.exitCode, 64);
    expect(
      '${escaped.stderr}',
      contains('must stay inside packages/map_gameplay'),
    );
  });
}

Future<ProcessResult> _run(List<String> arguments) {
  return Process.run(
    Platform.resolvedExecutable,
    <String>['run', 'benchmark/world_collision_scaling.dart', ...arguments],
    workingDirectory: Directory.current.path,
  );
}
~~~~

## `packages/map_authoring/benchmark/authoring_snapshot_open.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

import '../../../tool/performance/benchmark_support.dart';

const _knownFixtures = <String>{
  'small',
  'intermediate',
  'selbrume',
  'synthetic-10mb',
};

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{
        'warmups',
        'samples',
        'fixtures',
        'roots',
        'cycles',
        'output',
      },
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 2);
    final samples = cli.positiveInt('samples', fallback: 15);
    final cycles = cli.positiveInt('cycles', fallback: 10);
    final fixtures = cli.strings(
      'fixtures',
      fallback: 'small,intermediate,selbrume,synthetic-10mb',
    );
    if (fixtures.isEmpty) {
      throw const FormatException('fixtures must not be empty');
    }
    for (final fixture in fixtures) {
      if (fixture == 'promotion_checkpoint') {
        throw const FormatException(
          'snapshot benchmark forbids promotion_checkpoint: its missing '
          'resource makes it JSON/validation-only',
        );
      }
      if (!_knownFixtures.contains(fixture)) {
        throw FormatException('unknown fixture: $fixture');
      }
    }
    final rootCounts = cli.positiveInts(
      'roots',
      fallback: '1,3,10',
      singularLabel: 'root count',
    );
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_authoring');
    final results = <Map<String, Object?>>[];

    for (final fixtureName in fixtures) {
      final fixture = await _resolveFixture(fixtureName);
      final fingerprint = await _fixtureFingerprint(fixture);
      for (final rootCount in rootCounts) {
        final roots = await _allowedRoots(fixture, rootCount);
        for (var index = 0; index < warmups; index += 1) {
          await _measure(fixture, roots, cycles);
        }
        final measured = <({int elapsedUs, String checksum, int maps})>[];
        for (var index = 0; index < samples; index += 1) {
          measured.add(await _measure(fixture, roots, cycles));
        }
        final checksum = measured.first.checksum;
        if (measured.any((sample) => sample.checksum != checksum)) {
          throw StateError(
            'Unstable snapshot for $fixtureName with $rootCount roots.',
          );
        }
        results.add(<String, Object?>{
          'fixture': fixtureName,
          'fixturePath': _repositoryRelativePath(fixture),
          'rootCount': rootCount,
          'cyclesPerSample': cycles,
          'mapCount': measured.first.maps,
          'datasetFingerprint': fingerprint,
          'snapshotChecksum': checksum,
          'rssBytesAfterSamples': ProcessInfo.currentRss,
          ...percentileFields(
            measured.map((sample) => sample.elapsedUs).toList(growable: false),
          ),
        });
      }
    }

    final receipt = await performanceReceipt(
      benchmark: 'authoring_snapshot_open',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>[
        'benchmark/authoring_snapshot_open.dart',
        ...arguments,
      ],
      metadata: <String, Object?>{
        'fixtures': fixtures,
        'rootCounts': rootCounts,
        'cycles': cycles,
        'snapshotPolicy': ProjectSnapshotLoadPolicy.strict.name,
      },
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_authoring',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('authoring_snapshot_open: ${error.message}');
    exitCode = 64;
  }
}

// Exercise the production policy, handle store, open service and strict
// snapshot loader. A JSON-only parse would under-report authoring open cost.
Future<({int elapsedUs, String checksum, int maps})> _measure(
  Directory fixture,
  List<String> allowedRoots,
  int cycles,
) async {
  var token = 0;
  var mapCount = 0;
  final revisions = <String>[];
  const reader = LocalProjectFileReader();
  final stopwatch = Stopwatch()..start();
  for (var cycle = 0; cycle < cycles; cycle += 1) {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: allowedRoots,
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      clock: () => DateTime.utc(2026, 8, 1),
      tokenFactory: (prefix) => '$prefix${token++}',
    );
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(fixture.path);
    final snapshot = await ProjectSnapshotLoader(handles: handles).load(
      opened.projectHandle,
      policy: ProjectSnapshotLoadPolicy.strict,
    );
    mapCount += snapshot.maps.length;
    revisions.add(snapshot.revision);
  }
  stopwatch.stop();
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(revisions),
    maps: mapCount ~/ cycles,
  );
}

Future<Directory> _resolveFixture(String name) async {
  final repository = Directory.current.parent.parent;
  switch (name) {
    case 'small':
      return Directory(
        '${repository.path}/examples/playable_runtime_host/golden_battle_slice',
      );
    case 'intermediate':
      return Directory(
        '${repository.path}/examples/playable_runtime_host/golden_fangame_slice',
      );
    case 'selbrume':
      return Directory(
        '${repository.path}/examples/playable_runtime_host/'
        'event_builder_v2_selbrume_slice',
      );
    case 'synthetic-10mb':
      return _syntheticFixture();
  }
  throw FormatException('unknown fixture: $name');
}

Future<Directory> _syntheticFixture() async {
  final directory = Directory('build/performance/fixtures/synthetic-10mb');
  await directory.create(recursive: true);
  final project = File('${directory.path}/project.json');
  const targetBytes = 10 * 1024 * 1024;
  if (!await project.exists() || await project.length() < targetBytes) {
    const prefix = '{"name":"Synthetic 10 MiB","version":"v3","maps":[],'
        '"tilesets":[],"globalProperties":{"payload":"';
    const suffix = '"}}';
    final payloadLength = targetBytes - utf8.encode(prefix + suffix).length;
    final sink = project.openWrite();
    sink.write(prefix);
    const block = '0123456789abcdef';
    var remaining = payloadLength;
    while (remaining > 0) {
      final count = remaining.clamp(0, block.length);
      sink.write(block.substring(0, count));
      remaining -= count;
    }
    sink.write(suffix);
    await sink.close();
  }
  return Directory(directory.resolveSymbolicLinksSync());
}

Future<List<String>> _allowedRoots(Directory fixture, int count) async {
  final roots = <String>[fixture.parent.resolveSymbolicLinksSync()];
  final dummyRoot = Directory('build/performance/roots');
  await dummyRoot.create(recursive: true);
  for (var index = 1; index < count; index += 1) {
    final root = Directory('${dummyRoot.path}/root-$index');
    await root.create(recursive: true);
    roots.add(root.resolveSymbolicLinksSync());
  }
  return List<String>.unmodifiable(roots);
}

Future<String> _fixtureFingerprint(Directory fixture) async {
  final files = <File>[];
  await for (final entity
      in fixture.list(recursive: true, followLinks: false)) {
    if (entity is File) files.add(entity);
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  final entries = <Map<String, Object?>>[];
  for (final file in files) {
    entries.add(<String, Object?>{
      'path': file.path.substring(fixture.path.length + 1),
      'bytes': await file.length(),
      'content': stableBytesFingerprint(await file.readAsBytes()),
    });
  }
  return stableFingerprint(entries);
}

String _repositoryRelativePath(Directory fixture) {
  final repository = Directory.current.parent.parent.absolute.path;
  final absolute = fixture.absolute.path;
  return absolute.startsWith('$repository/')
      ? absolute.substring(repository.length + 1)
      : 'generated:${fixture.uri.pathSegments.lastWhere((part) => part.isNotEmpty)}';
}
~~~~

## `packages/map_authoring/test/benchmark/authoring_snapshot_open_cli_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('opens a deterministic synthetic authoring snapshot', () async {
    final output = await _temporaryOutput('authoring_snapshot');
    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--fixtures',
      'small',
      '--roots',
      '1,3',
      '--cycles',
      '1',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'authoring_snapshot_open');
    final rows =
        (payload['results']! as List<Object?>).cast<Map<String, Object?>>();
    expect(rows.map((row) => row['rootCount']), <Object?>[1, 3]);
    expect(rows.every((row) => row['fixture'] == 'small'), isTrue);
    expect(
        rows.every((row) => '${row['snapshotChecksum']}'.isNotEmpty), isTrue);
  });

  test('rejects promotion checkpoint, zero samples, and escaped output',
      () async {
    final forbidden = await _run(const <String>[
      '--fixtures',
      'promotion_checkpoint',
      '--output',
      'build/test/promotion.json',
    ]);
    final zero = await _run(const <String>[
      '--samples',
      '0',
      '--output',
      'build/test/authoring-zero.json',
    ]);
    final escaped = await _run(const <String>[
      '--output',
      '../authoring-escape.json',
    ]);

    expect(forbidden.exitCode, 64);
    expect('${forbidden.stderr}', contains('snapshot benchmark forbids'));
    expect(zero.exitCode, 64);
    expect('${zero.stderr}', contains('samples must be positive'));
    expect(escaped.exitCode, 64);
    expect('${escaped.stderr}',
        contains('must stay inside packages/map_authoring'));
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<File> _temporaryOutput(String prefix) async {
  await Directory('build/test').create(recursive: true);
  final directory = await Directory('build/test').createTemp('${prefix}_cli_');
  addTearDown(() => directory.delete(recursive: true));
  return File('${directory.path}/result.json');
}

Future<ProcessResult> _run(List<String> arguments) => Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'benchmark/authoring_snapshot_open.dart', ...arguments],
      workingDirectory: Directory.current.path,
    );
~~~~

## `packages/map_battle/benchmark/battle_turn_baseline.dart`

~~~~dart
import 'dart:io';

import 'package:map_battle/map_battle.dart';

import '../../../tool/performance/benchmark_support.dart';

const _fixtureDescriptor = <String, Object?>{
  'kind': 'deterministic-singles-independent-turn',
  'player': <String, Object?>{
    'species': 'charmander',
    'hp': 44,
    'speed': 65,
    'move': 'scratch',
    'power': 180,
  },
  'opponent': <String, Object?>{
    'species': 'bulbasaur',
    'hp': 18,
    'speed': 45,
    'move': 'scratch',
    'power': 20,
  },
  'rngSeeds': <int>[1, 2, 3, 4],
};

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{'warmups', 'samples', 'turns', 'output'},
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 5);
    final samples = cli.positiveInt('samples', fallback: 30);
    final turns = cli.positiveInts(
      'turns',
      fallback: '100,500,1000,2000,5000',
      singularLabel: 'turn count',
    );
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_battle');
    final fixtureFingerprint = stableFingerprint(_fixtureDescriptor);
    final setup = _setup();
    final results = <Map<String, Object?>>[];

    for (final turnCount in turns) {
      for (var index = 0; index < warmups; index += 1) {
        _measure(setup, turnCount);
      }
      final measured = <({int elapsedUs, String checksum, int events})>[
        for (var index = 0; index < samples; index += 1)
          _measure(setup, turnCount),
      ];
      final checksum = measured.first.checksum;
      if (measured.any((sample) => sample.checksum != checksum)) {
        throw StateError('Unstable battle result for $turnCount turns.');
      }
      results.add(<String, Object?>{
        'turnCount': turnCount,
        'turnSemantics': 'independent-engine-submit',
        'datasetFingerprint': fixtureFingerprint,
        'battleChecksum': checksum,
        'timelineEventCount': measured.first.events,
        'rssBytesAfterSamples': ProcessInfo.currentRss,
        ...percentileFields(
          measured.map((sample) => sample.elapsedUs).toList(growable: false),
        ),
      });
    }

    final receipt = await performanceReceipt(
      benchmark: 'battle_turn_baseline',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>['benchmark/battle_turn_baseline.dart', ...arguments],
      metadata: <String, Object?>{
        'turnCounts': turns,
        'fixtureFingerprint': fixtureFingerprint,
      },
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_battle',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('battle_turn_baseline: ${error.message}');
    exitCode = 64;
  }
}

// Each submission starts from the same deterministic setup. This measures the
// engine's turn path without letting a terminal battle shorten later samples.
({int elapsedUs, String checksum, int events}) _measure(
  PsdkBattleSetup setup,
  int turns,
) {
  var eventCount = 0;
  final stopwatch = Stopwatch()..start();
  for (var index = 0; index < turns; index += 1) {
    final result = BattleEngine(setup: BattleEngineSetup.fromPsdk(setup))
        .submit(const BattleDecision.fight(moveSlot: 0));
    eventCount += result.timeline.events.length;
  }
  stopwatch.stop();
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(<Object?>[turns, eventCount]),
    events: eventCount,
  );
}

PsdkBattleSetup _setup() => PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player-charmander',
        speciesId: 'charmander',
        speed: 65,
        hp: 44,
        movePower: 180,
      ),
      opponent: _combatant(
        id: 'opponent-bulbasaur',
        speciesId: 'bulbasaur',
        speed: 45,
        hp: 18,
        movePower: 20,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      ),
    );

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String speciesId,
  required int speed,
  required int hp,
  required int movePower,
}) =>
    PsdkBattleCombatantSetup(
      id: id,
      speciesId: speciesId,
      displayName: speciesId,
      level: 10,
      maxHp: hp,
      currentHp: hp,
      types: const PsdkBattleTypes(primary: 'normal'),
      stats: PsdkBattleStats(
        attack: 64,
        defense: 49,
        specialAttack: 60,
        specialDefense: 50,
        speed: speed,
      ),
      moves: <PsdkBattleMoveData>[_move(movePower)],
    );

PsdkBattleMoveData _move(int power) => PsdkBattleMoveData(
      id: 'scratch',
      dbSymbol: 'scratch',
      name: 'Scratch',
      type: 'normal',
      category: PsdkBattleMoveCategory.physical,
      power: power,
      accuracy: 100,
      pp: 35,
      priority: 0,
      battleEngineMethod: 's_basic',
      target: PsdkBattleMoveTarget.adjacentFoe,
    );
~~~~

## `packages/map_battle/test/benchmark/battle_turn_baseline_cli_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes deterministic battle turn percentile evidence', () async {
    final output = await _temporaryOutput('battle_turn');
    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--turns',
      '2,5',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'battle_turn_baseline');
    final rows =
        (payload['results']! as List<Object?>).cast<Map<String, Object?>>();
    expect(rows.map((row) => row['turnCount']), <Object?>[2, 5]);
    expect(
        rows.every((row) => '${row['datasetFingerprint']}'.isNotEmpty), isTrue);
    expect(rows.every((row) => '${row['battleChecksum']}'.isNotEmpty), isTrue);
  });

  test('rejects malformed turn counts, zero samples, and escaped output',
      () async {
    final malformed = await _run(const <String>[
      '--turns',
      '100,bad',
      '--output',
      'build/test/battle-malformed.json',
    ]);
    final zero = await _run(const <String>[
      '--samples',
      '0',
      '--output',
      'build/test/battle-zero.json',
    ]);
    final escaped = await _run(const <String>[
      '--output',
      '../battle-escape.json',
    ]);

    expect(malformed.exitCode, 64);
    expect('${malformed.stderr}', contains('invalid turn count: bad'));
    expect(zero.exitCode, 64);
    expect('${zero.stderr}', contains('samples must be positive'));
    expect(escaped.exitCode, 64);
    expect(
        '${escaped.stderr}', contains('must stay inside packages/map_battle'));
  });
}

Future<File> _temporaryOutput(String prefix) async {
  await Directory('build/test').create(recursive: true);
  final directory = await Directory('build/test').createTemp('${prefix}_cli_');
  addTearDown(() => directory.delete(recursive: true));
  return File('${directory.path}/result.json');
}

Future<ProcessResult> _run(List<String> arguments) => Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'benchmark/battle_turn_baseline.dart', ...arguments],
      workingDirectory: Directory.current.path,
    );
~~~~

## `packages/map_editor/integration_test/editor_project_journey_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/main.dart' show MapEditorApp;
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profiles a real open-paint-undo-save editor journey', (
    tester,
  ) async {
    final fixture = await _EditorPerformanceFixture.create();
    addTearDown(fixture.dispose);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final timings = <FrameTiming>[];
    void captureTimings(List<FrameTiming> batch) => timings.addAll(batch);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MapEditorApp(),
      ),
    );
    for (var index = 0; index < 3; index += 1) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // FrameTiming.totalSpan is captured directly. Build+raster is not a valid
    // substitute because those pipeline phases can overlap.
    SchedulerBinding.instance.addTimingsCallback(captureTimings);
    addTearDown(
      () => SchedulerBinding.instance.removeTimingsCallback(captureTimings),
    );

    final phases = <Map<String, Object?>>[];
    phases.add(await _measure('project-open', () async {
      await notifier.loadProject(
        fixture.manifestPath,
        rememberAsRecent: false,
      );
      await tester.pump(const Duration(milliseconds: 16));
    }));
    expect(notifier.state.project?.name, 'RM-00 editor profile');

    phases.add(await _measure('map-open', () async {
      await notifier.loadMap('maps/performance.json');
      await tester.pump(const Duration(milliseconds: 16));
    }));
    expect(notifier.state.activeMap?.id, 'performance');

    phases.add(await _measure('collision-paint-100', () async {
      notifier.setActiveLayer('collision');
      notifier.selectTool(EditorToolType.collisionPaint);
      notifier.beginMapStroke();
      for (var index = 0; index < 100; index += 1) {
        notifier.paintCollisionAt(
          GridPos(x: index % 64, y: (index * 7) % 64),
        );
        if (index % 10 == 9) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      notifier.endMapStroke();
      await tester.pump(const Duration(milliseconds: 16));
    }));
    expect(notifier.state.isDirty, isTrue);

    phases.add(await _measure('undo', () async {
      notifier.undoMap();
      await tester.pump(const Duration(milliseconds: 16));
    }));

    phases.add(await _measure('post-undo-paint', () async {
      notifier.beginMapStroke();
      notifier.paintCollisionAt(const GridPos(x: 63, y: 63));
      notifier.endMapStroke();
      await tester.pump(const Duration(milliseconds: 16));
    }));

    phases.add(await _measure('save', () async {
      final outcome = await notifier.saveActiveMap();
      expect(outcome.name, 'saved');
      await tester.pump(const Duration(milliseconds: 16));
    }));
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    SchedulerBinding.instance.removeTimingsCallback(captureTimings);
    final frameMetrics = _frameMetrics(timings);
    expect(frameMetrics['frameCount'], greaterThan(0));
    expect(tester.takeException(), isNull);

    binding.reportData = <String, dynamic>{
      'schemaVersion': 2,
      'generatorVersion': 1,
      'benchmark': 'editor_project_journey',
      'requestedOutputPath': _requestedOutputPath,
      'executionMode': const bool.fromEnvironment('dart.vm.profile')
          ? 'flutter-profile'
          : 'flutter-debug',
      'fixture': 'synthetic-collision-64x64',
      'fixtureFingerprint': fixture.fingerprint,
      'warmups': 3,
      'sampleCount': timings.length,
      'iterations': <String, Object?>{
        'projectOpen': 1,
        'mapOpen': 1,
        'collisionPaint': 100,
        'undo': 1,
        'postUndoPaint': 1,
        'save': 1,
      },
      'measurementScope': <String, Object?>{
        'flutterFrames': true,
        'pureCorePaint': false,
        'buildAndRasterCombined': false,
        // Profile mode does not expose debug rebuild callbacks. Null plus an
        // availability reason is intentional; missing evidence is never zero.
        'rebuildCount': null,
        'rebuildCountAvailability':
            'Flutter profile mode does not expose debug rebuild callbacks',
      },
      'memory': <String, Object?>{
        'rssBytes': ProcessInfo.currentRss,
        'heapBytes': null,
        'heapAvailability': 'not exposed by dart:io',
      },
      'results': phases,
      'frameMetrics': frameMetrics,
      'thresholdPolicy': <String, Object?>{
        'observationOnly': true,
        'minimumHistoricalObservations': 10,
        'requiredConsecutiveRegressions': 2,
      },
    };
  });
}

Future<Map<String, Object?>> _measure(
  String phase,
  Future<void> Function() action,
) async {
  final stopwatch = Stopwatch()..start();
  await action();
  stopwatch.stop();
  return <String, Object?>{
    'phase': phase,
    'durationUs': stopwatch.elapsedMicroseconds,
    'rssBytesAfterPhase': ProcessInfo.currentRss,
  };
}

Map<String, Object?> _frameMetrics(List<FrameTiming> timings) {
  final build = timings
      .map((timing) => timing.buildDuration.inMicroseconds)
      .toList(growable: false);
  final raster = timings
      .map((timing) => timing.rasterDuration.inMicroseconds)
      .toList(growable: false);
  final spans = timings
      .map((timing) => timing.totalSpan.inMicroseconds)
      .toList(growable: false);
  final sortedBuild = List<int>.of(build)..sort();
  final sortedRaster = List<int>.of(raster)..sort();
  final sortedSpans = List<int>.of(spans)..sort();
  final over16 = spans.where((value) => value > 16670).length;
  final over33 = spans.where((value) => value > 33300).length;
  return <String, Object?>{
    'frameCount': timings.length,
    'buildSamplesMicroseconds': build,
    'rasterSamplesMicroseconds': raster,
    'frameSpanSamplesMicroseconds': spans,
    'buildP50Us': _percentile(sortedBuild, 0.50),
    'buildP95Us': _percentile(sortedBuild, 0.95),
    'buildP99Us': _percentile(sortedBuild, 0.99),
    'rasterP50Us': _percentile(sortedRaster, 0.50),
    'rasterP95Us': _percentile(sortedRaster, 0.95),
    'rasterP99Us': _percentile(sortedRaster, 0.99),
    'frameSpanP50Us': _percentile(sortedSpans, 0.50),
    'frameSpanP95Us': _percentile(sortedSpans, 0.95),
    'frameSpanP99Us': _percentile(sortedSpans, 0.99),
    'framesOver16Point67Milliseconds': over16,
    'framesOver16Point67Rate': timings.isEmpty ? 0 : over16 / timings.length,
    'framesOver33Point3Milliseconds': over33,
    'framesOver33Point3Rate': timings.isEmpty ? 0 : over33 / timings.length,
  };
}

int _percentile(List<int> sorted, double percentile) {
  if (sorted.isEmpty) return 0;
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

final class _EditorPerformanceFixture {
  const _EditorPerformanceFixture({
    required this.root,
    required this.manifestPath,
    required this.fingerprint,
  });

  final Directory root;
  final String manifestPath;
  final String fingerprint;

  static Future<_EditorPerformanceFixture> create() async {
    final root = await Directory.systemTemp.createTemp('pokemap-rm00-editor-');
    final manifestPath = p.join(root.path, 'project.json');
    final mapPath = p.join(root.path, 'maps', 'performance.json');
    const manifest = ProjectManifest(
      name: 'RM-00 editor profile',
      version: ProjectVersion.v3,
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'performance',
          name: 'Performance',
          relativePath: 'maps/performance.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
    );
    final map = MapData(
      id: 'performance',
      name: 'Performance',
      size: const GridSize(width: 64, height: 64),
      layers: <MapLayer>[
        CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.filled(64 * 64, false),
        ),
      ],
    );
    await FileProjectRepository().saveProject(manifest, manifestPath);
    await FileMapRepository().saveMap(
      map,
      mapPath,
      projectDialogueContext: manifest,
    );
    return _EditorPerformanceFixture(
      root: root,
      manifestPath: manifestPath,
      fingerprint: sha256
          .convert(utf8.encode(jsonEncode(<String, Object?>{
            'project': manifest.toJson(),
            'map': map.toJson(),
          })))
          .toString(),
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}
~~~~

## `packages/map_editor/test_driver/performance_driver.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      if (data == null || data['schemaVersion'] != 2) {
        throw const FormatException(
          'Editor performance response must use schema V2.',
        );
      }
      final requestedOutput = data['requestedOutputPath'];
      if (requestedOutput is! String || requestedOutput.trim().isEmpty) {
        throw const FormatException('POKEMAP_PERF_OUTPUT is required.');
      }
      final output = _validatedOutput(requestedOutput);
      final repositoryRoot = await _git(<String>[
        'rev-parse',
        '--show-toplevel',
      ]);
      final status = await _git(
        <String>['status', '--porcelain=v1'],
        workingDirectory: repositoryRoot,
      );
      final diff = await _git(
        <String>['diff', '--binary', 'HEAD'],
        workingDirectory: repositoryRoot,
      );
      final untracked = await _git(<String>[
        'ls-files',
        '--others',
        '--exclude-standard',
      ], workingDirectory: repositoryRoot);
      final receipt = <String, Object?>{
        ...data,
        'commit': await _git(
          <String>['rev-parse', 'HEAD'],
          workingDirectory: repositoryRoot,
        ),
        'treeState': status.isEmpty ? 'clean' : 'dirty',
        'sdk': Platform.version,
        'treeFingerprint': await _sourceTreeFingerprint(
          repositoryRoot: repositoryRoot,
          status: status,
          diff: diff,
          untracked: untracked,
        ),
        'os': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'architecture': _architectureLabel(),
        'toolchain': <String, Object?>{
          'dart': Platform.version,
          'flutter': await _flutterMetadata(),
          'flame': await _flameVersion(),
        },
        'command': <String>[
          'flutter',
          'drive',
          '--profile',
          '-d',
          'macos',
          '--driver=test_driver/performance_driver.dart',
          '--target=integration_test/editor_project_journey_test.dart',
          '--dart-define=POKEMAP_PERF_OUTPUT=$requestedOutput',
        ],
      };
      await output.parent.create(recursive: true);
      final temporary = File('${output.path}.tmp-$pid');
      await temporary.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(receipt)}\n',
        flush: true,
      );
      if (await output.exists()) await output.delete();
      await temporary.rename(output.path);
      stdout.writeln(jsonEncode(receipt));
    },
  );
}

File _validatedOutput(String relativePath) {
  final packageRoot = Directory(Directory.current.resolveSymbolicLinksSync());
  if (p.isAbsolute(relativePath)) {
    throw const FormatException(
      'POKEMAP_PERF_OUTPUT must stay inside packages/map_editor.',
    );
  }
  final output = File(
    p.normalize(p.join(packageRoot.path, relativePath)),
  ).absolute;
  if (!p.isWithin(packageRoot.path, output.path)) {
    throw const FormatException(
      'POKEMAP_PERF_OUTPUT must stay inside packages/map_editor.',
    );
  }
  return output;
}

Future<String> _git(
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
  );
  return result.exitCode == 0 ? '${result.stdout}'.trim() : 'unavailable';
}

// Run Git from the repository root and hash untracked contents. The driver is
// itself untracked during this lot, so path-only fingerprints would be false.
Future<String> _sourceTreeFingerprint({
  required String repositoryRoot,
  required String status,
  required String diff,
  required String untracked,
}) async {
  final entries = <Map<String, Object?>>[];
  final paths = untracked
      .split('\n')
      .where((path) => path.trim().isNotEmpty)
      .toList(growable: false)
    ..sort();
  for (final relativePath in paths) {
    final file = File(p.join(repositoryRoot, relativePath));
    try {
      final bytes = await file.readAsBytes();
      entries.add(<String, Object?>{
        'path': relativePath,
        'bytes': bytes.length,
        'content': sha256.convert(bytes).toString(),
      });
    } on FileSystemException {
      entries.add(<String, Object?>{
        'path': relativePath,
        'content': 'unavailable',
      });
    }
  }
  return sha256
      .convert(
        utf8.encode(
          jsonEncode(<String, Object?>{
            'status': status,
            'diff': diff,
            'untracked': entries,
          }),
        ),
      )
      .toString();
}

Future<Map<String, Object?>> _flutterMetadata() async {
  final result = await Process.run(
    'flutter',
    <String>['--version', '--machine'],
  );
  if (result.exitCode != 0) {
    return const <String, Object?>{'status': 'unavailable'};
  }
  final decoded = jsonDecode('${result.stdout}');
  return decoded is Map
      ? Map<String, Object?>.from(decoded)
      : const <String, Object?>{'status': 'malformed'};
}

Future<String> _flameVersion() async {
  final lock = File('pubspec.lock');
  if (!await lock.exists()) return 'unavailable';
  final lines = (await lock.readAsLines());
  final start = lines.indexWhere((line) => line == '  flame:');
  if (start < 0) return 'unavailable';
  for (final line in lines.skip(start + 1)) {
    if (!line.startsWith('    ')) break;
    final trimmed = line.trim();
    if (trimmed.startsWith('version: ')) {
      return trimmed.substring('version: '.length).replaceAll('"', '');
    }
  }
  return 'unavailable';
}

String _architectureLabel() {
  final executable = Platform.resolvedExecutable.toLowerCase();
  if (executable.contains('arm64') || executable.contains('aarch64')) {
    return 'arm64';
  }
  if (executable.contains('x64') || executable.contains('x86_64')) {
    return 'x64';
  }
  return Platform.version.contains('arm64') ? 'arm64' : 'unknown';
}
~~~~

## `reports/performance/plans/2026-08-01-pokemap-perf-rm-00-observability.md`

~~~~markdown
# PERF-RM-00 — Observability and comparable baselines implementation plan

> **For Codex:** execute this plan package by package with the repository's
> `executing-plans`, `test-driven-development`, and
> `verification-before-completion` workflows. Git write operations, worktrees,
> and commits are deliberately omitted because they are not authorized for this
> workspace.

**Goal:** establish a deterministic, versioned and non-blocking performance
observation layer for PokeMap before the remaining remediation phases continue.

**Architecture:** pure-Dart harnesses measure one operation at a time and emit a
shared JSON V2 envelope; Flutter profile journeys report frame timings without
mixing build and raster durations. CI only collects and uploads receipts. Local
three-run baselines remain evidence, not release gates.

**Tech stack:** Dart AOT executables, Flutter profile/driver integration,
`package:test`, `flutter_test`, GitHub Actions.

---

## Scope and acceptance contract

- Preserve and validate the existing `surface_role_scaling` and
  `world_collision_scaling` harnesses introduced by Phase 1.
- Add isolated AOT harnesses for map paint gestures, group hierarchy
  validation, JSON round trips, authoring snapshot open, and battle turns.
- Every pure-Dart receipt uses schema V2 metadata, explicit warmups/sample
  counts, fixture fingerprints, raw samples, and p50/p95/p99 values.
- Invalid fixtures, zero samples, malformed arguments, and output paths outside
  the package root fail explicitly.
- Extend runtime frame collection with build/raster distributions kept
  separate, plus frame-budget exceedance counts and rates.
- Add a macOS editor profile journey and a driver that writes a versioned JSON
  receipt to the explicitly configured package-local output path.
- Extend `pokemap_eval run` with versioned multi-run profile output while
  preserving existing CLI behavior.
- Add one non-blocking CI observation job with an explicit test manifest and
  uploaded artifacts; no performance threshold can fail the workflow.
- Capture three comparable local baseline runs when the host supports the
  relevant execution mode. Never compare JIT/debug values with AOT/profile.

## Task 1: Lock the JSON and percentile contracts with tests

**Files:**

- Create: `packages/map_core/test/benchmark/map_paint_gesture_cli_test.dart`
- Create: `packages/map_core/test/benchmark/group_hierarchy_scaling_cli_test.dart`
- Create: `packages/map_core/test/benchmark/json_roundtrip_scaling_cli_test.dart`
- Create: `packages/map_authoring/test/benchmark/authoring_snapshot_open_cli_test.dart`
- Create: `packages/map_battle/test/benchmark/battle_turn_baseline_cli_test.dart`
- Modify: `examples/playable_runtime_host/test/evaluation/interactive_frame_metrics_test.dart`
- Modify: `examples/playable_runtime_host/test/evaluation/pokemap_eval_cli_test.dart`

1. Add RED tests for valid V2 receipts and deterministic checksums/fingerprints.
2. Add RED tests for zero samples, unknown fixtures, malformed inputs, output
   escapes, zero-frame snapshots, unsorted frame data, and unknown schemas.
3. Run each focused test from its owning package and retain the failure signal.

## Task 2: Implement pure-Dart AOT harnesses

**Files:**

- Create: `packages/map_core/benchmark/map_paint_gesture.dart`
- Create: `packages/map_core/benchmark/group_hierarchy_scaling.dart`
- Create: `packages/map_core/benchmark/json_roundtrip_scaling.dart`
- Create: `packages/map_authoring/benchmark/authoring_snapshot_open.dart`
- Create: `packages/map_battle/benchmark/battle_turn_baseline.dart`

1. Parse only the documented command-line options.
2. Validate inputs before warmup or measurement.
3. Build deterministic synthetic/canonical fixtures and fingerprint their
   serialized input.
4. Run warmups outside the measured samples.
5. Record raw microsecond samples and nearest-rank p50/p95/p99.
6. Write atomically to a package-local output path and print the receipt.
7. Keep benchmark code outside public package barrels.

## Task 3: Upgrade runtime frame observability

**Files:**

- Modify: `examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_frame_metrics.dart`
- Modify: `examples/playable_runtime_host/test/evaluation/interactive/interactive_frame_metrics_test.dart`

1. Store individual build and raster durations during a recording window.
2. Report separate p50/p95/p99 distributions and max/average values.
3. Report frames over 16.67 ms and 33.3 ms as counts and rates, using total
   frame span without adding build and raster phases together.
4. Preserve the existing JSON fields for compatibility.
5. Reject unknown receipt schemas in the parsing/validation seam.

## Task 4: Add versioned runtime and editor profile journeys

**Files:**

- Modify: `examples/playable_runtime_host/tool/pokemap_eval.dart`
- Modify: `examples/playable_runtime_host/tool/src/pokemap_eval_cli.dart`
- Modify: `examples/playable_runtime_host/test/evaluation/pokemap_eval_cli_test.dart`
- Modify: `packages/map_editor/pubspec.yaml`
- Create: `packages/map_editor/integration_test/editor_project_journey_test.dart`
- Create: `packages/map_editor/test_driver/performance_driver.dart`

1. Add `--build-mode`, `--runs`, and `--json-output` to `pokemap_eval run`.
2. Require `profile` for performance receipts and aggregate repeated run frame
   metrics without changing ordinary evaluation receipts.
3. Make the editor journey execute open/select/paint/undo/save-equivalent UI
   work with stable keys already exposed by the application; if a production
   seam is unavailable, use the narrowest test-only journey and state it.
4. Write editor timings and rebuild/frame data as schema V2 JSON under the
   configured package-local output.

## Task 5: Add non-blocking CI observation

**Files:**

- Modify: `.github/workflows/pokemap_hub_product_certification.yml`

1. Add a dedicated performance-observation job with `continue-on-error: true`.
2. Compile/run an explicit, bounded AOT harness manifest.
3. Run only explicitly named editor performance tests; remove the global tag
   sweep from this lane.
4. Upload JSON receipts with `if: always()`.
5. Do not introduce threshold assertions or required-job dependencies.

## Task 6: Capture comparable local evidence

**Files:**

- Create under ignored build output:
  `*/build/performance/baseline/run-{1,2,3}/*.json`

1. Record commit, dirty-tree fingerprint, toolchain, OS, architecture, fixture
   fingerprint, execution mode, and command line in every run.
2. Compile the pure-Dart harnesses once per owning package, then execute three
   isolated runs with identical arguments.
3. Run runtime/editor profile journeys three times when the desktop/profile
   environment is available; otherwise record the exact blocker and do not
   substitute debug mode.
4. Validate all receipts against V2 invariants and compare fingerprints/modes.

## Task 7: Verification and Evidence Pack

**Files:**

- Create: `reports/performance/perf_rm_00_observability.md`

1. Run formatter, focused tests, package analyzers, AOT compilation, and the
   relevant macOS profile/build checks.
2. Execute separate named passes: Audit/Architecture, Implementation, Tests,
   Build/Validation, and Final Critique.
3. Record initial/final Git status, file inventory, precise changed zones,
   commands and exact results, full content of created files, risks, non-goals,
   and residual variance.
4. Propose `DONE` only if every required proof exists; otherwise use `PARTIAL`
   with explicit closure steps.
~~~~


