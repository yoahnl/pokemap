import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class CommanderEffect extends BattleAbilityEffect {
  const CommanderEffect({required super.scope}) : super(abilityId: 'commander');

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CommanderEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (context.replacement.bank != context.owner.bank) {
      return null;
    }
    final commander = context.state.battlerAt(context.owner);
    if (commander.effects.contains('ability_suppressed') ||
        commander.effects.contains('commanding') ||
        _normalizedId(commander.speciesId) != 'tatsugiri') {
      return null;
    }
    final dondozo = _availableDondozo(
      state: context.state,
      commander: context.owner,
    );
    if (dondozo == null) {
      return null;
    }

    var state = context.state
        .updateBattler(
          context.owner,
          (battler) => battler.copyWith(
            effects: battler.effects.addEffects(
              <BattleEffect>[
                CommandingEffect(
                  scope: BattlerBattleEffectScope(context.owner),
                ),
                GenericBattleEffect(
                  id: 'out_of_reach_base',
                  scope: BattlerBattleEffectScope(context.owner),
                ),
              ],
            ),
          ),
        )
        .updateBattler(
          dondozo,
          (battler) => battler.copyWith(
            effects: battler.effects.addEffect(
              CommandedEffect(
                scope: BattlerBattleEffectScope(dondozo),
                origin: context.owner,
              ),
            ),
          ),
        );
    var rng = context.rng;
    final events = <PsdkBattleEvent>[];
    for (final stat in _commanderBoostStats) {
      final boosted = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.owner,
        ),
        target: dondozo,
        stat: stat,
        stages: 2,
        sourceAbilityId: abilityId,
      );
      state = boosted.state;
      rng = boosted.rng;
      events.addAll(boosted.events);
    }

    return BattleEffectSwitchEventResult(
      state: state,
      rng: rng,
      events: events,
    );
  }
}

final class CommandingEffect extends BattleEffect {
  const CommandingEffect({required super.scope}) : super(id: 'commanding');

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CommandingEffect(scope: scope);
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (_owner != context.user) {
      return null;
    }
    return BattleEffectUserMovePreventionResult(
      state: context.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
      recordAttempt: false,
    );
  }

  @override
  String? onSwitchPrevention(BattleEffectSwitchPreventionContext context) {
    return _owner == context.target ? 'commanding' : null;
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    if (_owner != context.target) {
      return null;
    }
    return BattleEffectDamagePreventionResult(
      state: context.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.protected,
      applied: false,
    );
  }

  PsdkBattleSlotRef? get _owner => switch (scope) {
        BattlerBattleEffectScope(:final slot) => slot,
        _ => null,
      };
}

final class CommandedEffect extends BattleEffect {
  const CommandedEffect({
    required super.scope,
    required this.origin,
  }) : super(id: 'commanded');

  final PsdkBattleSlotRef origin;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CommandedEffect(scope: scope, origin: origin);
  }

  @override
  String? onSwitchPrevention(BattleEffectSwitchPreventionContext context) {
    return _owner == context.target ? 'commanded' : null;
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (!context.targetFainted || context.target != _owner) {
      return null;
    }
    final originBattler = context.state.combatants[origin];
    if (originBattler == null ||
        originBattler.isFainted ||
        !originBattler.effects.contains('commanding')) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: context.state.updateBattler(
        origin,
        (battler) => battler.copyWith(
          effects:
              battler.effects.remove('commanding').remove('out_of_reach_base'),
        ),
      ),
      rng: context.rng,
    );
  }

  PsdkBattleSlotRef? get _owner => switch (scope) {
        BattlerBattleEffectScope(:final slot) => slot,
        _ => null,
      };
}

PsdkBattleSlotRef? _availableDondozo({
  required PsdkBattleState state,
  required PsdkBattleSlotRef commander,
}) {
  for (final ally in state.alliesOf(commander)) {
    final battler = state.battlerAt(ally);
    if (!battler.isFainted &&
        !battler.effects.contains('commanded') &&
        _normalizedId(battler.speciesId) == 'dondozo') {
      return ally;
    }
  }
  return null;
}

String _normalizedId(String value) {
  return value.trim().toLowerCase().replaceAll('-', '_');
}

const _commanderBoostStats = <String>{
  'attack',
  'defense',
  'specialAttack',
  'specialDefense',
  'speed',
};
