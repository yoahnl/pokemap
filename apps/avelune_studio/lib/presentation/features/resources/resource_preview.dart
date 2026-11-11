import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../shared/widgets/feedback/studio_notice.dart';

import 'package:map_core/map_core.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/contracts/character_workspace_visuals.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'resource_terrain_preview.dart';
import 'model_light_preview_scope.dart';
import 'model_light_gizmo.dart';

Widget resourcePreview(
  ResourceItem item,
  ProjectManifest project,
  MapWorkspaceVisuals visuals, {
  double size = 80,
  bool terrainPattern = false,
}) {
  return switch (resourcePreviewSource(
    item,
    project,
    terrainPattern: terrainPattern,
  )) {
    ModelPreviewSource(:final model) => SizedBox.square(
      dimension: size,
      child: _ModelResourcePreview(model: model, visuals: visuals),
    ),
    ElementPreviewSource(:final element) => visuals.thumbnail(
      element,
      size: size,
    ),
    CharacterPreviewSource(:final character) =>
      visuals is CharacterWorkspaceVisuals
          ? (visuals as CharacterWorkspaceVisuals).characterThumbnail(
              character,
              size: size,
            )
          : SizedBox.square(
              dimension: size,
              child: const Icon(Icons.person_outline),
            ),
    AtlasPreviewSource(:final tilesetId) =>
      visuals is ResourceWorkspaceVisuals
          ? SizedBox(
              width: size,
              height: size,
              child: (visuals as ResourceWorkspaceVisuals).atlasPreview(
                tilesetId,
              ),
            )
          : SizedBox.square(
              dimension: size,
              child: const Center(
                child: Text(
                  'Vue d’ensemble indisponible',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    TerrainPatternPreviewSource(:final preset) => SizedBox.square(
      dimension: size,
      child: ResourceTerrainPreview(
        preset: preset,
        project: project,
        visuals: visuals,
        size: size,
      ),
    ),
    TileFramePreviewSource(:final entry) => visuals.tileThumbnail(
      entry,
      size: size,
    ),
    FallbackPreviewSource() => Icon(Icons.terrain_outlined, size: size * .55),
  };
}

class _ModelResourcePreview extends StatefulWidget {
  const _ModelResourcePreview({required this.model, required this.visuals});
  final ProjectModel3dEntry model;
  final MapWorkspaceVisuals visuals;
  @override
  State<_ModelResourcePreview> createState() => _ModelResourcePreviewState();
}

class _ModelResourcePreviewState extends State<_ModelResourcePreview> {
  final controls = ModelPreviewController();
  Future<Uint8List>? source;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(_ModelResourcePreview old) {
    super.didUpdateWidget(old);
    if (old.model.id != widget.model.id || old.model.relativePath != widget.model.relativePath ||
        old.model.sourceAssetId != widget.model.sourceAssetId || !identical(old.model.inspection,widget.model.inspection) ||
        old.visuals != widget.visuals) {
      load();
    }
  }

  void load() {
    final visuals = widget.visuals;
    source = visuals is SpatialWorkspaceVisuals
        ? (visuals as SpatialWorkspaceVisuals).readModel(widget.model.id)
        : null;
  }

  @override
  void dispose() {
    controls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: source,
    builder: (context, snapshot) {
      if (snapshot.hasError || source == null) {
        return const StudioNotice('Aperçu indisponible');
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final bounds = widget.model.inspection.bounds;
      return ModelPreview(
        bytes: snapshot.data!,
        controller: ModelLightPreviewScope.maybeOf(context) ?? controls,
        lightOverlayBuilder: ModelLightPreviewScope.maybeOf(context) == null
            ? null
            : (context, controller) => ModelLightGizmo(controller: controller),
        minimum: [bounds.min.x, bounds.min.y, bounds.min.z],
        maximum: [bounds.max.x, bounds.max.y, bounds.max.z],
        background: Theme.of(context).colorScheme.surfaceContainerLowest,
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, error) => const StudioNotice('Aperçu indisponible'),
      );
    },
  );
}
