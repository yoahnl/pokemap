import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Player new game carries native recovery while preserving the actual start',
    () async {
      final harness = RuntimePlayerTestHarness(
        newGameConfig: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'start_map',
          initialRecoveryPoint: ProjectNewGameRecoveryPoint(
            mapId: 'start_map',
            position: GridPos(x: 0, y: 1),
            facing: EntityFacing.west,
          ),
        ),
      );
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();
      final result = await harness.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.newGame,
          snapshotRevision: harness.coordinator.snapshot.revision,
          payload: const RuntimePlayerLoadSlot(
            profileId: 'player',
            slotId: 'slot_1',
          ),
        ),
      );
      expect(result.status, RuntimePlayerCommandStatus.accepted);
      final state = harness.source.requests.single.initialGameState!;
      expect(state.playerPosition, const GridPos(x: 1, y: 1));
      expect(
        PlayerRecoveryPoint.tryRead(state),
        const PlayerRecoveryPoint(
          mapId: 'start_map',
          position: GridPos(x: 0, y: 1),
          facing: EntityFacing.west,
        ),
      );
    },
  );

  test('preparation validates and fingerprints the separate recovery map without changing the entry', () async {
    final root = await Directory.systemTemp.createTemp('initial-recovery-');
    addTearDown(() => root.delete(recursive: true));
    const point = ProjectNewGameRecoveryPoint(
      mapId: 'home',
      position: GridPos(x: 0, y: 1),
      facing: EntityFacing.south,
    );
    const config = ProjectNewGameConfig(
      enabled: true,
      startMapId: 'intro',
      initialRecoveryPoint: point,
    );
    const manifest = ProjectManifest(
      name: 'Recovery',
      tilesets: [],
      maps: [
        ProjectMapEntry(id: 'intro', name: 'Intro', relativePath: 'intro.json'),
        ProjectMapEntry(id: 'home', name: 'Home', relativePath: 'home.json'),
      ],
      newGame: config,
    );
    const intro = MapData(
      id: 'intro',
      name: 'Intro',
      size: GridSize(width: 2, height: 2),
      entities: [
        MapEntity(
          id: 'start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          spawn: MapEntitySpawnData(
            spawnKey: 'start',
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
    );
    const home = MapData(
      id: 'home',
      name: 'Home',
      size: GridSize(width: 2, height: 2),
    );
    final projectFile = File('${root.path}/project.json');
    await projectFile.writeAsString(jsonEncode(manifest.toJson()));
    await File('${root.path}/intro.json')
        .writeAsString(jsonEncode(intro.toJson()));
    final recoveryFile = File('${root.path}/home.json');
    await recoveryFile.writeAsString(jsonEncode(home.toJson()));
    final flow = RuntimeProjectNewGameFlowPort(
      projectFilePath: () async => projectFile.path,
      initialMapPreloader: RuntimeInitialMapPreloader(
        projectFilePath: () async => projectFile.path,
        loadSave: (_) async => null,
        tilesetImageLoader: (
          paths, {
          transparentColorByTilesetId = const {},
          onProgress,
        }) async => {},
      ),
    );
    addTearDown(flow.clear);
    final prepared = await flow.prepare();
    expect(prepared.startMap, intro);
    expect(prepared.initialRecoveryMap, home);
    final state = createNewGameStateFromProject(
      project: prepared.project,
      startMap: prepared.startMap,
      initialRecoveryMap: prepared.initialRecoveryMap,
    );
    expect(state.currentMapId, 'intro');
    expect(state.playerPosition, const GridPos(x: 1, y: 1));
    expect(PlayerRecoveryPoint.tryRead(state)?.mapId, 'home');
    expect(await flow.readCurrentProjectRevision(), prepared.projectRevision);
    await recoveryFile.writeAsString(
      jsonEncode(home.copyWith(name: 'Home edited').toJson()),
    );
    expect(
      await flow.readCurrentProjectRevision(),
      isNot(prepared.projectRevision),
    );
    await recoveryFile.writeAsString(
      jsonEncode(
        home.copyWith(size: const GridSize(width: 1, height: 1)).toJson(),
      ),
    );
    await expectLater(
      flow.readCurrentProjectRevision(),
      throwsA(isA<ValidationException>()),
    );
    await recoveryFile.delete();
    await expectLater(
      flow.readCurrentProjectRevision(),
      throwsA(isA<FileSystemException>()),
    );
    final outside = await Directory.systemTemp.createTemp('recovery-outside-');
    addTearDown(() => outside.delete(recursive: true));
    final target = File('${outside.path}/home.json');
    await target.writeAsString(jsonEncode(home.toJson()));
    await Link(recoveryFile.path).create(target.path);
    await expectLater(flow.readCurrentProjectRevision(), throwsStateError);
  });
}
