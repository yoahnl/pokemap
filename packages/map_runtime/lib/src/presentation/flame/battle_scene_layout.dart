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

    // Calculé AVANT la scène, parce que l'ennemi doit pouvoir s'écarter de lui.
    // Ce HUD est le seul élément placé en pixels d'écran au-dessus du panneau :
    // son empreinte au-dessus du bas de scène est constante alors que le
    // dégagement de l'ennemi vaut `140 * scale`. Sous une échelle d'environ
    // 0,5 — soit tous les téléphones en portrait — les deux se croisaient.
    final playerHudSize = switch (viewportClass) {
      BattleViewportClass.compactPortrait => Size(
          (sceneRect.width * 0.47).clamp(190.0, 216.0).toDouble(),
          (sceneRect.height * 0.105).clamp(70.0, 76.0).toDouble(),
        ),
      BattleViewportClass.mediumLandscape => const Size(184, 62),
      BattleViewportClass.wideDesktop => const Size(244, 74),
    };
    // `wideDesktop` place le sien en coordonnées de scène, donc invariant
    // d'échelle et sans collision possible : rien à réserver pour lui.
    final panelAnchoredPlayerHudRect = switch (viewportClass) {
      BattleViewportClass.compactPortrait => Rect.fromLTWH(
          sceneRect.right - portraitSafeMargin - playerHudSize.width,
          commandPanelRect.top - playerHudSize.height - 10,
          playerHudSize.width,
          playerHudSize.height,
        ),
      BattleViewportClass.mediumLandscape => Rect.fromLTWH(
          sceneRect.right - 192,
          commandPanelRect.top - 72,
          playerHudSize.width,
          playerHudSize.height,
        ),
      BattleViewportClass.wideDesktop => Rect.zero,
    };

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
    const playerSpriteReferenceSize = Size(350, 214);
    const enemySpriteReferenceSize = Size(210, 154);
    const playerPlatformReferenceSize = Size(222, 28);
    const enemyPlatformReferenceSize = Size(160, 22);
    const playerSpriteFootXRatio = 0.70;
    const enemySpriteFootXRatio = 0.5;
    const playerPlatformFootYOffset = 5.0;
    const enemyPlatformFootYOffset = 4.0;

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

    final scale = math.min(
      1.0,
      math.min(
        stageAvailableRect.width / referenceStageWidth,
        stageAvailableRect.height / referenceStageHeight,
      ),
    );

    // Le sprite de dos déborde volontairement à gauche de la boîte de scène :
    // le contrat l'exige explicitement (0,72 d'inclusion côté joueur contre
    // 0,9 côté ennemi). Ce débord n'a de sens que s'il reste de la place pour
    // l'absorber, et centrer la scène ne le garantit pas — à 1280x720 le
    // letterboxing l'absorbe, à 960x540 la scène remplit la largeur et le
    // quart gauche du Pokémon tombait hors écran. On ne centre donc que dans
    // la marge que les combattants laissent réellement.
    final combatantReferenceLeft = <double>[
      playerFootReference.dx -
          (playerSpriteReferenceSize.width * playerSpriteFootXRatio),
      playerFootReference.dx - (playerPlatformReferenceSize.width / 2),
      enemyFootReference.dx -
          (enemySpriteReferenceSize.width * enemySpriteFootXRatio),
      enemyFootReference.dx - (enemyPlatformReferenceSize.width / 2),
    ].reduce((left, right) => math.min(left, right));
    final combatantReferenceRight = <double>[
      playerFootReference.dx +
          (playerSpriteReferenceSize.width * (1 - playerSpriteFootXRatio)),
      playerFootReference.dx + (playerPlatformReferenceSize.width / 2),
      enemyFootReference.dx +
          (enemySpriteReferenceSize.width * (1 - enemySpriteFootXRatio)),
      enemyFootReference.dx + (enemyPlatformReferenceSize.width / 2),
    ].reduce((left, right) => math.max(left, right));
    final centeredStageLeft = stageAvailableRect.left +
        ((stageAvailableRect.width - (referenceStageWidth * scale)) / 2);
    final stageLeft = math.max(
      stageAvailableRect.left - (combatantReferenceLeft * scale),
      math.min(
        centeredStageLeft,
        stageAvailableRect.right - (combatantReferenceRight * scale),
      ),
    );

    final stageRect = Rect.fromLTWH(
      stageLeft,
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

    final playerFootAnchor = mapPoint(
      playerFootReference.dx,
      playerFootReference.dy,
    );
    final mappedEnemyFootAnchor = mapPoint(
      enemyFootReference.dx,
      enemyFootReference.dy,
    );
    final mappedEnemySpriteRect = rectFromFootAnchor(
      mappedEnemyFootAnchor,
      enemySpriteReferenceSize,
      footXRatio: enemySpriteFootXRatio,
    );

    // C'est l'ennemi qui cède le passage au HUD joueur, jamais l'inverse : le
    // HUD garde la taille lisible gagnée en BETA-BAT-007, et il reste de la
    // marge au-dessus de l'ennemi pour l'accueillir. Le `min` ne mord que là
    // où la collision existe réellement.
    final enemyOverlapsPlayerHud = !panelAnchoredPlayerHudRect.isEmpty &&
        mappedEnemySpriteRect.right > panelAnchoredPlayerHudRect.left &&
        mappedEnemySpriteRect.left < panelAnchoredPlayerHudRect.right;
    // C'est le combattant AVEC son sol qui doit degager : la plateforme
    // descend sous l'ancre, et ne compter que le sprite laissait l'ennemi
    // debout sur une ellipse cachee derriere le HUD, donc flottant.
    final enemyPlatformBelowFootAnchor =
        (enemyPlatformReferenceSize.height - enemyPlatformFootYOffset) * scale;
    final enemyFootAnchor = enemyOverlapsPlayerHud
        ? Offset(
            mappedEnemyFootAnchor.dx,
            math.min(
              mappedEnemyFootAnchor.dy,
              panelAnchoredPlayerHudRect.top - 4 - enemyPlatformBelowFootAnchor,
            ),
          )
        : mappedEnemyFootAnchor;

    final playerSpriteRect = rectFromFootAnchor(
      playerFootAnchor,
      playerSpriteReferenceSize,
      footXRatio: playerSpriteFootXRatio,
    );
    final enemySpriteRect = rectFromFootAnchor(
      enemyFootAnchor,
      enemySpriteReferenceSize,
      footXRatio: enemySpriteFootXRatio,
    );

    final playerPlatformRect = platformRectFromFootAnchor(
      playerFootAnchor,
      playerPlatformReferenceSize,
      footYOffset: playerPlatformFootYOffset,
    );
    final enemyPlatformRect = platformRectFromFootAnchor(
      enemyFootAnchor,
      enemyPlatformReferenceSize,
      footYOffset: enemyPlatformFootYOffset,
    );

    final enemyHudRect = switch (viewportClass) {
      BattleViewportClass.compactPortrait => Rect.fromLTWH(
          sceneRect.left + portraitSafeMargin,
          sceneRect.top + portraitSafeMargin,
          (sceneRect.width * 0.44).clamp(176.0, 196.0).toDouble(),
          (sceneRect.height * 0.09).clamp(60.0, 66.0).toDouble(),
        ),
      // Recette du 2026-08-24 : à 156 px le nom de l'adversaire se tronquait
      // (« Ratt… ») dès qu'il dépassait six lettres. La largeur rejoint celle
      // du HUD portrait, qui affiche les mêmes informations sans couper. La
      // hauteur reste 54 : à 640×360, un pixel de plus mord le dégagement du
      // sprite joueur (invariant « non occultante » de BETA-BAT-009).
      BattleViewportClass.mediumLandscape => Rect.fromLTWH(
          sceneRect.left + 8,
          sceneRect.top + 8,
          196,
          54,
        ),
      BattleViewportClass.wideDesktop => mapRect(16, 8, 210, 70),
    };
    // Exactement le rectangle que l'ennemi a contourné : le recalculer ici
    // rouvrirait l'écart entre la bande réservée et la bande rendue.
    final playerHudRect = switch (viewportClass) {
      BattleViewportClass.compactPortrait ||
      BattleViewportClass.mediumLandscape =>
        panelAnchoredPlayerHudRect,
      BattleViewportClass.wideDesktop => mapRect(
          668,
          232,
          playerHudSize.width,
          playerHudSize.height,
        ),
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
/// sprite joueur, qui déborde volontairement à gauche de la boîte de scène,
/// produirait des bornes absurdes dès qu'un HUD naît dans son débord.
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
