import 'dart:ui' show Rect;

import 'package:map_core/map_core.dart';

/// Editor-only draw instruction for a static Surface atlas preview.
///
/// It resolves catalog references far enough for the canvas to call
/// `drawImageRect`, but it deliberately keeps animation time and runtime asset
/// loading out of the editor Surface preview V0.
final class SurfaceTilePreviewInstruction {
  const SurfaceTilePreviewInstruction({
    required this.x,
    required this.y,
    required this.surfacePresetId,
    required this.resolvedRole,
    required this.animationId,
    required this.atlasId,
    required this.tilesetId,
    required this.sourceColumn,
    required this.sourceRow,
    required this.sourceRect,
  });

  final int x;
  final int y;
  final String surfacePresetId;
  final SurfaceVariantRole resolvedRole;
  final String animationId;
  final String atlasId;
  final String tilesetId;
  final int sourceColumn;
  final int sourceRow;
  final Rect sourceRect;
}

/// Resolves a sparse Surface placement into the first frame of the matching
/// atlas animation, or `null` when the debug overlay should remain visible.
SurfaceTilePreviewInstruction? resolveSurfaceTilePreviewInstruction({
  required SurfaceLayer layer,
  required SurfaceCellPlacement placement,
  required ProjectSurfaceCatalog catalog,
  required Set<String> availableTilesetIds,
}) {
  if (!layer.isVisible || layer.opacity <= 0) {
    return null;
  }

  final presetId = placement.surfacePresetId.trim();
  if (presetId.isEmpty) {
    return null;
  }
  final preset = catalog.presetById(presetId);
  if (preset == null) {
    return null;
  }

  final role = resolveSurfaceVariantRoleForPlacement(
    placements: layer.placements,
    x: placement.x,
    y: placement.y,
    surfacePresetId: presetId,
  );
  final animationId = _resolveAnimationId(preset, role);
  if (animationId == null) {
    return null;
  }

  final animation = catalog.animationById(animationId);
  if (animation == null || animation.timeline.frames.isEmpty) {
    return null;
  }
  final frame = animation.timeline.frames.first;
  final atlasId = frame.tileRef.atlasId.trim();
  if (atlasId.isEmpty) {
    return null;
  }
  final atlas = catalog.atlasById(atlasId);
  if (atlas == null || !frame.tileRef.isInside(atlas.geometry)) {
    return null;
  }

  final tilesetId = atlas.tilesetId.trim();
  if (tilesetId.isEmpty || !availableTilesetIds.contains(tilesetId)) {
    return null;
  }

  final tileWidth = atlas.geometry.tileSize.width;
  final tileHeight = atlas.geometry.tileSize.height;
  final sourceColumn = frame.tileRef.column;
  final sourceRow = frame.tileRef.row;
  final sourceRect = Rect.fromLTWH(
    (sourceColumn * tileWidth).toDouble(),
    (sourceRow * tileHeight).toDouble(),
    tileWidth.toDouble(),
    tileHeight.toDouble(),
  );

  return SurfaceTilePreviewInstruction(
    x: placement.x,
    y: placement.y,
    surfacePresetId: presetId,
    resolvedRole: role,
    animationId: animationId,
    atlasId: atlas.id,
    tilesetId: tilesetId,
    sourceColumn: sourceColumn,
    sourceRow: sourceRow,
    sourceRect: sourceRect,
  );
}

/// Returns the editor tileset images worth loading for the placed Surface
/// presets in [map].
///
/// The canvas already has a tileset image cache; this helper only feeds it ids
/// from actually placed Surface presets, instead of loading every Surface Studio
/// atlas in the project.
Set<String> collectSurfaceTilePreviewTilesetIds({
  required MapData map,
  required ProjectSurfaceCatalog catalog,
}) {
  final presetIds = <String>{};
  for (final layer in map.layers.whereType<SurfaceLayer>()) {
    if (!layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    for (final placement in layer.placements) {
      final presetId = placement.surfacePresetId.trim();
      if (presetId.isNotEmpty) {
        presetIds.add(presetId);
      }
    }
  }
  if (presetIds.isEmpty) {
    return const <String>{};
  }

  final tilesetIds = <String>{};
  for (final presetId in presetIds) {
    final preset = catalog.presetById(presetId);
    if (preset == null) {
      continue;
    }
    for (final ref in preset.variantAnimations.refs) {
      final animation = catalog.animationById(ref.animationId.trim());
      if (animation == null || animation.timeline.frames.isEmpty) {
        continue;
      }
      final atlasId = animation.timeline.frames.first.tileRef.atlasId.trim();
      if (atlasId.isEmpty) {
        continue;
      }
      final atlas = catalog.atlasById(atlasId);
      final tilesetId = atlas?.tilesetId.trim();
      if (tilesetId != null && tilesetId.isNotEmpty) {
        tilesetIds.add(tilesetId);
      }
    }
  }
  return Set<String>.unmodifiable(tilesetIds);
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
