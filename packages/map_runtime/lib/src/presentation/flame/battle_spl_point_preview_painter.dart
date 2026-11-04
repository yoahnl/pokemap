import 'dart:math' as math;
import 'dart:typed_data';
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
    this.directionStretch4096 = 0,
    this.scaleAxis = BattleSplPreviewScaleAxis.xy,
    this.polygonX = 0,
    this.polygonY = 0,
  }) : _textures = Map.unmodifiable(textures) {
    if (textures.isEmpty ||
        textures.length > 256 ||
        textures.keys.any((key) => key < 0 || key > 255) ||
        !pixelsPerUnit.isFinite ||
        pixelsPerUnit <= 0 ||
        pixelsPerUnit > 4096 ||
        aspectRatio4096 < 0 ||
        aspectRatio4096 > 32767 ||
        directionStretch4096 < 0 || directionStretch4096 > 65535 ||
        polygonX < -32768 || polygonX > 32767 ||
        polygonY < -32768 || polygonY > 32767) {
      throw const FormatException('Invalid SPL point preview settings');
    }
  }

  final Map<int, ui.Image> _textures;
  final double pixelsPerUnit;
  final int aspectRatio4096;
  final bool directionalParents;
  final bool directionalChildren;
  final int directionStretch4096;
  final BattleSplPreviewScaleAxis scaleAxis;
  final int polygonX;
  final int polygonY;

  void paint(
    ui.Canvas canvas, {
    required ui.Offset origin,
    required List<BattleSplPointParticle> particles,
    List<BattleSplProjectedParticle>? projections,
    List<List<ui.Offset>?>? polygons,
    List<BattleSplProjectedPolygon?>? clippedPolygons,
  }) {
    if (!origin.dx.isFinite ||
        !origin.dy.isFinite ||
        particles.length > 4096 ||
        (projections != null && projections.length != particles.length) ||
        (clippedPolygons != null && clippedPolygons.length != particles.length) ||
        (polygons != null && polygons.length != particles.length) ||
        (polygons != null && polygons.any((p) => p != null &&
            p.isNotEmpty && (p.length != 4 ||
                p.any((point) => !point.dx.isFinite || !point.dy.isFinite))))) {
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
              !value.direction.dy.isFinite ||
              !value.viewAlignment.isFinite ||
              value.viewAlignment < 0 || value.viewAlignment > 1,
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
      final baseHeight =
          base * (scaleAxis == BattleSplPreviewScaleAxis.x ? 1 : animatedScale);
      var height = baseHeight;
      if (directional && directionStretch4096 != 0) {
        final speed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z);
        final viewAlignment = projected?.viewAlignment ??
            (speed == 0 ? 0.0 : velocity.z.abs() / speed);
        height *= 1 + (1 - viewAlignment) * directionStretch4096 / 4096;
      }
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
      final polygon = polygons?[index];
      final clipped = clippedPolygons?[index];
      if (clipped != null) {
        if (clipped.positions.length < 3) continue;
        final vertices = ui.Vertices(
          ui.VertexMode.triangleFan,
          clipped.positions,
          textureCoordinates: [
            for (final uv in clipped.textureCoordinates)
              ui.Offset(uv.dx * image.width, uv.dy * image.height),
          ],
        );
        paint.shader = ui.ImageShader(image, ui.TileMode.clamp, ui.TileMode.clamp,
          Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 1]));
        canvas.drawVertices(vertices, ui.BlendMode.srcOver, paint);
        vertices.dispose();
        continue;
      }
      if (polygon != null) {
        if (polygon.isEmpty) continue;
        final matrix = _quadMatrix(polygon);
        if (matrix == null) continue;
        canvas.save();
        try {
          canvas.transform(matrix);
          canvas.drawImageRect(image,
              ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
              const ui.Rect.fromLTWH(0, 0, 1, 1), paint);
        } finally {
          canvas.restore();
        }
        continue;
      }
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
            center: particle.parentId == null
                ? ui.Offset(polygonX / 4096 * width / 2,
                    -polygonY / 4096 * height / 2)
                : ui.Offset.zero,
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

Float64List? _quadMatrix(List<ui.Offset> p) {
  final dx1 = p[1].dx - p[2].dx;
  final dx2 = p[3].dx - p[2].dx;
  final dx3 = p[0].dx - p[1].dx + p[2].dx - p[3].dx;
  final dy1 = p[1].dy - p[2].dy;
  final dy2 = p[3].dy - p[2].dy;
  final dy3 = p[0].dy - p[1].dy + p[2].dy - p[3].dy;
  final denominator = dx1 * dy2 - dx2 * dy1;
  if (denominator.abs() < 1e-9) return null;
  final g = (dx3 * dy2 - dx2 * dy3) / denominator;
  final h = (dx1 * dy3 - dx3 * dy1) / denominator;
  return Float64List.fromList([
    p[1].dx - p[0].dx + g * p[1].dx,
    p[1].dy - p[0].dy + g * p[1].dy,
    0, g,
    p[3].dx - p[0].dx + h * p[3].dx,
    p[3].dy - p[0].dy + h * p[3].dy,
    0, h,
    0, 0, 1, 0,
    p[0].dx, p[0].dy, 0, 1,
  ]);
}
