import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _playerAllySlot = PsdkBattleSlotRef(bank: 0, position: 1);

void main() {
  group('PSDK missing ability effects', () {
    test('Unaware defender ignores attacker offensive stat stages', () {
      final neutral = _calculateDamage(
        playerStages: PsdkBattleStatStages.neutral(),
      );
      final boosted = _calculateDamage(
        playerStages: PsdkBattleStatStages(
          values: const <String, int>{'attack': 2},
        ),
      );
      final unaware = _calculateDamage(
        playerStages: PsdkBattleStatStages(
          values: const <String, int>{'attack': 2},
        ),
        opponentAbilityId: 'unaware',
      );

      expect(boosted.damage, greaterThan(neutral.damage));
      expect(unaware.damage, neutral.damage);
    });

    test('Unaware attacker ignores target defensive stat stages', () {
      final neutral = _calculateDamage(
        opponentStages: PsdkBattleStatStages.neutral(),
      );
      final defended = _calculateDamage(
        opponentStages: PsdkBattleStatStages(
          values: const <String, int>{'defense': 2},
        ),
      );
      final unaware = _calculateDamage(
        playerAbilityId: 'unaware',
        opponentStages: PsdkBattleStatStages(
          values: const <String, int>{'defense': 2},
        ),
      );

      expect(defended.damage, lessThan(neutral.damage));
      expect(unaware.damage, neutral.damage);
    });

    test('Unaware target ignores user accuracy drops', () {
      final loweredAccuracy = _resolveAccuracy(
        accuracy: 100,
        moveAccuracySeed: 90,
        playerStages: PsdkBattleStatStages(
          values: const <String, int>{'accuracy': -1},
        ),
      );
      final unawareTarget = _resolveAccuracy(
        accuracy: 100,
        moveAccuracySeed: 90,
        opponentAbilityId: 'unaware',
        playerStages: PsdkBattleStatStages(
          values: const <String, int>{'accuracy': -1},
        ),
      );

      expect(loweredAccuracy.missedTargets, <BattlePositionRef>[
        const BattlePositionRef(bank: 1, position: 0),
      ]);
      expect(unawareTarget.hitTargets, <BattlePositionRef>[
        const BattlePositionRef(bank: 1, position: 0),
      ]);
    });

    test('Unaware user ignores target evasion boosts', () {
      final raisedEvasion = _resolveAccuracy(
        accuracy: 100,
        moveAccuracySeed: 90,
        opponentStages: PsdkBattleStatStages(
          values: const <String, int>{'evasion': 1},
        ),
      );
      final unawareUser = _resolveAccuracy(
        accuracy: 100,
        moveAccuracySeed: 90,
        playerAbilityId: 'unaware',
        opponentStages: PsdkBattleStatStages(
          values: const <String, int>{'evasion': 1},
        ),
      );

      expect(raisedEvasion.missedTargets, <BattlePositionRef>[
        const BattlePositionRef(bank: 1, position: 0),
      ]);
      expect(unawareUser.hitTargets, <BattlePositionRef>[
        const BattlePositionRef(bank: 1, position: 0),
      ]);
    });

    test('Emergency Exit queues a damaged holder below half HP', () {
      final state = _singlesState(
        opponentAbilityId: 'emergency_exit',
        opponentReserves: <PsdkBattleCombatantSetup>[
          _combatant(id: 'opponent-reserve'),
        ],
      );

      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkOpponentSlot,
        moveId: 'tackle',
        rawDamage: 60,
        move: _move(id: 'tackle', power: 40).definition,
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 40);
      expect(result.state.battlerAt(psdkOpponentSlot).switching, isTrue);
    });

    test('Emergency Exit does not trigger without a replacement', () {
      final state = _singlesState(opponentAbilityId: 'wimp_out');

      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkOpponentSlot,
        moveId: 'tackle',
        rawDamage: 60,
        move: _move(id: 'tackle', power: 40).definition,
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 40);
      expect(result.state.battlerAt(psdkOpponentSlot).switching, isFalse);
    });

    test('Symbiosis gives the owner held item to an ally that consumed one',
        () {
      final state = _doublesState(
        playerAbilityId: 'symbiosis',
        playerHeldItemId: 'sitrus_berry',
        playerAllyHeldItemId: 'oran_berry',
      );

      final result = const BattleItemChangeHandler().consumeHeldItem(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: _playerAllySlot,
        ),
        target: _playerAllySlot,
      );

      expect(result.state.battlerAt(psdkPlayerSlot).heldItemId, isNull);
      expect(
        result.state.battlerAt(_playerAllySlot).heldItemId,
        'sitrus_berry',
      );
      expect(
        result.events.whereType<PsdkBattleItemEvent>().single.itemId,
        'oran_berry',
      );
    });

    test('Ball Fetch retrieves the last failed ball at end turn', () {
      final state = _singlesState(
        playerAbilityId: 'ball_fetch',
        field: const PsdkBattleFieldState(
          lastBallUsedId: 'poke_ball',
          ballFetchEligibleSlots: <PsdkBattleSlotRef>[psdkPlayerSlot],
        ),
      );

      final result = const BattleEndTurnHandler().resolveEndTurn(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).heldItemId, 'poke_ball');
      expect(result.state.field.lastBallUsedId, isNull);
      expect(result.state.field.ballFetchEligibleSlots, isEmpty);
    });
  });
}

BattleMoveDamageResult _calculateDamage({
  String? playerAbilityId,
  String? opponentAbilityId,
  PsdkBattleStatStages? playerStages,
  PsdkBattleStatStages? opponentStages,
}) {
  final move = _move(id: 'tackle', power: 80).definition;
  final state = _singlesState(
    playerAbilityId: playerAbilityId,
    opponentAbilityId: opponentAbilityId,
    playerStages: playerStages,
    opponentStages: opponentStages,
  );
  return const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: state.battlerAt(psdkPlayerSlot),
      target: state.battlerAt(psdkOpponentSlot),
      move: move,
      rng: _rng(),
      field: state.field,
      state: state,
      userSlot: psdkPlayerSlot,
      targetSlot: psdkOpponentSlot,
    ),
  );
}

BattleAccuracyResult _resolveAccuracy({
  required int accuracy,
  required int moveAccuracySeed,
  String? playerAbilityId,
  String? opponentAbilityId,
  PsdkBattleStatStages? playerStages,
  PsdkBattleStatStages? opponentStages,
}) {
  final move = _move(
    id: 'tackle',
    power: 40,
    accuracy: accuracy,
  ).definition;
  final state = _singlesState(
    playerAbilityId: playerAbilityId,
    opponentAbilityId: opponentAbilityId,
    playerStages: playerStages,
    opponentStages: opponentStages,
  );
  return const BattleAccuracyResolver().resolve(
    execution: BattleMoveProcedureExecution(
      context: BattleMoveBehaviorContext(
        state: state,
        rng: BattleRngStreams.fromSeeds(
          moveDamageSeed: 1,
          moveCriticalSeed: 99999,
          moveAccuracySeed: moveAccuracySeed,
          genericSeed: 4,
        ),
        turn: 1,
        user: psdkPlayerSlot,
        target: psdkOpponentSlot,
        move: move,
      ),
      timeline: BattleTimelineBuilder(),
      user: const BattlePositionRef(bank: 0, position: 0),
      move: move,
      requestedTarget: const BattlePositionRef(bank: 1, position: 0),
    ),
    targets: const <BattlePositionRef>[
      BattlePositionRef(bank: 1, position: 0),
    ],
  );
}

PsdkBattleState _singlesState({
  String? playerAbilityId,
  String? opponentAbilityId,
  PsdkBattleStatStages? playerStages,
  PsdkBattleStatStages? opponentStages,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  List<PsdkBattleCombatantSetup> opponentReserves =
      const <PsdkBattleCombatantSetup>[],
}) {
  return PsdkBattleState.fromSetup(
    PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: playerAbilityId,
        statStages: playerStages,
      ),
      opponent: _combatant(
        id: 'opponent',
        abilityId: opponentAbilityId,
        statStages: opponentStages,
      ),
      opponentReserves: opponentReserves,
      field: field,
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
}

PsdkBattleState _doublesState({
  String? playerAbilityId,
  String? playerHeldItemId,
  String? playerAllyHeldItemId,
}) {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player',
          abilityId: playerAbilityId,
          heldItemId: playerHeldItemId,
        ),
      ),
      _playerAllySlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player-ally',
          heldItemId: playerAllyHeldItemId,
        ),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'opponent'),
      ),
    },
  );
}

({BattleMoveDefinition definition, PsdkBattleMoveData psdk}) _move({
  required String id,
  required int power,
  int accuracy = 100,
}) {
  final definition = BattleMoveDefinition(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
  return (definition: definition, psdk: definition.psdkMove);
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? abilityId,
  String? heldItemId,
  PsdkBattleStatStages? statStages,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 80,
      defense: 80,
      specialAttack: 80,
      specialDefense: 80,
      speed: 80,
    ),
    abilityId: abilityId,
    heldItemId: heldItemId,
    statStages: statStages,
    moves: <PsdkBattleMoveData>[
      _move(id: 'tackle', power: 40).psdk,
    ],
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 99999,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}
