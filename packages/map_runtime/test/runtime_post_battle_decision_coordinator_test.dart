import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimePostBattleDecisionCoordinator', () {
    test('commits trainer rewards only after move and evolution decisions',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _trainerResolutionWithPendingMoveAndEvolution,
      );
      final base = _state(knownMoves: const <String>[
        'tackle',
        'growl',
        'tail_whip',
        'focus_energy',
      ]);
      final outcome = _outcome();

      final started = await coordinator.begin(
        transactionBaseState: base,
        bundle: _bundle(),
        runtimeContext: _context(_trainerRequest()),
        outcome: outcome,
      );

      expect(started.isSuccess, isTrue);
      var transaction = started.transaction!;
      expect(transaction.finalState, isNull);
      expect(transaction.pendingMoveLearning, isNotNull);
      expect(transaction.pendingEvolution, isNull);
      expect(
        transaction.messages.map((message) => message.kind),
        <RuntimePostBattleMessageKind>[
          RuntimePostBattleMessageKind.victory,
          RuntimePostBattleMessageKind.experience,
          RuntimePostBattleMessageKind.levelUp,
          RuntimePostBattleMessageKind.moveLearningPrompt,
        ],
      );
      expect(base.trainerProfile.money, 0);
      expect(base.storyFlags.activeFlags, isEmpty);

      final pendingMove = transaction.pendingMoveLearning!;
      final accepted = coordinator.resolveMoveLearning(
        transaction: transaction,
        decision: BattleMoveLearningDecision.learn(
          opportunityId: pendingMove.opportunityId,
          partySlot: pendingMove.partySlot,
          moveId: pendingMove.candidate.moveId,
        ),
      );
      expect(accepted.isSuccess, isTrue);
      transaction = accepted.transaction!;
      expect(
        transaction.pendingMoveLearning!.phase,
        BattleMoveLearningPhase.awaitingReplacement,
      );
      expect(transaction.messages.last.kind,
          RuntimePostBattleMessageKind.moveReplacementPrompt);

      final replacement = transaction.pendingMoveLearning!;
      final replaced = coordinator.resolveMoveLearning(
        transaction: transaction,
        decision: BattleMoveLearningDecision.replace(
          opportunityId: replacement.opportunityId,
          partySlot: replacement.partySlot,
          moveId: replacement.candidate.moveId,
          replaceMoveIndex: 1,
          expectedReplacedMoveId: 'growl',
        ),
      );
      expect(replaced.isSuccess, isTrue);
      transaction = replaced.transaction!;
      expect(transaction.pendingMoveLearning, isNull);
      expect(transaction.pendingEvolution, isNotNull);
      expect(
        transaction.messages
            .skip(transaction.messages.length - 2)
            .map((message) => message.kind),
        <RuntimePostBattleMessageKind>[
          RuntimePostBattleMessageKind.moveReplaced,
          RuntimePostBattleMessageKind.evolutionPrompt,
        ],
      );

      final pendingEvolution = transaction.pendingEvolution!;
      final evolved = coordinator.resolveEvolution(
        transaction: transaction,
        decision: BattleEvolutionDecision.accept(
          opportunityId: pendingEvolution.opportunityId,
          occurrenceId: pendingEvolution.occurrenceId,
          partySlot: pendingEvolution.partySlot,
          sourceSpeciesId: pendingEvolution.sourceSpeciesId,
          targetSpeciesId: pendingEvolution.targetSpeciesId,
        ),
      );

      expect(evolved.isSuccess, isTrue);
      transaction = evolved.transaction!;
      expect(transaction.isReadyToCommit, isTrue);
      final finalState = transaction.finalState!;
      expect(finalState.party.members.single.speciesId, 'hero_evolved');
      expect(finalState.party.members.single.knownMoveIds,
          <String>['tackle', 'quick_attack', 'tail_whip', 'focus_energy']);
      expect(finalState.party.members.single.currentHp, 10);
      expect(finalState.trainerProfile.money, 480);
      expect(finalState.bag.entries.single.itemId, 'potion');
      expect(finalState.bag.entries.single.quantity, 2);
      expect(finalState.storyFlags.activeFlags, contains('story:iris_won'));
      expect(
        finalState.storyFlags.activeFlags,
        contains('trainer_defeated:trainer_iris'),
      );
      expect(
        transaction.messages
            .skip(transaction.messages.length - 5)
            .map((message) => message.kind),
        <RuntimePostBattleMessageKind>[
          RuntimePostBattleMessageKind.evolutionAccepted,
          RuntimePostBattleMessageKind.money,
          RuntimePostBattleMessageKind.item,
          RuntimePostBattleMessageKind.flag,
          RuntimePostBattleMessageKind.trainerDefeated,
        ],
      );
    });

    test('refusing move and evolution preserves the exact alternatives',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _trainerResolutionWithPendingMoveAndEvolution,
      );
      var transaction = (await coordinator.begin(
        transactionBaseState: _state(knownMoves: const <String>[
          'tackle',
          'growl',
          'tail_whip',
          'focus_energy',
        ]),
        bundle: _bundle(),
        runtimeContext: _context(_trainerRequest()),
        outcome: _outcome(),
      ))
          .transaction!;
      final pendingMove = transaction.pendingMoveLearning!;
      transaction = coordinator
          .resolveMoveLearning(
            transaction: transaction,
            decision: BattleMoveLearningDecision.decline(
              opportunityId: pendingMove.opportunityId,
              partySlot: pendingMove.partySlot,
              moveId: pendingMove.candidate.moveId,
            ),
          )
          .transaction!;
      expect(transaction.messages.last.kind,
          RuntimePostBattleMessageKind.evolutionPrompt);
      expect(
        transaction.messages.any((message) =>
            message.kind == RuntimePostBattleMessageKind.moveDeclined),
        isTrue,
      );
      final pendingEvolution = transaction.pendingEvolution!;
      transaction = coordinator
          .resolveEvolution(
            transaction: transaction,
            decision: BattleEvolutionDecision.refuse(
              opportunityId: pendingEvolution.opportunityId,
              occurrenceId: pendingEvolution.occurrenceId,
              partySlot: pendingEvolution.partySlot,
              sourceSpeciesId: pendingEvolution.sourceSpeciesId,
              targetSpeciesId: pendingEvolution.targetSpeciesId,
            ),
          )
          .transaction!;

      expect(transaction.finalState!.party.members.single.speciesId, 'hero');
      expect(transaction.finalState!.party.members.single.knownMoveIds,
          <String>['tackle', 'growl', 'tail_whip', 'focus_energy']);
      expect(
        transaction.messages.any((message) =>
            message.kind == RuntimePostBattleMessageKind.evolutionRefused),
        isTrue,
      );
    });

    test('automatic move and every crossed level are visible before rewards',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _multiLevelAutomaticMoveResolution,
      );
      final started = await coordinator.begin(
        transactionBaseState: _state(),
        bundle: _bundle(),
        runtimeContext: _context(_trainerRequest()),
        outcome: _outcome(),
      );

      final transaction = started.transaction!;
      expect(transaction.isReadyToCommit, isTrue);
      expect(
        transaction.messages.map((message) => message.kind),
        <RuntimePostBattleMessageKind>[
          RuntimePostBattleMessageKind.victory,
          RuntimePostBattleMessageKind.experience,
          RuntimePostBattleMessageKind.levelUp,
          RuntimePostBattleMessageKind.levelUp,
          RuntimePostBattleMessageKind.levelUp,
          RuntimePostBattleMessageKind.moveAutomaticallyLearned,
          RuntimePostBattleMessageKind.money,
          RuntimePostBattleMessageKind.item,
          RuntimePostBattleMessageKind.flag,
          RuntimePostBattleMessageKind.trainerDefeated,
        ],
      );
    });

    test('resolver failure rolls back to the original transaction base',
        () async {
      const failure = RuntimePostBattleResolutionException(
        code: RuntimePostBattleResolutionErrorCode.missingCatalogueData,
        message: 'missing species',
      );
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: ({
          required bundle,
          required postWriteBackState,
          required runtimeContext,
          required outcome,
        }) async =>
            throw failure,
      );
      final base = _state();

      final started = await coordinator.begin(
        transactionBaseState: base,
        bundle: _bundle(),
        runtimeContext: _context(_trainerRequest()),
        outcome: _outcome(),
      );

      expect(started.isSuccess, isFalse);
      expect(started.failure!.code,
          RuntimePostBattleCoordinatorFailureCode.rewardResolution);
      expect(started.failure!.originalState, same(base));
      expect(base.party.members.single.currentHp, 15);
      expect(base.trainerProfile.money, 0);
      expect(base.storyFlags.activeFlags, isEmpty);
    });

    test('duplicate completion and mismatched decisions do not mutate state',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _trainerResolutionWithPendingMoveAndEvolution,
      );
      final original = _state(knownMoves: const <String>[
        'tackle',
        'growl',
        'tail_whip',
        'focus_energy',
      ]);
      final transaction = (await coordinator.begin(
        transactionBaseState: original,
        bundle: _bundle(),
        runtimeContext: _context(_trainerRequest()),
        outcome: _outcome(),
      ))
          .transaction!;

      final failed = coordinator.resolveMoveLearning(
        transaction: transaction,
        decision: const BattleMoveLearningDecision.decline(
          opportunityId: 'wrong',
          partySlot: 0,
          moveId: 'quick_attack',
        ),
      );

      expect(failed.isSuccess, isFalse);
      expect(failed.failure!.code,
          RuntimePostBattleCoordinatorFailureCode.invalidDecision);
      expect(failed.failure!.originalState, same(original));
      expect(failed.transaction, same(transaction));
    });

    for (final type in <BattleOutcomeType>[
      BattleOutcomeType.defeat,
      BattleOutcomeType.runaway,
    ]) {
      test('${type.name} writes back battle state without any reward',
          () async {
        var resolverCalled = false;
        final coordinator = RuntimePostBattleDecisionCoordinator(
          resolveReward: ({
            required bundle,
            required postWriteBackState,
            required runtimeContext,
            required outcome,
          }) async {
            resolverCalled = true;
            throw StateError('must not resolve rewards');
          },
        );
        final base = _state();
        final started = await coordinator.begin(
          transactionBaseState: base,
          bundle: _bundle(),
          runtimeContext: _context(_wildRequest()),
          outcome: _outcome(type: type),
        );

        expect(started.isSuccess, isTrue);
        expect(started.transaction!.isReadyToCommit, isTrue);
        expect(
            started.transaction!.finalState!.party.members.single.currentHp, 7);
        expect(started.transaction!.finalState!.trainerProfile.money, 0);
        expect(
            started.transaction!.finalState!.storyFlags.activeFlags, isEmpty);
        expect(resolverCalled, isFalse);
        expect(
          started.transaction!.messages.single.kind,
          type == BattleOutcomeType.defeat
              ? RuntimePostBattleMessageKind.defeat
              : RuntimePostBattleMessageKind.fled,
        );
      });
    }

    test('capture stays replayable until the caller commits its receipt once',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator();

      final partyCapture = _successfulCaptureSubmission(
        state: _captureState(partySize: 1),
      );
      final partyResult = await coordinator.begin(
        transactionBaseState: partyCapture.updatedGameState,
        bundle: _bundle(),
        runtimeContext: _captureContext(),
        outcome: partyCapture.engineResult.state.outcome!,
        captureAttemptReceipt: partyCapture.receipt,
      );
      expect(partyResult.isSuccess, isTrue);
      expect(partyResult.transaction!.captureDestination!.destination,
          CaptureDestinationKind.party);
      expect(partyResult.transaction!.finalState!.party.members.length, 2);
      expect(partyResult.transaction!.messages.last.text, contains('équipe'));

      final previewReplay = await coordinator.begin(
        transactionBaseState: partyCapture.updatedGameState,
        bundle: _bundle(),
        runtimeContext: _captureContext(),
        outcome: partyCapture.engineResult.state.outcome!,
        captureAttemptReceipt: partyCapture.receipt,
      );
      expect(previewReplay.isSuccess, isTrue);
      expect(partyCapture.updatedGameState.party.members, hasLength(1));

      commitRuntimeBattleCaptureAttemptReceipt(
        context: _captureContext(),
        outcome: partyCapture.engineResult.state.outcome!,
        receipt: partyCapture.receipt,
      );

      final committedReplay = await coordinator.begin(
        transactionBaseState: partyCapture.updatedGameState,
        bundle: _bundle(),
        runtimeContext: _captureContext(),
        outcome: partyCapture.engineResult.state.outcome!,
        captureAttemptReceipt: partyCapture.receipt,
      );
      expect(committedReplay.isSuccess, isFalse);
      expect(
        committedReplay.failure!.originalState,
        same(partyCapture.updatedGameState),
      );

      final storageCapture = _successfulCaptureSubmission(
        state: _captureState(partySize: 6),
      );
      final storageResult = await coordinator.begin(
        transactionBaseState: storageCapture.updatedGameState,
        bundle: _bundle(),
        runtimeContext: _captureContext(),
        outcome: storageCapture.engineResult.state.outcome!,
        captureAttemptReceipt: storageCapture.receipt,
      );
      expect(storageResult.transaction!.captureDestination!.destination,
          CaptureDestinationKind.storage);
      expect(storageResult.transaction!.finalState!.party.members.length, 6);
      expect(
          storageResult.transaction!.finalState!.pokemonStorage.storedPokemon,
          hasLength(1));
      expect(
          storageResult.transaction!.messages.last.text, contains('stockage'));
    });

    test('final trainer transaction survives a save JSON roundtrip', () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _multiLevelAutomaticMoveResolution,
      );
      final transaction = (await coordinator.begin(
        transactionBaseState: _state(),
        bundle: _bundle(),
        runtimeContext: _context(_trainerRequest()),
        outcome: _outcome(),
      ))
          .transaction!;

      final restored = GameState.fromJson(transaction.finalState!.toJson());

      expect(restored, transaction.finalState);
      expect(restored.trainerProfile.money, 480);
      expect(
          restored.storyFlags.activeFlags,
          containsAll(
              <String>['story:iris_won', 'trainer_defeated:trainer_iris']));
      expect(
          restored.party.members.single.knownMoveIds, contains('quick_attack'));
    });
  });
}

Future<RuntimeBattleRewardResolution>
    _trainerResolutionWithPendingMoveAndEvolution({
  required RuntimeMapBundle bundle,
  required GameState postWriteBackState,
  required RuntimeActiveBattleContext runtimeContext,
  required BattleOutcome outcome,
}) async {
  final reward = _trainerReward();
  final context = BattleProgressionContext(
    outcome: BattleProgressionOutcomeKind.victory,
    playerParticipantPartySlots: const <int>{0},
    defeatedOpponents: const <BattleProgressionDefeatedOpponent>[
      BattleProgressionDefeatedOpponent(level: 14, baseExperience: 70),
    ],
    partySlotMetadata: <BattleProgressionPartySlotMetadata>[_metadata()],
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
    evolutionCandidatesByPartySlot: <int, Iterable<PokemonEvolutionCandidate>>{
      0: <PokemonEvolutionCandidate>[_evolutionCandidate()],
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

Future<RuntimeBattleRewardResolution> _multiLevelAutomaticMoveResolution({
  required RuntimeMapBundle bundle,
  required GameState postWriteBackState,
  required RuntimeActiveBattleContext runtimeContext,
  required BattleOutcome outcome,
}) async {
  final reward = _trainerReward();
  final context = BattleProgressionContext(
    outcome: BattleProgressionOutcomeKind.victory,
    playerParticipantPartySlots: const <int>{0},
    defeatedOpponents: const <BattleProgressionDefeatedOpponent>[
      BattleProgressionDefeatedOpponent(level: 20, baseExperience: 100),
    ],
    partySlotMetadata: <BattleProgressionPartySlotMetadata>[_metadata()],
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

BattleReward _trainerReward() {
  return BattleReward(
    sourceKind: BattleRewardSourceKind.trainer,
    trainerId: 'trainer_iris',
    money: 480,
    itemGrants: const <BattleRewardItemGrant>[
      BattleRewardItemGrant(itemId: 'potion', quantity: 2),
    ],
    flagIds: const <String>['story:iris_won'],
  );
}

BattleProgressionPartySlotMetadata _metadata() {
  return const BattleProgressionPartySlotMetadata(
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
  );
}

PokemonEvolutionCandidate _evolutionCandidate() {
  return PokemonEvolutionCandidate(
    opportunityId: 'hero:6:hero_evolved',
    sourceSpeciesId: 'hero',
    targetSpeciesId: 'hero_evolved',
    minLevel: 6,
    targetBaseStats: const PokemonBaseStats(
      hp: 60,
      attack: 62,
      defense: 63,
      specialAttack: 80,
      specialDefense: 80,
      speed: 60,
    ),
    targetPrimaryAbilityId: 'hero_power',
    targetAbilityIds: const <String>['hero_power'],
  );
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Coordinator fixture',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(id: 'route', name: 'Route', relativePath: 'route.json'),
      ],
      tilesets: <ProjectTilesetEntry>[],
      trainers: <ProjectTrainerEntry>[
        ProjectTrainerEntry(
          id: 'trainer_iris',
          name: 'Iris',
          trainerClass: 'Rivale',
        ),
      ],
    ),
    map: const MapData(
      id: 'route',
      name: 'Route',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[],
    ),
    projectRootDirectory: '/tmp/coordinator-fixture',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

GameState _state({List<String> knownMoves = const <String>['tackle']}) {
  return GameState(
    saveId: 'coordinator',
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'hero',
          natureId: 'hardy',
          abilityId: 'hero_power',
          level: 5,
          knownMoveIds: knownMoves,
          currentPpByMoveId: <String, int>{
            for (final move in knownMoves) move: 35,
          },
          experience: 125,
          currentHp: 15,
        ),
      ],
    ),
  );
}

RuntimeActiveBattleContext _context(BattleStartRequest request) {
  return RuntimeActiveBattleContext.withLineupMapping(
    request: request,
    playerPartyIndex: 0,
    playerPartySlotIndicesByLineupIndex: const <int>[0],
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
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
  );
}

BattleOutcome _outcome({
  BattleOutcomeType type = BattleOutcomeType.victory,
}) {
  return BattleOutcome(
    type: type,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: _combatant('hero', level: 5, currentHp: 7),
      enemy: _combatant('foe', level: 14, currentHp: 0),
      playerParticipantLineupIndexes: const <int>{0},
    ),
  );
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'wild',
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
    level: 14,
    minLevel: 14,
    maxLevel: 14,
    weight: 1,
    playerPos: GridPos(x: 1, y: 1),
  );
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
      speciesId: 'capture_target',
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

GameState _captureState({required int partySize}) {
  return GameState(
    saveId: 'capture-state',
    bag: const Bag(
      entries: <BagEntry>[
        BagEntry(itemId: 'poke-ball', quantity: 2),
      ],
    ),
    party: PlayerParty(
      members: <PlayerPokemon>[
        for (var index = 0; index < partySize; index++)
          PlayerPokemon(
            speciesId: index == 0 ? 'capture_player' : 'bench_$index',
            natureId: 'hardy',
            abilityId: 'steady',
            level: 10,
            knownMoveIds: const <String>['wait'],
            currentPpByMoveId: const <String, int>{'wait': 35},
            currentHp: 30,
          ),
      ],
    ),
  );
}

RuntimeBattleCaptureAttemptSubmission<BattleSession>
    _successfulCaptureSubmission({required GameState state}) {
  return submitRuntimeBattleCaptureAttempt<BattleSession>(
    gameState: state,
    context: _captureContext(),
    captureAllowed: true,
    itemId: canonicalPokeBallItemId,
    itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
    submitToEngine: () => createBattleSession(
      const BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'capture_player',
          level: 10,
          maxHp: 30,
          stats: BattleStatsSnapshot(
            attack: 20,
            defense: 20,
            specialAttack: 20,
            specialDefense: 20,
            speed: 20,
          ),
          moves: <BattleMoveData>[
            BattleMoveData(id: 'wait', name: 'Wait', power: 0),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'capture_target',
          level: 10,
          maxHp: 100,
          currentHp: 1,
          catchRate: 255,
          majorStatus: BattleMajorStatusState.slp(),
          abilityId: 'wild_power',
          stats: BattleStatsSnapshot(
            attack: 20,
            defense: 20,
            specialAttack: 20,
            specialDefense: 20,
            speed: 20,
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
      BattleMove(
        id: 'tackle',
        name: 'Charge',
        type: 'normal',
        pp: 35,
        currentPp: 30,
        power: 40,
      ),
    ],
  );
}
