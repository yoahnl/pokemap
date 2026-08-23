import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

// BETA-BAT-015, critères 6 et 7 : la musique de carte reprend à la sortie du
// combat sur les QUATRE issues (victoire, défaite, fuite, capture), et aucune
// piste de combat ne survit à la sortie. Le seam est le même que le
// whiteout-lite : on applique l'issue réelle sans piloter l'overlay Flame.

const _exitTestStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

const _mapMusicAbsolutePath = '/tmp/music_exit_project/audio/town.ogg';

final class _RecordingAudioDriver implements FlameCinematicAudioDriver {
  final List<String> playedPaths = <String>[];

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    playedPaths.add(path);
    return Object();
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final outcomeType in BattleOutcomeType.values) {
    test('la musique de carte reprend après une issue ${outcomeType.name}',
        () async {
      final driver = _RecordingAudioDriver();
      final service = RuntimeMusicService(
        driver: driver,
        mixer: RuntimeAudioMixer(),
        fadeDelay: (_) async {},
      );
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/music_exit_project/project.json',
        musicService: service,
        saveData: saveDataFromGameState(
          const GameState(
            saveId: 'music-exit-save',
            trainerProfile: TrainerProfile(name: 'Leaf', money: 999),
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 10,
                  knownMoveIds: <String>['tackle'],
                  currentPpByMoveId: <String, int>{'tackle': 10},
                  currentHp: 20,
                ),
              ],
            ),
          ),
        ),
        runtimePlayerPokemonProgressionCatalogLoader: _loadCatalogs,
        defeatRecoveryCapsLoader: (_) async =>
            const RuntimePlayerServiceRecoveryCaps(
          maxHpByPartyIndex: <int, int>{0: 24},
          maxPpByPartyIndex: <int, Map<String, int>>{
            0: <String, int>{'tackle': 35},
          },
        ),
        defeatRecoveryCheckpointEmitter: () async {},
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _waitForActivationDispatch(game);
      await _pumpEventQueue(game);

      expect(
        service.playingPath,
        _mapMusicAbsolutePath,
        reason: 'la musique de carte doit jouer avant le combat',
      );

      final context = _wildContext();
      if (outcomeType == BattleOutcomeType.captured) {
        // La preuve de capture est fail-closed : le reçu n'existe qu'après un
        // vrai jet accepté par le moteur, donc on charge une vraie tentative
        // (RNG scripté = capture au premier jet) au lieu de forger l'issue.
        final attempt = submitRuntimeBattleCaptureAttempt<BattleSession>(
          gameState: markSpeciesSeenInGameState(
            game.gameStateSnapshot.copyWith(
              bag: const Bag(
                entries: <BagEntry>[BagEntry(itemId: 'poke-ball', quantity: 1)],
              ),
            ),
            'wildmon',
          ),
          context: context,
          captureAllowed: true,
          itemId: canonicalPokeBallItemId,
          itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
          submitToEngine: () => createBattleSession(
            _captureSetup(),
            rng: const BattleScriptedRng(<int>[1]),
          ).applyChoice(const PlayerBattleChoiceCapture()),
        );
        final capturedOutcome = attempt.engineResult.state.outcome;
        expect(capturedOutcome?.isCaptured, isTrue,
            reason: 'le RNG scripté doit capturer au premier jet');
        game.debugApplyBattleOutcomeForTest(
          context: context,
          outcome: capturedOutcome!,
          captureAttemptReceipt: attempt.receipt,
        );
      } else {
        game.debugApplyBattleOutcomeForTest(
          context: context,
          outcome: _outcome(outcomeType),
        );
      }
      if (outcomeType == BattleOutcomeType.defeat) {
        await game.debugWaitForDefeatRecovery();
      }
      await _pumpEventQueue(game);

      expect(game.debugFlowPhaseName, 'overworld');
      expect(
        service.playingPath,
        _mapMusicAbsolutePath,
        reason: 'la musique de carte doit reprendre après ${outcomeType.name}',
      );
    });
  }
}

Future<void> _pumpEventQueue(PlayableMapGame game) async {
  for (var i = 0; i < 30; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the initial map activation dispatch.');
}

Future<RuntimePlayerPokemonProgressionCatalogs> _loadCatalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  return const RuntimePlayerPokemonProgressionCatalogs(
    speciesById: <String, PlayerPokemonHydrationSpecies>{
      'sproutle': PlayerPokemonHydrationSpecies(
        id: 'sproutle',
        baseStats: PokemonBaseStats(
          hp: 45,
          attack: 49,
          defense: 49,
          specialAttack: 65,
          specialDefense: 65,
          speed: 45,
        ),
        primaryAbilityId: 'overgrow',
        abilityIds: <String>['overgrow'],
        growthRateId: 'medium_slow',
      ),
      'wildmon': PlayerPokemonHydrationSpecies(
        id: 'wildmon',
        baseStats: PokemonBaseStats(
          hp: 40,
          attack: 45,
          defense: 40,
          specialAttack: 35,
          specialDefense: 35,
          speed: 56,
        ),
        primaryAbilityId: 'run_away',
        abilityIds: <String>['run_away'],
        growthRateId: 'medium_fast',
      ),
    },
    maxPpByMoveId: <String, int>{
      'tackle': 35,
      'scratch': 35,
    },
  );
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Music Battle Exits Test',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'test_field',
          name: 'Test Field',
          relativePath: 'maps/test_field.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
    ),
    map: const MapData(
      id: 'test_field',
      name: 'Test Field',
      size: GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_start',
          name: 'Spawn Start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      mapMetadata: MapMetadata(
        defaultSpawnId: 'spawn_start',
        musicPath: 'audio/town.ogg',
      ),
    ),
    projectRootDirectory: '/tmp/music_exit_project',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

RuntimeActiveBattleContext _wildContext() {
  return const RuntimeActiveBattleContext(
    request: WildBattleStartRequest(
      requestId: 'wild-music-exit',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'test_field',
        playerPos: GridPos(x: 2, y: 1),
        playerFacing: Direction.west,
      ),
      mapId: 'test_field',
      encounterSourceId: 'grass',
      encounterSourceKind: EncounterSourceKind.gameplayZone,
      tableId: 'field_grass',
      encounterKind: EncounterKind.walk,
      speciesId: 'wildmon',
      level: 7,
      minLevel: 7,
      maxLevel: 7,
      weight: 1,
      playerPos: GridPos(x: 2, y: 1),
    ),
    playerPartyIndex: 0,
  );
}

BattleSetup _captureSetup() {
  return const BattleSetup(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    playerPokemon: BattleCombatantData(
      speciesId: 'sproutle',
      level: 10,
      maxHp: 24,
      stats: _exitTestStats,
      moves: <BattleMoveData>[
        BattleMoveData(id: 'tackle', name: 'Tackle', power: 10),
      ],
    ),
    enemyPokemon: BattleCombatantData(
      speciesId: 'wildmon',
      level: 7,
      maxHp: 18,
      stats: _exitTestStats,
      catchRate: 255,
      moves: <BattleMoveData>[
        BattleMoveData(id: 'scratch', name: 'Scratch', power: 10),
      ],
    ),
    isTrainerBattle: false,
    trainerId: null,
    allowCapture: true,
  );
}

BattleOutcome _outcome(BattleOutcomeType type) {
  final playerCurrentHp = type == BattleOutcomeType.defeat ? 0 : 20;
  final enemyCurrentHp = type == BattleOutcomeType.victory ? 0 : 9;
  return BattleOutcome(
    type: type,
    captureItemId: type == BattleOutcomeType.captured ? 'poke_ball' : null,
    captureAttemptId:
        type == BattleOutcomeType.captured ? 'capture-music-exit' : null,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: BattleCombatant(
        speciesId: 'sproutle',
        level: 10,
        currentHp: playerCurrentHp,
        maxHp: 24,
        stats: _exitTestStats,
        moves: const <BattleMove>[
          BattleMove(id: 'tackle', name: 'Tackle', power: 10),
        ],
      ),
      enemy: BattleCombatant(
        speciesId: 'wildmon',
        level: 7,
        currentHp: enemyCurrentHp,
        maxHp: 18,
        stats: _exitTestStats,
        moves: const <BattleMove>[
          BattleMove(id: 'scratch', name: 'Scratch', power: 10),
        ],
      ),
      currentTurn: null,
      outcome: null,
    ),
  );
}
