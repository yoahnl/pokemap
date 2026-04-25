import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/ability/ability_effect.dart';
import '../../effect/item/item_effect.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

const List<int> _psdkMultiHitChances = <int>[2, 2, 2, 3, 3, 5, 4, 3];

enum _MultiHitKind {
  fixed,
  psdkRandomTwoToFive,
  tripleKick,
  populationBomb,
}

/// Ports the first deterministic slice of PSDK multi-hit moves.
///
/// This covers the Ruby `TwoHit`, `ThreeHit`, base `MultiHit`, Triple Kick and
/// Population Bomb classes. Ability/form-specific branches such as Skill Link,
/// Population Bomb's `always_hit?` override and Ash-Greninja Water Shuriken stay
/// partial until those combatant contracts exist in the PSDK lane.
final class MultiHitMoveBehavior implements BattleMoveBehavior {
  const MultiHitMoveBehavior.fixed({
    required this.battleEngineMethod,
    required int hitCount,
  })  : _hitCount = hitCount,
        _kind = _MultiHitKind.fixed;

  const MultiHitMoveBehavior.psdkRandom()
      : battleEngineMethod = 's_multi_hit',
        _hitCount = null,
        _kind = _MultiHitKind.psdkRandomTwoToFive;

  const MultiHitMoveBehavior.tripleKick()
      : battleEngineMethod = 's_triple_kick',
        _hitCount = 3,
        _kind = _MultiHitKind.tripleKick;

  const MultiHitMoveBehavior.populationBomb()
      : battleEngineMethod = 's_population_bomb',
        _hitCount = 10,
        _kind = _MultiHitKind.populationBomb;

  const MultiHitMoveBehavior.waterShuriken()
      : battleEngineMethod = 's_water_shuriken',
        _hitCount = null,
        _kind = _MultiHitKind.psdkRandomTwoToFive;

  @override
  final String battleEngineMethod;
  final int? _hitCount;
  final _MultiHitKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final target = prepared.psdkTargets.single;
    final hitPlan = _resolveHitCount(context, prepared, target);
    var state = prepared.state;
    var rng = hitPlan.rng;
    var dealtDamage = false;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (var hitIndex = 0; hitIndex < hitPlan.hitCount; hitIndex += 1) {
      final user = state.battlerAt(context.user);
      final targetBattler = state.battlerAt(target);
      if (user.isFainted || targetBattler.isFainted) {
        break;
      }

      if (_rechecksAccuracy && hitIndex > 0) {
        final accuracy = _resolveExtraHitAccuracy(
          state: state,
          user: context.user,
          target: target,
          move: context.move,
          rng: rng,
          moveAccuracy: context.move.accuracy,
        );
        rng = accuracy.rng;
        if (!accuracy.didHit) {
          events.add(
            PsdkBattleMissEvent(
              user: context.user,
              target: target,
              moveId: context.move.id,
            ),
          );
          break;
        }
      }

      // PSDK plays the animation again after the first successful hit. The
      // common procedure already emitted the first cue, so only repeat extras.
      if (hitIndex > 0) {
        events.add(
          PsdkBattleAnimationCueEvent(
            user: context.user,
            target: target,
            moveId: context.move.id,
          ),
        );
      }

      final damage = const BattleMoveDamageCalculator().calculate(
        BattleMoveDamageContext(
          user: user,
          target: targetBattler,
          move: context.move,
          rng: rng,
          overrides: BattleMoveDamageOverrides(
            power: _powerForHit(context.move.power, hitIndex),
          ),
        ),
      );
      rng = damage.rng;
      if (damage.damage <= 0) {
        continue;
      }

      final applied = applyDirectDamage(
        state: state,
        user: context.user,
        target: target,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: damage.damage,
      );
      state = applied.state;
      rng = applied.rng;
      if (applied.event != null) {
        dealtDamage = true;
        events.add(applied.event!);
      }
    }

    if (dealtDamage) {
      final secondary = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: rng,
        user: context.user,
        target: target,
        move: context.move,
        turn: context.turn,
      );
      state = secondary.state;
      rng = secondary.rng;
      events.addAll(secondary.events);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  _ResolvedHitCount _resolveHitCount(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
    PsdkBattleSlotRef target,
  ) {
    final forced = _forcedHitCount(
      context: context,
      state: prepared.state,
      target: target,
    );
    if (forced != null) {
      return _ResolvedHitCount(hitCount: forced, rng: prepared.rng);
    }
    return switch (_kind) {
      _MultiHitKind.fixed => _ResolvedHitCount(
          hitCount: _hitCount!,
          rng: prepared.rng,
        ),
      _MultiHitKind.psdkRandomTwoToFive => _resolvePsdkRandomHitCount(
          context: context,
          prepared: prepared,
        ),
      _MultiHitKind.tripleKick ||
      _MultiHitKind.populationBomb =>
        _ResolvedHitCount(
          hitCount: _hitCount!,
          rng: prepared.rng,
        ),
    };
  }

  _ResolvedHitCount _resolvePsdkRandomHitCount({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final roll = prepared.rng.generic.nextIntInclusive(
      min: 0,
      max: _psdkMultiHitChances.length - 1,
    );
    final rolledHitCount = _psdkMultiHitChances[roll.value];
    final minimumHitCount = _minimumHitCount(context);
    return _ResolvedHitCount(
      hitCount: minimumHitCount == null || rolledHitCount >= minimumHitCount
          ? rolledHitCount
          : minimumHitCount,
      rng: prepared.rng.copyWith(generic: roll.next),
    );
  }

  bool get _rechecksAccuracy {
    return switch (_kind) {
      _MultiHitKind.tripleKick || _MultiHitKind.populationBomb => true,
      _ => false,
    };
  }

  int _powerForHit(int movePower, int hitIndex) {
    return switch (_kind) {
      _MultiHitKind.tripleKick => movePower * (hitIndex + 1),
      _ => movePower,
    };
  }

  _ExtraHitAccuracy _resolveExtraHitAccuracy({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required BattleMoveDefinition move,
    required BattleRngStreams rng,
    required int moveAccuracy,
  }) {
    final abilityContext = BattleAbilityMoveContext(
      state: state,
      user: user,
      target: target,
      move: move,
    );
    if (moveAccuracy <= 0 ||
        moveAccuracy >= 100 ||
        state.activeAbilityEffects().any(
              (effect) => effect.bypassesAccuracy(abilityContext),
            ) ||
        state.battlerAt(user).abilityEffects.any(
              (effect) => effect.bypassesMultiHitAccuracyRecheck(
                abilityContext,
              ),
            )) {
      return _ExtraHitAccuracy(didHit: true, rng: rng);
    }
    final roll = rng.moveAccuracy.nextPercent();
    return _ExtraHitAccuracy(
      didHit: roll.value <= moveAccuracy,
      rng: rng.copyWith(moveAccuracy: roll.next),
    );
  }
}

int? _forcedHitCount({
  required BattleMoveBehaviorContext context,
  required PsdkBattleState state,
  required PsdkBattleSlotRef target,
}) {
  final abilityContext = BattleAbilityMoveContext(
    state: state,
    user: context.user,
    target: target,
    move: context.move,
  );
  for (final effect in state.battlerAt(context.user).abilityEffects) {
    final hitCount = effect.forcedHitCount(abilityContext);
    if (hitCount != null) {
      return hitCount;
    }
  }
  return null;
}

int? _minimumHitCount(BattleMoveBehaviorContext context) {
  for (final effect in context.state.battlerAt(context.user).itemEffects) {
    final minimum = effect.minimumHitCount(context.move);
    if (minimum != null) {
      return minimum;
    }
  }
  return null;
}

final class _ResolvedHitCount {
  const _ResolvedHitCount({
    required this.hitCount,
    required this.rng,
  });

  final int hitCount;
  final BattleRngStreams rng;
}

final class _ExtraHitAccuracy {
  const _ExtraHitAccuracy({
    required this.didHit,
    required this.rng,
  });

  final bool didHit;
  final BattleRngStreams rng;
}
