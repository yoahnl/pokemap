import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';
import '../foundation/player_image.dart';
import '../foundation/player_input_scope.dart';
import '../theme/pokemap_player_battle_theme.dart';
import 'player_battle_scene.dart';
import 'player_battle_surface.dart';

export 'player_battle_scene.dart';
export 'player_battle_surface.dart';

class PlayerBattleOverlay extends StatefulWidget {
  const PlayerBattleOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.itemIconBuilder,
    this.display = PlayerBattleDisplay.full,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<BattlePresentationCommand> onCommand;
  final Widget Function(String assetPath)? itemIconBuilder;
  final PlayerBattleDisplay display;

  @override
  State<PlayerBattleOverlay> createState() => _PlayerBattleOverlayState();
}

class _PlayerBattleOverlayState extends State<PlayerBattleOverlay> {
  (BattleCommandPanelPlacement, bool, Size, int)? _lastRequestedPlacement;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final onCommand = widget.onCommand;
    final display = widget.display;
    final itemIconBuilder = widget.itemIconBuilder;
    final battle = context.playerBattleProfile;
    final canonical =
        battle == null ||
        (battle.commandLayout == ProjectBattleCommandLayout.grid &&
            battle.commandColumns == 2 &&
            battle.enemyHudPosition == ProjectBattleHudPosition.topStart &&
            battle.playerHudPosition == ProjectBattleHudPosition.bottomEnd);
    if (display != PlayerBattleDisplay.commandsOnly) {
      final padding = MediaQuery.paddingOf(context);
      final supportsSidePanel =
          snapshot.viewportSize.width - padding.horizontal >= 700 &&
          snapshot.viewportSize.height - padding.vertical >= 320;
      final placement = display == PlayerBattleDisplay.hudOnly
          ? BattleCommandPanelPlacement.detached
          : canonical &&
                PlayerInputScope.usesController(context) &&
                supportsSidePanel &&
                snapshot.viewportSize.width > snapshot.viewportSize.height
          ? BattleCommandPanelPlacement.end
          : BattleCommandPanelPlacement.bottom;
      final controllerLayout =
          canonical &&
          display == PlayerBattleDisplay.full &&
          PlayerInputScope.usesController(context);
      final request = (
        placement,
        controllerLayout,
        snapshot.viewportSize,
        snapshot.revision,
      );
      if (snapshot.commandPanelPlacement == placement &&
          snapshot.controllerLayout == controllerLayout) {
        _lastRequestedPlacement = null;
      }
      if ((snapshot.commandPanelPlacement != placement ||
              snapshot.controllerLayout != controllerLayout) &&
          _lastRequestedPlacement != request) {
        _lastRequestedPlacement = request;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || widget.snapshot.revision != snapshot.revision) {
            return;
          }
          onCommand(
            BattleSetCommandPanelPlacementCommand(
              snapshotRevision: snapshot.revision,
              expectedMode: snapshot.mode,
              placement: placement,
              controllerLayout: controllerLayout,
            ),
          );
        });
      }
    }

    return PlayerBattleScene(
      display: display,
      data: PlayerBattleViewData(
        revision: snapshot.revision,
        enemy: _hud(snapshot.enemyHud),
        player: _hud(snapshot.playerHud),
        additionalHuds: [
          for (final hud in snapshot.additionalHuds)
            PlayerBattleAdditionalHud(
              identity:
                  'battle-hud-${hud.effectiveSlot.side.name}-${hud.effectiveSlot.slotIndex}-${hud.combatantId}',
              rect: hud.rect,
              data: _hud(hud),
              isPlayerSide: hud.isPlayerSide,
            ),
        ],
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
      onAction: (action) => onCommand(switch (action) {
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
      }),
      itemIconBuilder:
          itemIconBuilder ??
          (assetPath) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: PlayerFileImage(
              path: assetPath,
              width: 32,
              height: 32,
              fallback: const Icon(Icons.inventory_2_outlined, size: 18),
            ),
          ),
    );
  }
}

String _localizedBattleTitle(
  PokeMapPlayerLocalizations localizations,
  BattleCommandOverlayMode mode,
) => switch (mode) {
  BattleCommandOverlayMode.root => localizations.battleCommands,
  BattleCommandOverlayMode.fight ||
  BattleCommandOverlayMode.bagMedicineMoveTarget => localizations.battleMoves,
  BattleCommandOverlayMode.bag => localizations.battleBag,
  BattleCommandOverlayMode.bagMedicineTarget => localizations.battleTarget,
  BattleCommandOverlayMode.moveTarget => localizations.battleTarget,
  BattleCommandOverlayMode.pokemon => localizations.battlePokemon,
  BattleCommandOverlayMode.continueOnly => localizations.battleContinue,
  BattleCommandOverlayMode.decision => localizations.battleDecision,
};

List<PlayerBattleCommandViewData> _commands(
  BattleCommandOverlaySnapshot snapshot,
  ProjectBattlePresentationProfile? profile,
) {
  PlayerBattleCommandViewData mapEntry(
    BattleCommandOverlayEntry entry, {
    ProjectBattleCommandProfile? authored,
  }) => PlayerBattleCommandViewData(
    index: entry.index,
    primaryLabel: authored?.label ?? entry.primaryLabel,
    secondaryLabel: entry.secondaryLabel,
    tertiaryLabel: entry.tertiaryLabel,
    trailingLabel: entry.trailingLabel,
    statusLabel: entry.statusLabel,
    moveTypeId:
        entry.kind == BattleCommandOverlayEntryKind.move &&
            entry.secondaryLabel.trim().isNotEmpty
        ? entry.secondaryLabel
        : null,
    isBagItem: entry.kind == BattleCommandOverlayEntryKind.bag,
    enabled: entry.enabled,
    selected: entry.selected,
    tone: _tone(entry.tone),
    iconAssetPath: entry.iconAssetPath,
    commandId:
        authored?.id ??
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
    // La décision post-combat rend ses choix comme des commandes, mais sous
    // son propre mode : le remapping de personnalisation ne s'applique qu'au
    // mode root et laisse les libellés « Apprendre » / « Ne pas apprendre »
    // intacts.
    BattleCommandOverlayMode.root => PlayerBattlePanelKind.commands,
    BattleCommandOverlayMode.decision => PlayerBattlePanelKind.decision,
    BattleCommandOverlayMode.fight ||
    BattleCommandOverlayMode.bagMedicineMoveTarget =>
      PlayerBattlePanelKind.moves,
    BattleCommandOverlayMode.bagMedicineTarget => PlayerBattlePanelKind.target,
    BattleCommandOverlayMode.moveTarget => PlayerBattlePanelKind.target,
    BattleCommandOverlayMode.bag ||
    BattleCommandOverlayMode.pokemon => PlayerBattlePanelKind.target,
    BattleCommandOverlayMode.continueOnly => PlayerBattlePanelKind.message,
  };
}

PlayerBattleHudViewData _hud(BattleCommandOverlayHudSnapshot snapshot) =>
    PlayerBattleHudViewData(
      isRevealed: snapshot.isRevealed,
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
      experienceProgressTarget: snapshot.experienceProgressTarget,
      xpTweenDuration: snapshot.xpTweenDuration,
      xpTweenRevision: snapshot.xpTweenRevision,
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
