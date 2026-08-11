import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

enum BattleBagMenuMode {
  empty,
  available,
  unavailable,
}

enum BattleBagItemKind {
  captureBall,
  medicine,
  unsupported,
}

enum BattleBagMenuDisabledReason {
  trainerBattle,
  partyFull,
  captureUnavailable,
  currentRequestDisallowsBag,
  medicineNotImplemented,
  unsupportedMedicine,
  unsupportedItem,
  passive,
  unavailableInContext,
  invalidDefinition,
  unsupportedCapability,
}

sealed class BattleBagMenuAction {
  const BattleBagMenuAction();
}

final class BattleBagMenuActionCapture extends BattleBagMenuAction {
  const BattleBagMenuActionCapture(this.playerChoice);

  final PlayerBattleChoiceCapture playerChoice;
}

final class BattleBagMenuActionMedicineTarget extends BattleBagMenuAction {
  const BattleBagMenuActionMedicineTarget({
    required this.itemId,
    required this.displayName,
    required this.quantity,
  });

  final String itemId;
  final String displayName;
  final int quantity;
}

class BattleBagMenuEntry {
  const BattleBagMenuEntry({
    required this.visualIndex,
    required this.itemId,
    required this.displayName,
    required this.pocketId,
    required this.quantity,
    required this.kind,
    required this.usability,
    required this.isSelectable,
    required this.disabledReason,
    required this.action,
  });

  final int visualIndex;
  final String itemId;
  final String displayName;
  final String pocketId;
  final int quantity;
  final BattleBagItemKind kind;
  final ItemUsabilityState usability;
  final bool isSelectable;
  final BattleBagMenuDisabledReason? disabledReason;
  final BattleBagMenuAction? action;
}

class BattleBagMenuModel {
  const BattleBagMenuModel({
    required this.mode,
    required this.entries,
  });

  final BattleBagMenuMode mode;
  final List<BattleBagMenuEntry> entries;

  bool get hasEntries => entries.isNotEmpty;

  bool get hasSelectableEntries => entries.any((entry) => entry.isSelectable);
}

BattleBagMenuModel buildBattleBagMenuModel({
  required GameState gameState,
  required BattleSession session,
  required ItemCapabilityResolver resolver,
}) {
  final normalizedBag = gameState.bag.normalized();
  final captureChoice = _captureChoiceFor(session.decisionRequest);
  final entries = List<BattleBagMenuEntry>.unmodifiable(
    _sortedBagEntriesForDisplay(
      normalizedBag.entries.asMap().entries.map(
            (entry) => _buildEntry(
              visualIndex: entry.key,
              bagEntry: entry.value,
              gameState: gameState,
              session: session,
              captureChoice: captureChoice,
              resolver: resolver,
            ),
          ),
    ),
  );

  return BattleBagMenuModel(
    mode: _modeForEntries(entries),
    entries: entries,
  );
}

List<BattleBagMenuEntry> _sortedBagEntriesForDisplay(
  Iterable<BattleBagMenuEntry> entries,
) {
  final sorted = entries.toList(growable: false);
  sorted.sort((left, right) {
    final rankCompare = _displayRankForBagKind(left.kind)
        .compareTo(_displayRankForBagKind(right.kind));
    if (rankCompare != 0) {
      return rankCompare;
    }
    final pocketCompare = left.pocketId.compareTo(right.pocketId);
    if (pocketCompare != 0) {
      return pocketCompare;
    }
    final itemCompare = left.itemId.compareTo(right.itemId);
    if (itemCompare != 0) {
      return itemCompare;
    }
    return left.visualIndex.compareTo(right.visualIndex);
  });
  return sorted;
}

int _displayRankForBagKind(BattleBagItemKind kind) {
  return switch (kind) {
    BattleBagItemKind.captureBall => 0,
    BattleBagItemKind.medicine => 1,
    BattleBagItemKind.unsupported => 2,
  };
}

BattleBagMenuMode _modeForEntries(List<BattleBagMenuEntry> entries) {
  if (entries.isEmpty) {
    return BattleBagMenuMode.empty;
  }
  if (entries.any((entry) => entry.isSelectable)) {
    return BattleBagMenuMode.available;
  }
  return BattleBagMenuMode.unavailable;
}

BattleBagMenuEntry _buildEntry({
  required int visualIndex,
  required BagEntry bagEntry,
  required GameState gameState,
  required BattleSession session,
  required PlayerBattleChoiceCapture? captureChoice,
  required ItemCapabilityResolver resolver,
}) {
  final definition = resolver.definitionFor(bagEntry.itemId);
  final kind = classifyBattleBagItem(
    itemId: bagEntry.itemId,
    resolver: resolver,
  );

  return switch (kind) {
    BattleBagItemKind.captureBall => _buildCaptureEntry(
        visualIndex: visualIndex,
        bagEntry: bagEntry,
        gameState: gameState,
        session: session,
        captureChoice: captureChoice,
        definition: definition!,
      ),
    BattleBagItemKind.medicine => _buildMedicineEntry(
        visualIndex: visualIndex,
        bagEntry: bagEntry,
        session: session,
        definition: definition!,
      ),
    BattleBagItemKind.unsupported => BattleBagMenuEntry(
        visualIndex: visualIndex,
        itemId: bagEntry.itemId,
        displayName: definition?.displayName ?? bagEntry.itemId,
        pocketId: definition?.pocketId ?? '',
        quantity: bagEntry.quantity,
        kind: kind,
        usability: resolveBattleBagItemUsability(
          itemId: bagEntry.itemId,
          resolver: resolver,
        ),
        isSelectable: false,
        disabledReason: _unsupportedDisabledReason(
          bagEntry.itemId,
          resolver,
        ),
        action: null,
      ),
  };
}

BattleBagMenuEntry _buildCaptureEntry({
  required int visualIndex,
  required BagEntry bagEntry,
  required GameState gameState,
  required BattleSession session,
  required PlayerBattleChoiceCapture? captureChoice,
  required ProjectItemDefinition definition,
}) {
  final isSelectable = captureChoice != null;
  return BattleBagMenuEntry(
    visualIndex: visualIndex,
    itemId: bagEntry.itemId,
    displayName: definition.displayName,
    pocketId: definition.pocketId,
    quantity: bagEntry.quantity,
    kind: BattleBagItemKind.captureBall,
    usability: isSelectable
        ? ItemUsabilityState.usable
        : ItemUsabilityState.unavailableInContext,
    isSelectable: isSelectable,
    disabledReason: isSelectable
        ? null
        : _captureDisabledReason(
            gameState: gameState,
            session: session,
          ),
    action: isSelectable
        ? BattleBagMenuActionCapture(
            PlayerBattleChoiceCapture(
              itemId: bagEntry.itemId,
              rateNumerator: definition.capture!.rateNumerator,
              rateDenominator: definition.capture!.rateDenominator,
            ),
          )
        : null,
  );
}

BattleBagMenuEntry _buildMedicineEntry({
  required int visualIndex,
  required BagEntry bagEntry,
  required BattleSession session,
  required ProjectItemDefinition definition,
}) {
  final bagAllowed = session.decisionRequest is BattleTurnChoiceRequest;
  return BattleBagMenuEntry(
    visualIndex: visualIndex,
    itemId: bagEntry.itemId,
    displayName: definition.displayName,
    pocketId: definition.pocketId,
    quantity: bagEntry.quantity,
    kind: BattleBagItemKind.medicine,
    usability: bagAllowed
        ? ItemUsabilityState.usable
        : ItemUsabilityState.unavailableInContext,
    isSelectable: bagAllowed,
    disabledReason: bagAllowed
        ? null
        : BattleBagMenuDisabledReason.currentRequestDisallowsBag,
    action: bagAllowed
        ? BattleBagMenuActionMedicineTarget(
            itemId: bagEntry.itemId,
            displayName: definition.displayName,
            quantity: bagEntry.quantity,
          )
        : null,
  );
}

ItemUsabilityState resolveBattleBagItemUsability({
  required String itemId,
  required ItemCapabilityResolver resolver,
}) {
  final definition = resolver.definitionFor(itemId);
  if (definition?.capture != null) {
    return ItemUsabilityState.usable;
  }
  final capability = resolver.resolveUse(
    itemId: itemId,
    context: ProjectItemUseContext.battle,
  );
  if (capability.isAvailable) {
    return _isMedicineEffect(capability.use!.effect)
        ? ItemUsabilityState.usable
        : ItemUsabilityState.unsupportedCapability;
  }
  return resolver.classifyUse(
    itemId: itemId,
    context: ProjectItemUseContext.battle,
  );
}

ItemUsabilityState _unsupportedUsability(
  String itemId,
  ItemCapabilityResolver resolver,
) {
  return resolveBattleBagItemUsability(
    itemId: itemId,
    resolver: resolver,
  );
}

BattleBagMenuDisabledReason _unsupportedDisabledReason(
  String itemId,
  ItemCapabilityResolver resolver,
) {
  return switch (_unsupportedUsability(itemId, resolver)) {
    ItemUsabilityState.passive => BattleBagMenuDisabledReason.passive,
    ItemUsabilityState.unavailableInContext =>
      BattleBagMenuDisabledReason.unavailableInContext,
    ItemUsabilityState.invalidDefinition =>
      BattleBagMenuDisabledReason.invalidDefinition,
    ItemUsabilityState.unsupportedCapability =>
      BattleBagMenuDisabledReason.unsupportedCapability,
    ItemUsabilityState.usable => BattleBagMenuDisabledReason.unsupportedItem,
  };
}

PlayerBattleChoiceCapture? _captureChoiceFor(BattleDecisionRequest request) {
  for (final choice in request.allowedChoices) {
    if (choice is PlayerBattleChoiceCapture) {
      return choice;
    }
  }
  return null;
}

BattleBagItemKind classifyBattleBagItem({
  required String itemId,
  required ItemCapabilityResolver resolver,
}) {
  final definition = resolver.definitionFor(itemId);
  if (definition == null) {
    return BattleBagItemKind.unsupported;
  }
  if (definition.capture != null) {
    return BattleBagItemKind.captureBall;
  }
  final battleUse = resolver.resolveUse(
    itemId: itemId,
    context: ProjectItemUseContext.battle,
  );
  if (battleUse.isAvailable && _isMedicineEffect(battleUse.use!.effect)) {
    return BattleBagItemKind.medicine;
  }
  return BattleBagItemKind.unsupported;
}

bool _isMedicineEffect(ProjectItemEffectDefinition effect) {
  return effect is ProjectItemHealHpEffectDefinition ||
      effect is ProjectItemCureStatusEffectDefinition ||
      effect is ProjectItemReviveEffectDefinition;
}

BattleBagMenuDisabledReason _captureDisabledReason({
  required GameState gameState,
  required BattleSession session,
}) {
  if (session.setup.isTrainerBattle) {
    return BattleBagMenuDisabledReason.trainerBattle;
  }
  if (session.decisionRequest is! BattleTurnChoiceRequest) {
    return BattleBagMenuDisabledReason.currentRequestDisallowsBag;
  }
  if (!session.setup.allowCapture && gameState.party.members.length >= 6) {
    return BattleBagMenuDisabledReason.partyFull;
  }
  return BattleBagMenuDisabledReason.captureUnavailable;
}
