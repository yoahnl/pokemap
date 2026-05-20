import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_handler_result.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _HitThenCureStatusKind {
  smellingSalt,
  wakeUpSlap,
  sparklingAria,
}

/// Ports PSDK Basic descendants that damage a target and cure a matching major
/// status afterwards.
///
/// The local effect is intentionally narrow: power override, normal Basic
/// damage, then status cure. Ability/item/effect hooks that can alter damage
/// or cure processing still keep these entries partial in the manifest.
final class HitThenCureStatusMoveBehavior implements BattleMoveBehavior {
  const HitThenCureStatusMoveBehavior.smellingSalt()
      : battleEngineMethod = 's_smelling_salt',
        _kind = _HitThenCureStatusKind.smellingSalt;

  const HitThenCureStatusMoveBehavior.wakeUpSlap()
      : battleEngineMethod = 's_wakeup_slap',
        _kind = _HitThenCureStatusKind.wakeUpSlap;

  const HitThenCureStatusMoveBehavior.sparklingAria()
      : battleEngineMethod = 's_sparkling_aria',
        _kind = _HitThenCureStatusKind.sparklingAria;

  @override
  final String battleEngineMethod;
  final _HitThenCureStatusKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (final targetSlot in prepared.psdkTargets) {
      final user = state.battlerAt(context.user);
      final target = state.battlerAt(targetSlot);
      final move = _damageMove(context.move, target);
      final damageResult = const BattleMoveDamageCalculator().calculate(
        BattleMoveDamageContext(
          user: user,
          target: target,
          move: move,
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

      final damage = applyDirectDamage(
        state: state,
        user: context.user,
        target: targetSlot,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: damageResult.damage,
      );
      state = damage.state;
      rng = damage.rng;
      if (damage.event != null) {
        events.add(damage.event!);
      }

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

      final cure = _cureStatus(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        targetSlot: targetSlot,
        moveId: context.move.id,
      );
      state = cure.state;
      rng = cure.rng;
      if (cure.applied) {
        events.addAll(cure.events);
      }
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveDefinition _damageMove(
    BattleMoveDefinition move,
    PsdkBattleCombatant target,
  ) {
    if (!_boostsPower(target)) {
      return move;
    }
    return _moveWithPower(move, power: move.power * 2);
  }

  bool _boostsPower(PsdkBattleCombatant target) {
    return switch (_kind) {
      _HitThenCureStatusKind.smellingSalt =>
        target.majorStatus == PsdkBattleMajorStatus.paralysis,
      _HitThenCureStatusKind.wakeUpSlap =>
        target.majorStatus == PsdkBattleMajorStatus.sleep ||
            target.abilityId == 'comatose',
      _HitThenCureStatusKind.sparklingAria => false,
    };
  }

  BattleHandlerResult _cureStatus({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef targetSlot,
    required String moveId,
  }) {
    final target = state.battlerAt(targetSlot);
    final shouldCure = switch (_kind) {
      _HitThenCureStatusKind.smellingSalt =>
        target.majorStatus == PsdkBattleMajorStatus.paralysis,
      _HitThenCureStatusKind.wakeUpSlap =>
        target.majorStatus == PsdkBattleMajorStatus.sleep,
      _HitThenCureStatusKind.sparklingAria =>
        target.majorStatus == PsdkBattleMajorStatus.burn,
    };
    if (!shouldCure) {
      return BattleHandlerResult(
        state: state,
        rng: rng,
        applied: false,
        reason: 'status_not_matched',
      );
    }

    return const BattleStatusChangeHandler().cureMajorStatus(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: turn,
        user: user,
      ),
      target: targetSlot,
      moveId: moveId,
    );
  }
}

BattleMoveDefinition _moveWithPower(
  BattleMoveDefinition move, {
  required int power,
}) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: move.type,
    category: move.category,
    power: power,
    accuracy: move.accuracy,
    pp: move.pp,
    currentPp: move.currentPp,
    priority: move.priority,
    criticalRate: move.criticalRate,
    effectChance: move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    flags: move.flags,
    stageMods: move.stageMods,
    statuses: move.statuses,
  );
}
