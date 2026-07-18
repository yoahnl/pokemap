import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('createNewGameStateFromProject', () {
    test('builds the authored empty-party start and preserves it through save',
        () {
      final state = createNewGameStateFromProject(
        project: _project(initialParty: const <PlayerPokemon>[]),
        startMap: _startMap(),
        saveId: 'selbrume_empty_party',
      );

      expect(state.saveId, 'selbrume_empty_party');
      expect(state.currentMapId, 'map_start');
      expect(state.playerPosition, const GridPos(x: 7, y: 8));
      expect(state.playerFacing, EntityFacing.east);
      expect(state.trainerProfile.name, 'Joueur');
      expect(state.trainerProfile.money, 350);
      expect(
        state.bag.entries,
        const <BagEntry>[
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
      );
      expect(state.party.members, isEmpty);
      expect(
        state.narrativeFactRuntimeState.overridesByFactId,
        <String, bool>{
          'fact_intro_active': true,
          'fact_existing_party': false,
        },
      );

      final reloaded = gameStateFromSaveData(saveDataFromGameState(state));
      expect(reloaded.currentMapId, state.currentMapId);
      expect(reloaded.playerPosition, state.playerPosition);
      expect(reloaded.playerFacing, state.playerFacing);
      expect(reloaded.party.members, isEmpty);
      expect(reloaded.bag, state.bag);
      expect(reloaded.trainerProfile, state.trainerProfile);
      expect(
        reloaded.narrativeFactRuntimeState,
        state.narrativeFactRuntimeState,
      );
    });

    test('builds the authored existing-party alternative and marks the fact',
        () {
      const eevee = PlayerPokemon(
        speciesId: 'eevee',
        natureId: 'hardy',
        abilityId: 'run-away',
        level: 5,
        currentHp: 20,
      );

      final state = createNewGameStateFromProject(
        project: _project(initialParty: const <PlayerPokemon>[eevee]),
        startMap: _startMap(),
      );

      expect(state.party.members, const <PlayerPokemon>[eevee]);
      expect(
        state
            .narrativeFactRuntimeState.overridesByFactId['fact_existing_party'],
        isTrue,
      );
      expect(state.progression.seenSpeciesIds, contains('eevee'));
      expect(state.progression.caughtSpeciesIds, contains('eevee'));
    });

    test('rejects a map or configured spawn outside the authored contract', () {
      expect(
        () => createNewGameStateFromProject(
          project: _project(initialParty: const <PlayerPokemon>[]),
          startMap: _startMap(mapId: 'wrong_map'),
        ),
        throwsArgumentError,
      );
      expect(
        () => createNewGameStateFromProject(
          project: _project(
            initialParty: const <PlayerPokemon>[],
            startSpawnId: 'missing_spawn',
          ),
          startMap: _startMap(),
        ),
        throwsA(isA<GameplaySpawnResolutionException>()),
      );
    });

    test('rejects a disabled project new-game contract', () {
      expect(
        () => createNewGameStateFromProject(
          project: _project(
            initialParty: const <PlayerPokemon>[],
            enabled: false,
          ),
          startMap: _startMap(),
        ),
        throwsStateError,
      );
    });
  });
}

ProjectManifest _project({
  required List<PlayerPokemon> initialParty,
  String startSpawnId = 'spawn_authored',
  bool enabled = true,
}) {
  return ProjectManifest(
    name: 'Project new game fixture',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_start',
        name: 'Start',
        relativePath: 'maps/map_start.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: 'fact_intro_active',
        label: 'Introduction active',
      ),
      NarrativeFactDefinition(
        id: 'fact_existing_party',
        label: 'Équipe existante',
      ),
    ],
    newGame: ProjectNewGameConfig(
      enabled: enabled,
      startMapId: 'map_start',
      startSpawnId: startSpawnId,
      playerName: 'Joueur',
      startingMoney: 350,
      initialBag: const <BagEntry>[
        BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
      ],
      initialParty: initialParty,
      initialFacts: const <String, bool>{'fact_intro_active': true},
      existingPartyFactId: 'fact_existing_party',
    ),
  );
}

MapData _startMap({String mapId = 'map_start'}) {
  return MapData(
    id: mapId,
    name: 'Start',
    size: const GridSize(width: 12, height: 10),
    mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_default'),
    entities: const <MapEntity>[
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
