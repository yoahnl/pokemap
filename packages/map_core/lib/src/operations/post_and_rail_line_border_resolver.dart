import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/geometry.dart';
import 'border_deterministic_rng.dart';
import 'border_fingerprints.dart';
import 'border_linear_lattice.dart';
import 'border_rle_codec.dart';
import 'border_slot_keys.dart';
import 'border_sprite_geometry.dart';
import 'border_stroke_canonicalization.dart';

/// Per-edge packing evidence retained for canonical-gallery previews.
@immutable
final class PostAndRailLineEdgeResolutionEvidence {
  const PostAndRailLineEdgeResolutionEvidence({
    required this.strokeId,
    required this.edgeIndex,
    required this.spanCount,
    required this.uncoveredLengthPx,
    required this.longestGapPx,
    required this.maximumPairwiseOverlapPx,
  });

  final String strokeId;
  final int edgeIndex;
  final int spanCount;
  final int uncoveredLengthPx;
  final int longestGapPx;
  final int maximumPairwiseOverlapPx;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostAndRailLineEdgeResolutionEvidence &&
          strokeId == other.strokeId &&
          edgeIndex == other.edgeIndex &&
          spanCount == other.spanCount &&
          uncoveredLengthPx == other.uncoveredLengthPx &&
          longestGapPx == other.longestGapPx &&
          maximumPairwiseOverlapPx == other.maximumPairwiseOverlapPx;

  @override
  int get hashCode => Object.hash(
        strokeId,
        edgeIndex,
        spanCount,
        uncoveredLengthPx,
        longestGapPx,
        maximumPairwiseOverlapPx,
      );
}

/// Result plus exact post-and-rail packing evidence.
@immutable
final class PostAndRailLineBorderResolutionEvidence {
  PostAndRailLineBorderResolutionEvidence({
    required this.result,
    required List<PostAndRailLineEdgeResolutionEvidence> edges,
  }) : _edges = List<PostAndRailLineEdgeResolutionEvidence>.unmodifiable(edges);

  final BorderResolutionResult result;
  final List<PostAndRailLineEdgeResolutionEvidence> _edges;

  List<PostAndRailLineEdgeResolutionEvidence> get edges => _edges;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostAndRailLineBorderResolutionEvidence &&
          result == other.result &&
          _listsEqual(_edges, other._edges);

  @override
  int get hashCode => Object.hash(result, Object.hashAll(_edges));
}

/// Resolves one V1 post-and-rail feature into native-size visual placements.
BorderResolutionResult resolvePostAndRailLineBorder(
  BorderResolutionRequest request,
) =>
    resolvePostAndRailLineBorderWithEvidence(request).result;

/// Resolves post-and-rail and exposes its deterministic packing trace.
PostAndRailLineBorderResolutionEvidence
    resolvePostAndRailLineBorderWithEvidence(
  BorderResolutionRequest request,
) {
  final diagnostics = <BorderDiagnostic>[];
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
    return _failure(diagnostics);
  }
  final definition = revision.definition;
  if (definition.template != BorderBlueprintTemplate.postAndRailLine) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.template_mismatch',
        scope: BorderDiagnosticScope.blueprint,
        parameters: <String, Object?>{'template': definition.template.name},
        action: 'border.action.select_post_and_rail_blueprint',
      ),
    );
  }
  final geometry = request.feature.geometry;
  if (geometry is! BorderStrokeGeometry) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.stroke_geometry_required',
        scope: BorderDiagnosticScope.geometry,
        action: 'border.action.draw_nonempty_stroke',
      ),
    );
    return _failure(diagnostics);
  }
  if (geometry.strokes.isEmpty) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.stroke_geometry_empty',
        scope: BorderDiagnosticScope.geometry,
        action: 'border.action.draw_nonempty_stroke',
      ),
    );
  }
  if (request.feature.overrides.isNotEmpty) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.overrides_not_supported',
        scope: BorderDiagnosticScope.feature,
        action: 'border.action.remove_overrides_before_resolution',
      ),
    );
  }
  if (request.feature.keepOutRegions.isNotEmpty) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.keep_outs_not_supported',
        scope: BorderDiagnosticScope.feature,
        action: 'border.action.remove_keep_outs_before_resolution',
      ),
    );
  }
  if (definition.ground != null) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.linear_ground_not_supported',
        scope: BorderDiagnosticScope.blueprint,
        action: 'border.action.remove_ground_from_linear_blueprint',
      ),
    );
  }

  final lattices = <BorderLinearStrokeLattice>[];
  for (final stroke in geometry.strokes) {
    final outside = stroke.points.where(
      (cell) =>
          cell.x < 0 ||
          cell.y < 0 ||
          cell.x >= request.mapSize.width ||
          cell.y >= request.mapSize.height,
    );
    if (outside.isNotEmpty) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.stroke_out_of_bounds',
          scope: BorderDiagnosticScope.stroke,
          strokeId: stroke.id,
          cell: outside.first,
          action: 'border.action.move_stroke_inside_map',
        ),
      );
      continue;
    }
    try {
      final canonical = canonicalizeBorderStrokeV1(
        id: stroke.id,
        sampledPoints: stroke.points,
        closed: stroke.closed,
      );
      if (!_sameStroke(stroke, canonical)) {
        diagnostics.add(
          _error(
            request,
            code: 'border.resolution.stroke_not_canonical',
            scope: BorderDiagnosticScope.stroke,
            strokeId: stroke.id,
            action: 'border.action.redraw_canonical_stroke',
          ),
        );
        continue;
      }
      lattices.add(
        buildBorderLinearLatticeV1(
          stroke: stroke,
          tileSizePx: request.tileSizePx,
        ),
      );
    } on ValidationException {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.stroke_invalid',
          scope: BorderDiagnosticScope.stroke,
          strokeId: stroke.id,
          action: 'border.action.redraw_valid_stroke',
        ),
      );
    }
  }
  lattices.sort((left, right) => left.strokeId.compareTo(right.strokeId));

  final primitives = definition.primitives.toList(growable: false)
    ..sort((left, right) => left.id.compareTo(right.id));
  _diagnosePublishedInputs(
    request,
    primitives: primitives,
    diagnostics: diagnostics,
  );
  final posts = primitives
      .where((primitive) => primitive.role == BorderPrimitiveRole.post)
      .toList(growable: false);
  final spans = primitives
      .where((primitive) => primitive.role == BorderPrimitiveRole.span)
      .toList(growable: false);
  if (posts.isEmpty) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.post_role_missing',
        scope: BorderDiagnosticScope.blueprint,
        action: 'border.action.assign_post_primitive',
      ),
    );
  }
  if (spans.isEmpty) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.span_role_missing',
        scope: BorderDiagnosticScope.blueprint,
        action: 'border.action.assign_span_primitive',
      ),
    );
  }

  if (!_hasErrors(diagnostics)) {
    for (final lattice in lattices) {
      for (final edge in lattice.edges) {
        if (_eligibleForDirection(spans, edge.direction).isEmpty) {
          diagnostics.add(
            _orientationError(
              request,
              strokeId: lattice.strokeId,
              edge: edge,
              role: BorderPrimitiveRole.span,
            ),
          );
        }
      }
      for (final node in lattice.nodes) {
        final direction = node.outgoingDirection ?? node.incomingDirection!;
        if (_eligibleForDirection(posts, direction).isEmpty) {
          final edge = node.outgoingDirection != null
              ? lattice.edges[node.index]
              : lattice.edges.last;
          diagnostics.add(
            _orientationError(
              request,
              strokeId: lattice.strokeId,
              edge: edge,
              role: BorderPrimitiveRole.post,
            ),
          );
        }
      }
    }
  }
  if (_hasErrors(diagnostics)) {
    return _failure(diagnostics);
  }

  final params = request.feature.paramsOverride ?? definition.defaults;
  final generated = <_GeneratedPlacement>[];
  final evidence = <PostAndRailLineEdgeResolutionEvidence>[];
  final postedCells = <GridPos>{};
  for (final lattice in lattices) {
    final latticeSpans = <_GeneratedPlacement>[];
    for (final edge in lattice.edges) {
      final packing = _packSpans(
        request: request,
        strokeId: lattice.strokeId,
        edge: edge,
        candidates: _eligibleForDirection(spans, edge.direction),
        params: params,
      );
      if (packing == null) {
        diagnostics.add(
          _error(
            request,
            code: 'border.resolution.span_too_short',
            scope: BorderDiagnosticScope.segment,
            strokeId: lattice.strokeId,
            segmentIndex: edge.index,
            cell: edge.startCell,
            parameters: <String, Object?>{
              'edgeLengthPx': edge.lengthPx,
              'maxOverlapPx': params.maxOverlapPx,
            },
            action: 'border.action.select_fitting_span',
          ),
        );
        evidence.add(
          PostAndRailLineEdgeResolutionEvidence(
            strokeId: lattice.strokeId,
            edgeIndex: edge.index,
            spanCount: 0,
            uncoveredLengthPx: edge.lengthPx,
            longestGapPx: edge.lengthPx,
            maximumPairwiseOverlapPx: 0,
          ),
        );
        continue;
      }
      final edgeGenerated = <_GeneratedPlacement>[];
      for (var ordinal = 0;
          ordinal < packing.coverageStartsPx.length;
          ordinal += 1) {
        final placement = _spanPlacement(
          request: request,
          strokeId: lattice.strokeId,
          edge: edge,
          primitive: packing.primitive,
          transform: packing.transform,
          localIntervals: packing.localIntervals,
          coverageStartPx: packing.coverageStartsPx[ordinal],
          ordinalLocal: ordinal,
        );
        if (placement == null) {
          diagnostics.add(
            _error(
              request,
              code: 'border.resolution.placement_outside_canvas',
              scope: BorderDiagnosticScope.segment,
              strokeId: lattice.strokeId,
              segmentIndex: edge.index,
              cell: edge.startCell,
              action: 'border.action.adjust_primitive_anchor',
            ),
          );
          continue;
        }
        edgeGenerated.add(placement);
      }
      generated.addAll(edgeGenerated);
      latticeSpans.addAll(edgeGenerated);
      final coverage = _assessEdgeCoverage(
        request: request,
        edge: edge,
        generated: edgeGenerated,
      );
      evidence.add(
        PostAndRailLineEdgeResolutionEvidence(
          strokeId: lattice.strokeId,
          edgeIndex: edge.index,
          spanCount: edgeGenerated.length,
          uncoveredLengthPx: edge.lengthPx - coverage.coveredLengthPx,
          longestGapPx: coverage.longestGapPx,
          maximumPairwiseOverlapPx: coverage.maximumPairwiseOverlapPx,
        ),
      );
    }

    final strokeCoverage = _assessStrokeCoverage(
      request: request,
      lattice: lattice,
      generated: latticeSpans,
    );
    if (strokeCoverage.longestGapPx > params.gapTolerancePx) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.coverage_gap',
          scope: BorderDiagnosticScope.stroke,
          strokeId: lattice.strokeId,
          cell: lattice.nodes.first.cell,
          parameters: <String, Object?>{
            'longestGapPx': strokeCoverage.longestGapPx,
            'gapTolerancePx': params.gapTolerancePx,
          },
          action: 'border.action.select_continuous_span',
        ),
      );
    }
    if (strokeCoverage.maximumPairwiseOverlapPx > params.maxOverlapPx) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.coverage_overlap',
          scope: BorderDiagnosticScope.stroke,
          strokeId: lattice.strokeId,
          cell: lattice.nodes.first.cell,
          parameters: <String, Object?>{
            'maximumOverlapPx': strokeCoverage.maximumPairwiseOverlapPx,
            'maxOverlapPx': params.maxOverlapPx,
          },
          action: 'border.action.reduce_overlap',
        ),
      );
    }

    for (final node in lattice.nodes) {
      if (!postedCells.add(node.cell)) {
        continue;
      }
      final edge = node.outgoingDirection != null
          ? lattice.edges[node.index]
          : lattice.edges.last;
      final direction = node.outgoingDirection ?? node.incomingDirection!;
      final eligible = _eligibleForDirection(posts, direction);
      final primitive = _choosePrimitive(
        request,
        strokeId: lattice.strokeId,
        edge: edge,
        candidates: eligible,
        role: BorderPrimitiveRole.post,
        passIndex: 1,
        ordinalLocal: node.outgoingDirection != null ? 0 : 1,
        variationPermille: params.variationPermille,
      );
      final transform = _chooseTransform(
        request,
        strokeId: lattice.strokeId,
        edge: edge,
        primitive: primitive,
        role: BorderPrimitiveRole.post,
        passIndex: 1,
        ordinalLocal: node.outgoingDirection != null ? 0 : 1,
        variationPermille: params.variationPermille,
        direction: direction,
      );
      final post = _placementForEdge(
        request: request,
        strokeId: lattice.strokeId,
        edge: edge,
        primitive: primitive,
        transform: transform,
        passIndex: 1,
        ordinalLocal: node.outgoingDirection != null ? 0 : 1,
        drawBand: BorderDrawBand.structure,
        target: _cellCenterWorldPx(request, node.cell),
        anchorCell: node.cell,
      );
      if (post == null) {
        diagnostics.add(
          _error(
            request,
            code: 'border.resolution.placement_outside_canvas',
            scope: BorderDiagnosticScope.stroke,
            strokeId: lattice.strokeId,
            cell: node.cell,
            action: 'border.action.adjust_primitive_anchor',
          ),
        );
      } else {
        generated.add(post);
      }
    }

    _resolveOptionalDetails(
      request: request,
      lattice: lattice,
      primitives: primitives,
      params: params,
      generated: generated,
    );
  }

  if (_hasErrors(diagnostics)) {
    return PostAndRailLineBorderResolutionEvidence(
      result: _failed(diagnostics),
      edges: evidence,
    );
  }
  final placements = generated.map((entry) => entry.placement).toList()
    ..sort(
      (left, right) => left.stableOrderKey.compareTo(right.stableOrderKey),
    );
  if (placements.isEmpty) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.materialization_empty',
        scope: BorderDiagnosticScope.materialization,
        action: 'border.action.adjust_blueprint_or_geometry',
      ),
    );
    return PostAndRailLineBorderResolutionEvidence(
      result: _failed(diagnostics),
      edges: evidence,
    );
  }
  final components = computeBorderInputFingerprints(request);
  final inputFingerprint = computeBorderAggregateInputFingerprint(
    resolverVersion: request.resolverVersion,
    blueprintRevision: revision.revision,
    components: components,
  );
  final outputFingerprint = computeBorderOutputFingerprint(
    ground: const <BorderResolvedGroundCell>[],
    placements: placements,
  );
  final materialization = BorderMaterialization(
    receipt: BorderResolutionReceipt(
      resolverVersion: request.resolverVersion,
      blueprintRevision: revision.revision,
      components: components,
      inputFingerprint: inputFingerprint,
      outputFingerprint: outputFingerprint,
    ),
    ground: const <BorderResolvedGroundCell>[],
    placements: placements,
  );
  return PostAndRailLineBorderResolutionEvidence(
    result: BorderResolutionResult(
      materialization: materialization,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    ),
    edges: evidence,
  );
}

void _diagnosePublishedInputs(
  BorderResolutionRequest request, {
  required List<BorderPublishedPrimitive> primitives,
  required List<BorderDiagnostic> diagnostics,
}) {
  final ids = <String>{};
  for (final primitive in primitives) {
    if (!ids.add(primitive.id)) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.duplicate_primitive_id',
          scope: BorderDiagnosticScope.primitive,
          parameters: <String, Object?>{'primitiveId': primitive.id},
          action: 'border.action.assign_unique_primitive_ids',
        ),
      );
    }
    if (!_roleAllowed(primitive.role)) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.role_not_supported_by_template',
          scope: BorderDiagnosticScope.primitive,
          parameters: <String, Object?>{
            'primitiveId': primitive.id,
            'role': primitive.role.name,
          },
          action: 'border.action.remove_incompatible_role',
        ),
      );
    }
    final metrics = primitive.publishedMetrics;
    final anchorValid = _anchorInside(primitive.anchorPx, metrics.pixelSize);
    final defaultAnchorValid =
        _anchorInside(metrics.defaultAnchorPx, metrics.pixelSize);
    if (!anchorValid || !defaultAnchorValid) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.anchor_outside_asset',
          scope: BorderDiagnosticScope.primitive,
          parameters: <String, Object?>{'primitiveId': primitive.id},
          action: 'border.action.correct_primitive_anchor',
        ),
      );
    }
    try {
      final expectedLength = checkedBorderRleCellCount(
        width: metrics.pixelSize.width,
        height: metrics.pixelSize.height,
        path: r'$.publishedMetrics.pixelSize',
      );
      if (!borderRleMaskHasTrue(
        metrics.occupancyMaskRle,
        expectedLength: expectedLength,
        path: r'$.publishedMetrics.occupancyMaskRle',
      )) {
        diagnostics.add(
          _error(
            request,
            code: 'border.resolution.occupancy_empty',
            scope: BorderDiagnosticScope.primitive,
            parameters: <String, Object?>{'primitiveId': primitive.id},
            action: 'border.action.select_nonempty_primitive',
          ),
        );
      }
    } on FormatException {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.occupancy_invalid',
          scope: BorderDiagnosticScope.primitive,
          parameters: <String, Object?>{'primitiveId': primitive.id},
          action: 'border.action.reanalyze_primitive',
        ),
      );
    }
    final snapshot = request.visualSnapshotById(primitive.visualSnapshotId);
    if (!_snapshotMatches(snapshot, metrics.pixelSize)) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.visual_snapshot_invalid',
          scope: BorderDiagnosticScope.visualSnapshot,
          parameters: <String, Object?>{
            'primitiveId': primitive.id,
            'snapshotId': primitive.visualSnapshotId,
          },
          action: 'border.action.restore_or_republish_snapshot',
        ),
      );
    }
  }
}

bool _roleAllowed(BorderPrimitiveRole role) => switch (role) {
      BorderPrimitiveRole.post ||
      BorderPrimitiveRole.span ||
      BorderPrimitiveRole.accent ||
      BorderPrimitiveRole.surfacePatch =>
        true,
      BorderPrimitiveRole.structureLarge ||
      BorderPrimitiveRole.structureMedium ||
      BorderPrimitiveRole.filler ||
      BorderPrimitiveRole.outerAccent =>
        false,
    };

bool _anchorInside(BorderPixelPos anchor, GridSize size) =>
    anchor.x >= 0 &&
    anchor.y >= 0 &&
    anchor.x < size.width &&
    anchor.y < size.height;

bool _snapshotMatches(BorderVisualSnapshot? snapshot, GridSize size) =>
    snapshot != null &&
    snapshot.frames.isNotEmpty &&
    snapshot.frames.every(
      (frame) =>
          frame.sourceRectPx.width == size.width &&
          frame.sourceRectPx.height == size.height,
    );

List<BorderPublishedPrimitive> _eligibleForDirection(
  Iterable<BorderPublishedPrimitive> candidates,
  BorderCardinalDirection direction,
) {
  final quarterTurns = borderCardinalDirectionV1Rank(direction);
  return candidates
      .where(
        (primitive) =>
            primitive.transforms.allowedQuarterTurns.contains(quarterTurns),
      )
      .toList(growable: false)
    ..sort((left, right) => left.id.compareTo(right.id));
}

_SpanPacking? _packSpans({
  required BorderResolutionRequest request,
  required String strokeId,
  required BorderLinearEdge edge,
  required List<BorderPublishedPrimitive> candidates,
  required BorderGenerationParams params,
}) {
  if (candidates.isEmpty) return null;
  final primary = _choosePrimitive(
    request,
    strokeId: strokeId,
    edge: edge,
    candidates: candidates,
    role: BorderPrimitiveRole.span,
    passIndex: 0,
    ordinalLocal: 0,
    variationPermille: params.variationPermille,
  );
  final ordered = <BorderPublishedPrimitive>[
    primary,
    ...candidates.where((candidate) => candidate.id != primary.id),
  ];
  _SpanPackingAttempt? bestAttempt;
  for (final primitive in ordered) {
    final attempt = _packSpanPrimitive(
      request: request,
      strokeId: strokeId,
      edge: edge,
      primitive: primitive,
      params: params,
    );
    if (attempt == null) continue;
    if (attempt.coverage.longestGapPx <= params.gapTolerancePx &&
        attempt.coverage.maximumPairwiseOverlapPx <= params.maxOverlapPx) {
      return attempt.packing;
    }
    final best = bestAttempt;
    if (best == null ||
        attempt.coverage.longestGapPx < best.coverage.longestGapPx ||
        (attempt.coverage.longestGapPx == best.coverage.longestGapPx &&
            attempt.coverage.maximumPairwiseOverlapPx <
                best.coverage.maximumPairwiseOverlapPx)) {
      bestAttempt = attempt;
    }
  }
  return bestAttempt?.packing;
}

_SpanPackingAttempt? _packSpanPrimitive({
  required BorderResolutionRequest request,
  required String strokeId,
  required BorderLinearEdge edge,
  required BorderPublishedPrimitive primitive,
  required BorderGenerationParams params,
}) {
  final transform = _chooseTransform(
    request,
    strokeId: strokeId,
    edge: edge,
    primitive: primitive,
    role: BorderPrimitiveRole.span,
    passIndex: 0,
    ordinalLocal: 0,
    variationPermille: params.variationPermille,
    direction: edge.direction,
  );
  final localIntervals = _projectLocalOccupiedTangentIntervals(
    primitive: primitive,
    transform: transform,
    destinationX: _tangentIsX(edge.direction),
  );
  if (localIntervals.isEmpty) return null;
  final first = localIntervals.first.startPx;
  final extent = localIntervals.last.endPx - first;
  final length = edge.lengthPx;
  if (extent > length) {
    final excess = extent - length;
    final left = excess ~/ 2;
    final right = excess - left;
    if (left > params.maxOverlapPx || right > params.maxOverlapPx) {
      return null;
    }
    final starts = <int>[-left];
    return _SpanPackingAttempt(
      packing: _SpanPacking(
        primitive: primitive,
        transform: transform,
        localIntervals: localIntervals,
        coverageStartsPx: starts,
      ),
      coverage: _coverageForPackingStarts(
        localIntervals: localIntervals,
        starts: starts,
        domainLengthPx: length,
      ),
    );
  }

  final minimumCount = (length + extent - 1) ~/ extent;
  final maximumCount = minimumCount + 2;
  _SpanPackingAttempt? bestAttempt;
  for (var count = 1; count <= maximumCount; count += 1) {
    final starts = count == 1
        ? <int>[(length - extent) ~/ 2]
        : <int>[
            for (var index = 0; index < count; index += 1)
              (index * (length - extent)) ~/ (count - 1),
          ];
    final coverage = _coverageForPackingStarts(
      localIntervals: localIntervals,
      starts: starts,
      domainLengthPx: length,
    );
    if (bestAttempt == null ||
        coverage.longestGapPx < bestAttempt.coverage.longestGapPx ||
        (coverage.longestGapPx == bestAttempt.coverage.longestGapPx &&
            coverage.maximumPairwiseOverlapPx <
                bestAttempt.coverage.maximumPairwiseOverlapPx)) {
      bestAttempt = _SpanPackingAttempt(
        packing: _SpanPacking(
          primitive: primitive,
          transform: transform,
          localIntervals: localIntervals,
          coverageStartsPx: starts,
        ),
        coverage: coverage,
      );
    }
    if (coverage.longestGapPx <= params.gapTolerancePx &&
        coverage.maximumPairwiseOverlapPx <= params.maxOverlapPx) {
      return _SpanPackingAttempt(
        packing: _SpanPacking(
          primitive: primitive,
          transform: transform,
          localIntervals: localIntervals,
          coverageStartsPx: starts,
        ),
        coverage: coverage,
      );
    }
  }
  return bestAttempt;
}

_Coverage _coverageForPackingStarts({
  required List<_Interval> localIntervals,
  required List<int> starts,
  required int domainLengthPx,
}) {
  final first = localIntervals.first.startPx;
  return _assessIntervals(
    intervalsByPlacement: <List<_Interval>>[
      for (final start in starts)
        <_Interval>[
          for (final interval in localIntervals)
            _Interval(
              startPx: start + interval.startPx - first,
              endPx: start + interval.endPx - first,
            ),
        ],
    ],
    domainLengthPx: domainLengthPx,
  );
}

_GeneratedPlacement? _spanPlacement({
  required BorderResolutionRequest request,
  required String strokeId,
  required BorderLinearEdge edge,
  required BorderPublishedPrimitive primitive,
  required BorderSpriteTransform transform,
  required List<_Interval> localIntervals,
  required int coverageStartPx,
  required int ordinalLocal,
}) {
  final tangentIsX = _tangentIsX(edge.direction);
  final origin = resolveBorderSpriteGeometry(
    metrics: primitive.publishedMetrics,
    sourceAnchorPx: primitive.anchorPx,
    transform: transform,
    targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
  );
  final low = _edgeLowAxisWorldPx(request, edge);
  final localStart = localIntervals.first.startPx;
  final transformedAnchorAxis =
      tangentIsX ? origin.transformedAnchorPx.x : origin.transformedAnchorPx.y;
  final targetAxis = low + coverageStartPx - localStart + transformedAnchorAxis;
  final normal = _edgeNormalWorldPx(request, edge);
  final target = tangentIsX
      ? BorderPixelPos(x: targetAxis, y: normal)
      : BorderPixelPos(x: normal, y: targetAxis);
  return _placementForEdge(
    request: request,
    strokeId: strokeId,
    edge: edge,
    primitive: primitive,
    transform: transform,
    passIndex: 0,
    ordinalLocal: ordinalLocal,
    drawBand: BorderDrawBand.outerAccent,
    target: target,
    anchorCell: edge.startCell,
  );
}

void _resolveOptionalDetails({
  required BorderResolutionRequest request,
  required BorderLinearStrokeLattice lattice,
  required List<BorderPublishedPrimitive> primitives,
  required BorderGenerationParams params,
  required List<_GeneratedPlacement> generated,
}) {
  if (params.detailDensityPermille == 0) return;
  for (final edge in lattice.edges) {
    for (final entry
        in const <({BorderPrimitiveRole role, int pass, BorderDrawBand band})>[
      (
        role: BorderPrimitiveRole.surfacePatch,
        pass: 2,
        band: BorderDrawBand.innerFinish,
      ),
      (
        role: BorderPrimitiveRole.accent,
        pass: 3,
        band: BorderDrawBand.accent,
      ),
    ]) {
      final candidates = _eligibleForDirection(
        primitives.where((primitive) => primitive.role == entry.role),
        edge.direction,
      );
      if (candidates.isEmpty ||
          !_passesPermille(
            request,
            strokeId: lattice.strokeId,
            edge: edge,
            passIndex: entry.pass,
            role: entry.role,
            ordinalLocal: 0,
            decision: 'detail-density',
            permille: params.detailDensityPermille,
          )) {
        continue;
      }
      final primitive = _choosePrimitive(
        request,
        strokeId: lattice.strokeId,
        edge: edge,
        candidates: candidates,
        role: entry.role,
        passIndex: entry.pass,
        ordinalLocal: 0,
        variationPermille: params.variationPermille,
      );
      final transform = _chooseTransform(
        request,
        strokeId: lattice.strokeId,
        edge: edge,
        primitive: primitive,
        role: entry.role,
        passIndex: entry.pass,
        ordinalLocal: 0,
        variationPermille: params.variationPermille,
        direction: edge.direction,
      );
      final placement = _placementForEdge(
        request: request,
        strokeId: lattice.strokeId,
        edge: edge,
        primitive: primitive,
        transform: transform,
        passIndex: entry.pass,
        ordinalLocal: 0,
        drawBand: entry.band,
        target: _edgeMidpointWorldPx(request, edge),
        anchorCell: edge.startCell,
      );
      if (placement != null) generated.add(placement);
    }
  }
}

BorderPublishedPrimitive _choosePrimitive(
  BorderResolutionRequest request, {
  required String strokeId,
  required BorderLinearEdge edge,
  required List<BorderPublishedPrimitive> candidates,
  required BorderPrimitiveRole role,
  required int passIndex,
  required int ordinalLocal,
  required int variationPermille,
}) {
  if (variationPermille == 0 || candidates.length == 1) {
    return candidates.first;
  }
  return chooseBorderWeightedCandidate(
    _decisionRng(
      request,
      strokeId: strokeId,
      edge: edge,
      passIndex: passIndex,
      role: role,
      ordinalLocal: ordinalLocal,
      decision: 'primitive',
    ),
    <BorderWeightedCandidate<BorderPublishedPrimitive>>[
      for (final candidate in candidates)
        BorderWeightedCandidate<BorderPublishedPrimitive>(
          id: candidate.id,
          value: candidate,
          weight: candidate.weight,
        ),
    ],
  )!
      .value;
}

BorderSpriteTransform _chooseTransform(
  BorderResolutionRequest request, {
  required String strokeId,
  required BorderLinearEdge edge,
  required BorderPublishedPrimitive primitive,
  required BorderPrimitiveRole role,
  required int passIndex,
  required int ordinalLocal,
  required int variationPermille,
  required BorderCardinalDirection direction,
}) {
  final flip = primitive.transforms.allowFlipX &&
      variationPermille > 0 &&
      _passesPermille(
        request,
        strokeId: strokeId,
        edge: edge,
        passIndex: passIndex,
        role: role,
        ordinalLocal: ordinalLocal,
        decision: 'flip',
        permille: variationPermille ~/ 2,
      );
  return BorderSpriteTransform(
    quarterTurns: borderCardinalDirectionV1Rank(direction),
    flipX: flip,
  );
}

_GeneratedPlacement? _placementForEdge({
  required BorderResolutionRequest request,
  required String strokeId,
  required BorderLinearEdge edge,
  required BorderPublishedPrimitive primitive,
  required BorderSpriteTransform transform,
  required int passIndex,
  required int ordinalLocal,
  required BorderDrawBand drawBand,
  required BorderPixelPos target,
  required GridPos anchorCell,
}) {
  final sprite = resolveBorderSpriteGeometry(
    metrics: primitive.publishedMetrics,
    sourceAnchorPx: primitive.anchorPx,
    transform: transform,
    targetAnchorWorldPx: target,
  );
  final canvas = GridSize(
    width: request.mapSize.width * request.tileSizePx.width,
    height: request.mapSize.height * request.tileSizePx.height,
  );
  if (!borderPixelRectIntersectsCanvas(
    rect: sprite.opaqueWorldBoundsPx,
    canvasSizePx: canvas,
  )) {
    return null;
  }
  final slotKey = buildBorderLineSlotKey(
    featureId: request.feature.id,
    strokeId: strokeId,
    edgeStart: edge.startCell,
    edgeEnd: edge.endCell,
    passIndex: passIndex,
    role: primitive.role,
    rank: 0,
    ordinalLocal: ordinalLocal,
  );
  final placement = BorderResolvedPlacement(
    id: 'border-placement-v1:${slotKey.substring(borderSlotKeyV1Prefix.length)}',
    slotKey: slotKey,
    primitiveId: primitive.id,
    visualSnapshotId: primitive.visualSnapshotId,
    anchorCell: anchorCell,
    topLeftWorldPx: sprite.topLeftWorldPx,
    opaqueWorldBoundsPx: sprite.opaqueWorldBoundsPx,
    transform: transform,
    drawBand: drawBand,
    stableOrderKey: buildBorderStableOrderKey(
      drawBand: drawBand,
      mapWidth: request.mapSize.width,
      anchorCell: anchorCell,
      passIndex: passIndex,
      rank: 0,
      ordinalLocal: ordinalLocal,
      slotKey: slotKey,
    ),
  );
  return _GeneratedPlacement(
    edgeIndex: edge.index,
    primitive: primitive,
    placement: placement,
  );
}

_Coverage _assessEdgeCoverage({
  required BorderResolutionRequest request,
  required BorderLinearEdge edge,
  required List<_GeneratedPlacement> generated,
}) {
  final low = _edgeLowAxisWorldPx(request, edge);
  final byPlacement = <List<_Interval>>[];
  for (final entry in generated) {
    final world = _projectWorldOccupiedTangentIntervals(
      primitive: entry.primitive,
      placement: entry.placement,
      destinationX: _tangentIsX(edge.direction),
    );
    byPlacement.add(
      <_Interval>[
        for (final interval in world)
          _Interval(
            startPx: interval.startPx - low,
            endPx: interval.endPx - low,
          ),
      ],
    );
  }
  return _assessIntervals(
    intervalsByPlacement: byPlacement,
    domainLengthPx: edge.lengthPx,
  );
}

_Coverage _assessStrokeCoverage({
  required BorderResolutionRequest request,
  required BorderLinearStrokeLattice lattice,
  required List<_GeneratedPlacement> generated,
}) {
  final byPlacement = <List<_Interval>>[];
  for (final entry in generated) {
    final edge = lattice.edges[entry.edgeIndex];
    final low = _edgeLowAxisWorldPx(request, edge);
    final high = low + edge.lengthPx;
    final world = _projectWorldOccupiedTangentIntervals(
      primitive: entry.primitive,
      placement: entry.placement,
      destinationX: _tangentIsX(edge.direction),
    );
    final unwrapped = <_Interval>[
      for (final interval in world)
        if (_directionIsForward(edge.direction))
          _Interval(
            startPx: edge.startAbscissaPx + interval.startPx - low,
            endPx: edge.startAbscissaPx + interval.endPx - low,
          )
        else
          _Interval(
            startPx: edge.startAbscissaPx + high - interval.endPx,
            endPx: edge.startAbscissaPx + high - interval.startPx,
          ),
    ];
    final intervals = lattice.closed
        ? _wrapIntervals(unwrapped, lattice.totalLengthPx)
        : _clipIntervals(
            unwrapped,
            startPx: 0,
            endPx: lattice.totalLengthPx,
          );
    byPlacement.add(_mergeIntervals(intervals));
  }
  return _assessIntervals(
    intervalsByPlacement: byPlacement,
    domainLengthPx: lattice.totalLengthPx,
    closed: lattice.closed,
  );
}

_Coverage _assessIntervals({
  required List<List<_Interval>> intervalsByPlacement,
  required int domainLengthPx,
  bool closed = false,
}) {
  final clippedByPlacement = <List<_Interval>>[
    for (final placement in intervalsByPlacement)
      _mergeIntervals(
        <_Interval>[
          for (final interval in placement)
            if (_minimum(interval.endPx, domainLengthPx) >
                _maximum(interval.startPx, 0))
              _Interval(
                startPx: _maximum(interval.startPx, 0),
                endPx: _minimum(interval.endPx, domainLengthPx),
              ),
        ],
      ),
  ];
  final merged = _mergeIntervals(
    <_Interval>[
      for (final placement in clippedByPlacement) ...placement,
    ],
  );
  var cursor = 0;
  var covered = 0;
  var longestGap = 0;
  for (final interval in merged) {
    if (interval.startPx > cursor) {
      longestGap = _maximum(longestGap, interval.startPx - cursor);
    }
    final start = _maximum(interval.startPx, cursor);
    if (interval.endPx > start) covered += interval.endPx - start;
    cursor = _maximum(cursor, interval.endPx);
  }
  if (cursor < domainLengthPx) {
    longestGap = _maximum(longestGap, domainLengthPx - cursor);
  }
  if (closed && merged.isNotEmpty) {
    longestGap = _maximum(
      longestGap,
      merged.first.startPx + (domainLengthPx - merged.last.endPx),
    );
  }
  var maximumOverlap = 0;
  for (var first = 0; first < clippedByPlacement.length; first += 1) {
    for (var second = first + 1;
        second < clippedByPlacement.length;
        second += 1) {
      maximumOverlap = _maximum(
        maximumOverlap,
        _intersectionLength(
          clippedByPlacement[first],
          clippedByPlacement[second],
        ),
      );
    }
  }
  return _Coverage(
    coveredLengthPx: covered,
    longestGapPx: longestGap,
    maximumPairwiseOverlapPx: maximumOverlap,
  );
}

List<_Interval> _clipIntervals(
  Iterable<_Interval> source, {
  required int startPx,
  required int endPx,
}) =>
    <_Interval>[
      for (final interval in source)
        if (_minimum(interval.endPx, endPx) >
            _maximum(interval.startPx, startPx))
          _Interval(
            startPx: _maximum(interval.startPx, startPx),
            endPx: _minimum(interval.endPx, endPx),
          ),
    ];

List<_Interval> _wrapIntervals(
  Iterable<_Interval> source,
  int domainLengthPx,
) {
  final result = <_Interval>[];
  for (final interval in source) {
    final length = interval.endPx - interval.startPx;
    if (length <= 0) continue;
    if (length >= domainLengthPx) {
      return <_Interval>[
        _Interval(startPx: 0, endPx: domainLengthPx),
      ];
    }
    final start = _positiveModulo(interval.startPx, domainLengthPx);
    final end = start + length;
    if (end <= domainLengthPx) {
      result.add(_Interval(startPx: start, endPx: end));
    } else {
      result
        ..add(_Interval(startPx: start, endPx: domainLengthPx))
        ..add(_Interval(startPx: 0, endPx: end - domainLengthPx));
    }
  }
  return result;
}

List<_Interval> _projectLocalOccupiedTangentIntervals({
  required BorderPublishedPrimitive primitive,
  required BorderSpriteTransform transform,
  required bool destinationX,
}) {
  final metrics = primitive.publishedMetrics;
  final axis = _sourceAxisForDestination(
    quarterTurns: transform.quarterTurns,
    flipX: transform.flipX,
    destinationX: destinationX,
  );
  var intervals = _occupiedSourceAxisIntervals(
    metrics,
    sourceX: axis.sourceX,
  );
  final sourceLength =
      axis.sourceX ? metrics.pixelSize.width : metrics.pixelSize.height;
  if (axis.reversed) {
    intervals = <_Interval>[
      for (final interval in intervals.reversed)
        _Interval(
          startPx: sourceLength - interval.endPx,
          endPx: sourceLength - interval.startPx,
        ),
    ];
  }
  return _mergeIntervals(intervals);
}

List<_Interval> _projectWorldOccupiedTangentIntervals({
  required BorderPublishedPrimitive primitive,
  required BorderResolvedPlacement placement,
  required bool destinationX,
}) {
  final local = _projectLocalOccupiedTangentIntervals(
    primitive: primitive,
    transform: placement.transform,
    destinationX: destinationX,
  );
  final topLeft =
      destinationX ? placement.topLeftWorldPx.x : placement.topLeftWorldPx.y;
  return <_Interval>[
    for (final interval in local)
      _Interval(
        startPx: topLeft + interval.startPx,
        endPx: topLeft + interval.endPx,
      ),
  ];
}

({bool sourceX, bool reversed}) _sourceAxisForDestination({
  required int quarterTurns,
  required bool flipX,
  required bool destinationX,
}) =>
    switch ((quarterTurns, destinationX)) {
      (0, true) => (sourceX: true, reversed: flipX),
      (0, false) => (sourceX: false, reversed: false),
      (1, true) => (sourceX: false, reversed: true),
      (1, false) => (sourceX: true, reversed: flipX),
      (2, true) => (sourceX: true, reversed: !flipX),
      (2, false) => (sourceX: false, reversed: true),
      (3, true) => (sourceX: false, reversed: false),
      (3, false) => (sourceX: true, reversed: !flipX),
      _ => throw const ValidationException(
          'Post-and-rail transform quarterTurns must be 0..3',
        ),
    };

List<_Interval> _occupiedSourceAxisIntervals(
  BorderPrimitiveAssetMetrics metrics, {
  required bool sourceX,
}) {
  final width = metrics.pixelSize.width;
  final height = metrics.pixelSize.height;
  final occupied = List<bool>.filled(
    sourceX ? width : height,
    false,
    growable: false,
  );
  visitBorderRleTrueRuns(
    metrics.occupancyMaskRle,
    expectedLength: checkedBorderRleCellCount(
      width: width,
      height: height,
      path: r'$.publishedMetrics.pixelSize',
    ),
    path: r'$.publishedMetrics.occupancyMaskRle',
    visitor: (start, end) {
      final firstRow = start ~/ width;
      final lastRow = (end - 1) ~/ width;
      if (!sourceX) {
        for (var row = firstRow; row <= lastRow; row += 1) {
          occupied[row] = true;
        }
        return;
      }
      if (firstRow == lastRow) {
        final endColumn = (end - 1) % width + 1;
        for (var column = start % width; column < endColumn; column += 1) {
          occupied[column] = true;
        }
        return;
      }
      for (var column = start % width; column < width; column += 1) {
        occupied[column] = true;
      }
      for (var column = 0; column <= (end - 1) % width; column += 1) {
        occupied[column] = true;
      }
      if (lastRow - firstRow > 1) {
        occupied.fillRange(0, occupied.length, true);
      }
    },
  );
  final result = <_Interval>[];
  var start = -1;
  for (var index = 0; index <= occupied.length; index += 1) {
    final filled = index < occupied.length && occupied[index];
    if (filled && start < 0) {
      start = index;
    } else if (!filled && start >= 0) {
      result.add(_Interval(startPx: start, endPx: index));
      start = -1;
    }
  }
  return result;
}

List<_Interval> _mergeIntervals(Iterable<_Interval> source) {
  final sorted = source.toList(growable: true)
    ..sort((left, right) {
      final byStart = left.startPx.compareTo(right.startPx);
      return byStart != 0 ? byStart : left.endPx.compareTo(right.endPx);
    });
  final result = <_Interval>[];
  for (final interval in sorted) {
    if (result.isEmpty || interval.startPx > result.last.endPx) {
      result.add(interval);
    } else if (interval.endPx > result.last.endPx) {
      result[result.length - 1] = _Interval(
        startPx: result.last.startPx,
        endPx: interval.endPx,
      );
    }
  }
  return result;
}

int _intersectionLength(List<_Interval> left, List<_Interval> right) {
  var first = 0;
  var second = 0;
  var total = 0;
  while (first < left.length && second < right.length) {
    final start = _maximum(left[first].startPx, right[second].startPx);
    final end = _minimum(left[first].endPx, right[second].endPx);
    if (end > start) total += end - start;
    if (left[first].endPx <= right[second].endPx) {
      first += 1;
    } else {
      second += 1;
    }
  }
  return total;
}

BorderDeterministicRng _decisionRng(
  BorderResolutionRequest request, {
  required String strokeId,
  required BorderLinearEdge edge,
  required int passIndex,
  required BorderPrimitiveRole role,
  required int ordinalLocal,
  required String decision,
}) =>
    BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
      BorderRngKeyComponent.text(request.feature.id),
      BorderRngKeyComponent.text(strokeId),
      BorderRngKeyComponent.text('${edge.startCell.x},${edge.startCell.y}'),
      BorderRngKeyComponent.text('${edge.endCell.x},${edge.endCell.y}'),
      BorderRngKeyComponent.text('$passIndex'),
      BorderRngKeyComponent.text(borderPrimitiveRoleV1WireName(role)),
      BorderRngKeyComponent.text('$ordinalLocal'),
      BorderRngKeyComponent.text(decision),
      BorderRngKeyComponent.signedInt64(request.feature.seed),
    ]);

bool _passesPermille(
  BorderResolutionRequest request, {
  required String strokeId,
  required BorderLinearEdge edge,
  required int passIndex,
  required BorderPrimitiveRole role,
  required int ordinalLocal,
  required String decision,
  required int permille,
}) =>
    permille >= 1000 ||
    (permille > 0 &&
        _decisionRng(
              request,
              strokeId: strokeId,
              edge: edge,
              passIndex: passIndex,
              role: role,
              ordinalLocal: ordinalLocal,
              decision: decision,
            ).nextIndex(1000) <
            permille);

BorderPixelPos _edgeMidpointWorldPx(
  BorderResolutionRequest request,
  BorderLinearEdge edge,
) {
  final start = _cellCenterWorldPx(request, edge.startCell);
  final end = _cellCenterWorldPx(request, edge.endCell);
  return BorderPixelPos(
    x: (start.x + end.x) ~/ 2,
    y: (start.y + end.y) ~/ 2,
  );
}

int _edgeLowAxisWorldPx(
  BorderResolutionRequest request,
  BorderLinearEdge edge,
) {
  final start = _cellCenterWorldPx(request, edge.startCell);
  final end = _cellCenterWorldPx(request, edge.endCell);
  final first = _tangentIsX(edge.direction) ? start.x : start.y;
  final second = _tangentIsX(edge.direction) ? end.x : end.y;
  return _minimum(first, second);
}

int _edgeNormalWorldPx(
  BorderResolutionRequest request,
  BorderLinearEdge edge,
) =>
    _tangentIsX(edge.direction)
        ? edge.startCell.y * request.tileSizePx.height +
            request.tileSizePx.height ~/ 2
        : edge.startCell.x * request.tileSizePx.width +
            request.tileSizePx.width ~/ 2;

BorderPixelPos _cellCenterWorldPx(
  BorderResolutionRequest request,
  GridPos cell,
) =>
    BorderPixelPos(
      x: cell.x * request.tileSizePx.width + request.tileSizePx.width ~/ 2,
      y: cell.y * request.tileSizePx.height + request.tileSizePx.height ~/ 2,
    );

bool _sameStroke(BorderStroke left, BorderStroke right) {
  if (left.id != right.id ||
      left.closed != right.closed ||
      left.points.length != right.points.length) {
    return false;
  }
  for (var index = 0; index < left.points.length; index += 1) {
    if (left.points[index] != right.points[index]) return false;
  }
  return true;
}

bool _tangentIsX(BorderCardinalDirection direction) =>
    direction == BorderCardinalDirection.east ||
    direction == BorderCardinalDirection.west;

bool _directionIsForward(BorderCardinalDirection direction) =>
    direction == BorderCardinalDirection.east ||
    direction == BorderCardinalDirection.south;

int _positiveModulo(int value, int positiveDivisor) {
  final remainder = value % positiveDivisor;
  return remainder < 0 ? remainder + positiveDivisor : remainder;
}

int _minimum(int left, int right) => left < right ? left : right;
int _maximum(int left, int right) => left > right ? left : right;

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _hasErrors(List<BorderDiagnostic> diagnostics) => diagnostics.any(
      (diagnostic) => diagnostic.severity == BorderDiagnosticSeverity.error,
    );

PostAndRailLineBorderResolutionEvidence _failure(
  List<BorderDiagnostic> diagnostics,
) =>
    PostAndRailLineBorderResolutionEvidence(
      result: _failed(diagnostics),
      edges: const <PostAndRailLineEdgeResolutionEvidence>[],
    );

BorderResolutionResult _failed(List<BorderDiagnostic> diagnostics) =>
    BorderResolutionResult(
      materialization: null,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    );

BorderDiagnostic _orientationError(
  BorderResolutionRequest request, {
  required String strokeId,
  required BorderLinearEdge edge,
  required BorderPrimitiveRole role,
}) =>
    _error(
      request,
      code: 'border.resolution.orientation_unavailable',
      scope: BorderDiagnosticScope.segment,
      strokeId: strokeId,
      segmentIndex: edge.index,
      cell: edge.startCell,
      parameters: <String, Object?>{
        'direction': borderCardinalDirectionV1WireName(edge.direction),
        'role': borderPrimitiveRoleV1WireName(role),
      },
      action: 'border.action.allow_required_orientation',
    );

BorderDiagnostic _error(
  BorderResolutionRequest request, {
  required String code,
  required BorderDiagnosticScope scope,
  String? strokeId,
  int? segmentIndex,
  GridPos? cell,
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
      strokeId: strokeId,
      segmentIndex: segmentIndex,
      cell: cell,
      parameters: parameters,
      suggestedAction: action,
    );

final class _SpanPacking {
  const _SpanPacking({
    required this.primitive,
    required this.transform,
    required this.localIntervals,
    required this.coverageStartsPx,
  });

  final BorderPublishedPrimitive primitive;
  final BorderSpriteTransform transform;
  final List<_Interval> localIntervals;
  final List<int> coverageStartsPx;
}

final class _SpanPackingAttempt {
  const _SpanPackingAttempt({
    required this.packing,
    required this.coverage,
  });

  final _SpanPacking packing;
  final _Coverage coverage;
}

final class _GeneratedPlacement {
  const _GeneratedPlacement({
    required this.edgeIndex,
    required this.primitive,
    required this.placement,
  });

  final int edgeIndex;
  final BorderPublishedPrimitive primitive;
  final BorderResolvedPlacement placement;
}

final class _Interval {
  const _Interval({required this.startPx, required this.endPx});

  final int startPx;
  final int endPx;
}

final class _Coverage {
  const _Coverage({
    required this.coveredLengthPx,
    required this.longestGapPx,
    required this.maximumPairwiseOverlapPx,
  });

  final int coveredLengthPx;
  final int longestGapPx;
  final int maximumPairwiseOverlapPx;
}
