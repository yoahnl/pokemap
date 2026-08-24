import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'battle_stat_sheet_manifest.dart';

/// L'aura d'un changement de stat — BETA-BAT-021.
///
/// Parité `UI::StatAnimation` : la planche de la référence est une grille de
/// 12 colonnes × 10 lignes (120 cellules) parcourue dans l'ordre de lecture,
/// d'un bloc, en 1,5 s. Le sprite est ancré au BAS du Pokémon visé, avec le
/// décalage de la référence (`x_offset` -2, `y_offset` +10, à l'échelle de la
/// scène) et son zoom de 0,75.
///
/// Le composant se retire seul à la dernière cellule.
class BattleStatAuraComponent extends PositionComponent {
  BattleStatAuraComponent({
    required this.sheet,
    required Rect targetSpriteRect,
    required this.durationSeconds,
    int priority = 40,
  })  : _targetSpriteRect = targetSpriteRect,
        super(priority: priority);

  /// Le zoom de la référence.
  static const double _referenceZoom = 0.75;

  /// Les décalages d'ancrage de la référence, en pixels de son écran 320×240.
  static const double _referenceOffsetX = -2;
  static const double _referenceOffsetY = 10;

  final Image sheet;
  final Rect _targetSpriteRect;
  final double durationSeconds;

  var _elapsed = 0.0;
  var _cellIndex = 0;
  var _removalScheduled = false;

  int get _cellCount => battleStatSheetColumns * battleStatSheetRows;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final progress = (_elapsed / durationSeconds).clamp(0.0, 1.0);
    _cellIndex = (progress * (_cellCount - 1)).floor().clamp(0, _cellCount - 1);
    if (progress >= 1 && !_removalScheduled) {
      _removalScheduled = true;
      // En microtask : se retirer en pleine itération updateTree muterait
      // l'arbre des composants pendant son parcours (le piège de BAT-016).
      Future<void>.microtask(removeFromParent);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final cellWidth = sheet.width / battleStatSheetColumns;
    final cellHeight = sheet.height / battleStatSheetRows;
    final column = _cellIndex % battleStatSheetColumns;
    final row = _cellIndex ~/ battleStatSheetColumns;

    // La planche de la référence est dessinée à la taille du Pokémon visé :
    // sa cellule couvre la boîte du sprite, au zoom de la référence.
    final destSize = _targetSpriteRect.height * _referenceZoom;
    final scale = destSize / cellHeight;
    final destWidth = cellWidth * scale;
    final center = Offset(
      _targetSpriteRect.center.dx + _referenceOffsetX * scale,
      _targetSpriteRect.bottom + _referenceOffsetY * scale - destSize / 2,
    );

    canvas.drawImageRect(
      sheet,
      Rect.fromLTWH(
        column * cellWidth,
        row * cellHeight,
        cellWidth,
        cellHeight,
      ),
      Rect.fromCenter(center: center, width: destWidth, height: destSize),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @visibleForTesting
  int get debugCellIndex => _cellIndex;
}
