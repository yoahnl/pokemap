import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'contracts/map_workspace_visuals.dart';

class TerrainSpatialRenderSurface extends StatelessWidget {
  const TerrainSpatialRenderSurface({
    super.key,
    required this.map,
    required this.project,
    required this.sources,
    required this.controls,
    required this.errorBuilder,
    this.onCell,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
  });

  final MapData map;
  final ProjectManifest project;
  final SpatialWorkspaceVisuals sources;
  final SpatialSceneController controls;
  final Widget Function(BuildContext, Object) errorBuilder;
  final void Function(int, int)? onCell;
  final bool Function(int, int, SpatialSceneContentHit?)? onDragStart;
  final ValueChanged<(int, int)>? onDragUpdate;
  final VoidCallback? onDragEnd, onDragCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SpatialSceneView(
      scene: map.spatialScene!,
      models: project.models3d,
      loadModel: sources.readModel,
      controller: controls,
      onCell: onCell ?? (_, _) {},
      selectContent: false,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onDragCancel: onDragCancel,
      groundMap: map,
      groundProject: project,
      loadGroundImage: sources.readGroundImage,
      background: colors.surfaceContainerLowest,
      ground: colors.surfaceContainerHigh,
      edge: colors.outlineVariant,
      errorBuilder: errorBuilder,
    );
  }
}
