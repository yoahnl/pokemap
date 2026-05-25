import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/effect/battle_effect_registry.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK residual move effects', () {
    test('Nightmare damages sleeping targets by one quarter at end turn', () {
      final state = _state(
        player: _combatant(
          currentHp: 80,
          majorStatus: PsdkBattleMajorStatus.sleep,
          effects: const PsdkBattleEffectStack.empty().addEffect(
            NightmareEffect(scope: BattlerBattleEffectScope(psdkPlayerSlot)),
          ),
        ),
      );

      final result = state.battlerAt(psdkPlayerSlot).effects.dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: state,
              rng: _rng(),
              turn: 1,
              owner: psdkPlayerSlot,
            ),
          );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 55);
      expect(
        result.events,
        contains(
          isA<PsdkBattleDamageEvent>()
              .having((event) => event.moveId, 'moveId', 'effect:nightmare')
              .having((event) => event.damage, 'damage', 25),
        ),
      );
    });

    test('Nightmare clears itself when the target is no longer asleep', () {
      final state = _state(
        player: _combatant(
          effects: const PsdkBattleEffectStack.empty().addEffect(
            NightmareEffect(scope: BattlerBattleEffectScope(psdkPlayerSlot)),
          ),
        ),
      );

      final result = state.battlerAt(psdkPlayerSlot).effects.dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: state,
              rng: _rng(),
              turn: 1,
              owner: psdkPlayerSlot,
            ),
          );

      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('nightmare'),
        isFalse,
      );
    });

    test('Perish Song counts down, transfers, then faints the holder', () {
      const effect = PerishSongEffect(
        scope: BattlerBattleEffectScope(psdkPlayerSlot),
        remainingTurns: 2,
      );
      final state = _state(
        player: _combatant(
          effects: const PsdkBattleEffectStack.empty().addEffect(effect),
        ),
      );

      final tick = state.battlerAt(psdkPlayerSlot).effects.dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: state,
              rng: _rng(),
              turn: 1,
              owner: psdkPlayerSlot,
            ),
          );

      expect(tick.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      final nextEffect = tick.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .whereType<PerishSongEffect>()
          .single;
      expect(nextEffect.remainingTurns, 1);
      expect(
        effect.onBatonPassTransfer(
          const BattleEffectBatonPassContext(
            source: psdkPlayerSlot,
            target: psdkOpponentSlot,
          ),
        ),
        isA<PerishSongEffect>().having(
          (transferred) => transferred.remainingTurns,
          'remainingTurns',
          2,
        ),
      );

      final faint =
          tick.state.battlerAt(psdkPlayerSlot).effects.dispatchEndTurn(
                BattleEffectEndTurnContext(
                  state: tick.state,
                  rng: tick.rng,
                  turn: 2,
                  owner: psdkPlayerSlot,
                ),
              );

      expect(faint.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(
        faint.state.battlerAt(psdkPlayerSlot).effects.contains('perish_song'),
        isFalse,
      );
    });

    test('BattleEffectRegistry hydrates residual move effects with state', () {
      const registry = BattleEffectRegistry();

      expect(registry.fromId('leech_seed'), isA<LeechSeedEffect>());
      expect(registry.fromId('wish'), isA<WishEffect>());
      expect(registry.fromId('nightmare'), isA<NightmareEffect>());
      expect(registry.fromId('perish_song'), isA<PerishSongEffect>());
    });
  });
}

PsdkBattleState _state({
  PsdkBattleCombatantSetup? player,
  PsdkBattleCombatantSetup? opponent,
}) {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(player ?? _combatant()),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(opponent ?? _combatant()),
    },
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

PsdkBattleCombatantSetup _combatant({
  int currentHp = 100,
  String? abilityId,
  String? heldItemId,
  PsdkBattleMajorStatus? majorStatus,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: 'mon',
    speciesId: 'mon',
    displayName: 'Mon',
    level: 50,
    maxHp: 100,
    currentHp: currentHp,
    abilityId: abilityId,
    heldItemId: heldItemId,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: 100,
    ),
    moves: <PsdkBattleMoveData>[_move()],
    majorStatus: majorStatus,
    effects: effects,
  );
}

PsdkBattleMoveData _move() {
  return PsdkBattleMoveData(
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
