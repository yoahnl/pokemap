import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../features/rendering/contracts/map_workspace_visuals.dart';
import 'studio_map_resources.dart';
import 'studio_map_visual_widgets.dart';

Widget buildStudioBorderAssemblyPreview(
  MapData map,
  ProjectManifest project,
  StudioMapResources resources,
) {
  if (map.spatialScene != null) {
    return _SpatialBorderAssemblyPreview(
      project: project,
      map: map,
      visuals: resources,
    );
  }
  final settings = project.settings;
  return FittedBox(
    child: SizedBox(
      width: map.size.width * settings.tileWidth * settings.displayScale,
      height: map.size.height * settings.tileHeight * settings.displayScale,
      child: StudioMapVisual(
        map: map,
        resources: resources,
        preview: true,
        previewProject: project,
      ),
    ),
  );
}

class _SpatialBorderAssemblyPreview extends StatefulWidget {
  const _SpatialBorderAssemblyPreview({
    required this.project,
    required this.map,
    required this.visuals,
  });

  final ProjectManifest project;
  final MapData map;
  final SpatialWorkspaceVisuals visuals;

  @override
  State<_SpatialBorderAssemblyPreview> createState() =>
      _SpatialBorderAssemblyPreviewState();
}

class _SpatialBorderAssemblyPreviewState
    extends State<_SpatialBorderAssemblyPreview> {
  late var _assets = SpatialMapAssetSource(widget.project, widget.visuals);
  final _controller = SpatialSceneController(presentationEffectsEnabled: false);

  @override
  void didUpdateWidget(_SpatialBorderAssemblyPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.project, widget.project) ||
        !identical(oldWidget.visuals, widget.visuals)) {
      _assets = SpatialMapAssetSource(widget.project, widget.visuals);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scene = widget.map.spatialScene!;
    return SpatialSceneView(
      scene: scene,
      models: widget.project.models3d,
      loadModel: _assets.loadModel,
      controller: _controller,
      groundMap: widget.map,
      groundProject: widget.project,
      loadGroundImage: _assets.loadGroundImage,
      onCell: (_, _) {},
      selectContent: false,
      background: colors.surfaceContainerLowest,
      ground: colors.surfaceContainerHighest,
      edge: colors.outlineVariant,
      errorBuilder: (_, _) =>
          const Center(child: Text('Rendu 3D de la bordure indisponible')),
    );
  }
}
