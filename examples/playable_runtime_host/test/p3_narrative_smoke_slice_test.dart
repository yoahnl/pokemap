import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/runtime_launch_save.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'P3 narrative smoke slice loads host data and PlayableMapGame dispatches mapEnter',
      () async {
    final projectFilePath = p.join(
      Directory.current.path,
      'p3_narrative_smoke_slice',
      'project.json',
    );

    final launchSave = await loadRuntimeHostLaunchSaveData(
      projectFilePath: projectFilePath,
    );

    expect(launchSave, isNotNull);
    expect(launchSave!.currentMapId, _mapId);
    expect(launchSave.progression.storyFlags, contains(_launchFlag));

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFilePath,
      mapId: launchSave.currentMapId,
    );

    expect(bundle.map.id, _mapId);
    expect(bundle.manifest.scenarios.map((scenario) => scenario.id),
        contains(_scenarioId));

    final launchState = gameStateFromSaveData(launchSave);
    expect(launchState.storyFlags.activeFlags, contains(_launchFlag));
    expect(_isSmokeNpcVisible(bundle, launchState), isFalse);

    final game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: projectFilePath,
      saveData: launchSave,
    );

    expect(game.saveLoadInfo.mapId, _mapId);
    expect(
        game.gameStateSnapshot.storyFlags.activeFlags, contains(_launchFlag));
    expect(
      game.gameStateSnapshot.storyFlags.activeFlags,
      isNot(contains(_scenarioFlag)),
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    game.update(0);

    final loadedState = game.gameStateSnapshot;
    expect(loadedState.currentMapId, _mapId);
    expect(loadedState.storyFlags.activeFlags, contains(_launchFlag));
    expect(loadedState.storyFlags.activeFlags, contains(_scenarioFlag));
    expect(loadedState.progression.completedStepIds, contains(_scenarioStep));
    expect(_isSmokeNpcVisible(bundle, loadedState), isTrue);
  });
}

const _mapId = 'p3_narrative_smoke_map';
const _scenarioId = 'p3_narrative_smoke_scenario';
const _launchFlag = 'p3.smoke.launch.flag';
const _scenarioFlag = 'p3.smoke.flag.visible';
const _scenarioStep = 'p3.smoke.step.completed';

bool _isSmokeNpcVisible(RuntimeMapBundle bundle, GameState state) {
  final entity = bundle.map.entities.singleWhere(
    (candidate) => candidate.id == 'p3_smoke_npc',
  );
  return isNpcRuntimePresentOnMap(
    gameState: state,
    manifest: bundle.manifest,
    stepStudioWorldRules: const [],
    mapId: _mapId,
    entity: entity,
  );
}
