import 'package:map_core/map_core.dart';

class PathAutotileSet {
  const PathAutotileSet({
    required this.id,
    required this.tilesetId,
    required this.variants,
  });

  factory PathAutotileSet.defaultForTileset(String tilesetId) {
    return PathAutotileSet(
      id: 'default_$tilesetId',
      tilesetId: tilesetId,
      variants: const {
        TerrainPathVariant.isolated: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
        TerrainPathVariant.endNorth: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
        ],
        TerrainPathVariant.endEast: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 2, y: 0)),
        ],
        TerrainPathVariant.endSouth: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 0)),
        ],
        TerrainPathVariant.endWest: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 1)),
        ],
        TerrainPathVariant.horizontal: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 1)),
        ],
        TerrainPathVariant.vertical: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 2, y: 1)),
        ],
        TerrainPathVariant.cornerNE: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 1)),
        ],
        TerrainPathVariant.cornerSE: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 2)),
        ],
        TerrainPathVariant.cornerSW: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 2)),
        ],
        TerrainPathVariant.cornerNW: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 2, y: 2)),
        ],
        TerrainPathVariant.innerCornerNE: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 3)),
        ],
        TerrainPathVariant.innerCornerSE: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 3)),
        ],
        TerrainPathVariant.innerCornerSW: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 3)),
        ],
        TerrainPathVariant.innerCornerNW: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 3)),
        ],
        TerrainPathVariant.teeNorth: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 2)),
        ],
        TerrainPathVariant.teeEast: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 3)),
        ],
        TerrainPathVariant.teeSouth: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 3)),
        ],
        TerrainPathVariant.teeWest: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 2, y: 3)),
        ],
        TerrainPathVariant.cross: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 3)),
        ],
      },
    );
  }

  factory PathAutotileSet.fromPreset(ProjectPathPreset preset) {
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
    return PathAutotileSet(
      id: preset.id,
      tilesetId: preset.tilesetId.trim(),
      variants: mapping,
    );
  }

  final String id;
  final String tilesetId;
  final Map<TerrainPathVariant, List<TilesetVisualFrame>> variants;

  TilesetVisualFrame? frameForVariantAt(
    TerrainPathVariant variant, {
    required double elapsedMs,
  }) {
    final frames = _playbackFramesForVariant(variant);
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
    final frameTilesetId = frame?.tilesetId.trim() ?? '';
    if (frameTilesetId.isNotEmpty) {
      return frameTilesetId;
    }
    return tilesetId.trim();
  }

  List<TilesetVisualFrame>? _playbackFramesForVariant(
    TerrainPathVariant variant,
  ) {
    final frames = variants[variant];
    if (frames == null || frames.isEmpty || frames.length > 1) {
      return frames;
    }
    final firstFrame = frames.first;
    for (final candidate in variants.values) {
      if (candidate.length <= 1) {
        continue;
      }
      final candidateFirstFrame = candidate.first;
      if (candidateFirstFrame.source == firstFrame.source &&
          candidateFirstFrame.tilesetId.trim() == firstFrame.tilesetId.trim()) {
        return candidate;
      }
    }
    return frames;
  }
}
