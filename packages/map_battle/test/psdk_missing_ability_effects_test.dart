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

    test('Dancer immediately replays dance moves without PP or history', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            move: _move(id: 'fiery_dance', power: 40).psdk.copyWith(
                  dance: true,
                ),
            speed: 80,
          ),
          opponent: _combatant(
            id: 'opponent',
            abilityId: 'dancer',
            move: _move(id: 'wait', power: 0).psdk,
            speed: 40,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final danceDamage = result.timeline.events
          .whereType<PsdkBattleDamageEvent>()
          .where((event) => event.moveId == 'fiery_dance')
          .toList(growable: false);
      final fieryPpEvents = result.timeline.events
          .whereType<PsdkBattleMovePpSpentEvent>()
          .where((event) => event.moveId == 'fiery_dance')
          .toList(growable: false);
      final opponentHistory =
          result.state.battlerAt(psdkOpponentSlot).moveHistory;

      expect(
        danceDamage.map((event) => event.user),
        <PsdkBattleSlotRef>[psdkPlayerSlot, psdkOpponentSlot],
      );
      expect(
        danceDamage.map((event) => event.target),
        <PsdkBattleSlotRef>[psdkOpponentSlot, psdkPlayerSlot],
      );
      expect(fieryPpEvents.map((event) => event.user), <PsdkBattleSlotRef>[
        psdkPlayerSlot,
      ]);
      expect(opponentHistory.usedMoveIds, isNot(contains('fiery_dance')));
      expect(
        opponentHistory.successfulMoveIds,
        isNot(contains('fiery_dance')),
      );
    });

    test('Dancer replay does not lock Thrash-style dance moves', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            move: _move(
              id: 'thrash',
              power: 40,
              battleEngineMethod: 's_thrash',
            ).psdk.copyWith(dance: true),
            speed: 80,
          ),
          opponent: _combatant(
            id: 'opponent',
            abilityId: 'dancer',
            move: _move(id: 'wait', power: 0).psdk,
            speed: 40,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(
        result.state
            .battlerAt(psdkOpponentSlot)
            .effects
            .contains('force_next_move_base'),
        isFalse,
      );
    });

    test('Commander marks Tatsugiri and sharply boosts allied Dondozo', () {
      final result = const BattleSwitchHandler().dispatchSwitchEvents(
        context: BattleHandlerContext(
          state: _commanderState(),
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        who: psdkPlayerSlot,
        replacement: psdkPlayerSlot,
      );
      final tatsugiri = result.state.battlerAt(psdkPlayerSlot);
      final dondozo = result.state.battlerAt(_playerAllySlot);

      expect(tatsugiri.effects.contains('commanding'), isTrue);
      expect(dondozo.effects.contains('commanded'), isTrue);
      expect(dondozo.statStages.valueOf('attack'), 2);
      expect(dondozo.statStages.valueOf('defense'), 2);
      expect(dondozo.statStages.valueOf('specialAttack'), 2);
      expect(dondozo.statStages.valueOf('specialDefense'), 2);
      expect(dondozo.statStages.valueOf('speed'), 2);
      expect(
        result.events.whereType<PsdkBattleStatStageEvent>(),
        hasLength(5),
      );
    });

    test('Commander also activates when allied Dondozo switches in', () {
      final result = const BattleSwitchHandler().dispatchSwitchEvents(
        context: BattleHandlerContext(
          state: _commanderState(),
          rng: _rng(),
          turn: 1,
          user: _playerAllySlot,
        ),
        who: _playerAllySlot,
        replacement: _playerAllySlot,
      );

      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('commanding'),
        isTrue,
      );
      expect(
        result.state.battlerAt(_playerAllySlot).effects.contains('commanded'),
        isTrue,
      );
    });

    test('Commanding and Commanded prevent actions until Dondozo faints', () {
      final commander = const BattleSwitchHandler().dispatchSwitchEvents(
        context: BattleHandlerContext(
          state: _commanderState(),
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        who: psdkPlayerSlot,
        replacement: psdkPlayerSlot,
      );
      final commandingPrevention =
          commander.state.battlerAt(psdkPlayerSlot).effects.userMovePrevention(
                BattleEffectUserMovePreventionContext(
                  state: commander.state,
                  rng: _rng(),
                  turn: 1,
                  user: psdkPlayerSlot,
                  target: psdkOpponentSlot,
                  move: _move(id: 'tackle', power: 40).definition,
                ),
              );
      final tatsugiriSwitch =
          const BattleSwitchHandler().resolveSwitchPrevention(
        context: BattleHandlerContext(
          state: commander.state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkPlayerSlot,
      );
      final dondozoSwitch = const BattleSwitchHandler().resolveSwitchPrevention(
        context: BattleHandlerContext(
          state: commander.state,
          rng: _rng(),
          turn: 1,
          user: _playerAllySlot,
        ),
        target: _playerAllySlot,
      );
      final ko = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: commander.state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: _playerAllySlot,
        moveId: 'ko_hit',
        rawDamage: 100,
      );
      final outOfReach = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: commander.state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
        moveId: 'target_commander',
        rawDamage: 20,
      );

      expect(commandingPrevention?.prevented, isTrue);
      expect(
          commandingPrevention?.reason, BattleMoveFailureReason.unusableByUser);
      expect(
        commander.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains('out_of_reach_base'),
        isTrue,
      );
      expect(outOfReach.applied, isFalse);
      expect(outOfReach.reason, BattleMoveFailureReason.protected.jsonName);
      expect(tatsugiriSwitch.applied, isFalse);
      expect(tatsugiriSwitch.reason, 'commanding');
      expect(dondozoSwitch.applied, isFalse);
      expect(dondozoSwitch.reason, 'commanded');
      expect(
        ko.state.battlerAt(psdkPlayerSlot).effects.contains('commanding'),
        isFalse,
      );
    });

    test('Neutralizing Gas suppresses other active abilities on switch-in', () {
      final state = _doublesState(
        playerAbilityId: 'neutralizing_gas',
        playerAllyAbilityId: 'levitate',
        opponentAbilityId: 'water_absorb',
      );

      final result = const BattleSwitchHandler().dispatchSwitchEvents(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        who: psdkPlayerSlot,
        replacement: psdkPlayerSlot,
      );

      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains(
              'neutralizing_gas_activated',
            ),
        isTrue,
      );
      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains(
              'ability_suppressed',
            ),
        isFalse,
      );
      expect(
        _abilitySuppressionOrigin(
          result.state.battlerAt(_playerAllySlot),
        ),
        'neutralizing_gas',
      );
      expect(
        _abilitySuppressionOrigin(
          result.state.battlerAt(psdkOpponentSlot),
        ),
        'neutralizing_gas',
      );
    });

    test('Neutralizing Gas restores suppressed abilities when owner leaves',
        () {
      final activated = const BattleSwitchHandler().dispatchSwitchEvents(
        context: BattleHandlerContext(
          state: _doublesState(
            playerAbilityId: 'neutralizing_gas',
            playerAllyAbilityId: 'levitate',
            opponentAbilityId: 'water_absorb',
          ),
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        who: psdkPlayerSlot,
        replacement: psdkPlayerSlot,
      );

      final restored = const BattleSwitchHandler().dispatchSwitchEvents(
        context: BattleHandlerContext(
          state: activated.state,
          rng: activated.rng,
          turn: 2,
          user: psdkPlayerSlot,
        ),
        who: psdkPlayerSlot,
        replacement: _playerAllySlot,
      );

      expect(
        restored.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains('neutralizing_gas_activated'),
        isFalse,
      );
      expect(
        restored.state
            .battlerAt(_playerAllySlot)
            .effects
            .contains('ability_suppressed'),
        isFalse,
      );
      expect(
        restored.state
            .battlerAt(psdkOpponentSlot)
            .effects
            .contains('ability_suppressed'),
        isFalse,
      );
    });

    test('Neutralizing Gas releases suppression before ability changes away',
        () {
      final activated = const BattleSwitchHandler().dispatchSwitchEvents(
        context: BattleHandlerContext(
          state: _doublesState(
            playerAbilityId: 'neutralizing_gas',
            opponentAbilityId: 'water_absorb',
          ),
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        who: psdkPlayerSlot,
        replacement: psdkPlayerSlot,
      );

      final changed = const BattleAbilityChangeHandler().changeAbility(
        context: BattleHandlerContext(
          state: activated.state,
          rng: activated.rng,
          turn: 2,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
        abilityId: 'run_away',
      );

      expect(changed.state.battlerAt(psdkPlayerSlot).abilityId, 'run_away');
      expect(
        changed.state
            .battlerAt(psdkOpponentSlot)
            .effects
            .contains('ability_suppressed'),
        isFalse,
      );
    });

    test('Parental Bond adds a weaker second hit for simple damaging moves',
        () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            abilityId: 'parental_bond',
            move: _move(id: 'tackle', power: 40).psdk,
          ),
          opponent: _combatant(id: 'opponent'),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final hits = result.timeline.events
          .whereType<PsdkBattleDamageEvent>()
          .where((event) => event.user == psdkPlayerSlot)
          .toList(growable: false);

      expect(hits, hasLength(2));
      expect(hits[1].damage, lessThan(hits[0].damage));
      expect(
        result.state.battlerAt(psdkOpponentSlot).currentHp,
        100 - hits[0].damage - hits[1].damage,
      );
    });

    test('Parental Bond skips excluded one-attack methods', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            abilityId: 'parental_bond',
            move: _move(
              id: 'uproar',
              power: 40,
              battleEngineMethod: 's_uproar',
            ).psdk,
          ),
          opponent: _combatant(id: 'opponent'),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final hits = result.timeline.events
          .whereType<PsdkBattleDamageEvent>()
          .where((event) => event.user == psdkPlayerSlot)
          .toList(growable: false);

      expect(hits, hasLength(1));
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
  String? playerAllyAbilityId,
  String? opponentAbilityId,
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
          abilityId: playerAllyAbilityId,
          heldItemId: playerAllyHeldItemId,
        ),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'opponent', abilityId: opponentAbilityId),
      ),
    },
  );
}

PsdkBattleState _commanderState() {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'tatsugiri',
          speciesId: 'tatsugiri',
          abilityId: 'commander',
        ),
      ),
      _playerAllySlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'dondozo',
          speciesId: 'dondozo',
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
  String battleEngineMethod = 's_basic',
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
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
  return (definition: definition, psdk: definition.psdkMove);
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? speciesId,
  String? abilityId,
  String? heldItemId,
  PsdkBattleStatStages? statStages,
  PsdkBattleMoveData? move,
  int speed = 80,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId ?? id,
    displayName: id,
    level: 50,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 80,
      defense: 80,
      specialAttack: 80,
      specialDefense: 80,
      speed: speed,
    ),
    abilityId: abilityId,
    heldItemId: heldItemId,
    statStages: statStages,
    moves: <PsdkBattleMoveData>[
      move ?? _move(id: 'tackle', power: 40).psdk,
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

String? _abilitySuppressionOrigin(PsdkBattleCombatant battler) {
  for (final effect in battler.effects.effects) {
    if (effect is AbilitySuppressedEffect) {
      return effect.origin;
    }
  }
  return null;
}
