import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../move/battle_move_prevention.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class HpThresholdFormAbilityEffect extends BattleAbilityEffect {
  const HpThresholdFormAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.family,
  }) : super(abilityId: abilityId, scope: scope);

  final HpThresholdFormFamily family;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return HpThresholdFormAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      family: family,
    );
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }
    return _calibrate(context.state, context.rng, context.replacement);
  }

  @override
  BattleEffectSwitchOutResult? onSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    final battler = context.state.battlerAt(context.owner);
    if (battler.form == 0) {
      return null;
    }
    return BattleEffectSwitchOutResult(
      state: context.state.updateBattler(
        context.owner,
        (current) => current.copyWith(form: 0),
      ),
      rng: context.rng,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final battler = context.state.battlerAt(context.owner);
    if (battler.isFainted) {
      return null;
    }
    final result = _calibrate(context.state, context.rng, context.owner);
    if (result == null) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  @override
  String? onStatusPrevention(BattleEffectStatusPreventionContext context) {
    if (family != HpThresholdFormFamily.shieldsDown ||
        !isOwnedBy(context.target) ||
        context.state.battlerAt(context.target).form != 0 ||
        context.user == context.target) {
      return null;
    }
    return 'ability:$abilityId';
  }

  BattleEffectSwitchEventResult? _calibrate(
    PsdkBattleState state,
    BattleRngStreams rng,
    PsdkBattleSlotRef owner,
  ) {
    final battler = state.battlerAt(owner);
    final nextForm = switch (family) {
      HpThresholdFormFamily.zenMode =>
        battler.currentHp * 2 <= battler.maxHp ? 1 : 0,
      HpThresholdFormFamily.schooling =>
        battler.level >= 20 && battler.currentHp * 4 > battler.maxHp ? 1 : 0,
      HpThresholdFormFamily.shieldsDown =>
        battler.currentHp * 2 <= battler.maxHp ? 1 : 0,
    };
    if (battler.form == nextForm) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: state.updateBattler(
        owner,
        (current) => current.copyWith(form: nextForm),
      ),
      rng: rng,
    );
  }
}

enum HpThresholdFormFamily {
  zenMode,
  schooling,
  shieldsDown,
}

final class HungerSwitchEffect extends BattleAbilityEffect {
  const HungerSwitchEffect({required BattleEffectScope scope})
      : super(abilityId: 'hunger_switch', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return HungerSwitchEffect(scope: scope);
  }

  @override
  BattleEffectSwitchOutResult? onSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    return _resetForm(context.state, context.rng, context.owner);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final battler = context.state.battlerAt(context.owner);
    if (battler.isFainted) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (current) => current.copyWith(form: current.form == 0 ? 1 : 0),
      ),
      rng: context.rng,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (!isOwnedBy(context.target) || !context.targetFainted) {
      return null;
    }
    final result = _resetForm(context.state, context.rng, context.target);
    if (result == null) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  BattleEffectSwitchOutResult? _resetForm(
    PsdkBattleState state,
    BattleRngStreams rng,
    PsdkBattleSlotRef owner,
  ) {
    if (state.battlerAt(owner).form == 0) {
      return null;
    }
    return BattleEffectSwitchOutResult(
      state: state.updateBattler(
        owner,
        (current) => current.copyWith(form: 0),
      ),
      rng: rng,
    );
  }
}

final class ZeroToHeroEffect extends BattleAbilityEffect {
  const ZeroToHeroEffect({required BattleEffectScope scope})
      : super(abilityId: 'zero_to_hero', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ZeroToHeroEffect(scope: scope);
  }

  @override
  BattleEffectSwitchOutResult? onSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    final battler = context.state.battlerAt(context.owner);
    if (battler.isFainted || battler.form != 0) {
      return null;
    }
    return BattleEffectSwitchOutResult(
      state: context.state.updateBattler(
        context.owner,
        (current) => current.copyWith(form: 1),
      ),
      rng: context.rng,
    );
  }
}

final class TeraShiftEffect extends BattleAbilityEffect {
  const TeraShiftEffect({required BattleEffectScope scope})
      : super(abilityId: 'tera_shift', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TeraShiftEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context) ||
        context.state.battlerAt(context.replacement).form == 1) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: context.state.updateBattler(
        context.replacement,
        (current) => current.copyWith(form: 1),
      ),
      rng: context.rng,
    );
  }
}

final class IceFaceEffect extends BattleAbilityEffect {
  const IceFaceEffect({required BattleEffectScope scope})
      : super(abilityId: 'ice_face', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return IceFaceEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context) || !_isSnowing(context.state.field)) {
      return null;
    }
    return _restoreIceFace(context.state, context.rng, context.replacement);
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    final target = context.state.battlerAt(context.target);
    if (!isOwnedBy(context.target) ||
        context.user == context.target ||
        target.form != 0 ||
        context.move.category != PsdkBattleMoveCategory.physical) {
      return null;
    }
    return BattleEffectDamagePreventionResult(
      state: context.state.updateBattler(
        context.target,
        (current) => current.copyWith(form: 1),
      ),
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.immunity,
      amount: 0,
    );
  }

  @override
  BattleEffectFieldChangeResult? onPostWeatherChange(
    BattleEffectWeatherChangeContext context,
  ) {
    if (context.weather != PsdkBattleWeatherId.hail &&
        context.weather != PsdkBattleWeatherId.snow) {
      return null;
    }
    final result = _restoreIceFace(context.state, context.rng, context.owner);
    if (result == null) {
      return null;
    }
    return BattleEffectFieldChangeResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (!isOwnedBy(context.target) || !context.targetFainted) {
      return null;
    }
    final result = _restoreIceFace(context.state, context.rng, context.target);
    if (result == null) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  BattleEffectSwitchEventResult? _restoreIceFace(
    PsdkBattleState state,
    BattleRngStreams rng,
    PsdkBattleSlotRef target,
  ) {
    if (state.battlerAt(target).form == 0) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: state.updateBattler(
        target,
        (current) => current.copyWith(form: 0),
      ),
      rng: rng,
    );
  }
}

final class DisguiseEffect extends BattleAbilityEffect {
  const DisguiseEffect({required BattleEffectScope scope})
      : super(abilityId: 'disguise', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return DisguiseEffect(scope: scope);
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    final target = context.state.battlerAt(context.target);
    if (!isOwnedBy(context.target) ||
        context.user == context.target ||
        target.form != 0 ||
        target.effects.contains('substitute') ||
        context.move.category == PsdkBattleMoveCategory.status) {
      return null;
    }
    final chip = (target.maxHp ~/ 8).clamp(1, target.currentHp).toInt();
    final nextTarget = target.copyWith(
      currentHp: target.currentHp - chip,
      form: 1,
      type3: null,
      temporaryTypes: const <String>[],
    );
    return BattleEffectDamagePreventionResult(
      state: context.state.replaceBattler(context.target, nextTarget),
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.immunity,
      amount: chip,
      events: <PsdkBattleEvent>[
        PsdkBattleDamageEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          damage: chip,
          remainingHp: nextTarget.currentHp,
        ),
      ],
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (!isOwnedBy(context.target) ||
        !context.targetFainted ||
        context.state.battlerAt(context.target).form == 0) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: context.state.updateBattler(
        context.target,
        (current) => current.copyWith(form: 0),
      ),
      rng: context.rng,
    );
  }
}

final class GulpMissileEffect extends BattleAbilityEffect {
  const GulpMissileEffect({required BattleEffectScope scope})
      : super(abilityId: 'gulp_missile', scope: scope);

  static const Set<String> _triggerMoves = <String>{'surf', 'waterfall'};

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return GulpMissileEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (isOwnedBy(context.user) && context.user != context.target) {
      return _catchPrey(context);
    }
    if (isOwnedBy(context.target) && context.user != context.target) {
      return _spitPrey(context);
    }
    return null;
  }

  BattleEffectPostDamageResult? _catchPrey(
    BattleEffectPostDamageContext context,
  ) {
    final owner = context.state.battlerAt(context.owner);
    if (owner.isFainted ||
        owner.form != 0 ||
        !_triggerMoves.contains(context.move.dbSymbol)) {
      return null;
    }
    final nextForm = owner.currentHp * 2 > owner.maxHp ? 1 : 2;
    return BattleEffectPostDamageResult(
      state: context.state.updateBattler(
        context.owner,
        (current) => current.copyWith(form: nextForm),
      ),
      rng: context.rng,
    );
  }

  BattleEffectPostDamageResult? _spitPrey(
    BattleEffectPostDamageContext context,
  ) {
    final owner = context.state.battlerAt(context.owner);
    final attacker = context.state.battlerAt(context.user);
    if (owner.isFainted ||
        owner.form == 0 ||
        context.move.category == PsdkBattleMoveCategory.status) {
      return null;
    }
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    if (attacker.abilityId != 'magic_guard') {
      final damage = (attacker.maxHp ~/ 4).clamp(1, attacker.currentHp).toInt();
      final nextAttacker = attacker.copyWith(
        currentHp: attacker.currentHp - damage,
      );
      nextState = nextState.replaceBattler(context.user, nextAttacker);
      events.add(
        PsdkBattleDamageEvent(
          user: context.owner,
          target: context.user,
          moveId: 'ability:gulp_missile',
          damage: damage,
          remainingHp: nextAttacker.currentHp,
        ),
      );
    }

    if (owner.form == 1) {
      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.owner,
        ),
        target: context.user,
        stat: 'defense',
        stages: -1,
        sourceAbilityId: abilityId,
      );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
    } else {
      final result = const BattleStatusChangeHandler().applyMajorStatus(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.owner,
        ),
        target: context.user,
        moveId: 'ability:gulp_missile',
        status: PsdkBattleMajorStatus.paralysis,
      );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
    }

    nextState = nextState.updateBattler(
      context.owner,
      (current) => current.copyWith(form: 0),
    );
    return BattleEffectPostDamageResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }
}

final class PowerConstructEffect extends BattleAbilityEffect {
  const PowerConstructEffect({required BattleEffectScope scope})
      : super(abilityId: 'power_construct', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PowerConstructEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final battler = context.state.battlerAt(context.owner);
    if (battler.isFainted ||
        battler.form == 3 ||
        battler.currentHp * 2 >= battler.maxHp) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (current) => current.copyWith(form: 3),
      ),
      rng: context.rng,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (!isOwnedBy(context.target) || !context.targetFainted) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: context.state.updateBattler(
        context.target,
        (current) => current.copyWith(form: 0),
      ),
      rng: context.rng,
    );
  }
}

final class BattleBondEffect extends BattleAbilityEffect {
  const BattleBondEffect({required BattleEffectScope scope})
      : super(abilityId: 'battle_bond', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BattleBondEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (isOwnedBy(context.user) &&
        context.user != context.target &&
        context.targetFainted &&
        context.state.battlerAt(context.user).form == 0) {
      return BattleEffectPostDamageResult(
        state: context.state.updateBattler(
          context.user,
          (current) => current.copyWith(form: 1),
        ),
        rng: context.rng,
      );
    }
    if (isOwnedBy(context.target) &&
        context.targetFainted &&
        context.state.battlerAt(context.target).form != 0) {
      return BattleEffectPostDamageResult(
        state: context.state.updateBattler(
          context.target,
          (current) => current.copyWith(form: 0),
        ),
        rng: context.rng,
      );
    }
    return null;
  }
}

bool _isEnteringOwner(BattleEffectSwitchEventContext context) {
  return context.owner == context.replacement;
}

bool _isSnowing(PsdkBattleFieldState field) {
  return field.isWeatherActive(PsdkBattleWeatherId.hail) ||
      field.isWeatherActive(PsdkBattleWeatherId.snow);
}
