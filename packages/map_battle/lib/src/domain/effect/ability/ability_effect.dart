import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../move/battle_move_data.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';

abstract class BattleAbilityEffect extends BattleEffect {
  const BattleAbilityEffect({
    required this.abilityId,
    required super.scope,
  }) : super(id: 'ability:$abilityId');

  final String abilityId;

  PsdkBattleSlotRef? get owner {
    final scope = this.scope;
    return scope is BattlerBattleEffectScope ? scope.slot : null;
  }

  bool isOwnedBy(PsdkBattleSlotRef slot) {
    final currentOwner = owner;
    return currentOwner == slot;
  }

  BattleMoveFailureReason? onMovePreventionUser(
    BattleAbilityMoveContext context,
  ) {
    return null;
  }

  bool bypassesAccuracy(BattleAbilityMoveContext context) => false;

  double chanceOfHitMultiplier(BattleAbilityMoveContext context) => 1;

  int? forcedHitCount(BattleAbilityMoveContext context) => null;

  bool bypassesMultiHitAccuracyRecheck(BattleAbilityMoveContext context) {
    return false;
  }

  String? moveTypeOverride(BattleAbilityMoveTypeContext context) => null;

  double basePowerMultiplier(BattleAbilityMoveContext context) => 1;

  double damageBasePowerMultiplier(BattleAbilityDamageContext context) => 1;

  double offensiveStatMultiplier(BattleAbilityDamageContext context) => 1;

  double incomingDamageBasePowerMultiplier(
    BattleAbilityDamageContext context,
  ) {
    return 1;
  }

  double finalDamageMultiplier(BattleAbilityDamageContext context) => 1;

  double statMultiplier(BattleAbilityStatContext context) => 1;

  bool preventsRecoil(BattleAbilityMoveContext context) => false;

  bool? groundedOverride(PsdkBattleCombatant battler) => null;

  bool preventsStatus(BattleAbilityStatusContext context) => false;

  bool get suppressesWeatherEffects => false;
}

final class BattleAbilityMoveContext {
  const BattleAbilityMoveContext({
    required this.state,
    required this.user,
    required this.target,
    required this.move,
  });

  final PsdkBattleState state;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final BattleMoveDefinition move;
}

final class BattleAbilityStatusContext {
  const BattleAbilityStatusContext({
    required this.status,
    required this.target,
    this.launcher,
    this.move,
    this.field = const PsdkBattleFieldState(),
  });

  final PsdkBattleMajorStatus status;
  final PsdkBattleCombatant target;
  final PsdkBattleCombatant? launcher;
  final BattleMoveDefinition? move;
  final PsdkBattleFieldState field;
}

final class BattleAbilityMoveTypeContext {
  const BattleAbilityMoveTypeContext({
    required this.user,
    required this.target,
    required this.move,
    required this.currentType,
  });

  final PsdkBattleCombatant user;
  final PsdkBattleCombatant target;
  final BattleMoveDefinition move;
  final String currentType;
}

final class BattleAbilityDamageContext {
  const BattleAbilityDamageContext({
    required this.field,
    required this.user,
    required this.target,
    required this.move,
    required this.moveType,
    required this.typeEffectivenessMultiplier,
    this.userSlot,
    this.targetSlot,
    this.activeAbilityIds = const <String>{},
    this.weatherEffectsSuppressed = false,
    this.isLastActionOfTurn = false,
  });

  final PsdkBattleFieldState field;
  final PsdkBattleCombatant user;
  final PsdkBattleCombatant target;
  final BattleMoveDefinition move;
  final String moveType;
  final double typeEffectivenessMultiplier;
  final PsdkBattleSlotRef? userSlot;
  final PsdkBattleSlotRef? targetSlot;
  final Set<String> activeAbilityIds;
  final bool weatherEffectsSuppressed;
  final bool isLastActionOfTurn;
}

final class BattleAbilityStatContext {
  const BattleAbilityStatContext({
    required this.field,
    required this.battler,
    required this.stat,
    this.weatherEffectsSuppressed = false,
  });

  final PsdkBattleFieldState field;
  final PsdkBattleCombatant battler;
  final String stat;
  final bool weatherEffectsSuppressed;
}

extension BattleAbilityEffectList on PsdkBattleCombatant {
  Iterable<BattleAbilityEffect> get abilityEffects sync* {
    if (effects.contains('ability_suppressed')) {
      return;
    }
    for (final effect in effects.effects) {
      if (effect is BattleAbilityEffect) {
        yield effect;
      }
    }
  }
}

extension BattleAbilityEffectStateList on PsdkBattleState {
  Iterable<BattleAbilityEffect> activeAbilityEffects() sync* {
    for (final slot in aliveSlots()) {
      yield* battlerAt(slot).abilityEffects;
    }
  }
}
