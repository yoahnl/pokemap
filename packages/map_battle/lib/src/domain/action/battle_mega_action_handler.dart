import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../battler/battle_transform_state.dart';
import '../handler/battle_handler_context.dart';
import '../handler/battle_handler_result.dart';
import 'battle_action.dart';

final class BattleMegaActionHandler {
  const BattleMegaActionHandler();

  BattleHandlerResult megaEvolve({
    required BattleHandlerContext context,
    required PsdkBattleMegaAction action,
  }) {
    final user = context.state.battlerAt(action.user);
    if (context.state.hasMegaEvolvedBank(action.user.bank)) {
      throw StateError('Bank ${action.user.bank} has already mega evolved.');
    }
    if (user.isFainted) {
      throw StateError('A fainted battler cannot mega evolve.');
    }
    if (user.transformState.isTransformed) {
      throw StateError('A transformed battler cannot mega evolve.');
    }
    if (user.speciesId != action.form.requiredSpeciesId) {
      throw StateError(
        'Expected ${action.form.requiredSpeciesId} for mega evolution, '
        'got ${user.speciesId}.',
      );
    }

    final evolved = user
        .copyWith(
          speciesId: action.form.speciesId,
          displayName: action.form.displayName,
          types: action.form.types,
          stats: action.form.stats,
          abilityId: action.form.abilityId,
          transformState: const PsdkBattleTransformState(),
        )
        .withAbilityEffect(action.user)
        .withItemEffect(action.user);
    return BattleHandlerResult(
      state: _replaceActiveAndParty(
        context: context,
        slot: action.user,
        battler: evolved,
      ).copyWith(
        megaEvolvedBanks: <int>{
          ...context.state.megaEvolvedBanks,
          action.user.bank,
        },
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: action.user,
          effectId: 'mega:${action.form.speciesId}',
          reason: 'mega',
        ),
      ],
    );
  }
}

PsdkBattleState _replaceActiveAndParty({
  required BattleHandlerContext context,
  required PsdkBattleSlotRef slot,
  required PsdkBattleCombatant battler,
}) {
  final party = context.state.partyForBank(slot.bank);
  final active = context.state.battlerAt(slot);
  final index = party.indexWhere((candidate) => candidate.id == active.id);
  final nextParties = context.state.parties;
  if (index < 0) {
    return context.state.replaceBattler(slot, battler);
  }

  final nextParty = <PsdkBattleCombatant>[...party];
  nextParty[index] = battler;
  return context.state.copyWith(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      ...context.state.combatants,
      slot: battler,
    },
    parties: <int, List<PsdkBattleCombatant>>{
      ...nextParties,
      slot.bank: nextParty,
    },
  );
}
