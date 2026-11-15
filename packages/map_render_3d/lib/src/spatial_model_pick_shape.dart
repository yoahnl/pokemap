import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'glb_renderer_layout.dart';
import 'spatial_model_source_admission.dart';
import 'spatial_pixel_material.dart';

const _stride = 19;
const _maximumTriangles = 200000;
const _maximumSamples = 4000000;
const _maximumSamplesPerEdge = 64;
const _sampleInset = .001;

final _shapes = Expando<_CachedPickShape>('spatial-model-pick-shape');

final class _CachedPickShape {
  const _CachedPickShape(this.shape);
  final SpatialModelPickShape? shape;
}

SpatialModelPickShape? spatialModelPickShape(Model model) =>
    (_shapes[model] ??= _CachedPickShape(_buildPickShape(model))).shape;

final class SpatialModelPickShape {
  SpatialModelPickShape._(this._triangles, this._masks, this.bounds);

  final Float64List _triangles;
  final List<_AlphaMask?> _masks;
  final Model3dBounds bounds;

  int get triangleCount => _triangles.length ~/ _stride;

  double? rayDistance(Vector3 origin, Vector3 direction) {
    double? nearest;
    final t = _triangles;
    for (var base = 0; base < t.length; base += _stride) {
      final hit = _rayTriangle(origin, direction, t, base);
      if (hit == null || (nearest != null && hit.$1 >= nearest)) continue;
      final mask = _masks[t[base + 18].toInt()];
      if (mask != null) {
        final w = 1 - hit.$2 - hit.$3;
        final visible = mask.visible(
          t[base + 9] * w + t[base + 11] * hit.$2 + t[base + 13] * hit.$3,
          t[base + 10] * w + t[base + 12] * hit.$2 + t[base + 14] * hit.$3,
          t[base + 15] * w + t[base + 16] * hit.$2 + t[base + 17] * hit.$3,
        );
        if (!visible) continue;
      }
      nearest = hit.$1;
    }
    return nearest;
  }
}

final class _AlphaMask {
  _AlphaMask(Texture texture, this.material)
    : pixels = texture.sourceData,
      width = texture.width,
      height = texture.height;

  final ByteData pixels;
  final int width, height;
  final SpatialPixelMaterial material;

  bool get valid =>
      width > 0 && height > 0 && pixels.lengthInBytes >= width * height * 4;

  bool visible(double u, double v, double vertexAlpha) {
    final x = (_wrap(u, material.wrapS) * width).floor().clamp(0, width - 1);
    final y = (_wrap(v, material.wrapT) * height).floor().clamp(0, height - 1);
    final texel = pixels.getUint8((y * width + x) * 4 + 3) / 255;
    return switch (material.alphaMode) {
      Model3dAlphaMode.mask =>
        texel * material.albedoColor.a * vertexAlpha >= material.alphaCutoff,
      Model3dAlphaMode.blend =>
        texel * material.albedoColor.a * vertexAlpha >= .1,
      _ => texel >= material.alphaCutoff,
    };
  }

  static double _wrap(double value, int mode) => switch (mode) {
    33071 => value.clamp(0.0, 1.0),
    33648 => 1 - (value % 2 - 1).abs(),
    _ => value - value.floorToDouble(),
  };
}

SpatialModelPickShape? _buildPickShape(Model model) {
  final issues = spatialModelClipSourceIssues(model);
  if (issues == null || issues.isNotEmpty) return null;
  if (model.nodes.values.any((node) => node.joints.isNotEmpty)) return null;
  final masks = <_AlphaMask?>[null];
  final maskIndices = <SpatialPixelMaterial, int>{};
  var triangleCount = 0;
  for (final node in model.nodes.values) {
    for (final surface in node.mesh?.surfaces ?? const <Surface>[]) {
      if (surface is! SpatialModelSurface) return null;
      triangleCount += surface.indices.length ~/ 3;
      final material = surface.material;
      if (material is! SpatialPixelMaterial ||
          material.alphaMode == Model3dAlphaMode.opaque ||
          maskIndices.containsKey(material)) {
        continue;
      }
      final mask = _AlphaMask(material.albedoTexture, material);
      if (!mask.valid) return null;
      maskIndices[material] = masks.length;
      masks.add(mask);
    }
  }
  if (maskIndices.isEmpty || triangleCount > _maximumTriangles) return null;
  final builder = _ShapeBuilder(triangleCount);
  final processed = model.processNodes(AnimationState());
  for (final entry in model.nodes.entries) {
    final transform = processed[entry.key]!.combinedTransform;
    for (final raw in entry.value.mesh?.surfaces ?? const <Surface>[]) {
      final surface = raw as SpatialModelSurface;
      final maskIndex = maskIndices[surface.material] ?? 0;
      if (!builder.addSurface(
        surface,
        transform,
        maskIndex,
        masks[maskIndex],
      )) {
        return null;
      }
    }
  }
  return builder.build(masks);
}

final class _ShapeBuilder {
  _ShapeBuilder(int capacity) : _triangles = Float64List(capacity * _stride);

  final Float64List _triangles;
  var _length = 0, _samples = 0;
  var _minX = double.infinity, _minY = double.infinity;
  var _minZ = double.infinity, _maxX = double.negativeInfinity;
  var _maxY = double.negativeInfinity, _maxZ = double.negativeInfinity;

  bool addSurface(
    SpatialModelSurface surface,
    Matrix4 transform,
    int maskIndex,
    _AlphaMask? mask,
  ) {
    final vertices = surface.clipVertices;
    final points = [
      for (final vertex in vertices)
        transform.transform3(Vector3(vertex.x, vertex.y, vertex.z)),
    ];
    final indices = surface.indices;
    for (var index = 0; index + 2 < indices.length; index += 3) {
      final corners = [indices[index], indices[index + 1], indices[index + 2]];
      final base = _length;
      for (final (slot, corner) in corners.indexed) {
        final point = points[corner];
        final vertex = vertices[corner];
        _triangles
          ..[base + slot * 3] = point.x
          ..[base + slot * 3 + 1] = point.y
          ..[base + slot * 3 + 2] = point.z
          ..[base + 9 + slot * 2] = vertex.u
          ..[base + 10 + slot * 2] = vertex.v
          ..[base + 15 + slot] = vertex.a;
      }
      _triangles[base + 18] = maskIndex.toDouble();
      if (mask == null) {
        for (var slot = 0; slot < 3; slot++) {
          _include(base + slot * 3);
        }
        _length += _stride;
      } else {
        final kept = _sampleVisible(base, mask);
        if (kept == null) return false;
        if (kept) _length += _stride;
      }
    }
    return true;
  }

  bool? _sampleVisible(int base, _AlphaMask mask) {
    final t = _triangles;
    var texels = 0.0;
    for (var slot = 0; slot < 3; slot++) {
      final next = (slot + 1) % 3;
      final du = (t[base + 9 + next * 2] - t[base + 9 + slot * 2]) * mask.width;
      final dv =
          (t[base + 10 + next * 2] - t[base + 10 + slot * 2]) * mask.height;
      texels = math.max(texels, math.sqrt(du * du + dv * dv));
    }
    final steps = texels.ceil().clamp(2, _maximumSamplesPerEdge);
    _samples += (steps + 1) * (steps + 2) ~/ 2;
    if (_samples > _maximumSamples) return null;
    var visible = false;
    for (var i = 0; i <= steps; i++) {
      for (var j = 0; j <= steps - i; j++) {
        final b1 = (i / steps) * (1 - _sampleInset) + _sampleInset / 3;
        final b2 = (j / steps) * (1 - _sampleInset) + _sampleInset / 3;
        final b0 = 1 - b1 - b2;
        double mix(int offset, int width) =>
            t[base + offset] * b0 +
            t[base + offset + width] * b1 +
            t[base + offset + width * 2] * b2;
        if (!mask.visible(mix(9, 2), mix(10, 2), mix(15, 1))) continue;
        visible = true;
        _includePoint(mix(0, 3), mix(1, 3), mix(2, 3));
      }
    }
    return visible;
  }

  void _include(int offset) => _includePoint(
    _triangles[offset],
    _triangles[offset + 1],
    _triangles[offset + 2],
  );

  void _includePoint(double x, double y, double z) {
    _minX = math.min(_minX, x);
    _minY = math.min(_minY, y);
    _minZ = math.min(_minZ, z);
    _maxX = math.max(_maxX, x);
    _maxY = math.max(_maxY, y);
    _maxZ = math.max(_maxZ, z);
  }

  SpatialModelPickShape build(List<_AlphaMask?> masks) {
    final empty = _length == 0;
    return SpatialModelPickShape._(
      Float64List.fromList(Float64List.sublistView(_triangles, 0, _length)),
      List.unmodifiable(masks),
      Model3dBounds(
        min: empty
            ? Model3dVector3(x: 0, y: 0, z: 0)
            : Model3dVector3(x: _minX, y: _minY, z: _minZ),
        max: empty
            ? Model3dVector3(x: 0, y: 0, z: 0)
            : Model3dVector3(x: _maxX, y: _maxY, z: _maxZ),
      ),
    );
  }
}

(double, double, double)? _rayTriangle(
  Vector3 origin,
  Vector3 direction,
  Float64List t,
  int base,
) {
  final ax = t[base], ay = t[base + 1], az = t[base + 2];
  final e1x = t[base + 3] - ax, e1y = t[base + 4] - ay, e1z = t[base + 5] - az;
  final e2x = t[base + 6] - ax, e2y = t[base + 7] - ay, e2z = t[base + 8] - az;
  final px = direction.y * e2z - direction.z * e2y;
  final py = direction.z * e2x - direction.x * e2z;
  final pz = direction.x * e2y - direction.y * e2x;
  final determinant = e1x * px + e1y * py + e1z * pz;
  if (determinant.abs() < 1e-12) return null;
  final inverse = 1 / determinant;
  final sx = origin.x - ax, sy = origin.y - ay, sz = origin.z - az;
  final u = (sx * px + sy * py + sz * pz) * inverse;
  if (u < 0 || u > 1) return null;
  final qx = sy * e1z - sz * e1y;
  final qy = sz * e1x - sx * e1z;
  final qz = sx * e1y - sy * e1x;
  final v = (direction.x * qx + direction.y * qy + direction.z * qz) * inverse;
  if (v < 0 || u + v > 1) return null;
  final distance = (e2x * qx + e2y * qy + e2z * qz) * inverse;
  return distance >= 0 ? (distance, u, v) : null;
}
