import 'dart:ui';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/resources.dart';

import 'package:map_core/map_core.dart';

import 'spatial_scene_view.dart';

const _overlayBundle =
    'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle';

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
  final material = UnlitMaterial(albedoColor: color)
    ..vertexShader = VertexShader.fromAsset(
      _overlayBundle,
      entryPoint: 'SelectionOverlayVertex',
      slots: ['VertexInfo', 'JointMatrices'],
    )
    ..fragmentShader = FragmentShader.fromAsset(
      _overlayBundle,
      entryPoint: 'SelectionOverlayFragment',
      slots: ['albedoTexture', 'Material'],
    );
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

Set<String> spatialSelectedIds(
  SpatialSceneView view,
  SpatialSceneContentKind kind,
) => {
  for (final hit in [?view.selectedContent, ...view.additionalSelectedContent])
    if (hit.kind == kind) hit.id,
};

bool spatialSameSelection(SpatialSceneView before, SpatialSceneView after) {
  final first = [?before.selectedContent, ...before.additionalSelectedContent];
  final second = [?after.selectedContent, ...after.additionalSelectedContent];
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index].kind != second[index].kind ||
        first[index].id != second[index].id) {
      return false;
    }
  }
  return true;
}

Map<String, Model3dVector3> spatialModelPreviews(SpatialSceneView view) => {
  for (final preview in [
    ?view.contentPreview,
    ...view.additionalContentPreviews,
  ])
    if (preview.kind == SpatialSceneContentKind.model)
      preview.id: preview.position,
};
