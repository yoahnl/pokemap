import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final intro = MapData(
    id: 'intro',
    name: 'Intro',
    size: const GridSize(width: 4, height: 4),
    entities: const [
      MapEntity(
          id: 'start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 2, y: 3),
          spawn: MapEntitySpawnData(
              spawnKey: 'start',
              role: EntitySpawnRole.playerStart,
              facing: EntityFacing.east))
    ],
  );
  final recovery = MapData(
      id: 'home', name: 'Home', size: const GridSize(width: 2, height: 2));
  ProjectManifest project(
          {String mapId = 'home',
          GridPos position = const GridPos(x: 0, y: 1)}) =>
      ProjectManifest(
          name: 'Recovery',
          maps: const [
            ProjectMapEntry(
                id: 'intro', name: 'Intro', relativePath: 'maps/intro.json'),
            ProjectMapEntry(
                id: 'home', name: 'Home', relativePath: 'maps/home.json'),
          ],
          tilesets: const [],
          newGame: ProjectNewGameConfig(
              enabled: true,
              startMapId: 'intro',
              initialRecoveryPoint: ProjectNewGameRecoveryPoint(
                  mapId: mapId,
                  position: position,
                  facing: EntityFacing.south)));
  test(
      'distinct recovery preserves actual entry, native cold save and replacement',
      () {
    final state = createNewGameStateFromProject(
        project: project(), startMap: intro, initialRecoveryMap: recovery);
    expect(state.currentMapId, 'intro');
    expect(state.playerPosition, const GridPos(x: 2, y: 3));
    expect(state.playerFacing, EntityFacing.east);
    expect(state.party.members, isEmpty);
    final cold = gameStateFromSaveData(SaveData.fromJson(
        jsonDecode(jsonEncode(saveDataFromGameState(state).toJson()))
            as Map<String, dynamic>));
    expect(
        PlayerRecoveryPoint.tryRead(cold),
        const PlayerRecoveryPoint(
            mapId: 'home',
            position: GridPos(x: 0, y: 1),
            facing: EntityFacing.south));
    expect(cold.currentMapId, 'intro');
    final later = recordPlayerRecoveryPoint(cold.copyWith(
        currentMapId: 'intro',
        playerPosition: const GridPos(x: 1, y: 1),
        playerFacing: EntityFacing.west));
    expect(
        PlayerRecoveryPoint.tryRead(later),
        const PlayerRecoveryPoint(
            mapId: 'intro',
            position: GridPos(x: 1, y: 1),
            facing: EntityFacing.west));
  });
  test('same map validates against actual entry map without an extra map', () {
    final state = createNewGameStateFromProject(
        project: project(mapId: 'intro'), startMap: intro);
    expect(PlayerRecoveryPoint.tryRead(state)?.position,
        const GridPos(x: 0, y: 1));
    expect(state.playerPosition, const GridPos(x: 2, y: 3));
  });
  test('cross-map recovery refuses missing, wrong and out-of-bounds maps', () {
    expect(
        () =>
            createNewGameStateFromProject(project: project(), startMap: intro),
        throwsArgumentError);
    expect(
        () => createNewGameStateFromProject(
            project: project(), startMap: intro, initialRecoveryMap: intro),
        throwsA(isA<ValidationException>()));
    expect(
        () => createNewGameStateFromProject(
            project: project(position: const GridPos(x: 2, y: 1)),
            startMap: intro,
            initialRecoveryMap: recovery),
        throwsA(isA<ValidationException>()));
    expect(
        () => createNewGameStateFromProject(
            project: project(),
            startMap: intro,
            initialRecoveryMap: recovery.copyWith(version: ProjectVersion.v9)),
        throwsA(isA<ValidationException>()));
  });
  test('seed projection passes the separately validated recovery map', () {
    final draft = NewGameDraft.start(
        draftId: 'draft',
        projectRevision: 'revision',
        slotId: 'slot',
        config: project().newGame);
    final committed = commitNewGameDraft(
        journal: NewGameSeedCommitJournal.empty(),
        operationId: 'op',
        currentProjectRevision: 'revision',
        expectedDraftRevision: draft.revision,
        draft: draft);
    final state = createNewGameStateFromSeed(
        project: project(),
        startMap: intro,
        initialRecoveryMap: recovery,
        seed: committed.seed!,
        currentProjectRevision: 'revision');
    expect(state.currentMapId, 'intro');
    expect(PlayerRecoveryPoint.tryRead(state)?.mapId, 'home');
  });
}
