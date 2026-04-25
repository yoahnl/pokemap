import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../effect/battle_effect_scope.dart';
import '../../effect/move/aqua_ring_effect.dart';
import '../../effect/move/ingrain_effect.dart';
import '../../effect/move/leech_seed_effect.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

enum _PersistentEffectKind {
  aquaRing,
  ingrain,
  leechSeed,
}

final class PersistentEffectMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const PersistentEffectMoveBehavior.aquaRing()
      : battleEngineMethod = 's_aqua_ring',
        _kind = _PersistentEffectKind.aquaRing;

  const PersistentEffectMoveBehavior.ingrain()
      : battleEngineMethod = 's_ingrain',
        _kind = _PersistentEffectKind.ingrain;

  const PersistentEffectMoveBehavior.leechSeed()
      : battleEngineMethod = 's_leech_seed',
        _kind = _PersistentEffectKind.leechSeed;

  @override
  final String battleEngineMethod;
  final _PersistentEffectKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    return switch (_kind) {
      _PersistentEffectKind.aquaRing =>
        context.state.battlerAt(context.target).effects.contains('aqua_ring')
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
      _PersistentEffectKind.ingrain =>
        context.state.battlerAt(context.target).effects.contains('ingrain')
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
      _PersistentEffectKind.leechSeed =>
        _isLeechSeedImmune(context.state.battlerAt(context.target))
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.immunity,
              )
            : null,
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    final events = <PsdkBattleEvent>[...prepared.events];
    for (final target in prepared.psdkTargets) {
      final effect = switch (_kind) {
        _PersistentEffectKind.aquaRing =>
          state.battlerAt(target).effects.contains('aqua_ring')
              ? null
              : AquaRingEffect(scope: BattlerBattleEffectScope(target)),
        _PersistentEffectKind.ingrain =>
          state.battlerAt(target).effects.contains('ingrain')
              ? null
              : IngrainEffect(scope: BattlerBattleEffectScope(target)),
        _PersistentEffectKind.leechSeed =>
          _isLeechSeedImmune(state.battlerAt(target))
              ? null
              : LeechSeedEffect(
                  scope: BattlerBattleEffectScope(target),
                  source: context.user,
                ),
      };
      if (effect == null) {
        continue;
      }
      state = state.updateBattler(
        target,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(effect),
        ),
      );
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: prepared.rng,
      events: events,
    );
  }
}

bool _isLeechSeedImmune(PsdkBattleCombatant battler) {
  return battler.effects.contains('leech_seed') ||
      battler.effects.contains('substitute') ||
      battler.hasType('grass');
}
