import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../shared/widgets/feedback/studio_notice.dart';

import 'package:map_core/map_core.dart';

import '../map_workspace/map_workspace_visuals.dart';
import '../characters/character_workspace_visuals.dart';
import 'resource_catalog.dart';
import 'resource_terrain_preview.dart';

Widget resourcePreview(
  ResourceItem item,
  ProjectManifest project,
  MapWorkspaceVisuals visuals, {
  double size = 80,
  bool terrainPattern = false,
}) {
  final model =
      item.model3d ??
      project.models3d
          .where(
            (model) =>
                model.id ==
                (item.environment?.palette.firstOrNull?.modelId ??
                    item
                        .border
                        ?.draft
                        .definition
                        .primitives
                        .firstOrNull
                        ?.sourceModelId),
          )
          .firstOrNull;
  if (model != null) {
    return SizedBox.square(
      dimension: size,
      child: _ModelResourcePreview(model: model, visuals: visuals),
    );
  }
  if (item.element != null) return visuals.thumbnail(item.element!, size: size);
  final previewElementId =
      item.border?.draft.definition.primitives.firstOrNull?.sourceElementId ??
      item.environment?.palette.firstOrNull?.elementId;
  if (previewElementId != null) {
    final element = project.elements
        .where((element) => element.id == previewElementId)
        .firstOrNull;
    if (element != null) return visuals.thumbnail(element, size: size);
  }
  if (item.character case final character?) {
    return visuals is CharacterWorkspaceVisuals
        ? (visuals as CharacterWorkspaceVisuals).characterThumbnail(
            character,
            size: size,
          )
        : SizedBox.square(
            dimension: size,
            child: const Icon(Icons.person_outline),
          );
  }
  if (item.tileset != null) {
    if (visuals is ResourceWorkspaceVisuals) {
      return SizedBox(
        width: size,
        height: size,
        child: (visuals as ResourceWorkspaceVisuals).atlasPreview(item.id),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: const Center(
        child: Text('Vue d’ensemble indisponible', textAlign: TextAlign.center),
      ),
    );
  }
  final preset = item.terrain;
  if (preset != null) {
    if (terrainPattern) {
      return SizedBox.square(
        dimension: size,
        child: ResourceTerrainPreview(
          preset: preset,
          project: project,
          visuals: visuals,
          size: size,
        ),
      );
    }
    for (final rule in preset.rules) {
      for (final candidate in rule.candidates) {
        for (final part in candidate.parts) {
          if (part.source case SmartTileModel3dSource(:final modelId)) {
            final model = project.models3d
                .where((model) => model.id == modelId)
                .firstOrNull;
            if (model != null) {
              return SizedBox.square(
                dimension: size,
                child: _ModelResourcePreview(model: model, visuals: visuals),
              );
            }
          }
          if (part.source case SmartTileFrameSource(:final frame)) {
            final atlas = project.smartTileCatalog.atlases
                .where((a) => a.id == frame.atlasId)
                .firstOrNull;
            final source = project.tilesets
                .where((t) => t.id == atlas?.tilesetId)
                .firstOrNull
                ?.source;
            if (atlas != null && source is ProjectRegularAtlasTilesetSource) {
              return visuals.tileThumbnail(
                TileLayerPaletteEntry(
                  tilesetId: atlas.tilesetId,
                  localTileId: frame.row * source.columns + frame.column,
                ),
                size: size,
              );
            }
          }
        }
      }
    }
  }
  return Icon(Icons.terrain_outlined, size: size * .55);
}

int resourceOpenMapUsage(ResourceItem item, Iterable<MapData> maps) {
  var count = 0;
  for (final map in maps) {
    if (item.model3d != null) {
      count +=
          map.spatialScene?.instances
              .where((instance) => instance.modelId == item.id)
              .length ??
          0;
    }
    if (item.element != null) {
      count += map.placedElements.where((e) => e.elementId == item.id).length;
    }
    if (item.terrain != null) {
      count += map.layers
          .whereType<SmartTileLayer>()
          .where((l) => l.presetId == item.id)
          .length;
    }
    if (item.tileset != null) {
      count += map.layers
          .whereType<TileLayer>()
          .where((l) => l.palette.any((t) => t.tilesetId == item.id))
          .length;
    }
    if (item.border != null) {
      count += map.layers
          .whereType<BorderLayer>()
          .expand((layer) => layer.content.features)
          .where((feature) => feature.blueprintId == item.id)
          .length;
    }
    if (item.environment != null) {
      count += map.layers
          .whereType<EnvironmentLayer>()
          .expand((layer) => layer.content.areas)
          .where((area) => area.presetId == item.id)
          .length;
    }
    if (item.character != null) {
      count += map.entities
          .where((entity) => entity.npc?.characterId == item.id)
          .length;
    }
  }
  return count;
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
    if (old.model != widget.model || old.visuals != widget.visuals) load();
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
        controller: controls,
        minimum: [bounds.min.x, bounds.min.y, bounds.min.z],
        maximum: [bounds.max.x, bounds.max.y, bounds.max.z],
        background: Theme.of(context).colorScheme.surfaceContainerLowest,
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, error) => const StudioNotice('Aperçu indisponible'),
      );
    },
  );
}
