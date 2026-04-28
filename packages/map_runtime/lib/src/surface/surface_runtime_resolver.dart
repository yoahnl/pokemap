import 'package:map_core/map_core.dart';

import 'surface_runtime_render_instruction.dart';

/// Resolves Surface placements into pure runtime render instructions.
///
/// This is the runtime counterpart of the editor preview resolver, minus any
/// image cache or Flame dependency. Missing catalog references are skipped so a
/// partially-authored project can still load the rest of the map.
List<SurfaceRuntimeRenderInstruction> resolveSurfaceRuntimeRenderInstructions({
  required SurfaceLayer layer,
  required ProjectSurfaceCatalog catalog,
  int elapsedMs = 0,
}) {
  if (!layer.isVisible || layer.opacity <= 0) {
    return const <SurfaceRuntimeRenderInstruction>[];
  }

  final placements = _runtimeResolvablePlacements(layer.placements);
  if (placements.isEmpty) {
    return const <SurfaceRuntimeRenderInstruction>[];
  }

  final instructions = <SurfaceRuntimeRenderInstruction>[];
  for (final placement in placements) {
    final presetId = placement.surfacePresetId.trim();
    final preset = catalog.presetById(presetId);
    if (preset == null) {
      continue;
    }

    final role = resolveSurfaceVariantRoleForPlacement(
      placements: placements,
      x: placement.x,
      y: placement.y,
      surfacePresetId: presetId,
    );
    final animationId = _resolveAnimationId(preset, role);
    if (animationId == null) {
      continue;
    }

    final animation = catalog.animationById(animationId);
    if (animation == null) {
      continue;
    }

    final frame = _resolveSurfaceAnimationFrameAtElapsedMs(
      timeline: animation.timeline,
      elapsedMs: elapsedMs,
    );
    final atlasId = frame.tileRef.atlasId.trim();
    final atlas = catalog.atlasById(atlasId);
    if (atlas == null || !frame.tileRef.isInside(atlas.geometry)) {
      continue;
    }

    final tilesetId = atlas.tilesetId.trim();
    if (tilesetId.isEmpty) {
      continue;
    }

    instructions.add(
      SurfaceRuntimeRenderInstruction(
        x: placement.x,
        y: placement.y,
        surfacePresetId: presetId,
        resolvedRole: role,
        animationId: animationId,
        atlasId: atlas.id,
        tilesetId: tilesetId,
        sourceColumn: frame.tileRef.column,
        sourceRow: frame.tileRef.row,
        sourceTileWidth: atlas.geometry.tileSize.width,
        sourceTileHeight: atlas.geometry.tileSize.height,
      ),
    );
  }

  return List<SurfaceRuntimeRenderInstruction>.unmodifiable(instructions);
}

List<SurfaceCellPlacement> _runtimeResolvablePlacements(
  Iterable<SurfaceCellPlacement> placements,
) {
  final out = <SurfaceCellPlacement>[
    for (final placement in placements)
      if (placement.x >= 0 &&
          placement.y >= 0 &&
          placement.surfacePresetId.trim().isNotEmpty)
        placement,
  ]..sort((a, b) {
      final yComparison = a.y.compareTo(b.y);
      if (yComparison != 0) return yComparison;
      final xComparison = a.x.compareTo(b.x);
      if (xComparison != 0) return xComparison;
      return a.surfacePresetId.compareTo(b.surfacePresetId);
    });
  return List<SurfaceCellPlacement>.unmodifiable(out);
}

String? _resolveAnimationId(
  ProjectSurfacePreset preset,
  SurfaceVariantRole resolvedRole,
) {
  final exact = preset.animationIdForRole(resolvedRole)?.trim();
  if (exact != null && exact.isNotEmpty) {
    return exact;
  }

  final isolated =
      preset.animationIdForRole(SurfaceVariantRole.isolated)?.trim();
  if (isolated != null && isolated.isNotEmpty) {
    return isolated;
  }

  for (final ref in preset.variantAnimations.refs) {
    final animationId = ref.animationId.trim();
    if (animationId.isNotEmpty) {
      return animationId;
    }
  }
  return null;
}

SurfaceAnimationFrame _resolveSurfaceAnimationFrameAtElapsedMs({
  required SurfaceAnimationTimeline timeline,
  required int elapsedMs,
}) {
  if (timeline.frames.length == 1) {
    return timeline.frames.single;
  }

  final normalizedElapsedMs = elapsedMs < 0 ? 0 : elapsedMs;
  final totalDurationMs = timeline.totalDurationMs;
  if (totalDurationMs <= 0) {
    return timeline.frames.first;
  }

  var t = normalizedElapsedMs % totalDurationMs;
  for (final frame in timeline.frames) {
    if (t < frame.durationMs) {
      return frame;
    }
    t -= frame.durationMs;
  }
  return timeline.frames.first;
}
