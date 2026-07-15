import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_feature.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_signed_int64.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import 'border_deterministic_rng.dart';
import 'border_rle_codec.dart';
import 'border_sprite_geometry.dart';

/// Final shared V1 pass for stable-slot overrides and keep-out masks.
@immutable
final class BorderOverrideResolution {
  BorderOverrideResolution._({
    required List<BorderResolvedGroundCell> ground,
    required List<BorderResolvedPlacement> placements,
    required this.diagnosticReport,
    required Set<String> orphanedSlotKeys,
    required Set<String> intentionalGapSlotKeys,
  })  : _ground = List<BorderResolvedGroundCell>.unmodifiable(ground),
        _placements = List<BorderResolvedPlacement>.unmodifiable(placements),
        _orphanedSlotKeys = _sortedUnmodifiableSet(orphanedSlotKeys),
        _intentionalGapSlotKeys =
            _sortedUnmodifiableSet(intentionalGapSlotKeys);

  final List<BorderResolvedGroundCell> _ground;
  final List<BorderResolvedPlacement> _placements;
  final Set<String> _orphanedSlotKeys;
  final Set<String> _intentionalGapSlotKeys;

  List<BorderResolvedGroundCell> get ground => _ground;

  List<BorderResolvedPlacement> get placements => _placements;

  final BorderDiagnosticsReport diagnosticReport;

  List<BorderDiagnostic> get diagnostics => diagnosticReport.diagnostics;

  Set<String> get orphanedSlotKeys => _orphanedSlotKeys;

  /// Slots deliberately removed by a suppression or keep-out.
  Set<String> get intentionalGapSlotKeys => _intentionalGapSlotKeys;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderOverrideResolution &&
          _listsEqual(_ground, other._ground) &&
          _listsEqual(_placements, other._placements) &&
          diagnosticReport == other.diagnosticReport &&
          _setsEqual(_orphanedSlotKeys, other._orphanedSlotKeys) &&
          _setsEqual(
            _intentionalGapSlotKeys,
            other._intentionalGapSlotKeys,
          );

  @override
  int get hashCode => Object.hash(
        Object.hashAll(_ground),
        Object.hashAll(_placements),
        diagnosticReport,
        Object.hashAllUnordered(_orphanedSlotKeys),
        Object.hashAllUnordered(_intentionalGapSlotKeys),
      );
}

/// Applies persisted overrides to already-generated slots, then masks output.
///
/// Base generation remains independent from overrides. This keeps slot
/// allocation and every placement outside the locally edited slots stable.
BorderOverrideResolution resolveBorderOverrides({
  required BorderResolutionRequest request,
  required Iterable<BorderResolvedGroundCell> baseGround,
  required Iterable<BorderResolvedPlacement> basePlacements,
  Set<String> alreadyResolvedSlotKeys = const <String>{},
  Map<String, BorderResolvedPlacement> previouslyResolvedPlacementsBySlot =
      const <String, BorderResolvedPlacement>{},
  Set<String> previouslySuppressedSlotKeys = const <String>{},
}) {
  final ground = baseGround.toList(growable: false);
  final placements = basePlacements.toList(growable: false);
  final diagnostics = <BorderDiagnostic>[];
  final orphaned = <String>{};
  final intentionalGaps = <String>{};
  final revision = request.blueprintRevision;
  if (revision == null) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.blueprint_unavailable',
        scope: BorderDiagnosticScope.blueprint,
        action: 'border.action.publish_blueprint',
      ),
    );
    return BorderOverrideResolution._(
      ground: ground,
      placements: placements,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
      orphanedSlotKeys: orphaned,
      intentionalGapSlotKeys: intentionalGaps,
    );
  }
  if (request.feature.overrides.isEmpty &&
      request.feature.keepOutRegions.isEmpty) {
    return BorderOverrideResolution._(
      ground: ground,
      placements: placements,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
      orphanedSlotKeys: orphaned,
      intentionalGapSlotKeys: intentionalGaps,
    );
  }

  final keepOutMask = _buildKeepOutMask(request, diagnostics);
  final hasKeepOutCells = keepOutMask.contains(true);

  final primitives = <String, BorderPublishedPrimitive>{
    for (final primitive in revision.definition.primitives)
      primitive.id: primitive,
  };
  final overridesBySlot = <String, BorderSlotOverride>{
    for (final override in request.feature.overrides)
      override.slotKey: override,
  };
  final baseSlots = <String>{
    for (final placement in placements) placement.slotKey,
  };
  for (final override in request.feature.overrides) {
    if (baseSlots.contains(override.slotKey)) {
      continue;
    }
    _validateOrphanOverrideReferences(
      request: request,
      override: override,
      primitives: primitives,
      diagnostics: diagnostics,
    );
    orphaned.add(override.slotKey);
    diagnostics.add(
      _warning(
        request,
        code: 'border.resolution.override_orphaned',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        action: 'border.action.remove_or_retarget_override',
      ),
    );
  }

  final resolvedPlacements = <BorderResolvedPlacement>[];
  for (final base in placements) {
    if (alreadyResolvedSlotKeys.contains(base.slotKey)) {
      if (previouslySuppressedSlotKeys.contains(base.slotKey)) {
        intentionalGaps.add(base.slotKey);
        continue;
      }
      final previous = previouslyResolvedPlacementsBySlot[base.slotKey];
      if (previous == null) {
        throw StateError(
          'Missing prior resolved Border placement for ${base.slotKey}',
        );
      }
      resolvedPlacements.add(previous);
      continue;
    }
    final override = overridesBySlot[base.slotKey];
    if (override?.suppressed ?? false) {
      intentionalGaps.add(base.slotKey);
      continue;
    }
    final resolved = override == null
        ? base
        : _resolvePlacementOverride(
            request: request,
            base: base,
            override: override,
            primitives: primitives,
            diagnostics: diagnostics,
          );
    final primitive = primitives[resolved.primitiveId];
    if (hasKeepOutCells &&
        primitive != null &&
        _placementIntersectsKeepOut(
          placement: resolved,
          primitive: primitive,
          keepOutMask: keepOutMask,
          mapSize: request.mapSize,
          tileSizePx: request.tileSizePx,
        )) {
      intentionalGaps.add(base.slotKey);
      continue;
    }
    resolvedPlacements.add(resolved);
  }
  resolvedPlacements.sort(
    (left, right) => left.stableOrderKey.compareTo(right.stableOrderKey),
  );

  final resolvedGround = <BorderResolvedGroundCell>[
    for (final cell in ground)
      if (!hasKeepOutCells ||
          !_cellIsKeptOut(
            x: cell.x,
            y: cell.y,
            keepOutMask: keepOutMask,
            mapWidth: request.mapSize.width,
            mapHeight: request.mapSize.height,
          ))
        cell,
  ];

  return BorderOverrideResolution._(
    ground: resolvedGround,
    placements: resolvedPlacements,
    diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    orphanedSlotKeys: orphaned,
    intentionalGapSlotKeys: intentionalGaps,
  );
}

BorderResolvedPlacement _resolvePlacementOverride({
  required BorderResolutionRequest request,
  required BorderResolvedPlacement base,
  required BorderSlotOverride override,
  required Map<String, BorderPublishedPrimitive> primitives,
  required List<BorderDiagnostic> diagnostics,
}) {
  final basePrimitive = primitives[base.primitiveId];
  if (basePrimitive == null) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_base_primitive_missing',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{'primitiveId': base.primitiveId},
        action: 'border.action.republish_blueprint',
      ),
    );
    return base;
  }

  final locked = override.lockedPlacement;
  if (locked != null) {
    return _validateLockedPlacement(
      request: request,
      base: base,
      locked: locked,
      primitives: primitives,
      diagnostics: diagnostics,
    )
        ? locked
        : base;
  }

  var primitive = basePrimitive;
  final transform = override.transformOverride ?? base.transform;
  final replacementId = override.replacementPrimitiveId;
  if (replacementId != null) {
    final replacement = primitives[replacementId];
    if (replacement == null) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_primitive_missing',
          scope: BorderDiagnosticScope.slot,
          slotKey: override.slotKey,
          parameters: <String, Object?>{'primitiveId': replacementId},
          action: 'border.action.remove_or_retarget_override',
        ),
      );
      return base;
    }
    if (replacement.role != basePrimitive.role) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_primitive_role_mismatch',
          scope: BorderDiagnosticScope.slot,
          slotKey: override.slotKey,
          parameters: <String, Object?>{'primitiveId': replacementId},
          action: 'border.action.choose_compatible_primitive',
        ),
      );
      return base;
    }
    primitive = replacement;
  } else if (override.variationSalt != BorderSignedInt64.zero) {
    final candidates = primitives.values.where(
      (candidate) =>
          candidate.role == basePrimitive.role &&
          _transformAllowed(candidate, transform),
    );
    final selected = chooseBorderWeightedCandidate(
      BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
        BorderRngKeyComponent.text(request.feature.id),
        BorderRngKeyComponent.text(base.slotKey),
        BorderRngKeyComponent.signedInt64(request.feature.seed),
        BorderRngKeyComponent.signedInt64(override.variationSalt),
        const BorderRngKeyComponent.text('override-local-variation'),
      ]),
      <BorderWeightedCandidate<BorderPublishedPrimitive>>[
        for (final candidate in candidates)
          BorderWeightedCandidate<BorderPublishedPrimitive>(
            id: candidate.id,
            value: candidate,
            weight: candidate.weight,
          ),
      ],
    );
    if (selected != null) {
      primitive = selected.value;
    }
  }

  if (!_transformAllowed(primitive, transform)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_transform_not_allowed',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{
          'primitiveId': primitive.id,
          'quarterTurns': transform.quarterTurns,
          'flipX': transform.flipX,
        },
        action: 'border.action.choose_allowed_transform',
      ),
    );
    return base;
  }
  if (!_snapshotValidForPrimitive(request, primitive)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_snapshot_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{
          'snapshotId': primitive.visualSnapshotId,
        },
        action: 'border.action.restore_or_republish_snapshot',
      ),
    );
    return base;
  }

  final offset = override.offsetDeltaPx ?? const BorderPixelOffset(x: 0, y: 0);
  if (!_offsetInsideCorridor(request, offset.x, offset.y)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_outside_corridor',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{'offsetX': offset.x, 'offsetY': offset.y},
        action: 'border.action.move_override_inside_corridor',
      ),
    );
    return base;
  }

  try {
    final baseOrigin = resolveBorderSpriteGeometry(
      metrics: basePrimitive.publishedMetrics,
      sourceAnchorPx: basePrimitive.anchorPx,
      transform: base.transform,
      targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
    );
    final target = BorderPixelPos(
      x: base.topLeftWorldPx.x - baseOrigin.topLeftWorldPx.x + offset.x,
      y: base.topLeftWorldPx.y - baseOrigin.topLeftWorldPx.y + offset.y,
    );
    final sprite = resolveBorderSpriteGeometry(
      metrics: primitive.publishedMetrics,
      sourceAnchorPx: primitive.anchorPx,
      transform: transform,
      targetAnchorWorldPx: target,
    );
    if (!_intersectsCanvas(request, sprite.opaqueWorldBoundsPx)) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_outside_canvas',
          scope: BorderDiagnosticScope.slot,
          slotKey: override.slotKey,
          action: 'border.action.move_override_inside_canvas',
        ),
      );
      return base;
    }
    return BorderResolvedPlacement(
      id: base.id,
      slotKey: base.slotKey,
      primitiveId: primitive.id,
      visualSnapshotId: primitive.visualSnapshotId,
      anchorCell: base.anchorCell,
      topLeftWorldPx: sprite.topLeftWorldPx,
      opaqueWorldBoundsPx: sprite.opaqueWorldBoundsPx,
      transform: transform,
      drawBand: base.drawBand,
      stableOrderKey: base.stableOrderKey,
    );
  } on ValidationException {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_geometry_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        action: 'border.action.reset_override_geometry',
      ),
    );
    return base;
  }
}

bool _validateLockedPlacement({
  required BorderResolutionRequest request,
  required BorderResolvedPlacement base,
  required BorderResolvedPlacement locked,
  required Map<String, BorderPublishedPrimitive> primitives,
  required List<BorderDiagnostic> diagnostics,
}) {
  final basePrimitive = primitives[base.primitiveId];
  if (basePrimitive == null) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_base_primitive_missing',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        parameters: <String, Object?>{'primitiveId': base.primitiveId},
        action: 'border.action.republish_blueprint',
      ),
    );
    return false;
  }
  final primitive = primitives[locked.primitiveId];
  if (primitive == null) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_primitive_missing',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        parameters: <String, Object?>{'primitiveId': locked.primitiveId},
        action: 'border.action.remove_or_retarget_override',
      ),
    );
    return false;
  }
  if (primitive.role != basePrimitive.role) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_primitive_role_mismatch',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.choose_compatible_primitive',
      ),
    );
    return false;
  }
  if (locked.id != base.id ||
      locked.anchorCell != base.anchorCell ||
      locked.drawBand != base.drawBand ||
      locked.stableOrderKey != base.stableOrderKey) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_anchor_or_order_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        action: 'border.action.relock_current_slot',
      ),
    );
    return false;
  }
  if (locked.visualSnapshotId != primitive.visualSnapshotId ||
      !_snapshotValidForPrimitive(request, primitive)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_snapshot_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        parameters: <String, Object?>{
          'snapshotId': locked.visualSnapshotId,
        },
        action: 'border.action.restore_or_remove_locked_override',
      ),
    );
    return false;
  }
  if (!_transformAllowed(primitive, locked.transform)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_transform_not_allowed',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        action: 'border.action.choose_allowed_transform',
      ),
    );
    return false;
  }
  try {
    final baseTarget = _targetAnchorWorldPx(
      placement: base,
      primitive: basePrimitive,
    );
    final lockedTarget = _targetAnchorWorldPx(
      placement: locked,
      primitive: primitive,
    );
    final expected = resolveBorderSpriteGeometry(
      metrics: primitive.publishedMetrics,
      sourceAnchorPx: primitive.anchorPx,
      transform: locked.transform,
      targetAnchorWorldPx: lockedTarget,
    );
    if (expected.opaqueWorldBoundsPx != locked.opaqueWorldBoundsPx) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_geometry_invalid',
          scope: BorderDiagnosticScope.slot,
          slotKey: locked.slotKey,
          action: 'border.action.relock_current_slot',
        ),
      );
      return false;
    }
    final deltaX = lockedTarget.x - baseTarget.x;
    final deltaY = lockedTarget.y - baseTarget.y;
    if (!_offsetInsideCorridor(request, deltaX, deltaY)) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_outside_corridor',
          scope: BorderDiagnosticScope.slot,
          slotKey: locked.slotKey,
          action: 'border.action.move_override_inside_corridor',
        ),
      );
      return false;
    }
    if (!_intersectsCanvas(request, locked.opaqueWorldBoundsPx)) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_outside_canvas',
          scope: BorderDiagnosticScope.slot,
          slotKey: locked.slotKey,
          action: 'border.action.move_override_inside_canvas',
        ),
      );
      return false;
    }
  } on ValidationException {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_geometry_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        action: 'border.action.relock_current_slot',
      ),
    );
    return false;
  }
  return true;
}

void _validateOrphanOverrideReferences({
  required BorderResolutionRequest request,
  required BorderSlotOverride override,
  required Map<String, BorderPublishedPrimitive> primitives,
  required List<BorderDiagnostic> diagnostics,
}) {
  if (override.suppressed) {
    return;
  }
  final locked = override.lockedPlacement;
  final primitiveId = locked?.primitiveId ?? override.replacementPrimitiveId;
  if (primitiveId == null) {
    return;
  }
  final primitive = primitives[primitiveId];
  if (primitive == null) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_primitive_missing',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{'primitiveId': primitiveId},
        action: 'border.action.remove_or_retarget_override',
      ),
    );
    return;
  }
  if (!_snapshotValidForPrimitive(request, primitive) ||
      (locked != null &&
          locked.visualSnapshotId != primitive.visualSnapshotId)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_snapshot_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{
          'snapshotId': locked?.visualSnapshotId ?? primitive.visualSnapshotId,
        },
        action: 'border.action.restore_or_remove_locked_override',
      ),
    );
    return;
  }
  final transform = locked?.transform ?? override.transformOverride;
  if (transform != null && !_transformAllowed(primitive, transform)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_transform_not_allowed',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.choose_allowed_transform',
      ),
    );
  }
}

BorderPixelPos _targetAnchorWorldPx({
  required BorderResolvedPlacement placement,
  required BorderPublishedPrimitive primitive,
}) {
  final origin = resolveBorderSpriteGeometry(
    metrics: primitive.publishedMetrics,
    sourceAnchorPx: primitive.anchorPx,
    transform: placement.transform,
    targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
  );
  return BorderPixelPos(
    x: placement.topLeftWorldPx.x - origin.topLeftWorldPx.x,
    y: placement.topLeftWorldPx.y - origin.topLeftWorldPx.y,
  );
}

List<bool> _buildKeepOutMask(
  BorderResolutionRequest request,
  List<BorderDiagnostic> diagnostics,
) {
  final mask = List<bool>.filled(
    request.mapSize.width * request.mapSize.height,
    false,
    growable: false,
  );
  for (final keepOut in request.feature.keepOutRegions) {
    if (keepOut.region.width != request.mapSize.width ||
        keepOut.region.height != request.mapSize.height) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.keep_out_size_mismatch',
          scope: BorderDiagnosticScope.geometry,
          parameters: <String, Object?>{'keepOutId': keepOut.id},
          action: 'border.action.resize_keep_out_to_map',
        ),
      );
      continue;
    }
    for (var index = 0; index < mask.length; index += 1) {
      mask[index] = mask[index] || keepOut.region.cells[index];
    }
  }
  return mask;
}

bool _placementIntersectsKeepOut({
  required BorderResolvedPlacement placement,
  required BorderPublishedPrimitive primitive,
  required List<bool> keepOutMask,
  required GridSize mapSize,
  required GridSize tileSizePx,
}) {
  final metrics = primitive.publishedMetrics;
  final width = metrics.pixelSize.width;
  final height = metrics.pixelSize.height;
  var intersects = false;
  visitBorderRleTrueRuns(
    metrics.occupancyMaskRle,
    expectedLength: checkedBorderRleCellCount(
      width: width,
      height: height,
      path: r'$.publishedMetrics.pixelSize',
    ),
    path: r'$.publishedMetrics.occupancyMaskRle',
    visitor: (start, end) {
      for (var index = start; index < end && !intersects; index += 1) {
        final transformed = _transformSourcePixel(
          x: index % width,
          y: index ~/ width,
          width: width,
          height: height,
          transform: placement.transform,
        );
        final worldX = placement.topLeftWorldPx.x + transformed.$1;
        final worldY = placement.topLeftWorldPx.y + transformed.$2;
        if (worldX < 0 || worldY < 0) {
          continue;
        }
        final cellX = worldX ~/ tileSizePx.width;
        final cellY = worldY ~/ tileSizePx.height;
        if (cellX >= mapSize.width || cellY >= mapSize.height) {
          continue;
        }
        intersects = keepOutMask[cellY * mapSize.width + cellX];
      }
    },
  );
  return intersects;
}

(int, int) _transformSourcePixel({
  required int x,
  required int y,
  required int width,
  required int height,
  required BorderSpriteTransform transform,
}) {
  final flippedX = transform.flipX ? width - 1 - x : x;
  return switch (transform.quarterTurns) {
    0 => (flippedX, y),
    1 => (height - 1 - y, flippedX),
    2 => (width - 1 - flippedX, height - 1 - y),
    3 => (y, width - 1 - flippedX),
    _ => throw const ValidationException(
        'Border quarterTurns must be between 0 and 3',
      ),
  };
}

bool _offsetInsideCorridor(
  BorderResolutionRequest request,
  int deltaX,
  int deltaY,
) {
  final definition = request.blueprintRevision!.definition;
  final parameters = request.feature.paramsOverride ?? definition.defaults;
  final tileSize = request.tileSizePx.width > request.tileSizePx.height
      ? request.tileSizePx.width
      : request.tileSizePx.height;
  final radius = computeBorderDirtyHaloRadiusPx(
    depthRows: parameters.depthRows,
    tileSizePx: tileSize,
    largestTransformedOpaqueExtentPx: maximumBorderTransformedOpaqueExtentPx(
      definition.primitives.map((primitive) => primitive.publishedMetrics),
    ),
    jitterMaxPx: computeBorderJitterMaxPx(
      irregularityPermille: parameters.irregularityPermille,
      tileSizePx: tileSize,
    ),
    maxOverlapPx: parameters.maxOverlapPx,
    gapTolerancePx: parameters.gapTolerancePx,
  );
  final absoluteX = BigInt.from(deltaX).abs();
  final absoluteY = BigInt.from(deltaY).abs();
  final bound = BigInt.from(radius);
  return absoluteX <= bound && absoluteY <= bound;
}

bool _transformAllowed(
  BorderPublishedPrimitive primitive,
  BorderSpriteTransform transform,
) =>
    primitive.transforms.allowedQuarterTurns.contains(transform.quarterTurns) &&
    (!transform.flipX || primitive.transforms.allowFlipX);

bool _snapshotValidForPrimitive(
  BorderResolutionRequest request,
  BorderPublishedPrimitive primitive,
) {
  final snapshot = request.visualSnapshotById(primitive.visualSnapshotId);
  if (snapshot == null) {
    return false;
  }
  final size = primitive.publishedMetrics.pixelSize;
  return snapshot.frames.every(
    (frame) =>
        frame.sourceRectPx.width == size.width &&
        frame.sourceRectPx.height == size.height,
  );
}

bool _intersectsCanvas(
  BorderResolutionRequest request,
  BorderPixelRect bounds,
) =>
    borderPixelRectIntersectsCanvas(
      rect: bounds,
      canvasSizePx: GridSize(
        width: request.mapSize.width * request.tileSizePx.width,
        height: request.mapSize.height * request.tileSizePx.height,
      ),
    );

bool _cellIsKeptOut({
  required int x,
  required int y,
  required List<bool> keepOutMask,
  required int mapWidth,
  required int mapHeight,
}) =>
    x >= 0 &&
    y >= 0 &&
    x < mapWidth &&
    y < mapHeight &&
    keepOutMask[y * mapWidth + x];

BorderDiagnostic _error(
  BorderResolutionRequest request, {
  required String code,
  required BorderDiagnosticScope scope,
  String? slotKey,
  Map<String, Object?> parameters = const <String, Object?>{},
  required String action,
}) =>
    BorderDiagnostic(
      code: code,
      severity: BorderDiagnosticSeverity.error,
      phase: BorderDiagnosticPhase.resolution,
      scope: scope,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      slotKey: slotKey,
      parameters: parameters,
      suggestedAction: action,
    );

BorderDiagnostic _warning(
  BorderResolutionRequest request, {
  required String code,
  required BorderDiagnosticScope scope,
  String? slotKey,
  required String action,
}) =>
    BorderDiagnostic(
      code: code,
      severity: BorderDiagnosticSeverity.warning,
      phase: BorderDiagnosticPhase.resolution,
      scope: scope,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      slotKey: slotKey,
      suggestedAction: action,
    );

bool _listsEqual<T>(List<T> first, List<T> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

bool _setsEqual<T>(Set<T> first, Set<T> second) =>
    first.length == second.length && first.containsAll(second);

Set<String> _sortedUnmodifiableSet(Iterable<String> values) {
  final sorted = values.toList(growable: false)..sort();
  return Set<String>.unmodifiable(sorted);
}
