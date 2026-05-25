import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK effect lifecycle and Baton Pass transfer', () {
    test('timed generic effect ticks and emits a lifecycle event', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'player',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                GenericBattleEffect(
                  id: 'gravity',
                  scope: BattlerBattleEffectScope(psdkPlayerSlot),
                  remainingTurns: 2,
                ),
              ),
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'opponent'),
          ),
        },
      );

      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 4,
          user: psdkPlayerSlot,
        ),
      );
      final effect = result.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .singleWhere((effect) => effect.id == 'gravity');
      final event = result.events.whereType<PsdkBattleEffectEvent>().single;

      expect(effect.remainingTurns, 1);
      expect(event.kind, 'effect_ticked');
      expect(event.target, psdkPlayerSlot);
      expect(event.effectId, 'gravity');
      expect(event.remainingTurns, 1);
      expect(event.reason, 'duration_tick');
    });

    test('timed generic effect expires and emits a lifecycle event', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'player',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                GenericBattleEffect(
                  id: 'gravity',
                  scope: BattlerBattleEffectScope(psdkPlayerSlot),
                  remainingTurns: 1,
                ),
              ),
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'opponent'),
          ),
        },
      );

      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 5,
          user: psdkPlayerSlot,
        ),
      );
      final event = result.events.whereType<PsdkBattleEffectEvent>().single;

      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('gravity'),
        isFalse,
      );
      expect(event.kind, 'effect_removed');
      expect(event.target, psdkPlayerSlot);
      expect(event.effectId, 'gravity');
      expect(event.remainingTurns, 0);
      expect(event.reason, 'expired');
    });

    test('item_stolen marker clears when the holder receives an item', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'player',
              effects: const PsdkBattleEffectStack.empty().add('item_stolen'),
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'opponent'),
          ),
        },
      );

      final result =
          state.battlerAt(psdkPlayerSlot).effects.dispatchPostItemChange(
                BattleEffectItemChangeContext(
                  state: state,
                  rng: _rng(),
                  turn: 3,
                  owner: psdkPlayerSlot,
                  target: psdkPlayerSlot,
                  previousItemId: null,
                  nextItemId: 'leftovers',
                  consumedItemId: null,
                  reason: 'changed',
                ),
              );

      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('item_stolen'),
        isFalse,
      );
    });

    test('effect lifecycle events map to clean timeline events', () {
      const event = PsdkBattleEffectEvent.ticked(
        turn: 6,
        target: psdkPlayerSlot,
        effectId: 'gravity',
        remainingTurns: 1,
        reason: 'duration_tick',
      );

      final timelineEvent =
          BattleTimelineEvent.fromPsdk(event) as BattleEffectTimelineEvent;

      expect(timelineEvent.kind, 'effect_ticked');
      expect(timelineEvent.turn, 6);
      expect(timelineEvent.target.bank, psdkPlayerSlot.bank);
      expect(timelineEvent.target.position, psdkPlayerSlot.position);
      expect(timelineEvent.effectId, 'gravity');
      expect(timelineEvent.remainingTurns, 1);
      expect(timelineEvent.reason, 'duration_tick');
      expect(timelineEvent.toJson(), <String, Object?>{
        'kind': 'effect_ticked',
        'turn': 6,
        'target': <String, int>{'bank': 0, 'position': 0},
        'effectId': 'gravity',
        'remainingTurns': 1,
        'reason': 'duration_tick',
      });
    });

    test('effect stack transfers only Baton Pass compatible effects', () {
      final stack = const PsdkBattleEffectStack.empty()
          .addEffect(
            const AquaRingEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
            ),
          )
          .addEffect(
            const CurseEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
            ),
          )
          .addEffect(
            const IngrainEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
            ),
          )
          .addEffect(
            const LeechSeedEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
              source: psdkOpponentSlot,
            ),
          )
          .addEffect(
            const ProtectEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
            ),
          )
          .addEffect(
            const BatonPassEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
            ),
          );

      final transferred = stack.batonPassTransferEffects(
        source: psdkPlayerSlot,
        target: _benchSlot,
      );

      expect(
        transferred.values,
        <String>['aqua_ring', 'curse', 'ingrain', 'leech_seed'],
      );
      expect(
        transferred.effects
            .map((effect) => (effect.scope as BattlerBattleEffectScope).slot),
        everyElement(_benchSlot),
      );
    });

    test('BattleSwitchHandler Baton Pass copies stages and effects to incoming',
        () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'source',
              statStages: PsdkBattleStatStages(
                values: const <String, int>{
                  'attack': 2,
                  'speed': -1,
                },
              ),
              effects: const PsdkBattleEffectStack.empty()
                  .addEffect(
                    const BatonPassEffect(
                      scope: BattlerBattleEffectScope(psdkPlayerSlot),
                    ),
                  )
                  .addEffect(
                    const AquaRingEffect(
                      scope: BattlerBattleEffectScope(psdkPlayerSlot),
                    ),
                  )
                  .addEffect(
                    const IngrainEffect(
                      scope: BattlerBattleEffectScope(psdkPlayerSlot),
                    ),
                  )
                  .addEffect(
                    const ProtectEffect(
                      scope: BattlerBattleEffectScope(psdkPlayerSlot),
                    ),
                  ),
            ),
          ),
          _benchSlot: PsdkBattleCombatant.fromSetup(_combatant(id: 'bench')),
        },
      );

      final result = const BattleSwitchHandler().batonPassTransfer(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 4,
          user: psdkPlayerSlot,
        ),
        source: psdkPlayerSlot,
        replacement: _benchSlot,
      );
      final source = result.state.battlerAt(psdkPlayerSlot);
      final replacement = result.state.battlerAt(_benchSlot);

      expect(result.applied, isTrue);
      expect(source.statStages.values, isEmpty);
      expect(source.effects.contains('baton_pass'), isFalse);
      expect(source.effects.contains('aqua_ring'), isFalse);
      expect(source.effects.contains('ingrain'), isFalse);
      expect(replacement.statStages.valueOf('attack'), 2);
      expect(replacement.statStages.valueOf('speed'), -1);
      expect(replacement.effects.contains('aqua_ring'), isTrue);
      expect(replacement.effects.contains('ingrain'), isTrue);
      expect(replacement.effects.contains('protect'), isFalse);
    });

    test('Ingrain prevents regular switch-out attempts', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'source',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                const IngrainEffect(
                  scope: BattlerBattleEffectScope(psdkPlayerSlot),
                ),
              ),
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'opponent'),
          ),
        },
      );

      final result = const BattleSwitchHandler().resolveSwitchPrevention(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 4,
          user: psdkPlayerSlot,
        ),
        target: psdkPlayerSlot,
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'ingrain');
    });

    test('Leech Seed drains the seeded target and heals the source', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'source', currentHp: 40),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'seeded',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                const LeechSeedEffect(
                  scope: BattlerBattleEffectScope(psdkOpponentSlot),
                  source: psdkPlayerSlot,
                ),
              ),
            ),
          ),
        },
      );

      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 4,
          user: psdkPlayerSlot,
        ),
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 88);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 52);
      expect(
          result.events.whereType<PsdkBattleDamageEvent>().single.damage, 12);
      expect(result.events.whereType<PsdkBattleHealEvent>().single.amount, 12);
    });

    test('Leech Seed healing is boosted when the source holds Big Root', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'source',
              currentHp: 40,
              heldItemId: 'big_root',
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'seeded',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                const LeechSeedEffect(
                  scope: BattlerBattleEffectScope(psdkOpponentSlot),
                  source: psdkPlayerSlot,
                ),
              ),
            ),
          ),
        },
      );

      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 4,
          user: psdkPlayerSlot,
        ),
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 88);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 55);
      expect(
          result.events.whereType<PsdkBattleDamageEvent>().single.damage, 12);
      expect(result.events.whereType<PsdkBattleHealEvent>().single.amount, 15);
    });

    test('Leech Seed damages the source when the seeded target has Liquid Ooze',
        () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'source', currentHp: 40),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'seeded',
              abilityId: 'liquid_ooze',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                const LeechSeedEffect(
                  scope: BattlerBattleEffectScope(psdkOpponentSlot),
                  source: psdkPlayerSlot,
                ),
              ),
            ),
          ),
        },
      );

      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 4,
          user: psdkPlayerSlot,
        ),
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 88);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 28);
      expect(result.events.whereType<PsdkBattleHealEvent>(), isEmpty);
      expect(
        result.events
            .whereType<PsdkBattleDamageEvent>()
            .map((event) => event.damage),
        <int>[12, 12],
      );
    });

    test('Leech Seed Liquid Ooze damage skips a Magic Guard source', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'source',
              currentHp: 40,
              abilityId: 'magic_guard',
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'seeded',
              abilityId: 'liquid_ooze',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                const LeechSeedEffect(
                  scope: BattlerBattleEffectScope(psdkOpponentSlot),
                  source: psdkPlayerSlot,
                ),
              ),
            ),
          ),
        },
      );

      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 4,
          user: psdkPlayerSlot,
        ),
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 88);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 40);
      expect(result.events.whereType<PsdkBattleHealEvent>(), isEmpty);
      expect(result.events.whereType<PsdkBattleDamageEvent>(), hasLength(1));
    });

    test('Confusion can self-hit and prevent the user before PP is spent', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          player: _combatant(
            id: 'confused',
            effects: PsdkBattleEffectStack(
              values: const <String>[PsdkBattleEffectIds.confusion],
            ),
          ),
          genericSeed: 2,
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);
      final damageEvents =
          result.timeline.events.whereType<PsdkBattleDamageEvent>();
      final failedEvents =
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>();

      expect(player.currentHp, 92);
      expect(player.moves.single.currentPp, 35);
      expect(player.effects.contains(PsdkBattleEffectIds.confusion), isTrue);
      expect(damageEvents.single.moveId, 'effect:confusion');
      expect(damageEvents.single.user, psdkPlayerSlot);
      expect(damageEvents.single.target, psdkPlayerSlot);
      expect(damageEvents.single.damage, 8);
      expect(failedEvents.single.moveId, 'splash');
      expect(failedEvents.single.reason, 'unusable_by_user');
    });

    test('Confusion decrements on clean action then clears on its last turn',
        () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          player: _combatant(
            id: 'confused',
            effects: PsdkBattleEffectStack(
              values: const <String>[PsdkBattleEffectIds.confusion],
            ),
          ),
          genericSeed: 1,
        ),
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(first.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(first.state.battlerAt(psdkPlayerSlot).moves.single.currentPp, 34);
      expect(
        first.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.confusion),
        isTrue,
      );
      expect(
        first.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .where((event) => event.user == psdkPlayerSlot),
        isEmpty,
      );
      expect(second.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(
        second.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.confusion),
        isFalse,
      );
      expect(
        second.timeline.events
            .whereType<PsdkBattleDamageEvent>()
            .where((event) => event.moveId == 'effect:confusion'),
        isEmpty,
      );
    });
  });
}

const _benchSlot = PsdkBattleSlotRef(bank: 0, position: -1);

PsdkBattleCombatantSetup _combatant({
  required String id,
  int currentHp = 100,
  String? heldItemId,
  String? abilityId,
  PsdkBattleStatStages? statStages,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    heldItemId: heldItemId,
    abilityId: abilityId,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[_move(id: 'splash')],
    statStages: statStages,
    effects: effects,
  );
}

PsdkBattleMoveData _move({required String id}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 0,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: 's_splash',
    target: PsdkBattleMoveTarget.none,
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

PsdkBattleSetup _setup({
  PsdkBattleCombatantSetup? player,
  PsdkBattleCombatantSetup? opponent,
  int genericSeed = 4,
}) {
  return PsdkBattleSetup.singles(
    player: player ?? _combatant(id: 'player'),
    opponent: opponent ?? _combatant(id: 'opponent'),
    rngSeeds: PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 2,
      moveAccuracy: 3,
      generic: genericSeed,
    ),
  );
}
