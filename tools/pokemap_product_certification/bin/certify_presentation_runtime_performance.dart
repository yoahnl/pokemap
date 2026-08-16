import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/src/presentation_runtime_performance_receipt.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help')) {
    stdout.writeln(
      'Usage: dart run bin/certify_presentation_runtime_performance.dart '
      '--repository-root <path> --measurements <path> '
      '--platform-support <path> --output <path>',
    );
    return;
  }
  try {
    final options = _parseArguments(arguments);
    final repository = Directory(p.absolute(options['repository-root']!));
    final measurements = _readJsonMap(
      File(p.absolute(options['measurements']!)),
    );
    final platformSupport = _readJsonMap(
      File(p.absolute(options['platform-support']!)),
    );
    final commit = await _git(repository, const <String>['rev-parse', 'HEAD']);
    final status = await _git(repository, const <String>[
      'status',
      '--porcelain=v1',
    ]);
    if (status.isNotEmpty) {
      throw StateError('CIN-038 certification requires a clean tree.');
    }
    final treeListing = await _git(repository, const <String>[
      'ls-tree',
      '-r',
      '--full-tree',
      'HEAD',
    ]);
    final receipt = PresentationRuntimePerformanceReceipt.fromMeasurements(
      measurements: measurements,
      platformSupport: platformSupport,
      provenance: <String, Object?>{
        'commit': commit,
        'treeState': 'clean',
        'treeFingerprint': sha256.convert(utf8.encode(treeListing)).toString(),
        'os': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'architecture': _architecture(),
        'dartVersion': Platform.version,
        'flutterVersion': Platform.environment['FLUTTER_VERSION'] ?? 'unknown',
        'flutterRevision':
            Platform.environment['FLUTTER_REVISION'] ?? 'unknown',
        'command': <String>[
          'dart',
          'run',
          'bin/certify_presentation_runtime_performance.dart',
          ...arguments,
        ],
      },
    );
    final output = File(p.absolute(options['output']!));
    await output.parent.create(recursive: true);
    final temporary = File('${output.path}.tmp-$pid');
    await temporary.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(receipt.toJson())}\n',
      flush: true,
    );
    if (await output.exists()) await output.delete();
    await temporary.rename(output.path);
    stdout.writeln(jsonEncode(receipt.toJson()));
    if (!receipt.passed) exitCode = 1;
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 2;
  }
}

Map<String, String> _parseArguments(List<String> arguments) {
  const names = <String>{
    'repository-root',
    'measurements',
    'platform-support',
    'output',
  };
  final parsed = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    if (index + 1 >= arguments.length || !arguments[index].startsWith('--')) {
      throw const FormatException('CIN-038 CLI arguments are incomplete.');
    }
    final name = arguments[index].substring(2);
    if (!names.contains(name) || parsed.containsKey(name)) {
      throw FormatException('Unsupported CIN-038 option: --$name.');
    }
    parsed[name] = arguments[index + 1];
  }
  if (parsed.keys.toSet().length != names.length) {
    throw const FormatException('CIN-038 CLI requires every option.');
  }
  return parsed;
}

Map<String, Object?> _readJsonMap(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    throw FormatException('${file.path} must contain a JSON object.');
  }
  return decoded;
}

Future<String> _git(Directory repository, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: repository.path,
  );
  if (result.exitCode != 0) {
    throw StateError('Git command failed: ${result.stderr}');
  }
  return '${result.stdout}'.trim();
}

String _architecture() {
  final version = Platform.version.toLowerCase();
  if (version.contains('arm64') || version.contains('aarch64')) return 'arm64';
  if (version.contains('x64') || version.contains('x86_64')) return 'x64';
  return 'unknown';
}
