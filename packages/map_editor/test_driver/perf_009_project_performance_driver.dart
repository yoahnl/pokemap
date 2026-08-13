import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

import 'performance_driver.dart' as legacy_driver;

const _projectTarget = 'integration_test/editor_project_journey_test.dart';
const _persistenceCounters = <String>{
  'filesystem.read',
  'filesystem.write',
  'filesystem.metadata',
  'json.encode',
  'json.decode',
  'base64.encode',
  'base64.decode',
};

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) {
        throw const FormatException('Editor performance response is missing.');
      }
      if (data['target'] != _projectTarget) {
        throw const FormatException(
          'PERF-009 project driver only accepts the editor project journey.',
        );
      }
      final requestedOutput = data['requestedOutputPath'];
      if (requestedOutput is! String || requestedOutput.trim().isEmpty) {
        throw const FormatException('POKEMAP_PERF_OUTPUT is required.');
      }
      final repositoryRoot = await _git(<String>['rev-parse', '--show-toplevel']);
      final status = await _git(
        <String>['status', '--porcelain=v1'],
        workingDirectory: repositoryRoot,
      );
      final receipt = <String, dynamic>{
        ...data,
        'commit': await _git(
          <String>['rev-parse', 'HEAD'],
          workingDirectory: repositoryRoot,
        ),
        'treeState': status.isEmpty ? 'clean' : 'dirty',
        'sdk': Platform.version,
        'treeFingerprint': await _git(
          <String>['rev-parse', 'HEAD^{tree}'],
          workingDirectory: repositoryRoot,
        ),
        'os': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'architecture': await _architectureLabel(),
        'toolchain': <String, Object?>{
          'dart': Platform.version,
          'flutter': <String, Object?>{
            'frameworkRevision': await _flutterFrameworkRevision(),
          },
          'flame': await _flameVersion(repositoryRoot),
        },
        'command': <String>[
          'flutter',
          'drive',
          '--profile',
          '-d',
          'macos',
          '--driver=test_driver/perf_009_project_performance_driver.dart',
          '--target=$_projectTarget',
          '--dart-define=POKEMAP_PERF_OUTPUT=$requestedOutput',
        ],
      };
      validatePerf009ProjectReceipt(receipt);
      final output = File(requestedOutput).absolute;
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

void validatePerf009ProjectPayload(Map<String, dynamic> data) {
  validatePerf009BufferedProjectPhases(data);
  legacy_driver.validatePerformancePayload(_normalizeForLegacyValidator(data));
}

void validatePerf009ProjectReceipt(Map<String, dynamic> data) {
  validatePerf009BufferedProjectPhases(data);
  legacy_driver.validatePerformanceResponse(_normalizeForLegacyValidator(data));
}

void validatePerf009BufferedProjectPhases(Map<String, dynamic> data) {
  if (data['target'] != _projectTarget) {
    throw const FormatException(
      'PERF-009 buffered project contract requires the editor project journey.',
    );
  }
  final results = data['results'];
  if (results is! List) {
    throw const FormatException('PERF-009 project results are missing.');
  }

  final tilePlacement = _singlePhase(results, 'tile-placement-90');
  _validateSpanCount(
    tilePlacement,
    spanName: 'mutation.local',
    expectedCount: 154,
  );
  _validateZeroPersistenceCounters(tilePlacement);

  for (final extent in const <int>[128, 256, 512, 1024]) {
    for (final strokeCount in const <int>[1, 10, 100, 1000]) {
      final phase = _singlePhase(
        results,
        'collision-paint-${extent}x$extent-$strokeCount',
      );
      _validateSpanCount(
        phase,
        spanName: 'mutation.local',
        expectedCount: strokeCount + 1,
      );
      _validateZeroPersistenceCounters(phase);
    }
  }

  final placement = _singlePhase(results, 'canonical-element-placement');
  _validateZeroPersistenceCounters(placement);
  for (final name in const <String>['snapshot', 'plan', 'apply']) {
    final metrics = _spanMetrics(placement, name);
    if (metrics['count'] != 0) {
      throw FormatException(
        'canonical-element-placement must keep $name outside the interactive phase.',
      );
    }
  }

  final publication = _singlePhase(results, 'canonical-element-publication');
  for (final name in const <String>['snapshot', 'plan', 'apply']) {
    final metrics = _spanMetrics(publication, name);
    final count = metrics['count'];
    if (count is! int || count <= 0) {
      throw FormatException(
        'canonical-element-publication must record at least one $name span.',
      );
    }
    _validateSampleMetrics(metrics, expectedCount: count);
  }
}

Map<String, dynamic> _normalizeForLegacyValidator(Map<String, dynamic> data) {
  final normalized = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  final results = normalized['results']! as List<dynamic>;

  final tilePlacement = _singlePhase(results, 'tile-placement-90');
  _truncateSpan(tilePlacement, 'mutation.local', 90);

  for (final extent in const <int>[128, 256, 512, 1024]) {
    for (final strokeCount in const <int>[1, 10, 100, 1000]) {
      final phase = _singlePhase(
        results,
        'collision-paint-${extent}x$extent-$strokeCount',
      );
      _truncateSpan(phase, 'mutation.local', strokeCount);
    }
  }

  final placement = _singlePhase(results, 'canonical-element-placement');
  final publication = _singlePhase(results, 'canonical-element-publication');
  final placementSpans =
      (placement['instrumentation']! as Map<String, dynamic>)['spans']!
          as Map<String, dynamic>;
  for (final name in const <String>['snapshot', 'plan', 'apply']) {
    placementSpans[name] = jsonDecode(jsonEncode(_spanMetrics(publication, name)));
  }
  return normalized;
}

void _truncateSpan(Map phase, String spanName, int expectedCount) {
  final metrics = _spanMetrics(phase, spanName);
  final samples = (metrics['samplesUs']! as List).cast<int>();
  if (samples.length < expectedCount) {
    throw FormatException('$spanName has fewer samples than expected.');
  }
  final retained = samples.take(expectedCount).toList(growable: false)..sort();
  metrics['count'] = expectedCount;
  metrics['samplesUs'] = retained;
  metrics['p50Us'] = _percentile(retained, 0.50);
  metrics['p95Us'] = _percentile(retained, 0.95);
  metrics['p99Us'] = _percentile(retained, 0.99);
  metrics['maxUs'] = retained.last;
}

void _validateSpanCount(
  Map phase, {
  required String spanName,
  required int expectedCount,
}) {
  final metrics = _spanMetrics(phase, spanName);
  if (metrics['count'] != expectedCount) {
    throw FormatException(
      '${phase['phase']} must record exactly $expectedCount $spanName spans.',
    );
  }
  _validateSampleMetrics(metrics, expectedCount: expectedCount);
}

Map<String, dynamic> _spanMetrics(Map phase, String spanName) {
  final instrumentation = phase['instrumentation'];
  final spans = instrumentation is Map ? instrumentation['spans'] : null;
  final metrics = spans is Map ? spans[spanName] : null;
  if (metrics is! Map) {
    throw FormatException('${phase['phase']} is missing $spanName metrics.');
  }
  return metrics.cast<String, dynamic>();
}

void _validateZeroPersistenceCounters(Map phase) {
  final instrumentation = phase['instrumentation'];
  final counters = instrumentation is Map ? instrumentation['counters'] : null;
  if (counters is! Map ||
      _persistenceCounters.difference(counters.keys.toSet()).isNotEmpty ||
      _persistenceCounters.any((name) => counters[name] != 0)) {
    throw FormatException(
      '${phase['phase']} must perform zero filesystem, JSON and base64 work.',
    );
  }
}

void _validateSampleMetrics(Map metrics, {required int expectedCount}) {
  final samples = metrics['samplesUs'];
  if (samples is! List ||
      samples.length != expectedCount ||
      samples.any((sample) => sample is! int || sample < 0)) {
    throw const FormatException('Span metrics must contain every raw sample.');
  }
  final sorted = samples.cast<int>().toList(growable: false)..sort();
  if (metrics['p50Us'] != _percentile(sorted, 0.50) ||
      metrics['p95Us'] != _percentile(sorted, 0.95) ||
      metrics['p99Us'] != _percentile(sorted, 0.99) ||
      metrics['maxUs'] != sorted.last) {
    throw const FormatException(
      'Span percentiles must be recomputable from raw samples.',
    );
  }
}

Map _singlePhase(List results, String phaseName) {
  final matches = results
      .whereType<Map>()
      .where((candidate) => candidate['phase'] == phaseName)
      .toList(growable: false);
  if (matches.length != 1) {
    throw FormatException(
      'PERF-009 project response must contain exactly one $phaseName phase.',
    );
  }
  return matches.single;
}

int _percentile(List<int> sorted, double percentile) {
  if (sorted.isEmpty) return 0;
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
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
  if (result.exitCode != 0) {
    throw StateError('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
  return (result.stdout as String).trim();
}

Future<String> _architectureLabel() async {
  final result = await Process.run('uname', const <String>['-m']);
  if (result.exitCode != 0) {
    throw StateError('Unable to resolve runner architecture: ${result.stderr}');
  }
  return switch ((result.stdout as String).trim()) {
    'arm64' => 'arm64',
    'x86_64' => 'x64',
    final value => throw StateError('Unsupported runner architecture: $value'),
  };
}

Future<String> _flutterFrameworkRevision() async {
  final result = await Process.run(
    'flutter',
    const <String>['--version', '--machine'],
  );
  if (result.exitCode != 0) {
    throw StateError('flutter --version --machine failed: ${result.stderr}');
  }
  final metadata = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  final revision = metadata['frameworkRevision'];
  if (revision is! String || revision.trim().isEmpty) {
    throw StateError('Flutter framework revision is unavailable.');
  }
  return revision;
}

Future<String> _flameVersion(String repositoryRoot) async {
  final lock = File('$repositoryRoot/packages/map_editor/pubspec.lock');
  final lines = await lock.readAsLines();
  final flameIndex = lines.indexWhere((line) => line.trim() == 'flame:');
  if (flameIndex < 0) throw StateError('Flame is absent from pubspec.lock.');
  for (var index = flameIndex + 1;
      index < lines.length && index <= flameIndex + 12;
      index += 1) {
    final line = lines[index].trim();
    if (!line.startsWith('version:')) continue;
    final value = line.substring('version:'.length).trim().replaceAll('"', '');
    if (value.isNotEmpty) return value;
  }
  throw StateError('Flame version is unavailable in pubspec.lock.');
}
