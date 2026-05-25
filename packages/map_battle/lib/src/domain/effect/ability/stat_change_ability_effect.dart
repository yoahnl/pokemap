import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

enum AbilityStatChangeTransform {
  contrary,
  simple,
  guardDog,
}

final class StatChangeTransformAbilityEffect extends BattleAbilityEffect {
  const StatChangeTransformAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.transform,
  }) : super(abilityId: abilityId, scope: scope);

  final AbilityStatChangeTransform transform;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StatChangeTransformAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      transform: transform,
    );
  }

  @override
  int? onStatChange(BattleEffectStatChangeContext context) {
    if (!isOwnedBy(context.target)) {
      return null;
    }
    return switch (transform) {
      AbilityStatChangeTransform.contrary => -context.stages,
      AbilityStatChangeTransform.simple => context.stages * 2,
      AbilityStatChangeTransform.guardDog =>
        context.sourceAbilityId == 'intimidate' ? 1 : null,
    };
  }
}

final class MirrorArmorEffect extends BattleAbilityEffect {
  const MirrorArmorEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'mirror_armor', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return MirrorArmorEffect(scope: scope);
  }

  @override
  BattleEffectStatChangeRedirectResult? onStatChangeRedirect(
    BattleEffectStatChangeContext context,
  ) {
    final reflectedTargets = context.originalTargets.isEmpty
        ? <PsdkBattleSlotRef>[context.user]
        : context.originalTargets;
    if (!isOwnedBy(context.target) ||
        (context.user == context.target && context.originalTargets.isEmpty) ||
        context.stages >= 0 ||
        context.sourceAbilityId == abilityId) {
      return null;
    }

    // PSDK Mirror Armor returns 0 for the original drop and runs a fresh stat
    // change against the launcher, or against the original batch of targets
    // when an effect such as Magic Coat has remapped the move.
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var applied = false;

    for (final reflectedTarget in reflectedTargets) {
      if (!nextState.combatants.containsKey(reflectedTarget) ||
          nextState.battlerAt(reflectedTarget).isFainted) {
        continue;
      }
      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.user,
        ),
        target: reflectedTarget,
        stat: context.stat,
        stages: context.stages,
        move: context.move,
        sourceAbilityId: abilityId,
      );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      applied = applied || result.applied || result.events.isNotEmpty;
    }

    return BattleEffectStatChangeRedirectResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: applied || reflectedTargets.isNotEmpty,
    );
  }
}

final class StatDropPunishAbilityEffect extends BattleAbilityEffect {
  const StatDropPunishAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.boostedStat,
  }) : super(abilityId: abilityId, scope: scope);

  final String boostedStat;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StatDropPunishAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      boostedStat: boostedStat,
    );
  }

  @override
  BattleEffectStatChangePostResult? onStatChangePost(
    BattleEffectStatChangeContext context,
  ) {
    if (!isOwnedBy(context.target) ||
        context.user == context.target ||
        context.user.bank == context.target.bank ||
        context.stages >= 0) {
      return null;
    }

    final result = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      stat: boostedStat,
      stages: 2,
      move: context.move,
      sourceAbilityId: abilityId,
    );
    if (!result.applied && result.events.isEmpty) {
      return null;
    }
    return BattleEffectStatChangePostResult(
      state: result.state,
      rng: result.rng,
      events: <PsdkBattleEvent>[
        ...result.events,
      ],
    );
  }
}
