import 'package:map_battle/map_battle.dart';

final class RuntimeBattleActiveCombatantProjection {
  const RuntimeBattleActiveCombatantProjection({
    required this.slot,
    required this.combatantId,
    required this.lineupIndex,
    required this.combatant,
  });

  final BattleSlotRef slot;
  final String combatantId;
  final int lineupIndex;
  final BattleCombatant combatant;
}

final class RuntimeBattlePresentation {
  RuntimeBattlePresentation({
    required Iterable<RuntimeBattleActiveCombatantProjection> activeCombatants,
    required Iterable<BattleCombatant> playerParty,
    required this.request,
    required this.isDoubles,
  }) : activeCombatants = List.unmodifiable(activeCombatants),
       playerParty = List.unmodifiable(playerParty);

  final List<RuntimeBattleActiveCombatantProjection> activeCombatants;
  final List<BattleCombatant> playerParty;
  final BattleEngineDecisionRequest request;
  final bool isDoubles;

  Map<BattleSlotRef, BattleCombatant> get combatantsBySlot => Map.unmodifiable({
    for (final active in activeCombatants) active.slot: active.combatant,
  });

  RuntimeBattleActiveCombatantProjection? combatantAt(BattleSlotRef slot) =>
      activeCombatants.where((active) => active.slot == slot).firstOrNull;
}

BattleSlotRef runtimeBattleSlot(PsdkBattleSlotRef slot) => BattleSlotRef(
  side: switch (slot.bank) {
    0 => BattleSideId.player,
    1 => BattleSideId.enemy,
    _ => throw ArgumentError.value(slot.bank, 'bank'),
  },
  slotIndex: slot.position,
);

PsdkBattleSlotRef runtimePsdkBattleSlot(BattleSlotRef slot) =>
    PsdkBattleSlotRef(
      bank: slot.side == BattleSideId.player ? 0 : 1,
      position: slot.slotIndex,
    );
