import 'dart:io';

import 'package:map_battle/src/data/generated/psdk_move_registry_manifest.dart';
import 'package:map_battle/src/data/psdk_attack_coverage_report.dart';

Future<void> main(List<String> args) async {
  final movesDirectory = Directory(
    args.isNotEmpty
        ? args[0]
        : '../../pokémon_sdk_test_project/Data/Studio/moves',
  );
  final outputFile = File(
    args.length > 1 ? args[1] : '../../reports/psdk-attack-coverage.md',
  );

  final moves = await loadPsdkStudioMoveCoverageEntries(movesDirectory);
  final report = generatePsdkAttackCoverageReport(
    moves: moves,
    manifest: psdkMoveRegistryManifest,
    sourceDescription: movesDirectory.path,
  );

  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(report);
  stdout.writeln(
    'Wrote ${moves.length} PSDK attack coverage rows to ${outputFile.path}',
  );
}
