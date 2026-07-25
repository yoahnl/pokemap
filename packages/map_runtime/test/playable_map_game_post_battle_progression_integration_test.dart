import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PlayableMapGame keeps battle locked and commits one win decision flow',
      () async {
    final coordinator = RuntimePostBattleDecisionCoordinator(
      resolveReward: _pendingMoveResolution,
    );
    final game = _TestPlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/post-battle/project.json',
      saveData: saveDataFromGameState(_state()),
      postBattleDecisionCoordinator: coordinator,
      runtimePlayerPokemonProgressionCatalogLoader: _loadCatalogs,
    );
    game.onGameResize(Vector2(640, 480));
    await game.onLoad();
    await _waitForActivationDispatch(game);
    await game.debugStartPostBattleForTest(
      context: _context(),
      outcome: _outcome(),
    );

    expect(game.debugPostBattleOverlayMounted, isTrue);
    expect(game.debugFlowPhaseName, 'battle');
    expect(game.debugIsBattleResolving, isTrue);
    expect(game.gameStateSnapshot.trainerProfile.money, 0);
    expect(game.gameStateSnapshot.party.members.single.currentHp, 15);
    final lockedPosition = game.debugPlayerGridPosition;
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.left),
      ),
      isTrue,
    );
    game.update(0.1);
    expect(game.debugPlayerGridPosition, lockedPosition);

    for (var index = 0; index < 3; index++) {
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
    }
    expect(game.debugPostBattleDecisionLabels,
        <String>['Apprendre', 'Ne pas apprendre']);
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.down),
      ),
      isTrue,
    );
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );

    expect(game.gameStateSnapshot.trainerProfile.money, 0,
        reason: 'No intermediate post-battle state may be published.');
    for (var index = 0; index < 3; index++) {
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
    }
    await game.debugWaitForPostBattleCompletion();

    final committed = game.gameStateSnapshot;
    expect(committed.party.members.single.currentHp, 9);
    expect(committed.party.members.single.experience, 335);
    expect(committed.party.members.single.knownMoveIds,
        <String>['tackle', 'growl', 'tail_whip', 'focus_energy']);
    expect(committed.trainerProfile.money, 100);
    expect(committed.storyFlags.activeFlags,
        contains('trainer_defeated:trainer_iris'));
    expect(game.debugPostBattleOverlayMounted, isFalse);
    expect(game.debugFlowPhaseName, 'overworld');
    expect(game.debugIsBattleResolving, isFalse);
  });

  test('failed post-battle resolution rolls back win and restores input',
      () async {
    final game = _TestPlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/post-battle/project.json',
      saveData: saveDataFromGameState(_state()),
      postBattleDecisionCoordinator: RuntimePostBattleDecisionCoordinator(
        resolveReward: _failingResolution,
      ),
      runtimePlayerPokemonProgressionCatalogLoader: _loadCatalogs,
    );
    game.onGameResize(Vector2(640, 480));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    await game.debugStartPostBattleForTest(
      context: _context(),
      outcome: _outcome(),
    );
    expect(game.debugPostBattleOverlayMounted, isTrue);
    expect(game.gameStateSnapshot.party.members.single.currentHp, 15);

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await game.debugWaitForPostBattleCompletion();

    final rolledBack = game.gameStateSnapshot;
    expect(rolledBack.party.members.single.currentHp, 15);
    expect(rolledBack.party.members.single.experience, 125);
    expect(rolledBack.trainerProfile.money, 0);
    expect(
      rolledBack.storyFlags.activeFlags,
      isNot(contains('trainer_defeated:trainer_iris')),
    );
    expect(game.debugPostBattleOverlayMounted, isFalse);
    expect(game.debugFlowPhaseName, 'overworld');
    expect(game.debugIsBattleResolving, isFalse);
  });

  test('final Flutter acknowledgement clears presentation and restores input',
      () async {
    final game = _TestPlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/post-battle/project.json',
      saveData: saveDataFromGameState(_state()),
      postBattleDecisionCoordinator: RuntimePostBattleDecisionCoordinator(
        resolveReward: _failingResolution,
      ),
      runtimePlayerPokemonProgressionCatalogLoader: _loadCatalogs,
    )..setPostBattleFlutterOverlayPreferred(true);
    game.onGameResize(Vector2(640, 480));
    await game.onLoad();
    await _waitForActivationDispatch(game);
    await game.debugStartPostBattleForTest(
      context: _context(),
      outcome: _outcome(),
    );

    final presentation = game.postBattlePresentationListenable.value;
    expect(presentation, isNotNull);
    expect(presentation!.completed, isFalse);
    expect(
      game.dispatchPostBattlePresentationCommand(
        PostBattleAdvanceCommand(
          snapshotRevision: presentation.revision,
        ),
      ),
      isTrue,
    );
    await game.debugWaitForPostBattleCompletion();

    expect(game.postBattlePresentationListenable.value, isNull);
    expect(game.debugPostBattleOverlayMounted, isFalse);
    expect(game.debugFlowPhaseName, 'overworld');
    expect(game.debugIsBattleResolving, isFalse);

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      ),
      isTrue,
    );
    game.update(0.016);
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      ),
      isTrue,
    );
    await _waitForPlayerStep(game);
    expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
  });

  test('failed overlay mount rolls back and completes without a softlock',
      () async {
    final game = _TestPlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/post-battle/project.json',
      saveData: saveDataFromGameState(_state()),
      postBattleDecisionCoordinator: RuntimePostBattleDecisionCoordinator(
        resolveReward: _pendingMoveResolution,
      ),
      runtimePlayerPokemonProgressionCatalogLoader: _loadCatalogs,
      postBattleOverlayMounter: (_) async {
        throw StateError('overlay mount failed');
      },
    );
    game.onGameResize(Vector2(640, 480));
    await game.onLoad();
    await _waitForActivationDispatch(game);
    final stateBeforePostBattle = game.gameStateSnapshot;

    await game.debugStartPostBattleForTest(
      context: _context(),
      outcome: _outcome(),
    );
    await game.debugWaitForPostBattleCompletion();

    expect(game.gameStateSnapshot, stateBeforePostBattle);
    expect(game.debugPostBattleOverlayMounted, isFalse);
    expect(game.debugFlowPhaseName, 'overworld');
    expect(game.debugIsBattleResolving, isFalse);
  });

  test('failed final commit rolls back, completes, and permits a retry',
      () async {
    var commitAttempts = 0;
    final game = _TestPlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/post-battle/project.json',
      saveData: saveDataFromGameState(_state()),
      postBattleDecisionCoordinator: RuntimePostBattleDecisionCoordinator(
        resolveReward: _pendingMoveResolution,
      ),
      runtimePlayerPokemonProgressionCatalogLoader: _loadCatalogs,
      beforePostBattleStateCommit: () {
        commitAttempts += 1;
        throw StateError('commit failed');
      },
    );
    game.onGameResize(Vector2(640, 480));
    await game.onLoad();
    await _waitForActivationDispatch(game);
    final stateBeforePostBattle = game.gameStateSnapshot;

    for (var attempt = 1; attempt <= 2; attempt++) {
      await game.debugStartPostBattleForTest(
        context: _context(),
        outcome: _outcome(),
      );
      await _acknowledgePostBattle(game);

      expect(commitAttempts, attempt);
      expect(game.gameStateSnapshot, stateBeforePostBattle);
      expect(game.debugPostBattleOverlayMounted, isFalse);
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsBattleResolving, isFalse);
    }
  });

  test('failed capture commit leaves its receipt reusable for one retry',
      () async {
    final captureContext = _captureContext();
    final capture = _successfulCaptureSubmission(
      state: _captureState(),
      context: captureContext,
    );
    var failCommit = true;
    final game = _TestPlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/post-battle/project.json',
      saveData: saveDataFromGameState(capture.updatedGameState),
      postBattleDecisionCoordinator: RuntimePostBattleDecisionCoordinator(),
      runtimePlayerPokemonProgressionCatalogLoader: _loadCatalogs,
      beforePostBattleStateCommit: () {
        if (failCommit) throw StateError('capture commit failed');
      },
    );
    game.onGameResize(Vector2(640, 480));
    await game.onLoad();
    await _waitForActivationDispatch(game);
    final stateBeforePostBattle = game.gameStateSnapshot;
    final outcome = capture.engineResult.state.outcome!;

    await game.debugStartPostBattleForTest(
      context: captureContext,
      outcome: outcome,
      captureAttemptReceipt: capture.receipt,
    );
    await _acknowledgePostBattle(game);
    expect(game.gameStateSnapshot, stateBeforePostBattle);
    expect(game.gameStateSnapshot.party.members, hasLength(1));

    failCommit = false;
    await game.debugStartPostBattleForTest(
      context: captureContext,
      outcome: outcome,
      captureAttemptReceipt: capture.receipt,
    );
    await _acknowledgePostBattle(game);

    expect(game.gameStateSnapshot.party.members, hasLength(2));
    expect(game.gameStateSnapshot.party.members.last.speciesId, 'foe');
    expect(game.debugFlowPhaseName, 'overworld');
    expect(game.debugIsBattleResolving, isFalse);
  });
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveData,
    required super.postBattleDecisionCoordinator,
    required super.runtimePlayerPokemonProgressionCatalogLoader,
    super.postBattleOverlayMounter,
    super.beforePostBattleStateCommit,
  });

  @override
  bool get isLoaded => true;
}

Future<void> _acknowledgePostBattle(PlayableMapGame game) async {
  for (var index = 0;
      index < 64 && game.debugPostBattleOverlayMounted;
      index++) {
    expect(game.debugValidatePostBattleChoice(), isTrue);
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  if (game.debugPostBattleOverlayMounted) {
    fail('Post-battle acknowledgement exceeded 64 inputs.');
  }
  await game.debugWaitForPostBattleCompletion();
}

RuntimeActiveBattleContext _captureContext() {
  return RuntimeActiveBattleContext.withLineupMapping(
    request: const WildBattleStartRequest(
      requestId: 'capture',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'route',
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.south,
      ),
      mapId: 'route',
      zoneId: 'grass',
      tableId: 'grass',
      encounterKind: EncounterKind.walk,
      speciesId: 'foe',
      level: 10,
      minLevel: 10,
      maxLevel: 10,
      weight: 1,
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: 0,
    playerPartySlotIndicesByLineupIndex: const <int>[0],
  );
}

GameState _captureState() {
  return _state().copyWith(
    bag: const Bag(
      entries: <BagEntry>[
        BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
      ],
    ),
  );
}

RuntimeBattleCaptureAttemptSubmission<BattleSession>
    _successfulCaptureSubmission({
  required GameState state,
  required RuntimeActiveBattleContext context,
}) {
  return submitRuntimeBattleCaptureAttempt<BattleSession>(
    gameState: state,
    context: context,
    captureAllowed: true,
    submitToEngine: () => createBattleSession(
      const BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'hero',
          level: 5,
          maxHp: 19,
          stats: BattleStatsSnapshot(
            attack: 10,
            defense: 10,
            specialAttack: 10,
            specialDefense: 10,
            speed: 10,
          ),
          moves: <BattleMoveData>[
            BattleMoveData(id: 'tackle', name: 'Charge', power: 40),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'foe',
          level: 10,
          maxHp: 100,
          currentHp: 1,
          catchRate: 255,
          majorStatus: BattleMajorStatusState.slp(),
          abilityId: 'foe_power',
          stats: BattleStatsSnapshot(
            attack: 10,
            defense: 10,
            specialAttack: 10,
            specialDefense: 10,
            speed: 10,
          ),
          moves: <BattleMoveData>[
            BattleMoveData(id: 'wait', name: 'Wait', power: 0),
          ],
        ),
        allowCapture: true,
        isTrainerBattle: false,
        trainerId: null,
      ),
      rng: const BattleScriptedRng(<int>[1]),
    ).applyChoice(const PlayerBattleChoiceCapture()),
  );
}

Future<RuntimePlayerPokemonProgressionCatalogs> _loadCatalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  return const RuntimePlayerPokemonProgressionCatalogs(
    growthRateIdBySpeciesId: <String, String>{'hero': 'medium'},
    maxPpByMoveId: <String, int>{
      'tackle': 35,
      'growl': 40,
      'tail_whip': 30,
      'focus_energy': 30,
    },
  );
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var index = 0; index < 240; index++) {
    if (!game.debugIsMapActivationDispatchInFlight) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the initial activation.');
}

Future<void> _waitForPlayerStep(PlayableMapGame game) async {
  for (var index = 0; index < 240; index++) {
    if (!game.debugIsPlayerStepping) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for player movement after post-battle cleanup.');
}

Future<RuntimeBattleRewardResolution> _pendingMoveResolution({
  required RuntimeMapBundle bundle,
  required GameState postWriteBackState,
  required RuntimeActiveBattleContext runtimeContext,
  required BattleOutcome outcome,
}) async {
  final reward = BattleReward(
    sourceKind: BattleRewardSourceKind.trainer,
    trainerId: 'trainer_iris',
    money: 100,
  );
  final context = BattleProgressionContext(
    outcome: BattleProgressionOutcomeKind.victory,
    playerParticipantPartySlots: const <int>{0},
    defeatedOpponents: const <BattleProgressionDefeatedOpponent>[
      BattleProgressionDefeatedOpponent(level: 14, baseExperience: 70),
    ],
    partySlotMetadata: const <BattleProgressionPartySlotMetadata>[
      BattleProgressionPartySlotMetadata(
        partySlot: 0,
        growthRateId: 'medium',
        oldMaxHp: 19,
        baseStats: PokemonBaseStats(
          hp: 45,
          attack: 49,
          defense: 49,
          specialAttack: 65,
          specialDefense: 65,
          speed: 45,
        ),
      ),
    ],
    moveLearningCandidatesByPartySlot: const <int,
        Iterable<PokemonMoveLearningCandidate>>{
      0: <PokemonMoveLearningCandidate>[
        PokemonMoveLearningCandidate(
          opportunityId: 'hero:6:quick_attack',
          moveId: 'quick_attack',
          learnedAtLevel: 6,
          maxPp: 30,
        ),
      ],
    },
  );
  return RuntimeBattleRewardResolution(
    baseState: postWriteBackState,
    reward: reward,
    progressionContext: context,
    progression: const BattleProgressionService().apply(
      state: postWriteBackState,
      context: context,
      reward: reward,
      applyAuthoredRewards: false,
    ),
  );
}

Future<RuntimeBattleRewardResolution> _failingResolution({
  required RuntimeMapBundle bundle,
  required GameState postWriteBackState,
  required RuntimeActiveBattleContext runtimeContext,
  required BattleOutcome outcome,
}) async {
  throw const RuntimePostBattleResolutionException(
    code: RuntimePostBattleResolutionErrorCode.missingCatalogueData,
    message: 'Catalogue post-combat indisponible.',
  );
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Post battle game fixture',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'route',
          name: 'Route',
          relativePath: 'maps/route.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
      trainers: <ProjectTrainerEntry>[
        ProjectTrainerEntry(
          id: 'trainer_iris',
          name: 'Iris',
          trainerClass: 'Rivale',
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
    ),
    map: const MapData(
      id: 'route',
      name: 'Route',
      size: GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/post-battle',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

GameState _state() {
  return const GameState(
    saveId: 'post-battle-game',
    currentMapId: 'route',
    playerPosition: GridPos(x: 1, y: 1),
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'hero',
          natureId: 'hardy',
          abilityId: 'hero_power',
          level: 5,
          knownMoveIds: <String>[
            'tackle',
            'growl',
            'tail_whip',
            'focus_energy',
          ],
          currentPpByMoveId: <String, int>{
            'tackle': 35,
            'growl': 40,
            'tail_whip': 30,
            'focus_energy': 30,
          },
          experience: 125,
          currentHp: 15,
        ),
      ],
    ),
  );
}

RuntimeActiveBattleContext _context() {
  return RuntimeActiveBattleContext.withLineupMapping(
    request: const TrainerBattleStartRequest(
      requestId: 'trainer',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'route',
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.south,
      ),
      mapId: 'route',
      trainerId: 'trainer_iris',
      npcEntityId: 'npc_iris',
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: 0,
    playerPartySlotIndicesByLineupIndex: const <int>[0],
  );
}

BattleOutcome _outcome() {
  return BattleOutcome(
    type: BattleOutcomeType.victory,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: _combatant('hero', level: 5, currentHp: 7),
      enemy: _combatant('foe', level: 14, currentHp: 0),
      playerParticipantLineupIndexes: const <int>{0},
    ),
  );
}

BattleCombatant _combatant(
  String speciesId, {
  required int level,
  required int currentHp,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    lineupIndex: 0,
    level: level,
    currentHp: currentHp,
    maxHp: 19,
    stats: const BattleStatsSnapshot(
      attack: 10,
      defense: 10,
      specialAttack: 10,
      specialDefense: 10,
      speed: 10,
    ),
    moves: const <BattleMove>[
      BattleMove(id: 'tackle', name: 'Charge', power: 40, currentPp: 30),
      BattleMove(id: 'growl', name: 'Grognement', power: 0, currentPp: 35),
      BattleMove(id: 'tail_whip', name: 'Mimi-Queue', power: 0, currentPp: 25),
      BattleMove(
        id: 'focus_energy',
        name: 'Puissance',
        power: 0,
        currentPp: 25,
      ),
    ],
  );
}
