import '../exceptions/map_exceptions.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import 'border_fingerprints.dart';
import 'border_linear_lattice.dart';
import 'border_local_resolution_scope.dart';
import 'masonry_line_border_resolver.dart';
import 'organic_edge_border_resolver.dart';
import 'post_and_rail_line_border_resolver.dart';
import 'border_sprite_geometry.dart';
import 'border_stroke_canonicalization.dart';
import 'connected_line_border_resolver.dart';
import 'stone_chain_line_border_resolver.dart';

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
  var semanticFaceReachPx = 0;
  if (revision.definition.template == BorderBlueprintTemplate.stoneChainLine &&
      parameters.depthRows >= 2) {
    for (final primitive in revision.definition.primitives) {
      if (primitive.weight <= 0 ||
          primitive.role != BorderPrimitiveRole.structureMedium) {
        continue;
      }
      final bounds = primitive.publishedMetrics.opaqueBounds;
      final reach = bounds.width > bounds.height ? bounds.width : bounds.height;
      if (reach > semanticFaceReachPx) semanticFaceReachPx = reach;
    }
    // A two-tier face can change one complete grid-edge station even when its
    // current synthetic mask is shallower. Keep that 32px-on-the-reference-
    // grid semantic reach explicit instead of deriving locality solely from
    // whichever face variant happened to be selected.
    if (tileSizePx > semanticFaceReachPx) semanticFaceReachPx = tileSizePx;
  }
  final structuralRadius =
      placementRadius > groundRadius ? placementRadius : groundRadius;
  return structuralRadius > semanticFaceReachPx
      ? structuralRadius
      : semanticFaceReachPx;
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
    BorderBlueprintTemplate.connectedLine =>
      resolveConnectedLineBorderWithEvidence(
        request,
        localCapture: capture,
      ).result,
    BorderBlueprintTemplate.stoneChainLine =>
      resolveStoneChainLineBorderWithEvidence(
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
  final editList = edits.toList(growable: false);
  final dirtyHalo = _computeLocalDirtyHalo(
    currentRequest: request,
    previousRequest: previousState.request,
    edits: editList,
  );
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
    BorderBlueprintTemplate.connectedLine =>
      resolveConnectedLineBorderWithEvidence(
        request,
        localScope: scope,
        localCapture: capture,
      ).result,
    BorderBlueprintTemplate.stoneChainLine =>
      resolveStoneChainLineBorderWithEvidence(
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

BorderDirtyHalo _computeLocalDirtyHalo({
  required BorderResolutionRequest currentRequest,
  required BorderResolutionRequest previousRequest,
  required List<BorderLocalEdit> edits,
}) {
  final base = computeBorderDirtyHalo(
    request: currentRequest,
    edits: edits,
  );
  final plannerRunBounds = <BorderPixelRect>[
    ..._strictStoneChainPlannerRunBoundsPx(previousRequest),
    ..._strictStoneChainPlannerRunBoundsPx(currentRequest),
  ];
  if (plannerRunBounds.isEmpty) return base;

  // A strict topology row is solved as one coupled run. Select against the
  // original edit halo only: recursively selecting neighboring runs at turns
  // would incorrectly turn one local edit into a whole-stroke regeneration.
  final affected = <BorderPixelRect>{...base.affectedBoundsPx};
  for (final runBounds in plannerRunBounds) {
    if (base.affectedBoundsPx.any(
      (dirty) => _rectanglesIntersect(dirty, runBounds),
    )) {
      affected.add(_expand(runBounds, base.radiusPx));
    }
  }
  final ordered = affected.toList(growable: false)
    ..sort((left, right) {
      var result = left.y.compareTo(right.y);
      if (result != 0) return result;
      result = left.x.compareTo(right.x);
      if (result != 0) return result;
      result = left.height.compareTo(right.height);
      return result != 0 ? result : left.width.compareTo(right.width);
    });
  return BorderDirtyHalo._(
    radiusPx: base.radiusPx,
    affectedBoundsPx: ordered,
  );
}

List<BorderPixelRect> _strictStoneChainPlannerRunBoundsPx(
  BorderResolutionRequest request,
) {
  final revision = request.blueprintRevision;
  if (revision == null ||
      revision.definition.template != BorderBlueprintTemplate.stoneChainLine) {
    return const <BorderPixelRect>[];
  }
  final parameters =
      request.feature.paramsOverride ?? revision.definition.defaults;
  if (parameters.depthRows < 2) return const <BorderPixelRect>[];
  final structural = revision.definition.primitives
      .where(
        (primitive) =>
            primitive.weight > 0 &&
            (primitive.role == BorderPrimitiveRole.structureLarge ||
                primitive.role == BorderPrimitiveRole.structureMedium),
      )
      .toList(growable: false);
  final supportsStrictTopology = structural.any(
        (primitive) => primitive.role == BorderPrimitiveRole.structureLarge,
      ) &&
      structural.any(
        (primitive) => primitive.role == BorderPrimitiveRole.structureMedium,
      ) &&
      structural.every(
        (primitive) =>
            primitive.authoredOrientation !=
            BorderPrimitiveOrientation.legacyAxis,
      );
  final geometry = request.feature.geometry;
  if (!supportsStrictTopology ||
      geometry is! BorderStrokeGeometry ||
      geometry.alignment != BorderStrokeAlignment.gridEdges) {
    return const <BorderPixelRect>[];
  }

  final paths = <_BorderLocalPlannerPath>[];
  for (final stroke in geometry.strokes) {
    try {
      final lineage = resolveBorderStrokeLineageIdentityV1(stroke);
      final normalized = lineage.preserveTraversal
          ? stroke
          : canonicalizeBorderStrokeV1(
              id: stroke.id,
              sampledPoints: stroke.points,
              closed: stroke.closed,
            );
      final edges = <_BorderLocalPlannerEdge>[];
      final edgeCount =
          normalized.points.length - 1 + (normalized.closed ? 1 : 0);
      for (var index = 0; index < edgeCount; index += 1) {
        final start = normalized.points[index];
        final end = index + 1 < normalized.points.length
            ? normalized.points[index + 1]
            : normalized.points.first;
        final dx = end.x - start.x;
        final dy = end.y - start.y;
        if (dx.abs() + dy.abs() != 1) {
          throw const ValidationException(
            'Strict stone-chain locality requires unit cardinal edges',
          );
        }
        edges.add((start: start, end: end, dx: dx, dy: dy));
      }
      if (edges.isNotEmpty) {
        paths.add((lineageId: lineage.lineageNamespace, edges: edges));
      }
    } on ValidationException {
      // The resolver owns canonical diagnostics for invalid strokes. Locality
      // must not invent a dependency run for geometry it cannot normalize.
    }
  }
  final topologyLineages = <String>{
    for (final path in paths)
      if (!_borderLocalPlannerPathIsStraight(path)) path.lineageId,
  };
  if (topologyLineages.isEmpty) return const <BorderPixelRect>[];

  final result = <BorderPixelRect>[];
  for (final path in paths) {
    if (!topologyLineages.contains(path.lineageId)) continue;
    var runStart = 0;
    void addRun(int endExclusive) {
      result.add(
        _borderLocalPlannerRunBoundsPx(
          path.edges.sublist(runStart, endExclusive),
          request.tileSizePx,
        ),
      );
    }

    for (var index = 1; index < path.edges.length; index += 1) {
      final previous = path.edges[index - 1];
      final current = path.edges[index];
      if (previous.dx == current.dx && previous.dy == current.dy) continue;
      addRun(index);
      runStart = index;
    }
    addRun(path.edges.length);
  }
  return List<BorderPixelRect>.unmodifiable(result);
}

bool _borderLocalPlannerPathIsStraight(_BorderLocalPlannerPath path) {
  final first = path.edges.first;
  return path.edges.every(
    (edge) => edge.dx == first.dx && edge.dy == first.dy,
  );
}

BorderPixelRect _borderLocalPlannerRunBoundsPx(
  List<_BorderLocalPlannerEdge> edges,
  GridSize tileSizePx,
) {
  var minimumX = edges.first.start.x;
  var maximumX = minimumX;
  var minimumY = edges.first.start.y;
  var maximumY = minimumY;
  for (final edge in edges) {
    for (final point in <GridPos>[edge.start, edge.end]) {
      if (point.x < minimumX) minimumX = point.x;
      if (point.x > maximumX) maximumX = point.x;
      if (point.y < minimumY) minimumY = point.y;
      if (point.y > maximumY) maximumY = point.y;
    }
  }
  final left = BigInt.from(minimumX) * BigInt.from(tileSizePx.width);
  final top = BigInt.from(minimumY) * BigInt.from(tileSizePx.height);
  final right = BigInt.from(maximumX) * BigInt.from(tileSizePx.width);
  final bottom = BigInt.from(maximumY) * BigInt.from(tileSizePx.height);
  return BorderPixelRect(
    x: left.toInt(),
    y: top.toInt(),
    // Include the terminal grid-line pixel in the dependency envelope.
    width: (right - left + BigInt.one).toInt(),
    height: (bottom - top + BigInt.one).toInt(),
  );
}

typedef _BorderLocalPlannerEdge = ({
  GridPos start,
  GridPos end,
  int dx,
  int dy,
});

typedef _BorderLocalPlannerPath = ({
  String lineageId,
  List<_BorderLocalPlannerEdge> edges,
});

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
          request.feature.lineSide == previousRequest.feature.lineSide &&
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
