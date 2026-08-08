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
    'maxUs': sorted.last,
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
  final sourceIdentity = await currentPerformanceSourceIdentity();
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
    ...sourceIdentity,
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

Future<Map<String, Object?>> currentPerformanceSourceIdentity() async {
  final status = await _git(<String>['status', '--porcelain=v1']);
  return <String, Object?>{
    'commit': await _git(<String>['rev-parse', 'HEAD']),
    'treeState': status.isEmpty ? 'clean' : 'dirty',
    'treeFingerprint': await sourceTreeFingerprint(status: status),
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
