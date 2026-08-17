import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';
import '../theme/pokemap_player_battle_theme.dart';
import 'player_battle_scene.dart';
import 'player_battle_surface.dart';

export 'player_battle_scene.dart';
export 'player_battle_surface.dart';

class PlayerBattleOverlay extends StatelessWidget {
  const PlayerBattleOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.itemIconBuilder,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<BattlePresentationCommand> onCommand;
  final Widget Function(String assetPath)? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    final battle = context.playerBattleProfile;
    return PlayerBattleScene(
      data: PlayerBattleViewData(
        revision: snapshot.revision,
        enemy: _hud(snapshot.enemyHud),
        player: _hud(snapshot.playerHud),
        viewportLayout: PlayerBattleViewportLayout(
          viewportSize: snapshot.viewportSize,
          panelRect: snapshot.panelRect,
          enemyHudRect: snapshot.enemyHud.rect,
          playerHudRect: snapshot.playerHud.rect,
        ),
        battleLabel: snapshot.battleLabel,
        title: _localizedBattleTitle(context.playerL10n, snapshot.mode),
        prompt: snapshot.prompt,
        narrationLines: snapshot.narrationLines,
        commands: _commands(snapshot, battle),
        interactionsEnabled: snapshot.interactionsEnabled,
        canGoBack: snapshot.canGoBack,
        forcedReplacement: snapshot.forcedReplacement,
        panelKind: _panelKind(snapshot),
      ),
      onAction: (action) => onCommand(
        switch (action) {
          PlayerBattleBackAction() => BattleBackCommand(
              snapshotRevision: action.snapshotRevision,
              expectedMode: snapshot.mode,
            ),
          PlayerBattleSelectEntryAction(:final entryIndex) =>
            BattleSelectEntryCommand(
              snapshotRevision: action.snapshotRevision,
              expectedMode: snapshot.mode,
              entryIndex: entryIndex,
            ),
        },
      ),
      itemIconBuilder: itemIconBuilder ??
          (assetPath) => BattleMobileItemIcon(imagePath: assetPath),
    );
  }
}

String _localizedBattleTitle(
  PokeMapPlayerLocalizations localizations,
  BattleCommandOverlayMode mode,
) =>
    switch (mode) {
      BattleCommandOverlayMode.root => localizations.battleCommands,
      BattleCommandOverlayMode.fight => localizations.battleMoves,
      BattleCommandOverlayMode.bag => localizations.battleBag,
      BattleCommandOverlayMode.bagMedicineTarget => localizations.battleTarget,
      BattleCommandOverlayMode.pokemon => localizations.battlePokemon,
      BattleCommandOverlayMode.continueOnly => localizations.battleContinue,
    };

List<PlayerBattleCommandViewData> _commands(
  BattleCommandOverlaySnapshot snapshot,
  ProjectBattlePresentationProfile? profile,
) {
  PlayerBattleCommandViewData mapEntry(
    BattleCommandOverlayEntry entry, {
    ProjectBattleCommandProfile? authored,
  }) =>
      PlayerBattleCommandViewData(
        index: entry.index,
        primaryLabel: authored?.label ?? entry.primaryLabel,
        secondaryLabel: entry.secondaryLabel,
        tertiaryLabel: entry.tertiaryLabel,
        trailingLabel: entry.trailingLabel,
        statusLabel: entry.statusLabel,
        moveTypeId: entry.kind == BattleCommandOverlayEntryKind.move &&
                entry.secondaryLabel.trim().isNotEmpty
            ? entry.secondaryLabel
            : null,
        isBagItem: entry.kind == BattleCommandOverlayEntryKind.bag,
        enabled: entry.enabled,
        selected: entry.selected,
        tone: _tone(entry.tone),
        iconAssetPath: entry.iconAssetPath,
        commandId: authored?.id ??
            (entry.kind == BattleCommandOverlayEntryKind.root
                ? _commandIdForRuntimeIndex(entry.index)
                : null),
        commandIcon: authored?.icon,
      );
  if (snapshot.mode != BattleCommandOverlayMode.root || profile == null) {
    return snapshot.entries.map(mapEntry).toList(growable: false);
  }
  final byId = <ProjectBattleCommandId, BattleCommandOverlayEntry>{};
  for (final entry in snapshot.entries) {
    if (entry.kind != BattleCommandOverlayEntryKind.root) continue;
    final id = _commandIdForRuntimeIndex(entry.index);
    if (id != null) byId[id] = entry;
  }
  return <PlayerBattleCommandViewData>[
    for (final authored in profile.effectiveCommands)
      if (byId[authored.id] case final entry?)
        mapEntry(entry, authored: authored),
  ];
}

ProjectBattleCommandId? _commandIdForRuntimeIndex(int index) => switch (index) {
      0 => ProjectBattleCommandId.fight,
      1 => ProjectBattleCommandId.bag,
      2 => ProjectBattleCommandId.party,
      3 => ProjectBattleCommandId.run,
      _ => null,
    };

PlayerBattlePanelKind _panelKind(BattleCommandOverlaySnapshot snapshot) {
  if (snapshot.phase != BattlePresentationPhase.choosingCommand ||
      snapshot.mode == BattleCommandOverlayMode.continueOnly) {
    return PlayerBattlePanelKind.message;
  }
  return switch (snapshot.mode) {
    BattleCommandOverlayMode.root => PlayerBattlePanelKind.commands,
    BattleCommandOverlayMode.fight => PlayerBattlePanelKind.moves,
    BattleCommandOverlayMode.bagMedicineTarget => PlayerBattlePanelKind.target,
    BattleCommandOverlayMode.bag ||
    BattleCommandOverlayMode.pokemon =>
      PlayerBattlePanelKind.target,
    BattleCommandOverlayMode.continueOnly => PlayerBattlePanelKind.message,
  };
}

PlayerBattleHudViewData _hud(BattleCommandOverlayHudSnapshot snapshot) =>
    PlayerBattleHudViewData(
      ownerLabel: snapshot.ownerLabel,
      speciesLabel: snapshot.speciesLabel,
      level: snapshot.level,
      currentHp: snapshot.currentHp,
      maxHp: snapshot.maxHp,
      displayedHp: snapshot.displayedHp,
      targetDisplayedHp: snapshot.targetDisplayedHp,
      hpTweenDuration: snapshot.hpTweenDuration,
      hpTweenRevision: snapshot.hpTweenRevision,
      statusLabel: snapshot.statusLabel,
      genderSymbol: snapshot.genderSymbol,
      experienceProgress: snapshot.experienceProgress,
    );

PlayerBattleEntryTone _tone(BattleCommandOverlayEntryTone tone) =>
    switch (tone) {
      BattleCommandOverlayEntryTone.neutral => PlayerBattleEntryTone.neutral,
      BattleCommandOverlayEntryTone.attack => PlayerBattleEntryTone.attack,
      BattleCommandOverlayEntryTone.special => PlayerBattleEntryTone.special,
      BattleCommandOverlayEntryTone.support => PlayerBattleEntryTone.support,
      BattleCommandOverlayEntryTone.switching =>
        PlayerBattleEntryTone.switching,
      BattleCommandOverlayEntryTone.medicine => PlayerBattleEntryTone.medicine,
      BattleCommandOverlayEntryTone.capture => PlayerBattleEntryTone.capture,
      BattleCommandOverlayEntryTone.disabled => PlayerBattleEntryTone.disabled,
    };
