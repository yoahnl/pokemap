import 'dart:math' as math;

import 'package:flutter/painting.dart';

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

  factory BattleSceneHudLayout.forBounds({
    required Rect hudRect,
    required bool isPlayerSide,
    required String speciesText,
    String? genderSymbol,
    required String levelText,
    required String hpValueText,
    String? statusText,
  }) {
    final compact = hudRect.width <= 220 || hudRect.height <= 74;
    final extraCompact = hudRect.width <= 170 || hudRect.height <= 68;

    final horizontalPadding = extraCompact ? 10.0 : 14.0;
    final topPadding = extraCompact ? 10.0 : 12.0;
    final bottomPadding = extraCompact ? 10.0 : 12.0;
    final ownerFontSize = extraCompact ? 8.0 : compact ? 9.0 : 10.0;
    final nameFontSize = extraCompact ? 12.0 : compact ? 14.0 : 16.0;
    final levelFontSize = extraCompact ? 12.0 : compact ? 14.0 : 15.0;
    final statusFontSize = extraCompact ? 8.0 : 9.0;
    final hpLabelFontSize = extraCompact ? 10.0 : 11.0;
    final hpValueFontSize = extraCompact ? 10.0 : compact ? 11.0 : 12.0;
    final ownerHeight = ownerFontSize * 1.2;
    final titleHeight = math.max(nameFontSize, levelFontSize) * 1.15;
    final statusHeight = statusFontSize * 1.5;
    final hpRowHeight = math.max(hpLabelFontSize, hpValueFontSize) * 1.15;
    final hpBarHeight = extraCompact ? 7.0 : 8.0;

    final ownerRect = Rect.fromLTWH(
      hudRect.left + horizontalPadding,
      hudRect.top + topPadding,
      hudRect.width - (horizontalPadding * 2),
      ownerHeight,
    );

    final titleTop = ownerRect.bottom + 2;
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
    final genderRect = normalizedGender == null
        ? null
        : Rect.fromLTWH(
            levelRect.left - 4 - genderWidth,
            titleTop + ((titleHeight - (nameFontSize * 0.95)) / 2),
            genderWidth,
            nameFontSize * 0.95,
          );

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
        statusTop + statusHeight <= hpRowTop - 4 &&
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
      20,
      hpRowHeight,
    );

    final shouldShowHpValue = isPlayerSide && !extraCompact && hudRect.width >= 190;
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
      math.max(24, hpBarRight - hpBarLeft),
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
    );
  }
}

double _measureSingleLineWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}
