import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'battle_stat_sheet_manifest.dart';

/// L'aura d'un changement de stat — BETA-BAT-021.
///
/// Parité `UI::StatAnimation` : la planche de la référence est une grille de
/// 12 colonnes × 10 lignes (120 cellules) parcourue dans l'ordre de lecture,
/// d'un bloc, en 1,5 s. Le sprite est ancré au BAS du Pokémon visé, avec le
/// décalage de la référence (`x_offset` -2, `y_offset` +10).
///
/// TAILLE — recette du 2026-08-24 : « l'animation de baisse de stats est
/// vraiment trop petite et pas à la hauteur ».
///
/// Le `zoom = 0.75` de la référence s'applique à sa CELLULE de 200 px, dans
/// un écran de 320×240 (`display_config.json` du projet PSDK :
/// gameResolution 320×240, windowScale 2). L'aura y couvre donc 150 px —
/// une taille ABSOLUE, identique pour les deux camps, qui vaut 62,5 % de la
/// hauteur de l'écran de la référence.
///
/// Ce 62,5 % n'est PAS transposable tel quel : la scène de la référence est
/// en 4:3 et son Pokémon occupe la moitié de la hauteur, alors qu'ici le
/// même sprite en occupe un tiers en paysage et un neuvième en portrait —
/// mesuré. Appliquer la fraction d'écran donnerait 528 px d'aura pour un
/// Pokémon de 94 px en portrait. L'invariant retenu est donc celui que la
/// vidéo de recette montre : l'aura ENGLOBE le Pokémon et le dépasse, dans
/// le rapport de la référence ([_auraToPlayerSpriteRatio]), et elle garde la
/// même taille des deux côtés. La première version lisait 0,75 comme une
/// fraction de la hauteur du sprite VISÉ : deux fois trop petite, et l'aura
/// de l'ennemi rétrécissait avec son sprite sans que la référence ne le
/// fasse jamais.
///
/// Le composant se retire seul à la dernière cellule.
class BattleStatAuraComponent extends PositionComponent {
  BattleStatAuraComponent({
    required this.sheet,
    required Rect targetSpriteRect,
    required this.durationSeconds,
    required this.auraSize,
    int priority = 40,
  })  : _targetSpriteRect = targetSpriteRect,
        super(priority: priority);

  /// Le zoom de la référence, appliqué à sa cellule.
  static const double _referenceZoom = 0.75;

  /// Le côté d'une cellule dans l'écran de la référence.
  static const double _referenceCellSize = 200;

  /// Le côté de l'aura dans l'écran de la référence : 200 × 0,75.
  static const double referenceAuraSize = _referenceCellSize * _referenceZoom;

  /// Le rapport entre l'aura et le sprite du joueur, à appliquer par l'hôte.
  /// L'aura dépasse le Pokémon de moitié, comme dans la vidéo de recette.
  static const double auraToPlayerSpriteRatio = 1.55;

  /// Les décalages d'ancrage de la référence, en pixels de son écran 320×240.
  static const double _referenceOffsetX = -2;
  static const double _referenceOffsetY = 10;

  final Image sheet;
  final Rect _targetSpriteRect;
  final double durationSeconds;

  /// Le côté de l'aura à l'écran, en pixels de scène. L'hôte le tire du
  /// sprite du joueur — jamais du sprite visé, sinon l'aura de l'ennemi
  /// rétrécit.
  final double auraSize;

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

    // Les décalages de la référence sont en pixels de son écran : ils
    // suivent la taille de l'aura, pas celle du sprite visé.
    final destSize = auraSize;
    final offsetScale = auraSize / referenceAuraSize;
    final destWidth = destSize * (cellWidth / cellHeight);
    final center = Offset(
      _targetSpriteRect.center.dx + _referenceOffsetX * offsetScale,
      _targetSpriteRect.bottom +
          _referenceOffsetY * offsetScale -
          destSize / 2,
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

  /// Le côté de l'aura à l'écran, en pixels de scène.
  @visibleForTesting
  double get debugAuraSize => auraSize;
}
