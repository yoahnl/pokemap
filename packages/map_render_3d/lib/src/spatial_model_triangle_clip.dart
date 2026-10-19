final class SpatialModelClipRect {
  const SpatialModelClipRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left, top, right, bottom;
}

final class SpatialModelClipVertex {
  const SpatialModelClipVertex({
    required this.x,
    required this.y,
    required this.z,
    required this.u,
    required this.v,
    this.r = 1,
    this.g = 1,
    this.b = 1,
    this.a = 1,
    this.normal,
  });

  final double x, y, z, u, v, r, g, b, a;
  final ({double x, double y, double z})? normal;
}

final class SpatialModelTriangleClipResult<T> {
  SpatialModelTriangleClipResult({
    required Iterable<SpatialModelClipVertex> vertices,
    required Iterable<int> indices,
    required this.material,
  }) : vertices = List.unmodifiable(vertices),
       indices = List.unmodifiable(indices);

  final List<SpatialModelClipVertex> vertices;
  final List<int> indices;
  final T material;
}

SpatialModelTriangleClipResult<T> clipSpatialModelTriangles<T>({
  required List<SpatialModelClipVertex> vertices,
  required List<int> indices,
  required T material,
  required SpatialModelClipRect clip,
  List<double> nodeTransform = const [
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ],
  int maximumInputVertices = 65535,
  int maximumInputTriangles = 200000,
  int maximumOutputVertices = 65535,
  int maximumOutputTriangles = 200000,
}) {
  if (maximumInputVertices < 1 ||
      maximumInputTriangles < 1 ||
      maximumOutputVertices < 1 ||
      maximumOutputVertices > 65535 ||
      maximumOutputTriangles < 1) {
    throw const FormatException('Invalid model clip geometry budgets.');
  }
  if (![
        clip.left,
        clip.top,
        clip.right,
        clip.bottom,
      ].every((v) => v.isFinite) ||
      clip.left >= clip.right ||
      clip.top >= clip.bottom) {
    throw const FormatException(
      'Model clipping requires a finite XZ rectangle.',
    );
  }
  if (vertices.length > maximumInputVertices ||
      indices.length % 3 != 0 ||
      indices.length ~/ 3 > maximumInputTriangles ||
      indices.any((index) => index < 0 || index >= vertices.length)) {
    throw const FormatException(
      'Invalid or over-budget input triangle geometry.',
    );
  }
  if (nodeTransform.length != 16 ||
      nodeTransform.any((value) => !value.isFinite) ||
      nodeTransform[3] != 0 ||
      nodeTransform[7] != 0 ||
      nodeTransform[11] != 0 ||
      nodeTransform[15] != 1) {
    throw const FormatException(
      'Model clipping requires a finite affine matrix.',
    );
  }
  final m = nodeTransform;
  final determinant =
      m[0] * (m[5] * m[10] - m[9] * m[6]) -
      m[4] * (m[1] * m[10] - m[9] * m[2]) +
      m[8] * (m[1] * m[6] - m[5] * m[2]);
  if (!determinant.isFinite || determinant == 0) {
    throw const FormatException(
      'Model clipping requires a nonsingular matrix.',
    );
  }
  final hasNormals = vertices.firstOrNull?.normal != null;
  final points = <_ClipPoint>[];
  for (final vertex in vertices) {
    final normal = vertex.normal;
    if (![
          vertex.x,
          vertex.y,
          vertex.z,
          vertex.u,
          vertex.v,
          vertex.r,
          vertex.g,
          vertex.b,
          vertex.a,
        ].every((v) => v.isFinite) ||
        [vertex.r, vertex.g, vertex.b, vertex.a].any((v) => v < 0 || v > 1) ||
        (normal != null) != hasNormals ||
        normal != null &&
            ![normal.x, normal.y, normal.z].every((v) => v.isFinite)) {
      throw const FormatException(
        'Invalid source vertex attributes for clipping.',
      );
    }
    final point = _ClipPoint(
      vertex,
      m[0] * vertex.x + m[4] * vertex.y + m[8] * vertex.z + m[12],
      m[1] * vertex.x + m[5] * vertex.y + m[9] * vertex.z + m[13],
      m[2] * vertex.x + m[6] * vertex.y + m[10] * vertex.z + m[14],
    );
    if (![point.x, point.y, point.z].every((v) => v.isFinite)) {
      throw const FormatException('Transformed clip positions must be finite.');
    }
    points.add(point);
  }
  final resultVertices = <SpatialModelClipVertex>[];
  final resultIndices = <int>[];
  final vertexIndices =
      <
        (
          double,
          double,
          double,
          double,
          double,
          double,
          double,
          double,
          double,
          ({double x, double y, double z})?,
        ),
        int
      >{};

  int appendVertex(SpatialModelClipVertex vertex) {
    final key = (
      vertex.x,
      vertex.y,
      vertex.z,
      vertex.u,
      vertex.v,
      vertex.r,
      vertex.g,
      vertex.b,
      vertex.a,
      vertex.normal,
    );
    final existing = vertexIndices[key];
    if (existing != null) return existing;
    if (resultVertices.length >= maximumOutputVertices) {
      throw const FormatException(
        'Clipped geometry exceeds the vertex budget.',
      );
    }
    final index = resultVertices.length;
    vertexIndices[key] = index;
    resultVertices.add(vertex);
    return index;
  }

  final planes = [
    (axis: 0, boundary: clip.left, sign: 1.0),
    (axis: 0, boundary: clip.right, sign: -1.0),
    (axis: 2, boundary: clip.top, sign: 1.0),
    (axis: 2, boundary: clip.bottom, sign: -1.0),
  ];
  for (var index = 0; index < indices.length; index += 3) {
    var polygon = [
      points[indices[index]],
      points[indices[index + 1]],
      points[indices[index + 2]],
    ];
    for (final plane in planes) {
      if (polygon.isEmpty) break;
      polygon = _clipPolygon(polygon, plane);
    }
    for (var triangle = 1; triangle + 1 < polygon.length; triangle++) {
      final a = polygon[0], b = polygon[triangle], c = polygon[triangle + 1];
      final abX = b.x - a.x, abY = b.y - a.y, abZ = b.z - a.z;
      final acX = c.x - a.x, acY = c.y - a.y, acZ = c.z - a.z;
      final cross = [
        abY * acZ - abZ * acY,
        abZ * acX - abX * acZ,
        abX * acY - abY * acX,
      ];
      if (cross.any((value) => !value.isFinite)) {
        throw const FormatException(
          'Clipped triangle area exceeds numeric range.',
        );
      }
      if (cross.every((value) => value == 0)) continue;
      if (resultIndices.length ~/ 3 >= maximumOutputTriangles) {
        throw const FormatException(
          'Clipped geometry exceeds the triangle budget.',
        );
      }
      resultIndices.addAll([
        appendVertex(a.vertex),
        appendVertex(b.vertex),
        appendVertex(c.vertex),
      ]);
    }
  }
  return SpatialModelTriangleClipResult(
    vertices: resultVertices,
    indices: resultIndices,
    material: material,
  );
}

final class _ClipPoint {
  const _ClipPoint(this.vertex, this.x, this.y, this.z);
  final SpatialModelClipVertex vertex;
  final double x, y, z;
}

List<_ClipPoint> _clipPolygon(
  List<_ClipPoint> polygon,
  ({int axis, double boundary, double sign}) plane,
) {
  final result = <_ClipPoint>[];
  double distance(_ClipPoint point) =>
      ((plane.axis == 0 ? point.x : point.z) - plane.boundary) * plane.sign;
  var previous = polygon.last;
  var previousDistance = distance(previous);
  for (final current in polygon) {
    final currentDistance = distance(current);
    if (!previousDistance.isFinite || !currentDistance.isFinite) {
      throw const FormatException('Clip plane distances exceed numeric range.');
    }
    if ((previousDistance >= 0) != (currentDistance >= 0)) {
      final denominator = previousDistance - currentDistance;
      final t = previousDistance / denominator;
      if (!t.isFinite || !denominator.isFinite || t < 0 || t > 1) {
        throw const FormatException('Invalid model clip edge intersection.');
      }
      double blend(double a, double b) {
        if (a == b || t == 0) return a;
        if (t == 1) return b;
        return (1 - t) * a + t * b;
      }

      final a = previous.vertex, b = current.vertex;
      final an = a.normal, bn = b.normal;
      final vertex = SpatialModelClipVertex(
        x: blend(a.x, b.x),
        y: blend(a.y, b.y),
        z: blend(a.z, b.z),
        u: blend(a.u, b.u),
        v: blend(a.v, b.v),
        r: blend(a.r, b.r),
        g: blend(a.g, b.g),
        b: blend(a.b, b.b),
        a: blend(a.a, b.a),
        normal: an == null || bn == null
            ? null
            : (
                x: blend(an.x, bn.x),
                y: blend(an.y, bn.y),
                z: blend(an.z, bn.z),
              ),
      );
      result.add(
        _ClipPoint(
          vertex,
          plane.axis == 0 ? plane.boundary : blend(previous.x, current.x),
          blend(previous.y, current.y),
          plane.axis == 2 ? plane.boundary : blend(previous.z, current.z),
        ),
      );
    }
    if (currentDistance >= 0) result.add(current);
    previous = current;
    previousDistance = currentDistance;
  }
  return result;
}
