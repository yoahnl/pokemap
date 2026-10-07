import 'dart:ui';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

enum SpatialCellOverlayKind { spawn, warp, collision }

final class SpatialCellOverlay {
  const SpatialCellOverlay({
    required this.id,
    required this.cell,
    required this.kind,
    required this.color,
  });
  final String id;
  final (int, int) cell;
  final SpatialCellOverlayKind kind;
  final Color color;
  @override
  bool operator ==(Object other) =>
      other is SpatialCellOverlay &&
      id == other.id &&
      cell == other.cell &&
      kind == other.kind &&
      color == other.color;
  @override
  int get hashCode => Object.hash(id, cell, kind, color);
}

Iterable<Mesh> spatialCellOverlayMeshes(
  MapSpatialScene scene,
  List<SpatialCellOverlay> overlays,
) sync* {
  final groups = <Color, ({List<Vertex> vertices, List<int> indices})>{};
  var vertexCount = 0;
  Mesh flush() {
    final mesh = Mesh();
    for (final entry in groups.entries) {
      mesh.addSurface(
        Surface(
          vertices: entry.value.vertices,
          indices: entry.value.indices,
          material: UnlitMaterial(albedoColor: entry.key),
        ),
      );
    }
    groups.clear();
    vertexCount = 0;
    return mesh;
  }

  for (final overlay in overlays) {
    final (x, z) = overlay.cell;
    if (x < 0 || z < 0 || x >= scene.width || z >= scene.depth) continue;
    final group = groups.putIfAbsent(
      overlay.color,
      () => (vertices: <Vertex>[], indices: <int>[]),
    );
    for (final bounds in [
      (0.04, 0.04, 0.96, 0.1),
      (0.04, 0.9, 0.96, 0.96),
      (0.04, 0.1, 0.1, 0.9),
      (0.9, 0.1, 0.96, 0.9),
    ]) {
      final base = group.vertices.length;
      for (final point in [
        (bounds.$1, bounds.$2),
        (bounds.$1, bounds.$4),
        (bounds.$3, bounds.$4),
        (bounds.$3, bounds.$2),
      ]) {
        final a = x + point.$1, b = z + point.$2;
        group.vertices.add(
          Vertex(
            position: Vector3(a, scene.worldHeightAt(a, b) + .035, b),
            texCoord: Vector2.zero(),
            color: overlay.color,
          ),
        );
      }
      group.indices.addAll([
        base,
        base + 1,
        base + 2,
        base,
        base + 2,
        base + 3,
      ]);
      vertexCount += 4;
    }
    if (vertexCount > 60000) yield flush();
  }
  if (vertexCount > 0) yield flush();
}
