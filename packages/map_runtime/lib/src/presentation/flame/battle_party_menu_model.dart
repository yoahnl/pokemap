import 'package:map_battle/map_battle.dart';

enum BattlePartyMenuMode {
  voluntarySwitch,
  forcedReplacement,
  unavailable,
}

enum BattlePartyMenuDisabledReason {
  activePokemon,
  fainted,
  notAllowedByCurrentRequest,
  noSwitchAvailable,
}

class BattlePartyMenuEntry {
  const BattlePartyMenuEntry({
    required this.visualIndex,
    required this.reserveIndex,
    required this.speciesId,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.isActive,
    required this.isFainted,
    required this.isSelectable,
    required this.disabledReason,
    required this.playerChoice,
  });

  final int visualIndex;
  final int? reserveIndex;
  final String speciesId;
  final int level;
  final int currentHp;
  final int maxHp;
  final bool isActive;
  final bool isFainted;
  final bool isSelectable;
  final BattlePartyMenuDisabledReason? disabledReason;
  final PlayerBattleChoiceSwitch? playerChoice;
}

class BattlePartyMenuModel {
  const BattlePartyMenuModel({
    required this.mode,
    required this.activeEntry,
    required this.reserveEntries,
    required this.allEntries,
  });

  final BattlePartyMenuMode mode;
  final BattlePartyMenuEntry activeEntry;
  final List<BattlePartyMenuEntry> reserveEntries;
  final List<BattlePartyMenuEntry> allEntries;

  bool get hasSelectableEntries =>
      allEntries.any((entry) => entry.isSelectable);
}

BattlePartyMenuModel buildBattlePartyMenuModel({
  required BattleSession session,
}) {
  final request = session.decisionRequest;
  final mode = _modeForRequest(request);
  final allowedSwitchChoices = <int, PlayerBattleChoiceSwitch>{
    for (final choice
        in request.allowedChoices.whereType<PlayerBattleChoiceSwitch>())
      choice.reserveIndex: choice,
  };

  final activeEntry = BattlePartyMenuEntry(
    visualIndex: 0,
    reserveIndex: null,
    speciesId: session.state.player.speciesId,
    level: session.state.player.level,
    currentHp: session.state.player.currentHp,
    maxHp: session.state.player.maxHp,
    isActive: true,
    isFainted: session.state.player.isFainted,
    isSelectable: false,
    disabledReason: BattlePartyMenuDisabledReason.activePokemon,
    playerChoice: null,
  );

  final reserveEntries = <BattlePartyMenuEntry>[
    for (var index = 0; index < session.state.playerReserve.length; index++)
      _buildReserveEntry(
        visualIndex: index + 1,
        reserveIndex: index,
        combatant: session.state.playerReserve[index],
        mode: mode,
        allowedSwitchChoice: allowedSwitchChoices[index],
      ),
  ];

  return BattlePartyMenuModel(
    mode: mode,
    activeEntry: activeEntry,
    reserveEntries: List<BattlePartyMenuEntry>.unmodifiable(reserveEntries),
    allEntries: List<BattlePartyMenuEntry>.unmodifiable(
      <BattlePartyMenuEntry>[activeEntry, ...reserveEntries],
    ),
  );
}

BattlePartyMenuEntry _buildReserveEntry({
  required int visualIndex,
  required int reserveIndex,
  required BattleCombatant combatant,
  required BattlePartyMenuMode mode,
  required PlayerBattleChoiceSwitch? allowedSwitchChoice,
}) {
  final isSelectable = allowedSwitchChoice != null;
  return BattlePartyMenuEntry(
    visualIndex: visualIndex,
    reserveIndex: reserveIndex,
    speciesId: combatant.speciesId,
    level: combatant.level,
    currentHp: combatant.currentHp,
    maxHp: combatant.maxHp,
    isActive: false,
    isFainted: combatant.isFainted,
    isSelectable: isSelectable,
    disabledReason: isSelectable
        ? null
        : _disabledReasonForReserve(
            combatant: combatant,
            mode: mode,
          ),
    playerChoice: allowedSwitchChoice,
  );
}

BattlePartyMenuDisabledReason _disabledReasonForReserve({
  required BattleCombatant combatant,
  required BattlePartyMenuMode mode,
}) {
  if (combatant.isFainted) {
    return BattlePartyMenuDisabledReason.fainted;
  }
  return switch (mode) {
    BattlePartyMenuMode.unavailable =>
      BattlePartyMenuDisabledReason.notAllowedByCurrentRequest,
    BattlePartyMenuMode.voluntarySwitch ||
    BattlePartyMenuMode.forcedReplacement =>
      BattlePartyMenuDisabledReason.notAllowedByCurrentRequest,
  };
}

BattlePartyMenuMode _modeForRequest(BattleDecisionRequest request) {
  if (request is BattleForcedReplacementRequest) {
    return request.switchChoices.isEmpty
        ? BattlePartyMenuMode.unavailable
        : BattlePartyMenuMode.forcedReplacement;
  }
  if (request is BattleTurnChoiceRequest) {
    return request.switchChoices.isEmpty
        ? BattlePartyMenuMode.unavailable
        : BattlePartyMenuMode.voluntarySwitch;
  }
  return BattlePartyMenuMode.unavailable;
}
