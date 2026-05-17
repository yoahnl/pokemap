import 'dart:convert';
import 'dart:io';

import 'package:map_battle/src/data/psdk_fight_convergence_dashboard.dart';

Future<void> main(List<String> args) async {
  final options = _DashboardOptions.parse(args);
  final auditJson = jsonDecode(
    await File(options.auditJsonPath).readAsString(),
  );
  if (auditJson is! Map) {
    throw FormatException('Audit JSON root must be an object.');
  }
  final dashboard = renderPsdkFightConvergenceDashboard(
    auditJson.cast<String, Object?>(),
  );
  final outputFile = File(options.outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(dashboard);
  stdout.writeln(
      'PSDK fight convergence dashboard written to ${outputFile.path}');
}

final class _DashboardOptions {
  const _DashboardOptions({
    required this.auditJsonPath,
    required this.outputPath,
  });

  factory _DashboardOptions.parse(List<String> args) {
    var auditJsonPath =
        '../../reports/analysis/psdk_fight_parity_audit_latest.json';
    var outputPath =
        '../../reports/analysis/psdk_fight_convergence_dashboard.md';
    for (var index = 0; index < args.length; index += 1) {
      switch (args[index]) {
        case '--audit-json':
          auditJsonPath = _requiredValue(args, ++index, '--audit-json');
        case '--output':
          outputPath = _requiredValue(args, ++index, '--output');
        case '--help' || '-h':
          stdout.writeln(_usage);
          exit(0);
        default:
          throw FormatException('Unknown option: ${args[index]}\n\n$_usage');
      }
    }
    return _DashboardOptions(
      auditJsonPath: auditJsonPath,
      outputPath: outputPath,
    );
  }

  final String auditJsonPath;
  final String outputPath;
}

String _requiredValue(List<String> args, int index, String option) {
  if (index >= args.length || args[index].startsWith('--')) {
    throw FormatException('Missing value for $option\n\n$_usage');
  }
  return args[index];
}

const _usage = '''
Usage:
  dart run tool/update_psdk_fight_convergence_dashboard.dart [options]

Options:
  --audit-json <file>  Audit JSON produced by psdk_fight_parity_audit.dart.
  --output <file>      Markdown dashboard output path.
  --help               Show this help.
''';
