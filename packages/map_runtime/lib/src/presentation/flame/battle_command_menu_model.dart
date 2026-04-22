import 'package:map_battle/map_battle.dart';

enum BattleCommandChoiceTone {
  attack,
  special,
  support,
  switching,
  neutral,
}

enum BattleCommandMenuMode {
  root,
  fight,
  bag,
  bagMedicineTarget,
  pokemon,
  continueOnly,
}

enum BattleCommandRootAction {
  fight,
  bag,
  pokemon,
  run,
}

class BattleCommandChoiceEntry {
  const BattleCommandChoiceEntry({
    required this.choice,
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  final PlayerBattleChoice choice;
  final String title;
  final String subtitle;
  final BattleCommandChoiceTone tone;
}

class BattleCommandRootEntry {
  const BattleCommandRootEntry({
    required this.action,
    required this.label,
    required this.subtitle,
    required this.enabled,
  });

  final BattleCommandRootAction action;
  final String label;
  final String subtitle;
  final bool enabled;
}

class BattleCommandMenuModel {
  const BattleCommandMenuModel({
    required this.mode,
    required this.rootEntries,
    required this.selectedRootIndex,
    required this.choiceEntries,
    required this.selectedChoiceIndex,
    required this.choiceColumns,
    required this.choiceGroupTitle,
  });

  final BattleCommandMenuMode mode;
  final List<BattleCommandRootEntry> rootEntries;
  final int selectedRootIndex;
  final List<BattleCommandChoiceEntry> choiceEntries;
  final int selectedChoiceIndex;
  final int choiceColumns;
  final String choiceGroupTitle;

  bool get isRootMode => mode == BattleCommandMenuMode.root;
  bool get isContinueOnly => mode == BattleCommandMenuMode.continueOnly;
}

BattleCommandMenuMode normalizeBattleCommandMenuMode({
  required BattleDecisionRequest request,
  required BattleCommandMenuMode currentMode,
}) {
  if (request is BattleContinueRequest) {
    return BattleCommandMenuMode.continueOnly;
  }
  if (currentMode == BattleCommandMenuMode.continueOnly) {
    return BattleCommandMenuMode.root;
  }
  switch (currentMode) {
    case BattleCommandMenuMode.root:
    case BattleCommandMenuMode.fight:
    case BattleCommandMenuMode.bag:
    case BattleCommandMenuMode.bagMedicineTarget:
    case BattleCommandMenuMode.pokemon:
      return currentMode;
    case BattleCommandMenuMode.continueOnly:
      return BattleCommandMenuMode.root;
  }
}

BattleCommandMenuModel buildBattleCommandMenuModel({
  required BattleSession session,
  required BattleCommandMenuMode mode,
  required int selectedRootIndex,
  required int selectedChoiceIndex,
}) {
  final request = session.decisionRequest;
  final normalizedMode = normalizeBattleCommandMenuMode(
    request: request,
    currentMode: mode,
  );
  final rootEntries = _buildRootEntries(request);

  if (normalizedMode == BattleCommandMenuMode.continueOnly) {
    final continueChoice = request.allowedChoices.firstWhere(
      (choice) => choice is PlayerBattleChoiceContinue,
      orElse: () => const PlayerBattleChoiceContinue(),
    );
    return BattleCommandMenuModel(
      mode: normalizedMode,
      rootEntries: rootEntries,
      selectedRootIndex: 0,
      choiceEntries: <BattleCommandChoiceEntry>[
        const BattleCommandChoiceEntry(
          choice: PlayerBattleChoiceContinue(),
          title: 'CONTINUE',
          subtitle: 'Forced turn progression',
          tone: BattleCommandChoiceTone.neutral,
        ),
      ],
      selectedChoiceIndex: 0,
      choiceColumns: 1,
      choiceGroupTitle:
          continueChoice is PlayerBattleChoiceContinue ? 'CONTINUE' : 'COMMAND',
    );
  }

  final safeRootIndex = selectedRootIndex.clamp(0, rootEntries.length - 1);
  final safeMode = _normalizeSubmenuAgainstRequest(
    request: request,
    mode: normalizedMode,
  );
  final choiceEntries = _buildChoiceEntries(
    session: session,
    mode: safeMode,
  );
  final safeChoiceIndex = choiceEntries.isEmpty
      ? 0
      : selectedChoiceIndex.clamp(0, choiceEntries.length - 1);

  return BattleCommandMenuModel(
    mode: safeMode,
    rootEntries: List<BattleCommandRootEntry>.unmodifiable(rootEntries),
    selectedRootIndex: safeRootIndex,
    choiceEntries: List<BattleCommandChoiceEntry>.unmodifiable(choiceEntries),
    selectedChoiceIndex: safeChoiceIndex,
    choiceColumns: _choiceColumnsFor(
      mode: safeMode,
      entryCount: choiceEntries.length,
    ),
    choiceGroupTitle: _choiceGroupTitleFor(safeMode),
  );
}

int moveBattleCommandGridSelection({
  required int currentIndex,
  required int itemCount,
  required int columnCount,
  required int horizontalDelta,
  required int verticalDelta,
}) {
  if (itemCount <= 0) {
    return 0;
  }
  final safeColumns = columnCount <= 0 ? 1 : columnCount;
  final rowCount = (itemCount / safeColumns).ceil();
  final currentRow = currentIndex ~/ safeColumns;
  final currentColumn = currentIndex % safeColumns;
  final nextRow = (currentRow + verticalDelta).clamp(0, rowCount - 1).toInt();
  var nextColumn =
      (currentColumn + horizontalDelta).clamp(0, safeColumns - 1).toInt();
  var nextIndex = (nextRow * safeColumns) + nextColumn;
  while (nextIndex >= itemCount && nextColumn > 0) {
    nextColumn--;
    nextIndex = (nextRow * safeColumns) + nextColumn;
  }
  return nextIndex.clamp(0, itemCount - 1).toInt();
}

BattleCommandMenuMode _normalizeSubmenuAgainstRequest({
  required BattleDecisionRequest request,
  required BattleCommandMenuMode mode,
}) {
  if (mode == BattleCommandMenuMode.root) {
    return mode;
  }
  if (request is BattleForcedReplacementRequest &&
      mode != BattleCommandMenuMode.pokemon) {
    return BattleCommandMenuMode.root;
  }
  if (mode == BattleCommandMenuMode.fight &&
      request.allowedChoices.whereType<PlayerBattleChoiceFight>().isEmpty) {
    return BattleCommandMenuMode.root;
  }
  if (mode == BattleCommandMenuMode.pokemon &&
      request.allowedChoices.whereType<PlayerBattleChoiceSwitch>().isEmpty) {
    return BattleCommandMenuMode.root;
  }
  if (mode == BattleCommandMenuMode.bag &&
      request is! BattleTurnChoiceRequest) {
    return BattleCommandMenuMode.root;
  }
  if (mode == BattleCommandMenuMode.bagMedicineTarget &&
      request is! BattleTurnChoiceRequest) {
    return BattleCommandMenuMode.root;
  }
  return mode;
}

List<BattleCommandRootEntry> _buildRootEntries(BattleDecisionRequest request) {
  final fightChoices =
      request.allowedChoices.whereType<PlayerBattleChoiceFight>();
  final switchChoices =
      request.allowedChoices.whereType<PlayerBattleChoiceSwitch>();
  final captureChoices =
      request.allowedChoices.whereType<PlayerBattleChoiceCapture>();
  final runChoices = request.allowedChoices.whereType<PlayerBattleChoiceRun>();
  final bagInspectable = request is BattleTurnChoiceRequest;

  return <BattleCommandRootEntry>[
    BattleCommandRootEntry(
      action: BattleCommandRootAction.fight,
      label: 'FIGHT',
      subtitle: fightChoices.isEmpty
          ? 'Unavailable'
          : '${fightChoices.length} move${fightChoices.length > 1 ? 's' : ''}',
      enabled: fightChoices.isNotEmpty,
    ),
    BattleCommandRootEntry(
      action: BattleCommandRootAction.bag,
      label: 'BAG',
      subtitle: !bagInspectable
          ? 'Unavailable'
          : captureChoices.isEmpty
              ? 'Inspect'
              : 'Capture',
      enabled: bagInspectable,
    ),
    BattleCommandRootEntry(
      action: BattleCommandRootAction.pokemon,
      label: 'POKÉMON',
      subtitle: switchChoices.isEmpty
          ? 'Unavailable'
          : '${switchChoices.length} switch${switchChoices.length > 1 ? 'es' : ''}',
      enabled: switchChoices.isNotEmpty,
    ),
    BattleCommandRootEntry(
      action: BattleCommandRootAction.run,
      label: 'RUN',
      subtitle: runChoices.isEmpty ? 'Unavailable' : 'Escape',
      enabled: runChoices.isNotEmpty,
    ),
  ];
}

List<BattleCommandChoiceEntry> _buildChoiceEntries({
  required BattleSession session,
  required BattleCommandMenuMode mode,
}) {
  final request = session.decisionRequest;
  if (mode == BattleCommandMenuMode.root) {
    return const <BattleCommandChoiceEntry>[];
  }
  if (mode == BattleCommandMenuMode.continueOnly) {
    return const <BattleCommandChoiceEntry>[];
  }

  if (mode == BattleCommandMenuMode.fight) {
    return List<BattleCommandChoiceEntry>.unmodifiable(
      request.allowedChoices.whereType<PlayerBattleChoiceFight>().map(
            (choice) => _entryForChoice(session, choice),
          ),
    );
  }
  if (mode == BattleCommandMenuMode.pokemon) {
    return List<BattleCommandChoiceEntry>.unmodifiable(
      request.allowedChoices.whereType<PlayerBattleChoiceSwitch>().map(
            (choice) => _entryForChoice(session, choice),
          ),
    );
  }
  return const <BattleCommandChoiceEntry>[];
}

int _choiceColumnsFor({
  required BattleCommandMenuMode mode,
  required int entryCount,
}) {
  if (mode == BattleCommandMenuMode.fight && entryCount > 1) {
    return 2;
  }
  if (mode == BattleCommandMenuMode.pokemon && entryCount > 4) {
    return 2;
  }
  return 1;
}

String _choiceGroupTitleFor(BattleCommandMenuMode mode) {
  return switch (mode) {
    BattleCommandMenuMode.root => 'COMMANDS',
    BattleCommandMenuMode.fight => 'MOVES',
    BattleCommandMenuMode.bag => 'BAG',
    BattleCommandMenuMode.bagMedicineTarget => 'TARGET',
    BattleCommandMenuMode.pokemon => 'POKÉMON',
    BattleCommandMenuMode.continueOnly => 'CONTINUE',
  };
}

BattleCommandChoiceEntry _entryForChoice(
  BattleSession session,
  PlayerBattleChoice choice,
) {
  if (choice is PlayerBattleChoiceFight) {
    final move = session.state.player.moves[choice.moveIndex];
    final moveKind = switch (move.category) {
      BattleMoveCategory.physical => 'Physical',
      BattleMoveCategory.special => 'Special',
      BattleMoveCategory.status => 'Status',
      null => 'Technique',
    };
    final moveType = move.type.toUpperCase();
    final powerLabel =
        move.power > 0 ? 'Power ${move.power}' : 'No direct damage';
    return BattleCommandChoiceEntry(
      choice: choice,
      title: move.name,
      subtitle: '$moveType · $moveKind · $powerLabel',
      tone: switch (move.category) {
        BattleMoveCategory.physical => BattleCommandChoiceTone.attack,
        BattleMoveCategory.special => BattleCommandChoiceTone.special,
        BattleMoveCategory.status || null => BattleCommandChoiceTone.support,
      },
    );
  }
  if (choice is PlayerBattleChoiceSwitch) {
    final reserve = session.state.playerReserve[choice.reserveIndex];
    return BattleCommandChoiceEntry(
      choice: choice,
      title: reserve.speciesId.toUpperCase(),
      subtitle: 'Reserve · ${reserve.currentHp}/${reserve.maxHp} HP',
      tone: BattleCommandChoiceTone.switching,
    );
  }
  if (choice is PlayerBattleChoiceCapture) {
    return const BattleCommandChoiceEntry(
      choice: PlayerBattleChoiceCapture(),
      title: 'Capture',
      subtitle: 'Use the supported capture action',
      tone: BattleCommandChoiceTone.special,
    );
  }
  if (choice is PlayerBattleChoiceRun) {
    return const BattleCommandChoiceEntry(
      choice: PlayerBattleChoiceRun(),
      title: 'Run',
      subtitle: 'Attempt to escape',
      tone: BattleCommandChoiceTone.attack,
    );
  }
  return const BattleCommandChoiceEntry(
    choice: PlayerBattleChoiceContinue(),
    title: 'Continue',
    subtitle: 'Advance the forced step',
    tone: BattleCommandChoiceTone.neutral,
  );
}
