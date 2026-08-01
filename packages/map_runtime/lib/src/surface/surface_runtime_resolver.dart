import 'package:map_core/map_core.dart';

import 'surface_runtime_render_instruction.dart';

/// Half-open cell bounds used to keep Surface instruction work near the
/// camera. The topology itself remains complete, so cells on a viewport edge
/// still see neighbors just outside these bounds.
final class SurfaceRuntimeCellViewport {
  const SurfaceRuntimeCellViewport({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;

  bool get isEmpty => right <= left || bottom <= top;

  bool contains(SurfaceCellPlacement placement) =>
      !isEmpty &&
      placement.x >= left &&
      placement.x < right &&
      placement.y >= top &&
      placement.y < bottom;
}

/// Runtime-owned cache for one immutable Surface layer.
///
/// Core owns only [SurfacePlacementTopology]. This wrapper owns the sorted
/// render order and row index needed by Flame's viewport, and is rebuilt when
/// a new immutable layer instance is mounted.
final class SurfaceRuntimeLayerIndex {
  SurfaceRuntimeLayerIndex._({
    required SurfaceLayer sourceLayer,
    required List<SurfaceCellPlacement> placements,
  })  : _sourceLayer = sourceLayer,
        _placements = placements,
        _topology = SurfacePlacementTopology(placements),
        _placementsByRow = _indexPlacementsByRow(placements);

  factory SurfaceRuntimeLayerIndex.fromLayer(SurfaceLayer layer) {
    return SurfaceRuntimeLayerIndex._(
      sourceLayer: layer,
      placements: _runtimeResolvablePlacements(layer.placements),
    );
  }

  final SurfaceLayer _sourceLayer;
  final List<SurfaceCellPlacement> _placements;
  final SurfacePlacementTopology _topology;
  final Map<int, List<SurfaceCellPlacement>> _placementsByRow;

  int get indexedPlacementCount => _placements.length;

  Iterable<SurfaceCellPlacement> placementsIn(
    SurfaceRuntimeCellViewport? viewport,
  ) sync* {
    if (viewport == null) {
      yield* _placements;
      return;
    }
    if (viewport.isEmpty) {
      return;
    }
    if (_placements.isEmpty) {
      return;
    }
    final firstIndexedRow = _placements.first.y;
    final lastIndexedRowExclusive = _placements.last.y + 1;
    final startRow =
        viewport.top > firstIndexedRow ? viewport.top : firstIndexedRow;
    final endRow = viewport.bottom < lastIndexedRowExclusive
        ? viewport.bottom
        : lastIndexedRowExclusive;
    for (var y = startRow; y < endRow; y += 1) {
      final row = _placementsByRow[y];
      if (row == null) {
        continue;
      }
      for (final placement in row) {
        if (placement.x >= viewport.left && placement.x < viewport.right) {
          yield placement;
        }
      }
    }
  }

  SurfaceVariantRole roleFor(SurfaceCellPlacement placement) {
    return _topology.roleAt(
      x: placement.x,
      y: placement.y,
      surfacePresetId: placement.surfacePresetId,
    );
  }
}

/// Resolves Surface placements into pure runtime render instructions.
///
/// This is the runtime counterpart of the editor preview resolver, minus any
/// image cache or Flame dependency. Missing catalog references are skipped so a
/// partially-authored project can still load the rest of the map.
List<SurfaceRuntimeRenderInstruction> resolveSurfaceRuntimeRenderInstructions({
  required SurfaceLayer layer,
  required ProjectSurfaceCatalog catalog,
  int elapsedMs = 0,
  SurfaceRuntimeLayerIndex? layerIndex,
  SurfaceRuntimeCellViewport? viewport,
}) {
  if (!layer.isVisible || layer.opacity <= 0) {
    return const <SurfaceRuntimeRenderInstruction>[];
  }

  final index = layerIndex ?? SurfaceRuntimeLayerIndex.fromLayer(layer);
  if (!identical(index._sourceLayer, layer)) {
    throw ArgumentError.value(
      index._sourceLayer.id,
      'layerIndex',
      'must belong to the provided SurfaceLayer instance ${layer.id}',
    );
  }
  if (index.indexedPlacementCount == 0 || viewport?.isEmpty == true) {
    return const <SurfaceRuntimeRenderInstruction>[];
  }

  final instructions = <SurfaceRuntimeRenderInstruction>[];
  for (final placement in index.placementsIn(viewport)) {
    final presetId = placement.surfacePresetId.trim();
    final preset = catalog.presetById(presetId);
    if (preset == null) {
      continue;
    }

    final role = index.roleFor(placement);
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

Map<int, List<SurfaceCellPlacement>> _indexPlacementsByRow(
  List<SurfaceCellPlacement> placements,
) {
  final rows = <int, List<SurfaceCellPlacement>>{};
  for (final placement in placements) {
    rows
        .putIfAbsent(placement.y, () => <SurfaceCellPlacement>[])
        .add(placement);
  }
  return Map<int, List<SurfaceCellPlacement>>.unmodifiable(
    <int, List<SurfaceCellPlacement>>{
      for (final entry in rows.entries)
        entry.key: List<SurfaceCellPlacement>.unmodifiable(entry.value),
    },
  );
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
