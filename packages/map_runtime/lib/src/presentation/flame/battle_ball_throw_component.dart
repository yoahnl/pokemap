import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:map_battle/map_battle.dart';

import 'battle_animation_plan.dart';

/// La Poké Ball d'un envoi ou d'un rappel — BETA-BAT-022.
///
/// Composant autonome : monté par l'overlay pour la durée exacte du
/// [PlayBallSequenceStep], il joue le vol en arc (cellules 0-3 de la planche
/// 1×32, 0,5 s, parité `scalar_offset SQUARE010` : montée de 64 px et
/// redescente) puis l'ouverture (cellules 4-5, 0,1 s), appelle [onOpen] au
/// moment de l'ouverture (le SE et le grossissement du Pokémon s'y
/// alignent) et se retire seul. Les emplois posés (adversaire, rappel)
/// sautent le vol : 0,2 s d'attente puis l'ouverture.
class BattleBallThrowComponent extends PositionComponent {
  BattleBallThrowComponent({
    required this.sheet,
    required this.kind,
    required Offset targetCenter,
    required double throwStartX,
    this.cellSize = 26,
    this.onOpen,
    int priority = 50,
  })  : _targetCenter = targetCenter,
        _throwStartX = throwStartX,
        super(
          position: Vector2(targetCenter.dx, targetCenter.dy),
          anchor: Anchor.center,
          priority: priority,
        );

  static const int _cellRows = 32;
  static const double _throwSeconds = 0.5;
  static const double _openSeconds = 0.1;
  static const double _heldWaitSeconds = 0.2;
  static const double _arcHeightPx = 64;

  final Image sheet;
  final BattleBallSequenceKind kind;
  final Offset _targetCenter;
  final double _throwStartX;

  /// La taille de rendu d'une cellule en pixels logiques de la scène.
  final double cellSize;

  final void Function()? onOpen;

  var _elapsed = 0.0;
  var _openNotified = false;
  var _removalScheduled = false;
  var _cellIndex = 3;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final throwSeconds =
        kind == BattleBallSequenceKind.sendOutThrown ? _throwSeconds : 0.0;
    final waitSeconds =
        kind == BattleBallSequenceKind.sendOutThrown ? 0.0 : _heldWaitSeconds;

    if (_elapsed < waitSeconds) {
      _cellIndex = 3;
      position = Vector2(_targetCenter.dx, _targetCenter.dy);
      return;
    }
    if (_elapsed < waitSeconds + throwSeconds) {
      final progress =
          ((_elapsed - waitSeconds) / throwSeconds).clamp(0.0, 1.0);
      // Parité `SQUARE010_DISTORTION` : 0 aux extrémités, 1 au sommet.
      final lift = 1 - math.pow(2 * progress - 1, 2).toDouble();
      position = Vector2(
        _throwStartX + (_targetCenter.dx - _throwStartX) * progress,
        _targetCenter.dy - _arcHeightPx * lift,
      );
      _cellIndex = (progress * 4).floor().clamp(0, 3);
      return;
    }
    position = Vector2(_targetCenter.dx, _targetCenter.dy);
    if (!_openNotified) {
      _openNotified = true;
      onOpen?.call();
    }
    final openProgress =
        ((_elapsed - waitSeconds - throwSeconds) / _openSeconds)
            .clamp(0.0, 1.0);
    _cellIndex = (openProgress * 2).floor().clamp(0, 1) + 4;
    if (openProgress >= 1 && !_removalScheduled) {
      _removalScheduled = true;
      // En microtask : se retirer en pleine itération updateTree muterait
      // l'arbre des composants pendant son parcours (le piège de BAT-016).
      Future<void>.microtask(removeFromParent);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final cellHeight = sheet.height / _cellRows;
    final cellWidth = sheet.width.toDouble();
    canvas.drawImageRect(
      sheet,
      Rect.fromLTWH(0, _cellIndex * cellHeight, cellWidth, cellHeight),
      Rect.fromCenter(
        center: Offset.zero,
        width: cellSize,
        height: cellSize,
      ),
      Paint()..filterQuality = FilterQuality.none,
    );
  }
}

/// Le point de départ du lancer côté joueur : hors champ à gauche pour le
/// joueur, hors champ à droite pour l'adversaire — la parité de la Ball qui
/// part de la main du dresseur.
double ballThrowStartXFor({
  required BattleSideId side,
  required double viewportWidth,
}) {
  return side == BattleSideId.player ? -32 : viewportWidth + 32;
}
