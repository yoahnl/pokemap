import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _VariablePowerKind {
  brine,
  eruption,
  flail,
  wringOut,
  hardPress,
  electroBall,
  gyroBall,
  facade,
  targetStatusPowerBoost,
  hex,
  venoshock,
}

/// Ports PSDK move classes whose main override is dynamic base power.
///
/// The class mirrors Ruby `real_base_power`/`damages` overrides while leaving
/// target selection, PP, accuracy, Protect, immunity and secondary riders in
/// the shared move procedure. Families needing items, abilities, weights,
/// weather, terrain, damage history or custom stat sources stay out of this
/// lot so the registry does not overstate support.
final class VariablePowerMoveBehavior implements BattleMoveBehavior {
  const VariablePowerMoveBehavior.brine()
      : battleEngineMethod = 's_brine',
        _kind = _VariablePowerKind.brine;

  const VariablePowerMoveBehavior.eruption()
      : battleEngineMethod = 's_eruption',
        _kind = _VariablePowerKind.eruption;

  const VariablePowerMoveBehavior.flail()
      : battleEngineMethod = 's_flail',
        _kind = _VariablePowerKind.flail;

  const VariablePowerMoveBehavior.wringOut()
      : battleEngineMethod = 's_wring_out',
        _kind = _VariablePowerKind.wringOut;

  const VariablePowerMoveBehavior.hardPress()
      : battleEngineMethod = 's_hard_press',
        _kind = _VariablePowerKind.hardPress;

  const VariablePowerMoveBehavior.electroBall()
      : battleEngineMethod = 's_electro_ball',
        _kind = _VariablePowerKind.electroBall;

  const VariablePowerMoveBehavior.gyroBall()
      : battleEngineMethod = 's_gyro_ball',
        _kind = _VariablePowerKind.gyroBall;

  const VariablePowerMoveBehavior.facade()
      : battleEngineMethod = 's_facade',
        _kind = _VariablePowerKind.facade;

  const VariablePowerMoveBehavior.infernalParade()
      : battleEngineMethod = 's_infernal_parade',
        _kind = _VariablePowerKind.targetStatusPowerBoost;

  const VariablePowerMoveBehavior.bitterMalice()
      : battleEngineMethod = 's_bitter_malice',
        _kind = _VariablePowerKind.targetStatusPowerBoost;

  const VariablePowerMoveBehavior.hex()
      : battleEngineMethod = 's_hex',
        _kind = _VariablePowerKind.hex;

  const VariablePowerMoveBehavior.venoshock()
      : battleEngineMethod = 's_venoshock',
        _kind = _VariablePowerKind.venoshock;

  @override
  final String battleEngineMethod;
  final _VariablePowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = _resolvePower(
      movePower: context.move.power,
      user: user,
      target: target,
    );
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    final finalDamage = _resolveFinalDamage(
      damage: damageResult.damage,
      target: target,
    );
    if (finalDamage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: finalDamage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  int _resolvePower({
    required int movePower,
    required PsdkBattleCombatant user,
    required PsdkBattleCombatant target,
  }) {
    return switch (_kind) {
      _VariablePowerKind.brine => _brinePower(movePower, target),
      _VariablePowerKind.eruption => _hpRatePower(movePower, user),
      _VariablePowerKind.flail => _flailPower(user),
      _VariablePowerKind.wringOut => _hpRatePower(120, target),
      _VariablePowerKind.hardPress => _hpRatePower(100, target),
      _VariablePowerKind.electroBall => _electroBallPower(user, target),
      _VariablePowerKind.gyroBall => _gyroBallPower(user, target),
      _VariablePowerKind.facade => _facadePower(movePower, user),
      _VariablePowerKind.targetStatusPowerBoost =>
        target.majorStatus == null ? movePower : movePower * 2,
      // Hex and Venoshock double final damage in PSDK, not base power.
      _VariablePowerKind.hex || _VariablePowerKind.venoshock => movePower,
    };
  }

  int _resolveFinalDamage({
    required int damage,
    required PsdkBattleCombatant target,
  }) {
    return switch (_kind) {
      _VariablePowerKind.hex =>
        target.majorStatus == null ? damage : damage * 2,
      _VariablePowerKind.venoshock =>
        _isPoisonStatus(target.majorStatus) ? damage * 2 : damage,
      _ => damage,
    };
  }

  int _brinePower(int movePower, PsdkBattleCombatant target) {
    return target.currentHp <= target.maxHp ~/ 2 ? movePower * 2 : movePower;
  }

  int _hpRatePower(int maxPower, PsdkBattleCombatant battler) {
    final power = (maxPower * _hpRate(battler)).floor();
    return power < 1 ? 1 : power;
  }

  int _flailPower(PsdkBattleCombatant user) {
    final rate = _hpRate(user);
    if (rate > 0.70) {
      return 20;
    }
    if (rate > 0.35) {
      return 40;
    }
    if (rate > 0.20) {
      return 80;
    }
    if (rate > 0.10) {
      return 100;
    }
    if (rate > 0.04) {
      return 150;
    }
    return 200;
  }

  int _electroBallPower(
    PsdkBattleCombatant user,
    PsdkBattleCombatant target,
  ) {
    final ratio = _positiveSpeed(target) / _positiveSpeed(user);
    if (ratio < 0.25) {
      return 150;
    }
    if (ratio < 0.33) {
      return 120;
    }
    if (ratio < 0.5) {
      return 80;
    }
    if (ratio < 1) {
      return 60;
    }
    return 40;
  }

  int _gyroBallPower(
    PsdkBattleCombatant user,
    PsdkBattleCombatant target,
  ) {
    final rawPower =
        (25 * _positiveSpeed(target) / _positiveSpeed(user)).floor();
    return rawPower.clamp(1, 150).toInt();
  }

  int _facadePower(int movePower, PsdkBattleCombatant user) {
    return _isFacadeBoostingStatus(user.majorStatus)
        ? movePower * 2
        : movePower;
  }

  double _hpRate(PsdkBattleCombatant battler) {
    if (battler.maxHp <= 0) {
      return 0;
    }
    return battler.currentHp.clamp(0, battler.maxHp) / battler.maxHp;
  }

  int _positiveSpeed(PsdkBattleCombatant battler) {
    final speed = battler.stats.speed;
    if (battler.majorStatus != PsdkBattleMajorStatus.paralysis ||
        battler.abilityId == 'quick_feet') {
      return speed < 1 ? 1 : speed;
    }
    final paralyzedSpeed = (speed * 0.25).floor();
    return paralyzedSpeed < 1 ? 1 : paralyzedSpeed;
  }

  bool _isFacadeBoostingStatus(PsdkBattleMajorStatus? status) {
    return switch (status) {
      PsdkBattleMajorStatus.burn ||
      PsdkBattleMajorStatus.paralysis ||
      PsdkBattleMajorStatus.poison ||
      PsdkBattleMajorStatus.toxic =>
        true,
      _ => false,
    };
  }

  bool _isPoisonStatus(PsdkBattleMajorStatus? status) {
    return switch (status) {
      PsdkBattleMajorStatus.poison || PsdkBattleMajorStatus.toxic => true,
      _ => false,
    };
  }
}
