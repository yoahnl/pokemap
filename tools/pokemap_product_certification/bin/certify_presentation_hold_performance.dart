import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/src/presentation_hold_performance_receipt.dart';

/// Turns one local BETA-CIN-084 profile run into a receipt.
///
/// Local and explicit by construction: it takes a measurements file a profile
/// journey wrote and never runs the journey itself, so nothing here can be
/// scheduled into a workflow and quietly start costing macOS runner minutes.
/// The provenance it stamps is what makes the numbers reproducible — the exact
/// commit, a clean tree, the device and the Flutter version — because a
/// measurement nobody can reproduce certifies nothing.
Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help')) {
    stdout.writeln(
      'Usage: dart run bin/certify_presentation_hold_performance.dart '
      '--repository-root <path> --measurements <path> --device <name> '
      '--output <path>',
    );
    return;
  }
  try {
    final options = _parseArguments(arguments);
    final repository = Directory(p.absolute(options['repository-root']!));
    final measurements = _readJsonMap(
      File(p.absolute(options['measurements']!)),
    );
    final commit = await _git(repository, const <String>['rev-parse', 'HEAD']);
    final status = await _git(repository, const <String>[
      'status',
      '--porcelain=v1',
    ]);
    if (status.isNotEmpty) {
      throw StateError(
        'CIN-084 certification requires a clean tree: a hold measurement taken '
        'on uncommitted code cannot be reproduced.',
      );
    }
    final receipt = PresentationHoldPerformanceReceipt.fromMeasurements(
      measurements: measurements,
      provenance: <String, Object?>{
        'commit': commit,
        'treeState': 'clean',
        'os': '${Platform.operatingSystem} '
            '${Platform.operatingSystemVersion}',
        'device': options['device']!,
        'flutterVersion':
            Platform.environment['FLUTTER_VERSION'] ?? Platform.version,
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      },
    );
    final output = File(p.absolute(options['output']!));
    await output.parent.create(recursive: true);
    // Written through a temporary file so a killed run never leaves a
    // half-written receipt that reads as evidence.
    final temporary = File('${output.path}.tmp-$pid');
    await temporary.writeAsString('${receipt.encode()}\n', flush: true);
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
    'device',
    'output',
  };
  final parsed = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    if (index + 1 >= arguments.length || !arguments[index].startsWith('--')) {
      throw const FormatException('CIN-084 CLI arguments are incomplete.');
    }
    final name = arguments[index].substring(2);
    if (!names.contains(name) || parsed.containsKey(name)) {
      throw FormatException('Unsupported CIN-084 option: --$name.');
    }
    parsed[name] = arguments[index + 1];
  }
  if (parsed.keys.toSet().length != names.length) {
    throw const FormatException('CIN-084 CLI requires every option.');
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
