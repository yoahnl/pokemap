import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';
import 'package:path/path.dart' as p;

import 'support/fine_mask_performance_contract.dart';

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) {
        throw const FormatException(
          'Fine-mask performance response is missing.',
        );
      }
      validateFineMaskPerformanceReceipt(data, requireProvenance: false);
      final requestedOutput = data['requestedOutputPath'];
      if (requestedOutput is! String || requestedOutput.trim().isEmpty) {
        throw const FormatException('POKEMAP_PERF_OUTPUT is required.');
      }
      final output = _validatedOutput(requestedOutput);
      final repositoryRoot = await _git(<String>[
        'rev-parse',
        '--show-toplevel',
      ]);
      final status = await _git(<String>[
        'status',
        '--porcelain=v1',
      ], workingDirectory: repositoryRoot);
      final receipt = <String, Object?>{
        ...data,
        'commit': await _git(<String>[
          'rev-parse',
          'HEAD',
        ], workingDirectory: repositoryRoot),
        'treeState': status.isEmpty ? 'clean' : 'dirty',
        'sdk': Platform.version,
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
          '--driver=test_driver/fine_mask_performance_driver.dart',
          '--target=integration_test/editor_fine_mask_journey_test.dart',
          '--dart-define=POKEMAP_PERF_OUTPUT=$requestedOutput',
        ],
      };
      validateFineMaskPerformanceReceipt(receipt, requireProvenance: true);
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

Future<String> _git(List<String> arguments, {String? workingDirectory}) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
  );
  return result.exitCode == 0 ? '${result.stdout}'.trim() : 'unavailable';
}

Future<Map<String, Object?>> _flutterMetadata() async {
  final result = await Process.run('flutter', <String>[
    '--version',
    '--machine',
  ]);
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
  final lines = await lock.readAsLines();
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
  return Platform.version;
}
