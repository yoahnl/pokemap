import 'dart:typed_data';

import 'indexed_atlas.dart';

typedef Gen5McssDsRotatedVertex = ({int x, int y, int u, int v, int w});

final class Gen5McssDsRotatedRaster {
  Gen5McssDsRotatedRaster._(Uint8List indices, Uint8List alpha)
    : indices = indices.asUnmodifiableView(),
      alpha = alpha.asUnmodifiableView();

  final Uint8List indices;
  final Uint8List alpha;
}

Gen5McssDsRotatedRaster rasterizeGen5McssDsRotatedQuad({
  required Gen5IndexedAtlas atlas,
  required int width,
  required int height,
  required List<Gen5McssDsRotatedVertex> vertices,
}) {
  if (width < 1 ||
      width > 256 ||
      height < 1 ||
      height > 192 ||
      vertices.length != 4) {
    throw const FormatException('Invalid rotated DS raster input');
  }
  final w = vertices.first.w;
  if (w <= 0 ||
      w > 2147483647 ||
      w & 0x7f != 0 ||
      vertices.any(
        (p) =>
            p.x < 0 ||
            p.x > width ||
            p.y < 0 ||
            p.y > height ||
            p.u < -32768 ||
            p.u > 32767 ||
            p.v < -32768 ||
            p.v > 32767 ||
            p.w != w,
      )) {
    throw const FormatException('Unsupported rotated DS quad');
  }
  var winding = 0;
  for (var i = 0; i < 4; i++) {
    final a = vertices[i];
    final b = vertices[(i + 1) % 4];
    final c = vertices[(i + 2) % 4];
    final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
    if (cross == 0 || (winding != 0 && cross.sign != winding)) {
      throw const FormatException('Rotated DS quad must be strictly convex');
    }
    winding = cross.sign;
  }
  var top = 0;
  var bottom = 0;
  for (var i = 1; i < 4; i++) {
    if (vertices[i].y < vertices[top].y) top = i;
    if (vertices[i].y > vertices[bottom].y ||
        (vertices[i].y == vertices[bottom].y &&
            vertices[i].x > vertices[bottom].x)) {
      bottom = i;
    }
  }
  final indices = Uint8List(width * height);
  final alpha = Uint8List(width * height);
  final leftStep = winding < 0 ? 1 : -1;
  var left = top;
  var right = top;
  for (var y = vertices[top].y; y < vertices[bottom].y; y++) {
    var nextLeft = (left + leftStep) % 4;
    var nextRight = (right - leftStep) % 4;
    while (y >= vertices[nextLeft].y && left != bottom) {
      left = nextLeft;
      nextLeft = (left + leftStep) % 4;
    }
    while (y >= vertices[nextRight].y && right != bottom) {
      right = nextRight;
      nextRight = (right - leftStep) % 4;
    }
    final leftEdge = _DsEdge(vertices[left], vertices[nextLeft], y, false);
    final rightEdge = _DsEdge(vertices[right], vertices[nextRight], y, true);
    var x0 = leftEdge.x;
    var x1 = rightEdge.x;
    if (rightEdge.increment == 0 &&
        (leftEdge.increment != 0 || x0 != x1) &&
        x1 != 0) {
      x1--;
    }
    final swapped = x0 > x1;
    final first = swapped ? rightEdge : leftEdge;
    final last = swapped ? leftEdge : rightEdge;
    if (swapped) {
      final old = x0;
      x0 = x1;
      x1 = old;
    }
    final firstCoverage = first.coverage(swapped);
    final lastCoverage = last.coverage(swapped);
    final leftEnd = (x0 + firstCoverage.length).clamp(x0, x1 + 1);
    final rightStart = (x1 - lastCoverage.length + 1).clamp(leftEnd, x1 + 1);
    final leftU = first.interpolate((p) => p.u);
    final leftV = first.interpolate((p) => p.v);
    final rightU = last.interpolate((p) => p.u);
    final rightV = last.interpolate((p) => p.v);
    for (var x = x0; x <= x1; x++) {
      final coverage = x < leftEnd
          ? firstCoverage.at(x - x0, false)
          : x >= rightStart
          ? lastCoverage.at(x - rightStart, true)
          : 31;
      if (coverage == 0 || x < 0 || x >= width || y < 0 || y >= height)
        continue;
      var u = (_linear(leftU, rightU, x - x0, x1 + 1 - x0) >> 4) % 512;
      var v = (_linear(leftV, rightV, x - x0, x1 + 1 - x0) >> 4) % 256;
      if (u >= 256) u = 511 - u;
      if (v >= 128) v = 255 - v;
      final index = atlas.indices[v * 256 + u];
      if (index == 0) continue;
      indices[y * width + x] = index;
      alpha[y * width + x] = coverage;
    }
  }
  return Gen5McssDsRotatedRaster._(indices, alpha);
}

int _linear(int a, int b, int position, int length) {
  if (length == 0 || a == b) return a;
  return a < b
      ? a + (b - a) * position ~/ length
      : b + (a - b) * (length - position) ~/ length;
}

final class _DsEdge {
  _DsEdge(this.from, this.to, this.y, this.right) {
    final deltaX = to.x - from.x;
    final deltaY = to.y - from.y;
    if (deltaY <= 0) throw const FormatException('Invalid rotated DS edge');
    negative = deltaX < 0;
    final lengthX = deltaX.abs();
    increment = deltaY == lengthX && lengthX != 1
        ? 0x40000
        : (deltaX * (0x40000 ~/ deltaY)).abs();
    xMajor = increment > 0x40000;
    final int startDistance;
    if (right) {
      startDistance = xMajor
          ? (negative ? 0x60000 : increment - 0x20000)
          : (increment != 0 && negative ? 0x40000 : 0);
    } else {
      startDistance = xMajor
          ? (negative ? increment + 0x20000 : 0x20000)
          : (increment != 0 && negative ? 0x40000 : 0);
    }
    distance = startDistance + (y - from.y) * increment;
    final minimum = from.x < to.x ? from.x : to.x;
    final maximum = from.x == to.x
        ? from.x
        : (from.x > to.x ? from.x : to.x) - 1;
    x = (negative ? from.x - (distance >> 18) : from.x + (distance >> 18))
        .clamp(minimum, maximum);
    offset = increment >= 0x40000 && right != negative ? 1 : 0;
  }

  final Gen5McssDsRotatedVertex from;
  final Gen5McssDsRotatedVertex to;
  final int y;
  final bool right;
  late final bool negative;
  late final bool xMajor;
  late final int increment;
  late final int distance;
  late final int x;
  late final int offset;

  int interpolate(int Function(Gen5McssDsRotatedVertex) value) =>
      _linear(value(from), value(to), y - from.y + offset, to.y - from.y);

  _DsCoverage coverage(bool swapped) {
    if (!xMajor) {
      if (increment == 0) return _DsCoverage(1, swapped ? 0 : 31, 0, false);
      var value = ((distance >> 9) + (increment >> 10)) >> 4;
      if (value >> 5 != distance >> 18) value = 31;
      value &= 31;
      if (swapped ? right != negative : right == negative) value = 31 - value;
      return _DsCoverage(1, value, 0, false);
    }
    var length = right != negative
        ? (distance >> 18) - ((distance - increment) >> 18)
        : ((distance + increment) >> 18) - (distance >> 18);
    final span = (to.x - from.x).abs();
    var start = distance >> 18;
    if (negative) start = span - start;
    if (right) start = start - length + 1;
    final value = (((start << 10) + 0x1ff) * (to.y - from.y) ~/ span) & 0x3ff;
    final step = ((to.y - from.y) << 10) ~/ span;
    if (swapped) length = 1;
    return _DsCoverage(length, value == 0x3ff ? 0 : value, step, true);
  }
}

final class _DsCoverage {
  _DsCoverage(this.length, this.value, this.step, this.xMajor);

  final int length;
  final int value;
  final int step;
  final bool xMajor;

  int at(int position, bool right) {
    if (!xMajor) return value;
    final coverage = (value + position * step) >> 5;
    return right ? (31 - coverage).clamp(0, 31) : coverage.clamp(0, 31);
  }
}
