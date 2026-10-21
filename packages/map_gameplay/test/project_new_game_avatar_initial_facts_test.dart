import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final map = MapData(
      id: 'home',
      name: 'Home',
      size: const GridSize(width: 4, height: 4),
      entities: const [
        MapEntity(
            id: 'spawn',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            spawn: MapEntitySpawnData(
                spawnKey: 'spawn', role: EntitySpawnRole.playerStart)),
      ]);
  final project = ProjectManifest(
    name: 'Avatar initialization',
    maps: const [
      ProjectMapEntry(id: 'home', name: 'Home', relativePath: 'maps/home.json')
    ],
    tilesets: const [
      ProjectTilesetEntry(
          id: 'actors', name: 'Actors', relativePath: 'assets/actors.png')
    ],
    characters: const [
      ProjectCharacterEntry(id: 'a', name: 'A', tilesetId: 'actors'),
      ProjectCharacterEntry(id: 'b', name: 'B', tilesetId: 'actors'),
    ],
    facts: [
      NarrativeFactDefinition(
          id: 'identity',
          label: 'Identity',
          initialValue: NarrativeValue.integer(-1)),
      NarrativeFactDefinition(
          id: 'paired',
          label: 'Paired',
          initialValue: NarrativeValue.integer(-1)),
      NarrativeFactDefinition(id: 'party', label: 'Party'),
    ],
    newGame: ProjectNewGameConfig.fromJson({
      'enabled': true,
      'startMapId': 'home',
      'playerAvatarCharacterIds': ['a', 'b'],
      'factSchemaVersion': 2,
      'initialFactValues': {'identity': NarrativeValue.integer(-1).toJson()},
      'initialFactValuesByAvatarCharacterId': {
        for (final (avatar, value) in [('a', 0), ('b', 1)])
          avatar: {
            'identity': NarrativeValue.integer(value).toJson(),
            'paired': NarrativeValue.integer(value).toJson(),
          },
      },
      'existingPartyFactId': 'party',
    }),
  );
  for (final (avatar, value) in [('a', 0), ('b', 1)]) {
    test('selected avatar $avatar initializes its correlated facts once', () {
      final state = createNewGameStateFromProject(
          project: project, startMap: map, playerAvatarCharacterId: avatar);
      expect(state.trainerProfile.avatarCharacterId, avatar);
      expect(state.narrativeFactRuntimeState.valueFor('identity'),
          NarrativeValue.integer(value));
      expect(state.narrativeFactRuntimeState.valueFor('paired'),
          NarrativeValue.integer(value));
      expect(state.narrativeFactRuntimeState.valueFor('party'),
          const NarrativeValue.boolean(false));
      expect(state.party.members, isEmpty);
      expect(state.bag.entries, isEmpty);
      final changedAvatar = state.copyWith(
          trainerProfile: state.trainerProfile
              .copyWith(avatarCharacterId: avatar == 'a' ? 'b' : 'a'));
      final cold = gameStateFromSaveData(SaveData.fromJson(
          jsonDecode(jsonEncode(saveDataFromGameState(changedAvatar).toJson()))
              as Map<String, dynamic>));
      expect(cold.narrativeFactRuntimeState.valueFor('identity'),
          NarrativeValue.integer(value));
      expect(cold.narrativeFactRuntimeState.valueFor('paired'),
          NarrativeValue.integer(value));
    });
  }
  test('default avatar chooses only the first authored row', () {
    final state =
        createNewGameStateFromProject(project: project, startMap: map);
    expect(state.trainerProfile.avatarCharacterId, 'a');
    expect(state.narrativeFactRuntimeState.valueFor('identity'),
        NarrativeValue.integer(0));
  });
  test('resolved project default selects its authored row', () {
    final state = createNewGameStateFromProject(
        project: project.copyWith(
            settings: project.settings.copyWith(defaultPlayerCharacterId: 'b')),
        startMap: map);
    expect(state.trainerProfile.avatarCharacterId, 'b');
    expect(state.narrativeFactRuntimeState.valueFor('identity'),
        NarrativeValue.integer(1));
  });
  test('actual seed avatar wins without adding any new seed identity fields',
      () {
    final state = createNewGameStateFromSeed(
        project: project,
        startMap: map,
        currentProjectRevision: 'revision',
        seed: NewGameSeed(
            operationId: 'operation',
            projectRevision: 'revision',
            slotId: 'slot',
            saveId: 'save',
            draftId: 'draft',
            draftRevision: 1,
            playerName: 'Player',
            avatarCharacterId: 'b',
            pronounSet: PlayerPronounSet.neutral,
            starterOptionId: null,
            variables: const {}));
    expect(state.narrativeFactRuntimeState.valueFor('identity'),
        NarrativeValue.integer(1));
    expect(state.party.members, isEmpty);
  });
  test('an old save without the Fact stays unknown despite a current avatar',
      () {
    final old = GameState(
        saveId: 'old',
        currentMapId: 'home',
        playerPosition: const GridPos(x: 1, y: 1),
        trainerProfile:
            const TrainerProfile(name: 'Old', avatarCharacterId: 'b'));
    final cold = normalizeLoadedGameState(gameStateFromSaveData(
        SaveData.fromJson(saveDataFromGameState(old).toJson())));
    expect(cold.narrativeFactRuntimeState.valueFor('identity'), isNull);
    expect(
        project.facts.firstWhere((fact) => fact.id == 'identity').initialValue,
        NarrativeValue.integer(-1));
  });
}
