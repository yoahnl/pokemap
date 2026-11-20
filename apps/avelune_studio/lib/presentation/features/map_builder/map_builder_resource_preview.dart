import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/resources/model_resource_preview.dart';

class MapBuilderResourcePreview extends StatelessWidget {
  const MapBuilderResourcePreview({
    super.key,
    required this.item,
    required this.project,
    required this.visuals,
    required this.size,
  });

  final ResourceItem item;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.image_not_supported_outlined,
      size: size * .35,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final visuals = this.visuals;
    return SizedBox.square(
      dimension: size,
      child: switch (resourcePreviewSource(item, project)) {
        ModelPreviewSource(:final model)
            when visuals is SpatialWorkspaceVisuals =>
          ModelResourcePreview(model: model, visuals: visuals),
        ElementPreviewSource(:final element) => visuals.thumbnail(
          element,
          size: size,
        ),
        TileFramePreviewSource(:final entry) => visuals.tileThumbnail(
          entry,
          size: size,
        ),
        AtlasPreviewSource(:final tilesetId)
            when visuals is ResourceWorkspaceVisuals =>
          (visuals as ResourceWorkspaceVisuals).atlasPreview(tilesetId),
        _ => Center(child: fallback),
      },
    );
  }
}
