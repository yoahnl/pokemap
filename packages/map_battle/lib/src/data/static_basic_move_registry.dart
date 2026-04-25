import '../domain/move/behaviors/battle_move_behavior_support.dart';
import '../domain/move/behaviors/basic_damage_specialization_move_behavior.dart';
import '../domain/move/behaviors/custom_stat_source_move_behavior.dart';
import '../domain/move/behaviors/direct_hp_move_behavior.dart';
import '../domain/move/behaviors/fixed_damage_move_behavior.dart';
import '../domain/move/behaviors/mind_blown_move_behavior.dart';
import '../domain/move/behaviors/multi_hit_move_behavior.dart';
import '../domain/move/behaviors/no_effect_move_behavior.dart';
import '../domain/move/behaviors/recoil_move_behavior.dart';
import '../domain/move/behaviors/self_destruct_move_behavior.dart';
import '../domain/move/behaviors/terrain_power_move_behavior.dart';
import '../domain/move/behaviors/variable_power_move_behavior.dart';
import '../domain/move/behaviors/weight_power_move_behavior.dart';
import '../domain/move/battle_move_behavior.dart';
import '../domain/move/battle_move_damage_calculator.dart';
import '../domain/move/battle_move_prevention.dart';
import '../domain/move/battle_move_registry.dart';
import '../domain/move/battle_move_secondary_effect_resolver.dart';
import '../psdk/domain/psdk_battle_combatant.dart';
import '../psdk/domain/psdk_battle_timeline.dart';

BattleMoveRegistry createStaticBasicMoveRegistry() {
  return BattleMoveRegistry(<BattleMoveBehavior>[
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_basic',
      resolve: _resolveBasic,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_status',
      resolve: _resolveStatus,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_protect',
      resolve: _resolveProtect,
    ),
    const FixedDamageMoveBehavior.psdkFixedDamage(),
    const FixedDamageMoveBehavior.userLevel(),
    const FixedDamageMoveBehavior.psywave(),
    const FixedDamageMoveBehavior.halfCurrentTargetHp(),
    const MultiHitMoveBehavior.fixed(
      battleEngineMethod: 's_2hits',
      hitCount: 2,
    ),
    const MultiHitMoveBehavior.fixed(
      battleEngineMethod: 's_3hits',
      hitCount: 3,
    ),
    const MultiHitMoveBehavior.psdkRandom(),
    const MultiHitMoveBehavior.tripleKick(),
    const MultiHitMoveBehavior.populationBomb(),
    const MultiHitMoveBehavior.waterShuriken(),
    const BasicDamageSpecializationMoveBehavior.falseSwipe(),
    const BasicDamageSpecializationMoveBehavior.fullCrit(),
    const NoEffectMoveBehavior.doNothing(),
    const NoEffectMoveBehavior.splash(),
    const DirectHpMoveBehavior.endeavor(),
    const DirectHpMoveBehavior.finalGambit(),
    const MindBlownMoveBehavior.mindBlown(),
    const MindBlownMoveBehavior.steelBeam(),
    const MindBlownMoveBehavior.chloroblast(),
    const SelfDestructMoveBehavior.explosion(),
    const SelfDestructMoveBehavior.mistyExplosion(),
    const TerrainPowerMoveBehavior.terrainBoosting(),
    const RecoilMoveBehavior.psdkRecoil(),
    const VariablePowerMoveBehavior.brine(),
    const VariablePowerMoveBehavior.eruption(),
    const VariablePowerMoveBehavior.flail(),
    const VariablePowerMoveBehavior.wringOut(),
    const VariablePowerMoveBehavior.hardPress(),
    const VariablePowerMoveBehavior.electroBall(),
    const VariablePowerMoveBehavior.gyroBall(),
    const VariablePowerMoveBehavior.facade(),
    const VariablePowerMoveBehavior.infernalParade(),
    const VariablePowerMoveBehavior.bitterMalice(),
    const VariablePowerMoveBehavior.hex(),
    const VariablePowerMoveBehavior.venoshock(),
    const WeightPowerMoveBehavior.lowKick(),
    const WeightPowerMoveBehavior.heavySlam(),
    const CustomStatSourceMoveBehavior.bodyPress(),
    const CustomStatSourceMoveBehavior.foulPlay(),
    const CustomStatSourceMoveBehavior.psyshock(),
    const CustomStatSourceMoveBehavior.customStatsBased(),
  ]);
}

BattleMoveBehaviorResolution _resolveBasic(BattleMoveBehaviorContext context) {
  final common = prepareBattleMove(context);
  if (!common.shouldExecuteBehavior) {
    return common.toResolution();
  }

  final targetSlot = common.psdkTargets.single;
  final user = common.state.battlerAt(context.user);
  final target = common.state.battlerAt(targetSlot);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: common.rng,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: common.state,
      rng: damageResult.rng,
      events: common.events,
    );
  }

  final applied = applyDirectDamage(
    state: common.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    amount: damageResult.damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: damageResult.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...common.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveStatus(BattleMoveBehaviorContext context) {
  final common = prepareBattleMove(context);
  if (!common.shouldExecuteBehavior) {
    return common.toResolution();
  }
  if (context.move.statuses.isEmpty) {
    return common.toResolution(successful: true);
  }

  var rng = common.rng;
  final status = context.move.statuses.first;
  if (status.chance < 100) {
    final roll = rng.generic.nextPercent();
    rng = rng.copyWith(generic: roll.next);
    if (roll.value > status.chance) {
      return BattleMoveBehaviorResolution(
        state: common.state,
        rng: rng,
        events: common.events,
      );
    }
  }

  final targetSlot = common.psdkTargets.single;
  final target = common.state.battlerAt(targetSlot);
  if (target.majorStatus != null) {
    // Major statuses are exclusive. Until the richer PSDK condition stack is
    // ported, refusing to overwrite keeps this first slice honest and stable.
    return BattleMoveBehaviorResolution(
      state: common.state,
      rng: rng,
      events: common.events,
    );
  }

  final nextTarget = target.copyWith(majorStatus: status.status);
  return BattleMoveBehaviorResolution(
    state: common.state.replaceBattler(targetSlot, nextTarget),
    rng: rng,
    events: <PsdkBattleEvent>[
      ...common.events,
      PsdkBattleStatusEvent(
        user: context.user,
        target: targetSlot,
        moveId: context.move.id,
        status: status.status,
      ),
    ],
  );
}

BattleMoveBehaviorResolution _resolveProtect(
    BattleMoveBehaviorContext context) {
  if (context.isLastActionOfTurn) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: BattleMoveFailureReason.unusableByUser.jsonName,
        ),
      ],
      successful: false,
    );
  }

  final common = prepareBattleMove(context);
  if (!common.shouldExecuteBehavior) {
    return common.toResolution();
  }

  final protectedSlot = common.psdkTargets.single;
  final protectedBattler = common.state.battlerAt(protectedSlot);

  // PSDK stores Protect as a pokemon-tied effect. This first Dart slice keeps
  // only the effect id and the same one-turn lifetime; success-rate decay and
  // variants such as Endure/Spiky Shield intentionally remain outside Lot 14.
  final nextState = common.state.replaceBattler(
    protectedSlot,
    protectedBattler.copyWith(
      effects: protectedBattler.effects.add(PsdkBattleEffectIds.protect),
    ),
  );

  return BattleMoveBehaviorResolution(
    state: nextState,
    rng: common.rng,
    events: common.events,
  );
}
