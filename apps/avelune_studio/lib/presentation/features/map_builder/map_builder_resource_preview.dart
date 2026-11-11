import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';

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
          _ModelPreview(
            model: model,
            visuals: visuals as SpatialWorkspaceVisuals,
          ),
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

class _ModelPreview extends StatefulWidget {
  const _ModelPreview({required this.model, required this.visuals});

  final ProjectModel3dEntry model;
  final SpatialWorkspaceVisuals visuals;

  @override
  State<_ModelPreview> createState() => _ModelPreviewState();
}

class _ModelPreviewState extends State<_ModelPreview> {
  final _controller = ModelPreviewController();
  late Future<Uint8List> _bytes = widget.visuals.readModel(widget.model.id);

  @override
  void didUpdateWidget(_ModelPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.id != widget.model.id ||
        oldWidget.model.relativePath != widget.model.relativePath ||
        oldWidget.model.sourceAssetId != widget.model.sourceAssetId ||
        !identical(oldWidget.visuals, widget.visuals)) {
      _bytes = widget.visuals.readModel(widget.model.id);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unavailable = Center(
      child: Icon(Icons.view_in_ar_outlined, color: scheme.onSurfaceVariant),
    );
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (snapshot.hasError) return unavailable;
        if (bytes == null) {
          return const Center(
            child: SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final bounds = widget.model.inspection.bounds;
        return ModelPreview(
          bytes: bytes,
          controller: _controller,
          minimum: [bounds.min.x, bounds.min.y, bounds.min.z],
          maximum: [bounds.max.x, bounds.max.y, bounds.max.z],
          background: scheme.surfaceContainerLowest,
          loadingBuilder: (_) => const SizedBox(),
          errorBuilder: (_, _) => unavailable,
        );
      },
    );
  }
}
