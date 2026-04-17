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

BattleSession _session({
  required BattleMoveData playerMove,
  required BattleMoveData enemyMove,
  BattleMajorStatusState? playerMajorStatus,
  BattleMajorStatusState? enemyMajorStatus,
  BattleVolatileState playerVolatileState = const BattleVolatileState(),
  BattleVolatileState enemyVolatileState = const BattleVolatileState(),
  BattleRng rng = const BattleSeededRng(),
  int playerSpeed = 70,
  int enemySpeed = 40,
  int playerHp = 80,
  int enemyHp = 80,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: BattleCombatantData(
        speciesId: 'playermon',
        level: 30,
        maxHp: playerHp,
        stats: _stats(speed: playerSpeed),
        majorStatus: playerMajorStatus,
        volatileState: playerVolatileState,
        moves: <BattleMoveData>[playerMove],
      ),
      enemyPokemon: BattleCombatantData(
        speciesId: 'enemymon',
        level: 30,
        maxHp: enemyHp,
        stats: _stats(speed: enemySpeed),
        majorStatus: enemyMajorStatus,
        volatileState: enemyVolatileState,
        moves: <BattleMoveData>[enemyMove],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
    rng: rng,
  );
}

void main() {
  group('BattleSession BE8 useful volatiles', () {
    test('Protect blocks a slower opposing attack after activation', () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'protect',
          name: 'Protect',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.self,
          accuracy: BattleMoveAccuracy.alwaysHits(),
          selfVolatileStatus: BattleVolatileStatusId.protect,
        ),
        enemyMove: const BattleMoveData(
          id: 'tackle',
          name: 'Tackle',
          power: 40,
          type: 'normal',
          category: BattleMoveCategory.physical,
          target: BattleMoveTarget.opponent,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final volatileKinds = afterTurn.state.currentTurn!.volatileEvents
          .map((event) => event.kind)
          .toList(growable: false);
      final enemyExecution = afterTurn.state.currentTurn!.executions
          .where((execution) => execution.attacker == 'enemy')
          .single;

      expect(afterTurn.state.player.currentHp, equals(80));
      expect(afterTurn.state.player.volatileState.protectActive, isFalse);
      expect(
        volatileKinds,
        equals(<BattleVolatileEventKind>[
          BattleVolatileEventKind.protectActivated,
          BattleVolatileEventKind.protectBlocked,
        ]),
      );
      expect(enemyExecution.damage, equals(0));
      expect(enemyExecution.didHit, isTrue);
    });

    test('Protect does not retroactively block a faster opposing attack', () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'protect',
          name: 'Protect',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.self,
          accuracy: BattleMoveAccuracy.alwaysHits(),
          selfVolatileStatus: BattleVolatileStatusId.protect,
        ),
        enemyMove: const BattleMoveData(
          id: 'tackle',
          name: 'Tackle',
          power: 40,
          type: 'normal',
          category: BattleMoveCategory.physical,
          target: BattleMoveTarget.opponent,
        ),
        playerSpeed: 30,
        enemySpeed: 80,
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final volatileKinds = afterTurn.state.currentTurn!.volatileEvents
          .map((event) => event.kind)
          .toList(growable: false);

      expect(afterTurn.state.player.currentHp, lessThan(80));
      expect(
        volatileKinds,
        equals(<BattleVolatileEventKind>[
          BattleVolatileEventKind.protectActivated,
        ]),
      );
    });

    test('breakProtect pierces an active protection honestly', () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'protect',
          name: 'Protect',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.self,
          accuracy: BattleMoveAccuracy.alwaysHits(),
          selfVolatileStatus: BattleVolatileStatusId.protect,
        ),
        enemyMove: const BattleMoveData(
          id: 'feint',
          name: 'Feint',
          power: 30,
          type: 'normal',
          category: BattleMoveCategory.physical,
          target: BattleMoveTarget.opponent,
          breaksProtect: true,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final volatileKinds = afterTurn.state.currentTurn!.volatileEvents
          .map((event) => event.kind)
          .toList(growable: false);

      expect(afterTurn.state.player.currentHp, lessThan(80));
      expect(
        volatileKinds,
        equals(<BattleVolatileEventKind>[
          BattleVolatileEventKind.protectActivated,
          BattleVolatileEventKind.protectBroken,
        ]),
      );
    });

    test('breakProtect does nothing special when no protect is active', () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'growl',
          name: 'Growl',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.opponent,
        ),
        enemyMove: const BattleMoveData(
          id: 'feint',
          name: 'Feint',
          power: 30,
          type: 'normal',
          category: BattleMoveCategory.physical,
          target: BattleMoveTarget.opponent,
          breaksProtect: true,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.player.currentHp, lessThan(80));
      expect(
        afterTurn.state.currentTurn!.volatileEvents.where(
            (event) => event.kind == BattleVolatileEventKind.protectBroken),
        isEmpty,
      );
    });

    test('requireRecharge forces a visible skipped turn and then clears', () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'hyper_beam',
          name: 'Hyper Beam',
          power: 90,
          type: 'normal',
          category: BattleMoveCategory.special,
          target: BattleMoveTarget.opponent,
          requiresRecharge: true,
        ),
        enemyMove: const BattleMoveData(
          id: 'growl',
          name: 'Growl',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.opponent,
        ),
        playerSpeed: 80,
        enemySpeed: 40,
        enemyHp: 140,
      );

      final afterAttack = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterAttack.state.player.volatileState.mustRecharge, isTrue);
      expect(
        afterAttack.getAvailableChoices(),
        equals(<PlayerBattleChoice>[const PlayerBattleChoiceContinue()]),
      );
      expect(
        afterAttack.state.currentTurn!.volatileEvents
            .where((event) =>
                event.kind == BattleVolatileEventKind.rechargeRequired)
            .single
            .sourceMoveId,
        equals('hyper_beam'),
      );

      final afterRecharge =
          afterAttack.applyChoice(const PlayerBattleChoiceContinue());

      expect(afterRecharge.state.player.volatileState.mustRecharge, isFalse);
      expect(
        afterRecharge.state.currentTurn!.volatileEvents
            .where((event) =>
                event.kind == BattleVolatileEventKind.rechargeTurnSpent)
            .single
            .actor,
        equals('player'),
      );
      final timeline = afterRecharge.state.currentTurn!.timeline;
      final rechargeIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnVolatileEvent &&
            event.event.kind == BattleVolatileEventKind.rechargeTurnSpent,
      );
      final enemyExecutionIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnExecutionEvent &&
            event.execution.attacker == 'enemy',
      );
      expect(rechargeIndex, isNonNegative);
      expect(enemyExecutionIndex, greaterThan(rechargeIndex));
    });

    test(
        'chargeThenStrike charges first, releases next turn, and spends PP once',
        () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'solar_beam',
          name: 'Solar Beam',
          power: 120,
          type: 'grass',
          category: BattleMoveCategory.special,
          target: BattleMoveTarget.opponent,
          pp: 10,
          chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
            chargeStateId: 'solar_charge',
          ),
        ),
        enemyMove: const BattleMoveData(
          id: 'growl',
          name: 'Growl',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.opponent,
        ),
        playerSpeed: 80,
        enemySpeed: 40,
      );

      final afterCharge = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterCharge.state.enemy.currentHp, equals(80));
      expect(afterCharge.state.player.moves.single.currentPp, equals(9));
      expect(afterCharge.state.player.volatileState.pendingCharge, isNotNull);
      expect(
        afterCharge.getAvailableChoices(),
        equals(<PlayerBattleChoice>[const PlayerBattleChoiceContinue()]),
      );
      expect(
        afterCharge.state.currentTurn!.volatileEvents
            .where(
                (event) => event.kind == BattleVolatileEventKind.chargeStarted)
            .single
            .chargeStateId,
        equals('solar_charge'),
      );

      final afterRelease =
          afterCharge.applyChoice(const PlayerBattleChoiceContinue());
      final playerExecution = afterRelease.state.currentTurn!.executions
          .where((execution) => execution.attacker == 'player')
          .single;

      expect(afterRelease.state.player.volatileState.pendingCharge, isNull);
      expect(afterRelease.state.player.moves.single.currentPp, equals(9));
      expect(afterRelease.state.enemy.currentHp, lessThan(80));
      expect(playerExecution.move.id, equals('solar_beam'));
      expect(playerExecution.damage, greaterThan(0));
      expect(
        afterRelease.state.currentTurn!.volatileEvents
            .where(
                (event) => event.kind == BattleVolatileEventKind.chargeReleased)
            .single
            .sourceMoveId,
        equals('solar_beam'),
      );
    });

    test(
        'paralysis on the first charge turn spends PP but does not arm a fake pending charge',
        () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'solar_beam',
          name: 'Solar Beam',
          power: 120,
          type: 'grass',
          category: BattleMoveCategory.special,
          target: BattleMoveTarget.opponent,
          pp: 10,
          chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
            chargeStateId: 'solar_charge',
          ),
        ),
        enemyMove: const BattleMoveData(
          id: 'growl',
          name: 'Growl',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.opponent,
        ),
        playerMajorStatus: const BattleMajorStatusState.par(),
        rng: const BattleScriptedRng(<int>[1]),
        playerSpeed: 80,
        enemySpeed: 40,
      );

      final afterBlocked =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterBlocked.state.player.moves.single.currentPp, equals(9));
      expect(afterBlocked.state.player.volatileState.pendingCharge, isNull);
      expect(
        afterBlocked.state.currentTurn!.statusEvents
            .where(
              (event) => event.kind == BattleStatusEventKind.preventedAction,
            )
            .single
            .status,
        equals(BattleMajorStatusId.par),
      );
      expect(
        afterBlocked.state.currentTurn!.volatileEvents.where(
          (event) => event.kind == BattleVolatileEventKind.chargeStarted,
        ),
        isEmpty,
      );
      expect(
        afterBlocked.decisionRequest,
        isA<BattleTurnChoiceRequest>(),
      );
    });
  });
}
