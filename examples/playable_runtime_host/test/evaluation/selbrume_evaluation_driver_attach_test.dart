import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/driver/evaluation_driver.dart';
import 'package:pokemap_loader/src/evaluation/driver/evaluation_game_fixtures.dart';
import 'package:pokemap_loader/src/evaluation/driver/selbrume_evaluation_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('attached driver does not dispose the host-owned game', () async {
    final fixture = await _createFixture();
    final services = _RecordingPlayerServiceAutomation();
    final driver = SelbrumeEvaluationDriver.attach(
      game: fixture.game,
      project: fixture.bundle.manifest,
      projectRoot: Directory(fixture.bundle.projectRootDirectory),
      services: services,
    );

    await driver.dispose();

    expect(fixture.game.removeCount, 0);
  });

  test('attached driver delegates player services to the visible host',
      () async {
    final fixture = await _createFixture();
    final services = _RecordingPlayerServiceAutomation();
    final driver = SelbrumeEvaluationDriver.attach(
      game: fixture.game,
      project: fixture.bundle.manifest,
      projectRoot: Directory(fixture.bundle.projectRootDirectory),
      services: services,
    );
    addTearDown(driver.dispose);

    await driver.inspectShop();
    await driver.buy('potion', 2);
    await driver.healParty();
    await driver.withdrawFromPc('magikarp');

    expect(
      services.calls,
      <String>[
        'shop.inspect',
        'shop.buy:potion:2',
        'heal',
        'pc.withdraw:magikarp',
      ],
    );
  });
}

Future<_AttachedGameFixture> _createFixture() async {
  final repositoryRoot = _findRepositoryRoot();
  final projectPath = p.join(repositoryRoot.path, 'selbrume', 'project.json');
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectPath,
    mapId: 'map_bourg_selbrume',
  );
  return _AttachedGameFixture(
    bundle: bundle,
    game: _TrackingPlayableMapGame(
      bundle: bundle,
      projectFilePath: projectPath,
      saveRepository: SerializedEvaluationSaveRepository(),
      encounterRandom: AlwaysEncounterRandom(),
    ),
  );
}

final class _AttachedGameFixture {
  const _AttachedGameFixture({
    required this.bundle,
    required this.game,
  });

  final RuntimeMapBundle bundle;
  final _TrackingPlayableMapGame game;
}

final class _TrackingPlayableMapGame extends PlayableMapGame {
  _TrackingPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
    required super.encounterRandom,
  });

  int removeCount = 0;

  @override
  void onRemove() {
    removeCount += 1;
    super.onRemove();
  }
}

final class _RecordingPlayerServiceAutomation
    implements EvaluationPlayerServiceAutomation {
  final List<String> calls = <String>[];

  @override
  Future<void> inspectShop() async {
    calls.add('shop.inspect');
  }

  @override
  Future<void> buy(String itemId, int quantity) async {
    calls.add('shop.buy:$itemId:$quantity');
  }

  @override
  Future<void> healParty() async {
    calls.add('heal');
  }

  @override
  Future<void> withdrawFromPc(String pokemonId) async {
    calls.add('pc.withdraw:$pokemonId');
  }
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}
