import 'dart:ui';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/resources.dart';

Iterable<(Vector3, Vector3)> spatialSelectionEdges(
  Vector3 minimum,
  Vector3 maximum,
  double padding,
) sync* {
  final low = minimum - Vector3.all(padding);
  final high = maximum + Vector3.all(padding);
  for (var axis = 0; axis < 3; axis++) {
    final first = (axis + 1) % 3;
    final second = (axis + 2) % 3;
    for (final a in [low[first], high[first]]) {
      for (final b in [low[second], high[second]]) {
        final start = low.clone()
          ..[first] = a
          ..[second] = b;
        final end = start.clone()..[axis] = high[axis];
        yield (start, end);
      }
    }
  }
}

List<MeshComponent> spatialSelectionFrame(
  Vector3 minimum,
  Vector3 maximum,
  double thickness,
  Color color,
) {
  final material = UnlitMaterial(albedoColor: color);
  return [
    for (final (start, end) in spatialSelectionEdges(
      minimum,
      maximum,
      thickness,
    ))
      MeshComponent(
        position: (start + end) / 2,
        mesh: CuboidMesh(
          size: end - start + Vector3.all(thickness),
          material: material,
        ),
      ),
  ];
}
