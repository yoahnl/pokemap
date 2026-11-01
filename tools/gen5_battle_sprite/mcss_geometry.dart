import 'dart:math' as math;

import 'mcss_bin.dart';
import 'multicell.dart';

List<({double x, double y, double z, double w})> gen5McssPerspectiveClipCorners(
  Gen5ActiveNode node,
  Gen5McssQuad quad, {
  required List<double> position,
  required List<double> billboard,
  required List<double> viewProjection,
  double spriteScaleX = 1,
  double spriteScaleY = 1,
  double scaleOffsetX = 1,
  double scaleOffsetY = 1,
  double nodeOffsetScale = 1,
  int rotationOffset = 0,
  int depth = 0,
}) {
  if (position.length != 3 ||
      billboard.length != 9 ||
      viewProjection.length != 16 ||
      [
        ...position,
        ...billboard,
        ...viewProjection,
        spriteScaleX,
        spriteScaleY,
        scaleOffsetX,
        scaleOffsetY,
        nodeOffsetScale,
      ].any((v) => !v.isFinite)) {
    throw const FormatException('Invalid MCSS perspective input');
  }
  final parent = node.parentFrame;
  final angle = -(parent.rotation + rotationOffset) * 2 * math.pi / 65536;
  final c = math.cos(angle);
  final s = math.sin(angle);
  final tx = parent.translateX * nodeOffsetScale / 16;
  final ty = -parent.translateY * nodeOffsetScale / 16;
  return List.unmodifiable(
    gen5McssLocalCorners(node, quad, mirrored: spriteScaleX < 0).map((p) {
      final x = p.x * parent.scaleX / 4096 * spriteScaleX * scaleOffsetX;
      final y = p.y * parent.scaleY / 4096 * spriteScaleY * scaleOffsetY;
      final bx = tx + x * c - y * s;
      final by = ty + x * s + y * c;
      final bz = depth / 4096;
      final world = <double>[
        position[0] + bx * billboard[0] + by * billboard[3] + bz * billboard[6],
        position[1] + bx * billboard[1] + by * billboard[4] + bz * billboard[7],
        position[2] + bx * billboard[2] + by * billboard[5] + bz * billboard[8],
      ];
      double component(int column) =>
          world[0] * viewProjection[column] +
          world[1] * viewProjection[4 + column] +
          world[2] * viewProjection[8 + column] +
          viewProjection[12 + column];
      return (
        x: component(0),
        y: component(1),
        z: component(2),
        w: component(3),
      );
    }),
  );
}

List<({double x, double y})> gen5McssOrthoCorners(
  Gen5ActiveNode node,
  Gen5McssQuad quad, {
  double spriteScaleX = 1,
  double spriteScaleY = 1,
  double scaleOffsetX = 1,
  double scaleOffsetY = 1,
  int rotationOffset = 0,
}) {
  if (!spriteScaleX.isFinite ||
      !spriteScaleY.isFinite ||
      !scaleOffsetX.isFinite ||
      !scaleOffsetY.isFinite) {
    throw const FormatException('Unsupported MCSS sprite scale');
  }
  final parent = node.parentFrame;
  final baseX = spriteScaleX * scaleOffsetX;
  final baseY = spriteScaleY * scaleOffsetY;
  final tx = parent.translateX * baseX / 16;
  final ty = -parent.translateY * baseY / 16;
  final angle = -(parent.rotation + rotationOffset) * 2 * math.pi / 65536;
  final c = math.cos(angle);
  final s = math.sin(angle);
  return List.unmodifiable(
    gen5McssLocalCorners(node, quad, mirrored: spriteScaleX < 0).map((p) {
      final x = p.x * parent.scaleX / 4096 * baseX;
      final y = p.y * parent.scaleY / 4096 * baseY;
      return (x: tx + x * c - y * s, y: ty + x * s + y * c);
    }),
  );
}

({double x, double y, double z}) gen5McssProjectAnchor(
  List<double> position,
  List<double> viewProjection,
) {
  if (position.length != 3 ||
      viewProjection.length != 16 ||
      position.any((v) => !v.isFinite) ||
      viewProjection.any((v) => !v.isFinite)) {
    throw const FormatException('Invalid MCSS projection input');
  }
  double component(int column) =>
      position[0] * viewProjection[column] +
      position[1] * viewProjection[4 + column] +
      position[2] * viewProjection[8 + column] +
      viewProjection[12 + column];
  final w = component(3);
  if (w == 0 || !w.isFinite)
    throw const FormatException('Invalid MCSS projection w');
  return (
    x: component(0) / w * 128,
    y: component(1) / w * 96,
    z: -component(2),
  );
}

List<({double x, double y})> gen5McssLocalCorners(
  Gen5ActiveNode node,
  Gen5McssQuad quad, {
  bool mirrored = false,
}) {
  final frame = node.localFrame;
  final angle = -frame.rotation * 2 * math.pi / 65536;
  final cosAngle = math.cos(angle);
  final sinAngle = math.sin(angle);
  final translationX = (frame.translateX + node.record.x) / 16;
  final translationY = -(frame.translateY + node.record.y) / 16;
  final x = quad.x / 4096;
  final y = quad.y / 4096;
  final width = quad.width / 65536;
  final height = quad.height / 65536;
  final result = <({double x, double y})>[];
  for (final (px, py) in [
    (x + (mirrored ? width : 0), y),
    (x + (mirrored ? width : 0), y - height),
    (x + (mirrored ? 0 : width), y - height),
    (x + (mirrored ? 0 : width), y),
  ]) {
    final sx = px * frame.scaleX / 4096;
    final sy = py * frame.scaleY / 4096;
    result.add((
      x: translationX + sx * cosAngle - sy * sinAngle,
      y: translationY + sx * sinAngle + sy * cosAngle,
    ));
  }
  return List.unmodifiable(result);
}

int gen5McssTextureX(Gen5McssQuad quad, {required bool mirrored}) =>
    mirrored ? 512 * 4096 - quad.textureX - quad.width : quad.textureX;

({double left, double top, double right, double bottom}) gen5McssLocalBounds(
  Gen5ActiveNode node,
  List<Gen5McssQuad> quads,
) {
  if (quads.isEmpty) throw const FormatException('No MCSS quads');
  var left = double.infinity;
  var top = double.infinity;
  var right = double.negativeInfinity;
  var bottom = double.negativeInfinity;
  for (final quad in quads) {
    for (final point in gen5McssLocalCorners(node, quad)) {
      left = math.min(left, point.x);
      top = math.min(top, point.y);
      right = math.max(right, point.x);
      bottom = math.max(bottom, point.y);
    }
  }
  return (left: left, top: top, right: right, bottom: bottom);
}
