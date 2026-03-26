import 'package:map_core/map_core.dart';

class RuntimePathAutotileSet {
  RuntimePathAutotileSet({
    required this.tilesetId,
    required this.variants,
  });

  factory RuntimePathAutotileSet.fromPreset(ProjectPathPreset preset) {
    final mapping = <TerrainPathVariant, TilesetSourceRect>{};
    for (final entry in preset.variants) {
      mapping[entry.variant] = entry.frames.primarySource;
    }
    return RuntimePathAutotileSet(
      tilesetId: preset.tilesetId.trim(),
      variants: mapping,
    );
  }

  final String tilesetId;
  final Map<TerrainPathVariant, TilesetSourceRect> variants;

  TilesetSourceRect? sourceForVariant(TerrainPathVariant variant) {
    return variants[variant];
  }
}
