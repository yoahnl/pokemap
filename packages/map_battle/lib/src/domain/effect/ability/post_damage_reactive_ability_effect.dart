import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_outcome.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_handler_result.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../handler/battle_switch_handler.dart';
import '../../move/battle_move_data.dart';
import '../../move/battle_move_prevention.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../move/flinch_effect.dart';
import 'ability_effect.dart';
import 'mental_immunity_ability_effect.dart';

final class InnardsOutEffect extends BattleAbilityEffect {
  const InnardsOutEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'innards_out', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return InnardsOutEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        !context.targetFainted) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.isFainted) {
      return null;
    }

    final result = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.user,
      moveId: 'effect:innards_out',
      rawDamage: context.damage,
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

final class CottonDownEffect extends BattleAbilityEffect {
  const CottonDownEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'cotton_down', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CottonDownEffect(scope: scope);
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

    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var applied = false;
    for (final target in context.state.aliveSlots()) {
      if (target == context.owner) {
        continue;
      }
      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.owner,
        ),
        target: target,
        stat: 'speed',
        stages: -1,
        move: context.move,
        sourceAbilityId: abilityId,
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

final class ElectromorphosisEffect extends BattleAbilityEffect {
  const ElectromorphosisEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'electromorphosis', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ElectromorphosisEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0) {
      return null;
    }

    final target = context.state.battlerAt(context.target);
    if (target.effects.contains('charge')) {
      return null;
    }

    const chargeEffectId = 'charge';
    final chargeRemainingTurns = _chargeRemainingTurns(context);
    final charge = GenericBattleEffect(
      id: chargeEffectId,
      scope: BattlerBattleEffectScope(context.target),
      remainingTurns: chargeRemainingTurns,
    );
    return BattleEffectPostDamageResult(
      state: context.state.updateBattler(
        context.target,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(charge),
        ),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: context.target,
          effectId: chargeEffectId,
          remainingTurns: charge.remainingTurns,
          reason: 'ability:electromorphosis',
        ),
      ],
    );
  }
}

final class WindPowerEffect extends BattleAbilityEffect {
  const WindPowerEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'wind_power', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return WindPowerEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        !_isWindMove(context.move)) {
      return null;
    }
    final charged = _addCharge(
      state: context.state,
      owner: context.owner,
      turn: context.turn,
      remainingTurns: _chargeRemainingTurns(context),
      reason: 'ability:$abilityId',
    );
    if (charged == null) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: charged.state,
      rng: context.rng,
      events: charged.events,
    );
  }

  @override
  BattleEffectPostActionResult? onPostAction(
    BattleEffectPostActionContext context,
  ) {
    if (context.owner.bank != context.user.bank ||
        !context.successful ||
        !_isTailwindMove(context.move) ||
        context.state.battlerAt(context.owner).isFainted) {
      return null;
    }
    final charged = _addCharge(
      state: context.state,
      owner: context.owner,
      turn: context.turn,
      remainingTurns: 2,
      reason: 'ability:$abilityId',
    );
    if (charged == null) {
      return null;
    }
    return BattleEffectPostActionResult(
      state: charged.state,
      rng: context.rng,
      events: charged.events,
    );
  }
}

final class WindRiderEffect extends BattleAbilityEffect {
  const WindRiderEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'wind_rider', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return WindRiderEffect(scope: scope);
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        !_isWindMove(context.move)) {
      return null;
    }
    final boosted = _raiseAttack(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: context.owner,
      move: context.move,
      abilityId: abilityId,
    );
    return BattleEffectDamagePreventionResult(
      state: boosted.state,
      rng: boosted.rng,
      prevented: true,
      reason: BattleMoveFailureReason.immunity,
      events: boosted.events,
    );
  }

  @override
  BattleEffectPostActionResult? onPostAction(
    BattleEffectPostActionContext context,
  ) {
    if (context.owner.bank != context.user.bank ||
        !context.successful ||
        !_isTailwindMove(context.move) ||
        context.state.battlerAt(context.owner).isFainted) {
      return null;
    }
    final boosted = _raiseAttack(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: context.owner,
      move: context.move,
      abilityId: abilityId,
    );
    if (!boosted.applied && boosted.events.isEmpty) {
      return null;
    }
    return BattleEffectPostActionResult(
      state: boosted.state,
      rng: boosted.rng,
      events: boosted.events,
    );
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (context.owner != context.replacement ||
        !_bankHasTailwind(context.state, context.owner.bank)) {
      return null;
    }
    final boosted = _raiseAttack(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: context.owner,
      move: null,
      abilityId: abilityId,
    );
    if (!boosted.applied && boosted.events.isEmpty) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: boosted.state,
      rng: boosted.rng,
      events: boosted.events,
    );
  }
}

final class EmergencyExitEffect extends BattleAbilityEffect {
  const EmergencyExitEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return EmergencyExitEffect(abilityId: abilityId, scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        !context.isFinalHit ||
        _skillPreventsEmergencyExit(context.move) ||
        _sheerForceAlreadyActivated(context)) {
      return null;
    }

    final holder = context.state.battlerAt(context.owner);
    final previousHp = _hpBeforeCurrentMoveDamage(
      holder: holder,
      turn: context.turn,
      user: context.user,
      moveId: context.move.id,
      fallbackDamage: context.damage,
    );
    if (holder.abilityId != abilityId ||
        holder.switching ||
        holder.currentHp * 2 > holder.maxHp ||
        previousHp * 2 <= holder.maxHp ||
        holder.effects.contains('out_of_reach') ||
        holder.heldItemId == 'eject_button' ||
        _healingBerryPreventsEmergencyExit(holder)) {
      return null;
    }

    if (!const BattleSwitchHandler().hasAvailableReplacement(
      state: context.state,
      target: context.owner,
    )) {
      if (!context.canFlee) {
        return null;
      }
      return BattleEffectPostDamageResult(
        state: context.state.copyWith(
          outcome: const PsdkBattleOutcome(kind: PsdkBattleOutcomeKind.fled),
        ),
        rng: context.rng,
      );
    }

    final switched = const BattleSwitchHandler().markSwitching(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      switching: true,
    );
    return BattleEffectPostDamageResult(
      state: switched.state,
      rng: switched.rng,
      events: switched.events,
    );
  }
}

bool _skillPreventsEmergencyExit(BattleMoveDefinition move) {
  return switch (move.battleEngineMethod) {
    's_dragon_tail' || 's_roar' || 's_sky_drop' => true,
    _ => false,
  };
}

int _hpBeforeCurrentMoveDamage({
  required PsdkBattleCombatant holder,
  required int turn,
  required PsdkBattleSlotRef user,
  required String moveId,
  required int fallbackDamage,
}) {
  final relevantDamage = holder.damageHistory.entries
      .where(
        (entry) =>
            entry.turn == turn &&
            entry.source == user &&
            _normalizedId(entry.moveId) == _normalizedId(moveId),
      )
      .fold<int>(0, (sum, entry) => sum + entry.damage);
  return holder.currentHp +
      (relevantDamage > 0 ? relevantDamage : fallbackDamage);
}

bool _healingBerryPreventsEmergencyExit(PsdkBattleCombatant holder) {
  final itemId = _normalizedNullableId(holder.heldItemId);
  if (itemId == null) {
    return false;
  }
  final heal = _emergencyExitBerryHealAmount(itemId, holder.maxHp);
  if (heal == null || heal <= 0) {
    return false;
  }
  if (holder.currentHp / holder.maxHp >
      _emergencyExitBerryHpThreshold(itemId)) {
    return false;
  }
  return (holder.currentHp + heal) * 2 > holder.maxHp;
}

int? _emergencyExitBerryHealAmount(String itemId, int maxHp) {
  return switch (itemId) {
    'oran_berry' => 10,
    'sitrus_berry' => (maxHp ~/ 4).clamp(1, maxHp).toInt(),
    'berry_juice' => 20,
    'figy_berry' ||
    'wiki_berry' ||
    'mago_berry' ||
    'aguav_berry' ||
    'iapapa_berry' =>
      (maxHp ~/ 3).clamp(1, maxHp).toInt(),
    _ => null,
  };
}

double _emergencyExitBerryHpThreshold(String itemId) {
  return switch (itemId) {
    'figy_berry' ||
    'wiki_berry' ||
    'mago_berry' ||
    'aguav_berry' ||
    'iapapa_berry' =>
      0.25,
    _ => 0.5,
  };
}

String? _normalizedNullableId(String? id) {
  if (id == null) {
    return null;
  }
  final normalized = _normalizedId(id);
  return normalized.isEmpty ? null : normalized;
}

final class StenchEffect extends BattleAbilityEffect {
  const StenchEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'stench', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StenchEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.user ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.isFainted || _heldItemSuppressesStench(user.heldItemId)) {
      return null;
    }

    final roll = context.rng.generic.nextChance(
      numerator: 1,
      denominator: 10,
    );
    final nextRng = context.rng.copyWith(generic: roll.next);
    if (!roll.didOccur ||
        battleMentalAbilityBlocksEffect(
          state: context.state,
          user: context.user,
          target: context.target,
          effectId: 'flinch',
        )) {
      return BattleEffectPostDamageResult(
        state: context.state,
        rng: nextRng,
        applied: false,
      );
    }

    final result = applyFlinchEffect(
      state: context.state,
      rng: nextRng,
      turn: context.turn,
      target: context.target,
      reason: 'ability:stench',
      move: context.move,
    );
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  bool _heldItemSuppressesStench(String? itemId) {
    return itemId == 'king_s_rock' || itemId == 'razor_fang';
  }
}

bool _sheerForceAlreadyActivated(BattleEffectPostDamageContext context) {
  final attacker = context.state.battlerAt(context.user);
  if (attacker.abilityId != 'sheer_force' ||
      attacker.effects.contains('ability_suppressed') ||
      context.move.category == PsdkBattleMoveCategory.status) {
    return false;
  }
  if (context.move.statuses.any(
        (status) => status.majorStatus != null || status.volatileStatus != null,
      ) ||
      context.move.effectChance != null) {
    return true;
  }
  if (context.move.stageMods.isEmpty) {
    return false;
  }
  final onlyPositive = context.move.stageMods.every((mod) => mod.stages > 0);
  final onlyNegative = context.move.stageMods.every((mod) => mod.stages < 0);
  return switch (context.move.target) {
    PsdkBattleMoveTarget.self || PsdkBattleMoveTarget.user => onlyPositive,
    _ => onlyNegative,
  };
}

_ChargeResult? _addCharge({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
  required int turn,
  required int remainingTurns,
  required String reason,
}) {
  final battler = state.battlerAt(owner);
  if (battler.effects.contains('charge')) {
    return null;
  }
  final charge = GenericBattleEffect(
    id: 'charge',
    scope: BattlerBattleEffectScope(owner),
    remainingTurns: remainingTurns,
  );
  return _ChargeResult(
    state: state.updateBattler(
      owner,
      (current) => current.copyWith(
        effects: current.effects.addEffect(charge),
      ),
    ),
    events: <PsdkBattleEvent>[
      PsdkBattleEffectEvent.added(
        turn: turn,
        target: owner,
        effectId: 'charge',
        remainingTurns: charge.remainingTurns,
        reason: reason,
      ),
    ],
  );
}

int _chargeRemainingTurns(BattleEffectPostDamageContext context) {
  final userOrder = context.userActionOrder;
  final targetOrder = context.targetActionOrder;
  if (userOrder != null && targetOrder != null && userOrder < targetOrder) {
    return 1;
  }
  return 2;
}

BattleHandlerResult _raiseAttack({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef owner,
  required BattleMoveDefinition? move,
  required String abilityId,
}) {
  return const BattleStatChangeHandler().applyStatChange(
    context: BattleHandlerContext(
      state: state,
      rng: rng,
      turn: turn,
      user: owner,
    ),
    target: owner,
    stat: 'attack',
    stages: 1,
    move: move,
    sourceAbilityId: abilityId,
  );
}

bool _isWindMove(BattleMoveDefinition move) {
  return move.flags.wind || _windMoveIds.contains(_normalizedId(move.dbSymbol));
}

bool _isTailwindMove(BattleMoveDefinition move) {
  return _normalizedId(move.dbSymbol) == 'tailwind';
}

bool _bankHasTailwind(PsdkBattleState state, int bank) {
  return state.combatants.values.any(
    (battler) => battler.effects.effects.any((effect) {
      final scope = effect.scope;
      return effect.id == 'tailwind' &&
          scope is BankBattleEffectScope &&
          scope.bank == bank;
    }),
  );
}

String _normalizedId(String id) {
  return id.trim().toLowerCase().replaceAll('-', '_');
}

const _windMoveIds = <String>{
  'air_cutter',
  'bleakwind_storm',
  'blizzard',
  'fairy_wind',
  'gust',
  'heat_wave',
  'hurricane',
  'icy_wind',
  'ominous_wind',
  'petal_blizzard',
  'razor_wind',
  'sandsear_storm',
  'silver_wind',
  'springtide_storm',
  'tailwind',
  'twister',
  'whirlwind',
  'wildbolt_storm',
};

final class _ChargeResult {
  const _ChargeResult({
    required this.state,
    required this.events,
  });

  final PsdkBattleState state;
  final List<PsdkBattleEvent> events;
}
