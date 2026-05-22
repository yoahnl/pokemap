import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../../effect/ability/ability_effect.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

const Map<String, int> _psdkRecoilFactors = <String, int>{
  'brave_bird': 3,
  'double_edge': 3,
  'chloroblast': 2,
  'flare_blitz': 3,
  'head_charge': 4,
  'head_smash': 2,
  'light_of_ruin': 2,
  'shadow_end': 2,
  'shadow_rush': 16,
  'struggle': 4,
  'submission': 4,
  'take_down': 4,
  'volt_tackle': 3,
  'wave_crash': 3,
  'wild_charge': 4,
  'wood_hammer': 3,
};

const Set<String> _recoilFromUserMaxHp = <String>{
  'struggle',
  'shadow_rush',
};

const Set<String> _recoilFromUserCurrentHp = <String>{
  'shadow_end',
};

/// Ports the base PSDK `RecoilMove` family.
///
/// The target hit still uses the normal damage formula and shared move
/// procedure. Recoil is represented as a second damage event targeting the
/// user. The strict subset includes regular recoil, Rock Head prevention and
/// Reckless power; Parental Bond, dedicated messages and Basculin evolution
/// bookkeeping remain outside this lot.
final class RecoilMoveBehavior implements BattleMoveBehavior {
  const RecoilMoveBehavior.psdkRecoil() : battleEngineMethod = 's_recoil';

  const RecoilMoveBehavior.struggle() : battleEngineMethod = 's_struggle';

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      if (_isStudioMindBlown(context.move.dbSymbol) &&
          _shouldMindBlownCrashAfterFailure(prepared.failureReason)) {
        return _crashMindBlownUser(
          context: context,
          state: prepared.state,
          rng: prepared.rng,
          events: prepared.events,
          successful: false,
        );
      }
      return prepared.toResolution();
    }

    if (_isStudioMindBlown(context.move.dbSymbol)) {
      return _resolveStudioMindBlown(
        context: context,
        prepared: prepared,
      );
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final abilityContext = BattleAbilityMoveContext(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      move: context.move,
    );
    final resolvedPower = _resolvePowerWithAbility(
      user: user,
      context: abilityContext,
      movePower: context.move.power,
    );
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        field: prepared.state.field,
        state: prepared.state,
        userSlot: context.user,
        targetSlot: targetSlot,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final targetDamage = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    var state = targetDamage.state;
    final events = <PsdkBattleEvent>[
      ...prepared.events,
      if (targetDamage.event != null) targetDamage.event!,
    ];
    if (targetDamage.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: state,
        rng: damageResult.rng,
        events: events,
      );
    }

    final recoilBase = _recoilBaseDamage(
      dbSymbol: context.move.dbSymbol,
      user: user,
      targetDamage: targetDamage.damage,
    );
    final recoilDamage = _recoilDamage(
      baseDamage: recoilBase,
      factor: _recoilFactor(context.move.dbSymbol),
    );
    if (_preventsRecoil(user: user, context: abilityContext)) {
      final secondary = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: targetDamage.rng,
        user: context.user,
        target: targetSlot,
        move: context.move,
        turn: context.turn,
      );
      return BattleMoveBehaviorResolution(
        state: secondary.state,
        rng: secondary.rng,
        events: <PsdkBattleEvent>[
          ...events,
          ...secondary.events,
        ],
      );
    }
    final recoil = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: targetDamage.rng,
      turn: context.turn,
      amount: recoilDamage,
    );
    state = recoil.state;
    if (recoil.event != null) {
      events.add(recoil.event!);
    }

    // PSDK Basic applies recoil immediately after target damage and before
    // status/stat/effect riders. Keeping secondary effects after the self-hit
    // preserves that order for animation consumers and tests.
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: recoil.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    state = secondary.state;
    events.addAll(secondary.events);

    return BattleMoveBehaviorResolution(
      state: state,
      rng: secondary.rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveStudioMindBlown({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final successfulTargets = <PsdkBattleSlotRef>[];

    for (final targetSlot in prepared.psdkTargets) {
      final damageResult = const BattleMoveDamageCalculator().calculate(
        BattleMoveDamageContext(
          user: state.battlerAt(context.user),
          target: state.battlerAt(targetSlot),
          move: context.move,
          rng: rng,
          field: state.field,
          state: state,
          userSlot: context.user,
          targetSlot: targetSlot,
        ),
      );
      rng = damageResult.rng;
      if (damageResult.damage <= 0) {
        continue;
      }

      final targetDamage = applyDirectDamage(
        state: state,
        user: context.user,
        target: targetSlot,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: damageResult.damage,
      );
      state = targetDamage.state;
      rng = targetDamage.rng;
      if (targetDamage.event != null) {
        events.add(targetDamage.event!);
      }
      if (targetDamage.damage > 0) {
        successfulTargets.add(targetSlot);
      }
    }

    for (final targetSlot in successfulTargets) {
      final secondary = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: rng,
        user: context.user,
        target: targetSlot,
        move: context.move,
        turn: context.turn,
      );
      state = secondary.state;
      rng = secondary.rng;
      events.addAll(secondary.events);
    }

    return _crashMindBlownUser(
      context: context,
      state: state,
      rng: rng,
      events: events,
    );
  }

  bool _isStudioMindBlown(String dbSymbol) => dbSymbol == 'mind_blown';

  bool _shouldMindBlownCrashAfterFailure(BattleMoveFailureReason? reason) {
    return switch (reason) {
      BattleMoveFailureReason.accuracy ||
      BattleMoveFailureReason.immunity ||
      BattleMoveFailureReason.protected =>
        true,
      _ => false,
    };
  }

  BattleMoveBehaviorResolution _crashMindBlownUser({
    required BattleMoveBehaviorContext context,
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required List<PsdkBattleEvent> events,
    bool successful = true,
  }) {
    final user = state.battlerAt(context.user);
    if (user.abilityId == 'wonder_guard') {
      return BattleMoveBehaviorResolution(
        state: state,
        rng: rng,
        events: events,
        successful: successful,
      );
    }

    final crash = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: user.maxHp ~/ 2,
    );
    return BattleMoveBehaviorResolution(
      state: crash.state,
      rng: crash.rng,
      events: <PsdkBattleEvent>[
        ...events,
        if (crash.event != null) crash.event!,
      ],
      successful: successful,
    );
  }

  int _recoilFactor(String dbSymbol) {
    return _psdkRecoilFactors[dbSymbol] ?? 4;
  }

  int _recoilBaseDamage({
    required String dbSymbol,
    required PsdkBattleCombatant user,
    required int targetDamage,
  }) {
    if (_recoilFromUserMaxHp.contains(dbSymbol)) {
      return user.maxHp;
    }
    if (_recoilFromUserCurrentHp.contains(dbSymbol)) {
      return user.currentHp;
    }
    // PSDK `damages` clamps normal move damage to the target's current HP
    // before `recoil(hp, user)` receives it. `applyDirectDamage.damage` is the
    // same clamped amount in this Dart lane.
    return targetDamage;
  }

  int _recoilDamage({
    required int baseDamage,
    required int factor,
  }) {
    final damage = baseDamage ~/ factor;
    return damage < 1 ? 1 : damage;
  }

  int _resolvePowerWithAbility({
    required PsdkBattleCombatant user,
    required BattleAbilityMoveContext context,
    required int movePower,
  }) {
    var multiplier = 1.0;
    for (final effect in user.abilityEffects) {
      multiplier *= effect.basePowerMultiplier(context);
    }
    final resolvedPower = (movePower * multiplier).floor();
    return resolvedPower < 1 ? 1 : resolvedPower;
  }

  bool _preventsRecoil({
    required PsdkBattleCombatant user,
    required BattleAbilityMoveContext context,
  }) {
    return user.abilityEffects.any((effect) => effect.preventsRecoil(context));
  }
}
