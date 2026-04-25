import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK effect lifecycle and Baton Pass transfer', () {
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

      expect(transferred.values, <String>['aqua_ring', 'curse']);
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
      expect(replacement.statStages.valueOf('attack'), 2);
      expect(replacement.statStages.valueOf('speed'), -1);
      expect(replacement.effects.contains('aqua_ring'), isTrue);
      expect(replacement.effects.contains('protect'), isFalse);
    });
  });
}

const _benchSlot = PsdkBattleSlotRef(bank: 0, position: -1);

PsdkBattleCombatantSetup _combatant({
  required String id,
  PsdkBattleStatStages? statStages,
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
