import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../battler/battle_grounding_resolver.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

enum SwitchPreventingAbilityKind {
  shadowTag,
  arenaTrap,
  magnetPull,
}

final class ShadowTagEffect extends BattleAbilityEffect {
  const ShadowTagEffect({
    required BattleEffectScope scope,
    SwitchPreventingAbilityKind kind = SwitchPreventingAbilityKind.shadowTag,
  })  : _kind = kind,
        super(abilityId: 'shadow_tag', scope: scope);

  const ShadowTagEffect.arenaTrap({
    required BattleEffectScope scope,
  })  : _kind = SwitchPreventingAbilityKind.arenaTrap,
        super(abilityId: 'arena_trap', scope: scope);

  const ShadowTagEffect.magnetPull({
    required BattleEffectScope scope,
  })  : _kind = SwitchPreventingAbilityKind.magnetPull,
        super(abilityId: 'magnet_pull', scope: scope);

  final SwitchPreventingAbilityKind _kind;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return switch (_kind) {
      SwitchPreventingAbilityKind.shadowTag => ShadowTagEffect(scope: scope),
      SwitchPreventingAbilityKind.arenaTrap =>
        ShadowTagEffect.arenaTrap(scope: scope),
      SwitchPreventingAbilityKind.magnetPull =>
        ShadowTagEffect.magnetPull(scope: scope),
    };
  }

  @override
  String? onSwitchPrevention(BattleEffectSwitchPreventionContext context) {
    final trapper = owner;
    if (trapper == null || trapper.bank == context.target.bank) {
      return null;
    }
    final trapperBattler = context.state.combatants[trapper];
    if (trapperBattler == null || trapperBattler.isFainted) {
      return null;
    }

    final target = context.state.battlerAt(context.target);
    if (_effectPrevented(target)) {
      return null;
    }
    return id;
  }

  bool _effectPrevented(PsdkBattleCombatant target) {
    return switch (_kind) {
      SwitchPreventingAbilityKind.shadowTag =>
        target.hasType('ghost') || target.abilityId == 'shadow_tag',
      SwitchPreventingAbilityKind.arenaTrap => target.hasType('ghost') ||
          !const BattleGroundingResolver().isGrounded(target),
      SwitchPreventingAbilityKind.magnetPull =>
        target.hasType('ghost') || !target.hasType('steel'),
    };
  }
}

final class SuctionCupsEffect extends BattleAbilityEffect {
  const SuctionCupsEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'suction_cups', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SuctionCupsEffect(scope: scope);
  }

  @override
  String? onSwitchPrevention(BattleEffectSwitchPreventionContext context) {
    final owner = this.owner;
    if (owner == null || owner != context.target) {
      return null;
    }
    final move = context.move;
    if (move == null ||
        !_forceSwitchMethods.contains(move.battleEngineMethod)) {
      return null;
    }
    final battler = context.state.battlerAt(owner);
    if (battler.isFainted || battler.abilityId != abilityId) {
      return null;
    }
    return id;
  }
}

const _forceSwitchMethods = <String>{
  's_dragon_tail',
  's_roar',
};
