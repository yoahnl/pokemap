import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'glb_renderer_layout.dart';
import 'spatial_model_source_admission.dart';
import 'spatial_model_triangle_clip.dart';

final class SpatialClippedModel {
  const SpatialClippedModel({
    required this.model,
    required this.bounds,
    required this.retainedBytes,
  });

  final Model model;
  final Model3dBounds bounds;
  final int retainedBytes;
}

final class SpatialClippedModelCache {
  SpatialClippedModelCache({
    this.maximumRetainedBytes = 8 * 1024 * 1024,
    this.maximumEntries = 512,
    this.maximumInputVertices = 1000000,
    this.maximumInputTriangles = 1000000,
    this.maximumOutputVertices = 65535,
    this.maximumOutputTriangles = 200000,
  }) {
    if (maximumRetainedBytes < 1 ||
        maximumEntries < 1 ||
        maximumInputVertices < 1 ||
        maximumInputTriangles < 1 ||
        maximumOutputVertices < 1 ||
        maximumOutputVertices > 65535 ||
        maximumOutputTriangles < 1) {
      throw const FormatException('Invalid clipped model cache budgets.');
    }
  }

  final int maximumRetainedBytes, maximumEntries;
  final int maximumInputVertices, maximumInputTriangles;
  final int maximumOutputVertices, maximumOutputTriangles;
  final _sourceIds = Expando<int>('spatial-clip-cache-source');
  final _entries =
      <(int, double, double, double, double), SpatialClippedModel?>{};
  final _sourceEntries = <int, Set<(int, double, double, double, double)>>{};
  int _nextSourceId = 0, _hits = 0, _misses = 0, _retainedBytes = 0;

  int get hits => _hits;
  int get misses => _misses;
  int get retainedBytes => _retainedBytes;
  int get entryCount => _entries.length;

  SpatialClippedModel? resolve(Model source, SpatialModelClipRect clip) {
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
    final issues = spatialModelClipSourceIssues(source);
    if (issues == null ||
        issues.isNotEmpty ||
        source.animations.isNotEmpty ||
        source.nodes.values.any((node) => node.joints.isNotEmpty)) {
      throw FormatException(
        'Static model clipping is unavailable: '
        '${issues?.join(', ') ?? 'unqualified_source'}.',
      );
    }
    final sourceId = _sourceIds[source] ??= _nextSourceId++;
    final key = (sourceId, clip.left, clip.top, clip.right, clip.bottom);
    if (_entries.containsKey(key)) {
      _hits++;
      final value = _entries.remove(key);
      _entries[key] = value;
      return value;
    }
    _misses++;
    final value = _build(source, clip);
    final bytes = value?.retainedBytes ?? 0;
    if (bytes > maximumRetainedBytes) {
      throw const FormatException(
        'A clipped model exceeds the retained geometry budget.',
      );
    }
    while (_entries.isNotEmpty &&
        (_entries.length >= maximumEntries ||
            _retainedBytes + bytes > maximumRetainedBytes)) {
      final oldest = _entries.keys.first;
      _retainedBytes -= _entries.remove(oldest)?.retainedBytes ?? 0;
      final sourceEntries = _sourceEntries[oldest.$1]!;
      sourceEntries.remove(oldest);
      if (sourceEntries.isEmpty) _sourceEntries.remove(oldest.$1);
    }
    _entries[key] = value;
    (_sourceEntries[sourceId] ??= {}).add(key);
    _retainedBytes += bytes;
    return value;
  }

  void clear() {
    _entries.clear();
    _sourceEntries.clear();
    _retainedBytes = 0;
  }

  void releaseSource(Model source) {
    final id = _sourceIds[source];
    if (id == null) return;
    for (final key in _sourceEntries.remove(id) ?? const {}) {
      _retainedBytes -= _entries.remove(key)?.retainedBytes ?? 0;
    }
  }

  SpatialClippedModel? _build(Model source, SpatialModelClipRect clip) {
    var inputVertices = 0, inputTriangles = 0;
    for (final node in source.nodes.values) {
      for (final surface in node.mesh?.surfaces ?? const <Surface>[]) {
        inputVertices += surface.vertexCount;
        inputTriangles += surface.indices.length ~/ 3;
      }
    }
    if (inputVertices > maximumInputVertices ||
        inputTriangles > maximumInputTriangles) {
      throw const FormatException(
        'Source model exceeds clipping input budgets.',
      );
    }
    final processed = source.processNodes(AnimationState());
    final nodes = <int, ModelNode>{};
    var outputVertices = 0, outputTriangles = 0, bytes = 0;
    var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    var maxZ = double.negativeInfinity;
    for (final entry in source.nodes.entries) {
      final node = entry.value;
      final transform = processed[entry.key]!.combinedTransform;
      final mesh = Mesh();
      for (final raw in node.mesh?.surfaces ?? const <Surface>[]) {
        if (raw is! SpatialModelSurface) {
          throw const FormatException(
            'Model clipping requires retained source vertex attributes.',
          );
        }
        final cut = clipSpatialModelTriangles(
          vertices: raw.clipVertices,
          indices: raw.indices,
          material: raw.material,
          clip: clip,
          nodeTransform: transform.storage,
          maximumInputVertices: maximumInputVertices,
          maximumInputTriangles: maximumInputTriangles,
          maximumOutputVertices: math.max(
            1,
            maximumOutputVertices - outputVertices,
          ),
          maximumOutputTriangles: math.max(
            1,
            maximumOutputTriangles - outputTriangles,
          ),
        );
        if (cut.indices.isEmpty) continue;
        outputVertices += cut.vertices.length;
        outputTriangles += cut.indices.length ~/ 3;
        if (outputVertices > maximumOutputVertices ||
            outputTriangles > maximumOutputTriangles) {
          throw const FormatException(
            'Clipped model exceeds output geometry budgets.',
          );
        }
        final surface = SpatialModelSurface(
          vertices: [
            for (final vertex in cut.vertices)
              Vertex(
                position: Vector3(vertex.x, vertex.y, vertex.z),
                texCoord: Vector2(vertex.u, vertex.v),
                color: Color.from(
                  red: vertex.r,
                  green: vertex.g,
                  blue: vertex.b,
                  alpha: vertex.a,
                ),
                normal: vertex.normal == null
                    ? null
                    : Vector3(
                        vertex.normal!.x,
                        vertex.normal!.y,
                        vertex.normal!.z,
                      ),
              ),
          ],
          indices: cut.indices,
          material: cut.material,
          materialIndex: raw.materialIndex,
        );
        bytes += surface.retainedGeometryBytes;
        if (bytes > maximumRetainedBytes) {
          throw const FormatException(
            'Clipped model exceeds the retained geometry budget.',
          );
        }
        for (var index = 0; index < surface.vertexCount; index++) {
          final position = transform.transform3(
            Vector3.array(surface.positions, index * 3),
          );
          minX = math.min(minX, position.x);
          maxX = math.max(maxX, position.x);
          minY = math.min(minY, position.y);
          maxY = math.max(maxY, position.y);
          minZ = math.min(minZ, position.z);
          maxZ = math.max(maxZ, position.z);
        }
        mesh.addSurface(surface);
      }
      nodes[entry.key] = ModelNode(
        name: node.name,
        nodeIndex: node.nodeIndex,
        parentNodeIndex: node.parentNodeIndex,
        transform: Matrix4.copy(node.transform),
        mesh: mesh.surfaces.isEmpty ? null : mesh,
        joints: const {},
      );
    }
    if (outputTriangles == 0) return null;
    final model = Model(nodes: Map.unmodifiable(nodes), animations: const []);
    inheritSpatialModelClipSource(source, model);
    return SpatialClippedModel(
      model: model,
      bounds: Model3dBounds(
        min: Model3dVector3(x: minX, y: minY, z: minZ),
        max: Model3dVector3(x: maxX, y: maxY, z: maxZ),
      ),
      retainedBytes: bytes,
    );
  }
}
