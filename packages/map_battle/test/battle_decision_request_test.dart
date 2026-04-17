import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleMoveData _waitingMove() {
  return const BattleMoveData(
    id: 'wait',
    name: 'Wait',
    power: 0,
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.self,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
  bool allowCapture = false,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
      allowCapture: allowCapture,
    ),
  );
}

void main() {
  group('BattleSession Phase C decision requests', () {
    test('a free turn exposes a turn choice request with moves and switches',
        () {
      final session = _session(
        allowCapture: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
            ),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleTurnChoiceRequest>());
      final turnChoiceRequest = request as BattleTurnChoiceRequest;
      expect(turnChoiceRequest.actor, equals(BattleDecisionActor.player));
      expect(turnChoiceRequest.side, equals(BattleSideId.player));
      expect(
        turnChoiceRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(turnChoiceRequest.moveChoices, hasLength(1));
      expect(turnChoiceRequest.switchChoices, hasLength(1));
      expect(turnChoiceRequest.captureChoice, isA<PlayerBattleChoiceCapture>());
      expect(turnChoiceRequest.runChoice, isA<PlayerBattleChoiceRun>());
    });

    test('a fainted active with a reserve exposes a forced replacement request',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleForcedReplacementRequest>());
      final forcedReplacementRequest =
          request as BattleForcedReplacementRequest;
      expect(forcedReplacementRequest.side, equals(BattleSideId.player));
      expect(
        forcedReplacementRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(
        forcedReplacementRequest.reason,
        equals(BattleForcedReplacementReason.activeFainted),
      );
      expect(forcedReplacementRequest.switchChoices, hasLength(1));
      expect(
        forcedReplacementRequest.allowedChoices.single,
        isA<PlayerBattleChoiceSwitch>(),
      );
    });

    test('a forced recharge exposes a continue request with an explicit reason',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleContinueRequest>());
      final continueRequest = request as BattleContinueRequest;
      expect(continueRequest.side, equals(BattleSideId.player));
      expect(
        continueRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(
        continueRequest.reason,
        equals(BattleContinueReason.mustRecharge),
      );
      expect(continueRequest.allowedChoices, hasLength(1));
      expect(continueRequest.allowedChoices.single,
          isA<PlayerBattleChoiceContinue>());
    });

    test('request constructors reject mismatched side and slot attachments',
        () {
      expect(
        () => BattleContinueRequest(
          actor: BattleDecisionActor.player,
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          reason: BattleContinueReason.mustRecharge,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => BattleWaitRequest(
          actor: BattleDecisionActor.player,
          side: BattleSideId.player,
          slot: const BattleSlotRef(
            side: BattleSideId.player,
            slotIndex: 1,
          ),
          reason: BattleWaitReason.noLegalChoice,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('an illegal choice for the current request kind is rejected cleanly',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('forcedReplacement'),
          ),
        ),
      );
    });

    test('request transitions remain coherent across a forced continue turn',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(session.decisionRequest, isA<BattleContinueRequest>());

      final afterContinue =
          session.applyChoice(const PlayerBattleChoiceContinue());

      expect(afterContinue.decisionRequest, isA<BattleTurnChoiceRequest>());
    });

    test('a finished battle exposes an explicit wait request', () {
      final session = _session(
        player: _combatant(
          speciesId: 'player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 200,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          maxHp: 1,
          currentHp: 1,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final finishedSession =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(finishedSession.state.isFinished, isTrue);
      expect(finishedSession.decisionRequest, isA<BattleWaitRequest>());
      expect(
        (finishedSession.decisionRequest as BattleWaitRequest).reason,
        equals(BattleWaitReason.battleFinished),
      );
    });
  });
}
