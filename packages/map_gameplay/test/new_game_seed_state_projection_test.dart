import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('createNewGameStateFromSeed', () {
    test('projects identity, starter and typed variables without mutation', () {
      final project = _project();
      final startMap = _startMap();
      final projectBefore = project.toJson();
      final mapBefore = startMap.toJson();

      final state = createNewGameStateFromSeed(
        project: project,
        startMap: startMap,
        seed: _seed(
          playerName: 'Élodie',
          avatarCharacterId: 'hero_b',
          pronounSet: PlayerPronounSet.feminine,
          starterOptionId: 'starter_leaf',
          variables: const <String, NarrativeValue>{
            'difficulty': NarrativeValue.string('story'),
          },
        ),
        currentProjectRevision: 'project-r1',
        locale: 'fr-FR',
      );

      expect(state.saveId, '018f255f-2d50-4f4f-8aa2-c893ae06b8c1');
      expect(state.currentMapId, 'map_start');
      expect(state.playerPosition, const GridPos(x: 7, y: 8));
      expect(state.playerFacing, EntityFacing.east);
      expect(state.trainerProfile.name, 'Élodie');
      expect(state.trainerProfile.avatarCharacterId, 'hero_b');
      expect(state.trainerProfile.pronounSet, PlayerPronounSet.feminine);
      expect(state.party.members.single.speciesId, 'leafmon');
      expect(state.progression.seenSpeciesIds, contains('leafmon'));
      expect(state.progression.caughtSpeciesIds, contains('leafmon'));
      expect(
        state.scriptVariables.values['difficulty'],
        const ScriptVariableValue.string('story'),
      );
      expect(
        state.narrativeFactRuntimeState.valueFor('fact_existing_party'),
        const NarrativeValue.boolean(true),
      );
      expect(project.toJson(), projectBefore);
      expect(startMap.toJson(), mapBefore);
    });

    test('uses authored fallbacks when optional seed extensions are absent',
        () {
      const authoredPokemon = PlayerPokemon(
        speciesId: 'eevee',
        natureId: 'hardy',
        abilityId: 'run-away',
        level: 5,
        currentHp: 20,
      );
      final state = createNewGameStateFromSeed(
        project: _project(
          initialParty: const <PlayerPokemon>[authoredPokemon],
          starterOptions: const <ProjectStarterOption>[],
        ),
        startMap: _startMap(),
        seed: _seed(
          playerName: 'Ari',
          avatarCharacterId: null,
          starterOptionId: null,
        ),
        currentProjectRevision: 'project-r1',
      );

      expect(state.trainerProfile.name, 'Ari');
      expect(state.trainerProfile.avatarCharacterId, 'hero_a');
      expect(state.party.members, hasLength(1));
      expect(state.party.members.single.individualId, isNotEmpty);
      expect(
        state.party.members.single.copyWith(individualId: ''),
        authoredPokemon,
      );
      expect(
        state.narrativeFactRuntimeState.valueFor('fact_difficulty'),
        const NarrativeValue.string('normal'),
      );
      expect(
        state.narrativeFactRuntimeState.valueFor('fact_existing_party'),
        const NarrativeValue.boolean(true),
      );
    });

    test('is deterministic for the same seed, project and map', () {
      final project = _project();
      final startMap = _startMap();
      final seed = _seed(
        starterOptionId: 'starter_leaf',
        variables: const <String, NarrativeValue>{
          'difficulty': NarrativeValue.string('hard'),
        },
      );

      final first = createNewGameStateFromSeed(
        project: project,
        startMap: startMap,
        seed: seed,
        currentProjectRevision: 'project-r1',
      );
      final second = createNewGameStateFromSeed(
        project: project,
        startMap: startMap,
        seed: seed,
        currentProjectRevision: 'project-r1',
      );

      expect(second.toJson(), first.toJson());
    });

    test('rejects a stale project revision before session creation', () {
      expect(
        () => createNewGameStateFromSeed(
          project: _project(),
          startMap: _startMap(),
          seed: _seed(starterOptionId: 'starter_leaf'),
          currentProjectRevision: 'project-r2',
        ),
        throwsA(
          isA<NewGameSeedProjectionException>().having(
            (error) => error.code,
            'code',
            NewGameSeedProjectionIssueCode.staleProjectRevision,
          ),
        ),
      );
    });

    test('requires an authored starter selection when choices exist', () {
      expect(
        () => createNewGameStateFromSeed(
          project: _project(),
          startMap: _startMap(),
          seed: _seed(starterOptionId: null),
          currentProjectRevision: 'project-r1',
        ),
        throwsA(
          isA<NewGameSeedProjectionException>().having(
            (error) => error.code,
            'code',
            NewGameSeedProjectionIssueCode.starterRequired,
          ),
        ),
      );
    });

    test('rejects an unknown starter option', () {
      expect(
        () => createNewGameStateFromSeed(
          project: _project(),
          startMap: _startMap(),
          seed: _seed(starterOptionId: 'starter_missing'),
          currentProjectRevision: 'project-r1',
        ),
        throwsA(
          isA<NewGameSeedProjectionException>().having(
            (error) => error.code,
            'code',
            NewGameSeedProjectionIssueCode.starterUnknown,
          ),
        ),
      );
    });

    test('rejects a starter when the authored party is already full', () {
      const member = PlayerPokemon(
        speciesId: 'eevee',
        natureId: 'hardy',
        abilityId: 'run-away',
        level: 5,
        currentHp: 20,
      );
      expect(
        () => createNewGameStateFromSeed(
          project: _project(
            initialParty: List<PlayerPokemon>.filled(
              maxPlayerPartySize,
              member,
            ),
          ),
          startMap: _startMap(),
          seed: _seed(starterOptionId: 'starter_leaf'),
          currentProjectRevision: 'project-r1',
        ),
        throwsA(
          isA<NewGameSeedProjectionException>().having(
            (error) => error.code,
            'code',
            NewGameSeedProjectionIssueCode.starterPartyFull,
          ),
        ),
      );
    });

    test('projects each generic variable kind into script variables', () {
      final state = createNewGameStateFromSeed(
        project: _project(),
        startMap: _startMap(),
        seed: _seed(
          starterOptionId: 'starter_leaf',
          variables: <String, NarrativeValue>{
            'intro_seen': const NarrativeValue.boolean(true),
            'difficulty_rank': NarrativeValue.integer(3),
            'route': const NarrativeValue.string('forest'),
          },
        ),
        currentProjectRevision: 'project-r1',
      );

      expect(
        state.scriptVariables.values,
        containsPair('intro_seen', const ScriptVariableValue.bool(true)),
      );
      expect(
        state.scriptVariables.values,
        containsPair('difficulty_rank', const ScriptVariableValue.int(3)),
      );
      expect(
        state.scriptVariables.values,
        containsPair('route', const ScriptVariableValue.string('forest')),
      );
    });

    test('rejects a generic variable that collides with player identity', () {
      expect(
        () => createNewGameStateFromSeed(
          project: _project(),
          startMap: _startMap(),
          seed: _seed(
            starterOptionId: 'starter_leaf',
            variables: const <String, NarrativeValue>{
              playerNameScriptVariable: NarrativeValue.string('Override'),
            },
          ),
          currentProjectRevision: 'project-r1',
        ),
        throwsA(
          isA<NewGameSeedProjectionException>().having(
            (error) => error.code,
            'code',
            NewGameSeedProjectionIssueCode.variableReserved,
          ),
        ),
      );
    });

    test('preserves project validation failures', () {
      expect(
        () => createNewGameStateFromSeed(
          project: _project(enabled: false),
          startMap: _startMap(),
          seed: _seed(starterOptionId: 'starter_leaf'),
          currentProjectRevision: 'project-r1',
        ),
        throwsStateError,
      );
    });
  });
}

NewGameSeed _seed({
  String playerName = 'Élodie',
  String? avatarCharacterId = 'hero_a',
  PlayerPronounSet pronounSet = PlayerPronounSet.neutral,
  String? starterOptionId,
  Map<String, NarrativeValue> variables = const <String, NarrativeValue>{},
}) {
  return NewGameSeed(
    operationId: 'new-game-1',
    projectRevision: 'project-r1',
    slotId: 'slot-1',
    saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
    draftId: 'draft-1',
    draftRevision: 4,
    playerName: playerName,
    avatarCharacterId: avatarCharacterId,
    pronounSet: pronounSet,
    starterOptionId: starterOptionId,
    variables: variables,
  );
}

ProjectManifest _project({
  bool enabled = true,
  List<PlayerPokemon> initialParty = const <PlayerPokemon>[],
  List<ProjectStarterOption> starterOptions = const <ProjectStarterOption>[
    ProjectStarterOption(
      id: 'starter_leaf',
      label: 'Leaf',
      pokemon: PlayerPokemon(
        speciesId: 'leafmon',
        natureId: 'calm',
        abilityId: 'grow',
        level: 5,
        currentHp: 20,
      ),
    ),
  ],
}) {
  return ProjectManifest(
    name: 'Seed projection fixture',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_start',
        name: 'Start',
        relativePath: 'maps/map_start.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'characters',
        name: 'Characters',
        relativePath: 'assets/characters.png',
      ),
    ],
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'hero_a',
        name: 'Hero A',
        tilesetId: 'characters',
      ),
      ProjectCharacterEntry(
        id: 'hero_b',
        name: 'Hero B',
        tilesetId: 'characters',
      ),
    ],
    settings: const ProjectSettings(defaultPlayerCharacterId: 'hero_a'),
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: 'fact_existing_party',
        label: 'Existing party',
      ),
      NarrativeFactDefinition(
        id: 'fact_difficulty',
        label: 'Difficulty',
        initialValue: const NarrativeValue.string('normal'),
      ),
    ],
    newGame: ProjectNewGameConfig(
      enabled: enabled,
      startMapId: 'map_start',
      startSpawnId: 'spawn_authored',
      playerName: 'Player',
      playerAvatarCharacterIds: const <String>['hero_a', 'hero_b'],
      initialParty: initialParty,
      initialFactValues: const <String, NarrativeValue>{
        'fact_difficulty': NarrativeValue.string('normal'),
      },
      existingPartyFactId: 'fact_existing_party',
      starterOptions: starterOptions,
    ),
  );
}

MapData _startMap() {
  return const MapData(
    id: 'map_start',
    name: 'Start',
    size: GridSize(width: 12, height: 10),
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_default'),
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_default',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 2),
        spawn: MapEntitySpawnData(
          spawnKey: 'spawn_default',
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.south,
        ),
      ),
      MapEntity(
        id: 'spawn_authored',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 7, y: 8),
        spawn: MapEntitySpawnData(
          spawnKey: 'spawn_authored',
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
  );
}
