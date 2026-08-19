import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'battle_scene_layout.dart';

/// Marge minimale entre le bas du bloc titre et le haut de la ligne d'HP.
///
/// Déjà appliquée au bandeau de statut avant d'être nommée ; le plafond
/// géométrique de l'échelle de texte la réutilise pour que les deux règles ne
/// puissent pas diverger.
const double _titleToHpRowGap = 4.0;

final class BattleSceneHudLayout {
  const BattleSceneHudLayout._({
    required this.hudRect,
    required this.ownerRect,
    required this.nameRect,
    required this.genderRect,
    required this.levelRect,
    required this.statusRect,
    required this.hpLabelRect,
    required this.hpBarRect,
    required this.hpValueRect,
    required this.showsHpValue,
    required this.ownerFontSize,
    required this.nameFontSize,
    required this.levelFontSize,
    required this.statusFontSize,
    required this.hpLabelFontSize,
    required this.hpValueFontSize,
    required this.effectiveTextScale,
  });

  final Rect hudRect;
  final Rect ownerRect;
  final Rect nameRect;
  final Rect? genderRect;
  final Rect levelRect;
  final Rect? statusRect;
  final Rect hpLabelRect;
  final Rect hpBarRect;
  final Rect? hpValueRect;
  final bool showsHpValue;
  final double ownerFontSize;
  final double nameFontSize;
  final double levelFontSize;
  final double statusFontSize;
  final double hpLabelFontSize;
  final double hpValueFontSize;

  /// Part de l'échelle demandée que le rectangle a réellement pu accorder.
  ///
  /// Rendue observable exprès : sur les HUD les plus bas, la hauteur imposée par
  /// la scène ne laisse presque rien, et une échelle demandée sans effet doit
  /// pouvoir être constatée plutôt que devinée.
  final double effectiveTextScale;

  factory BattleSceneHudLayout.forBounds({
    required Rect hudRect,
    required bool isPlayerSide,
    required String speciesText,
    String? genderSymbol,
    required String levelText,
    required String hpValueText,
    String? statusText,
    double textScale = 1.0,
  }) {
    final requestedScale = textScale.clamp(
      battleMinimumTextScale,
      battleMaximumTextScale,
    );
    final compact = hudRect.width <= 220 || hudRect.height <= 74;
    final extraCompact = hudRect.width <= 170 || hudRect.height <= 68;
    final ultraCompact = hudRect.width <= 140 || hudRect.height <= 46;

    // Un texte agrandi rend la boîte plus serrée, donc on emprunte les marges
    // du palier serré suivant au lieu d'inventer des valeurs : ce sont celles
    // qui habillent déjà les petits HUD. Troquer de la marge contre de la
    // lisibilité est le bon échange sous un réglage d'accessibilité, et c'est
    // la seule place disponible — la hauteur du rectangle, elle, est imposée
    // par la scène.
    final crampedByText = textScale > 1.0;
    final horizontalPadding = ultraCompact
        ? 7.0
        : extraCompact || crampedByText
            ? 10.0
            : 14.0;
    final topPadding = ultraCompact || (extraCompact && crampedByText)
        ? 6.0
        : extraCompact || crampedByText
            ? 10.0
            : 12.0;
    final bottomPadding = topPadding;
    final baseOwnerFontSize =
        ultraCompact ? 6.0 : extraCompact ? 8.0 : compact ? 9.0 : 10.0;
    final baseNameFontSize =
        ultraCompact ? 9.0 : extraCompact ? 12.0 : compact ? 14.0 : 16.0;
    final baseLevelFontSize =
        ultraCompact ? 9.0 : extraCompact ? 12.0 : compact ? 14.0 : 15.0;
    final baseStatusFontSize = ultraCompact ? 6.5 : extraCompact ? 8.0 : 9.0;
    final baseHpLabelFontSize = ultraCompact ? 8.0 : extraCompact ? 10.0 : 11.0;
    final baseHpValueFontSize = ultraCompact
        ? 8.0
        : extraCompact
            ? 10.0
            : compact
                ? 11.0
                : 12.0;
    final ownerLineFactor = ultraCompact ? 1.0 : 1.2;
    final titleLineFactor = ultraCompact ? 1.0 : 1.15;
    final hpRowLineFactor = ultraCompact ? 1.0 : 1.15;
    final titleGap = ultraCompact ? 1.0 : 2.0;
    final hpBarHeight = ultraCompact ? 6.0 : extraCompact ? 7.0 : 8.0;

    // BETA-BAT-007, accessibilité texte. Contrairement au panneau de commandes,
    // le HUD ne peut pas se contenter de multiplier ses tailles : ses hauteurs
    // de ligne en DÉRIVENT, le bloc titre est ancré en haut et la ligne HP en
    // bas, dans un rectangle de hauteur fixe. Mesuré avant d'écrire ce calcul :
    // à l'échelle maximale le nom recouvrait la barre d'HP sur les QUATRE
    // tailles de HUD certifiées, de 2.4 à 9.2 px.
    //
    // Le budget vertical est linéaire en l'échelle, donc le plafond se résout
    // sans itérer. Le bloc bas est pris à l'échelle demandée, ce qui rend le
    // plafond conservateur : il peut laisser un pixel inutilisé, jamais en
    // réclamer un de trop.
    //
    // Deux garanties tenues par la dernière ligne : agrandir n'est permis que
    // jusqu'à la boîte, et le plancher de 1.0 interdit à ce calcul de RÉDUIRE
    // une taille d'aujourd'hui — l'accessibilité ne doit pas rendre le HUD
    // moins lisible qu'avant elle.
    final topBlockPerUnitScale = (baseOwnerFontSize * ownerLineFactor) +
        (math.max(baseNameFontSize, baseLevelFontSize) * titleLineFactor);
    final hpRowPerUnitScale =
        math.max(baseHpLabelFontSize, baseHpValueFontSize) * hpRowLineFactor;
    final verticalRoom = hudRect.height -
        topPadding -
        bottomPadding -
        titleGap -
        _titleToHpRowGap;

    // La hauteur nécessaire croît strictement avec l'échelle, donc le plafond
    // est unique. Il se résout sans itérer, mais en DEUX branches, parce que le
    // bas de la boîte vaut `max(ligne HP, barre)` : selon l'échelle, c'est le
    // texte ou la barre de hauteur fixe qui commande.
    //
    // Une première version injectait l'échelle DEMANDÉE dans le bloc bas pour
    // rester conservatrice. Mesure à l'appui, c'était faux et pas seulement
    // approximatif : demander 1.6 rendait un texte PLUS PETIT que demander 1.2
    // (1.00 contre 1.07), puisque la demande rognait la place qu'elle
    // réclamait. Le plafond ne doit dépendre que de la boîte.
    final textDominatedCeiling =
        verticalRoom / (topBlockPerUnitScale + hpRowPerUnitScale);
    final barDominatedCeiling =
        (verticalRoom - hpBarHeight) / topBlockPerUnitScale;
    final geometricCeiling =
        hpRowPerUnitScale * textDominatedCeiling >= hpBarHeight
            ? textDominatedCeiling
            : barDominatedCeiling;
    final scale = requestedScale <= 1.0
        ? requestedScale
        : math.min(requestedScale, math.max(1.0, geometricCeiling));

    final ownerFontSize = baseOwnerFontSize * scale;
    final nameFontSize = baseNameFontSize * scale;
    final levelFontSize = baseLevelFontSize * scale;
    final statusFontSize = baseStatusFontSize * scale;
    final hpLabelFontSize = baseHpLabelFontSize * scale;
    final hpValueFontSize = baseHpValueFontSize * scale;
    final ownerHeight = ownerFontSize * ownerLineFactor;
    final titleHeight =
        math.max(nameFontSize, levelFontSize) * titleLineFactor;
    final statusHeight = statusFontSize * (ultraCompact ? 1.2 : 1.5);
    final hpRowHeight =
        math.max(hpLabelFontSize, hpValueFontSize) * hpRowLineFactor;

    final ownerRect = Rect.fromLTWH(
      hudRect.left + horizontalPadding,
      hudRect.top + topPadding,
      hudRect.width - (horizontalPadding * 2),
      ownerHeight,
    );

    final titleTop = ownerRect.bottom + titleGap;
    final innerRight = hudRect.right - horizontalPadding;
    final levelWidth = _measureSingleLineWidth(
          levelText,
          TextStyle(
            fontSize: levelFontSize,
            fontWeight: FontWeight.w800,
          ),
        ) +
        2;
    final levelRect = Rect.fromLTWH(
      innerRight - levelWidth,
      titleTop,
      levelWidth,
      titleHeight,
    );

    final normalizedGender = (genderSymbol?.trim().isEmpty ?? true)
        ? null
        : genderSymbol!.trim();
    final genderWidth = normalizedGender == null
        ? 0.0
        : _measureSingleLineWidth(
              normalizedGender,
              TextStyle(
                fontSize: nameFontSize * 0.9,
                fontWeight: FontWeight.w800,
              ),
            ) +
            2;
    final canShowGender = normalizedGender != null && !ultraCompact;
    final tentativeGenderRect = !canShowGender
        ? null
        : Rect.fromLTWH(
            levelRect.left - 4 - genderWidth,
            titleTop + ((titleHeight - (nameFontSize * 0.95)) / 2),
            genderWidth,
            nameFontSize * 0.95,
          );
    final tentativeNameRight =
        (tentativeGenderRect?.left ?? levelRect.left) - (canShowGender ? 4 : 6);
    final minimumPortraitNameWidth = ultraCompact ? 46.0 : 40.0;
    final genderRect = tentativeGenderRect != null &&
            tentativeNameRight - (hudRect.left + horizontalPadding) >=
                minimumPortraitNameWidth
        ? tentativeGenderRect
        : null;

    final nameRight =
        (genderRect?.left ?? levelRect.left) - (normalizedGender == null ? 6 : 4);
    final nameRect = Rect.fromLTWH(
      hudRect.left + horizontalPadding,
      titleTop,
      math.max(20, nameRight - (hudRect.left + horizontalPadding)),
      titleHeight,
    );

    final normalizedStatus = (statusText?.trim().isEmpty ?? true)
        ? null
        : statusText!.trim().toUpperCase();
    final tentativeStatusWidth = normalizedStatus == null
        ? 0.0
        : math.min(
            58.0,
            _measureSingleLineWidth(
                  normalizedStatus,
                  TextStyle(
                    fontSize: statusFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ) +
                14,
          );
    final statusTop = titleTop + titleHeight + 2;

    final hpRowTop = hudRect.bottom - bottomPadding - math.max(hpRowHeight, hpBarHeight);
    final fitsStatus = normalizedStatus != null &&
        !ultraCompact &&
        statusTop + statusHeight <= hpRowTop - _titleToHpRowGap &&
        tentativeStatusWidth <= hudRect.width * 0.28;
    final statusRect = fitsStatus
        ? Rect.fromLTWH(
            innerRight - tentativeStatusWidth,
            statusTop,
            tentativeStatusWidth,
            statusHeight,
          )
        : null;

    final hpLabelRect = Rect.fromLTWH(
      hudRect.left + horizontalPadding,
      hpRowTop,
      ultraCompact ? 18 : 20,
      hpRowHeight,
    );

    final shouldShowHpValue =
        isPlayerSide && !extraCompact && !ultraCompact && hudRect.width >= 210;
    final hpValueWidth = shouldShowHpValue
        ? _measureSingleLineWidth(
              hpValueText,
              TextStyle(
                fontSize: hpValueFontSize,
                fontWeight: FontWeight.w800,
              ),
            ) +
            2
        : 0.0;
    final hpValueRect = shouldShowHpValue
        ? Rect.fromLTWH(
            innerRight - hpValueWidth,
            hpRowTop,
            hpValueWidth,
            hpRowHeight,
          )
        : null;

    final hpBarLeft = hpLabelRect.right + 6;
    final hpBarRight = hpValueRect == null ? innerRight : hpValueRect.left - 8;
    final hpBarRect = Rect.fromLTWH(
      hpBarLeft,
      hpRowTop + ((hpRowHeight - hpBarHeight) / 2),
      math.max(ultraCompact ? 20 : 24, hpBarRight - hpBarLeft),
      hpBarHeight,
    );

    return BattleSceneHudLayout._(
      hudRect: hudRect,
      ownerRect: ownerRect,
      nameRect: nameRect,
      genderRect: genderRect,
      levelRect: levelRect,
      statusRect: statusRect,
      hpLabelRect: hpLabelRect,
      hpBarRect: hpBarRect,
      hpValueRect: hpValueRect,
      showsHpValue: shouldShowHpValue,
      ownerFontSize: ownerFontSize,
      nameFontSize: nameFontSize,
      levelFontSize: levelFontSize,
      statusFontSize: statusFontSize,
      hpLabelFontSize: hpLabelFontSize,
      hpValueFontSize: hpValueFontSize,
      effectiveTextScale: scale,
    );
  }
}

double _measureSingleLineWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}
