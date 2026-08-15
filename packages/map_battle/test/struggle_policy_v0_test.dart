import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/effect/move/taunt_effect.dart';
import 'package:test/test.dart';

void main() {
  group('RM-029 Struggle policy V0', () {
    test('exhausted PP exposes Struggle instead of noLegalChoice', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'empty', currentPp: 0),
          ],
        ),
      );

      final request = session.decisionRequest;

      expect(request.kind, BattleEngineDecisionRequestKind.turnChoice);
      expect(request.fightChoices, isEmpty);
      expect(request.canStruggle, isTrue);
      expect(
        request.allowedDecisions,
        contains(
          isA<BattleFightDecision>().having(
            (decision) => decision.isStruggle,
            'isStruggle',
            isTrue,
          ),
        ),
      );
      expect(request.allows(const BattleDecision.struggle()), isTrue);
    });

    test('Struggle deals damage, recoils 1/4 max HP and consumes no PP', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'empty', currentPp: 0),
          ],
        ),
      );

      final result = session.submit(const BattleDecision.struggle());
      final struggleDamage = result.timeline.events
          .whereType<BattleDamageTimelineEvent>()
          .where((event) => event.moveId == canonicalStruggleMoveId)
          .toList(growable: false);
      final recoil = struggleDamage.singleWhere(
        (event) =>
            event.user.bank == psdkPlayerSlot.bank &&
            event.target.bank == psdkPlayerSlot.bank,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(struggleDamage, hasLength(2));
      expect(recoil.damage, 20);
      expect(player.moves.single.id, 'empty');
      expect(player.moves.single.currentPp, 0);
      expect(player.moves, isNot(contains(canonicalStruggleMoveId)));
      expect(
        player.writeBackMoves.map((move) => move.id),
        isNot(contains(canonicalStruggleMoveId)),
      );
      expect(
        result.timeline.events
            .whereType<BattleMovePpSpentTimelineEvent>()
            .where((event) => event.moveId == canonicalStruggleMoveId),
        isEmpty,
      );
    });

    test('a usable move keeps Struggle unavailable and rejection atomic', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'usable', currentPp: 1),
          ],
        ),
      );
      final before = session.state;

      expect(session.decisionRequest.canStruggle, isFalse);
      expect(
        session.decisionRequest.allows(const BattleDecision.struggle()),
        isFalse,
      );
      expect(
        () => session.submit(const BattleDecision.struggle()),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(session.state.turnNumber, before.turnNumber);
      expect(
        session.state.battlerAt(psdkPlayerSlot).currentHp,
        before.battlerAt(psdkPlayerSlot).currentHp,
      );
    });

    test('Struggle coexists with a voluntary switch', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'empty', currentPp: 0),
          ],
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'reserve',
              moves: <PsdkBattleMoveData>[_move(id: 'reserve-hit')],
            ),
          ],
        ),
      );

      final request = session.decisionRequest;

      expect(request.canStruggle, isTrue);
      expect(request.switchChoices, hasLength(1));
      expect(
        request.allowedDecisions.whereType<BattleSwitchDecision>(),
        hasLength(1),
      );
    });

    test('all PP-positive moves prevented by effects also expose Struggle', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerEffects: const PsdkBattleEffectStack.empty().addEffect(
            TauntEffect(scope: BattlerBattleEffectScope(psdkPlayerSlot)),
          ),
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'status-only',
              power: 0,
              category: PsdkBattleMoveCategory.status,
              battleEngineMethod: 's_status',
            ),
          ],
        ),
      );

      expect(session.decisionRequest.fightChoices, isEmpty);
      expect(session.decisionRequest.canStruggle, isTrue);
      expect(
        session.submit(const BattleDecision.struggle()).timeline.events.where(
              (event) =>
                  event is BattleMoveDeclaredTimelineEvent &&
                  event.moveId == canonicalStruggleMoveId,
            ),
        isNotEmpty,
      );
    });

    test('a combatant with no configured move stays fail-closed', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(playerMoves: const <PsdkBattleMoveData>[]),
      );

      expect(
        session.decisionRequest.kind,
        BattleEngineDecisionRequestKind.noLegalChoice,
      );
      expect(session.decisionRequest.canStruggle, isFalse);
      expect(session.decisionRequest.allowedDecisions, isEmpty);
    });

    test('an exhausted opponent uses Struggle instead of noAction', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'player-tap', power: 1),
          ],
          opponentMoves: <PsdkBattleMoveData>[
            _move(id: 'enemy-empty', currentPp: 0),
          ],
        ),
        opponentAi: const PsdkBattleAi(level: 1),
      );

      final result = session.submit(
        const BattleDecision.fight(moveSlot: 0),
      );
      final enemyStruggleDeclarations = result.timeline.events
          .whereType<BattleMoveDeclaredTimelineEvent>()
          .where(
            (event) =>
                event.user.bank == psdkOpponentSlot.bank &&
                event.moveId == canonicalStruggleMoveId,
          );
      final enemyRecoil = result.timeline.events
          .whereType<BattleDamageTimelineEvent>()
          .singleWhere(
            (event) =>
                event.moveId == canonicalStruggleMoveId &&
                event.user.bank == psdkOpponentSlot.bank &&
                event.target.bank == psdkOpponentSlot.bank,
          );

      expect(enemyStruggleDeclarations, hasLength(1));
      expect(enemyRecoil.damage, 20);
      expect(
        result.state.battlerAt(psdkOpponentSlot).moves.map((move) => move.id),
        <String>['enemy-empty'],
      );
    });
  });
}

BattleEngineSetup _setup({
  List<PsdkBattleMoveData>? playerMoves,
  List<PsdkBattleMoveData>? opponentMoves,
  PsdkBattleEffectStack? playerEffects,
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
}) {
  return BattleEngineSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(
      id: 'player',
      moves: playerMoves ?? <PsdkBattleMoveData>[_move(id: 'player-hit')],
      effects: playerEffects,
    ),
    playerReserves: playerReserves,
    opponent: _combatant(
      id: 'opponent',
      moves: opponentMoves ?? <PsdkBattleMoveData>[_move(id: 'opponent-hit')],
    ),
    isTrainerBattle: true,
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
  required List<PsdkBattleMoveData> moves,
  PsdkBattleEffectStack? effects,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 80,
    currentHp: 80,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: moves,
    effects: effects,
  );
}

PsdkBattleMoveData _move({
  required String id,
  int power = 40,
  int currentPp = 10,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  String battleEngineMethod = 's_basic',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: 100,
    pp: 10,
    currentPp: currentPp,
    priority: 0,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
