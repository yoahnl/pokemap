import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

enum MvpReleaseCommandMode { quick, full }

final class MvpReleaseCommandSpec {
  const MvpReleaseCommandSpec({
    required this.id,
    required this.criterion,
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
  });

  final String id;
  final MvpReleaseGateCriterion criterion;
  final String executable;
  final List<String> arguments;
  final String workingDirectory;

  String get displayCommand =>
      '$executable ${arguments.map(_shellWord).join(' ')}';
}

final class MvpReleaseCommandResult {
  const MvpReleaseCommandResult._({
    required this.command,
    required this.exitCode,
    required this.durationMilliseconds,
    required this.outputDigestSha256,
    required this.source,
  });

  factory MvpReleaseCommandResult.validated({
    required MvpReleaseCommandSpec command,
    required int exitCode,
    required int durationMilliseconds,
    required String outputDigestSha256,
    required String source,
  }) {
    if (durationMilliseconds < 0) {
      throw ArgumentError.value(
        durationMilliseconds,
        'durationMilliseconds',
        'must not be negative',
      );
    }
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(outputDigestSha256)) {
      throw ArgumentError.value(
        outputDigestSha256,
        'outputDigestSha256',
        'must contain exactly 64 hexadecimal characters',
      );
    }
    if (source.trim().isEmpty) {
      throw ArgumentError.value(source, 'source', 'must not be blank');
    }
    return MvpReleaseCommandResult._(
      command: command,
      exitCode: exitCode,
      durationMilliseconds: durationMilliseconds,
      outputDigestSha256: outputDigestSha256.toLowerCase(),
      source: source.trim(),
    );
  }

  final MvpReleaseCommandSpec command;
  final int exitCode;
  final int durationMilliseconds;
  final String outputDigestSha256;
  final String source;

  bool get isSuccessful => exitCode == 0;
}

typedef MvpReleaseCommandExecutor = Future<MvpReleaseCommandResult> Function(
  MvpReleaseCommandSpec command,
);

/// Ordered, fail-fast command matrix used by the MVP release gate.
final class MvpReleaseCommandMatrix {
  MvpReleaseCommandMatrix({
    required this.mode,
    required Iterable<MvpReleaseCommandSpec> commands,
  }) : commands = List.unmodifiable(commands) {
    if (this.commands.isEmpty) {
      throw ArgumentError.value(commands, 'commands', 'must not be empty');
    }
    final ids = this.commands.map((command) => command.id).toList();
    if (ids.toSet().length != ids.length) {
      throw ArgumentError.value(ids, 'commands', 'ids must be unique');
    }
  }

  factory MvpReleaseCommandMatrix.quick(String repositoryRoot) {
    final root = p.normalize(p.absolute(repositoryRoot));
    return MvpReleaseCommandMatrix(
      mode: MvpReleaseCommandMode.quick,
      commands: [
        _dartTest(
          root,
          id: 'core-release-contracts',
          packagePath: 'packages/map_core',
          criterion: MvpReleaseGateCriterion.projectGameplayReadiness,
          tests: const [
            'test/mvp_release_evidence_receipt_test.dart',
            'test/mvp_release_gate_test.dart',
          ],
        ),
        _flutterTest(
          root,
          id: 'host-release-contracts',
          packagePath: 'examples/playable_runtime_host',
          criterion: MvpReleaseGateCriterion.criticalPackageTests,
          tests: const [
            'test/mvp_release_evidence_collector_test.dart',
            'test/mvp_release_command_matrix_test.dart',
            'test/human_walkthrough_receipt_validator_test.dart',
          ],
        ),
      ],
    );
  }

  factory MvpReleaseCommandMatrix.full(String repositoryRoot) {
    final root = p.normalize(p.absolute(repositoryRoot));
    return MvpReleaseCommandMatrix(
      mode: MvpReleaseCommandMode.full,
      commands: [
        _dartTest(
          root,
          id: 'core-tests',
          packagePath: 'packages/map_core',
          criterion: MvpReleaseGateCriterion.projectGameplayReadiness,
        ),
        _analyze(
          root,
          id: 'core-analyze',
          packagePath: 'packages/map_core',
        ),
        _dartTest(
          root,
          id: 'gameplay-tests',
          packagePath: 'packages/map_gameplay',
          criterion: MvpReleaseGateCriterion.criticalPackageTests,
        ),
        _analyze(
          root,
          id: 'gameplay-analyze',
          packagePath: 'packages/map_gameplay',
        ),
        _dartTest(
          root,
          id: 'battle-tests',
          packagePath: 'packages/map_battle',
          criterion: MvpReleaseGateCriterion.criticalPackageTests,
        ),
        _analyze(
          root,
          id: 'battle-analyze',
          packagePath: 'packages/map_battle',
        ),
        _flutterTest(
          root,
          id: 'runtime-tests',
          packagePath: 'packages/map_runtime',
          criterion: MvpReleaseGateCriterion.criticalPackageTests,
        ),
        _analyze(
          root,
          id: 'runtime-analyze',
          packagePath: 'packages/map_runtime',
          flutter: true,
        ),
        _flutterTest(
          root,
          id: 'editor-tests',
          packagePath: 'packages/map_editor',
          criterion: MvpReleaseGateCriterion.criticalPackageTests,
        ),
        _analyze(
          root,
          id: 'editor-analyze',
          packagePath: 'packages/map_editor',
          flutter: true,
        ),
        _flutterTest(
          root,
          id: 'player-ui-tests',
          packagePath: 'packages/map_player_ui',
          criterion: MvpReleaseGateCriterion.criticalPackageTests,
        ),
        _analyze(
          root,
          id: 'player-ui-analyze',
          packagePath: 'packages/map_player_ui',
          flutter: true,
        ),
        _dartTest(
          root,
          id: 'distribution-tests',
          packagePath: 'packages/map_distribution',
          criterion: MvpReleaseGateCriterion.criticalPackageTests,
        ),
        _analyze(
          root,
          id: 'distribution-analyze',
          packagePath: 'packages/map_distribution',
        ),
        _flutterTest(
          root,
          id: 'hub-tests',
          packagePath: 'apps/pokemap_hub',
          criterion: MvpReleaseGateCriterion.criticalPackageTests,
        ),
        _analyze(
          root,
          id: 'hub-analyze',
          packagePath: 'apps/pokemap_hub',
          flutter: true,
        ),
        _flutterTest(
          root,
          id: 'host-tests',
          packagePath: 'examples/playable_runtime_host',
          criterion: MvpReleaseGateCriterion.goldenSlice,
        ),
        _analyze(
          root,
          id: 'host-analyze',
          packagePath: 'examples/playable_runtime_host',
          flutter: true,
        ),
        _flutterTest(
          root,
          id: 'runtime-golden-battle-smoke',
          packagePath: 'packages/map_runtime',
          criterion: MvpReleaseGateCriterion.goldenSlice,
          tests: const ['test/phase_a_golden_battle_slice_smoke_test.dart'],
        ),
        _flutterTest(
          root,
          id: 'host-golden-launch-smoke',
          packagePath: 'examples/playable_runtime_host',
          criterion: MvpReleaseGateCriterion.goldenSlice,
          tests: const ['test/phase_a_golden_slice_launch_test.dart'],
        ),
        MvpReleaseCommandSpec(
          id: 'selbrume-seed-check',
          criterion: MvpReleaseGateCriterion.projectGameplayReadiness,
          executable: 'dart',
          arguments: const [
            'run',
            'tool/seed_selbrume_canonical_narrative_content.dart',
            '--check',
          ],
          workingDirectory: p.join(root, 'packages/map_editor'),
        ),
        _flutterTest(
          root,
          id: 'host-product-journey',
          packagePath: 'examples/playable_runtime_host',
          criterion: MvpReleaseGateCriterion.goldenSlice,
          tests: const ['test/selbrume_player_journey_e2e_test.dart'],
        ),
        _dartTest(
          root,
          id: 'roadmap-release-contracts',
          packagePath: 'packages/map_core',
          criterion: MvpReleaseGateCriterion.postMvpLimitationsDocumented,
          tests: const [
            'test/gameplay_roadmap_dashboard_test.dart',
            'test/gameplay_roadmap_repository_consistency_test.dart',
          ],
        ),
        _flutterTest(
          root,
          id: 'walkthrough-receipt-contract',
          packagePath: 'examples/playable_runtime_host',
          criterion: MvpReleaseGateCriterion.userScopeApproved,
          tests: const ['test/human_walkthrough_receipt_validator_test.dart'],
        ),
      ],
    );
  }

  final MvpReleaseCommandMode mode;
  final List<MvpReleaseCommandSpec> commands;

  Future<List<MvpReleaseCommandResult>> execute(
    MvpReleaseCommandExecutor executor,
  ) async {
    final results = <MvpReleaseCommandResult>[];
    for (final command in commands) {
      final result = await executor(command);
      results.add(result);
      if (!result.isSuccessful) break;
    }
    return List.unmodifiable(results);
  }
}

Future<MvpReleaseCommandResult> executeMvpReleaseCommand(
  MvpReleaseCommandSpec command, {
  IOSink? stdoutSink,
  IOSink? stderrSink,
}) async {
  final stopwatch = Stopwatch()..start();
  final process = await Process.start(
    command.executable,
    command.arguments,
    workingDirectory: command.workingDirectory,
    runInShell: false,
  );
  final output = BytesBuilder(copy: false);
  final stdoutFuture = process.stdout.listen((bytes) {
    output.add(bytes);
    stdoutSink?.add(bytes);
  }).asFuture<void>();
  final stderrFuture = process.stderr.listen((bytes) {
    output.add(bytes);
    stderrSink?.add(bytes);
  }).asFuture<void>();
  final exitCode = await process.exitCode;
  await Future.wait([stdoutFuture, stderrFuture]);
  stopwatch.stop();
  return MvpReleaseCommandResult.validated(
    command: command,
    exitCode: exitCode,
    durationMilliseconds: stopwatch.elapsedMilliseconds,
    outputDigestSha256: sha256.convert(output.takeBytes()).toString(),
    source: 'command://${command.id}',
  );
}

MvpReleaseCommandSpec _dartTest(
  String root, {
  required String id,
  required String packagePath,
  required MvpReleaseGateCriterion criterion,
  List<String> tests = const [],
}) =>
    MvpReleaseCommandSpec(
      id: id,
      criterion: criterion,
      executable: 'dart',
      arguments: ['test', ...tests, '-r', 'compact'],
      workingDirectory: p.join(root, packagePath),
    );

MvpReleaseCommandSpec _flutterTest(
  String root, {
  required String id,
  required String packagePath,
  required MvpReleaseGateCriterion criterion,
  List<String> tests = const [],
}) =>
    MvpReleaseCommandSpec(
      id: id,
      criterion: criterion,
      executable: 'flutter',
      arguments: ['test', ...tests, '-r', 'compact'],
      workingDirectory: p.join(root, packagePath),
    );

MvpReleaseCommandSpec _analyze(
  String root, {
  required String id,
  required String packagePath,
  bool flutter = false,
}) =>
    MvpReleaseCommandSpec(
      id: id,
      criterion: MvpReleaseGateCriterion.criticalPackageTests,
      executable: flutter ? 'flutter' : 'dart',
      arguments: const ['analyze'],
      workingDirectory: p.join(root, packagePath),
    );

String _shellWord(String value) {
  if (RegExp(r'^[A-Za-z0-9_./:=+-]+$').hasMatch(value)) return value;
  return "'${value.replaceAll("'", "'\"'\"'")}'";
}
