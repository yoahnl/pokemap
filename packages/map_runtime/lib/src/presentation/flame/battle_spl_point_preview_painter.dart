import 'dart:math' as math;
import 'dart:ui' as ui;

import 'battle_spl_camera_projection.dart';
import 'battle_spl_point_emitter_playback.dart';

enum BattleSplPreviewScaleAxis { xy, x, y }

final class BattleSplPointPreviewPainter {
  BattleSplPointPreviewPainter({
    required Map<int, ui.Image> textures,
    required this.pixelsPerUnit,
    required this.aspectRatio4096,
    this.directionalParents = false,
    this.directionalChildren = false,
    this.scaleAxis = BattleSplPreviewScaleAxis.xy,
  }) : _textures = Map.unmodifiable(textures) {
    if (textures.isEmpty ||
        textures.length > 256 ||
        textures.keys.any((key) => key < 0 || key > 255) ||
        !pixelsPerUnit.isFinite ||
        pixelsPerUnit <= 0 ||
        pixelsPerUnit > 4096 ||
        aspectRatio4096 < 0 ||
        aspectRatio4096 > 32767) {
      throw const FormatException('Invalid SPL point preview settings');
    }
  }

  final Map<int, ui.Image> _textures;
  final double pixelsPerUnit;
  final int aspectRatio4096;
  final bool directionalParents;
  final bool directionalChildren;
  final BattleSplPreviewScaleAxis scaleAxis;

  void paint(
    ui.Canvas canvas, {
    required ui.Offset origin,
    required List<BattleSplPointParticle> particles,
    List<BattleSplProjectedParticle>? projections,
  }) {
    if (!origin.dx.isFinite ||
        !origin.dy.isFinite ||
        particles.length > 4096 ||
        (projections != null && projections.length != particles.length)) {
      throw const FormatException('Invalid SPL point preview frame');
    }
    if (projections != null &&
        projections.any(
          (value) =>
              !value.position.dx.isFinite ||
              !value.position.dy.isFinite ||
              !value.scale.isFinite ||
              value.scale <= 0 ||
              !value.direction.dx.isFinite ||
              !value.direction.dy.isFinite,
        )) {
      throw const FormatException('Invalid SPL particle projection');
    }
    for (final particle in particles) {
      final color = particle.color;
      if (!_textures.containsKey(particle.texture) ||
          particle.baseScale4096 < 0 ||
          particle.scale4096 < 0 ||
          particle.alpha5 < 0 ||
          particle.alpha5 > 31 ||
          color.red < 0 ||
          color.red > 31 ||
          color.green < 0 ||
          color.green > 31 ||
          color.blue < 0 ||
          color.blue > 31) {
        throw const FormatException('Invalid SPL point preview particle');
      }
    }
    for (var index = 0; index < particles.length; index++) {
      final particle = particles[index];
      if (particle.alpha5 == 0 || particle.scale4096 == 0) continue;
      final image = _textures[particle.texture]!;
      final directional = particle.parentId == null ? directionalParents : directionalChildren;
      final velocity = particle.motion.velocity;
      final projected = projections?[index];
      final direction = projected?.direction;
      if (directional &&
          (direction == null
              ? velocity.x == 0 && velocity.y == 0
              : direction.dx == 0 && direction.dy == 0)) {
        continue;
      }
      final base = 2 * pixelsPerUnit * (particle.baseScale4096 / 4096);
      final animatedScale = particle.scale4096 / 4096;
      final height =
          base * (scaleAxis == BattleSplPreviewScaleAxis.x ? 1 : animatedScale);
      final width =
          base *
          (aspectRatio4096 / 4096) *
          (scaleAxis == BattleSplPreviewScaleAxis.y ? 1 : animatedScale);
      final color = particle.color;
      final paint = ui.Paint()
        ..filterQuality = ui.FilterQuality.none
        ..colorFilter = ui.ColorFilter.mode(
          ui.Color.fromARGB(
            particle.alpha5 * 255 ~/ 31,
            color.red * 255 ~/ 31,
            color.green * 255 ~/ 31,
            color.blue * 255 ~/ 31,
          ),
          ui.BlendMode.modulate,
        );
      canvas.save();
      try {
        if (projected == null) {
          canvas.translate(
            origin.dx +
                (particle.motion.position.x + particle.emitterPosition.x) /
                    4096 *
                    pixelsPerUnit,
            origin.dy -
                (particle.motion.position.y + particle.emitterPosition.y) /
                    4096 *
                    pixelsPerUnit,
          );
        } else {
          canvas.translate(projected.position.dx, projected.position.dy);
          canvas.scale(projected.scale);
          canvas.translate(origin.dx, origin.dy);
        }
        canvas.rotate(
          directional
              ? direction == null
                    ? math.atan2(velocity.x.toDouble(), velocity.y.toDouble())
                    : math.atan2(direction.dx, -direction.dy)
              : -particle.motion.rotation * 2 * math.pi / 65536,
        );
        canvas.drawImageRect(
          image,
          ui.Rect.fromLTWH(
            0,
            0,
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          ui.Rect.fromCenter(
            center: ui.Offset.zero,
            width: width,
            height: height,
          ),
          paint,
        );
      } finally {
        canvas.restore();
      }
    }
  }
}
