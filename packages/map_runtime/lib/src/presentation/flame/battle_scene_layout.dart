import 'dart:math' as math;

import 'package:flutter/painting.dart';

enum BattleCommandPanelLayoutMode {
  split,
  stacked,
}

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
    required this.sceneRect,
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
  final Rect sceneRect;
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

  Rect get enemyCombatantBoundsRect =>
      enemySpriteRect.expandToInclude(enemyPlatformRect);

  Rect get playerCombatantBoundsRect =>
      playerSpriteRect.expandToInclude(playerPlatformRect);

  factory BattleSceneLayout.forViewport({
    required Size viewportSize,
    EdgeInsets safePadding = EdgeInsets.zero,
  }) {
    final sceneRect = Rect.fromLTWH(
      safePadding.left,
      safePadding.top,
      math.max(0, viewportSize.width - safePadding.horizontal),
      math.max(0, viewportSize.height - safePadding.vertical),
    );

    final commandPanelLayoutMode =
        _resolveCommandPanelLayoutMode(sceneRect.size);
    final commandPanelHorizontalPadding =
        commandPanelLayoutMode == BattleCommandPanelLayoutMode.stacked
            ? 12.0
            : 16.0;
    final commandPanelBottomPadding =
        commandPanelLayoutMode == BattleCommandPanelLayoutMode.stacked
            ? 12.0
            : 14.0;
    final commandPanelHeight =
        (commandPanelLayoutMode == BattleCommandPanelLayoutMode.stacked
                ? sceneRect.height * 0.34
                : sceneRect.height * 0.295)
            .clamp(
              commandPanelLayoutMode == BattleCommandPanelLayoutMode.stacked
                  ? 236.0
                  : 152.0,
              commandPanelLayoutMode == BattleCommandPanelLayoutMode.stacked
                  ? 320.0
                  : 182.0,
            )
            .toDouble();
    final commandPanelRect = Rect.fromLTWH(
      sceneRect.left + commandPanelHorizontalPadding,
      sceneRect.bottom - commandPanelBottomPadding - commandPanelHeight,
      sceneRect.width - (commandPanelHorizontalPadding * 2),
      commandPanelHeight,
    );

    final stageAvailableRect = Rect.fromLTRB(
      sceneRect.left,
      sceneRect.top + 8,
      sceneRect.right,
      commandPanelRect.top - 12,
    );

    const referenceStageWidth = 960.0;
    const referenceStageHeight = 330.0;
    final scale = math.min(
      1.0,
      math.min(
        stageAvailableRect.width / referenceStageWidth,
        stageAvailableRect.height / referenceStageHeight,
      ),
    );
    final stageRect = Rect.fromLTWH(
      stageAvailableRect.left +
          ((stageAvailableRect.width - (referenceStageWidth * scale)) / 2),
      stageAvailableRect.bottom - (referenceStageHeight * scale),
      referenceStageWidth * scale,
      referenceStageHeight * scale,
    );

    Offset mapPoint(double x, double y) {
      return Offset(
        stageRect.left + (x * scale),
        stageRect.top + (y * scale),
      );
    }

    Rect mapRect(double left, double top, double width, double height) {
      return Rect.fromLTWH(
        stageRect.left + (left * scale),
        stageRect.top + (top * scale),
        width * scale,
        height * scale,
      );
    }

    Rect rectFromFootAnchor(
      Offset footAnchor,
      Size spriteSize, {
      required double footXRatio,
    }) {
      final width = spriteSize.width * scale;
      final height = spriteSize.height * scale;
      return Rect.fromLTWH(
        footAnchor.dx - (width * footXRatio),
        footAnchor.dy - height,
        width,
        height,
      );
    }

    Rect platformRectFromFootAnchor(
      Offset footAnchor,
      Size platformSize, {
      double footYOffset = 4,
    }) {
      return Rect.fromLTWH(
        footAnchor.dx - ((platformSize.width * scale) / 2),
        footAnchor.dy - (footYOffset * scale),
        platformSize.width * scale,
        platformSize.height * scale,
      );
    }

    const playerFootReference = Offset(218, 296);
    const enemyFootReference = Offset(712, 208);
    final playerFootAnchor = mapPoint(
      playerFootReference.dx,
      playerFootReference.dy,
    );
    final enemyFootAnchor = mapPoint(
      enemyFootReference.dx,
      enemyFootReference.dy,
    );

    final playerSpriteRect = rectFromFootAnchor(
      playerFootAnchor,
      const Size(440, 264),
      footXRatio: 0.57,
    );
    final enemySpriteRect = rectFromFootAnchor(
      enemyFootAnchor,
      const Size(258, 182),
      footXRatio: 0.5,
    );

    final playerPlatformRect = platformRectFromFootAnchor(
      playerFootAnchor,
      const Size(248, 36),
    );
    final enemyPlatformRect = platformRectFromFootAnchor(
      enemyFootAnchor,
      const Size(176, 28),
    );

    final enemyHudRect = mapRect(18, 14, 262, 84);
    final playerHudRect = mapRect(640, 228, 286, 84);

    return BattleSceneLayout._(
      viewportSize: viewportSize,
      safePadding: safePadding,
      sceneRect: sceneRect,
      stageRect: stageRect,
      commandPanelRect: commandPanelRect,
      enemyHudRect: enemyHudRect,
      playerHudRect: playerHudRect,
      enemySpriteRect: enemySpriteRect,
      playerSpriteRect: playerSpriteRect,
      enemyPlatformRect: enemyPlatformRect,
      playerPlatformRect: playerPlatformRect,
      enemyFootAnchor: enemyFootAnchor,
      playerFootAnchor: playerFootAnchor,
      commandPanelLayoutMode: commandPanelLayoutMode,
      scale: scale,
    );
  }

  static BattleCommandPanelLayoutMode _resolveCommandPanelLayoutMode(
    Size sceneSize,
  ) {
    final portrait = sceneSize.height > sceneSize.width;
    final veryNarrow = sceneSize.width < 480;
    return portrait || veryNarrow
        ? BattleCommandPanelLayoutMode.stacked
        : BattleCommandPanelLayoutMode.split;
  }
}
