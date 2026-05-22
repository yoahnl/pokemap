import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/effect/battle_effect_registry.dart';
import 'package:map_battle/src/domain/effect/move/embargo_effect.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK move marker effects', () {
    test('Focus Punch mirrors PSDK preparing_attack marker', () {
      const effect = FocusPunchEffect(
        scope: BattlerBattleEffectScope(psdkPlayerSlot),
      );

      expect(effect.id, 'focus_punch');
      expect(effect.preparingAttack, isTrue);
      expect(effect.remainingTurns, 0);
      expect(
        const PsdkBattleEffectStack.empty()
            .addEffect(effect)
            .clearTurnScopedEffects()
            .contains('focus_punch'),
        isFalse,
      );
    });

    test('Happy Hour hydrates as the passive PSDK effect', () {
      const effect = HappyHourEffect(scope: LocalBattleEffectScope());

      expect(effect.id, 'happy_hour');
      expect(effect.preparingAttack, isFalse);
      expect(
        const PsdkBattleEffectStack.empty()
            .addEffect(effect)
            .clearTurnScopedEffects()
            .contains('happy_hour'),
        isTrue,
      );
    });

    test('registry exposes Focus Punch and Happy Hour effects', () {
      const registry = BattleEffectRegistry();

      expect(registry.fromId('focus_punch'), isA<FocusPunchEffect>());
      expect(registry.fromId('happy_hour'), isA<HappyHourEffect>());
      expect(
        PsdkBattleEffectStack(values: const <String>[
          'focus_punch',
          'happy_hour',
        ]).effects,
        containsAll(<Matcher>[
          isA<FocusPunchEffect>(),
          isA<HappyHourEffect>(),
        ]),
      );
    });

    test(
        'Ability Suppressed carries its origin and transfers through Baton Pass',
        () {
      const benchSlot = PsdkBattleSlotRef(bank: 0, position: -1);
      const effect = AbilitySuppressedEffect(
        scope: BattlerBattleEffectScope(psdkPlayerSlot),
        origin: 'gastro_acid',
      );

      final combatant = PsdkBattleCombatant.fromSetup(
        _combatant(
          abilityId: 'no_guard',
          effects: const PsdkBattleEffectStack.empty().addEffect(effect),
        ),
      ).withAbilityEffect(psdkPlayerSlot);
      final transferred = effect.onBatonPassTransfer(
        const BattleEffectBatonPassContext(
          source: psdkPlayerSlot,
          target: benchSlot,
        ),
      );

      expect(combatant.abilityEffects, isEmpty);
      expect(transferred, isA<AbilitySuppressedEffect>());
      expect((transferred! as AbilitySuppressedEffect).origin, 'gastro_acid');
      expect(
        (transferred.scope as BattlerBattleEffectScope).slot,
        benchSlot,
      );
    });

    test('Lock On stores its target and extends duration through Baton Pass',
        () {
      const benchSlot = PsdkBattleSlotRef(bank: 0, position: -1);
      const effect = LockOnEffect(
        scope: BattlerBattleEffectScope(psdkPlayerSlot),
        target: psdkOpponentSlot,
        remainingTurns: 2,
      );

      final transferred = effect.onBatonPassTransfer(
        const BattleEffectBatonPassContext(
          source: psdkPlayerSlot,
          target: benchSlot,
        ),
      );

      expect(effect.id, 'lock_on');
      expect(effect.target, psdkOpponentSlot);
      expect(transferred, isA<LockOnEffect>());
      final lockOn = transferred! as LockOnEffect;
      expect(lockOn.target, psdkOpponentSlot);
      expect(lockOn.remainingTurns, 3);
      expect((lockOn.scope as BattlerBattleEffectScope).slot, benchSlot);
    });

    test('Triple Arrows carries the crit marker duration through Baton Pass',
        () {
      const benchSlot = PsdkBattleSlotRef(bank: 0, position: -1);
      const effect = TripleArrowsEffect(
        scope: BattlerBattleEffectScope(psdkPlayerSlot),
        remainingTurns: 4,
      );

      final transferred = effect.onBatonPassTransfer(
        const BattleEffectBatonPassContext(
          source: psdkPlayerSlot,
          target: benchSlot,
        ),
      );

      expect(effect.id, 'triple_arrows');
      expect(transferred, isA<TripleArrowsEffect>());
      expect(transferred!.remainingTurns, 4);
      expect(
        (transferred.scope as BattlerBattleEffectScope).slot,
        benchSlot,
      );
    });

    test('No Retreat prevents switching for its holder', () {
      final state = PsdkBattleState.fromSetup(
        PsdkBattleSetup.singles(
          player: _combatant(
            effects: const PsdkBattleEffectStack.empty().addEffect(
              NoRetreatEffect(scope: BattlerBattleEffectScope(psdkPlayerSlot)),
            ),
          ),
          opponent: _combatant(id: 'opponent'),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 2,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
      );

      final prevention = const BattleSwitchHandler().resolveSwitchPrevention(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkPlayerSlot,
      );

      expect(prevention.applied, isFalse);
      expect(prevention.reason, 'no_retreat');
    });

    test('Embargo counts down and expires through end-turn dispatch', () {
      final initialState = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              effects: const PsdkBattleEffectStack.empty().addEffect(
                EmbargoEffect(
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

      final ticked = initialState.battlerAt(psdkPlayerSlot).effects
          .dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: initialState,
              rng: _rng(),
              turn: 7,
              owner: psdkPlayerSlot,
            ),
          );

      final tickedEffect = ticked.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .singleWhere((effect) => effect.id == 'embargo');
      expect(tickedEffect, isA<EmbargoEffect>());
      expect(tickedEffect.remainingTurns, 1);

      final expired = ticked.state.battlerAt(psdkPlayerSlot).effects
          .dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: ticked.state,
              rng: ticked.rng,
              turn: 8,
              owner: psdkPlayerSlot,
            ),
          );

      expect(
        expired.state.battlerAt(psdkPlayerSlot).effects.contains('embargo'),
        isFalse,
      );
    });

    test('Powder remains a turn-scoped marker effect', () {
      final stack = const PsdkBattleEffectStack.empty().addEffect(
        const PowderEffect(
          scope: BattlerBattleEffectScope(psdkPlayerSlot),
        ),
      );

      expect(stack.contains('powder'), isTrue);
      expect(stack.clearTurnScopedEffects().contains('powder'), isFalse);
    });

    test('registry exposes carried move effect objects', () {
      const registry = BattleEffectRegistry();

      expect(
        registry.fromId('ability_suppressed'),
        isA<AbilitySuppressedEffect>(),
      );
      expect(registry.fromId('embargo'), isA<EmbargoEffect>());
      expect(registry.fromId('force_next_move_base'),
          isA<ForceNextMoveBaseEffect>());
      expect(registry.fromId('item_burnt'), isA<ItemBurntEffect>());
      expect(registry.fromId('lock_on'), isA<LockOnEffect>());
      expect(registry.fromId('no_retreat'), isA<NoRetreatEffect>());
      expect(registry.fromId('powder'), isA<PowderEffect>());
      expect(registry.fromId('triple_arrows'), isA<TripleArrowsEffect>());
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  String id = 'mon',
  String? abilityId,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 25,
    maxHp: 100,
    currentHp: 100,
    abilityId: abilityId,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[_move()],
    effects: effects,
  );
}

PsdkBattleMoveData _move() {
  return PsdkBattleMoveData(
    id: 'splash',
    dbSymbol: 'splash',
    name: 'Splash',
    type: 'normal',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 0,
    pp: 40,
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
