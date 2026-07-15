import '../exceptions/map_exceptions.dart';
import '../models/border_feature.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import 'border_fingerprints.dart';
import 'border_local_resolution_scope.dart';
import 'masonry_line_border_resolver.dart';
import 'organic_edge_border_resolver.dart';
import 'post_and_rail_line_border_resolver.dart';
import 'border_sprite_geometry.dart';

/// One authoring edit expressed as the pixel domains it can influence.
final class BorderLocalEdit {
  BorderLocalEdit._(List<BorderPixelRect> sourceBoundsPx)
      : _sourceBoundsPx = List<BorderPixelRect>.unmodifiable(sourceBoundsPx);

  /// Describes a manual placement move, including its complete swept domain.
  factory BorderLocalEdit.forManualMove({
    required BorderPixelRect oldOpaqueBoundsPx,
    required BorderPixelRect newOpaqueBoundsPx,
  }) =>
      BorderLocalEdit._(<BorderPixelRect>[
        oldOpaqueBoundsPx,
        newOpaqueBoundsPx,
        _boundingEnvelope(oldOpaqueBoundsPx, newOpaqueBoundsPx),
      ]);

  /// Describes region paint/erase or stroke cells changed by one gesture.
  factory BorderLocalEdit.forCells({
    required Iterable<GridPos> cells,
    required GridSize tileSizePx,
  }) {
    if (tileSizePx.width <= 0 || tileSizePx.height <= 0) {
      throw const ValidationException(
        'Border local edit tile dimensions must be > 0',
      );
    }
    final canonicalCells = cells.toSet().toList(growable: false)
      ..sort((first, second) {
        final row = first.y.compareTo(second.y);
        return row != 0 ? row : first.x.compareTo(second.x);
      });
    if (canonicalCells.isEmpty) {
      throw const ValidationException(
        'Border local edit requires at least one changed cell',
      );
    }
    return BorderLocalEdit._(<BorderPixelRect>[
      for (final cell in canonicalCells)
        BorderPixelRect(
          x: (BigInt.from(cell.x) * BigInt.from(tileSizePx.width)).toInt(),
          y: (BigInt.from(cell.y) * BigInt.from(tileSizePx.height)).toInt(),
          width: tileSizePx.width,
          height: tileSizePx.height,
        ),
    ]);
  }

  final List<BorderPixelRect> _sourceBoundsPx;

  List<BorderPixelRect> get sourceBoundsPx => _sourceBoundsPx;
}

/// Conservative pixel region containing every subproblem affected by edits.
final class BorderDirtyHalo {
  BorderDirtyHalo._({
    required this.radiusPx,
    required List<BorderPixelRect> affectedBoundsPx,
  }) : _affectedBoundsPx = List<BorderPixelRect>.unmodifiable(affectedBoundsPx);

  final int radiusPx;
  final List<BorderPixelRect> _affectedBoundsPx;

  List<BorderPixelRect> get affectedBoundsPx => _affectedBoundsPx;

  bool intersects(BorderPixelRect bounds) =>
      _affectedBoundsPx.any((dirty) => _rectanglesIntersect(dirty, bounds));
}

/// Canonical resolution rebuilt with identity-preserved distant output.
final class BorderLocalResolutionResult {
  BorderLocalResolutionResult._({
    required this.dirtyHalo,
    required this.result,
    required this.nextState,
    required List<String> reusedDistantPlacementSlotKeys,
    required List<(int, int)> reusedDistantGroundCoordinates,
    required List<GridPos> recomputedSourceCells,
  })  : _reusedDistantPlacementSlotKeys =
            List<String>.unmodifiable(reusedDistantPlacementSlotKeys),
        _reusedDistantGroundCoordinates =
            List<(int, int)>.unmodifiable(reusedDistantGroundCoordinates),
        _recomputedSourceCells =
            List<GridPos>.unmodifiable(recomputedSourceCells);

  final BorderDirtyHalo dirtyHalo;
  final BorderResolutionResult result;
  final BorderLocalResolutionState? nextState;
  final List<String> _reusedDistantPlacementSlotKeys;
  final List<(int, int)> _reusedDistantGroundCoordinates;
  final List<GridPos> _recomputedSourceCells;

  List<String> get reusedDistantPlacementSlotKeys =>
      _reusedDistantPlacementSlotKeys;

  List<(int, int)> get reusedDistantGroundCoordinates =>
      _reusedDistantGroundCoordinates;

  /// Source cells whose placement or ground generation branch was entered.
  List<GridPos> get recomputedSourceCells => _recomputedSourceCells;
}

/// Computes the approved V1 dirty-halo radius from one complete request.
///
/// Border locality is pixel-only. For non-square tiles, the larger axis is
/// used conservatively for both the depth and jitter terms.
int computeBorderDirtyHaloRadiusForRequestPx(
  BorderResolutionRequest request,
) {
  final revision = request.blueprintRevision;
  if (revision == null) {
    throw const ValidationException(
      'Border locality requires a published blueprint revision',
    );
  }
  final parameters =
      request.feature.paramsOverride ?? revision.definition.defaults;
  final tileSizePx = request.tileSizePx.width > request.tileSizePx.height
      ? request.tileSizePx.width
      : request.tileSizePx.height;
  final placementRadius = computeBorderDirtyHaloRadiusPx(
    depthRows: parameters.depthRows,
    tileSizePx: tileSizePx,
    largestTransformedOpaqueExtentPx: maximumBorderTransformedOpaqueExtentPx(
      revision.definition.primitives.map(
        (primitive) => primitive.publishedMetrics,
      ),
    ),
    jitterMaxPx: computeBorderJitterMaxPx(
      irregularityPermille: parameters.irregularityPermille,
      tileSizePx: tileSizePx,
    ),
    maxOverlapPx: parameters.maxOverlapPx,
    gapTolerancePx: parameters.gapTolerancePx,
  );
  final groundRadius = revision.definition.ground == null
      ? 0
      : revision.definition.ground!.edgeBandCells * tileSizePx;
  return placementRadius > groundRadius ? placementRadius : groundRadius;
}

/// Expands every edit source by the approved request-local pixel radius.
BorderDirtyHalo computeBorderDirtyHalo({
  required BorderResolutionRequest request,
  required Iterable<BorderLocalEdit> edits,
}) {
  final editList = edits.toList(growable: false);
  if (editList.isEmpty) {
    throw const ValidationException(
      'Border dirty halo requires at least one local edit',
    );
  }
  final radiusPx = computeBorderDirtyHaloRadiusForRequestPx(request);
  return BorderDirtyHalo._(
    radiusPx: radiusPx,
    affectedBoundsPx: <BorderPixelRect>[
      for (final edit in editList)
        for (final bounds in edit.sourceBoundsPx) _expand(bounds, radiusPx),
    ],
  );
}

/// Produces the canonical pre/post-override baseline required by local edits.
///
/// This is the explicit full-resolution entrypoint. Later calls to
/// [resolveBorderFeatureLocally] never invoke a complete template solver.
BorderLocalResolutionState resolveBorderFeatureLocalBaseline(
  BorderResolutionRequest request,
) {
  final revision = request.blueprintRevision;
  if (revision == null) {
    throw const ValidationException(
      'Border local baseline requires a published blueprint revision',
    );
  }
  final capture = BorderLocalResolutionCapture();
  final result = switch (revision.definition.template) {
    BorderBlueprintTemplate.organicEdge => resolveOrganicEdgeBorderWithEvidence(
        request,
        localCapture: capture,
      ).result,
    BorderBlueprintTemplate.masonryLine => resolveMasonryLineBorderWithEvidence(
        request,
        localCapture: capture,
      ).result,
    BorderBlueprintTemplate.postAndRailLine =>
      resolvePostAndRailLineBorderWithEvidence(
        request,
        localCapture: capture,
      ).result,
  };
  return capture.finish(request: request, result: result);
}

/// Regenerates only subproblems intersecting the conservative dirty halo.
///
/// Validation, coverage reductions, sorting, and fingerprints still consume
/// the merged global trace; no distant placement or ground generation branch
/// is entered.
BorderLocalResolutionResult resolveBorderFeatureLocally({
  required BorderResolutionRequest request,
  required BorderLocalResolutionState previousState,
  required Iterable<BorderLocalEdit> edits,
}) {
  _validateLocalBaselineCompatibility(request, previousState);
  final dirtyHalo = computeBorderDirtyHalo(request: request, edits: edits);
  final changedOverrideSlotKeys = _validateChangedOverrideInputs(
    request: request,
    previousState: previousState,
    dirtyHalo: dirtyHalo,
  );
  final revision = request.blueprintRevision!;
  final capture = BorderLocalResolutionCapture();
  final scope = BorderLocalResolutionScope(
    previousState: previousState,
    affectedBoundsPx: dirtyHalo.affectedBoundsPx,
  );
  final result = switch (revision.definition.template) {
    BorderBlueprintTemplate.organicEdge => resolveOrganicEdgeBorderWithEvidence(
        request,
        localScope: scope,
        localCapture: capture,
      ).result,
    BorderBlueprintTemplate.masonryLine => resolveMasonryLineBorderWithEvidence(
        request,
        localScope: scope,
        localCapture: capture,
      ).result,
    BorderBlueprintTemplate.postAndRailLine =>
      resolvePostAndRailLineBorderWithEvidence(
        request,
        localScope: scope,
        localCapture: capture,
      ).result,
  };
  final materialization = result.materialization;
  if (materialization == null) {
    return BorderLocalResolutionResult._(
      dirtyHalo: dirtyHalo,
      result: result,
      nextState: null,
      reusedDistantPlacementSlotKeys: const <String>[],
      reusedDistantGroundCoordinates: const <(int, int)>[],
      recomputedSourceCells: scope.recomputedSourceCells,
    );
  }
  _validateChangedOverrideOutputs(
    changedSlotKeys: changedOverrideSlotKeys,
    materialization: materialization,
    dirtyHalo: dirtyHalo,
  );
  final nextState = capture.finish(request: request, result: result);
  final previousMaterialization = previousState.materialization;
  final previousPlacements = <String, BorderResolvedPlacement>{
    for (final placement in previousMaterialization.placements)
      placement.slotKey: placement,
  };
  final previousGround = <(int, int), BorderResolvedGroundCell>{
    for (final cell in previousMaterialization.ground) (cell.x, cell.y): cell,
  };
  return BorderLocalResolutionResult._(
    dirtyHalo: dirtyHalo,
    result: result,
    nextState: nextState,
    reusedDistantPlacementSlotKeys: <String>[
      for (final placement in materialization.placements)
        if (identical(previousPlacements[placement.slotKey], placement))
          placement.slotKey,
    ],
    reusedDistantGroundCoordinates: <(int, int)>[
      for (final cell in materialization.ground)
        if (identical(previousGround[(cell.x, cell.y)], cell)) (cell.x, cell.y),
    ],
    recomputedSourceCells: scope.recomputedSourceCells,
  );
}

void _validateLocalBaselineCompatibility(
  BorderResolutionRequest request,
  BorderLocalResolutionState previousState,
) {
  final revision = request.blueprintRevision;
  if (revision == null) {
    throw const ValidationException(
      'Border local regeneration requires a published blueprint revision',
    );
  }
  final previousRequest = previousState.request;
  final previousReceipt = previousState.materialization.receipt;
  final current = computeBorderInputFingerprints(request);
  final compatible =
      request.resolverVersion == previousReceipt.resolverVersion &&
          revision.revision == previousReceipt.blueprintRevision &&
          request.blueprintId == previousRequest.blueprintId &&
          request.feature.id == previousRequest.feature.id &&
          request.feature.seed == previousRequest.feature.seed &&
          current.blueprint == previousReceipt.components.blueprint &&
          current.parameters == previousReceipt.components.parameters &&
          current.mapContext == previousReceipt.components.mapContext &&
          current.visualSnapshots == previousReceipt.components.visualSnapshots;
  if (!compatible) {
    throw const ValidationException(
      'Border local regeneration only accepts geometry, override, or '
      'keep-out edits from its canonical baseline',
    );
  }
}

Set<String> _validateChangedOverrideInputs({
  required BorderResolutionRequest request,
  required BorderLocalResolutionState previousState,
  required BorderDirtyHalo dirtyHalo,
}) {
  final previous = <String, BorderSlotOverride>{
    for (final override in previousState.request.feature.overrides)
      override.slotKey: override,
  };
  final current = <String, BorderSlotOverride>{
    for (final override in request.feature.overrides)
      override.slotKey: override,
  };
  final changed = <String>{
    for (final slotKey in <String>{...previous.keys, ...current.keys})
      if (previous[slotKey] != current[slotKey]) slotKey,
  };
  if (changed.isEmpty) return changed;

  final baseBySlot = <String, BorderResolvedPlacement>{
    for (final placement in previousState.basePlacements)
      placement.slotKey: placement,
  };
  final resolvedBySlot = previousState.resolvedPlacementsBySlot;
  for (final slotKey in changed) {
    final base = baseBySlot[slotKey];
    final resolved = resolvedBySlot[slotKey];
    if ((base == null || !dirtyHalo.intersects(base.opaqueWorldBoundsPx)) &&
        (resolved == null ||
            !dirtyHalo.intersects(resolved.opaqueWorldBoundsPx))) {
      throw ValidationException(
        'Changed Border override $slotKey lies outside the declared local '
        'edit halo',
      );
    }
  }
  return changed;
}

void _validateChangedOverrideOutputs({
  required Set<String> changedSlotKeys,
  required BorderMaterialization materialization,
  required BorderDirtyHalo dirtyHalo,
}) {
  if (changedSlotKeys.isEmpty) return;
  for (final placement in materialization.placements) {
    if (changedSlotKeys.contains(placement.slotKey) &&
        !dirtyHalo.intersects(placement.opaqueWorldBoundsPx)) {
      throw ValidationException(
        'Changed Border override ${placement.slotKey} resolved outside the '
        'declared local edit halo',
      );
    }
  }
}

BorderPixelRect _boundingEnvelope(
  BorderPixelRect first,
  BorderPixelRect second,
) {
  final left = first.x < second.x ? first.x : second.x;
  final top = first.y < second.y ? first.y : second.y;
  final right = first.right > second.right ? first.right : second.right;
  final bottom = first.bottom > second.bottom ? first.bottom : second.bottom;
  return BorderPixelRect(
    x: left,
    y: top,
    width: right - left,
    height: bottom - top,
  );
}

BorderPixelRect _expand(BorderPixelRect bounds, int radiusPx) {
  final radius = BigInt.from(radiusPx);
  final left = BigInt.from(bounds.x) - radius;
  final top = BigInt.from(bounds.y) - radius;
  final width = BigInt.from(bounds.width) + radius * BigInt.two;
  final height = BigInt.from(bounds.height) + radius * BigInt.two;
  return BorderPixelRect(
    x: left.toInt(),
    y: top.toInt(),
    width: width.toInt(),
    height: height.toInt(),
  );
}

bool _rectanglesIntersect(BorderPixelRect first, BorderPixelRect second) =>
    first.x < second.right &&
    first.right > second.x &&
    first.y < second.bottom &&
    first.bottom > second.y;
