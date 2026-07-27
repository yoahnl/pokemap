import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('unified battle decision contract', () {
    test('wild turn exposes flee through the canonical request', () {
      final engine = BattleEngine(
        setup: _setup(canFlee: true),
      );

      final request = engine.currentRequest;

      expect(request.kind, BattleEngineDecisionRequestKind.turnChoice);
      expect(request.canFlee, isTrue);
      expect(request.allowedDecisions, contains(isA<BattleFleeDecision>()));
      expect(request.allows(const BattleDecision.flee()), isTrue);
    });

    test('trainer turn rejects flee atomically', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(isTrainerBattle: true),
      );
      final before = session.state;

      expect(session.decisionRequest.canFlee, isFalse);
      expect(
        () => session.submit(const BattleDecision.flee()),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(session.state.turnNumber, before.turnNumber);
      expect(
        session.state.battlerAt(psdkPlayerSlot).currentHp,
        before.battlerAt(psdkPlayerSlot).currentHp,
      );
    });

    test('fainted active produces a forced replacement request', () {
      final engine = BattleEngine(
        setup: _setup(
          playerHp: 0,
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(id: 'player-reserve', hp: 80),
          ],
        ),
      );

      final request = engine.currentRequest;

      expect(
        request.kind,
        BattleEngineDecisionRequestKind.forcedReplacement,
      );
      expect(request.fightChoices, isEmpty);
      expect(request.canFlee, isFalse);
      expect(request.canCapture, isFalse);
      expect(
        request.allowedDecisions.single,
        isA<BattleSwitchDecision>().having(
          (decision) => decision.partyIndex,
          'partyIndex',
          1,
        ),
      );
    });

    test('forced replacement does not grant the opponent another action', () {
      final engine = BattleEngine(
        setup: _setup(
          playerHp: 0,
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(id: 'player-reserve', hp: 80),
          ],
          opponentMoves: <PsdkBattleMoveData>[
            _move(id: 'opponent-hit', power: 200),
          ],
        ),
      );

      final result = engine.submit(
        const BattleDecision.switchPokemon(partyIndex: 1),
      );

      expect(result.state.turnNumber, 0);
      expect(
        result.state.battlerAt(psdkPlayerSlot).id,
        'player-reserve',
      );
      expect(
        result.state.battlerAt(psdkPlayerSlot).currentHp,
        80,
      );
      expect(
        result.nextRequest?.kind,
        BattleEngineDecisionRequestKind.turnChoice,
      );
      expect(
        result.timeline.events.whereType<BattleMoveDeclaredTimelineEvent>(),
        isEmpty,
      );
    });

    test('exhausted PP exposes the RM-029 Struggle fallback', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'empty', currentPp: 0),
          ],
        ),
      );

      final request = session.decisionRequest;

      expect(request.kind, BattleEngineDecisionRequestKind.turnChoice);
      expect(request.canStruggle, isTrue);
      expect(
        request.allowedDecisions,
        contains(const BattleDecision.struggle()),
      );
    });
  });
}

BattleEngineSetup _setup({
  bool canFlee = false,
  bool isTrainerBattle = false,
  int playerHp = 80,
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
  List<PsdkBattleMoveData>? playerMoves,
  List<PsdkBattleMoveData>? opponentMoves,
}) {
  return BattleEngineSetup.singles(
    player: _combatant(
      id: 'player-active',
      hp: playerHp,
      moves: playerMoves,
    ),
    playerReserves: playerReserves,
    opponent: _combatant(
      id: 'opponent-active',
      hp: 80,
      moves: opponentMoves,
    ),
    canFlee: canFlee,
    isTrainerBattle: isTrainerBattle,
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 80,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: moves ?? <PsdkBattleMoveData>[_move(id: '$id-move')],
  );
}

PsdkBattleMoveData _move({
  required String id,
  int power = 40,
  int pp = 10,
  int? currentPp,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: pp,
    currentPp: currentPp,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
