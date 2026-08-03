import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hydrateRuntimePlayerPokemonProgression', () {
    test('hydrates a level 16 legacy Pokemon without regressing its level', () {
      const legacy = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        level: 16,
        knownMoveIds: ['water_gun', 'bite'],
      );

      final hydrated = hydrateRuntimePlayerPokemonProgression(
        gameState: const GameState(
          saveId: 'legacy_level_16',
          party: PlayerParty(members: [legacy]),
        ),
        catalogs: _catalogs(),
      );
      final pokemon = hydrated.party.members.single;

      expect(pokemon.level, 16);
      expect(pokemon.experience, 2535);
      expect(
        pokemon.currentPpByMoveId,
        {'water_gun': 25, 'bite': 25},
      );
    });

    test('hydrates null PP to an empty map when no moves are known', () {
      const legacy = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        level: 16,
      );

      final hydrated = hydrateRuntimePlayerPokemonProgression(
        gameState: const GameState(
          saveId: 'legacy_no_moves',
          party: PlayerParty(members: [legacy]),
        ),
        catalogs: _catalogs(),
      );

      expect(hydrated.party.members.single.currentPpByMoveId, isEmpty);
    });

    test('preserves valid non-null experience and current PP', () {
      const persisted = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        level: 16,
        knownMoveIds: ['water_gun'],
        experience: 3000,
        currentPpByMoveId: {'water_gun': 7},
      );

      final hydrated = hydrateRuntimePlayerPokemonProgression(
        gameState: const GameState(
          saveId: 'persisted_progression',
          party: PlayerParty(members: [persisted]),
        ),
        catalogs: _catalogs(),
      );
      final pokemon = hydrated.party.members.single;

      expect(pokemon.experience, 3000);
      expect(pokemon.currentPpByMoveId, {'water_gun': 7});
    });

    test('hydrates stored Pokemon as well as party members', () {
      const stored = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        level: 16,
        knownMoveIds: ['bite'],
      );

      final hydrated = hydrateRuntimePlayerPokemonProgression(
        gameState: const GameState(
          saveId: 'stored_progression',
          pokemonStorage: PokemonStorage(storedPokemon: [stored]),
        ),
        catalogs: _catalogs(),
      );
      final pokemon = hydrated.pokemonStorage.storedPokemon.single;

      expect(pokemon.experience, 2535);
      expect(pokemon.currentPpByMoveId, {'bite': 25});
    });

    test('rejects negative experience with an explicit error code', () {
      const invalid = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        experience: -1,
      );

      expect(
        () => hydrateRuntimePlayerPokemonProgression(
          gameState: const GameState(
            saveId: 'negative_experience',
            party: PlayerParty(members: [invalid]),
          ),
          catalogs: _catalogs(),
        ),
        throwsA(
          isA<RuntimePlayerPokemonProgressionHydrationException>().having(
            (error) => error.code,
            'code',
            RuntimePlayerPokemonProgressionHydrationErrorCode
                .negativeExperience,
          ),
        ),
      );
    });

    test('rejects negative current PP with an explicit error code', () {
      const invalid = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        knownMoveIds: ['water_gun'],
        experience: 3000,
        currentPpByMoveId: {'water_gun': -1},
      );

      expect(
        () => hydrateRuntimePlayerPokemonProgression(
          gameState: const GameState(
            saveId: 'negative_pp',
            party: PlayerParty(members: [invalid]),
          ),
          catalogs: _catalogs(),
        ),
        throwsA(
          isA<RuntimePlayerPokemonProgressionHydrationException>().having(
            (error) => error.code,
            'code',
            RuntimePlayerPokemonProgressionHydrationErrorCode.negativeCurrentPp,
          ),
        ),
      );
    });

    test('rejects an empty current PP move key with an explicit error code',
        () {
      const invalid = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        experience: 3000,
        currentPpByMoveId: {' ': 1},
      );

      expect(
        () => hydrateRuntimePlayerPokemonProgression(
          gameState: const GameState(
            saveId: 'empty_pp_key',
            party: PlayerParty(members: [invalid]),
          ),
          catalogs: _catalogs(),
        ),
        throwsA(
          isA<RuntimePlayerPokemonProgressionHydrationException>().having(
            (error) => error.code,
            'code',
            RuntimePlayerPokemonProgressionHydrationErrorCode.emptyMoveId,
          ),
        ),
      );
    });

    test('rejects current PP linked to an unknown move', () {
      const invalid = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        knownMoveIds: ['missing_move'],
        experience: 3000,
        currentPpByMoveId: {'missing_move': 1},
      );

      expect(
        () => hydrateRuntimePlayerPokemonProgression(
          gameState: const GameState(
            saveId: 'unknown_move',
            party: PlayerParty(members: [invalid]),
          ),
          catalogs: _catalogs(),
        ),
        throwsA(
          isA<RuntimePlayerPokemonProgressionHydrationException>().having(
            (error) => error.code,
            'code',
            RuntimePlayerPokemonProgressionHydrationErrorCode.unknownMove,
          ),
        ),
      );
    });

    test('rejects current PP for a catalogued move that is not known', () {
      const invalid = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        knownMoveIds: ['water_gun'],
        experience: 3000,
        currentPpByMoveId: {'bite': 1},
      );

      expect(
        () => hydrateRuntimePlayerPokemonProgression(
          gameState: const GameState(
            saveId: 'pp_for_unlearned_move',
            party: PlayerParty(members: [invalid]),
          ),
          catalogs: _catalogs(),
        ),
        throwsA(
          isA<RuntimePlayerPokemonProgressionHydrationException>().having(
            (error) => error.code,
            'code',
            RuntimePlayerPokemonProgressionHydrationErrorCode
                .ppForUnlearnedMove,
          ),
        ),
      );
    });
  });

  group('PlayableMapGame progression hydration', () {
    test('hydrates a project New Game before the runtime becomes playable',
        () async {
      final game = PlayableMapGame(
        bundle: _runtimeBundle(newGameEnabled: true),
        projectFilePath: '/tmp/progression_hydration/project.json',
        runtimePlayerPokemonProgressionCatalogLoader: _loadCatalogs,
      );

      game.onGameResize(Vector2(320, 240));
      await game.onLoad();

      final pokemon = game.gameStateSnapshot.party.members.single;
      expect(pokemon.level, 16);
      expect(pokemon.experience, 2535);
      expect(pokemon.currentPpByMoveId, {'water_gun': 25});
    });

    test('starts independent catalogue and tileset IO concurrently', () async {
      final catalogueGate = Completer<void>();
      final tilesetGate = Completer<void>();
      var catalogueStarted = false;
      var tilesetStarted = false;
      final game = PlayableMapGame(
        bundle: _runtimeBundle(
          newGameEnabled: true,
          tilesetAbsolutePathsById: const {
            'fixture': '/tmp/progression_hydration/fixture.png',
          },
        ),
        projectFilePath: '/tmp/progression_hydration/project.json',
        runtimePlayerPokemonProgressionCatalogLoader: ({
          required gameState,
          required projectRootDirectory,
          required pokemonConfig,
        }) async {
          catalogueStarted = true;
          await catalogueGate.future;
          return _catalogs();
        },
        runtimeTilesetImageLoader: (
          absolutePathByTilesetId, {
          transparentColorByTilesetId = const {},
        }) async {
          tilesetStarted = true;
          await tilesetGate.future;
          return <String, RuntimeTilesetImage>{};
        },
      );

      game.onGameResize(Vector2(320, 240));
      final loading = game.onLoad();
      try {
        await _waitUntil(() => catalogueStarted);
        await _waitUntil(() => tilesetStarted);
      } finally {
        catalogueGate.complete();
        tilesetGate.complete();
      }
      await loading;
    });

    test('hydrates a legacy Pokemon restored by loadGame', () async {
      final repository = _MemoryGameSaveRepository(
        const GameState(
          saveId: 'legacy_runtime_load',
          currentMapId: 'hydration_map',
          playerPosition: GridPos(x: 1, y: 1),
          party: PlayerParty(
            members: [
              PlayerPokemon(
                speciesId: 'wartortle',
                natureId: 'bold',
                abilityId: 'torrent',
                level: 16,
                knownMoveIds: ['water_gun'],
              ),
            ],
          ),
        ),
      );
      final game = PlayableMapGame(
        bundle: _runtimeBundle(newGameEnabled: false),
        projectFilePath: '/tmp/progression_hydration/project.json',
        saveRepository: repository,
        runtimePlayerPokemonProgressionCatalogLoader: _loadCatalogs,
      );

      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      await _waitForActivationDispatch(game);

      expect(await game.loadGame(), isTrue);
      final pokemon = game.gameStateSnapshot.party.members.single;
      expect(pokemon.level, 16);
      expect(pokemon.experience, 2535);
      expect(pokemon.currentPpByMoveId, {'water_gun': 25});
    });
  });

  test('default loader projects growth rate and max PP from project data',
      () async {
    final root = await Directory.systemTemp.createTemp('progression_catalog_');
    addTearDown(() => root.delete(recursive: true));
    final speciesDirectory =
        Directory(p.join(root.path, 'data', 'pokemon', 'species'));
    final catalogDirectory =
        Directory(p.join(root.path, 'data', 'pokemon', 'catalogs'));
    await speciesDirectory.create(recursive: true);
    await catalogDirectory.create(recursive: true);
    await File(p.join(speciesDirectory.path, '0008-wartortle.json'))
        .writeAsString(
      jsonEncode({
        'id': 'wartortle',
        'progression': {'growthRateId': 'medium_slow'},
      }),
    );
    await File(p.join(catalogDirectory.path, 'moves.json')).writeAsString(
      jsonEncode({
        'catalog': 'moves',
        'entries': [
          const PokemonMove(
            id: 'water_gun',
            name: 'Water Gun',
            type: 'water',
            category: PokemonMoveCategory.special,
            accuracy: PokemonMoveAccuracy.percent(value: 100),
            pp: 25,
          ).toJson(),
        ],
      }),
    );

    final catalogs = await loadRuntimePlayerPokemonProgressionCatalogs(
      gameState: const GameState(
        saveId: 'loader_projection',
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'wartortle',
              natureId: 'bold',
              abilityId: 'torrent',
              level: 16,
              knownMoveIds: ['water_gun'],
            ),
          ],
        ),
      ),
      projectRootDirectory: root.path,
      pokemonConfig: const ProjectPokemonConfig(),
    );

    expect(catalogs.growthRateIdBySpeciesId, {'wartortle': 'medium_slow'});
    expect(catalogs.maxPpByMoveId, {'water_gun': 25});
  });
}

RuntimePlayerPokemonProgressionCatalogs _catalogs() {
  return const RuntimePlayerPokemonProgressionCatalogs(
    growthRateIdBySpeciesId: {'wartortle': 'medium_slow'},
    maxPpByMoveId: {'water_gun': 25, 'bite': 25},
  );
}

Future<RuntimePlayerPokemonProgressionCatalogs> _loadCatalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  return _catalogs();
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for map activation dispatch.');
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 1000; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Condition was not reached before the test timeout.');
}

RuntimeMapBundle _runtimeBundle({
  required bool newGameEnabled,
  Map<String, String> tilesetAbsolutePathsById = const {},
}) {
  const pokemon = PlayerPokemon(
    speciesId: 'wartortle',
    natureId: 'bold',
    abilityId: 'torrent',
    level: 16,
    knownMoveIds: ['water_gun'],
  );
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Progression hydration fixture',
      maps: const [
        ProjectMapEntry(
          id: 'hydration_map',
          name: 'Hydration map',
          relativePath: 'maps/hydration_map.json',
        ),
      ],
      tilesets: const [],
      newGame: ProjectNewGameConfig(
        enabled: newGameEnabled,
        startMapId: 'hydration_map',
        startSpawnId: 'spawn_start',
        initialParty: const [pokemon],
      ),
    ),
    map: const MapData(
      id: 'hydration_map',
      name: 'Hydration map',
      size: GridSize(width: 3, height: 3),
      layers: [MapLayer.object(id: 'objects', name: 'Objects')],
      entities: [
        MapEntity(
          id: 'spawn_start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            spawnKey: 'spawn_start',
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/progression_hydration',
    tilesetAbsolutePathsById: tilesetAbsolutePathsById,
  );
}

final class _MemoryGameSaveRepository implements GameSaveRepository {
  _MemoryGameSaveRepository(this._state);

  GameState? _state;

  @override
  Future<void> save(GameState state) async => _state = state;

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async => _state = null;
}
