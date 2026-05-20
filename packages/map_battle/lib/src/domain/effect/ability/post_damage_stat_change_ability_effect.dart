import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../handler/battle_status_change_handler.dart';
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

final class AngerPointEffect extends BattleAbilityEffect {
  const AngerPointEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'anger_point', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AngerPointEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        !context.criticalHit) {
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
      stat: 'attack',
      stages: 12,
      move: context.move,
    );
    if (!result.applied && result.events.isEmpty) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
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

final class ThermalExchangeEffect extends BattleAbilityEffect {
  const ThermalExchangeEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'thermal_exchange', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ThermalExchangeEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        context.move.type.toLowerCase() != 'fire') {
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
      stat: 'attack',
      stages: 1,
      move: context.move,
    );
    if (!result.applied && result.events.isEmpty) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  @override
  String? onStatusPrevention(BattleEffectStatusPreventionContext context) {
    if (!isOwnedBy(context.target) ||
        context.status != PsdkBattleMajorStatus.burn ||
        context.user == context.target) {
      return null;
    }
    return 'ability:$abilityId';
  }

  @override
  BattleEffectStatusChangeResult? onPostStatusChange(
    BattleEffectStatusChangeContext context,
  ) {
    if (context.cured ||
        !isOwnedBy(context.target) ||
        context.status != PsdkBattleMajorStatus.burn) {
      return null;
    }

    final result = const BattleStatusChangeHandler().cureMajorStatus(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.target,
      moveId: 'effect:thermal_exchange',
    );
    if (!result.applied && result.events.isEmpty) {
      return null;
    }
    return BattleEffectStatusChangeResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

final class PostDamageKoStatBoostAbilityEffect extends BattleAbilityEffect {
  const PostDamageKoStatBoostAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    String? boostedStat,
    this.skipFellStinger = false,
  })  : _boostedStat = boostedStat,
        super(abilityId: abilityId, scope: scope);

  final String? _boostedStat;
  final bool skipFellStinger;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PostDamageKoStatBoostAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      boostedStat: _boostedStat,
      skipFellStinger: skipFellStinger,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.user ||
        context.user == context.target ||
        context.damage <= 0 ||
        !context.targetFainted ||
        context.state.battlerAt(context.owner).isFainted ||
        (skipFellStinger &&
            context.move.battleEngineMethod == 's_fell_stinger')) {
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
      stat: _boostedStat ??
          _highestBattleStat(context.state.battlerAt(context.owner)),
      stages: 1,
      move: context.move,
    );
    if (!result.applied && result.events.isEmpty) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

final class SoulHeartEffect extends BattleAbilityEffect {
  const SoulHeartEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'soul_heart', scope: scope);

  @override
  bool get affectsAlliesPostDamage => true;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SoulHeartEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner == context.target ||
        context.owner.bank != context.target.bank ||
        context.user == context.target ||
        context.damage <= 0 ||
        !context.targetFainted ||
        context.state.battlerAt(context.owner).isFainted) {
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
      stat: 'specialAttack',
      stages: 1,
      move: context.move,
    );
    if (!result.applied && result.events.isEmpty) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

final class HalfHpThresholdStatChangeAbilityEffect extends BattleAbilityEffect {
  const HalfHpThresholdStatChangeAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.changes,
  }) : super(abilityId: abilityId, scope: scope);

  final Map<String, int> changes;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return HalfHpThresholdStatChangeAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      changes: changes,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted) {
      return null;
    }

    final target = context.state.battlerAt(context.target);
    final previousHp = target.currentHp + context.damage;
    final halfHp = target.maxHp / 2;
    if (target.currentHp > halfHp || previousHp <= halfHp) {
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
        target: context.owner,
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
}

String _highestBattleStat(PsdkBattleCombatant battler) {
  final stats = <String, int>{
    'speed': battler.stats.speed,
    'defense': battler.stats.defense,
    'specialAttack': battler.stats.specialAttack,
    'specialDefense': battler.stats.specialDefense,
    'attack': battler.stats.attack,
  };
  return stats.entries.reduce((left, right) {
    return right.value > left.value ? right : left;
  }).key;
}

enum AbilityPostDamageStatChangeTarget {
  owner,
  user,
}
