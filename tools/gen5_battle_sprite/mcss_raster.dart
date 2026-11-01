import 'dart:math' as math;
import 'dart:typed_data';

import 'indexed_atlas.dart';
import 'mcss_geometry.dart';
import 'mcss_pose.dart';
import 'mcss_submission.dart';

({int xFx, int yFx, int zFx}) projectGen5McssCameraFx({
  required int poseEpoch,
  required int cameraEpoch,
  required List<int> positionFx,
  required List<int> cameraFx,
  required List<int> projectionFx,
}) {
  if (poseEpoch != cameraEpoch ||
      positionFx.length != 3 ||
      cameraFx.length != 16 ||
      projectionFx.length != 16 ||
      [
        ...positionFx,
        ...cameraFx,
        ...projectionFx,
      ].any((v) => v < -2147483648 || v > 2147483647)) {
    throw const FormatException('Invalid MCSS camera sample');
  }
  final min64 = -(BigInt.one << 63);
  final max64 = (BigInt.one << 63) - BigInt.one;
  final min32 = BigInt.from(-2147483648);
  final max32 = BigInt.from(2147483647);
  BigInt checked64(BigInt value) {
    if (value < min64 || value > max64) {
      throw const FormatException('MCSS camera fixed-point overflow');
    }
    return value;
  }

  int checked32(BigInt value) {
    if (value < min32 || value > max32) {
      throw const FormatException('MCSS camera fixed-point overflow');
    }
    return value.toInt();
  }

  final combined = List<int>.generate(16, (index) {
    final row = index ~/ 4;
    final column = index % 4;
    var sum = BigInt.zero;
    for (var k = 0; k < 4; k++) {
      sum = checked64(
        sum +
            BigInt.from(cameraFx[row * 4 + k]) *
                BigInt.from(projectionFx[k * 4 + column]),
      );
    }
    return checked32(sum >> 12);
  });
  final clip = List<int>.generate(4, (column) {
    var sum = BigInt.zero;
    for (var k = 0; k < 3; k++) {
      sum = checked64(
        sum +
            BigInt.from(positionFx[k]) * BigInt.from(combined[k * 4 + column]),
      );
    }
    return checked32((sum >> 12) + BigInt.from(combined[12 + column]));
  });
  if (clip[3] == 0) {
    throw const FormatException('Invalid MCSS camera projection w');
  }
  int divide(int numerator) {
    final quotient = checked64(
      (BigInt.from(numerator) << 32) ~/ BigInt.from(clip[3]),
    );
    return checked32(checked64(quotient + BigInt.from(0x80000)) >> 20);
  }

  return (
    xFx: checked32(BigInt.from(divide(clip[0])) * BigInt.from(128)),
    yFx: checked32(BigInt.from(divide(clip[1])) * BigInt.from(96)),
    zFx: checked32(-BigInt.from(clip[2])),
  );
}

({int x, int y}) projectGen5McssDsOrthoViewportFx({
  required int xFx,
  required int yFx,
}) {
  if (xFx < -2147483648 ||
      xFx > 2147483647 ||
      yFx < -2147483648 ||
      yFx > 2147483647) {
    throw const FormatException('Invalid DS orthographic coordinates');
  }
  final clipX = (xFx * 32) >> 12;
  final clipY = (yFx * 43) >> 12;
  if (clipX < -4096 || clipX > 4096 || clipY < -4096 || clipY > 4096) {
    throw const FormatException('DS orthographic clipping required');
  }
  return (x: (clipX + 4096) * 256 ~/ 8192, y: (4096 - clipY) * 192 ~/ 8192);
}

({double originY, double projectedScaleY}) approximateGen5McssDsOrthoY({
  required double idealOriginY,
  double viewportCenterY = 96,
}) {
  if (!idealOriginY.isFinite || !viewportCenterY.isFinite) {
    throw const FormatException('Invalid DS orthographic placement');
  }
  final originY =
      viewportCenterY + (idealOriginY - viewportCenterY) * 129 / 128;
  if (!originY.isFinite) {
    throw const FormatException('Invalid DS orthographic placement');
  }
  return (originY: originY, projectedScaleY: 129 / 128);
}

final class Gen5McssRaster {
  Gen5McssRaster._(this.width, this.height, Uint8List pixels)
    : indices = pixels.asUnmodifiableView();

  final int width, height;
  final Uint8List indices;

  Uint8List rgba(List<({int r, int g, int b})> palette) {
    if (palette.length != 16 ||
        palette.any(
          (c) => [c.r, c.g, c.b].any((channel) => channel < 0 || channel > 255),
        )) {
      throw const FormatException('Invalid MCSS raster palette');
    }
    final output = Uint8List(indices.length * 4);
    for (var i = 0; i < indices.length; i++) {
      final index = indices[i];
      if (index == 0) continue;
      final color = palette[index];
      output[i * 4] = color.r;
      output[i * 4 + 1] = color.g;
      output[i * 4 + 2] = color.b;
      output[i * 4 + 3] = 255;
    }
    return output;
  }
}

typedef Gen5McssDsUvAlignedQuad = ({
  int left,
  int top,
  int right,
  int bottom,
  int uLeft,
  int uRight,
  int vTop,
  int vBottom,
});

Gen5McssRaster rasterizeGen5McssDsUvAlignedLinearOpaque({
  required Gen5IndexedAtlas atlas,
  required int width,
  required int height,
  required List<Gen5McssDsUvAlignedQuad> frontToBack,
}) {
  if (width < 1 ||
      width > 256 ||
      height < 1 ||
      height > 192 ||
      frontToBack.length > 4096) {
    throw const FormatException('Invalid DS UV-aligned raster input');
  }
  var sampleBudget = 0;
  for (final quad in frontToBack) {
    if (quad.left < 0 ||
        quad.top < 0 ||
        quad.right > width ||
        quad.bottom > height ||
        quad.left >= quad.right ||
        quad.top >= quad.bottom ||
        [
          quad.uLeft,
          quad.uRight,
          quad.vTop,
          quad.vBottom,
        ].any((v) => v < -32768 || v > 32767)) {
      throw const FormatException('Invalid DS UV-aligned quad');
    }
    sampleBudget += (quad.right - quad.left) * (quad.bottom - quad.top);
    if (sampleBudget > 16777216) {
      throw const FormatException('DS UV-aligned raster sample limit exceeded');
    }
  }
  final output = Uint8List(width * height);
  int interpolate(int a, int b, int position, int length) => a <= b
      ? a + (b - a) * position ~/ length
      : b + (a - b) * (length - position) ~/ length;
  for (final quad in frontToBack) {
    final spanX = quad.right - quad.left;
    final spanY = quad.bottom - quad.top;
    for (var y = quad.top; y < quad.bottom; y++) {
      var ty =
          (interpolate(quad.vTop, quad.vBottom, y - quad.top, spanY) >> 4) %
          256;
      if (ty >= 128) ty = 255 - ty;
      for (var x = quad.left; x < quad.right; x++) {
        final target = y * width + x;
        if (output[target] != 0) continue;
        var tx =
            (interpolate(quad.uLeft, quad.uRight, x - quad.left, spanX) >> 4) %
            512;
        if (tx >= 256) tx = 511 - tx;
        output[target] = atlas.indices[ty * 256 + tx];
      }
    }
  }
  return Gen5McssRaster._(width, height, output);
}

Gen5McssRaster rasterizeGen5McssOpaque({
  required Gen5IndexedAtlas atlas,
  required List<Gen5McssActiveNode> nodes,
  required int width,
  required int height,
  required double originX,
  required double originY,
  double spriteScaleX = 16,
  double spriteScaleY = 16,
  double projectedScaleY = 1,
  bool reverse = false,
}) {
  if (width < 1 ||
      width > 1024 ||
      height < 1 ||
      height > 1024 ||
      nodes.length > 4096 ||
      !originX.isFinite ||
      !originY.isFinite ||
      !spriteScaleX.isFinite ||
      !spriteScaleY.isFinite ||
      !projectedScaleY.isFinite) {
    throw const FormatException('Invalid MCSS raster input');
  }

  final output = Uint8List(width * height);
  final submissions = planGen5McssSubmission(
    nodes,
    alpha: 31,
    reverse: reverse,
    ortho: true,
  );
  var sampleBudget = 0;
  for (final submission in submissions) {
    final quad = submission.quad;
    if (quad.width < 0 || quad.height < 0) {
      throw const FormatException('Invalid MCSS quad size');
    }
    if (quad.width == 0 || quad.height == 0) continue;
    final corners = gen5McssOrthoCorners(
      nodes[submission.nodeIndex].node,
      quad,
      spriteScaleX: spriteScaleX,
      spriteScaleY: spriteScaleY,
    );
    final points = corners
        .map((p) => (x: originX + p.x, y: originY - p.y * projectedScaleY))
        .toList(growable: false);
    if (points.any((p) => !p.x.isFinite || !p.y.isFinite)) {
      throw const FormatException('Invalid MCSS raster coordinates');
    }
    final minX = points.map((p) => p.x).reduce(math.min);
    final maxX = points.map((p) => p.x).reduce(math.max);
    final minY = points.map((p) => p.y).reduce(math.min);
    final maxY = points.map((p) => p.y).reduce(math.max);
    if (maxX <= 0 || maxY <= 0 || minX >= width || minY >= height) {
      continue;
    }
    final left = math.max(0, minX.floor());
    final right = math.min(width, maxX.ceil());
    final top = math.max(0, minY.floor());
    final bottom = math.min(height, maxY.ceil());
    sampleBudget += (right - left) * (bottom - top);
    if (sampleBudget > 16777216) {
      throw const FormatException('MCSS raster sample limit exceeded');
    }

    final start = points[0];
    final horizontalX = points[3].x - start.x;
    final horizontalY = points[3].y - start.y;
    final verticalX = points[1].x - start.x;
    final verticalY = points[1].y - start.y;
    final determinant = horizontalX * verticalY - horizontalY * verticalX;
    if (!determinant.isFinite) {
      throw const FormatException('Invalid MCSS raster transform');
    }
    if (determinant == 0) continue;
    final textureX = gen5McssTextureX(quad, mirrored: spriteScaleX < 0) / 4096;
    final textureY = submission.textureY / 4096;
    final textureWidth = quad.width / 4096;
    final textureHeight = quad.height / 4096;

    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final target = y * width + x;
        if (output[target] != 0) continue;
        final dx = x + 0.5 - start.x;
        final dy = y + 0.5 - start.y;
        final u = (dx * verticalY - dy * verticalX) / determinant;
        final v = (horizontalX * dy - horizontalY * dx) / determinant;
        if (u < 0 || u >= 1 || v < 0 || v >= 1) continue;
        var tx = (textureX + u * textureWidth).floor() % 512;
        var ty = (textureY + v * textureHeight).floor() % 256;
        if (tx >= 256) tx = 511 - tx;
        if (ty >= 128) ty = 255 - ty;
        output[target] = atlas.indices[ty * 256 + tx];
      }
    }
  }
  return Gen5McssRaster._(width, height, output);
}
