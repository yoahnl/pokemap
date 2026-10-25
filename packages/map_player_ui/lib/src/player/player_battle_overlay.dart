import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';
import '../foundation/player_image.dart';
import '../foundation/player_input_scope.dart';
import '../theme/pokemap_player_battle_theme.dart';
import 'player_battle_scene.dart';
import 'player_control_profile.dart';
import 'player_battle_surface.dart';

export 'player_battle_scene.dart';
export 'player_battle_surface.dart';

final class PlayerBattlePresentationController {
  bool Function(RuntimeInputEvent event)? _handle;

  bool handle(RuntimeInputEvent event) => _handle?.call(event) ?? false;

  void dispose() => _handle = null;
}

class PlayerBattleOverlay extends StatefulWidget {
  const PlayerBattleOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.itemIconBuilder,
    this.display = PlayerBattleDisplay.full,
    this.presentationController,
    this.controlProfile,
    this.controllerFamily = PlayerControllerFamily.unknown,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<BattlePresentationCommand> onCommand;
  final Widget Function(String assetPath)? itemIconBuilder;
  final PlayerBattleDisplay display;
  final PlayerBattlePresentationController? presentationController;
  final PlayerControlProfile? controlProfile;
  final PlayerControllerFamily controllerFamily;

  @override
  State<PlayerBattleOverlay> createState() => _PlayerBattleOverlayState();
}

class _PlayerBattleOverlayState extends State<PlayerBattleOverlay> {
  (BattleCommandPanelPlacement, bool, Size, int, List<int>, int?)?
  _lastRequestedPlacement;
  bool _moveInfoOpen = false;
  Route<void>? _moveInfoRoute;
  final Set<RuntimeInputControl> _pressedControls = {};
  final Set<RuntimeInputControl> _modalControls = {};

  void _dismissMoveInfo({bool afterFrame = false}) {
    final route = _moveInfoRoute;
    _moveInfoRoute = null;
    if (route == null) return;
    void dismiss() {
      if (route.isActive) route.navigator?.removeRoute(route);
    }

    if (afterFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) => dismiss());
    } else {
      dismiss();
    }
  }

  @override
  void initState() {
    super.initState();
    widget.presentationController?._handle = _handlePresentationInput;
  }

  @override
  void didUpdateWidget(covariant PlayerBattleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.mode != widget.snapshot.mode ||
        oldWidget.snapshot.phase != widget.snapshot.phase ||
        !widget.snapshot.interactionsEnabled ||
        widget.display == PlayerBattleDisplay.hudOnly) {
      _dismissMoveInfo(afterFrame: true);
    }
    if (oldWidget.presentationController != widget.presentationController) {
      oldWidget.presentationController?._handle = null;
      widget.presentationController?._handle = _handlePresentationInput;
    }
  }

  @override
  void dispose() {
    widget.presentationController?._handle = null;
    _dismissMoveInfo(afterFrame: true);
    super.dispose();
  }

  bool _handlePresentationInput(RuntimeInputEvent event) {
    if (widget.display == PlayerBattleDisplay.hudOnly) return false;
    if (event.isRelease) {
      _pressedControls.remove(event.control);
      if (_modalControls.remove(event.control)) return true;
    } else if (!event.isRepeat) {
      _pressedControls.add(event.control);
    }
    if (_modalControls.contains(event.control) && !_moveInfoOpen) return true;
    if (_moveInfoOpen) {
      if (event.isPress) _modalControls.add(event.control);
      if (event.isPress &&
          !event.isRepeat &&
          (event.control == RuntimeInputControl.primary ||
              event.control == RuntimeInputControl.secondary ||
              event.control == RuntimeInputControl.menu)) {
        _dismissMoveInfo();
      }
      return true;
    }
    final snapshot = widget.snapshot;
    final moves =
        snapshot.mode == BattleCommandOverlayMode.fight ||
        snapshot.mode == BattleCommandOverlayMode.bagMedicineMoveTarget;
    if (!moves || event.control != RuntimeInputControl.sprint) return false;
    if (event.isPress && !event.isRepeat && snapshot.interactionsEnabled) {
      unawaited(_openMoveInfo());
    }
    return true;
  }

  Future<void> _openMoveInfo() async {
    if (_moveInfoOpen || !widget.snapshot.interactionsEnabled) return;
    final commands = _commands(widget.snapshot, context.playerBattleProfile);
    final selected =
        commands.where((entry) => entry.selected).firstOrNull ??
        commands.firstOrNull;
    if (selected == null || selected.moveTypeId == null) return;
    _moveInfoOpen = true;
    _modalControls.addAll(_pressedControls);
    try {
      await showPlayerBattleMoveInfo(
        context,
        selected,
        onRouteCreated: (route) => _moveInfoRoute = route,
      );
    } finally {
      _moveInfoOpen = false;
      _moveInfoRoute = null;
    }
  }

  String? _inputHint(BuildContext context, RuntimeInputControl control) {
    if (!PlayerInputScope.usesController(context)) return null;
    if (!PlayerInputScope.usesKeyboard(context) &&
        widget.controllerFamily == PlayerControllerFamily.unknown) {
      return null;
    }
    return (widget.controlProfile ?? PlayerControlProfile.standard).promptFor(
      PlayerInputScope.usesKeyboard(context)
          ? PlayerControlDevice.keyboard
          : PlayerControlDevice.gamepad,
      control,
      family: widget.controllerFamily,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _buildOverlay(context, constraints),
  );

  Widget _buildOverlay(BuildContext context, BoxConstraints constraints) {
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
    final panel = switch (snapshot.mode) {
      BattleCommandOverlayMode.fight ||
      BattleCommandOverlayMode.bagMedicineMoveTarget =>
        battle?.moves ?? const ProjectBattlePanelPresentationProfile(),
      BattleCommandOverlayMode.bag ||
      BattleCommandOverlayMode.pokemon ||
      BattleCommandOverlayMode.moveTarget ||
      BattleCommandOverlayMode.bagMedicineTarget =>
        battle?.target ?? const ProjectBattlePanelPresentationProfile(),
      BattleCommandOverlayMode.continueOnly =>
        battle?.message ?? const ProjectBattlePanelPresentationProfile(),
      _ => ProjectBattlePanelPresentationProfile(
        shape: battle?.commandShape ?? ProjectWindowShape.rounded,
        padding: battle?.commandPadding ?? 12,
        surfaceColor: battle?.commandSurfaceColor,
        borderColor: battle?.commandBorderColor,
        textColor: battle?.commandTextColor,
        selectionColor: battle?.commandSelectionColor,
      ),
    };
    final compactChrome =
        panel.layout == ProjectBattleCommandLayout.grid &&
        panel.columns == 2 &&
        panel.shape == ProjectWindowShape.rounded &&
        panel.padding == 12 &&
        panel.surfaceColor == null &&
        panel.borderColor == null &&
        panel.textColor == null &&
        panel.selectionColor == null;
    var placement = snapshot.commandPanelPlacement;
    var controllerLayout = snapshot.controllerLayout;
    if (display != PlayerBattleDisplay.commandsOnly) {
      final padding = MediaQuery.paddingOf(context);
      final supportsSidePanel =
          snapshot.viewportSize.width - padding.horizontal >= 700 &&
          snapshot.viewportSize.height - padding.vertical >= 320;
      final collection = switch (snapshot.mode) {
        BattleCommandOverlayMode.bag ||
        BattleCommandOverlayMode.pokemon ||
        BattleCommandOverlayMode.bagMedicineTarget ||
        BattleCommandOverlayMode.moveTarget ||
        BattleCommandOverlayMode.decision => true,
        _ => false,
      };
      final landscape =
          snapshot.viewportSize.width > snapshot.viewportSize.height;
      placement = display == PlayerBattleDisplay.hudOnly
          ? BattleCommandPanelPlacement.detached
          : landscape &&
                (collection ||
                    canonical &&
                        PlayerInputScope.usesController(context) &&
                        supportsSidePanel)
          ? BattleCommandPanelPlacement.end
          : BattleCommandPanelPlacement.bottom;
      controllerLayout =
          canonical &&
          compactChrome &&
          display == PlayerBattleDisplay.full &&
          PlayerInputScope.usesController(context);
    }
    final rootCommandOrder =
        snapshot.mode == BattleCommandOverlayMode.root &&
            display != PlayerBattleDisplay.hudOnly
        ? _commands(snapshot, battle).map((entry) => entry.index).toList()
        : snapshot.rootCommandOrder;
    final collectionMode = switch (snapshot.mode) {
      BattleCommandOverlayMode.bag ||
      BattleCommandOverlayMode.pokemon ||
      BattleCommandOverlayMode.bagMedicineTarget => true,
      _ => false,
    };
    final companion = display == PlayerBattleDisplay.commandsOnly;
    final portrait = companion
        ? constraints.maxHeight > constraints.maxWidth
        : snapshot.viewportSize.height > snapshot.viewportSize.width;
    final collectionPadding = playerBattleCollectionPadding(
      portrait: portrait,
      companion: companion,
      bottomSafePadding: MediaQuery.paddingOf(context).bottom,
    );
    final collectionColumns =
        collectionMode && display != PlayerBattleDisplay.hudOnly
        ? canonical && compactChrome
              ? playerBattleCollectionColumns(
                  portrait: portrait,
                  companion: companion,
                  bag: snapshot.mode == BattleCommandOverlayMode.bag,
                  contentWidth:
                      (companion
                          ? constraints.maxWidth -
                                playerBattleCompanionInsets(
                                  MediaQuery.paddingOf(context),
                                ).horizontal
                          : snapshot.panelRect.width) -
                      collectionPadding.horizontal,
                )
              : null
        : snapshot.collectionColumns;
    final request = (
      placement,
      controllerLayout,
      snapshot.viewportSize,
      snapshot.revision,
      rootCommandOrder,
      collectionColumns,
    );
    final acknowledged =
        snapshot.commandPanelPlacement == placement &&
        snapshot.controllerLayout == controllerLayout &&
        listEquals(snapshot.rootCommandOrder, rootCommandOrder) &&
        snapshot.collectionColumns == collectionColumns;
    final previous = _lastRequestedPlacement;
    final alreadyRequested =
        previous != null &&
        previous.$1 == request.$1 &&
        previous.$2 == request.$2 &&
        previous.$3 == request.$3 &&
        previous.$4 == request.$4 &&
        listEquals(previous.$5, request.$5) &&
        previous.$6 == request.$6;
    if (acknowledged) _lastRequestedPlacement = null;
    if (!acknowledged && !alreadyRequested) {
      _lastRequestedPlacement = request;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.snapshot.revision != snapshot.revision) return;
        onCommand(
          BattleSetCommandPanelPlacementCommand(
            snapshotRevision: snapshot.revision,
            expectedMode: snapshot.mode,
            placement: placement,
            controllerLayout: controllerLayout,
            rootCommandOrder: rootCommandOrder,
            collectionColumns: collectionColumns,
          ),
        );
      });
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
        isDecision: snapshot.mode == BattleCommandOverlayMode.decision,
        collectionIdentity: snapshot.mode.name,
        onMoveInfo: () => unawaited(_openMoveInfo()),
        moveInfoInputHint: _inputHint(context, RuntimeInputControl.sprint),
        backInputHint: _inputHint(context, RuntimeInputControl.secondary),
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
  if (snapshot.mode != BattleCommandOverlayMode.root) {
    return snapshot.entries.map(mapEntry).toList(growable: false);
  }
  if (profile?.commands == null) {
    final entries = snapshot.entries.map(mapEntry).toList();
    const order = [0, 2, 1, 3];
    entries.sort(
      (a, b) => order.indexOf(a.index).compareTo(order.indexOf(b.index)),
    );
    return entries;
  }
  final byId = <ProjectBattleCommandId, BattleCommandOverlayEntry>{};
  for (final entry in snapshot.entries) {
    if (entry.kind != BattleCommandOverlayEntryKind.root) continue;
    final id = _commandIdForRuntimeIndex(entry.index);
    if (id != null) byId[id] = entry;
  }
  return <PlayerBattleCommandViewData>[
    for (final authored in profile!.effectiveCommands)
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
  if (snapshot.phase == BattlePresentationPhase.presentingTurn ||
      snapshot.mode == BattleCommandOverlayMode.continueOnly) {
    return PlayerBattlePanelKind.message;
  }
  return switch (snapshot.mode) {
    // La décision post-combat rend ses choix comme des commandes, mais sous
    // son propre mode : le remapping de personnalisation ne s'applique qu'au
    // mode root et laisse les libellés « Apprendre » / « Ne pas apprendre »
    // intacts.
    BattleCommandOverlayMode.root ||
    BattleCommandOverlayMode.decision => PlayerBattlePanelKind.commands,
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
