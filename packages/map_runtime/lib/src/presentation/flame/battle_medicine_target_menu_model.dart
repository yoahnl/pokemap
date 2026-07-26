import 'package:map_battle/map_battle.dart';
import 'package:map_gameplay/map_gameplay.dart';

enum BattleMedicineTargetDisabledReason {
  fainted,
  fullHp,
  noCompatibleStatus,
  notFainted,
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
  PlayerItemEffectRegistry registry = const PlayerItemEffectRegistry.mvp(),
}) {
  final allowsTargeting = session.decisionRequest is BattleTurnChoiceRequest;
  final allowsCombatant = isTargetAllowed ?? (_) => true;
  final effect = registry.effectFor(itemId);

  BattleMedicineTargetEntry buildEntry({
    required int visualIndex,
    required int? reserveIndex,
    required BattleCombatant combatant,
    required bool isActive,
  }) {
    final isFainted = combatant.isFainted;
    final targetAllowed = allowsCombatant(combatant);
    final effectDisabledReason = _effectDisabledReason(
      combatant: combatant,
      effect: effect,
    );
    final isSelectable =
        allowsTargeting && targetAllowed && effectDisabledReason == null;
    final disabledReason = isSelectable
        ? null
        : !allowsTargeting || !targetAllowed
            ? BattleMedicineTargetDisabledReason.notAllowedByCurrentRequest
            : effectDisabledReason;

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

BattleMedicineTargetDisabledReason? _effectDisabledReason({
  required BattleCombatant combatant,
  required PlayerItemEffectDefinition? effect,
}) {
  if (effect == null) {
    return BattleMedicineTargetDisabledReason.notAllowedByCurrentRequest;
  }
  return switch (effect.kind) {
    PlayerItemEffectKind.healHp => combatant.isFainted
        ? BattleMedicineTargetDisabledReason.fainted
        : combatant.currentHp >= combatant.maxHp
            ? BattleMedicineTargetDisabledReason.fullHp
            : null,
    PlayerItemEffectKind.cureStatus => combatant.isFainted
        ? BattleMedicineTargetDisabledReason.fainted
        : _effectCuresStatus(effect, combatant.majorStatus)
            ? null
            : BattleMedicineTargetDisabledReason.noCompatibleStatus,
    PlayerItemEffectKind.revive => combatant.isFainted
        ? null
        : BattleMedicineTargetDisabledReason.notFainted,
    PlayerItemEffectKind.restorePp ||
    PlayerItemEffectKind.keyItem ||
    PlayerItemEffectKind.ballMetadata =>
      BattleMedicineTargetDisabledReason.notAllowedByCurrentRequest,
  };
}

bool _effectCuresStatus(
  PlayerItemEffectDefinition effect,
  BattleMajorStatusState? status,
) {
  if (status == null) {
    return false;
  }
  if (effect.curesAnyStatus) {
    return true;
  }
  return _gameplayStatusIds(status.id).any(effect.statusIds.contains);
}

Set<String> _gameplayStatusIds(BattleMajorStatusId status) {
  return switch (status) {
    BattleMajorStatusId.par => const <String>{'paralysis', 'paralyzed'},
    BattleMajorStatusId.brn => const <String>{'burn'},
    BattleMajorStatusId.psn => const <String>{'poison'},
    BattleMajorStatusId.tox => const <String>{'badly-poisoned'},
    BattleMajorStatusId.slp => const <String>{'sleep'},
    BattleMajorStatusId.frz => const <String>{'freeze', 'frozen'},
  };
}
