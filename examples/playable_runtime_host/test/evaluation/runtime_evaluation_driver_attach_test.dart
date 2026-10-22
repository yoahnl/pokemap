import 'dart:io';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_command_dispatcher.dart';
import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/driver/evaluation_driver.dart';

import '../support/evaluation_game_fixtures.dart';

import 'package:pokemap_loader/src/evaluation/driver/runtime_evaluation_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('session timing commands use the runtime speed and reject live manual stepping', () async {
    final fixture = await _createFixture();
    final driver = RuntimeEvaluationDriver.attach(
      game: fixture.game, project: fixture.bundle.manifest,
      projectRoot: Directory(fixture.bundle.projectRootDirectory),
      services: _RecordingPlayerServiceAutomation(),
    );
    addTearDown(driver.dispose);
    for (final multiplier in [1, 2, 5, 10]) {
      await const EvaluationCommandDispatcher().execute(driver: driver, commandId: 'speed-$multiplier', operation: 'simulation.setSpeed', arguments: {'multiplier': multiplier});
      expect(fixture.game.testSpeed.value.multiplier, multiplier);
    }
    await expectLater(const EvaluationCommandDispatcher().execute(driver: driver, commandId: 'invalid', operation: 'simulation.setSpeed', arguments: {'multiplier': 100}), throwsArgumentError);
    await expectLater(const EvaluationCommandDispatcher().execute(driver: driver, commandId: 'advance', operation: 'simulation.advance', arguments: {'milliseconds': 1000}), throwsStateError);
  });

  test('attached driver does not dispose the host-owned game', () async {
    final fixture = await _createFixture();
    final services = _RecordingPlayerServiceAutomation();
    final driver = RuntimeEvaluationDriver.attach(
      game: fixture.game,
      project: fixture.bundle.manifest,
      projectRoot: Directory(fixture.bundle.projectRootDirectory),
      services: services,
    );

    await driver.dispose();

    expect(fixture.game.removeCount, 0);
  });

  test(
    'attached driver delegates player services to the visible host',
    () async {
      final fixture = await _createFixture();
      final services = _RecordingPlayerServiceAutomation();
      final driver = RuntimeEvaluationDriver.attach(
        game: fixture.game,
        project: fixture.bundle.manifest,
        projectRoot: Directory(fixture.bundle.projectRootDirectory),
        services: services,
      );
      addTearDown(driver.dispose);

      await driver.inspectShop(
        entityId: 'service_port_shop',
        shopId: 'shop_port_supplies',
      );
      await driver.buy(
        'potion',
        2,
        entityId: 'service_port_shop',
        shopId: 'shop_port_supplies',
      );
      await driver.healParty(entityId: 'service_port_healing');
      await driver.withdrawFromPc('magikarp', entityId: 'service_port_pc');

      expect(services.calls, <String>[
        'shop.inspect',
        'shop.buy:potion:2',
        'heal',
        'pc.withdraw:magikarp',
      ]);
    },
  );
}

Future<_AttachedGameFixture> _createFixture() async {
  final root = await Directory.systemTemp.createTemp('attached-runtime-');
  addTearDown(() => root.delete(recursive: true));
  final projectPath = p.join(root.path, 'project.json');
  const project = ProjectManifest(
    name: 'Attached project',
    maps: [
      ProjectMapEntry(
        id: 'attached-map',
        name: 'Attached',
        relativePath: 'map.json',
      ),
    ],
    tilesets: [],
  );
  const map = MapData(
    id: 'attached-map',
    name: 'Attached',
    size: GridSize(width: 2, height: 2),
  );
  await File(projectPath).writeAsString(jsonEncode(project.toJson()));
  await File(p.join(root.path, 'map.json'))
      .writeAsString(jsonEncode(map.toJson()));
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectPath,
    mapId: map.id,
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
  const _AttachedGameFixture({required this.bundle, required this.game});

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
