import 'package:map_core/map_core_domain.dart';

import 'resource_catalog.dart';
import 'resource_terrain_example.dart';

sealed class ResourcePreviewSource {
  const ResourcePreviewSource();
}

final class ModelPreviewSource extends ResourcePreviewSource {
  const ModelPreviewSource(this.model);
  final ProjectModel3dEntry model;
}

final class ElementPreviewSource extends ResourcePreviewSource {
  const ElementPreviewSource(this.element);
  final ProjectElementEntry element;
}

final class CharacterPreviewSource extends ResourcePreviewSource {
  const CharacterPreviewSource(this.character);
  final ProjectCharacterEntry character;
}

final class AtlasPreviewSource extends ResourcePreviewSource {
  const AtlasPreviewSource(this.tilesetId);
  final String tilesetId;
}

final class TerrainPatternPreviewSource extends ResourcePreviewSource {
  const TerrainPatternPreviewSource(this.preset);
  final ProjectSmartTilePreset preset;
}

final class TileFramePreviewSource extends ResourcePreviewSource {
  const TileFramePreviewSource(this.entry);
  final TileLayerPaletteEntry entry;
}

final class FallbackPreviewSource extends ResourcePreviewSource {
  const FallbackPreviewSource();
}

ResourcePreviewSource resourcePreviewSource(
  ResourceItem item,
  ProjectManifest project, {
  bool terrainPattern = false,
}) {
  final modelId =
      item.environment?.palette.firstOrNull?.modelId ??
      item.border?.draft.definition.primitives.firstOrNull?.sourceModelId;
  final model =
      item.model3d ??
      project.models3d.where((model) => model.id == modelId).firstOrNull;
  if (model != null) return ModelPreviewSource(model);
  if (item.element != null) return ElementPreviewSource(item.element!);
  final previewElementId =
      item.border?.draft.definition.primitives.firstOrNull?.sourceElementId ??
      item.environment?.palette.firstOrNull?.elementId;
  if (previewElementId != null) {
    final element = project.elements
        .where((element) => element.id == previewElementId)
        .firstOrNull;
    if (element != null) return ElementPreviewSource(element);
  }
  if (item.character case final character?) {
    return CharacterPreviewSource(character);
  }
  if (item.tileset != null) return AtlasPreviewSource(item.id);
  final preset = item.terrain;
  if (preset != null) {
    if (terrainPattern) return TerrainPatternPreviewSource(preset);
    for (final rule in preset.rules) {
      for (final candidate in rule.candidates) {
        for (final part in candidate.parts) {
          if (part.source case SmartTileModel3dSource(:final modelId)) {
            final model = project.models3d
                .where((model) => model.id == modelId)
                .firstOrNull;
            if (model != null) return ModelPreviewSource(model);
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
              return TileFramePreviewSource(
                TileLayerPaletteEntry(
                  tilesetId: atlas.tilesetId,
                  localTileId: regularAtlasLocalTileId(
                    row: frame.row,
                    column: frame.column,
                    source: source,
                  ),
                ),
              );
            }
          }
        }
      }
    }
  }
  return const FallbackPreviewSource();
}
