import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:map_battle/map_battle.dart';

import '../flutter/battle_command_overlay_snapshot.dart'
    show BattleCommandPanelPlacement, BattleCommandOverlayMode;

final class BattleCombatantSceneGeometry {
  const BattleCombatantSceneGeometry({
    required this.spriteRect,
    required this.platformRect,
    required this.footAnchor,
    required this.hudRect,
  });

  final Rect spriteRect;
  final Rect platformRect;
  final Offset footAnchor;
  final Rect hudRect;
}

/// Bornes de l'échelle de texte de combat.
///
/// En dessous, les libellés deviennent illisibles ; au-dessus, l'ellipse du
/// cache de peinture les tronque, ce qui échoue proprement mais n'aide personne.
/// Borner vaut mieux que laisser une valeur absurde traverser tout le rendu.
///
/// Déclarées ici parce que le panneau de commande ET la scène les lisent, et que
/// ce fichier est le contrat de composition que les deux importent déjà.
const double battleMinimumTextScale = 0.8;
const double battleMaximumTextScale = 1.6;

enum BattleCommandPanelLayoutMode { split, stacked }

enum BattleViewportClass { compactPortrait, mediumLandscape, wideDesktop }

/// Contrat pur de composition de la battle scene.
///
/// Ce modèle reste volontairement indépendant de Flame :
/// - il transforme seulement un viewport en rectangles/anchors explicites ;
/// - il évite que le staging dépende d'offsets répartis entre plusieurs
///   composants ;
/// - il borne la taille perçue des battlers en wide desktop via un scale
///   plafonné à `1.0`.
final class BattleSceneLayout {
  BattleSceneLayout._({
    required this.viewportSize,
    required this.safePadding,
    required this.viewportClass,
    required this.isPortrait,
    required this.portraitSafeMargin,
    required this.sceneRect,
    required this.arenaRect,
    required this.commandPanelPlacement,
    required this.commandPanelMode,
    required this.controllerLayout,
    required this.portraitTouchLayout,
    required this.stageRect,
    required this.commandPanelRect,
    required this.enemyHudRect,
    required this.playerHudRect,
    required this.enemySpriteRect,
    required this.playerSpriteRect,
    required this.enemyPlatformRect,
    required this.playerPlatformRect,
    required this.enemyFootAnchor,
    required this.playerFootAnchor,
    required this.commandPanelLayoutMode,
    required this.scale,
  });

  final Size viewportSize;
  final EdgeInsets safePadding;
  final BattleViewportClass viewportClass;
  final bool isPortrait;
  final double portraitSafeMargin;
  final Rect sceneRect;
  final Rect arenaRect;
  final BattleCommandPanelPlacement commandPanelPlacement;
  final BattleCommandOverlayMode commandPanelMode;
  final bool controllerLayout;
  final bool portraitTouchLayout;
  final Rect stageRect;
  final Rect commandPanelRect;
  final Rect enemyHudRect;
  final Rect playerHudRect;
  final Rect enemySpriteRect;
  final Rect playerSpriteRect;
  final Rect enemyPlatformRect;
  final Rect playerPlatformRect;
  final Offset enemyFootAnchor;
  final Offset playerFootAnchor;
  final BattleCommandPanelLayoutMode commandPanelLayoutMode;
  final double scale;

  Rect? get backdropArtworkRect =>
      commandPanelPlacement != BattleCommandPanelPlacement.detached &&
          isPortrait &&
          switch (commandPanelMode) {
            BattleCommandOverlayMode.bag ||
            BattleCommandOverlayMode.pokemon ||
            BattleCommandOverlayMode.bagMedicineTarget ||
            BattleCommandOverlayMode.moveTarget ||
            BattleCommandOverlayMode.decision => true,
            _ => false,
          }
      ? arenaRect
      : null;

  Rect get enemyCombatantBoundsRect =>
      enemySpriteRect.expandToInclude(enemyPlatformRect);

  Rect get playerCombatantBoundsRect =>
      playerSpriteRect.expandToInclude(playerPlatformRect);

  BattleCombatantSceneGeometry combatantGeometry(
    BattleSlotRef slot, {
    bool doubles = false,
  }) {
    final player = slot.side == BattleSideId.player;
    if (!doubles) {
      return BattleCombatantSceneGeometry(
        spriteRect: player ? playerSpriteRect : enemySpriteRect,
        platformRect: player ? playerPlatformRect : enemyPlatformRect,
        footAnchor: player ? playerFootAnchor : enemyFootAnchor,
        hudRect: player ? playerHudRect : enemyHudRect,
      );
    }
    if (slot.slotIndex < 0 || slot.slotIndex > 1) {
      throw ArgumentError.value(slot, 'slot');
    }
    final field = Rect.fromLTRB(
      math.max(arenaRect.left + 8, safePadding.left),
      math.max(arenaRect.top + 8, safePadding.top),
      math.min(arenaRect.right - 8, viewportSize.width - safePadding.right),
      math.min(
        (commandPanelPlacement != BattleCommandPanelPlacement.bottom
                ? arenaRect.bottom
                : commandPanelRect.top) -
            8,
        viewportSize.height - safePadding.bottom,
      ),
    );
    const hudHeight = 64.0;
    final hudWidth = math.min(field.width * 0.46, 198.0);
    final hudTop = player
        ? field.bottom - (2 - slot.slotIndex) * (hudHeight + 4)
        : field.top + slot.slotIndex * (hudHeight + 4);
    final spriteWidth = math.min(field.width * 0.22, player ? 144.0 : 112.0);
    final spriteHeight = math.min(field.height * 0.28, player ? 148.0 : 116.0);
    final footXRatio = player ? .68 : .5;
    final platformWidth = spriteWidth * 1.1;
    final platformHeight = spriteHeight * .16;
    final requestedFootX =
        field.left +
        field.width *
            (player
                ? (slot.slotIndex == 0 ? 0.14 : 0.34)
                : (slot.slotIndex == 0 ? 0.68 : 0.84));
    final footX = requestedFootX
        .clamp(
          field.left + math.max(spriteWidth * footXRatio, platformWidth / 2),
          field.right -
              math.max(spriteWidth * (1 - footXRatio), platformWidth / 2),
        )
        .toDouble();
    final requestedFootY =
        field.top +
        field.height *
            (player
                ? (slot.slotIndex == 0 ? 0.68 : 0.94)
                : (slot.slotIndex == 0 ? 0.34 : 0.52));
    final crossesOppositeHuds = player
        ? footX - spriteWidth * footXRatio < field.left + hudWidth
        : footX + spriteWidth * (1 - footXRatio) > field.right - hudWidth;
    final unobstructedFootY = !crossesOppositeHuds
        ? requestedFootY
        : player
        ? math.max(requestedFootY, field.top + 2 * hudHeight + 8 + spriteHeight)
        : math.min(requestedFootY, field.bottom - 2 * (hudHeight + 4) - 4);
    final footY = unobstructedFootY
        .clamp(field.top + spriteHeight, field.bottom - platformHeight / 2)
        .toDouble();
    final foot = Offset(footX, footY);
    return BattleCombatantSceneGeometry(
      spriteRect: Rect.fromLTWH(
        foot.dx - spriteWidth * footXRatio,
        foot.dy - spriteHeight,
        spriteWidth,
        spriteHeight,
      ),
      platformRect: Rect.fromCenter(
        center: foot,
        width: platformWidth,
        height: platformHeight,
      ),
      footAnchor: foot,
      hudRect: Rect.fromLTWH(
        player ? field.right - hudWidth : field.left,
        hudTop,
        hudWidth,
        hudHeight,
      ),
    );
  }

  factory BattleSceneLayout.forViewport({
    required Size viewportSize,
    EdgeInsets safePadding = EdgeInsets.zero,
    double textScale = 1.0,
    BattleCommandOverlayMode commandPanelMode = BattleCommandOverlayMode.fight,
    bool controllerLayout = false,
    bool portraitTouchLayout = false,
    BattleCommandPanelPlacement commandPanelPlacement =
        BattleCommandPanelPlacement.bottom,
  }) {
    final viewportClass = classifyViewport(
      viewportSize: viewportSize,
      safePadding: safePadding,
    );
    final isPortrait = viewportSize.height > viewportSize.width;
    final viewportRect = Rect.fromLTWH(
      safePadding.left,
      safePadding.top,
      math.max(0, viewportSize.width - safePadding.horizontal),
      math.max(0, viewportSize.height - safePadding.vertical),
    );
    final sidePanel =
        commandPanelPlacement == BattleCommandPanelPlacement.end &&
        !isPortrait &&
        viewportRect.width >= 700 &&
        viewportRect.height >= 320;
    final detached =
        commandPanelPlacement == BattleCommandPanelPlacement.detached;
    final effectivePlacement = detached
        ? BattleCommandPanelPlacement.detached
        : sidePanel
        ? BattleCommandPanelPlacement.end
        : BattleCommandPanelPlacement.bottom;
    if (commandPanelMode == BattleCommandOverlayMode.decision && !detached) {
      final base = BattleSceneLayout.forViewport(
        viewportSize: viewportSize,
        safePadding: safePadding,
        textScale: textScale,
        commandPanelMode: BattleCommandOverlayMode.fight,
        controllerLayout: controllerLayout,
        portraitTouchLayout: portraitTouchLayout,
        commandPanelPlacement: isPortrait
            ? BattleCommandPanelPlacement.bottom
            : BattleCommandPanelPlacement.end,
      );
      final panelWidth = math.min(400.0, viewportRect.width * .6);
      final panel = isPortrait
          ? Rect.fromLTRB(
              0,
              viewportSize.height - math.min(380, viewportSize.height * .6),
              viewportSize.width,
              viewportSize.height,
            )
          : Rect.fromLTRB(
              viewportSize.width - math.max(44, safePadding.right) - panelWidth,
              math.max(20, safePadding.top),
              viewportSize.width - math.max(44, safePadding.right),
              viewportSize.height - math.max(20, safePadding.bottom),
            );
      final arena = isPortrait
          ? Rect.fromLTRB(0, 0, viewportSize.width, panel.top)
          : Rect.fromLTRB(0, 0, panel.left, viewportSize.height);
      final scale = math.min(
        base.scale,
        isPortrait ? arena.height / 464 : arena.width / 400,
      );
      final playerSize = Size(
        (isPortrait ? 147 : 148) * scale,
        (isPortrait ? 137 : 134) * scale,
      );
      final playerBottom = isPortrait
          ? arena.bottom - 102 * scale
          : viewportSize.height - 77 * scale;
      final playerSprite = Rect.fromLTWH(
        (isPortrait ? 28 : 169) * scale,
        playerBottom - playerSize.height,
        playerSize.width,
        playerSize.height,
      );
      final enemySize = Size(
        (isPortrait ? 98.7 : 86.3) * scale,
        (isPortrait ? 109.3 : 95.7) * scale,
      );
      final enemyBottom = isPortrait
          ? arena.bottom - 168 * scale
          : viewportSize.height - 160 * scale;
      final enemySprite = Rect.fromLTWH(
        viewportSize.width - (isPortrait ? 136 : 498) * scale,
        math.max(safePadding.top, enemyBottom - enemySize.height),
        enemySize.width,
        enemySize.height,
      );
      final playerFoot = Offset(
        playerSprite.left + playerSprite.width * .68,
        playerSprite.bottom,
      );
      final enemyFoot = Offset(enemySprite.center.dx, enemySprite.bottom);
      final enemyHud = Rect.fromLTWH(
        math.max(20 * scale, safePadding.left),
        math.max((isPortrait ? 48 : 30) * scale, safePadding.top),
        (isPortrait ? 216 : 264) * scale,
        40.5 * scale,
      );
      final playerHud = Rect.fromLTWH(
        isPortrait
            ? viewportSize.width - math.max(14, safePadding.right) - 218 * scale
            : math.max(20 * scale, safePadding.left),
        (isPortrait
                ? arena.bottom - 18
                : viewportSize.height - math.max(16, safePadding.bottom)) -
            68.25 * scale,
        (isPortrait ? 218 : 236) * scale,
        68.25 * scale,
      );
      return BattleSceneLayout._(
        viewportSize: viewportSize,
        safePadding: safePadding,
        viewportClass: viewportClass,
        isPortrait: isPortrait,
        portraitSafeMargin: isPortrait ? 14 : 0,
        sceneRect: Offset.zero & viewportSize,
        arenaRect: arena,
        commandPanelPlacement: isPortrait
            ? BattleCommandPanelPlacement.bottom
            : BattleCommandPanelPlacement.end,
        commandPanelMode: commandPanelMode,
        controllerLayout: controllerLayout,
        portraitTouchLayout: portraitTouchLayout,
        stageRect: arena,
        commandPanelRect: panel,
        enemyHudRect: _growHudRect(
          base: enemyHud,
          textScale: textScale,
          bounds: arena,
          obstacles: [playerHud, playerSprite, enemySprite],
        ),
        playerHudRect: _growHudRect(
          base: playerHud,
          textScale: textScale,
          bounds: arena,
          obstacles: [enemyHud, playerSprite, enemySprite],
        ),
        enemySpriteRect: enemySprite,
        playerSpriteRect: playerSprite,
        enemyPlatformRect: Rect.fromCenter(
          center: enemyFoot,
          width: enemySprite.width * .7,
          height: 4,
        ),
        playerPlatformRect: Rect.fromCenter(
          center: playerFoot,
          width: playerSprite.width * .7,
          height: 4,
        ),
        enemyFootAnchor: enemyFoot,
        playerFootAnchor: playerFoot,
        commandPanelLayoutMode: isPortrait
            ? BattleCommandPanelLayoutMode.stacked
            : BattleCommandPanelLayoutMode.split,
        scale: scale,
      );
    }
    final collection = switch (commandPanelMode) {
      BattleCommandOverlayMode.bag ||
      BattleCommandOverlayMode.pokemon ||
      BattleCommandOverlayMode.bagMedicineTarget ||
      BattleCommandOverlayMode.moveTarget => true,
      _ => false,
    };
    if (collection && !detached) {
      final bounds = Offset.zero & viewportSize;
      final target = commandPanelMode == BattleCommandOverlayMode.moveTarget;
      final panelWidth = math.min(
        target ? 310.0 : 460.0,
        viewportRect.width * .6,
      );
      final panel = isPortrait
          ? Rect.fromLTRB(
              0,
              viewportSize.height - math.min(560, viewportSize.height * .72),
              viewportSize.width,
              viewportSize.height,
            )
          : Rect.fromLTRB(
              math.max(
                safePadding.left,
                viewportSize.width -
                    math.max(20, safePadding.right) -
                    panelWidth,
              ),
              math.max(16, safePadding.top),
              viewportSize.width - math.max(20, safePadding.right),
              viewportSize.height - math.max(16, safePadding.bottom),
            );
      final arena = isPortrait
          ? Rect.fromLTRB(0, 0, viewportSize.width, panel.top)
          : Rect.fromLTRB(0, 0, panel.left, viewportSize.height);
      final scale = math.min(
        1.0,
        isPortrait
            ? math.min(viewportSize.width / 390, arena.height / 284)
            : math.min(viewportSize.width / 844, viewportSize.height / 390),
      );
      final enemyHud = Rect.fromLTWH(
        math.max((isPortrait ? 14 : 18) * scale, safePadding.left),
        math.max((isPortrait ? 38 : 18) * scale, safePadding.top),
        math.min((isPortrait ? 198 : 230) * scale, arena.width - 20),
        40.5 * scale,
      );
      final playerHud = Rect.fromLTWH(
        isPortrait
            ? viewportSize.width - math.max(14, safePadding.right) - 200 * scale
            : math.max(18 * scale, safePadding.left),
        arena.bottom -
            (isPortrait ? 12 : math.max(16, safePadding.bottom)) -
            68.25 * scale,
        math.min((isPortrait ? 200 : 230) * scale, arena.width - 20),
        68.25 * scale,
      );
      final playerSprite = Rect.fromLTWH(
        math.max((isPortrait ? 23.2 : 75.8) * scale, safePadding.left),
        arena.bottom - (isPortrait ? 75.05 + 91.6 : 111.95 + 118.4) * scale,
        (isPortrait ? 97.7 : 126.3) * scale,
        (isPortrait ? 91.6 : 118.4) * scale,
      );
      final enemySprite = isPortrait || target
          ? Rect.fromLTWH(
              arena.right - (isPortrait ? 117 : 110) * scale,
              arena.bottom - (isPortrait ? 106.83 + 75.2 : 180) * scale,
              67.8 * scale,
              75.2 * scale,
            )
          : Rect.zero;
      final playerFoot = Offset(
        playerSprite.left + playerSprite.width * .68,
        playerSprite.bottom,
      );
      final enemyFoot = Offset(enemySprite.center.dx, enemySprite.bottom);
      return BattleSceneLayout._(
        viewportSize: viewportSize,
        safePadding: safePadding,
        viewportClass: viewportClass,
        isPortrait: isPortrait,
        portraitSafeMargin: isPortrait ? 14 : 0,
        sceneRect: bounds,
        arenaRect: arena,
        commandPanelPlacement: isPortrait
            ? BattleCommandPanelPlacement.bottom
            : BattleCommandPanelPlacement.end,
        commandPanelMode: commandPanelMode,
        controllerLayout: controllerLayout,
        portraitTouchLayout: portraitTouchLayout,
        stageRect: arena,
        commandPanelRect: panel,
        enemyHudRect: _growHudRect(
          base: enemyHud,
          textScale: textScale,
          bounds: arena,
          obstacles: [playerHud, playerSprite, enemySprite],
        ),
        playerHudRect: _growHudRect(
          base: playerHud,
          textScale: textScale,
          bounds: arena,
          obstacles: [enemyHud, playerSprite, enemySprite],
        ),
        enemySpriteRect: enemySprite,
        playerSpriteRect: playerSprite,
        enemyPlatformRect: Rect.zero,
        playerPlatformRect: Rect.fromCenter(
          center: playerFoot,
          width: playerSprite.width * .7,
          height: 5 * scale,
        ),
        enemyFootAnchor: enemyFoot,
        playerFootAnchor: playerFoot,
        commandPanelLayoutMode: isPortrait
            ? BattleCommandPanelLayoutMode.stacked
            : BattleCommandPanelLayoutMode.split,
        scale: scale,
      );
    }
    final compactController = controllerLayout && !detached;
    final compactSideWidth = math.min(viewportSize.width * .25, 280.0);
    final sidePanelWidth = compactController ? compactSideWidth : 310.0;
    final sceneRect = sidePanel
        ? Rect.fromLTRB(
            viewportRect.left,
            viewportRect.top,
            viewportSize.width -
                math.max(20, safePadding.right) -
                sidePanelWidth -
                4,
            viewportRect.bottom,
          )
        : viewportRect;
    final portraitSafeMargin = isPortrait ? 14.0 : 0.0;

    final commandPanelLayoutMode = _resolveCommandPanelLayoutMode(
      viewportClass,
    );
    final commandPanelHorizontalPadding = switch (viewportClass) {
      BattleViewportClass.compactPortrait => 12.0,
      BattleViewportClass.mediumLandscape => 16.0,
      BattleViewportClass.wideDesktop => 20.0,
    };
    final commandPanelBottomPadding = switch (viewportClass) {
      BattleViewportClass.compactPortrait => 14.0,
      BattleViewportClass.mediumLandscape => 12.0,
      BattleViewportClass.wideDesktop => 18.0,
    };
    final controllerRoot = commandPanelMode == BattleCommandOverlayMode.root;
    final controllerTextScale = textScale.clamp(1.0, 1.6);
    final compactTouchPortrait =
        compactController && isPortrait && portraitTouchLayout && textScale <= 1.0;
    final expandedControllerHeight = compactTouchPortrait
        ? (viewportSize.width < 360 ? 228.0 : 220.0)
        : (viewportSize.width < 360 ? 268.0 : 236.0);
    final controllerBottomHeight =
        (controllerRoot
            ? (compactTouchPortrait ? 160.0 : 128.0)
            : expandedControllerHeight) *
        controllerTextScale;
    final commandPanelHeight = compactController && isPortrait
        ? math.min(
            controllerBottomHeight,
            viewportRect.height * (textScale > 1.3 ? .62 : .46),
          )
        : switch (viewportClass) {
            BattleViewportClass.compactPortrait => math.min(
              300.0,
              viewportSize.height * .5,
            ),
            BattleViewportClass.mediumLandscape => 108.0,
            BattleViewportClass.wideDesktop =>
              (sceneRect.height * 0.22).clamp(146.0, 176.0).toDouble(),
          };
    final rootDock = commandPanelMode == BattleCommandOverlayMode.root;
    final sideDockWidth = compactController
        ? compactSideWidth
        : rootDock
        ? 310.0
        : 293.0;
    final sideDockHeight = compactController
        ? (rootDock ? 232.0 : 288.0) * controllerTextScale
        : rootDock
        ? 284.0
        : 267.0;
    final controllerPanelTop = math.max(35.0, safePadding.top + 8) + 39 + 8;
    final controllerAvailableHeight = math.max(
      48.0,
      viewportSize.height -
          math.max(18, safePadding.bottom) -
          controllerPanelTop,
    );
    final actualSideHeight = compactController
        ? math.min(sideDockHeight, controllerAvailableHeight)
        : math.min(sideDockHeight, viewportRect.height - 24);
    final commandPanelRect = detached
        ? Rect.zero
        : sidePanel
        ? Rect.fromLTWH(
            viewportSize.width -
                math.max(rootDock ? 20 : 14, safePadding.right) -
                sideDockWidth,
            math.max(
              viewportRect.top + 12,
              viewportSize.height -
                  math.max(rootDock ? 16 : 18, safePadding.bottom) -
                  actualSideHeight,
            ),
            sideDockWidth,
            actualSideHeight,
          )
        : viewportClass != BattleViewportClass.wideDesktop
        ? Rect.fromLTWH(
            math.max(isPortrait ? 18 : 24, safePadding.left),
            viewportSize.height -
                math.max(isPortrait ? 24 : 12, safePadding.bottom) -
                commandPanelHeight,
            viewportSize.width -
                math.max(isPortrait ? 18 : 24, safePadding.left) -
                math.max(isPortrait ? 18 : 24, safePadding.right),
            commandPanelHeight,
          )
        : Rect.fromLTWH(
            sceneRect.left + commandPanelHorizontalPadding,
            sceneRect.bottom - commandPanelBottomPadding - commandPanelHeight,
            sceneRect.width - (commandPanelHorizontalPadding * 2),
            commandPanelHeight,
          );

    if (sidePanel || detached) {
      final growthObstacle = sidePanel
          ? Rect.fromLTWH(
              viewportSize.width -
                  math.max(20, safePadding.right) -
                  sidePanelWidth,
              math.max(
                viewportRect.top + 12,
                viewportSize.height -
                    math.max(16, safePadding.bottom) -
                    (compactController
                        ? math.min(
                            288 * controllerTextScale,
                            controllerAvailableHeight,
                          )
                        : 284),
              ),
              sidePanelWidth,
              compactController
                  ? math.min(
                      288 * controllerTextScale,
                      controllerAvailableHeight,
                    )
                  : math.min(284, viewportRect.height - 24),
            )
          : commandPanelRect;
      final detachedMessage =
          detached && commandPanelMode == BattleCommandOverlayMode.continueOnly;
      final scale = sidePanel
          ? math.min(
              1.0,
              math.min(viewportSize.width / 844, viewportSize.height / 390),
            )
          : math.min(
              1.0,
              math.min(viewportSize.width / 768, viewportSize.height / 432),
            );
      final enemyHudSize = sidePanel
          ? Size(261 * scale, 39 * scale)
          : Size(244 * scale, 40.5 * scale);
      final playerHudSize = sidePanel
          ? Size(243 * scale, 67 * scale)
          : Size(250 * scale, 68.25 * scale);
      final enemyHud = Rect.fromLTWH(
        sidePanel
            ? viewportSize.width - (14 * scale) - enemyHudSize.width
            : 24 * scale,
        sidePanel
            ? math.max(35 * scale, safePadding.top + 8)
            : math.max(22 * scale, safePadding.top),
        enemyHudSize.width,
        enemyHudSize.height,
      );
      final playerHud = Rect.fromLTWH(
        sidePanel
            ? compactController
                  ? sceneRect.left + 11 * scale
                  : 11 * scale
            : viewportSize.width - playerHudSize.width - 24 * scale,
        sidePanel
            ? compactController
                  ? viewportSize.height -
                        (77 + 134) * scale -
                        8 -
                        playerHudSize.height
                  : viewportSize.height - (19 * scale) - playerHudSize.height
            : viewportSize.height -
                  playerHudSize.height -
                  ((detachedMessage ? 120 : 20) * scale),
        playerHudSize.width,
        playerHudSize.height,
      );
      final playerSize = sidePanel
          ? Size(148 * scale, 134 * scale)
          : Size(185 * scale, 174 * scale);
      final enemySize = sidePanel
          ? Size(77 * scale, 96 * scale)
          : Size(128 * scale, 142 * scale);
      final playerSprite = Rect.fromLTWH(
        sidePanel
            ? compactController
                  ? sceneRect.left + sceneRect.width * .18
                  : 169 * scale
            : 99 * scale,
        sidePanel
            ? viewportSize.height - (77 * scale) - playerSize.height
            : viewportSize.height -
                  ((detachedMessage ? 134 : 74) * scale) -
                  playerSize.height,
        playerSize.width,
        playerSize.height,
      );
      final enemySprite = Rect.fromLTWH(
        sidePanel
            ? compactController
                  ? sceneRect.right - enemySize.width - 24 * scale
                  : math.min(
                      viewportSize.width - (343.5 * scale) - enemySize.width,
                      sceneRect.right - enemySize.width,
                    )
            : viewportSize.width - 299 * scale,
        sidePanel
            ? viewportSize.height - (159 * scale) - enemySize.height
            : math.min(
                    viewportSize.height - 161.5 * scale,
                    playerHud.top - 8 * scale,
                  ) -
                  enemySize.height,
        enemySize.width,
        enemySize.height,
      );
      final playerFoot = Offset(
        playerSprite.left + playerSprite.width * .68,
        playerSprite.bottom,
      );
      final enemyFoot = Offset(enemySprite.center.dx, enemySprite.bottom);
      final playerPlatform = Rect.fromLTWH(
        playerFoot.dx - (sidePanel ? 12 : 52) * scale,
        playerFoot.dy - 5 * scale,
        (sidePanel ? 24 : 104) * scale,
        12 * scale,
      );
      final enemyPlatform = Rect.fromLTWH(
        enemyFoot.dx - (sidePanel ? 40 : 48) * scale,
        enemyFoot.dy - 4 * scale,
        (sidePanel ? 80 : 96) * scale,
        12 * scale,
      );
      final grownEnemyHud = _growHudRect(
        base: enemyHud,
        textScale: textScale,
        bounds: Offset.zero & viewportSize,
        obstacles: [
          playerSprite.expandToInclude(playerPlatform),
          enemySprite.expandToInclude(enemyPlatform),
          playerHud,
          growthObstacle,
        ],
      );
      final playerHudCandidate = _growHudRect(
        base: playerHud,
        textScale: textScale,
        bounds: compactController ? sceneRect : Offset.zero & viewportSize,
        obstacles: [
          compactController
              ? playerSprite.expandToInclude(playerPlatform).inflate(8)
              : playerSprite.expandToInclude(playerPlatform),
          enemySprite.expandToInclude(enemyPlatform),
          compactController ? grownEnemyHud : enemyHud,
          growthObstacle,
        ],
      );
      final grownPlayerHud = sidePanel && !compactController
          ? Rect.fromLTRB(
              playerHudCandidate.left,
              math.max(playerHudCandidate.top, playerHud.top),
              math.min(playerHudCandidate.right, playerHud.right),
              playerHudCandidate.bottom,
            )
          : playerHudCandidate;
      return BattleSceneLayout._(
        viewportSize: viewportSize,
        safePadding: safePadding,
        viewportClass: viewportClass,
        isPortrait: isPortrait,
        portraitSafeMargin: portraitSafeMargin,
        sceneRect: viewportRect,
        arenaRect: sceneRect,
        commandPanelPlacement: effectivePlacement,
        commandPanelMode: commandPanelMode,
        controllerLayout: controllerLayout,
        portraitTouchLayout: portraitTouchLayout,
        stageRect: sceneRect.deflate(8),
        commandPanelRect: commandPanelRect,
        enemyHudRect: grownEnemyHud,
        playerHudRect: grownPlayerHud,
        enemySpriteRect: enemySprite,
        playerSpriteRect: playerSprite,
        enemyPlatformRect: enemyPlatform,
        playerPlatformRect: playerPlatform,
        enemyFootAnchor: enemyFoot,
        playerFootAnchor: playerFoot,
        commandPanelLayoutMode: commandPanelLayoutMode,
        scale: scale,
      );
    }

    {
      final bounds = Offset.zero & viewportSize;
      final scenePanelTop = compactController && isPortrait
          ? viewportSize.height -
                math.max(24, safePadding.bottom) -
                math.min(
                  expandedControllerHeight * controllerTextScale,
                  viewportRect.height * (textScale > 1.3 ? .62 : .46),
                )
          : commandPanelRect.top;
      final arena = Rect.fromLTRB(0, 0, viewportSize.width, scenePanelTop);
      final visualScale = math.min(
        1.0,
        isPortrait
            ? viewportSize.width / 390
            : math.min(viewportSize.width / 844, viewportSize.height / 390),
      );
      final enemyHud = Rect.fromLTWH(
        (isPortrait ? 14 : 20) * visualScale,
        math.max(
          (isPortrait ? 48 : 12) * visualScale,
          safePadding.top + (isPortrait ? 8 : 0),
        ),
        216 * visualScale,
        40.5 * visualScale,
      );
      final loweredPortrait = compactController && isPortrait;
      final touchPortrait = loweredPortrait && portraitTouchLayout;
      final portraitSpriteScale = math.min(
        visualScale,
        math.max(
              0.0,
              scenePanelTop - enemyHud.bottom - 68.25 * visualScale - 36,
            ) /
            246.3,
      );
      final touchPlayerLeft = math.max(28 * visualScale, safePadding.left + 8);
      final touchHudRight =
          viewportSize.width -
          math.max(14 * visualScale, safePadding.right + 8);
      final touchHudLeft = touchHudRight - 218 * visualScale;
      final touchHudDisplayLeft = math.min(
        touchHudRight,
        math.max(touchHudLeft, viewportSize.width / 2),
      );
      final touchPlayerHeight = math.min(
        137 * portraitSpriteScale,
        math.max(0, touchHudLeft - 8 - touchPlayerLeft) * 137 / 147,
      );
      final touchHudTop = math.min(
        scenePanelTop - 8 - 68.25 * visualScale,
        scenePanelTop - 8 - (touchPlayerHeight + 68.25 * visualScale) / 2,
      );
      final playerHud = Rect.fromLTWH(
        touchPortrait
            ? touchHudDisplayLeft
            : viewportSize.width -
                  ((isPortrait ? 14 : 24) + (isPortrait ? 218 : 210)) * visualScale,
        isPortrait
            ? loweredPortrait
                  ? touchPortrait
                        ? touchHudTop
                        : scenePanelTop -
                              16 -
                              68.25 * visualScale -
                              137 * portraitSpriteScale
                  : scenePanelTop - (30 + 68.25) * visualScale
            : math.min(
                    viewportSize.height - 142 * visualScale,
                    scenePanelTop - 12 * visualScale,
                  ) -
                  68.25 * visualScale,
        touchPortrait
            ? touchHudRight - touchHudDisplayLeft
            : (isPortrait ? 218 : 210) * visualScale,
        68.25 * visualScale,
      );
      final availableSpriteHeight = math.max(
        24.0,
        (isPortrait && !loweredPortrait ? playerHud.top : arena.bottom) -
            enemyHud.bottom -
            16,
      );
      final playerHeight = math.min(
        touchPortrait
            ? touchPlayerHeight
            : isPortrait
            ? 137 * (loweredPortrait ? portraitSpriteScale : visualScale)
            : 126.3 * visualScale,
        availableSpriteHeight,
      );
      final playerWidth =
          playerHeight * (isPortrait ? 147 / 137 : 134.7 / 126.3);
      final playerBottom = loweredPortrait
          ? scenePanelTop - 8
          : isPortrait
          ? (scenePanelTop - 112.5 * visualScale).clamp(
              math.min(enemyHud.bottom + 8 + playerHeight, playerHud.top - 8),
              playerHud.top - 8,
            )
          : math.min(
              viewportSize.height - 132.2 * visualScale,
              scenePanelTop - 8 * visualScale,
            );
      final playerSprite = Rect.fromLTWH(
        touchPortrait ? touchPlayerLeft : (isPortrait ? 28 : 140.6) * visualScale,
        playerBottom - playerHeight,
        playerWidth,
        playerHeight,
      );
      final enemyHeight = math.min(
        isPortrait
            ? 109.3 * (loweredPortrait ? portraitSpriteScale : visualScale)
            : 94 * visualScale,
        availableSpriteHeight,
      );
      final enemyWidth = enemyHeight * (isPortrait ? 98.7 / 109.3 : 84.8 / 94);
      final enemyBottom = math.min(
        isPortrait
            ? compactController
                  ? math.min(
                      scenePanelTop - 224.5 * visualScale,
                      playerHud.top - 12,
                    )
                  : scenePanelTop - 150.7 * visualScale
            : viewportSize.height - 208.3 * visualScale,
        playerHud.top - 8,
      );
      final enemySprite = Rect.fromLTWH(
        viewportSize.width - (isPortrait ? 136 : 306.3) * visualScale,
        math.max(enemyHud.bottom + 8, enemyBottom - enemyHeight),
        enemyWidth,
        enemyHeight,
      );
      final playerFoot = Offset(
        playerSprite.left + playerWidth * .68,
        playerSprite.bottom,
      );
      final enemyFoot = Offset(enemySprite.center.dx, enemySprite.bottom);
      final playerPlatform = Rect.fromLTWH(
        playerFoot.dx - playerWidth * .28,
        playerFoot.dy - 4 * visualScale,
        playerWidth * .56,
        12 * visualScale,
      );
      final enemyPlatform = Rect.fromLTWH(
        enemyFoot.dx - enemyWidth * .35,
        enemyFoot.dy - 4 * visualScale,
        enemyWidth * .7,
        12 * visualScale,
      );
      final touchBounds = Rect.fromLTRB(
        safePadding.left + 8,
        safePadding.top + 8,
        viewportSize.width - safePadding.right - 8,
        scenePanelTop - 8,
      );
      final enemyGrown = _growHudRect(
        base: enemyHud,
        textScale: textScale,
        bounds: touchPortrait ? touchBounds : arena,
        obstacles: [
          playerSprite.expandToInclude(playerPlatform),
          enemySprite.expandToInclude(enemyPlatform),
          playerHud,
        ],
      );
      final playerGrown = _growHudRect(
        base: playerHud,
        textScale: textScale,
        bounds: touchPortrait
            ? Rect.fromLTRB(
                touchHudDisplayLeft,
                touchBounds.top,
                touchBounds.right,
                touchBounds.bottom,
              )
            : arena,
        obstacles: [
          loweredPortrait
              ? playerSprite.expandToInclude(playerPlatform).inflate(8)
              : playerSprite.expandToInclude(playerPlatform),
          touchPortrait
              ? enemySprite.expandToInclude(enemyPlatform).inflate(8)
              : enemySprite.expandToInclude(enemyPlatform),
          touchPortrait ? enemyGrown : enemyHud,
        ],
      );
      return BattleSceneLayout._(
        viewportSize: viewportSize,
        safePadding: safePadding,
        viewportClass: viewportClass,
        isPortrait: isPortrait,
        portraitSafeMargin: portraitSafeMargin,
        sceneRect: bounds,
        arenaRect: arena,
        commandPanelPlacement: effectivePlacement,
        commandPanelMode: commandPanelMode,
        controllerLayout: controllerLayout,
        portraitTouchLayout: portraitTouchLayout,
        stageRect: Rect.fromLTRB(
          arena.left + portraitSafeMargin,
          arena.top + 14,
          arena.right - portraitSafeMargin,
          arena.bottom - 16,
        ),
        commandPanelRect: commandPanelRect,
        enemyHudRect: enemyGrown,
        playerHudRect: playerGrown,
        enemySpriteRect: enemySprite,
        playerSpriteRect: playerSprite,
        enemyPlatformRect: enemyPlatform,
        playerPlatformRect: playerPlatform,
        enemyFootAnchor: enemyFoot,
        playerFootAnchor: playerFoot,
        commandPanelLayoutMode: commandPanelLayoutMode,
        scale: visualScale,
      );
    }

  }

  static BattleViewportClass classifyViewport({
    required Size viewportSize,
    EdgeInsets safePadding = EdgeInsets.zero,
  }) {
    final sceneWidth = math.max(0, viewportSize.width - safePadding.horizontal);
    final sceneHeight = math.max(0, viewportSize.height - safePadding.vertical);
    final isPortrait = sceneHeight > sceneWidth;
    if (isPortrait) {
      return BattleViewportClass.compactPortrait;
    }
    if (sceneWidth >= 1000 && sceneHeight >= 600) {
      return BattleViewportClass.wideDesktop;
    }
    return BattleViewportClass.mediumLandscape;
  }

  static BattleCommandPanelLayoutMode _resolveCommandPanelLayoutMode(
    BattleViewportClass viewportClass,
  ) {
    return viewportClass == BattleViewportClass.compactPortrait
        ? BattleCommandPanelLayoutMode.stacked
        : BattleCommandPanelLayoutMode.split;
  }
}

/// Agrandit un rectangle de HUD à la demande de l'échelle de texte, en
/// s'arrêtant sur ses voisins réels.
///
/// Les deux axes sont traités séparément, et dans cet ordre : la largeur
/// d'abord, puis la hauteur bornée par les obstacles que la NOUVELLE bande
/// horizontale rencontre. Un seul facteur commun aux deux axes serait plus
/// simple et strictement moins bon : sur un portrait compact, la largeur bute
/// sur le sprite ennemi bien avant que la hauteur ne manque, et c'est la
/// hauteur qui commande la taille de police.
///
/// Un obstacle qui chevauche DÉJÀ la base est ignoré par construction — les
/// conditions ne retiennent que ce qui est entièrement d'un côté. Sans ça, le
/// sprite joueur, qui déborde volontairement à gauche de la boîte de scène,
/// produirait des bornes absurdes dès qu'un HUD naît dans son débord.
Rect _growHudRect({
  required Rect base,
  required double textScale,
  required Rect bounds,
  required List<Rect> obstacles,
}) {
  final scale = textScale.clamp(battleMinimumTextScale, battleMaximumTextScale);
  if (scale <= 1.0 || base.isEmpty) {
    return base;
  }

  double limit(
    Iterable<double> candidates,
    double fallback, {
    required bool lower,
  }) {
    var result = fallback;
    for (final candidate in candidates) {
      result = lower
          ? math.max(result, candidate)
          : math.min(result, candidate);
    }
    return result;
  }

  final verticalNeighbours = obstacles.where(
    (obstacle) => obstacle.top < base.bottom && obstacle.bottom > base.top,
  );
  final leftLimit = limit(
    verticalNeighbours
        .where((obstacle) => obstacle.right <= base.left)
        .map((obstacle) => obstacle.right),
    bounds.left,
    lower: true,
  );
  final rightLimit = limit(
    verticalNeighbours
        .where((obstacle) => obstacle.left >= base.right)
        .map((obstacle) => obstacle.left),
    bounds.right,
    lower: false,
  );
  final width = math.min(base.width * scale, rightLimit - leftLimit);
  final left = math.max(leftLimit, math.min(base.left, rightLimit - width));

  final horizontalNeighbours = obstacles.where(
    (obstacle) => obstacle.left < left + width && obstacle.right > left,
  );
  final topLimit = limit(
    horizontalNeighbours
        .where((obstacle) => obstacle.bottom <= base.top)
        .map((obstacle) => obstacle.bottom),
    bounds.top,
    lower: true,
  );
  final bottomLimit = limit(
    horizontalNeighbours
        .where((obstacle) => obstacle.top >= base.bottom)
        .map((obstacle) => obstacle.top),
    bounds.bottom,
    lower: false,
  );
  final height = math.min(base.height * scale, bottomLimit - topLimit);
  final top = math.max(topLimit, math.min(base.top, bottomLimit - height));

  return Rect.fromLTWH(left, top, width, height);
}
