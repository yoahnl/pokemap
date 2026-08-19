import 'dart:math' as math;

import 'package:flutter/painting.dart';

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
    double textScale = 1.0,
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
        (sceneRect.height * 0.315).clamp(280.0, 304.0).toDouble(),
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
          (sceneRect.width * 0.44).clamp(176.0, 196.0).toDouble(),
          (sceneRect.height * 0.09).clamp(60.0, 66.0).toDouble(),
        ),
      BattleViewportClass.mediumLandscape => Rect.fromLTWH(
          sceneRect.left + 8,
          sceneRect.top + 8,
          156,
          54,
        ),
      BattleViewportClass.wideDesktop => mapRect(16, 8, 210, 70),
    };
    final playerHudRect = switch (viewportClass) {
      BattleViewportClass.compactPortrait => Rect.fromLTWH(
          sceneRect.right -
              portraitSafeMargin -
              (sceneRect.width * 0.47).clamp(190.0, 216.0).toDouble(),
          commandPanelRect.top -
              (sceneRect.height * 0.105).clamp(70.0, 76.0).toDouble() -
              10,
          (sceneRect.width * 0.47).clamp(190.0, 216.0).toDouble(),
          (sceneRect.height * 0.105).clamp(70.0, 76.0).toDouble(),
        ),
      BattleViewportClass.mediumLandscape => Rect.fromLTWH(
          sceneRect.right - 192,
          commandPanelRect.top - 72,
          184,
          62,
        ),
      BattleViewportClass.wideDesktop => mapRect(668, 232, 244, 74),
    };

    // BETA-BAT-007. La hauteur du rectangle est ce qui plafonnait vraiment
    // l'accessibilité texte du HUD : sur 54 à 74 px, une demande de 1.6
    // n'obtenait que 1.03 à 1.29 quel que soit le soin apporté aux polices.
    // Autorisé par Yoahn le 2026-08-20, donc les rectangles grandissent — mais
    // seulement quand le texte le demande, pour que la géométrie certifiée à
    // l'échelle 1.0 ne bouge pas d'un pixel.
    //
    // Aucune nouvelle constante : l'agrandissement s'arrête sur les voisins
    // réels. Le HUD est en priorité 20, donc il RECOUVRE les sprites — et
    // BETA-BAT-009 s'appelle « non occultante ». Grandir dans le décor n'est
    // donc pas gratuit, c'est la contrainte principale.
    final grownEnemyHudRect = _growHudRect(
      base: enemyHudRect,
      textScale: textScale,
      bounds: sceneRect,
      obstacles: <Rect>[
        playerSpriteRect,
        enemySpriteRect,
        commandPanelRect,
        playerHudRect,
      ],
    );
    final grownPlayerHudRect = _growHudRect(
      base: playerHudRect,
      textScale: textScale,
      bounds: sceneRect,
      obstacles: <Rect>[
        playerSpriteRect,
        enemySpriteRect,
        commandPanelRect,
        enemyHudRect,
      ],
    );

    return BattleSceneLayout._(
      viewportSize: viewportSize,
      safePadding: safePadding,
      viewportClass: viewportClass,
      isPortrait: isPortrait,
      portraitSafeMargin: portraitSafeMargin,
      sceneRect: sceneRect,
      stageRect: stageRect,
      commandPanelRect: commandPanelRect,
      enemyHudRect: grownEnemyHudRect,
      playerHudRect: grownPlayerHudRect,
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
/// HUD joueur en portrait, qui recouvre déjà 8 px du sprite ennemi, produirait
/// des bornes absurdes.
Rect _growHudRect({
  required Rect base,
  required double textScale,
  required Rect bounds,
  required List<Rect> obstacles,
}) {
  final scale = textScale.clamp(
    battleMinimumTextScale,
    battleMaximumTextScale,
  );
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
    (obstacle) =>
        obstacle.top < base.bottom && obstacle.bottom > base.top,
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
