import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_combatant.dart';
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
  doubleIronBash,
  tripleKick,
  populationBomb,
  waterShuriken,
  scaleShot,
}

/// Ports the first deterministic slice of PSDK multi-hit moves.
///
/// This covers the Ruby `TwoHit`, `ThreeHit`, base `MultiHit`, Triple Kick and
/// Population Bomb classes. The strict `s_multi_hit` slice includes PSDK's
/// random 2-5 distribution plus local Skill Link and Loaded Dice hit-count
/// hooks. Water Shuriken also accepts the Studio `s_multi_hit` import row while
/// preserving Pokemon SDK's Ash-Greninja override.
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
        _kind = _MultiHitKind.waterShuriken;

  const MultiHitMoveBehavior.doubleIronBash()
      : battleEngineMethod = 's_double_iron_bash',
        _hitCount = 2,
        _kind = _MultiHitKind.doubleIronBash;

  const MultiHitMoveBehavior.scaleShot()
      : battleEngineMethod = 's_scale_shot',
        _hitCount = null,
        _kind = _MultiHitKind.scaleShot;

  @override
  final String battleEngineMethod;
  final int? _hitCount;
  final _MultiHitKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final targetIsMinimized = _kind == _MultiHitKind.doubleIronBash &&
        context.state.battlerAt(context.target).effects.contains(
              'minimize',
            );
    final prepared = prepareBattleMove(
      context,
      forceAccuracyBypass: targetIsMinimized,
    );
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
          field: state.field,
          state: state,
          userSlot: context.user,
          targetSlot: target,
          overrides: BattleMoveDamageOverrides(
            power: _powerForHit(
              user: user,
              move: context.move,
              movePower: context.move.power,
              hitIndex: hitIndex,
              targetIsMinimized: targetIsMinimized,
            ),
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
        move: context.move,
        isFinalHit: hitIndex == hitPlan.hitCount - 1,
      );
      state = applied.state;
      rng = applied.rng;
      if (applied.event != null) {
        dealtDamage = true;
        events.addAll(applied.events);
      }
    }

    if (dealtDamage) {
      final secondaryTarget =
          _kind == _MultiHitKind.scaleShot ? context.user : target;
      final secondary = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: rng,
        user: context.user,
        target: secondaryTarget,
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
    if (_usesAshGreninjaWaterShuriken(
      kind: _kind,
      move: context.move,
      user: prepared.state.battlerAt(context.user),
    )) {
      return _ResolvedHitCount(hitCount: 3, rng: prepared.rng);
    }
    if (forced != null) {
      return _ResolvedHitCount(hitCount: forced, rng: prepared.rng);
    }
    return switch (_kind) {
      _MultiHitKind.fixed || _MultiHitKind.doubleIronBash => _ResolvedHitCount(
          hitCount: _hitCount!,
          rng: prepared.rng,
        ),
      _MultiHitKind.psdkRandomTwoToFive ||
      _MultiHitKind.waterShuriken ||
      _MultiHitKind.scaleShot =>
        _resolvePsdkRandomHitCount(
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

  int _powerForHit({
    required PsdkBattleCombatant user,
    required BattleMoveDefinition move,
    required int movePower,
    required int hitIndex,
    required bool targetIsMinimized,
  }) {
    if (_usesAshGreninjaWaterShuriken(
      kind: _kind,
      move: move,
      user: user,
    )) {
      return 20;
    }
    return switch (_kind) {
      _MultiHitKind.doubleIronBash when targetIsMinimized => movePower * 2,
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
  for (final effect in context.state.activeItemEffectsAt(context.user)) {
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

bool _usesAshGreninjaWaterShuriken({
  required _MultiHitKind kind,
  required BattleMoveDefinition move,
  required PsdkBattleCombatant user,
}) {
  if (!_isWaterShuriken(kind: kind, move: move)) {
    return false;
  }
  // Pokemon SDK has BATTLE_BOND_GEN_NINE set to false in the referenced
  // script, so form 1 keeps the pre-gen-9 fixed 3-hit, 20-power behavior.
  return user.speciesId.trim().toLowerCase() == 'greninja' && user.form == 1;
}

bool _isWaterShuriken({
  required _MultiHitKind kind,
  required BattleMoveDefinition move,
}) {
  return kind == _MultiHitKind.waterShuriken ||
      move.dbSymbol.trim().toLowerCase() == 'water_shuriken';
}
