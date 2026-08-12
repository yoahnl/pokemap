import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) {
        throw const FormatException('Editor performance response is missing.');
      }
      validatePerformanceResponse(data);
      final target = data['target']! as String;
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
          '--target=$target',
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

void validatePerformanceResponse(Map<String, dynamic> data) {
  if (data['schemaVersion'] != 2) {
    throw const FormatException(
      'Editor performance response must use schema V2.',
    );
  }
  final target = data['target'];
  if (target is! String ||
      !RegExp(r'^integration_test/[a-z0-9_]+_test\.dart$')
          .hasMatch(target)) {
    throw const FormatException(
      'Editor performance response must declare its integration target.',
    );
  }
  if (target == 'integration_test/editor_project_journey_test.dart') {
    _validateInstrumentation(data);
  }
}

void _validateInstrumentation(Map<String, dynamic> data) {
  final instrumentation = data['instrumentation'];
  if (instrumentation is! Map || instrumentation['schemaVersion'] != 1) {
    throw const FormatException(
      'Editor performance response must include instrumentation V1.',
    );
  }
  final spans = instrumentation['spans'];
  const spanNames = <String>{
    'pointer_to_dispatch',
    'mutation.local',
    'state.publish',
    'canvas.build',
    'canvas.paint',
    'save.queue',
    'save.encode',
  };
  if (spans is! Map || spans.keys.toSet().difference(spanNames).isNotEmpty ||
      spanNames.difference(spans.keys.toSet()).isNotEmpty) {
    throw const FormatException(
      'Editor performance response has an invalid span catalog.',
    );
  }
  final counters = instrumentation['counters'];
  const counterNames = <String>{
    'filesystem.read',
    'filesystem.write',
    'filesystem.metadata',
    'json.encode',
    'json.decode',
    'base64.encode',
    'base64.decode',
  };
  if (counters is! Map ||
      counters.keys.toSet().difference(counterNames).isNotEmpty ||
      counterNames.difference(counters.keys.toSet()).isNotEmpty ||
      counters.values.any((value) => value is! int || value < 0)) {
    throw const FormatException(
      'Editor performance response has an invalid counter catalog.',
    );
  }
  if (instrumentation['droppedSampleCount'] != 0) {
    throw const FormatException(
      'Editor performance instrumentation dropped samples.',
    );
  }
  final results = data['results'];
  if (results is! List) {
    throw const FormatException(
      'Editor performance response must include measured phases.',
    );
  }
  _validateHotPathPhase(
    results,
    phaseName: 'pointer-collision-drag',
    requiredSpan: 'pointer_to_dispatch',
    expectedSpanCount: 1,
  );
  _validateHotPathPhase(
    results,
    phaseName: 'collision-paint-100',
    requiredSpan: 'mutation.local',
    expectedSpanCount: 100,
  );
}

void _validateHotPathPhase(
  List<Object?> results, {
  required String phaseName,
  required String requiredSpan,
  required int expectedSpanCount,
}) {
  Map? phase;
  for (final candidate in results) {
    if (candidate is Map && candidate['phase'] == phaseName) {
      phase = candidate;
      break;
    }
  }
  final instrumentation = phase?['instrumentation'];
  final spans = instrumentation is Map ? instrumentation['spans'] : null;
  final metrics = spans is Map ? spans[requiredSpan] : null;
  if (metrics is! Map || metrics['count'] != expectedSpanCount) {
    throw FormatException(
      '$phaseName must record exactly $expectedSpanCount $requiredSpan span(s).',
    );
  }
  final counters = instrumentation is Map
      ? instrumentation['counters']
      : null;
  const counterNames = <String>{
    'filesystem.read',
    'filesystem.write',
    'filesystem.metadata',
    'json.encode',
    'json.decode',
    'base64.encode',
    'base64.decode',
  };
  if (counters is! Map ||
      counterNames.difference(counters.keys.toSet()).isNotEmpty ||
      counterNames.any((name) => counters[name] != 0)) {
    throw FormatException(
      '$phaseName must perform zero filesystem, JSON and base64 work.',
    );
  }
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
