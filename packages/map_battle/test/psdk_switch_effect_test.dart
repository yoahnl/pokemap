import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK generic switch hooks', () {
    test('Shed Shell bypasses opposing switch-prevention abilities', () {
      final state = PsdkBattleState.fromSetup(
        PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            heldItemId: 'shed_shell',
          ),
          opponent: _combatant(
            id: 'opponent',
            abilityId: 'shadow_tag',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 2,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
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

      expect(
        state.battlerAt(psdkPlayerSlot).effects.contains('item:shed_shell'),
        isTrue,
      );
      expect(result.applied, isTrue);
      expect(result.reason, isNull);
    });

    test('CantSwitch clears when its origin switches out without Baton Pass',
        () {
      const benchSlot = PsdkBattleSlotRef(bank: 0, position: -1);
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'origin'),
          ),
          benchSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'replacement'),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'trapped',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                CantSwitchEffect(
                  scope: BattlerBattleEffectScope(psdkOpponentSlot),
                  origin: psdkPlayerSlot,
                ),
              ),
            ),
          ),
        },
      );

      final result = const BattleSwitchHandler().dispatchSwitchEvents(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 4,
          user: psdkPlayerSlot,
        ),
        who: psdkPlayerSlot,
        replacement: benchSlot,
      );

      expect(
        result.state.battlerAt(psdkOpponentSlot).effects.contains(
              PsdkBattleEffectIds.cantSwitch,
            ),
        isFalse,
      );
      expect(result.events.whereType<PsdkBattleEffectEvent>().single.reason,
          'switch_origin_left');
    });

    test('CantSwitch survives when its origin switches through Baton Pass', () {
      const benchSlot = PsdkBattleSlotRef(bank: 0, position: -1);
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'origin',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                BatonPassEffect(
                  scope: BattlerBattleEffectScope(psdkPlayerSlot),
                ),
              ),
            ),
          ),
          benchSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'replacement'),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'trapped',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                CantSwitchEffect(
                  scope: BattlerBattleEffectScope(psdkOpponentSlot),
                  origin: psdkPlayerSlot,
                ),
              ),
            ),
          ),
        },
      );

      final result = const BattleSwitchHandler().dispatchSwitchEvents(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 4,
          user: psdkPlayerSlot,
        ),
        who: psdkPlayerSlot,
        replacement: benchSlot,
      );

      expect(
        result.state.battlerAt(psdkOpponentSlot).effects.contains(
              PsdkBattleEffectIds.cantSwitch,
            ),
        isTrue,
      );
      expect(result.events.whereType<PsdkBattleEffectEvent>(), isEmpty);
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? abilityId,
  String? heldItemId,
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
    abilityId: abilityId,
    heldItemId: heldItemId,
    effects: effects,
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
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
      ),
    ],
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
