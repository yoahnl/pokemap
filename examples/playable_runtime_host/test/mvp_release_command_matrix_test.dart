import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/mvp_release_command_matrix.dart';

void main() {
  test('quick and full matrices are deterministic and cover release criteria',
      () {
    final quick = MvpReleaseCommandMatrix.quick('/workspace');
    final full = MvpReleaseCommandMatrix.full('/workspace');

    expect(quick.mode, MvpReleaseCommandMode.quick);
    expect(full.mode, MvpReleaseCommandMode.full);
    expect(quick.commands, isNotEmpty);
    expect(full.commands.length, greaterThan(quick.commands.length));
    expect(
      full.commands.map((command) => command.id).toSet(),
      hasLength(full.commands.length),
    );
    expect(
      full.commands.map((command) => command.criterion).toSet(),
      containsAll(MvpReleaseGateCriterion.values),
    );
    expect(
      MvpReleaseCommandMatrix.full('/workspace')
          .commands
          .map((command) => command.displayCommand),
      full.commands.map((command) => command.displayCommand),
    );
  });

  test('full matrix starts with every package gate and both runtime smokes',
      () {
    final commands = MvpReleaseCommandMatrix.full('/workspace').commands;

    expect(
      commands.take(20).map((command) => command.id),
      const <String>[
        'core-tests',
        'core-analyze',
        'gameplay-tests',
        'gameplay-analyze',
        'battle-tests',
        'battle-analyze',
        'runtime-tests',
        'runtime-analyze',
        'editor-tests',
        'editor-analyze',
        'player-ui-tests',
        'player-ui-analyze',
        'distribution-tests',
        'distribution-analyze',
        'hub-tests',
        'hub-analyze',
        'host-tests',
        'host-analyze',
        'runtime-golden-battle-smoke',
        'host-golden-launch-smoke',
      ],
    );
    expect(
      commands.take(20).map((command) => command.workingDirectory),
      const <String>[
        '/workspace/packages/map_core',
        '/workspace/packages/map_core',
        '/workspace/packages/map_gameplay',
        '/workspace/packages/map_gameplay',
        '/workspace/packages/map_battle',
        '/workspace/packages/map_battle',
        '/workspace/packages/map_runtime',
        '/workspace/packages/map_runtime',
        '/workspace/packages/map_editor',
        '/workspace/packages/map_editor',
        '/workspace/packages/map_player_ui',
        '/workspace/packages/map_player_ui',
        '/workspace/packages/map_distribution',
        '/workspace/packages/map_distribution',
        '/workspace/apps/pokemap_hub',
        '/workspace/apps/pokemap_hub',
        '/workspace/examples/playable_runtime_host',
        '/workspace/examples/playable_runtime_host',
        '/workspace/packages/map_runtime',
        '/workspace/examples/playable_runtime_host',
      ],
    );
  });

  test('runner is sequential and stops at the first failed command', () async {
    final observed = <String>[];
    final matrix = MvpReleaseCommandMatrix(
      mode: MvpReleaseCommandMode.quick,
      commands: [
        _command('one'),
        _command('two'),
        _command('three'),
      ],
    );

    final results = await matrix.execute((command) async {
      observed.add(command.id);
      return MvpReleaseCommandResult.validated(
        command: command,
        exitCode: command.id == 'two' ? 1 : 0,
        durationMilliseconds: 10,
        outputDigestSha256: 'a' * 64,
        source: 'test://${command.id}',
      );
    });

    expect(observed, ['one', 'two']);
    expect(results, hasLength(2));
    expect(results.last.isSuccessful, isFalse);
  });
}

MvpReleaseCommandSpec _command(String id) => MvpReleaseCommandSpec(
      id: id,
      criterion: MvpReleaseGateCriterion.criticalPackageTests,
      executable: 'dart',
      arguments: const ['test'],
      workingDirectory: '/workspace',
    );
