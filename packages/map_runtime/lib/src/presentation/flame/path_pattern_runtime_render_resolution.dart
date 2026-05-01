import 'package:map_core/map_core.dart';

import 'runtime_path_autotile.dart';

enum PathPatternRuntimeRenderResolutionSource {
  legacy,
  pathPattern,
  ambiguousPathPatternFallback,
}

enum PathPatternRuntimePlaybackKind {
  alwaysLoop,
  staticFrame,
  loopFrom,
  oneShot,
}

final class PathPatternRuntimePlayback {
  const PathPatternRuntimePlayback._({
    required this.kind,
    required this.startedAtMs,
  });

  const PathPatternRuntimePlayback.alwaysLoop()
      : this._(
          kind: PathPatternRuntimePlaybackKind.alwaysLoop,
          startedAtMs: 0,
        );

  const PathPatternRuntimePlayback.staticFrame()
      : this._(
          kind: PathPatternRuntimePlaybackKind.staticFrame,
          startedAtMs: 0,
        );

  const PathPatternRuntimePlayback.loopFrom({
    required double startedAtMs,
  }) : this._(
          kind: PathPatternRuntimePlaybackKind.loopFrom,
          startedAtMs: startedAtMs,
        );

  const PathPatternRuntimePlayback.oneShot({
    required double startedAtMs,
  }) : this._(
          kind: PathPatternRuntimePlaybackKind.oneShot,
          startedAtMs: startedAtMs,
        );

  final PathPatternRuntimePlaybackKind kind;
  final double startedAtMs;
}

final class PathPatternRuntimeRenderResolution {
  const PathPatternRuntimeRenderResolution({
    required this.source,
    required this.variant,
    required this.tilesetId,
    required this.sourceRect,
  });

  final PathPatternRuntimeRenderResolutionSource source;
  final TerrainPathVariant variant;
  final String tilesetId;
  final TilesetSourceRect sourceRect;
}

PathPatternRuntimeRenderResolution? resolvePathPatternRuntimeRenderResolution({
  required ProjectManifest manifest,
  required String basePathPresetId,
  required TerrainPathVariant variant,
  required int mapX,
  required int mapY,
  required double elapsedMs,
  required PathPatternRuntimePlayback playback,
  required RuntimePathAutotileSet legacyAutotileSet,
}) {
  final normalizedPresetId = basePathPresetId.trim();
  final legacyResolution = _resolveLegacy(
    variant: variant,
    elapsedMs: elapsedMs,
    playback: playback,
    legacyAutotileSet: legacyAutotileSet,
    source: PathPatternRuntimeRenderResolutionSource.legacy,
  );
  if (normalizedPresetId.isEmpty) {
    return legacyResolution;
  }

  final matchedPatterns = <ProjectPathPatternPreset>[
    for (final preset in manifest.pathPatternPresets)
      if (preset.basePathPresetId == normalizedPresetId) preset,
  ];
  if (matchedPatterns.length > 1) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      playback: playback,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternRuntimeRenderResolutionSource.ambiguousPathPatternFallback,
    );
  }
  if (matchedPatterns.isEmpty) {
    return legacyResolution;
  }

  ProjectPathPreset? basePreset;
  for (final preset in manifest.pathPresets) {
    if (preset.id == normalizedPresetId) {
      basePreset = preset;
      break;
    }
  }
  if (basePreset == null) {
    return legacyResolution;
  }

  final visual = resolvePathPatternVisual(
    pathPatternPreset: matchedPatterns.single,
    basePathPreset: basePreset,
    resolvedVariant: variant,
    mapX: mapX,
    mapY: mapY,
  );
  final frame = _resolveAnimatedFrameForPlayback(
    frames: visual.frames,
    elapsedMs: elapsedMs,
    playback: playback,
  );
  if (frame == null) {
    return legacyResolution;
  }
  final tilesetId = frame.tilesetId.trim().isNotEmpty
      ? frame.tilesetId.trim()
      : basePreset.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return legacyResolution;
  }
  return PathPatternRuntimeRenderResolution(
    source: PathPatternRuntimeRenderResolutionSource.pathPattern,
    variant: variant,
    tilesetId: tilesetId,
    sourceRect: frame.source,
  );
}

PathPatternRuntimeRenderResolution? _resolveLegacy({
  required TerrainPathVariant variant,
  required double elapsedMs,
  required PathPatternRuntimePlayback playback,
  required RuntimePathAutotileSet legacyAutotileSet,
  required PathPatternRuntimeRenderResolutionSource source,
}) {
  final frame = _resolveLegacyFrame(
    legacyAutotileSet: legacyAutotileSet,
    playback: playback,
    variant: variant,
    elapsedMs: elapsedMs,
  );
  if (frame == null) {
    return null;
  }
  final tilesetId = legacyAutotileSet.resolvedTilesetId(frame).trim();
  if (tilesetId.isEmpty) {
    return null;
  }
  return PathPatternRuntimeRenderResolution(
    source: source,
    variant: variant,
    tilesetId: tilesetId,
    sourceRect: frame.source,
  );
}

TilesetVisualFrame? _resolveLegacyFrame({
  required RuntimePathAutotileSet legacyAutotileSet,
  required PathPatternRuntimePlayback playback,
  required TerrainPathVariant variant,
  required double elapsedMs,
}) {
  switch (playback.kind) {
    case PathPatternRuntimePlaybackKind.alwaysLoop:
      return legacyAutotileSet.frameForVariantAt(variant, elapsedMs: elapsedMs);
    case PathPatternRuntimePlaybackKind.staticFrame:
      return legacyAutotileSet.frameForVariantAt(variant, elapsedMs: elapsedMs);
    case PathPatternRuntimePlaybackKind.loopFrom:
      return legacyAutotileSet.frameForVariantAt(
        variant,
        elapsedMs: elapsedMs - playback.startedAtMs,
      );
    case PathPatternRuntimePlaybackKind.oneShot:
      return legacyAutotileSet.frameForVariantOneShot(
        variant,
        elapsedMs: elapsedMs - playback.startedAtMs,
      );
  }
}

TilesetVisualFrame? _resolveAnimatedFrameForPlayback({
  required List<TilesetVisualFrame> frames,
  required double elapsedMs,
  required PathPatternRuntimePlayback playback,
}) {
  if (frames.isEmpty) {
    return null;
  }
  if (frames.length == 1) {
    return frames.first;
  }
  final durations = normalizeElementFrameDurationsMs(
    frames.map((frame) => frame.durationMs).toList(growable: false),
  );
  switch (playback.kind) {
    case PathPatternRuntimePlaybackKind.oneShot:
      final oneShot = resolvePlacedElementAnimationOneShotFrame(
        frameDurationsMs: durations,
        elapsedMs: elapsedMs - playback.startedAtMs,
      );
      return frames[oneShot.frameIndex.clamp(0, frames.length - 1)];
    case PathPatternRuntimePlaybackKind.alwaysLoop:
    case PathPatternRuntimePlaybackKind.staticFrame:
    case PathPatternRuntimePlaybackKind.loopFrom:
      final resolvedElapsed =
          playback.kind == PathPatternRuntimePlaybackKind.loopFrom
              ? elapsedMs - playback.startedAtMs
              : elapsedMs;
      final index = resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: durations,
        elapsedMs: resolvedElapsed,
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
        ),
      );
      return frames[index.clamp(0, frames.length - 1)];
  }
}
