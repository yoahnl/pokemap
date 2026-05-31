import 'package:map_battle/map_battle.dart';

enum BattleMedicineTargetDisabledReason {
  fainted,
  fullHp,
  notAllowedByCurrentRequest,
}

class BattleMedicineTargetEntry {
  const BattleMedicineTargetEntry({
    required this.visualIndex,
    required this.lineupIndex,
    required this.reserveIndex,
    required this.speciesId,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.isActive,
    required this.isFainted,
    required this.isSelectable,
    required this.disabledReason,
  });

  final int visualIndex;
  final int lineupIndex;
  final int? reserveIndex;
  final String speciesId;
  final int level;
  final int currentHp;
  final int maxHp;
  final bool isActive;
  final bool isFainted;
  final bool isSelectable;
  final BattleMedicineTargetDisabledReason? disabledReason;
}

class BattleMedicineTargetMenuModel {
  const BattleMedicineTargetMenuModel({
    required this.itemId,
    required this.categoryId,
    required this.activeEntry,
    required this.reserveEntries,
    required this.entries,
  });

  final String itemId;
  final String categoryId;
  final BattleMedicineTargetEntry activeEntry;
  final List<BattleMedicineTargetEntry> reserveEntries;
  final List<BattleMedicineTargetEntry> entries;

  bool get hasSelectableEntries => entries.any((entry) => entry.isSelectable);
}

// Shell only: ce modèle expose uniquement les cibles medicine visibles
// depuis la lineup battle courante. Il ne lit pas la party du GameState et
// ne porte ni soin, ni consommation, ni PlayerBattleChoice item.
BattleMedicineTargetMenuModel buildBattleMedicineTargetMenuModel({
  required BattleSession session,
  required String itemId,
  required String categoryId,
  bool Function(BattleCombatant combatant)? isTargetAllowed,
}) {
  final allowsTargeting = session.decisionRequest is BattleTurnChoiceRequest;
  final allowsCombatant = isTargetAllowed ?? (_) => true;

  BattleMedicineTargetEntry buildEntry({
    required int visualIndex,
    required int? reserveIndex,
    required BattleCombatant combatant,
    required bool isActive,
  }) {
    final isFainted = combatant.isFainted;
    final isFullHp = combatant.currentHp >= combatant.maxHp;
    final targetAllowed = allowsCombatant(combatant);
    final isSelectable =
        allowsTargeting && targetAllowed && !isFainted && !isFullHp;
    final disabledReason = isSelectable
        ? null
        : !allowsTargeting || !targetAllowed
            ? BattleMedicineTargetDisabledReason.notAllowedByCurrentRequest
            : isFainted
                ? BattleMedicineTargetDisabledReason.fainted
                : BattleMedicineTargetDisabledReason.fullHp;

    return BattleMedicineTargetEntry(
      visualIndex: visualIndex,
      lineupIndex: combatant.lineupIndex,
      reserveIndex: reserveIndex,
      speciesId: combatant.speciesId,
      level: combatant.level,
      currentHp: combatant.currentHp,
      maxHp: combatant.maxHp,
      isActive: isActive,
      isFainted: isFainted,
      isSelectable: isSelectable,
      disabledReason: disabledReason,
    );
  }

  final activeEntry = buildEntry(
    visualIndex: 0,
    reserveIndex: null,
    combatant: session.state.player,
    isActive: true,
  );

  final reserveEntries = <BattleMedicineTargetEntry>[
    for (var index = 0; index < session.state.playerReserve.length; index++)
      buildEntry(
        visualIndex: index + 1,
        reserveIndex: index,
        combatant: session.state.playerReserve[index],
        isActive: false,
      ),
  ];

  return BattleMedicineTargetMenuModel(
    itemId: itemId,
    categoryId: categoryId,
    activeEntry: activeEntry,
    reserveEntries: List<BattleMedicineTargetEntry>.unmodifiable(
      reserveEntries,
    ),
    entries: List<BattleMedicineTargetEntry>.unmodifiable(
      <BattleMedicineTargetEntry>[activeEntry, ...reserveEntries],
    ),
  );
}
