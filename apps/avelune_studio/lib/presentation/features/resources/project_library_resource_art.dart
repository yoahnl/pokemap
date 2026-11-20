import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/rendering/contracts/character_workspace_visuals.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/rendering/contracts/scoped_resource_preview_visuals.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_example.dart';

import 'model_resource_preview.dart';

class ProjectLibraryResourceArt extends StatelessWidget {
  const ProjectLibraryResourceArt({
    super.key,
    required this.item,
    required this.project,
    required this.visuals,
    required this.size,
    this.compact = false,
  });

  final ResourceItem item;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final terrain = item.terrain;
    final tiles = terrain == null
        ? null
        : terrainConnectionExample(project, terrain);
    final definitions = item.border?.draft.definition.primitives;
    final border = definitions == null
        ? const <ResourcePreviewSource>[]
        : _borderSources(definitions, project);
    return SizedBox.square(
      dimension: size,
      child: switch ((tiles, border)) {
        (final pattern?, _) => Column(
          children: [
            for (var row = 0; row < 3; row++)
              Expanded(
                child: Row(
                  children: [
                    for (var column = 0; column < 3; column++)
                      Expanded(
                        child: _art(
                          context,
                          TileFramePreviewSource(pattern[row * 3 + column]),
                          size / 3,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        (_, [final first]) => _art(context, first, size),
        (_, [_, ...]) => Tooltip(
          message: 'Pièces de la bordure',
          child: Row(
            children: [
              for (final source in border)
                Expanded(child: _art(context, source, size / border.length)),
            ],
          ),
        ),
        _ => _art(context, resourcePreviewSource(item, project), size),
      },
    );
  }

  Widget _art(
    BuildContext context,
    ResourcePreviewSource source,
    double extent,
  ) {
    final provider = visuals;
    final fallback = Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: size * .35,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        semanticLabel: 'Aperçu indisponible',
      ),
    );
    return switch (source) {
      ModelPreviewSource(:final model)
          when provider is SpatialWorkspaceVisuals =>
        ModelResourcePreview(model: model, visuals: provider, compact: compact),
      FallbackPreviewSource() ||
      TerrainPatternPreviewSource() ||
      ModelPreviewSource() => fallback,
      _ when provider is ScopedResourcePreviewVisuals =>
        (provider as ScopedResourcePreviewVisuals).scopedResourcePreview(
          source,
          project,
          size: extent,
        ),
      CharacterPreviewSource(:final character)
          when provider is CharacterWorkspaceVisuals =>
        (provider as CharacterWorkspaceVisuals).characterThumbnail(
          character,
          size: extent,
        ),
      TileFramePreviewSource(:final entry) => provider.tileThumbnail(
        entry,
        size: extent,
      ),
      ElementPreviewSource(:final element) => provider.thumbnail(
        element,
        size: extent,
      ),
      AtlasPreviewSource(:final tilesetId)
          when provider is ResourceWorkspaceVisuals =>
        (provider as ResourceWorkspaceVisuals).atlasPreview(tilesetId),
      _ => fallback,
    };
  }
}

List<ResourcePreviewSource> _borderSources(
  List<BorderPrimitiveDraft> primitives,
  ProjectManifest project,
) {
  final models = {for (final model in project.models3d) model.id: model};
  final elements = {
    for (final element in project.elements) element.id: element,
  };
  final distinct = <(BorderVisualKind, String)>{};
  final selected = <ResourcePreviewSource>[];
  final roles = <BorderPrimitiveRole>{};
  for (final primitive in primitives) {
    if (roles.contains(primitive.role)) continue;
    final modelId = primitive.sourceModelId;
    final model = models[modelId];
    final element = elements[primitive.sourceElementId];
    if (model != null && distinct.add((BorderVisualKind.model3d, model.id))) {
      selected.add(ModelPreviewSource(model));
      roles.add(primitive.role);
    } else if (element != null &&
        distinct.add((BorderVisualKind.element, element.id))) {
      selected.add(ElementPreviewSource(element));
      roles.add(primitive.role);
    }
    if (selected.length == 3) break;
  }
  return selected;
}
