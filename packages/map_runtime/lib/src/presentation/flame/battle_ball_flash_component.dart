import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Le flash d'ouverture d'une Poké Ball — BETA-BAT-031.
///
/// Recette du 2026-08-24 : « l'ouverture de la pokéball que tu as fait est
/// bien, mais ça manque de l'espèce de flash jolie ». Dans la vidéo de
/// référence (Pokémon Platine), l'ouverture projette un éclat blanc très bref
/// au point d'apparition, juste avant que le Pokémon ne prenne forme.
///
/// Un halo radial qui s'ouvre vite et s'éteint : plein éclat sur le premier
/// tiers, puis extinction. Le composant se retire seul.
class BattleBallFlashComponent extends PositionComponent {
  BattleBallFlashComponent({
    required Offset center,
    required this.radiusPx,
    this.durationSeconds = 0.28,
    int priority = 45,
  }) : super(
          position: Vector2(center.dx, center.dy),
          anchor: Anchor.center,
          priority: priority,
        );

  /// Le rayon du halo à son plein éclat.
  final double radiusPx;
  final double durationSeconds;

  var _elapsed = 0.0;
  var _removalScheduled = false;

  /// La progression du flash, de 0 à 1.
  double get _progress =>
      (_elapsed / (durationSeconds <= 0 ? 0.0001 : durationSeconds))
          .clamp(0.0, 1.0);

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_progress >= 1 && !_removalScheduled) {
      _removalScheduled = true;
      // En microtask : se retirer en pleine itération updateTree muterait
      // l'arbre des composants pendant son parcours (le piège de BAT-016).
      Future<void>.microtask(removeFromParent);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = _progress;
    // L'éclat s'ouvre sur le premier tiers, puis s'éteint : la référence
    // frappe fort et court.
    final intensity = progress < 0.33
        ? progress / 0.33
        : 1 - ((progress - 0.33) / 0.67);
    if (intensity <= 0) return;
    final radius = radiusPx * (0.45 + 0.55 * progress);
    final alpha = (intensity.clamp(0.0, 1.0) * 235).round();
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = Gradient.radial(
          Offset.zero,
          radius,
          <Color>[
            Color.fromARGB(alpha, 255, 255, 255),
            Color.fromARGB((alpha * 0.72).round(), 255, 249, 214),
            const Color(0x00FFF4C8),
          ],
          <double>[0.0, 0.45, 1.0],
        ),
    );
  }

  @visibleForTesting
  double get debugProgress => _progress;
}
