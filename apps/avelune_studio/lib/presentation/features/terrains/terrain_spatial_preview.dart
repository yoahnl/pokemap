import 'package:avelune_studio/platform/rendering/terrain_spatial_render_surface.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../shared/widgets/feedback/studio_notice.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';

class TerrainSpatialPreview extends StatefulWidget {
  const TerrainSpatialPreview({
    super.key,
    required this.map,
    required this.project,
    required this.visuals,
    this.onCell,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
  });
  final MapData map;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final void Function(int, int)? onCell;
  final bool Function(int, int, SpatialSceneContentHit?)? onDragStart;
  final ValueChanged<(int, int)>? onDragUpdate;
  final VoidCallback? onDragEnd, onDragCancel;

  @override
  State<TerrainSpatialPreview> createState() => _TerrainSpatialPreviewState();
}

class _TerrainSpatialPreviewState extends State<TerrainSpatialPreview> {
  final controls = SpatialSceneController();

  @override
  void dispose() {
    controls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visuals = widget.visuals;
    if (visuals is! SpatialWorkspaceVisuals) {
      return const StudioNotice('Aperçu 3D indisponible');
    }
    final sources = visuals as SpatialWorkspaceVisuals;
    return TerrainSpatialRenderSurface(
      map: widget.map,
      project: widget.project,
      sources: sources,
      controls: controls,
      onCell: widget.onCell,
      onDragStart: widget.onDragStart,
      onDragUpdate: widget.onDragUpdate,
      onDragEnd: widget.onDragEnd,
      onDragCancel: widget.onDragCancel,
      errorBuilder: (_, _) => const StudioNotice('Aperçu 3D indisponible'),
    );
  }
}
