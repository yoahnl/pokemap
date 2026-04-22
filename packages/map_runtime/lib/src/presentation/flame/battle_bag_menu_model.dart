import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

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
    required this.categoryId,
    required this.quantity,
  });

  final String itemId;
  final String categoryId;
  final int quantity;
}

class BattleBagMenuEntry {
  const BattleBagMenuEntry({
    required this.visualIndex,
    required this.itemId,
    required this.categoryId,
    required this.quantity,
    required this.kind,
    required this.isSelectable,
    required this.disabledReason,
    required this.action,
  });

  final int visualIndex;
  final String itemId;
  final String categoryId;
  final int quantity;
  final BattleBagItemKind kind;
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
}) {
  final normalizedBag = gameState.bag.normalized();
  final captureChoice = _captureChoiceFor(session.decisionRequest);
  final entries = List<BattleBagMenuEntry>.unmodifiable(
    normalizedBag.entries.asMap().entries.map(
          (entry) => _buildEntry(
            visualIndex: entry.key,
            bagEntry: entry.value,
            gameState: gameState,
            session: session,
            captureChoice: captureChoice,
          ),
        ),
  );

  return BattleBagMenuModel(
    mode: _modeForEntries(entries),
    entries: entries,
  );
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
}) {
  final kind = _classifyBagItem(bagEntry);

  return switch (kind) {
    BattleBagItemKind.captureBall => _buildCaptureEntry(
        visualIndex: visualIndex,
        bagEntry: bagEntry,
        gameState: gameState,
        session: session,
        captureChoice: captureChoice,
      ),
    BattleBagItemKind.medicine => _buildMedicineEntry(
        visualIndex: visualIndex,
        bagEntry: bagEntry,
        session: session,
      ),
    BattleBagItemKind.unsupported => BattleBagMenuEntry(
        visualIndex: visualIndex,
        itemId: bagEntry.itemId,
        categoryId: bagEntry.categoryId,
        quantity: bagEntry.quantity,
        kind: kind,
        isSelectable: false,
        disabledReason: BattleBagMenuDisabledReason.unsupportedItem,
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
}) {
  final isSelectable = captureChoice != null;
  return BattleBagMenuEntry(
    visualIndex: visualIndex,
    itemId: bagEntry.itemId,
    categoryId: bagEntry.categoryId,
    quantity: bagEntry.quantity,
    kind: BattleBagItemKind.captureBall,
    isSelectable: isSelectable,
    disabledReason: isSelectable
        ? null
        : _captureDisabledReason(
            gameState: gameState,
            session: session,
          ),
    action: isSelectable ? BattleBagMenuActionCapture(captureChoice) : null,
  );
}

BattleBagMenuEntry _buildMedicineEntry({
  required int visualIndex,
  required BagEntry bagEntry,
  required BattleSession session,
}) {
  if (!_isSupportedMedicine(bagEntry)) {
    return BattleBagMenuEntry(
      visualIndex: visualIndex,
      itemId: bagEntry.itemId,
      categoryId: bagEntry.categoryId,
      quantity: bagEntry.quantity,
      kind: BattleBagItemKind.medicine,
      isSelectable: false,
      disabledReason: BattleBagMenuDisabledReason.unsupportedMedicine,
      action: null,
    );
  }

  final bagAllowed = session.decisionRequest is BattleTurnChoiceRequest;
  return BattleBagMenuEntry(
    visualIndex: visualIndex,
    itemId: bagEntry.itemId,
    categoryId: bagEntry.categoryId,
    quantity: bagEntry.quantity,
    kind: BattleBagItemKind.medicine,
    isSelectable: bagAllowed,
    disabledReason: bagAllowed
        ? null
        : BattleBagMenuDisabledReason.currentRequestDisallowsBag,
    action: bagAllowed
        ? BattleBagMenuActionMedicineTarget(
            itemId: bagEntry.itemId,
            categoryId: bagEntry.categoryId,
            quantity: bagEntry.quantity,
          )
        : null,
  );
}

PlayerBattleChoiceCapture? _captureChoiceFor(BattleDecisionRequest request) {
  for (final choice in request.allowedChoices) {
    if (choice is PlayerBattleChoiceCapture) {
      return choice;
    }
  }
  return null;
}

BattleBagItemKind _classifyBagItem(BagEntry bagEntry) {
  if (bagEntry.itemId == 'poke-ball' && bagEntry.categoryId == 'items') {
    return BattleBagItemKind.captureBall;
  }
  if (bagEntry.categoryId == 'medicine') {
    return BattleBagItemKind.medicine;
  }
  return BattleBagItemKind.unsupported;
}

bool _isSupportedMedicine(BagEntry bagEntry) {
  // Lot 9-f factorise ici le strict minimum utile :
  // - `potion`
  // - `super-potion`
  //
  // On ne bascule pas vers un registre d'items ni vers un catalogue runtime.
  if (bagEntry.categoryId != 'medicine') {
    return false;
  }
  return bagEntry.itemId == 'potion' || bagEntry.itemId == 'super-potion';
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
