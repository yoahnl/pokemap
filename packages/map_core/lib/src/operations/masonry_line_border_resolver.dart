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

/// Exact per-edge coverage trace retained from one masonry resolution.
@immutable
final class MasonryLineEdgeResolutionEvidence {
  const MasonryLineEdgeResolutionEvidence({
    required this.strokeId,
    required this.edgeIndex,
    required this.coveredLengthPx,
    required this.longestGapPx,
    required this.maximumPairwiseOverlapPx,
  });

  final String strokeId;
  final int edgeIndex;
  final int coveredLengthPx;
  final int longestGapPx;
  final int maximumPairwiseOverlapPx;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasonryLineEdgeResolutionEvidence &&
          strokeId == other.strokeId &&
          edgeIndex == other.edgeIndex &&
          coveredLengthPx == other.coveredLengthPx &&
          longestGapPx == other.longestGapPx &&
          maximumPairwiseOverlapPx == other.maximumPairwiseOverlapPx;

  @override
  int get hashCode => Object.hash(
        strokeId,
        edgeIndex,
        coveredLengthPx,
        longestGapPx,
        maximumPairwiseOverlapPx,
      );
}

/// Result plus exact masonry packing evidence for canonical-gallery previews.
@immutable
final class MasonryLineBorderResolutionEvidence {
  MasonryLineBorderResolutionEvidence({
    required this.result,
    required List<MasonryLineEdgeResolutionEvidence> edges,
  }) : _edges = List<MasonryLineEdgeResolutionEvidence>.unmodifiable(edges);

  final BorderResolutionResult result;
  final List<MasonryLineEdgeResolutionEvidence> _edges;

  List<MasonryLineEdgeResolutionEvidence> get edges => _edges;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasonryLineBorderResolutionEvidence &&
          result == other.result &&
          _listsEqual(_edges, other._edges);

  @override
  int get hashCode => Object.hash(result, Object.hashAll(_edges));
}

/// Resolves one V1 masonry stroke feature into immutable native-size visuals.
BorderResolutionResult resolveMasonryLineBorder(
  BorderResolutionRequest request,
) =>
    resolveMasonryLineBorderWithEvidence(request).result;

/// Resolves masonry and exposes the coverage trace used for diagnostics.
MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
  BorderResolutionRequest request,
) {
  final diagnostics = <BorderDiagnostic>[];
  final revision = request.blueprintRevision;
  if (revision == null) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.blueprint_unavailable',
      scope: BorderDiagnosticScope.blueprint,
      action: 'border.action.publish_blueprint',
    ));
    return _failure(diagnostics);
  }
  final definition = revision.definition;
  if (definition.template != BorderBlueprintTemplate.masonryLine) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.template_mismatch',
      scope: BorderDiagnosticScope.blueprint,
      parameters: <String, Object?>{'template': definition.template.name},
      action: 'border.action.select_masonry_line_blueprint',
    ));
  }
  final geometry = request.feature.geometry;
  if (geometry is! BorderStrokeGeometry) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.stroke_geometry_required',
      scope: BorderDiagnosticScope.geometry,
      action: 'border.action.draw_nonempty_stroke',
    ));
    return _failure(diagnostics);
  }
  if (geometry.strokes.isEmpty) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.stroke_geometry_empty',
      scope: BorderDiagnosticScope.geometry,
      action: 'border.action.draw_nonempty_stroke',
    ));
  }
  if (request.feature.overrides.isNotEmpty) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.overrides_not_supported',
      scope: BorderDiagnosticScope.feature,
      action: 'border.action.remove_overrides_before_resolution',
    ));
  }
  if (request.feature.keepOutRegions.isNotEmpty) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.keep_outs_not_supported',
      scope: BorderDiagnosticScope.feature,
      action: 'border.action.remove_keep_outs_before_resolution',
    ));
  }
  if (definition.ground != null) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.linear_ground_not_supported',
      scope: BorderDiagnosticScope.blueprint,
      action: 'border.action.remove_ground_from_linear_blueprint',
    ));
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
      diagnostics.add(_error(
        request,
        code: 'border.resolution.stroke_out_of_bounds',
        scope: BorderDiagnosticScope.stroke,
        strokeId: stroke.id,
        cell: outside.first,
        action: 'border.action.move_stroke_inside_map',
      ));
      continue;
    }
    try {
      final canonical = canonicalizeBorderStrokeV1(
        id: stroke.id,
        sampledPoints: stroke.points,
        closed: stroke.closed,
      );
      if (!_sameStroke(stroke, canonical)) {
        diagnostics.add(_error(
          request,
          code: 'border.resolution.stroke_not_canonical',
          scope: BorderDiagnosticScope.stroke,
          strokeId: stroke.id,
          action: 'border.action.redraw_canonical_stroke',
        ));
        continue;
      }
      lattices.add(
        buildBorderLinearLatticeV1(
          stroke: stroke,
          tileSizePx: request.tileSizePx,
        ),
      );
    } on ValidationException {
      diagnostics.add(_error(
        request,
        code: 'border.resolution.stroke_invalid',
        scope: BorderDiagnosticScope.stroke,
        strokeId: stroke.id,
        action: 'border.action.redraw_valid_stroke',
      ));
    }
  }

  final primitives = definition.primitives.toList(growable: false)
    ..sort((left, right) => left.id.compareTo(right.id));
  _diagnosePublishedInputs(
    request,
    primitives: primitives,
    diagnostics: diagnostics,
  );
  final structuralCandidates = primitives
      .where((primitive) => _isStructuralRole(primitive.role))
      .toList(growable: false);
  if (structuralCandidates.isEmpty) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.structural_role_missing',
      scope: BorderDiagnosticScope.blueprint,
      action: 'border.action.assign_structural_primitive',
    ));
  }
  for (final lattice in lattices) {
    for (final edge in lattice.edges) {
      final quarterTurns = borderCardinalDirectionV1Rank(edge.direction);
      if (!structuralCandidates.any(
        (primitive) =>
            primitive.transforms.allowedQuarterTurns.contains(quarterTurns),
      )) {
        diagnostics.add(_error(
          request,
          code: 'border.resolution.orientation_unavailable',
          scope: BorderDiagnosticScope.segment,
          strokeId: lattice.strokeId,
          segmentIndex: edge.index,
          cell: edge.startCell,
          parameters: <String, Object?>{
            'direction': borderCardinalDirectionV1WireName(edge.direction),
          },
          action: 'border.action.allow_required_orientation',
        ));
      }
    }
  }

  if (_hasErrors(diagnostics)) {
    return _failure(diagnostics);
  }

  final params = request.feature.paramsOverride ?? definition.defaults;
  final generated = <_GeneratedLinePlacement>[];
  final edgeEvidence = <MasonryLineEdgeResolutionEvidence>[];
  for (final lattice in lattices) {
    final coverageAccumulator = _StrokeCoverageAccumulator();
    final occupiedSites =
        <(BorderPrimitiveRole, BorderCardinalDirection, int, int)>{};
    for (final edge in lattice.edges) {
      for (final role in const <BorderPrimitiveRole>[
        BorderPrimitiveRole.structureLarge,
        BorderPrimitiveRole.structureMedium,
        BorderPrimitiveRole.filler,
      ]) {
        final candidates = structuralCandidates
            .where((primitive) => primitive.role == role)
            .toList(growable: false);
        final eligible = _eligibleForDirection(candidates, edge.direction);
        if (eligible.isEmpty) {
          continue;
        }
        final maximumExtent = _maximumTangentOpaqueExtentPx(
          eligible,
          edge.direction,
        );
        final spacing = _spacingPx(
          maximumExtent,
          maxOverlapPx: params.maxOverlapPx,
        );
        final sites = _sitesForEdge(
          request,
          strokeId: lattice.strokeId,
          edge: edge,
          spacingPx: spacing,
          maximumExtentPx: maximumExtent,
          centerSingleOverhang: lattice.edges.length == 1,
        );
        final passIndex = _structuralPassForRole(role);
        for (var ordinalLocal = 0;
            ordinalLocal < sites.length;
            ordinalLocal += 1) {
          final site = sites[ordinalLocal];
          final normalAxis = _edgeStartNormalWorldPx(request, edge);
          final siteKey = (role, edge.direction, normalAxis, site);
          if (occupiedSites.contains(siteKey)) {
            continue;
          }
          final placement = _resolveStructuralPlacement(
            request: request,
            strokeId: lattice.strokeId,
            edge: edge,
            candidates: eligible,
            role: role,
            passIndex: passIndex,
            drawBand: BorderDrawBand.structure,
            ordinalLocal: ordinalLocal,
            latticeSitePx: site,
            params: params,
          );
          if (placement == null) {
            continue;
          }
          final candidateIntervals = _strokePlacementIntervals(
            request: request,
            lattice: lattice,
            generated: <_GeneratedLinePlacement>[placement],
          );
          if (candidateIntervals.length == 1 &&
              coverageAccumulator.tryAdd(
                candidateIntervals.single,
                maxOverlapPx: params.maxOverlapPx,
              )) {
            generated.add(placement);
            occupiedSites.add(siteKey);
          }
        }
      }
    }
    final strokeIntervals = coverageAccumulator.intervalsByPlacement;
    final strokeCoverage = _assessCoverageDomain(
      intervalsByPlacement: strokeIntervals,
      domainLengthPx: lattice.totalLengthPx,
      closed: lattice.closed,
    );
    for (final edge in lattice.edges) {
      final coverage = _assessEdgeCoverage(
        edge: edge,
        strokeIntervals: strokeIntervals,
      );
      edgeEvidence.add(
        MasonryLineEdgeResolutionEvidence(
          strokeId: lattice.strokeId,
          edgeIndex: edge.index,
          coveredLengthPx: coverage.coveredLengthPx,
          longestGapPx: coverage.longestGapPx,
          maximumPairwiseOverlapPx: coverage.maximumPairwiseOverlapPx,
        ),
      );
    }
    if (strokeCoverage.longestGapPx > params.gapTolerancePx) {
      diagnostics.add(_error(
        request,
        code: 'border.resolution.coverage_gap',
        scope: BorderDiagnosticScope.stroke,
        strokeId: lattice.strokeId,
        cell: lattice.nodes.first.cell,
        parameters: <String, Object?>{
          'longestGapPx': strokeCoverage.longestGapPx,
          'gapTolerancePx': params.gapTolerancePx,
        },
        action: 'border.action.add_or_adjust_filler',
      ));
    }
    if (strokeCoverage.maximumPairwiseOverlapPx > params.maxOverlapPx) {
      diagnostics.add(_error(
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
      ));
    }
    _resolveTerminations(
      request: request,
      lattice: lattice,
      primitives: primitives,
      generated: generated,
      diagnostics: diagnostics,
    );
    _resolveSurfacePatches(
      request: request,
      lattice: lattice,
      primitives: primitives,
      params: params,
      generated: generated,
    );
  }

  if (_hasErrors(diagnostics)) {
    return MasonryLineBorderResolutionEvidence(
      result: _failed(diagnostics),
      edges: edgeEvidence,
    );
  }
  final placements = generated.map((entry) => entry.placement).toList()
    ..sort(
      (left, right) => left.stableOrderKey.compareTo(right.stableOrderKey),
    );
  if (placements.isEmpty) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.materialization_empty',
      scope: BorderDiagnosticScope.materialization,
      action: 'border.action.adjust_blueprint_or_geometry',
    ));
    return MasonryLineBorderResolutionEvidence(
      result: _failed(diagnostics),
      edges: edgeEvidence,
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
  return MasonryLineBorderResolutionEvidence(
    result: BorderResolutionResult(
      materialization: materialization,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    ),
    edges: edgeEvidence,
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
      diagnostics.add(_error(
        request,
        code: 'border.resolution.duplicate_primitive_id',
        scope: BorderDiagnosticScope.primitive,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.assign_unique_primitive_ids',
      ));
    }
    if (!_masonryRoleAllowed(primitive.role)) {
      diagnostics.add(_error(
        request,
        code: 'border.resolution.role_not_supported_by_template',
        scope: BorderDiagnosticScope.primitive,
        parameters: <String, Object?>{
          'primitiveId': primitive.id,
          'role': primitive.role.name,
        },
        action: 'border.action.remove_incompatible_role',
      ));
    }
    final metrics = primitive.publishedMetrics;
    final anchorValid = primitive.anchorPx.x >= 0 &&
        primitive.anchorPx.y >= 0 &&
        primitive.anchorPx.x < metrics.pixelSize.width &&
        primitive.anchorPx.y < metrics.pixelSize.height;
    final defaultAnchorValid = metrics.defaultAnchorPx.x >= 0 &&
        metrics.defaultAnchorPx.y >= 0 &&
        metrics.defaultAnchorPx.x < metrics.pixelSize.width &&
        metrics.defaultAnchorPx.y < metrics.pixelSize.height;
    if (!anchorValid || !defaultAnchorValid) {
      diagnostics.add(_error(
        request,
        code: 'border.resolution.anchor_outside_asset',
        scope: BorderDiagnosticScope.primitive,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.correct_primitive_anchor',
      ));
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
        diagnostics.add(_error(
          request,
          code: 'border.resolution.structural_occupancy_empty',
          scope: BorderDiagnosticScope.primitive,
          parameters: <String, Object?>{'primitiveId': primitive.id},
          action: 'border.action.select_nonempty_primitive',
        ));
      }
    } on FormatException {
      diagnostics.add(_error(
        request,
        code: 'border.resolution.structural_occupancy_invalid',
        scope: BorderDiagnosticScope.primitive,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.reanalyze_primitive',
      ));
    }
    final snapshot = request.visualSnapshotById(primitive.visualSnapshotId);
    if (snapshot == null ||
        snapshot.frames.any(
          (frame) =>
              frame.sourceRectPx.width != metrics.pixelSize.width ||
              frame.sourceRectPx.height != metrics.pixelSize.height,
        )) {
      diagnostics.add(_error(
        request,
        code: 'border.resolution.visual_snapshot_invalid',
        scope: BorderDiagnosticScope.visualSnapshot,
        parameters: <String, Object?>{
          'primitiveId': primitive.id,
          'snapshotId': primitive.visualSnapshotId,
        },
        action: 'border.action.restore_or_republish_snapshot',
      ));
    }
  }
}

bool _isStructuralRole(BorderPrimitiveRole role) =>
    role == BorderPrimitiveRole.structureLarge ||
    role == BorderPrimitiveRole.structureMedium ||
    role == BorderPrimitiveRole.filler;

int _structuralPassForRole(BorderPrimitiveRole role) => switch (role) {
      BorderPrimitiveRole.structureLarge => 0,
      BorderPrimitiveRole.structureMedium => 1,
      BorderPrimitiveRole.filler => 2,
      _ => throw const ValidationException(
          'Masonry structural pass requires a structural role',
        ),
    };

bool _masonryRoleAllowed(BorderPrimitiveRole role) => switch (role) {
      BorderPrimitiveRole.structureLarge ||
      BorderPrimitiveRole.structureMedium ||
      BorderPrimitiveRole.filler ||
      BorderPrimitiveRole.post ||
      BorderPrimitiveRole.accent ||
      BorderPrimitiveRole.surfacePatch =>
        true,
      BorderPrimitiveRole.span || BorderPrimitiveRole.outerAccent => false,
    };

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

int _maximumTangentOpaqueExtentPx(
  Iterable<BorderPublishedPrimitive> candidates,
  BorderCardinalDirection direction,
) {
  final tangentIsX = _tangentIsX(direction);
  final quarterTurns = borderCardinalDirectionV1Rank(direction);
  var maximum = 0;
  for (final candidate in candidates) {
    final geometry = resolveBorderSpriteGeometry(
      metrics: candidate.publishedMetrics,
      sourceAnchorPx: candidate.anchorPx,
      transform: BorderSpriteTransform(
        quarterTurns: quarterTurns,
        flipX: false,
      ),
      targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
    );
    final extent = tangentIsX
        ? geometry.transformedOpaqueBoundsPx.width
        : geometry.transformedOpaqueBoundsPx.height;
    if (extent > maximum) {
      maximum = extent;
    }
  }
  if (maximum <= 0) {
    throw const ValidationException(
      'Masonry structural primitive tangent extent must be positive',
    );
  }
  return maximum;
}

int _spacingPx(int extentPx, {required int maxOverlapPx}) {
  final spacing = extentPx - maxOverlapPx;
  return spacing > 0 ? spacing : 1;
}

List<int> _sitesForEdge(
  BorderResolutionRequest request, {
  required String strokeId,
  required BorderLinearEdge edge,
  required int spacingPx,
  required int maximumExtentPx,
  bool centerSingleOverhang = false,
}) {
  final start = _edgeStartAxisWorldPx(request, edge);
  final end = _edgeEndAxisWorldPx(request, edge);
  final low = start < end ? start : end;
  final high = start < end ? end : start;
  if (maximumExtentPx == high - low) {
    return <int>[low];
  }
  if (centerSingleOverhang && maximumExtentPx >= high - low) {
    return <int>[
      low - (maximumExtentPx - (high - low)) ~/ 2,
    ];
  }
  final phase = BorderDeterministicRng.fromComponents(
    <BorderRngKeyComponent>[
      BorderRngKeyComponent.text(request.feature.id),
      BorderRngKeyComponent.text(strokeId),
      BorderRngKeyComponent.text(
        borderCardinalDirectionV1WireName(edge.direction),
      ),
      BorderRngKeyComponent.signedInt64(request.feature.seed),
    ],
  ).nextIndex(spacingPx);
  final first = phase + _floorDiv(low - phase, spacingPx) * spacingPx;
  final result = <int>[];
  for (var site = first; site < high; site += spacingPx) {
    if (site + maximumExtentPx > low) {
      result.add(site);
    }
  }
  if (result.isEmpty) {
    result.add(first);
  }
  if (!_directionIsForward(edge.direction)) {
    return List<int>.unmodifiable(result.reversed);
  }
  return List<int>.unmodifiable(result);
}

_GeneratedLinePlacement? _resolveStructuralPlacement({
  required BorderResolutionRequest request,
  required String strokeId,
  required BorderLinearEdge edge,
  required List<BorderPublishedPrimitive> candidates,
  required BorderPrimitiveRole role,
  required int passIndex,
  required BorderDrawBand drawBand,
  required int ordinalLocal,
  required int latticeSitePx,
  required BorderGenerationParams params,
}) {
  if (candidates.isEmpty) {
    return null;
  }
  var selected = candidates.first;
  if (params.variationPermille > 0 &&
      _passesPermille(
        _decisionRng(
          request,
          strokeId: strokeId,
          edge: edge,
          passIndex: passIndex,
          role: role,
          ordinalLocal: ordinalLocal,
          decision: 'variation-gate',
        ),
        params.variationPermille,
      )) {
    selected = chooseBorderWeightedCandidate(
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
  final flipX = selected.transforms.allowFlipX &&
      params.variationPermille > 0 &&
      _decisionRng(
            request,
            strokeId: strokeId,
            edge: edge,
            passIndex: passIndex,
            role: role,
            ordinalLocal: ordinalLocal,
            decision: 'flip',
          ).nextIndex(1000) <
          params.variationPermille ~/ 2;
  final transform = BorderSpriteTransform(
    quarterTurns: borderCardinalDirectionV1Rank(edge.direction),
    flipX: flipX,
  );
  final origin = resolveBorderSpriteGeometry(
    metrics: selected.publishedMetrics,
    sourceAnchorPx: selected.anchorPx,
    transform: transform,
    targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
  );
  final tangentIsX = _tangentIsX(edge.direction);
  final targetTangent = latticeSitePx +
      (tangentIsX
          ? origin.transformedAnchorPx.x - origin.transformedOpaqueBoundsPx.x
          : origin.transformedAnchorPx.y - origin.transformedOpaqueBoundsPx.y);
  final edgeNormal = _edgeStartNormalWorldPx(request, edge);
  final jitterMax = computeBorderJitterMaxPx(
    irregularityPermille: params.irregularityPermille,
    tileSizePx:
        tangentIsX ? request.tileSizePx.height : request.tileSizePx.width,
  );
  final normalJitter = jitterMax == 0
      ? 0
      : _decisionRng(
            request,
            strokeId: strokeId,
            edge: edge,
            passIndex: passIndex,
            role: role,
            ordinalLocal: ordinalLocal,
            decision: 'normal-jitter',
          ).nextIndex(jitterMax * 2 + 1) -
          jitterMax;
  final target = tangentIsX
      ? BorderPixelPos(x: targetTangent, y: edgeNormal + normalJitter)
      : BorderPixelPos(x: edgeNormal + normalJitter, y: targetTangent);
  final sprite = resolveBorderSpriteGeometry(
    metrics: selected.publishedMetrics,
    sourceAnchorPx: selected.anchorPx,
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
    role: role,
    rank: 0,
    ordinalLocal: ordinalLocal,
  );
  final order = buildBorderStableOrderKey(
    drawBand: drawBand,
    mapWidth: request.mapSize.width,
    anchorCell: edge.startCell,
    passIndex: passIndex,
    rank: 0,
    ordinalLocal: ordinalLocal,
    slotKey: slotKey,
  );
  return _GeneratedLinePlacement(
    edgeIndex: edge.index,
    primitive: selected,
    placement: BorderResolvedPlacement(
      id: 'border-placement-v1:${slotKey.substring(borderSlotKeyV1Prefix.length)}',
      slotKey: slotKey,
      primitiveId: selected.id,
      visualSnapshotId: selected.visualSnapshotId,
      anchorCell: edge.startCell,
      topLeftWorldPx: sprite.topLeftWorldPx,
      opaqueWorldBoundsPx: sprite.opaqueWorldBoundsPx,
      transform: transform,
      drawBand: drawBand,
      stableOrderKey: order,
    ),
  );
}

void _resolveTerminations({
  required BorderResolutionRequest request,
  required BorderLinearStrokeLattice lattice,
  required List<BorderPublishedPrimitive> primitives,
  required List<_GeneratedLinePlacement> generated,
  required List<BorderDiagnostic> diagnostics,
}) {
  if (lattice.closed) {
    return;
  }
  final terminationCandidates = primitives
      .where(
        (primitive) =>
            primitive.role == BorderPrimitiveRole.post ||
            primitive.role == BorderPrimitiveRole.accent,
      )
      .toList(growable: false)
    ..sort((left, right) {
      final leftRank = left.role == BorderPrimitiveRole.post ? 0 : 1;
      final rightRank = right.role == BorderPrimitiveRole.post ? 0 : 1;
      final byRole = leftRank.compareTo(rightRank);
      return byRole != 0 ? byRole : left.id.compareTo(right.id);
    });
  for (final node in <BorderLinearNodeNeed>[
    lattice.nodes.first,
    lattice.nodes.last,
  ]) {
    final direction = node.termination == BorderLinearTerminationNeed.startCap
        ? _oppositeDirection(node.outgoingDirection!)
        : node.incomingDirection!;
    final eligible = _eligibleForDirection(terminationCandidates, direction)
      ..sort((left, right) {
        final leftRank = left.role == BorderPrimitiveRole.post ? 0 : 1;
        final rightRank = right.role == BorderPrimitiveRole.post ? 0 : 1;
        final byRole = leftRank.compareTo(rightRank);
        return byRole != 0 ? byRole : left.id.compareTo(right.id);
      });
    if (eligible.isEmpty) {
      diagnostics.add(_warning(
        request,
        code: 'border.resolution.masonry_end_finish_missing',
        scope: BorderDiagnosticScope.segment,
        strokeId: lattice.strokeId,
        segmentIndex: node.index == 0 ? 0 : lattice.edges.last.index,
        cell: node.cell,
        action: 'border.action.add_optional_end_finish',
      ));
      continue;
    }
    final primitive = eligible.first;
    final edge = node.index == 0 ? lattice.edges.first : lattice.edges.last;
    final transform = BorderSpriteTransform(
      quarterTurns: borderCardinalDirectionV1Rank(direction),
      flipX: false,
    );
    final target = _cellCenterWorldPx(request, node.cell);
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
      diagnostics.add(_warning(
        request,
        code: 'border.resolution.masonry_end_finish_outside_canvas',
        scope: BorderDiagnosticScope.segment,
        strokeId: lattice.strokeId,
        segmentIndex: node.index == 0 ? 0 : lattice.edges.last.index,
        cell: node.cell,
        action: 'border.action.adjust_optional_end_finish_anchor',
      ));
      continue;
    }
    final ordinalLocal = node.index == 0 ? 0 : 1;
    final slotKey = buildBorderLineSlotKey(
      featureId: request.feature.id,
      strokeId: lattice.strokeId,
      edgeStart: edge.startCell,
      edgeEnd: edge.endCell,
      passIndex: 3,
      role: primitive.role,
      rank: 0,
      ordinalLocal: ordinalLocal,
    );
    final order = buildBorderStableOrderKey(
      drawBand: BorderDrawBand.accent,
      mapWidth: request.mapSize.width,
      anchorCell: node.cell,
      passIndex: 3,
      rank: 0,
      ordinalLocal: ordinalLocal,
      slotKey: slotKey,
    );
    generated.add(
      _GeneratedLinePlacement(
        edgeIndex: edge.index,
        primitive: primitive,
        placement: BorderResolvedPlacement(
          id: 'border-placement-v1:${slotKey.substring(borderSlotKeyV1Prefix.length)}',
          slotKey: slotKey,
          primitiveId: primitive.id,
          visualSnapshotId: primitive.visualSnapshotId,
          anchorCell: node.cell,
          topLeftWorldPx: sprite.topLeftWorldPx,
          opaqueWorldBoundsPx: sprite.opaqueWorldBoundsPx,
          transform: transform,
          drawBand: BorderDrawBand.accent,
          stableOrderKey: order,
        ),
      ),
    );
  }
}

void _resolveSurfacePatches({
  required BorderResolutionRequest request,
  required BorderLinearStrokeLattice lattice,
  required List<BorderPublishedPrimitive> primitives,
  required BorderGenerationParams params,
  required List<_GeneratedLinePlacement> generated,
}) {
  if (params.detailDensityPermille == 0) {
    return;
  }
  final source = primitives
      .where((primitive) => primitive.role == BorderPrimitiveRole.surfacePatch)
      .toList(growable: false);
  final occupiedSites = <(BorderCardinalDirection, int, int)>{};
  for (final edge in lattice.edges) {
    final eligible = _eligibleForDirection(source, edge.direction);
    if (eligible.isEmpty) {
      continue;
    }
    final maximumExtent = _maximumTangentOpaqueExtentPx(
      eligible,
      edge.direction,
    );
    final sites = _sitesForEdge(
      request,
      strokeId: lattice.strokeId,
      edge: edge,
      spacingPx: maximumExtent,
      maximumExtentPx: maximumExtent,
    );
    for (var ordinalLocal = 0; ordinalLocal < sites.length; ordinalLocal += 1) {
      final site = sites[ordinalLocal];
      if (!occupiedSites.add((
        edge.direction,
        _edgeStartNormalWorldPx(request, edge),
        site,
      ))) {
        continue;
      }
      if (_decisionRng(
            request,
            strokeId: lattice.strokeId,
            edge: edge,
            passIndex: 4,
            role: BorderPrimitiveRole.surfacePatch,
            ordinalLocal: ordinalLocal,
            decision: 'detail-density',
          ).nextIndex(1000) >=
          params.detailDensityPermille) {
        continue;
      }
      final placement = _resolveStructuralPlacement(
        request: request,
        strokeId: lattice.strokeId,
        edge: edge,
        candidates: eligible,
        role: BorderPrimitiveRole.surfacePatch,
        passIndex: 4,
        drawBand: BorderDrawBand.innerFinish,
        ordinalLocal: ordinalLocal,
        latticeSitePx: site,
        params: params,
      );
      if (placement != null) {
        generated.add(placement);
      }
    }
  }
}

List<_PlacementIntervals> _strokePlacementIntervals({
  required BorderResolutionRequest request,
  required BorderLinearStrokeLattice lattice,
  required List<_GeneratedLinePlacement> generated,
}) {
  final intervalsByPlacement = <_PlacementIntervals>[];
  for (final entry in generated) {
    final edge = lattice.edges[entry.edgeIndex];
    final edgeStartWorldPx = _edgeStartAxisWorldPx(request, edge);
    final worldIntervals = _projectOccupiedTangentIntervals(
      primitive: entry.primitive,
      placement: entry.placement,
      destinationX: _tangentIsX(edge.direction),
    );
    final unwrapped = <_Interval>[];
    for (final interval in worldIntervals) {
      final localStart = _directionIsForward(edge.direction)
          ? interval.startPx - edgeStartWorldPx
          : edgeStartWorldPx - interval.endPx;
      final localEnd = _directionIsForward(edge.direction)
          ? interval.endPx - edgeStartWorldPx
          : edgeStartWorldPx - interval.startPx;
      unwrapped.add(
        _Interval(
          startPx: edge.startAbscissaPx + localStart,
          endPx: edge.startAbscissaPx + localEnd,
        ),
      );
    }
    final intervals = lattice.closed
        ? _wrapIntervals(unwrapped, lattice.totalLengthPx)
        : _clipIntervals(
            unwrapped,
            startPx: 0,
            endPx: lattice.totalLengthPx,
          );
    if (intervals.isEmpty) {
      continue;
    }
    intervalsByPlacement.add(
      _PlacementIntervals(
        intervals: _mergeIntervals(intervals),
        drawBand: entry.placement.drawBand,
        passIndex: entry.placement.stableOrderKey.passIndex,
      ),
    );
  }
  return intervalsByPlacement;
}

_EdgeCoverage _assessEdgeCoverage({
  required BorderLinearEdge edge,
  required List<_PlacementIntervals> strokeIntervals,
}) {
  final intervalsByPlacement = <_PlacementIntervals>[];
  for (final entry in strokeIntervals) {
    final clipped = _clipIntervals(
      entry.intervals,
      startPx: edge.startAbscissaPx,
      endPx: edge.endAbscissaPx,
    );
    final local = <_Interval>[
      for (final interval in clipped)
        _Interval(
          startPx: interval.startPx - edge.startAbscissaPx,
          endPx: interval.endPx - edge.startAbscissaPx,
        ),
    ];
    if (local.isNotEmpty) {
      intervalsByPlacement.add(
        _PlacementIntervals(
          intervals: _mergeIntervals(local),
          drawBand: entry.drawBand,
          passIndex: entry.passIndex,
        ),
      );
    }
  }
  return _assessCoverageDomain(
    intervalsByPlacement: intervalsByPlacement,
    domainLengthPx: edge.lengthPx,
    closed: false,
  );
}

_EdgeCoverage _assessCoverageDomain({
  required List<_PlacementIntervals> intervalsByPlacement,
  required int domainLengthPx,
  required bool closed,
}) {
  final intervals = _mergeIntervals(<_Interval>[
    for (final placement in intervalsByPlacement) ...placement.intervals,
  ]);
  var cursor = 0;
  var covered = 0;
  var longestGap = 0;
  for (final interval in intervals) {
    if (interval.startPx > cursor) {
      final gap = interval.startPx - cursor;
      if (gap > longestGap) longestGap = gap;
    }
    final start = interval.startPx > cursor ? interval.startPx : cursor;
    if (interval.endPx > start) covered += interval.endPx - start;
    if (interval.endPx > cursor) cursor = interval.endPx;
  }
  if (cursor < domainLengthPx) {
    final gap = domainLengthPx - cursor;
    if (gap > longestGap) longestGap = gap;
  }
  if (closed && intervals.isNotEmpty) {
    final wrapGap =
        intervals.first.startPx + (domainLengthPx - intervals.last.endPx);
    if (wrapGap > longestGap) longestGap = wrapGap;
  }
  return _EdgeCoverage(
    coveredLengthPx: covered,
    longestGapPx: longestGap,
    maximumPairwiseOverlapPx: _maximumPairwiseOverlap(
      intervalsByPlacement,
    ),
  );
}

int _maximumPairwiseOverlap(List<_PlacementIntervals> source) {
  var maximum = 0;
  final groups = <(BorderDrawBand, int), List<_PlacementIntervals>>{};
  for (final placement in source) {
    groups.putIfAbsent(
      (placement.drawBand, placement.passIndex),
      () => <_PlacementIntervals>[],
    ).add(placement);
  }
  for (final group in groups.values) {
    for (var first = 0; first < group.length; first += 1) {
      for (var second = first + 1; second < group.length; second += 1) {
        final amount = _intersectionLength(
          group[first].intervals,
          group[second].intervals,
        );
        if (amount > maximum) maximum = amount;
      }
    }
  }
  return maximum;
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
    if (length <= 0) {
      continue;
    }
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

List<_Interval> _projectOccupiedTangentIntervals({
  required BorderPublishedPrimitive primitive,
  required BorderResolvedPlacement placement,
  required bool destinationX,
}) {
  final metrics = primitive.publishedMetrics;
  final axis = _sourceAxisForDestination(
    quarterTurns: placement.transform.quarterTurns,
    flipX: placement.transform.flipX,
    destinationX: destinationX,
  );
  var sourceIntervals = _occupiedSourceAxisIntervals(
    metrics,
    sourceX: axis.sourceX,
  );
  final sourceLength =
      axis.sourceX ? metrics.pixelSize.width : metrics.pixelSize.height;
  if (axis.reversed) {
    sourceIntervals = <_Interval>[
      for (final interval in sourceIntervals.reversed)
        _Interval(
          startPx: sourceLength - interval.endPx,
          endPx: sourceLength - interval.startPx,
        ),
    ];
  }
  final topLeftAxis =
      destinationX ? placement.topLeftWorldPx.x : placement.topLeftWorldPx.y;
  return <_Interval>[
    for (final interval in sourceIntervals)
      _Interval(
        startPx: topLeftAxis + interval.startPx,
        endPx: topLeftAxis + interval.endPx,
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
          'Masonry transform quarterTurns must be 0..3',
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
      continue;
    }
    if (interval.endPx > result.last.endPx) {
      result[result.length - 1] = _Interval(
        startPx: result.last.startPx,
        endPx: interval.endPx,
      );
    }
  }
  return result;
}

List<_Interval> _unionMergedIntervals(
  List<_Interval> left,
  List<_Interval> right,
) {
  final ordered = <_Interval>[];
  var leftIndex = 0;
  var rightIndex = 0;
  while (leftIndex < left.length || rightIndex < right.length) {
    final takeLeft = rightIndex >= right.length ||
        (leftIndex < left.length &&
            (left[leftIndex].startPx < right[rightIndex].startPx ||
                (left[leftIndex].startPx == right[rightIndex].startPx &&
                    left[leftIndex].endPx <= right[rightIndex].endPx)));
    final next = takeLeft ? left[leftIndex++] : right[rightIndex++];
    if (ordered.isEmpty || next.startPx > ordered.last.endPx) {
      ordered.add(next);
    } else if (next.endPx > ordered.last.endPx) {
      ordered[ordered.length - 1] = _Interval(
        startPx: ordered.last.startPx,
        endPx: next.endPx,
      );
    }
  }
  return ordered;
}

int _intervalLength(List<_Interval> intervals) => intervals.fold<int>(
      0,
      (total, interval) => total + interval.endPx - interval.startPx,
    );

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

bool _passesPermille(BorderDeterministicRng rng, int permille) =>
    permille >= 1000 || (permille > 0 && rng.nextIndex(1000) < permille);

int _edgeStartAxisWorldPx(
  BorderResolutionRequest request,
  BorderLinearEdge edge,
) =>
    _tangentIsX(edge.direction)
        ? edge.startCell.x * request.tileSizePx.width +
            request.tileSizePx.width ~/ 2
        : edge.startCell.y * request.tileSizePx.height +
            request.tileSizePx.height ~/ 2;

int _edgeEndAxisWorldPx(
  BorderResolutionRequest request,
  BorderLinearEdge edge,
) =>
    _tangentIsX(edge.direction)
        ? edge.endCell.x * request.tileSizePx.width +
            request.tileSizePx.width ~/ 2
        : edge.endCell.y * request.tileSizePx.height +
            request.tileSizePx.height ~/ 2;

int _edgeStartNormalWorldPx(
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

BorderCardinalDirection _oppositeDirection(
  BorderCardinalDirection direction,
) =>
    switch (direction) {
      BorderCardinalDirection.east => BorderCardinalDirection.west,
      BorderCardinalDirection.south => BorderCardinalDirection.north,
      BorderCardinalDirection.west => BorderCardinalDirection.east,
      BorderCardinalDirection.north => BorderCardinalDirection.south,
    };

int _floorDiv(int value, int positiveDivisor) {
  var quotient = value ~/ positiveDivisor;
  if (value < 0 && value % positiveDivisor != 0) quotient -= 1;
  return quotient;
}

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

MasonryLineBorderResolutionEvidence _failure(
  List<BorderDiagnostic> diagnostics,
) =>
    MasonryLineBorderResolutionEvidence(
      result: _failed(diagnostics),
      edges: const <MasonryLineEdgeResolutionEvidence>[],
    );

BorderResolutionResult _failed(List<BorderDiagnostic> diagnostics) =>
    BorderResolutionResult(
      materialization: null,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
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

BorderDiagnostic _warning(
  BorderResolutionRequest request, {
  required String code,
  required BorderDiagnosticScope scope,
  String? strokeId,
  int? segmentIndex,
  GridPos? cell,
  required String action,
}) =>
    BorderDiagnostic(
      code: code,
      severity: BorderDiagnosticSeverity.warning,
      phase: BorderDiagnosticPhase.resolution,
      scope: scope,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      strokeId: strokeId,
      segmentIndex: segmentIndex,
      cell: cell,
      suggestedAction: action,
    );

final class _GeneratedLinePlacement {
  const _GeneratedLinePlacement({
    required this.edgeIndex,
    required this.primitive,
    required this.placement,
  });

  final int edgeIndex;
  final BorderPublishedPrimitive primitive;
  final BorderResolvedPlacement placement;
}

final class _Interval {
  const _Interval({
    required this.startPx,
    required this.endPx,
  });

  final int startPx;
  final int endPx;
}

final class _PlacementIntervals {
  const _PlacementIntervals({
    required this.intervals,
    required this.drawBand,
    required this.passIndex,
  });

  final List<_Interval> intervals;
  final BorderDrawBand drawBand;
  final int passIndex;
}

final class _StrokeCoverageAccumulator {
  final List<_PlacementIntervals> _intervalsByPlacement =
      <_PlacementIntervals>[];
  final Map<(BorderDrawBand, int), List<_PlacementIntervals>> _byPass =
      <(BorderDrawBand, int), List<_PlacementIntervals>>{};
  List<_Interval> _coveredIntervals = <_Interval>[];

  List<_PlacementIntervals> get intervalsByPlacement =>
      List<_PlacementIntervals>.unmodifiable(_intervalsByPlacement);

  bool tryAdd(
    _PlacementIntervals candidate, {
    required int maxOverlapPx,
  }) {
    final candidateLength = _intervalLength(candidate.intervals);
    if (candidateLength == 0 ||
        candidateLength <=
            _intersectionLength(candidate.intervals, _coveredIntervals)) {
      return false;
    }
    final key = (candidate.drawBand, candidate.passIndex);
    final peers = _byPass[key] ?? const <_PlacementIntervals>[];
    for (final peer in peers) {
      if (_intersectionLength(candidate.intervals, peer.intervals) >
          maxOverlapPx) {
        return false;
      }
    }
    _intervalsByPlacement.add(candidate);
    _byPass.putIfAbsent(key, () => <_PlacementIntervals>[]).add(candidate);
    _coveredIntervals = _unionMergedIntervals(
      _coveredIntervals,
      candidate.intervals,
    );
    return true;
  }
}

final class _EdgeCoverage {
  const _EdgeCoverage({
    required this.coveredLengthPx,
    required this.longestGapPx,
    required this.maximumPairwiseOverlapPx,
  });

  final int coveredLengthPx;
  final int longestGapPx;
  final int maximumPairwiseOverlapPx;
}
