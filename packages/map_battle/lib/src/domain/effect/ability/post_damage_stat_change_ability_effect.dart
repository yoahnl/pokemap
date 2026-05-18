import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

enum AbilityPostDamageStatCondition {
  anyIncoming,
  physicalIncoming,
  waterIncoming,
  fireOrWaterIncoming,
  darkIncoming,
  bugDarkOrGhostIncoming,
  contactIncoming,
}

final class PostDamageStatChangeAbilityEffect extends BattleAbilityEffect {
  const PostDamageStatChangeAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.condition,
    required this.changes,
    this.changeTarget = AbilityPostDamageStatChangeTarget.owner,
  }) : super(abilityId: abilityId, scope: scope);

  final AbilityPostDamageStatCondition condition;
  final Map<String, int> changes;
  final AbilityPostDamageStatChangeTarget changeTarget;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PostDamageStatChangeAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      condition: condition,
      changes: changes,
      changeTarget: changeTarget,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        !_matches(context)) {
      return null;
    }
    final statTarget = switch (changeTarget) {
      AbilityPostDamageStatChangeTarget.owner => context.owner,
      AbilityPostDamageStatChangeTarget.user => context.user,
    };
    if (changeTarget == AbilityPostDamageStatChangeTarget.user &&
        context.state.battlerAt(context.user).isFainted) {
      return null;
    }

    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var applied = false;
    for (final entry in changes.entries) {
      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.owner,
        ),
        target: statTarget,
        stat: entry.key,
        stages: entry.value,
        move: context.move,
      );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      applied = applied || result.applied || result.events.isNotEmpty;
    }
    if (!applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }

  bool _matches(BattleEffectPostDamageContext context) {
    return switch (condition) {
      AbilityPostDamageStatCondition.anyIncoming => true,
      AbilityPostDamageStatCondition.physicalIncoming =>
        context.move.category == PsdkBattleMoveCategory.physical,
      AbilityPostDamageStatCondition.waterIncoming =>
        context.move.type == 'water',
      AbilityPostDamageStatCondition.fireOrWaterIncoming =>
        context.move.type == 'fire' || context.move.type == 'water',
      AbilityPostDamageStatCondition.darkIncoming =>
        context.move.type == 'dark',
      AbilityPostDamageStatCondition.bugDarkOrGhostIncoming =>
        context.move.type == 'bug' ||
            context.move.type == 'dark' ||
            context.move.type == 'ghost',
      AbilityPostDamageStatCondition.contactIncoming =>
        context.move.flags.contact,
    };
  }
}

final class RattledEffect extends PostDamageStatChangeAbilityEffect {
  const RattledEffect({
    required super.scope,
  }) : super(
          abilityId: 'rattled',
          condition: AbilityPostDamageStatCondition.bugDarkOrGhostIncoming,
          changes: const <String, int>{'speed': 1},
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RattledEffect(scope: scope);
  }

  @override
  BattleEffectStatChangePostResult? onStatChangePost(
    BattleEffectStatChangeContext context,
  ) {
    if (context.owner != context.target) {
      return null;
    }
    if (context.sourceAbilityId != 'intimidate') {
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
      stat: 'speed',
      stages: 1,
      move: context.move,
    );
    if (!result.applied && result.events.isEmpty) {
      return null;
    }
    return BattleEffectStatChangePostResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

enum AbilityPostDamageStatChangeTarget {
  owner,
  user,
}
