import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/src/installed_hub_journey_receipt.dart';

/// Turns one BETA-CIN-085 journey run into a receipt.
///
/// The journey observes and writes measurements; this stamps them with what
/// makes them mean something later — the exact commit, a clean tree, the
/// platform, and the commands that produced the run. The ticket's fifth
/// criterion asks for precisely that list, and for the limits the run did not
/// certify, which the receipt refuses to leave empty.
///
/// It never runs the journey. Nothing here can be scheduled into a workflow and
/// start installing packages on a hosted runner.
Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help')) {
    stdout.writeln(
      'Usage: dart run bin/certify_installed_hub_journey.dart '
      '--repository-root <path> --measurements <path> '
      '--journey-command <command> --output <path>',
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
        'CIN-085 certification requires a clean tree: a journey run against '
        'uncommitted code cannot be reproduced, and an unreproducible journey '
        'is not evidence that the product works.',
      );
    }
    final receipt = InstalledHubJourneyReceipt.fromMeasurements(
      measurements: measurements,
      provenance: <String, Object?>{
        'commit': commit,
        'treeState': 'clean',
        'platform': '${Platform.operatingSystem} '
            '${Platform.operatingSystemVersion}',
        'commands': <String>[
          options['journey-command']!,
          'dart run bin/certify_installed_hub_journey.dart ${arguments.join(' ')}',
        ],
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      },
    );
    final output = File(p.absolute(options['output']!));
    await output.parent.create(recursive: true);
    // Temporary then rename: a killed run must not leave a partial file that
    // later reads as a receipt.
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
    'journey-command',
    'output',
  };
  final parsed = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    if (index + 1 >= arguments.length || !arguments[index].startsWith('--')) {
      throw const FormatException('CIN-085 CLI arguments are incomplete.');
    }
    final name = arguments[index].substring(2);
    if (!names.contains(name) || parsed.containsKey(name)) {
      throw FormatException('Unsupported CIN-085 option: --$name.');
    }
    parsed[name] = arguments[index + 1];
  }
  if (parsed.keys.toSet().length != names.length) {
    throw const FormatException('CIN-085 CLI requires every option.');
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
