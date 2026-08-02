import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import '../../../tools/performance/benchmark_support.dart'
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
