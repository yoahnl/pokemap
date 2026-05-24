import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battler/battle_transform_state.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class PrimalOrbEffect extends BattleItemEffect {
  const PrimalOrbEffect.redOrb({
    required BattleEffectScope scope,
  }) : this._(
          itemId: 'red_orb',
          scope: scope,
          speciesId: 'groudon',
          types: const PsdkBattleTypes(primary: 'ground', secondary: 'fire'),
          abilityId: 'desolate_land',
          effectId: 'primal:groudon',
        );

  const PrimalOrbEffect.blueOrb({
    required BattleEffectScope scope,
  }) : this._(
          itemId: 'blue_orb',
          scope: scope,
          speciesId: 'kyogre',
          types: const PsdkBattleTypes(primary: 'water'),
          abilityId: 'primordial_sea',
          effectId: 'primal:kyogre',
        );

  const PrimalOrbEffect._({
    required super.itemId,
    required super.scope,
    required this.speciesId,
    required this.types,
    required this.abilityId,
    required this.effectId,
  });

  final String speciesId;
  final PsdkBattleTypes types;
  final String abilityId;
  final String effectId;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.replacement != owner) {
      return null;
    }
    final holder = context.state.battlerAt(owner);
    if (holder.isFainted ||
        holder.speciesId != speciesId ||
        holder.form == 1 ||
        holder.heldItemId != itemId ||
        holder.itemConsumed ||
        holder.itemEffectsSuppressed) {
      return null;
    }

    final reverted = holder
        .copyWith(
          form: 1,
          types: types,
          abilityId: abilityId,
          transformState: const PsdkBattleTransformState(),
        )
        .withAbilityEffect(owner)
        .withItemEffect(owner);
    var nextState = _replaceActiveAndParty(
      state: context.state,
      slot: owner,
      battler: reverted,
    );
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[
      PsdkBattleEffectEvent.added(
        turn: context.turn,
        target: owner,
        effectId: effectId,
        reason: 'item:$itemId',
      ),
    ];

    final abilitySwitch =
        nextState.battlerAt(owner).effects.dispatchSwitchEvent(
              BattleEffectSwitchEventContext(
                state: nextState,
                rng: nextRng,
                turn: context.turn,
                owner: owner,
                who: context.who,
                replacement: owner,
              ),
            );
    nextState = abilitySwitch.state;
    nextRng = abilitySwitch.rng;
    events.addAll(abilitySwitch.events);

    return BattleEffectSwitchEventResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }
}

PsdkBattleState _replaceActiveAndParty({
  required PsdkBattleState state,
  required PsdkBattleSlotRef slot,
  required PsdkBattleCombatant battler,
}) {
  final party = state.partyForBank(slot.bank);
  final active = state.battlerAt(slot);
  final index = party.indexWhere((candidate) => candidate.id == active.id);
  if (index < 0) {
    return state.replaceBattler(slot, battler);
  }

  final nextParty = <PsdkBattleCombatant>[...party];
  nextParty[index] = battler;
  return state.copyWith(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      ...state.combatants,
      slot: battler,
    },
    parties: <int, List<PsdkBattleCombatant>>{
      ...state.parties,
      slot.bank: List<PsdkBattleCombatant>.unmodifiable(nextParty),
    },
  );
}
