import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';

enum PsdkBattleActionKind {
  fight,
  switchPokemon,
  item,
  flee,
  mega,
  shift,
  preAttack,
  noAction,
  highPriorityItem,
}

sealed class PsdkBattleAction {
  const PsdkBattleAction({
    required this.kind,
    required this.user,
  });

  final PsdkBattleActionKind kind;
  final PsdkBattleSlotRef user;
}

final class PsdkBattleFightAction extends PsdkBattleAction {
  const PsdkBattleFightAction({
    required PsdkBattleSlotRef user,
    required this.target,
    required this.moveSlot,
    required this.move,
    required this.speed,
  }) : super(kind: PsdkBattleActionKind.fight, user: user);

  final PsdkBattleSlotRef target;
  final int moveSlot;
  final PsdkBattleMoveData move;
  final int speed;
}

final class PsdkBattleSwitchAction extends PsdkBattleAction {
  const PsdkBattleSwitchAction({
    required PsdkBattleSlotRef user,
    required this.partyIndex,
  }) : super(kind: PsdkBattleActionKind.switchPokemon, user: user);

  final int partyIndex;
}

final class PsdkBattleFleeAction extends PsdkBattleAction {
  const PsdkBattleFleeAction({
    required PsdkBattleSlotRef user,
  }) : super(kind: PsdkBattleActionKind.flee, user: user);
}

final class PsdkBattleShiftAction extends PsdkBattleAction {
  const PsdkBattleShiftAction({
    required PsdkBattleSlotRef user,
    required this.target,
  }) : super(kind: PsdkBattleActionKind.shift, user: user);

  final PsdkBattleSlotRef target;
}

final class PsdkBattleMegaEvolution {
  const PsdkBattleMegaEvolution({
    required this.requiredSpeciesId,
    required this.speciesId,
    required this.displayName,
    required this.types,
    required this.stats,
    required this.abilityId,
  });

  final String requiredSpeciesId;
  final String speciesId;
  final String displayName;
  final PsdkBattleTypes types;
  final PsdkBattleStats stats;
  final String abilityId;
}

final class PsdkBattleMegaAction extends PsdkBattleAction {
  const PsdkBattleMegaAction({
    required PsdkBattleSlotRef user,
    required this.form,
  }) : super(kind: PsdkBattleActionKind.mega, user: user);

  final PsdkBattleMegaEvolution form;
}

sealed class PsdkBattleItemActionEffect {
  const PsdkBattleItemActionEffect();
}

final class PsdkBattleHpHealItemEffect extends PsdkBattleItemActionEffect {
  const PsdkBattleHpHealItemEffect.flat(this.amount)
      : restoreToFull = false,
        assert(amount != null && amount > 0,
            'HP-heal item amount must stay positive.');

  const PsdkBattleHpHealItemEffect.full()
      : amount = null,
        restoreToFull = true;

  final int? amount;
  final bool restoreToFull;
}

final class PsdkBattleStatusCureItemEffect extends PsdkBattleItemActionEffect {
  const PsdkBattleStatusCureItemEffect.only(
    Set<PsdkBattleMajorStatus> statuses,
  )   : statuses = statuses,
        cureAny = false;

  const PsdkBattleStatusCureItemEffect.any()
      : statuses = const <PsdkBattleMajorStatus>{},
        cureAny = true;

  final Set<PsdkBattleMajorStatus> statuses;
  final bool cureAny;

  bool cures(PsdkBattleMajorStatus status) {
    return cureAny || statuses.contains(status);
  }
}

final class PsdkBattleItemAction extends PsdkBattleAction {
  const PsdkBattleItemAction({
    required PsdkBattleSlotRef user,
    required this.itemId,
    required this.target,
    required this.effect,
    this.highPriority = false,
  }) : super(
          kind: highPriority
              ? PsdkBattleActionKind.highPriorityItem
              : PsdkBattleActionKind.item,
          user: user,
        );

  final String itemId;
  final PsdkBattleSlotRef target;
  final PsdkBattleItemActionEffect effect;
  final bool highPriority;
}

final class PsdkBattleNoAction extends PsdkBattleAction {
  const PsdkBattleNoAction({
    required PsdkBattleSlotRef user,
  }) : super(kind: PsdkBattleActionKind.noAction, user: user);
}
