import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Les deux mouvements du dresseur adverse pendant l'intro.
enum BattleIntroTrainerMotion {
  /// Il entre par le bord opposé et rejoint la place de son Pokémon
  /// (parité `create_sprite_move_animation` : 0,8 s).
  enter,

  /// Il sort par son propre bord en lançant sa Ball (parité
  /// `create_enemy_send_animation` : 0,8 s, puis son Pokémon apparaît).
  exit,
}

/// Le sprite du dresseur adverse pendant l'intro — BETA-BAT-027.
///
/// Parité `enemy_sprites` + `create_enemy_send_animation` de la référence :
/// dans un combat de dresseur, ce n'est PAS le Pokémon qui glisse à l'entrée,
/// c'est le dresseur ; il rejoint la place de son Pokémon, annonce le défi,
/// puis quitte l'écran par la droite en envoyant sa Ball — et seulement là son
/// Pokémon apparaît.
///
/// Le composant tient sa propre horloge : un [motion] et sa durée, l'hôte le
/// monte et le laisse jouer. Il ne se retire pas seul — l'overlay le démonte
/// quand la sortie est finie, pour que le sprite reste affiché pendant les
/// messages qui suivent son entrée.
class BattleIntroTrainerComponent extends PositionComponent {
  BattleIntroTrainerComponent({
    required this.image,
    required Rect spriteRect,
    required this.offscreenDistancePx,
    int priority = 11,
  })  : _spriteRect = spriteRect,
        super(
          position: Vector2(spriteRect.left, spriteRect.top),
          size: Vector2(spriteRect.width, spriteRect.height),
          priority: priority,
        );

  final Image image;
  final Rect _spriteRect;

  /// La distance parcourue hors champ, de part et d'autre.
  final double offscreenDistancePx;

  BattleIntroTrainerMotion? _motion;
  var _elapsed = 0.0;
  var _duration = 0.0;
  var _offsetX = 0.0;

  /// Le dresseur attend hors champ, du côté de son entrée — avant le premier
  /// rendu, comme les combattants retenus.
  void holdOffscreen() {
    _motion = null;
    _elapsed = 0;
    _duration = 0;
    // Il entre par le bord OPPOSÉ au sien, comme le Pokémon sauvage : la
    // référence décale les sprites adverses de -360 px.
    _offsetX = -offscreenDistancePx;
    _applyOffset();
  }

  void play({
    required BattleIntroTrainerMotion motion,
    required double durationSeconds,
  }) {
    _motion = motion;
    _elapsed = 0;
    _duration = durationSeconds <= 0 ? 0.0001 : durationSeconds;
    if (motion == BattleIntroTrainerMotion.enter) {
      _offsetX = -offscreenDistancePx;
    } else {
      _offsetX = 0;
    }
    _applyOffset();
  }

  /// Vrai quand le mouvement courant est terminé.
  bool get isMotionComplete => _motion == null || _elapsed >= _duration;

  @override
  void update(double dt) {
    super.update(dt);
    final motion = _motion;
    if (motion == null) return;
    _elapsed += dt;
    final progress = (_elapsed / _duration).clamp(0.0, 1.0);
    _offsetX = switch (motion) {
      BattleIntroTrainerMotion.enter =>
        -offscreenDistancePx * (1 - progress),
      BattleIntroTrainerMotion.exit => offscreenDistancePx * progress,
    };
    _applyOffset();
    if (progress >= 1) {
      _motion = null;
    }
  }

  void _applyOffset() {
    position = Vector2(_spriteRect.left + _offsetX, _spriteRect.top);
  }

  @visibleForTesting
  double get debugOffsetX => _offsetX;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final scale = math.min(size.x / image.width, size.y / image.height);
    final destWidth = image.width * scale;
    final destHeight = image.height * scale;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(
        (size.x - destWidth) / 2,
        size.y - destHeight,
        destWidth,
        destHeight,
      ),
      Paint()..filterQuality = FilterQuality.none,
    );
  }
}
