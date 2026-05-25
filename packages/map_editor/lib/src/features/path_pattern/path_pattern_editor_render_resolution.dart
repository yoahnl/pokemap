import 'package:map_core/map_core.dart';

import '../../application/models/path_autotile_set.dart';

enum PathPatternEditorRenderResolutionSource {
  legacy,
  pathPattern,
  ambiguousPathPatternFallback,
}

enum PathPatternEditorPlaybackMode {
  loop,
  staticFrame,
}

final class PathPatternEditorRenderResolution {
  const PathPatternEditorRenderResolution({
    required this.source,
    required this.variant,
    required this.tilesetId,
    required this.sourceRect,
  });

  final PathPatternEditorRenderResolutionSource source;
  final TerrainPathVariant variant;
  final String tilesetId;
  final TilesetSourceRect sourceRect;
}

PathPatternEditorRenderResolution? resolvePathPatternEditorRenderResolution({
  required ProjectManifest? project,
  required String basePathPresetId,
  required TerrainPathVariant variant,
  required int mapX,
  required int mapY,
  required double elapsedMs,
  required PathAutotileSet? legacyAutotileSet,
  PathPatternEditorPlaybackMode playbackMode =
      PathPatternEditorPlaybackMode.loop,
}) {
  final normalizedPresetId = basePathPresetId.trim();
  if (project == null || normalizedPresetId.isEmpty) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      playbackMode: playbackMode,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternEditorRenderResolutionSource.legacy,
    );
  }

  final matchedPatterns = <ProjectPathPatternPreset>[
    for (final preset in project.pathPatternPresets)
      if (preset.basePathPresetId == normalizedPresetId) preset,
  ];
  if (matchedPatterns.length > 1) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      playbackMode: playbackMode,
      legacyAutotileSet: legacyAutotileSet,
      source:
          PathPatternEditorRenderResolutionSource.ambiguousPathPatternFallback,
    );
  }
  if (matchedPatterns.isEmpty) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      playbackMode: playbackMode,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternEditorRenderResolutionSource.legacy,
    );
  }

  ProjectPathPreset? basePreset;
  for (final preset in project.pathPresets) {
    if (preset.id == normalizedPresetId) {
      basePreset = preset;
      break;
    }
  }
  if (basePreset == null) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      playbackMode: playbackMode,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternEditorRenderResolutionSource.legacy,
    );
  }

  final visual = resolvePathPatternVisual(
    pathPatternPreset: matchedPatterns.single,
    basePathPreset: basePreset,
    resolvedVariant: variant,
    mapX: mapX,
    mapY: mapY,
  );
  final frame = _resolveAnimatedFrame(
    frames: visual.frames,
    elapsedMs: elapsedMs,
    playbackMode: playbackMode,
  );
  if (frame == null) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      playbackMode: playbackMode,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternEditorRenderResolutionSource.legacy,
    );
  }
  final tilesetId = frame.tilesetId.trim().isNotEmpty
      ? frame.tilesetId.trim()
      : basePreset.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      playbackMode: playbackMode,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternEditorRenderResolutionSource.legacy,
    );
  }
  return PathPatternEditorRenderResolution(
    source: PathPatternEditorRenderResolutionSource.pathPattern,
    variant: variant,
    tilesetId: tilesetId,
    sourceRect: frame.source,
  );
}

PathPatternEditorRenderResolution? _resolveLegacy({
  required TerrainPathVariant variant,
  required double elapsedMs,
  required PathPatternEditorPlaybackMode playbackMode,
  required PathAutotileSet? legacyAutotileSet,
  required PathPatternEditorRenderResolutionSource source,
}) {
  if (legacyAutotileSet == null) {
    return null;
  }
  final frame = playbackMode == PathPatternEditorPlaybackMode.staticFrame
      ? legacyAutotileSet.frameForVariantStatic(variant)
      : legacyAutotileSet.frameForVariantAt(
          variant,
          elapsedMs: elapsedMs,
        );
  if (frame == null) {
    return null;
  }
  final tilesetId = frame.tilesetId.trim().isNotEmpty
      ? frame.tilesetId.trim()
      : legacyAutotileSet.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return null;
  }
  return PathPatternEditorRenderResolution(
    source: source,
    variant: variant,
    tilesetId: tilesetId,
    sourceRect: frame.source,
  );
}

TilesetVisualFrame? _resolveAnimatedFrame({
  required List<TilesetVisualFrame> frames,
  required double elapsedMs,
  required PathPatternEditorPlaybackMode playbackMode,
}) {
  if (frames.isEmpty) {
    return null;
  }
  if (frames.length == 1) {
    return frames.first;
  }
  if (playbackMode == PathPatternEditorPlaybackMode.staticFrame) {
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
