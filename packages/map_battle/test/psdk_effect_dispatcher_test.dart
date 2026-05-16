import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK generic effect dispatcher', () {
    test('runs end-turn effects in stack order and composes state', () {
      final log = <String>[];
      final state = _state(
        effects: const PsdkBattleEffectStack.empty()
            .addEffect(
              _EndTurnProbeEffect(
                id: 'first',
                log: log,
                run: (context) {
                  log.add('first');
                  return _addMarker('first_marker')(context);
                },
              ),
            )
            .addEffect(
              _EndTurnProbeEffect(
                id: 'second',
                log: log,
                run: (context) {
                  log.add(
                    context.state
                            .battlerAt(context.owner)
                            .effects
                            .contains('first_marker')
                        ? 'second_saw_first_marker'
                        : 'second_missed_first_marker',
                  );
                  return BattleEffectEndTurnResult(
                    state: context.state,
                    rng: context.rng,
                  );
                },
              ),
            ),
      );

      final result = state.battlerAt(psdkPlayerSlot).effects.dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: state,
              rng: _rng(),
              turn: 7,
              owner: psdkPlayerSlot,
            ),
          );

      expect(log, <String>['first', 'second_saw_first_marker']);
      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('first_marker'),
        isTrue,
      );
      expect(result.applied, isTrue);
    });

    test('skips an effect removed earlier in the same dispatch', () {
      final log = <String>[];
      final state = _state(
        effects: const PsdkBattleEffectStack.empty()
            .addEffect(
              _EndTurnProbeEffect(
                id: 'first',
                log: log,
                run: (context) {
                  log.add('first');
                  return BattleEffectEndTurnResult(
                    state: context.state.updateBattler(
                      context.owner,
                      (battler) => battler.copyWith(
                        effects: battler.effects.remove('second'),
                      ),
                    ),
                    rng: context.rng,
                  );
                },
              ),
            )
            .addEffect(
              _EndTurnProbeEffect(
                id: 'second',
                log: log,
                run: (context) {
                  log.add('second');
                  return BattleEffectEndTurnResult(
                    state: context.state,
                    rng: context.rng,
                  );
                },
              ),
            ),
      );

      final result = state.battlerAt(psdkPlayerSlot).effects.dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: state,
              rng: _rng(),
              turn: 7,
              owner: psdkPlayerSlot,
            ),
          );

      expect(log, <String>['first']);
      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('second'),
        isFalse,
      );
    });

    test('post-damage effects compose after damage in stack order', () {
      final log = <String>[];
      final state = _state(
        effects: const PsdkBattleEffectStack.empty()
            .addEffect(
              _PostDamageProbeEffect(
                id: 'first',
                log: log,
                markerId: 'first_post_damage',
              ),
            )
            .addEffect(
              _PostDamageProbeEffect(
                id: 'second',
                log: log,
                markerId: 'second_post_damage',
              ),
            ),
      );

      final result = state.battlerAt(psdkPlayerSlot).effects.dispatchPostDamage(
            BattleEffectPostDamageContext(
              state: state,
              rng: _rng(),
              turn: 7,
              owner: psdkPlayerSlot,
              user: psdkPlayerSlot,
              target: psdkOpponentSlot,
              move: _move(),
              damage: 12,
            ),
          );

      expect(log, <String>['first:12', 'second:12']);
      expect(
        result.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains('first_post_damage'),
        isTrue,
      );
      expect(
        result.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains('second_post_damage'),
        isTrue,
      );
    });
  });
}

typedef _EndTurnRun = BattleEffectEndTurnResult Function(
  BattleEffectEndTurnContext context,
);

final class _EndTurnProbeEffect extends BattleEffect {
  _EndTurnProbeEffect({
    required String id,
    required this.log,
    required this.run,
  }) : super(id: id, scope: const BattlerBattleEffectScope(psdkPlayerSlot));

  final List<String> log;
  final _EndTurnRun run;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return _EndTurnProbeEffect(id: id, log: log, run: run);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    return run(context);
  }
}

final class _PostDamageProbeEffect extends BattleEffect {
  _PostDamageProbeEffect({
    required String id,
    required this.log,
    required this.markerId,
  }) : super(id: id, scope: const BattlerBattleEffectScope(psdkPlayerSlot));

  final List<String> log;
  final String markerId;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return _PostDamageProbeEffect(id: id, log: log, markerId: markerId);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    log.add('$id:${context.damage}');
    return BattleEffectPostDamageResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(
          effects: battler.effects.add(markerId),
        ),
      ),
      rng: context.rng,
    );
  }
}

_EndTurnRun _addMarker(String markerId) {
  return (context) {
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(
          effects: battler.effects.add(markerId),
        ),
      ),
      rng: context.rng,
    );
  };
}

PsdkBattleState _state({required PsdkBattleEffectStack effects}) {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'player', effects: effects),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(_combatant(id: 'foe')),
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'tackle',
        dbSymbol: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 40,
        accuracy: 100,
        pp: 35,
        priority: 0,
        criticalRate: 1,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
    effects: effects,
  );
}

BattleMoveDefinition _move() {
  return BattleMoveDefinition(
    id: 'tackle',
    dbSymbol: 'tackle',
    name: 'Tackle',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}
