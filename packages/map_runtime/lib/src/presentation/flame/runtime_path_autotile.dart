import 'package:map_core/map_core.dart';

class RuntimePathAutotileSet {
  RuntimePathAutotileSet({
    required this.tilesetId,
    required this.variants,
  });

  factory RuntimePathAutotileSet.fromPreset(ProjectPathPreset preset) {
    final mapping = <TerrainPathVariant, List<TilesetVisualFrame>>{};
    for (final entry in preset.variants) {
      if (entry.frames.isEmpty) {
        continue;
      }
      mapping[entry.variant] = List<TilesetVisualFrame>.from(
        entry.frames,
        growable: false,
      );
    }
    return RuntimePathAutotileSet(
      tilesetId: preset.tilesetId.trim(),
      variants: mapping,
    );
  }

  final String tilesetId;
  final Map<TerrainPathVariant, List<TilesetVisualFrame>> variants;

  TilesetVisualFrame? frameForVariantAt(
    TerrainPathVariant variant, {
    required double elapsedMs,
  }) {
    final frames = variants[variant];
    if (frames == null || frames.isEmpty) {
      return null;
    }
    if (frames.length == 1) {
      return frames.first;
    }
    final index = resolvePlacedElementAnimationFrameIndex(
      frameDurationsMs: normalizeElementFrameDurationsMs(
        frames.map((frame) => frame.durationMs).toList(growable: false),
      ),
      elapsedMs: elapsedMs,
      animation: const MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
      ),
    );
    if (index < 0 || index >= frames.length) {
      return frames.first;
    }
    return frames[index];
  }

  TilesetSourceRect? sourceForVariantAt(
    TerrainPathVariant variant, {
    required double elapsedMs,
  }) {
    final frame = frameForVariantAt(variant, elapsedMs: elapsedMs);
    return frame?.source;
  }

  String resolvedTilesetIdForVariantAt(
    TerrainPathVariant variant, {
    required double elapsedMs,
  }) {
    final frame = frameForVariantAt(variant, elapsedMs: elapsedMs);
    final frameTileset = frame?.tilesetId.trim() ?? '';
    if (frameTileset.isNotEmpty) {
      return frameTileset;
    }
    return tilesetId.trim();
  }
}
