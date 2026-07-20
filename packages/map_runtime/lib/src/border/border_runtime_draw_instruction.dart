import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

/// One passive draw command derived only from persisted materialization.
@immutable
sealed class BorderRuntimeDrawInstruction {
  const BorderRuntimeDrawInstruction({
    required this.featureId,
    required this.snapshotId,
  });

  final String featureId;
  final String snapshotId;

  BorderPixelRect get cullingBoundsPx;
}

/// One already-resolved cell of Surface-like ground.
@immutable
final class BorderRuntimeGroundInstruction
    extends BorderRuntimeDrawInstruction {
  const BorderRuntimeGroundInstruction({
    required super.featureId,
    required super.snapshotId,
    required this.cellX,
    required this.cellY,
    required this.worldBoundsPx,
  });

  final int cellX;
  final int cellY;
  final BorderPixelRect worldBoundsPx;

  @override
  BorderPixelRect get cullingBoundsPx => worldBoundsPx;
}

/// One already-resolved native-size prop placement.
@immutable
final class BorderRuntimePlacementInstruction
    extends BorderRuntimeDrawInstruction {
  const BorderRuntimePlacementInstruction({
    required super.featureId,
    required super.snapshotId,
    required this.placementId,
    required this.topLeftWorldPx,
    required this.opaqueWorldBoundsPx,
    required this.transform,
  });

  final String placementId;
  final BorderPixelPos topLeftWorldPx;
  final BorderPixelRect opaqueWorldBoundsPx;
  final BorderSpriteTransform transform;

  @override
  BorderPixelRect get cullingBoundsPx => opaqueWorldBoundsPx;
}

/// Passive instructions and visual metadata for one authored Border layer.
@immutable
final class BorderRuntimeDrawInstructionCollection {
  BorderRuntimeDrawInstructionCollection({
    required this.layerId,
    required this.isVisible,
    required this.opacity,
    required List<BorderRuntimeDrawInstruction> instructions,
  }) : instructions =
            List<BorderRuntimeDrawInstruction>.unmodifiable(instructions) {
    if (!opacity.isFinite || opacity < 0 || opacity > 1) {
      throw ArgumentError.value(opacity, 'opacity', 'must be between 0 and 1');
    }
  }

  final String layerId;
  final bool isVisible;
  final double opacity;
  final List<BorderRuntimeDrawInstruction> instructions;
}

/// Flattens saved materialization without solving or re-sorting anything.
///
/// All grounds across authored feature order are emitted first. Placements
/// then retain the exact persisted list order inside the same feature order,
/// even when stable keys from different features conflict.
BorderRuntimeDrawInstructionCollection buildBorderRuntimeDrawInstructions({
  required BorderLayer layer,
  required int tileWidthPx,
  required int tileHeightPx,
}) {
  if (tileWidthPx <= 0 || tileHeightPx <= 0) {
    throw ArgumentError('Border runtime tile dimensions must be positive');
  }
  final instructions = <BorderRuntimeDrawInstruction>[];

  for (final feature in layer.content.features) {
    final materialization = feature.materialization;
    if (materialization == null) {
      continue;
    }
    for (final ground in materialization.ground) {
      instructions.add(
        BorderRuntimeGroundInstruction(
          featureId: feature.id,
          snapshotId: ground.visualSnapshotId,
          cellX: ground.x,
          cellY: ground.y,
          worldBoundsPx: BorderPixelRect(
            x: ground.x * tileWidthPx,
            y: ground.y * tileHeightPx,
            width: tileWidthPx,
            height: tileHeightPx,
          ),
        ),
      );
    }
  }

  for (final feature in layer.content.features) {
    final materialization = feature.materialization;
    if (materialization == null) {
      continue;
    }
    for (final placement in materialization.placements) {
      instructions.add(
        BorderRuntimePlacementInstruction(
          featureId: feature.id,
          snapshotId: placement.visualSnapshotId,
          placementId: placement.id,
          topLeftWorldPx: placement.topLeftWorldPx,
          opaqueWorldBoundsPx: placement.opaqueWorldBoundsPx,
          transform: placement.transform,
        ),
      );
    }
  }

  return BorderRuntimeDrawInstructionCollection(
    layerId: layer.id,
    isVisible: layer.isVisible,
    opacity: layer.opacity,
    instructions: instructions,
  );
}
