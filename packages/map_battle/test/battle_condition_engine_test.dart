import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/battle_condition_engine.dart';
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

BattleMove _move({
  required String id,
  String? name,
  int power = 40,
  String type = 'normal',
  BattleMoveCategory category = BattleMoveCategory.physical,
  BattleMoveTarget target = BattleMoveTarget.opponent,
  BattleMoveAccuracy accuracy = const BattleMoveAccuracy.percent(value: 100),
  int pp = 10,
  int? currentPp,
  BattleMoveMajorStatusEffect? majorStatusEffect,
  BattleVolatileStatusId? selfVolatileStatus,
  bool breaksProtect = false,
  bool requiresRecharge = false,
  BattleChargeThenStrikeEffect? chargeThenStrikeEffect,
  BattleWeatherId? weatherEffect,
  BattlePseudoWeatherId? pseudoWeatherEffect,
}) {
  return BattleMove(
    id: id,
    name: name ?? id,
    power: power,
    type: type,
    category: category,
    target: target,
    accuracy: accuracy,
    pp: pp,
    currentPp: currentPp,
    majorStatusEffect: majorStatusEffect,
    selfVolatileStatus: selfVolatileStatus,
    breaksProtect: breaksProtect,
    requiresRecharge: requiresRecharge,
    chargeThenStrikeEffect: chargeThenStrikeEffect,
    weatherEffect: weatherEffect,
    pseudoWeatherEffect: pseudoWeatherEffect,
  );
}

BattleCombatant _combatant({
  required String speciesId,
  int currentHp = 100,
  int maxHp = 100,
  BattleMajorStatusState? majorStatus,
  BattleVolatileState volatileState = const BattleVolatileState(),
  BattleTypingSnapshot? typing,
  required List<BattleMove> moves,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    level: 40,
    currentHp: currentHp,
    maxHp: maxHp,
    stats: _stats(),
    majorStatus: majorStatus,
    volatileState: volatileState,
    typing: typing,
    moves: moves,
  );
}

void main() {
  group('BattleConditionEngine Phase E mini event runners', () {
    const engine = BattleConditionEngine();

    test('runActionAttempt spends PP and exposes a paralysis gate outcome', () {
      final attacker = _combatant(
        speciesId: 'locked',
        majorStatus: const BattleMajorStatusState.par(),
        moves: <BattleMove>[
          _move(
            id: 'tackle',
            currentPp: 10,
          ),
        ],
      );

      final result = engine.runActionAttempt(
        attackerSlot: const BattleSlotRef.active(BattleSideId.player),
        move: attacker.moves.single,
        moveIndex: 0,
        attacker: attacker,
        rng: const BattleScriptedRng(<int>[1]),
      );

      expect(
        result.outcome,
        equals(BattleActionAttemptOutcome.preventedAction),
      );
      expect(result.attacker.moves.single.currentPp, equals(9));
      expect(
        result.statusEvents.single.kind,
        equals(BattleStatusEventKind.preventedAction),
      );
      expect(
        result.statusEvents.single.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(result.volatileEvents, isEmpty);
    });

    test('runActionAttempt starts a charge turn honestly', () {
      final attacker = _combatant(
        speciesId: 'charger',
        moves: <BattleMove>[
          _move(
            id: 'solar_beam',
            name: 'Solar Beam',
            power: 120,
            type: 'grass',
            category: BattleMoveCategory.special,
            chargeThenStrikeEffect: const BattleChargeThenStrikeEffect(
              chargeStateId: 'solar_charge',
            ),
          ),
        ],
      );

      final result = engine.runActionAttempt(
        attackerSlot: const BattleSlotRef.active(BattleSideId.player),
        move: attacker.moves.single,
        moveIndex: 0,
        attacker: attacker,
        rng: const BattleSeededRng(),
      );

      expect(
        result.outcome,
        equals(BattleActionAttemptOutcome.chargeStarted),
      );
      expect(result.attacker.moves.single.currentPp, equals(9));
      expect(result.attacker.volatileState.pendingCharge, isNotNull);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.chargeStarted),
      );
      expect(
        result.volatileEvents.single.actorSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
    });

    test('runHitInterception blocks an opponent move behind Protect', () {
      final attacker = _combatant(
        speciesId: 'attacker',
        moves: <BattleMove>[_move(id: 'tackle')],
      );
      final defender = _combatant(
        speciesId: 'defender',
        volatileState: const BattleVolatileState(
          protectActive: true,
        ),
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runHitInterception(
        move: attacker.moves.single,
        attackerSlot: const BattleSlotRef.active(BattleSideId.enemy),
        targetSlot: const BattleSlotRef.active(BattleSideId.player),
        attacker: attacker,
        defender: defender,
      );

      expect(result.blockedByProtect, isTrue);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.protectBlocked),
      );
      expect(
        result.volatileEvents.single.actorSlot,
        equals(const BattleSlotRef.active(BattleSideId.enemy)),
      );
      expect(
        result.volatileEvents.single.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
    });

    test('runHitInterception lets breakProtect pierce and clear Protect', () {
      final attacker = _combatant(
        speciesId: 'attacker',
        moves: <BattleMove>[
          _move(
            id: 'feint',
            breaksProtect: true,
          ),
        ],
      );
      final defender = _combatant(
        speciesId: 'defender',
        volatileState: const BattleVolatileState(
          protectActive: true,
        ),
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runHitInterception(
        move: attacker.moves.single,
        attackerSlot: const BattleSlotRef.active(BattleSideId.enemy),
        targetSlot: const BattleSlotRef.active(BattleSideId.player),
        attacker: attacker,
        defender: defender,
      );

      expect(result.blockedByProtect, isFalse);
      expect(result.defender.volatileState.protectActive, isFalse);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.protectBroken),
      );
      expect(
        result.volatileEvents.single.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
    });

    test('runMoveResolved applies a supported major status on hit', () {
      final attacker = _combatant(
        speciesId: 'sparkitten',
        moves: <BattleMove>[
          _move(
            id: 'ember',
            type: 'fire',
            category: BattleMoveCategory.special,
            majorStatusEffect: const BattleMoveMajorStatusEffect(
              status: BattleMajorStatusId.brn,
            ),
          ),
        ],
      );
      final defender = _combatant(
        speciesId: 'dummy',
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runMoveResolved(
        move: attacker.moves.single,
        attackerSlot: const BattleSlotRef.active(BattleSideId.player),
        targetSlot: const BattleSlotRef.active(BattleSideId.enemy),
        attacker: attacker,
        defender: defender,
        field: const BattleFieldState(),
        wasImmune: false,
        rng: const BattleSeededRng(),
      );

      expect(result.defender.majorStatus?.id, equals(BattleMajorStatusId.brn));
      expect(
        result.statusEvents.single.kind,
        equals(BattleStatusEventKind.applied),
      );
      expect(
        result.statusEvents.single.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.enemy)),
      );
    });

    test('runMoveResolved can mark an honest recharge follow-up', () {
      final attacker = _combatant(
        speciesId: 'beammon',
        moves: <BattleMove>[
          _move(
            id: 'hyper_beam',
            name: 'Hyper Beam',
            power: 120,
            category: BattleMoveCategory.special,
            requiresRecharge: true,
          ),
        ],
      );
      final defender = _combatant(
        speciesId: 'dummy',
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runMoveResolved(
        move: attacker.moves.single,
        attackerSlot: const BattleSlotRef.active(BattleSideId.player),
        targetSlot: const BattleSlotRef.active(BattleSideId.enemy),
        attacker: attacker,
        defender: defender,
        field: const BattleFieldState(),
        wasImmune: false,
        rng: const BattleSeededRng(),
      );

      expect(result.attacker.volatileState.mustRecharge, isTrue);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.rechargeRequired),
      );
      expect(
        result.volatileEvents.single.actorSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
    });

    test('runMoveResolved can set a weather state through the field rules', () {
      final attacker = _combatant(
        speciesId: 'rainmon',
        moves: <BattleMove>[
          _move(
            id: 'rain_dance',
            name: 'Rain Dance',
            power: 0,
            type: 'water',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.field,
            accuracy: const BattleMoveAccuracy.alwaysHits(),
            weatherEffect: BattleWeatherId.rain,
          ),
        ],
      );
      final defender = _combatant(
        speciesId: 'dummy',
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runMoveResolved(
        move: attacker.moves.single,
        attackerSlot: const BattleSlotRef.active(BattleSideId.player),
        targetSlot: const BattleSlotRef.active(BattleSideId.enemy),
        attacker: attacker,
        defender: defender,
        field: const BattleFieldState(),
        wasImmune: false,
        rng: const BattleSeededRng(),
      );

      expect(result.field.weather?.id, equals(BattleWeatherId.rain));
      expect(result.field.weather?.remainingTurns, equals(5));
      expect(
        result.fieldEvents.single.kind,
        equals(BattleFieldEventKind.weatherSet),
      );
      expect(result.fieldEvents.single.targetSlot, isNull);
    });

    test('runForcedContinueTurn spends the recharge turn and clears it', () {
      final combatant = _combatant(
        speciesId: 'beammon',
        volatileState: const BattleVolatileState(
          mustRecharge: true,
        ),
        moves: <BattleMove>[_move(id: 'hyper_beam')],
      );

      final result = engine.runForcedContinueTurn(
        combatantSlot: const BattleSlotRef.active(BattleSideId.player),
        combatant: combatant,
      );

      expect(result.combatant.volatileState.mustRecharge, isFalse);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.rechargeTurnSpent),
      );
      expect(
        result.volatileEvents.single.actorSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
    });

    test(
        'runEndOfTurn applies toxic and sandstorm, expires field, and clears transient protect',
        () {
      final player = _combatant(
        speciesId: 'player',
        majorStatus: const BattleMajorStatusState.tox(toxicCounter: 2),
        volatileState: const BattleVolatileState(
          protectActive: true,
        ),
        typing: const BattleTypingSnapshot(primaryType: 'grass'),
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );
      final enemy = _combatant(
        speciesId: 'enemy',
        typing: const BattleTypingSnapshot(primaryType: 'grass'),
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runEndOfTurn(
        player: player,
        enemy: enemy,
        field: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.sandstorm,
            remainingTurns: 1,
          ),
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 1,
          ),
        ),
      );

      expect(result.player.majorStatus?.id, equals(BattleMajorStatusId.tox));
      expect(result.player.majorStatus?.toxicCounter, equals(3));
      expect(result.player.volatileState.protectActive, isFalse);
      expect(result.player.currentHp, equals(82));
      expect(result.enemy.currentHp, equals(94));
      expect(result.field.weather, isNull);
      expect(result.field.pseudoWeather, isNull);
      expect(
        result.statusEvents.single.kind,
        equals(BattleStatusEventKind.residualDamage),
      );
      expect(
        result.statusEvents.single.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(
        result.fieldEvents.map((event) => event.kind).toList(growable: false),
        equals(<BattleFieldEventKind>[
          BattleFieldEventKind.weatherResidualDamage,
          BattleFieldEventKind.weatherResidualDamage,
          BattleFieldEventKind.weatherExpired,
          BattleFieldEventKind.pseudoWeatherExpired,
        ]),
      );
      expect(
        result.fieldEvents
            .where(
              (event) =>
                  event.kind == BattleFieldEventKind.weatherResidualDamage,
            )
            .map((event) => event.targetSlot)
            .toList(growable: false),
        equals(<BattleSlotRef?>[
          const BattleSlotRef.active(BattleSideId.player),
          const BattleSlotRef.active(BattleSideId.enemy),
        ]),
      );
    });

    test(
        'resolveStatusDamageMultiplier centralizes the burn malus for physical damage',
        () {
      final attacker = _combatant(
        speciesId: 'burned',
        majorStatus: const BattleMajorStatusState.brn(),
        moves: <BattleMove>[
          _move(
            id: 'slash',
            power: 70,
            category: BattleMoveCategory.physical,
          ),
        ],
      );

      final physicalMultiplier = engine.resolveStatusDamageMultiplier(
        move: attacker.moves.single,
        attacker: attacker,
      );
      final specialMultiplier = engine.resolveStatusDamageMultiplier(
        move: _move(
          id: 'flamethrower',
          power: 90,
          type: 'fire',
          category: BattleMoveCategory.special,
        ),
        attacker: attacker,
      );

      expect(physicalMultiplier, equals(0.5));
      expect(specialMultiplier, equals(1.0));
    });

    test(
        'resolveStatusAdjustedSpeed centralizes the paralysis slow with honest clamping',
        () {
      final paralyzed = _combatant(
        speciesId: 'slowpoke',
        majorStatus: const BattleMajorStatusState.par(),
        moves: <BattleMove>[_move(id: 'tackle')],
      );

      expect(
        engine.resolveStatusAdjustedSpeed(
          combatant: paralyzed,
          stagedSpeed: 13,
        ),
        equals(6),
      );
      expect(
        engine.resolveStatusAdjustedSpeed(
          combatant: paralyzed,
          stagedSpeed: 1,
        ),
        equals(1),
      );
    });
  });
}
