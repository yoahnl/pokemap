import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battle/battle_slot.dart';
import '../../move/battle_move_prevention.dart';
import '../../move/battle_move_type_processor.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class PowderMoveImmunityAbilityEffect extends BattleAbilityEffect {
  const PowderMoveImmunityAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PowderMoveImmunityAbilityEffect(
      abilityId: abilityId,
      scope: scope,
    );
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (!_isOwner(context.target) || !context.move.flags.powder) {
      return null;
    }
    return BattleMoveFailureReason.immunity;
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    if (!isOwnedBy(context.target) || !context.move.flags.powder) {
      return null;
    }
    return BattleEffectDamagePreventionResult(
      state: context.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.immunity,
      applied: false,
    );
  }

  bool _isOwner(BattlePositionRef target) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope ||
        (scope.slot.bank == target.bank &&
            scope.slot.position == target.position);
  }
}

final class BulletproofEffect extends BattleAbilityEffect {
  const BulletproofEffect({required BattleEffectScope scope})
      : super(abilityId: 'bulletproof', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BulletproofEffect(scope: scope);
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (!_isOwner(context.target) || !context.move.flags.ballistics) {
      return null;
    }
    return BattleMoveFailureReason.immunity;
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    if (!isOwnedBy(context.target) || !context.move.flags.ballistics) {
      return null;
    }
    return BattleEffectDamagePreventionResult(
      state: context.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.immunity,
      applied: false,
    );
  }

  bool _isOwner(BattlePositionRef target) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope ||
        (scope.slot.bank == target.bank &&
            scope.slot.position == target.position);
  }
}

final class GoodAsGoldEffect extends BattleAbilityEffect {
  const GoodAsGoldEffect({required BattleEffectScope scope})
      : super(abilityId: 'good_as_gold', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return GoodAsGoldEffect(scope: scope);
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (!_isOwner(context.target) || context.user == context.target) {
      return null;
    }
    if (_goodAsGoldAffectedMoveIds.contains(context.move.id) ||
        _goodAsGoldAffectedMoveIds.contains(context.move.dbSymbol)) {
      return BattleMoveFailureReason.immunity;
    }
    if (context.move.category != PsdkBattleMoveCategory.status ||
        !_isOneTargetMove(context.move.target)) {
      return null;
    }
    return BattleMoveFailureReason.immunity;
  }

  bool _isOwner(BattlePositionRef target) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope ||
        (scope.slot.bank == target.bank &&
            scope.slot.position == target.position);
  }
}

final class SturdyEffect extends BattleAbilityEffect {
  const SturdyEffect({required BattleEffectScope scope})
      : super(abilityId: 'sturdy', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SturdyEffect(scope: scope);
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (!_isOwner(context.target) ||
        context.move.battleEngineMethod != 's_ohko') {
      return null;
    }
    return BattleMoveFailureReason.immunity;
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    if (!isOwnedBy(context.target) || context.user == context.target) {
      return null;
    }
    final target = context.state.battlerAt(context.target);
    if (target.currentHp != target.maxHp || context.damage < target.currentHp) {
      return null;
    }

    final damage = (target.currentHp - 1).clamp(0, target.currentHp).toInt();
    final nextTarget = target
        .recordDamage(
          turn: context.turn,
          source: context.user,
          moveId: context.move.id,
          damage: damage,
          remainingHp: 1,
          moveCategory: context.move.category,
        )
        .copyWith(currentHp: 1);
    return BattleEffectDamagePreventionResult(
      state: context.state.replaceBattler(context.target, nextTarget),
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.immunity,
      amount: damage,
      events: <PsdkBattleEvent>[
        PsdkBattleDamageEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          damage: damage,
          remainingHp: 1,
        ),
      ],
    );
  }

  bool _isOwner(BattlePositionRef target) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope ||
        (scope.slot.bank == target.bank &&
            scope.slot.position == target.position);
  }
}

final class WonderGuardEffect extends BattleAbilityEffect {
  const WonderGuardEffect({
    required BattleEffectScope scope,
    BattleMoveTypeProcessor typeProcessor = const BattleMoveTypeProcessor(),
  })  : _typeProcessor = typeProcessor,
        super(abilityId: 'wonder_guard', scope: scope);

  final BattleMoveTypeProcessor _typeProcessor;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return WonderGuardEffect(scope: scope, typeProcessor: _typeProcessor);
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    if (!isOwnedBy(context.target) ||
        context.user == context.target ||
        context.move.category == PsdkBattleMoveCategory.status ||
        context.move.dbSymbol == 'struggle') {
      return null;
    }
    final target = context.state.battlerAt(context.target);
    final effectiveness = _typeProcessor.resolveEffectiveness(
      moveType: context.move.type.toLowerCase(),
      targetTypes: target.types,
      extraTargetTypes: _extraTypes(target),
    );
    if (effectiveness.multiplier > 1) {
      return null;
    }
    return BattleEffectDamagePreventionResult(
      state: context.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.immunity,
      applied: true,
    );
  }
}

const _goodAsGoldAffectedMoveIds = <String>{
  'memento',
  'curse',
  'strength_sap',
};

bool _isOneTargetMove(PsdkBattleMoveTarget target) {
  return switch (target) {
    PsdkBattleMoveTarget.adjacentAlly ||
    PsdkBattleMoveTarget.adjacentAllyOrSelf ||
    PsdkBattleMoveTarget.adjacentFoe ||
    PsdkBattleMoveTarget.anyFoe ||
    PsdkBattleMoveTarget.randomFoe =>
      true,
    _ => false,
  };
}

Iterable<String> _extraTypes(PsdkBattleCombatant battler) {
  return <String>[
    if (battler.type3 != null) battler.type3!,
    ...battler.temporaryTypes,
  ];
}
