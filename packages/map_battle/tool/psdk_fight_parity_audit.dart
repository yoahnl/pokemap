import 'dart:io';

import 'package:map_battle/src/data/psdk_fight_parity_audit.dart';

Future<void> main(List<String> args) async {
  final options = _AuditCliOptions.parse(args);
  if (options.showHelp) {
    stdout.writeln(_usage);
    return;
  }

  final audit = await buildPsdkFightParityAudit(
    movesDirectory: Directory(options.movesDirectory),
    psdkBattleDirectory: Directory(options.psdkBattleDirectory),
  );

  if (options.jsonOutputPath case final jsonPath?) {
    await _writeTextFile(jsonPath, '${audit.toPrettyJson()}\n');
  }
  if (options.markdownOutputPath case final markdownPath?) {
    await _writeTextFile(markdownPath, audit.toMarkdown());
  }

  if (options.jsonOutputPath == null && options.markdownOutputPath == null) {
    stdout.write(audit.toMarkdown());
    return;
  }

  stdout.writeln(
    'PSDK fight parity audit: '
    '${audit.attackMetrics.fait}/${audit.attackMetrics.totalAttacks} attacks '
    'strict, ${audit.methodMetrics.byStatus.values.fold<int>(0, (a, b) => a + b)} '
    'manifest methods, ${audit.effectMetrics.totalEffects} effects.',
  );
}

const _usage = '''
Usage:
  dart run tool/psdk_fight_parity_audit.dart [options]

Options:
  --moves <dir>      PSDK Studio moves directory.
  --effects <dir>    Pokemon SDK "5 Battle" directory.
  --json <file>      Write machine-readable JSON audit.
  --markdown <file>  Write human-readable Markdown audit.
  --help             Show this help.

Defaults:
  --moves ../../pokémon_sdk_test_project/Data/Studio/moves
  --effects ../../pokemonsdk-development/scripts/5 Battle
''';

final class _AuditCliOptions {
  const _AuditCliOptions({
    required this.movesDirectory,
    required this.psdkBattleDirectory,
    this.jsonOutputPath,
    this.markdownOutputPath,
    this.showHelp = false,
  });

  factory _AuditCliOptions.parse(List<String> args) {
    var movesDirectory = '../../pokémon_sdk_test_project/Data/Studio/moves';
    var psdkBattleDirectory = '../../pokemonsdk-development/scripts/5 Battle';
    String? jsonOutputPath;
    String? markdownOutputPath;
    var showHelp = false;

    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      switch (arg) {
        case '--help' || '-h':
          showHelp = true;
        case '--moves':
          movesDirectory = _requiredValue(args, ++index, arg);
        case '--effects':
          psdkBattleDirectory = _requiredValue(args, ++index, arg);
        case '--json':
          jsonOutputPath = _requiredValue(args, ++index, arg);
        case '--markdown':
          markdownOutputPath = _requiredValue(args, ++index, arg);
        default:
          throw FormatException('Unknown option: $arg\n\n$_usage');
      }
    }

    return _AuditCliOptions(
      movesDirectory: movesDirectory,
      psdkBattleDirectory: psdkBattleDirectory,
      jsonOutputPath: jsonOutputPath,
      markdownOutputPath: markdownOutputPath,
      showHelp: showHelp,
    );
  }

  final String movesDirectory;
  final String psdkBattleDirectory;
  final String? jsonOutputPath;
  final String? markdownOutputPath;
  final bool showHelp;
}

String _requiredValue(List<String> args, int index, String option) {
  if (index >= args.length || args[index].startsWith('--')) {
    throw FormatException('Missing value for $option\n\n$_usage');
  }
  return args[index];
}

Future<void> _writeTextFile(String path, String content) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}
