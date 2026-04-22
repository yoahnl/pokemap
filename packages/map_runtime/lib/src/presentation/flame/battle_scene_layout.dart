import 'dart:math' as math;

import 'package:flutter/painting.dart';

enum BattleCommandPanelLayoutMode {
  split,
  stacked,
}

enum BattleViewportClass {
  compactPortrait,
  mediumLandscape,
  wideDesktop,
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
    required this.viewportClass,
    required this.isPortrait,
    required this.portraitSafeMargin,
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
  final BattleViewportClass viewportClass;
  final bool isPortrait;
  final double portraitSafeMargin;
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
    final viewportClass = classifyViewport(
      viewportSize: viewportSize,
      safePadding: safePadding,
    );
    final isPortrait = viewportSize.height > viewportSize.width;
    final sceneRect = Rect.fromLTWH(
      safePadding.left,
      safePadding.top,
      math.max(0, viewportSize.width - safePadding.horizontal),
      math.max(0, viewportSize.height - safePadding.vertical),
    );
    final portraitSafeMargin = isPortrait
        ? (sceneRect.width * 0.038).clamp(14.0, 20.0).toDouble()
        : 0.0;

    final commandPanelLayoutMode =
        _resolveCommandPanelLayoutMode(viewportClass);
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
    final commandPanelHeight = switch (viewportClass) {
      BattleViewportClass.compactPortrait =>
        (sceneRect.height * 0.315).clamp(248.0, 272.0).toDouble(),
      BattleViewportClass.mediumLandscape =>
        (sceneRect.height * 0.34).clamp(138.0, 168.0).toDouble(),
      BattleViewportClass.wideDesktop =>
        (sceneRect.height * 0.22).clamp(146.0, 176.0).toDouble(),
    };
    final commandPanelRect = Rect.fromLTWH(
      sceneRect.left + commandPanelHorizontalPadding,
      sceneRect.bottom - commandPanelBottomPadding - commandPanelHeight,
      sceneRect.width - (commandPanelHorizontalPadding * 2),
      commandPanelHeight,
    );

    final stageBottomGap = switch (viewportClass) {
      BattleViewportClass.compactPortrait => 16.0,
      BattleViewportClass.mediumLandscape => 12.0,
      BattleViewportClass.wideDesktop => 16.0,
    };
    final stageAvailableRect = Rect.fromLTRB(
      isPortrait ? sceneRect.left + portraitSafeMargin : sceneRect.left,
      switch (viewportClass) {
        BattleViewportClass.compactPortrait => sceneRect.top + 14,
        BattleViewportClass.mediumLandscape => sceneRect.top + 8,
        BattleViewportClass.wideDesktop => sceneRect.top + 18,
      },
      isPortrait ? sceneRect.right - portraitSafeMargin : sceneRect.right,
      commandPanelRect.top - stageBottomGap,
    );

    final referenceStageWidth = switch (viewportClass) {
      BattleViewportClass.compactPortrait => 820.0,
      BattleViewportClass.mediumLandscape => 960.0,
      BattleViewportClass.wideDesktop => 960.0,
    };
    final referenceStageHeight = switch (viewportClass) {
      BattleViewportClass.compactPortrait => 360.0,
      BattleViewportClass.mediumLandscape => 330.0,
      BattleViewportClass.wideDesktop => 330.0,
    };
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

    final playerFootReference = switch (viewportClass) {
      BattleViewportClass.compactPortrait => const Offset(192, 350),
      BattleViewportClass.mediumLandscape => const Offset(158, 322),
      BattleViewportClass.wideDesktop => const Offset(158, 322),
    };
    final enemyFootReference = switch (viewportClass) {
      BattleViewportClass.compactPortrait => const Offset(610, 220),
      BattleViewportClass.mediumLandscape => const Offset(724, 214),
      BattleViewportClass.wideDesktop => const Offset(724, 214),
    };
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
      const Size(350, 214),
      footXRatio: 0.70,
    );
    final enemySpriteRect = rectFromFootAnchor(
      enemyFootAnchor,
      const Size(210, 154),
      footXRatio: 0.5,
    );

    final playerPlatformRect = platformRectFromFootAnchor(
      playerFootAnchor,
      const Size(222, 28),
      footYOffset: 5,
    );
    final enemyPlatformRect = platformRectFromFootAnchor(
      enemyFootAnchor,
      const Size(160, 22),
      footYOffset: 4,
    );

    final enemyHudRect = switch (viewportClass) {
      BattleViewportClass.compactPortrait => Rect.fromLTWH(
          sceneRect.left + portraitSafeMargin,
          sceneRect.top + portraitSafeMargin,
          (sceneRect.width * 0.33).clamp(122.0, 160.0).toDouble(),
          (sceneRect.height * 0.061).clamp(46.0, 52.0).toDouble(),
        ),
      BattleViewportClass.mediumLandscape => mapRect(16, 8, 210, 68),
      BattleViewportClass.wideDesktop => mapRect(16, 8, 210, 68),
    };
    final playerHudRect = switch (viewportClass) {
      BattleViewportClass.compactPortrait => Rect.fromLTWH(
          sceneRect.right -
              portraitSafeMargin -
              (sceneRect.width * 0.36).clamp(142.0, 180.0).toDouble(),
          commandPanelRect.top -
              (sceneRect.height * 0.068).clamp(54.0, 60.0).toDouble() -
              10,
          (sceneRect.width * 0.36).clamp(142.0, 180.0).toDouble(),
          (sceneRect.height * 0.068).clamp(54.0, 60.0).toDouble(),
        ),
      BattleViewportClass.mediumLandscape => mapRect(668, 232, 244, 72),
      BattleViewportClass.wideDesktop => mapRect(668, 232, 244, 72),
    };

    return BattleSceneLayout._(
      viewportSize: viewportSize,
      safePadding: safePadding,
      viewportClass: viewportClass,
      isPortrait: isPortrait,
      portraitSafeMargin: portraitSafeMargin,
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
