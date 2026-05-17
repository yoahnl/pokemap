import 'dart:convert';
import 'dart:io';

import 'package:map_battle/src/data/psdk_fight_parity_audit.dart';
import 'package:map_battle/src/data/psdk_parity_gate.dart';

Future<void> main(List<String> args) async {
  final options = _AuditCliOptions.parse(args);
  if (options.showHelp) {
    stdout.writeln(_usage);
    return;
  }

  final audit = await buildPsdkFightParityAudit(
    movesDirectory: Directory(options.movesDirectory),
    psdkBattleDirectory: Directory(options.psdkBattleDirectory),
    runtimeBridge: await _loadRuntimeBridge(options.runtimeBridgePath),
  );

  if (options.jsonOutputPath case final jsonPath?) {
    await _writeTextFile(jsonPath, '${audit.toPrettyJson()}\n');
  }
  if (options.markdownOutputPath case final markdownPath?) {
    await _writeTextFile(markdownPath, audit.toMarkdown());
  }

  if (options.runGate) {
    final gateResult = psdkLot02ParityGate.evaluate(audit);
    if (!gateResult.passed) {
      stderr.writeln(gateResult.message);
      exitCode = 1;
      return;
    }
    stdout.writeln(gateResult.message);
  }
  if (options.runFinalGate) {
    final goldenFixtureCount = await _countGoldenFixtures(
      Directory(options.goldenFixturesDirectory),
    );
    final gateResult = psdkFinalParityGate.evaluate(
      audit,
      goldenFixtureCount: goldenFixtureCount,
    );
    if (!gateResult.passed) {
      stderr.writeln(gateResult.message);
      exitCode = 1;
      return;
    }
    stdout.writeln(gateResult.message);
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
  --runtime-bridge <file>
                     Import runtime bridge diagnostics JSON.
                     Defaults to ../../reports/analysis/
                     psdk_runtime_bridge_diagnostics_latest.json when present.
  --gate             Enforce Lot 02 non-regression thresholds.
  --final-gate       Enforce the final 100% parity acceptance gate.
  --goldens <dir>    Golden fixture directory for --final-gate.
  --help             Show this help.

Defaults:
  --moves ../../pokémon_sdk_test_project/Data/Studio/moves
  --effects ../../pokemonsdk-development/scripts/5 Battle
  --goldens test/fixtures/psdk_golden
''';

final class _AuditCliOptions {
  const _AuditCliOptions({
    required this.movesDirectory,
    required this.psdkBattleDirectory,
    this.jsonOutputPath,
    this.markdownOutputPath,
    this.runtimeBridgePath,
    required this.goldenFixturesDirectory,
    this.runGate = false,
    this.runFinalGate = false,
    this.showHelp = false,
  });

  factory _AuditCliOptions.parse(List<String> args) {
    var movesDirectory = '../../pokémon_sdk_test_project/Data/Studio/moves';
    var psdkBattleDirectory = '../../pokemonsdk-development/scripts/5 Battle';
    var goldenFixturesDirectory = 'test/fixtures/psdk_golden';
    String? jsonOutputPath;
    String? markdownOutputPath;
    String? runtimeBridgePath;
    var runGate = false;
    var runFinalGate = false;
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
        case '--runtime-bridge':
          runtimeBridgePath = _requiredValue(args, ++index, arg);
        case '--gate':
          runGate = true;
        case '--final-gate':
          runFinalGate = true;
        case '--goldens':
          goldenFixturesDirectory = _requiredValue(args, ++index, arg);
        default:
          throw FormatException('Unknown option: $arg\n\n$_usage');
      }
    }

    return _AuditCliOptions(
      movesDirectory: movesDirectory,
      psdkBattleDirectory: psdkBattleDirectory,
      jsonOutputPath: jsonOutputPath,
      markdownOutputPath: markdownOutputPath,
      runtimeBridgePath: runtimeBridgePath,
      goldenFixturesDirectory: goldenFixturesDirectory,
      runGate: runGate,
      runFinalGate: runFinalGate,
      showHelp: showHelp,
    );
  }

  final String movesDirectory;
  final String psdkBattleDirectory;
  final String? jsonOutputPath;
  final String? markdownOutputPath;
  final String? runtimeBridgePath;
  final String goldenFixturesDirectory;
  final bool runGate;
  final bool runFinalGate;
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

Future<PsdkRuntimeBridgeParity> _loadRuntimeBridge(String? path) async {
  final diagnosticsPath = path ?? _defaultRuntimeBridgePath;
  final diagnosticsFile = File(diagnosticsPath);
  if (!await diagnosticsFile.exists()) {
    return const PsdkRuntimeBridgeParity.notMeasured();
  }
  final decoded = jsonDecode(await diagnosticsFile.readAsString());
  if (decoded is! Map) {
    throw FormatException('Runtime bridge diagnostics JSON must be an object.');
  }
  return PsdkRuntimeBridgeParity.fromJson(decoded.cast<String, Object?>());
}

const _defaultRuntimeBridgePath =
    '../../reports/analysis/psdk_runtime_bridge_diagnostics_latest.json';

Future<int> _countGoldenFixtures(Directory directory) async {
  if (!await directory.exists()) {
    return 0;
  }
  var count = 0;
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.json')) {
      count += 1;
    }
  }
  return count;
}
