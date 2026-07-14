import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_signed_int64.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/geometry.dart';
import 'border_coverage.dart';
import 'border_deterministic_rng.dart';
import 'border_fingerprints.dart';
import 'border_ground_resolution.dart';
import 'border_region_contours.dart';
import 'border_rle_codec.dart';
import 'border_slot_keys.dart';
import 'border_sprite_geometry.dart';

/// Returns the conservative V1 locality halo for one organic request.
int computeOrganicEdgeBorderDirtyHaloRadiusPx(
  BorderResolutionRequest request,
) {
  final revision = request.blueprintRevision;
  if (revision == null ||
      revision.definition.template != BorderBlueprintTemplate.organicEdge) {
    throw const ValidationException(
      'Organic dirty-halo computation requires an organic published revision',
    );
  }
  final parameters =
      request.feature.paramsOverride ?? revision.definition.defaults;
  final tileSizePx = request.tileSizePx.width > request.tileSizePx.height
      ? request.tileSizePx.width
      : request.tileSizePx.height;
  return computeBorderDirtyHaloRadiusPx(
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
}

/// Resolves one V1 `organicEdge` feature into immutable saved visuals.
///
/// V1 defines quarter-turn zero as an asset whose tangent points east and
/// whose region interior lies on its right. Every other contour direction is
/// obtained only through an explicitly allowed clockwise quarter turn.
BorderResolutionResult resolveOrganicEdgeBorder(
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
    return _failed(diagnostics);
  }
  final definition = revision.definition;
  if (definition.template != BorderBlueprintTemplate.organicEdge) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.template_mismatch',
      scope: BorderDiagnosticScope.blueprint,
      parameters: <String, Object?>{'template': definition.template.name},
      action: 'border.action.select_organic_edge_blueprint',
    ));
  }
  final geometry = request.feature.geometry;
  if (geometry is! BorderRegionGeometry) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.region_geometry_required',
      scope: BorderDiagnosticScope.geometry,
      action: 'border.action.draw_nonempty_region',
    ));
    return _failed(diagnostics);
  }
  if (geometry.width != request.mapSize.width ||
      geometry.height != request.mapSize.height) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.region_size_mismatch',
      scope: BorderDiagnosticScope.geometry,
      parameters: <String, Object?>{
        'regionWidth': geometry.width,
        'regionHeight': geometry.height,
        'mapWidth': request.mapSize.width,
        'mapHeight': request.mapSize.height,
      },
      action: 'border.action.resize_region_to_map',
    ));
  }
  if (!geometry.cells.contains(true)) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.region_empty',
      scope: BorderDiagnosticScope.geometry,
      action: 'border.action.draw_nonempty_region',
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

  final keepOutMask = List<bool>.filled(
    request.mapSize.width * request.mapSize.height,
    false,
    growable: false,
  );
  for (final keepOut in request.feature.keepOutRegions) {
    if (keepOut.region.width != request.mapSize.width ||
        keepOut.region.height != request.mapSize.height) {
      diagnostics.add(_error(
        request,
        code: 'border.resolution.keep_out_size_mismatch',
        scope: BorderDiagnosticScope.geometry,
        parameters: <String, Object?>{'keepOutId': keepOut.id},
        action: 'border.action.resize_keep_out_to_map',
      ));
      continue;
    }
    for (var index = 0; index < keepOutMask.length; index += 1) {
      keepOutMask[index] = keepOutMask[index] || keepOut.region.cells[index];
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

  if (diagnostics.any(
    (diagnostic) => diagnostic.severity == BorderDiagnosticSeverity.error,
  )) {
    return _failed(diagnostics);
  }

  final params = request.feature.paramsOverride ?? definition.defaults;
  final contours = extractCanonicalBorderRegionContours(
    region: geometry,
    tileSizePx: request.tileSizePx,
  );
  if (contours.isEmpty) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.contour_empty',
      scope: BorderDiagnosticScope.geometry,
      action: 'border.action.draw_nonempty_region',
    ));
    return _failed(diagnostics);
  }

  final ground = switch (definition.ground) {
    final publishedGround? => resolveBorderGroundBand(
        region: geometry,
        ground: publishedGround,
      )
          .where(
            (cell) => !keepOutMask[cell.y * request.mapSize.width + cell.x],
          )
          .toList(growable: false),
    null => <BorderResolvedGroundCell>[],
  };

  final generated = <_GeneratedPlacement>[];
  for (var contourIndex = 0;
      contourIndex < contours.length;
      contourIndex += 1) {
    for (final edge in contours[contourIndex].edges) {
      if (_edgeIsKeptOut(edge, keepOutMask, request.mapSize.width)) {
        continue;
      }
      final quarterTurns = borderCardinalDirectionV1Rank(edge.direction);
      if (!structuralCandidates.any(
        (primitive) =>
            primitive.transforms.allowedQuarterTurns.contains(quarterTurns),
      )) {
        diagnostics.add(_error(
          request,
          code: 'border.resolution.orientation_unavailable',
          scope: BorderDiagnosticScope.segment,
          cell: edge.interiorCell,
          parameters: <String, Object?>{
            'direction': borderCardinalDirectionV1WireName(edge.direction),
          },
          action: 'border.action.allow_required_orientation',
        ));
      }
    }
  }

  for (final role in const <BorderPrimitiveRole>[
    BorderPrimitiveRole.structureLarge,
    BorderPrimitiveRole.structureMedium,
    BorderPrimitiveRole.filler,
  ]) {
    final candidates = primitives
        .where((primitive) => primitive.role == role)
        .toList(growable: false);
    if (candidates.isEmpty) {
      continue;
    }
    final passIndex = _passForRole(role);
    for (var contourIndex = 0;
        contourIndex < contours.length;
        contourIndex += 1) {
      final contour = contours[contourIndex];
      final excluded = _excludedCoverageIntervals(
        contour,
        keepOutMask: keepOutMask,
        mapWidth: request.mapSize.width,
      );
      for (var rank = 0; rank < params.depthRows; rank += 1) {
        final acceptedForRank = generated
            .where(
              (item) =>
                  item.contourIndex == contourIndex &&
                  item.placement.drawBand == BorderDrawBand.structure &&
                  item.placement.stableOrderKey.rank == rank,
            )
            .toList(growable: true);
        final occupiedLatticeSites = <(BorderCardinalDirection, int, int)>{};
        for (final edge in contour.edges) {
          if (_edgeIsKeptOut(edge, keepOutMask, request.mapSize.width)) {
            continue;
          }
          final eligible = _eligibleForDirection(candidates, edge.direction);
          if (eligible.isEmpty) {
            continue;
          }
          final maximumTangentExtent = _maximumTangentOpaqueExtentPx(
            eligible,
            edge.direction,
          );
          final spacingPx = _latticeSpacingPx(
            maximumTangentExtent,
            maxOverlapPx: params.maxOverlapPx,
          );
          final sites = _latticeSitesIntersectingEdge(
            request,
            edge: edge,
            spacingPx: spacingPx,
            maximumTangentExtentPx: maximumTangentExtent,
          );
          final normalAxis = _edgeNormalWorldAxis(edge);
          for (var ordinalLocal = 0;
              ordinalLocal < sites.length;
              ordinalLocal += 1) {
            final tangentSite = sites[ordinalLocal];
            if (!occupiedLatticeSites.add(
              (edge.direction, normalAxis, tangentSite),
            )) {
              continue;
            }
            final placement = _resolveEdgePlacement(
              request: request,
              edge: edge,
              contourIndex: contourIndex,
              candidates: eligible,
              role: role,
              drawBand: BorderDrawBand.structure,
              passIndex: passIndex,
              rank: rank,
              ordinalLocal: ordinalLocal,
              params: params,
              structure: true,
              tangentLatticeSitePx: tangentSite,
              continuitySiteIndex: _floorDiv(tangentSite, spacingPx),
              keepOutMask: keepOutMask,
            );
            if (placement == null ||
                !_addsResidualCoverage(
                  contour: contour,
                  excluded: excluded,
                  accepted: acceptedForRank,
                  candidate: placement,
                )) {
              continue;
            }
            acceptedForRank.add(placement);
            generated.add(placement);
          }
        }
      }
    }
  }

  for (final spec in const <_DecorativePass>[
    _DecorativePass(
      role: BorderPrimitiveRole.surfacePatch,
      drawBand: BorderDrawBand.innerFinish,
      passIndex: 3,
    ),
    _DecorativePass(
      role: BorderPrimitiveRole.outerAccent,
      drawBand: BorderDrawBand.outerAccent,
      passIndex: 4,
    ),
    _DecorativePass(
      role: BorderPrimitiveRole.accent,
      drawBand: BorderDrawBand.accent,
      passIndex: 5,
    ),
  ]) {
    final candidates = primitives
        .where((primitive) => primitive.role == spec.role)
        .toList(growable: false);
    if (candidates.isEmpty || params.detailDensityPermille == 0) {
      continue;
    }
    for (var contourIndex = 0;
        contourIndex < contours.length;
        contourIndex += 1) {
      for (final edge in contours[contourIndex].edges) {
        if (_edgeIsKeptOut(edge, keepOutMask, request.mapSize.width) ||
            !_includeDecoration(
              request,
              edge: edge,
              role: spec.role,
              passIndex: spec.passIndex,
              densityPermille: params.detailDensityPermille,
            )) {
          continue;
        }
        final placement = _resolveEdgePlacement(
          request: request,
          edge: edge,
          contourIndex: contourIndex,
          candidates: candidates,
          role: spec.role,
          drawBand: spec.drawBand,
          passIndex: spec.passIndex,
          rank: 0,
          ordinalLocal: 0,
          params: params,
          structure: false,
          tangentLatticeSitePx: null,
          continuitySiteIndex: null,
          keepOutMask: keepOutMask,
        );
        if (placement != null) {
          generated.add(placement);
        }
      }
    }
  }

  _diagnoseCoverage(
    request,
    contours: contours,
    generated: generated,
    keepOutMask: keepOutMask,
    params: params,
    diagnostics: diagnostics,
  );
  _diagnoseRepetition(
    request,
    generated: generated,
    diagnostics: diagnostics,
  );
  if (diagnostics.any(
    (diagnostic) => diagnostic.severity == BorderDiagnosticSeverity.error,
  )) {
    return _failed(diagnostics);
  }

  final placements = generated.map((item) => item.placement).toList()
    ..sort(
      (left, right) => left.stableOrderKey.compareTo(right.stableOrderKey),
    );
  if (ground.isEmpty && placements.isEmpty) {
    diagnostics.add(_error(
      request,
      code: 'border.resolution.materialization_empty',
      scope: BorderDiagnosticScope.materialization,
      action: 'border.action.adjust_blueprint_or_geometry',
    ));
    return _failed(diagnostics);
  }

  final components = computeBorderInputFingerprints(request);
  final inputFingerprint = computeBorderAggregateInputFingerprint(
    resolverVersion: request.resolverVersion,
    blueprintRevision: revision.revision,
    components: components,
  );
  final outputFingerprint = computeBorderOutputFingerprint(
    ground: ground,
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
    ground: ground,
    placements: placements,
  );
  return BorderResolutionResult(
    materialization: materialization,
    diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
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
    if (primitive.role == BorderPrimitiveRole.post ||
        primitive.role == BorderPrimitiveRole.span) {
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
    var occupancyValid = false;
    try {
      final expectedLength = checkedBorderRleCellCount(
        width: metrics.pixelSize.width,
        height: metrics.pixelSize.height,
        path: r'$.publishedMetrics.pixelSize',
      );
      occupancyValid = borderRleMaskHasTrue(
        metrics.occupancyMaskRle,
        expectedLength: expectedLength,
        path: r'$.publishedMetrics.occupancyMaskRle',
      );
    } on FormatException {
      diagnostics.add(_error(
        request,
        code: 'border.resolution.structural_occupancy_invalid',
        scope: BorderDiagnosticScope.primitive,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.reanalyze_primitive',
      ));
      continue;
    }
    if (!occupancyValid) {
      diagnostics.add(_error(
        request,
        code: 'border.resolution.structural_occupancy_empty',
        scope: BorderDiagnosticScope.primitive,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.select_nonempty_primitive',
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
  final ground = request.blueprintRevision!.definition.ground;
  if (ground != null) {
    final snapshotIds = ground.visualSnapshotIdsByRole.values.toSet();
    for (final snapshotId in snapshotIds) {
      if (request.visualSnapshotById(snapshotId) == null) {
        diagnostics.add(_error(
          request,
          code: 'border.resolution.ground_snapshot_missing',
          scope: BorderDiagnosticScope.visualSnapshot,
          parameters: <String, Object?>{'snapshotId': snapshotId},
          action: 'border.action.restore_or_republish_snapshot',
        ));
      }
    }
  }
}

bool _isStructuralRole(BorderPrimitiveRole role) =>
    role == BorderPrimitiveRole.structureLarge ||
    role == BorderPrimitiveRole.structureMedium ||
    role == BorderPrimitiveRole.filler;

int _passForRole(BorderPrimitiveRole role) => switch (role) {
      BorderPrimitiveRole.structureLarge => 0,
      BorderPrimitiveRole.structureMedium => 1,
      BorderPrimitiveRole.filler => 2,
      BorderPrimitiveRole.surfacePatch => 3,
      BorderPrimitiveRole.outerAccent => 4,
      BorderPrimitiveRole.accent => 5,
      BorderPrimitiveRole.post ||
      BorderPrimitiveRole.span =>
        throw const ValidationException('Linear role has no organic pass'),
    };

_GeneratedPlacement? _resolveEdgePlacement({
  required BorderResolutionRequest request,
  required BorderRegionContourEdge edge,
  required int contourIndex,
  required List<BorderPublishedPrimitive> candidates,
  required BorderPrimitiveRole role,
  required BorderDrawBand drawBand,
  required int passIndex,
  required int rank,
  required int ordinalLocal,
  required BorderGenerationParams params,
  required bool structure,
  required int? tangentLatticeSitePx,
  required int? continuitySiteIndex,
  required List<bool> keepOutMask,
}) {
  final quarterTurns = borderCardinalDirectionV1Rank(edge.direction);
  final eligible = candidates
      .where(
        (primitive) =>
            primitive.transforms.allowedQuarterTurns.contains(quarterTurns),
      )
      .toList(growable: false)
    ..sort((left, right) => left.id.compareTo(right.id));
  if (eligible.isEmpty) {
    return null;
  }

  final locallyEligible = <_LocallyEligiblePrimitive>[];
  for (final primitive in eligible) {
    final candidate = _resolveLocallyEligiblePrimitive(
      request: request,
      edge: edge,
      primitive: primitive,
      role: role,
      passIndex: passIndex,
      rank: rank,
      ordinalLocal: ordinalLocal,
      params: params,
      structure: structure,
      tangentLatticeSitePx: tangentLatticeSitePx,
      keepOutMask: keepOutMask,
    );
    if (candidate != null) {
      locallyEligible.add(candidate);
    }
  }
  if (locallyEligible.isEmpty) {
    return null;
  }

  var selected = locallyEligible.first;
  if (params.variationPermille > 0 &&
      _passesPermille(
        _decisionRng(
          request,
          edge: edge,
          passIndex: passIndex,
          role: role,
          rank: rank,
          ordinalLocal: ordinalLocal,
          decision: 'variation-gate',
        ),
        params.variationPermille,
      )) {
    selected = chooseBorderWeightedCandidate(
      _decisionRng(
        request,
        edge: edge,
        passIndex: passIndex,
        role: role,
        rank: rank,
        ordinalLocal: ordinalLocal,
        decision: 'primitive',
      ),
      <BorderWeightedCandidate<_LocallyEligiblePrimitive>>[
        for (final candidate in locallyEligible)
          BorderWeightedCandidate<_LocallyEligiblePrimitive>(
            id: candidate.primitive.id,
            value: candidate,
            weight: candidate.primitive.weight,
          ),
      ],
    )!
        .value;
  }
  final primitive = selected.primitive;
  final transform = selected.transform;
  final sprite = selected.sprite;

  final slotKey = buildBorderRegionSlotKey(
    featureId: request.feature.id,
    interiorCell: edge.interiorCell,
    side: edge.outwardSide,
    passIndex: passIndex,
    role: role,
    rank: rank,
    ordinalLocal: ordinalLocal,
  );
  final order = buildBorderStableOrderKey(
    drawBand: drawBand,
    mapWidth: request.mapSize.width,
    anchorCell: edge.interiorCell,
    passIndex: passIndex,
    rank: rank,
    ordinalLocal: ordinalLocal,
    slotKey: slotKey,
  );
  final placement = BorderResolvedPlacement(
    id: 'border-placement-v1:${slotKey.substring(borderSlotKeyV1Prefix.length)}',
    slotKey: slotKey,
    primitiveId: primitive.id,
    visualSnapshotId: primitive.visualSnapshotId,
    anchorCell: edge.interiorCell,
    topLeftWorldPx: sprite.topLeftWorldPx,
    opaqueWorldBoundsPx: sprite.opaqueWorldBoundsPx,
    transform: transform,
    drawBand: drawBand,
    stableOrderKey: order,
  );
  return _GeneratedPlacement(
    contourIndex: contourIndex,
    edge: edge,
    primitive: primitive,
    placement: placement,
    eligiblePrimitiveCount: locallyEligible.length,
    continuitySiteIndex: continuitySiteIndex,
  );
}

_LocallyEligiblePrimitive? _resolveLocallyEligiblePrimitive({
  required BorderResolutionRequest request,
  required BorderRegionContourEdge edge,
  required BorderPublishedPrimitive primitive,
  required BorderPrimitiveRole role,
  required int passIndex,
  required int rank,
  required int ordinalLocal,
  required BorderGenerationParams params,
  required bool structure,
  required int? tangentLatticeSitePx,
  required List<bool> keepOutMask,
}) {
  final quarterTurns = borderCardinalDirectionV1Rank(edge.direction);
  final flipX = primitive.transforms.allowFlipX &&
      params.variationPermille > 0 &&
      _passesPermille(
        _decisionRng(
          request,
          edge: edge,
          passIndex: passIndex,
          role: role,
          rank: rank,
          ordinalLocal: ordinalLocal,
          decision: 'flip',
        ),
        params.variationPermille ~/ 2,
      );
  final transform = BorderSpriteTransform(
    quarterTurns: quarterTurns,
    flipX: flipX,
  );
  final originGeometry = resolveBorderSpriteGeometry(
    metrics: primitive.publishedMetrics,
    sourceAnchorPx: primitive.anchorPx,
    transform: transform,
    targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
  );
  final tangentIsX = edge.direction == BorderCardinalDirection.east ||
      edge.direction == BorderCardinalDirection.west;
  final forward = _directionIsForward(edge.direction);
  final transformedAnchor = originGeometry.transformedAnchorPx;
  var targetX = edge.startWorldPx.x;
  var targetY = edge.startWorldPx.y;

  if (structure) {
    final latticeSite = tangentLatticeSitePx;
    if (latticeSite == null) {
      throw const ValidationException(
        'Structural Border placement requires a lattice site',
      );
    }
    final transformedOpaque = originGeometry.transformedOpaqueBoundsPx;
    final tangentAnchor =
        tangentIsX ? transformedAnchor.x : transformedAnchor.y;
    final tangentOpaqueStart =
        tangentIsX ? transformedOpaque.x : transformedOpaque.y;
    final tangentOpaqueEnd =
        tangentIsX ? transformedOpaque.right : transformedOpaque.bottom;
    final tangentTarget = forward
        ? latticeSite + tangentAnchor - tangentOpaqueStart
        : latticeSite + tangentAnchor - tangentOpaqueEnd;
    if (tangentIsX) {
      targetX = tangentTarget;
    } else {
      targetY = tangentTarget;
    }

    final inward = _oppositeDirectionVector(edge.outwardSide);
    final normalTileSize =
        tangentIsX ? request.tileSizePx.height : request.tileSizePx.width;
    targetX += inward.$1 * rank * normalTileSize;
    targetY += inward.$2 * rank * normalTileSize;
  } else {
    final edgeStartAxis =
        tangentIsX ? edge.startWorldPx.x : edge.startWorldPx.y;
    final edgeEndAxis = tangentIsX ? edge.endWorldPx.x : edge.endWorldPx.y;
    final tangentTopLeft = forward ? edgeStartAxis : edgeEndAxis;
    targetX =
        tangentIsX ? tangentTopLeft + transformedAnchor.x : edge.startWorldPx.x;
    targetY =
        tangentIsX ? edge.startWorldPx.y : tangentTopLeft + transformedAnchor.y;
    final outwardDistance = switch (role) {
      BorderPrimitiveRole.outerAccent =>
        tangentIsX ? request.tileSizePx.height : request.tileSizePx.width,
      BorderPrimitiveRole.surfacePatch => -(tangentIsX
          ? request.tileSizePx.height ~/ 2
          : request.tileSizePx.width ~/ 2),
      _ => 0,
    };
    final outward = _directionVector(edge.outwardSide);
    targetX += outward.$1 * outwardDistance;
    targetY += outward.$2 * outwardDistance;
  }

  final jitterMaxX = computeBorderJitterMaxPx(
    irregularityPermille: params.irregularityPermille,
    tileSizePx: request.tileSizePx.width,
  );
  final jitterMaxY = computeBorderJitterMaxPx(
    irregularityPermille: params.irregularityPermille,
    tileSizePx: request.tileSizePx.height,
  );
  if (structure) {
    final outward = _directionVector(edge.outwardSide);
    final normalMax = tangentIsX ? jitterMaxY : jitterMaxX;
    final normalJitter = _signedJitter(
      _decisionRng(
        request,
        edge: edge,
        passIndex: passIndex,
        role: role,
        rank: rank,
        ordinalLocal: ordinalLocal,
        decision: 'normal-jitter',
      ),
      normalMax,
    );
    targetX += outward.$1 * normalJitter;
    targetY += outward.$2 * normalJitter;
  } else {
    targetX += _signedJitter(
      _decisionRng(
        request,
        edge: edge,
        passIndex: passIndex,
        role: role,
        rank: rank,
        ordinalLocal: ordinalLocal,
        decision: 'jitter-x',
      ),
      jitterMaxX,
    );
    targetY += _signedJitter(
      _decisionRng(
        request,
        edge: edge,
        passIndex: passIndex,
        role: role,
        rank: rank,
        ordinalLocal: ordinalLocal,
        decision: 'jitter-y',
      ),
      jitterMaxY,
    );
  }

  final sprite = resolveBorderSpriteGeometry(
    metrics: primitive.publishedMetrics,
    sourceAnchorPx: primitive.anchorPx,
    transform: transform,
    targetAnchorWorldPx: BorderPixelPos(x: targetX, y: targetY),
  );
  final canvasSizePx = GridSize(
    width: request.mapSize.width * request.tileSizePx.width,
    height: request.mapSize.height * request.tileSizePx.height,
  );
  if (!borderPixelRectIntersectsCanvas(
        rect: sprite.opaqueWorldBoundsPx,
        canvasSizePx: canvasSizePx,
      ) ||
      _spriteOpaqueIntersectsKeepOut(
        metrics: primitive.publishedMetrics,
        transform: transform,
        topLeftWorldPx: sprite.topLeftWorldPx,
        keepOutMask: keepOutMask,
        mapSize: request.mapSize,
        tileSizePx: request.tileSizePx,
      )) {
    return null;
  }
  return _LocallyEligiblePrimitive(
    primitive: primitive,
    transform: transform,
    sprite: sprite,
  );
}

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
  final quarterTurns = borderCardinalDirectionV1Rank(direction);
  final tangentIsX = direction == BorderCardinalDirection.east ||
      direction == BorderCardinalDirection.west;
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
      'Eligible structural primitives require a positive tangent extent',
    );
  }
  return maximum;
}

int _latticeSpacingPx(
  int maximumTangentExtentPx, {
  required int maxOverlapPx,
}) {
  final spacing = maximumTangentExtentPx - maxOverlapPx;
  return spacing > 0 ? spacing : 1;
}

List<int> _latticeSitesIntersectingEdge(
  BorderResolutionRequest request, {
  required BorderRegionContourEdge edge,
  required int spacingPx,
  required int maximumTangentExtentPx,
}) {
  final tangentIsX = edge.direction == BorderCardinalDirection.east ||
      edge.direction == BorderCardinalDirection.west;
  final start = tangentIsX ? edge.startWorldPx.x : edge.startWorldPx.y;
  final end = tangentIsX ? edge.endWorldPx.x : edge.endWorldPx.y;
  final low = start < end ? start : end;
  final high = start < end ? end : start;
  final forward = _directionIsForward(edge.direction);
  final lower = forward ? low - maximumTangentExtentPx + 1 : low + 1;
  final upper = forward ? high - 1 : high + maximumTangentExtentPx - 1;
  final phase = _latticePhasePx(
    request,
    direction: edge.direction,
    spacingPx: spacingPx,
  );
  final first = phase + _ceilDiv(lower - phase, spacingPx) * spacingPx;
  final sites = <int>[];
  for (var site = first; site <= upper; site += spacingPx) {
    sites.add(site);
  }
  if (!forward) {
    return List<int>.unmodifiable(sites.reversed);
  }
  return List<int>.unmodifiable(sites);
}

int _latticePhasePx(
  BorderResolutionRequest request, {
  required BorderCardinalDirection direction,
  required int spacingPx,
}) =>
    BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
      BorderRngKeyComponent.text(request.feature.id),
      BorderRngKeyComponent.text(
        borderCardinalDirectionV1WireName(direction),
      ),
      BorderRngKeyComponent.signedInt64(request.feature.seed),
    ]).nextIndex(spacingPx);

int _ceilDiv(int value, int positiveDivisor) =>
    -_floorDiv(-value, positiveDivisor);

int _floorDiv(int value, int positiveDivisor) {
  var quotient = value ~/ positiveDivisor;
  if (value < 0 && value % positiveDivisor != 0) {
    quotient -= 1;
  }
  return quotient;
}

int _edgeNormalWorldAxis(BorderRegionContourEdge edge) =>
    edge.direction == BorderCardinalDirection.east ||
            edge.direction == BorderCardinalDirection.west
        ? edge.startWorldPx.y
        : edge.startWorldPx.x;

bool _directionIsForward(BorderCardinalDirection direction) =>
    direction == BorderCardinalDirection.east ||
    direction == BorderCardinalDirection.south;

List<BorderCoverageInterval> _excludedCoverageIntervals(
  BorderRegionContour contour, {
  required List<bool> keepOutMask,
  required int mapWidth,
}) =>
    <BorderCoverageInterval>[
      for (final edge in contour.edges)
        if (_edgeIsKeptOut(edge, keepOutMask, mapWidth))
          BorderCoverageInterval(
            startPx: edge.startAbscissaPx,
            endPx: edge.endAbscissaPx,
          ),
    ];

bool _addsResidualCoverage({
  required BorderRegionContour contour,
  required List<BorderCoverageInterval> excluded,
  required List<_GeneratedPlacement> accepted,
  required _GeneratedPlacement candidate,
}) {
  final before = _coverageForGenerated(
    contour: contour,
    excluded: excluded,
    generated: accepted,
  );
  final after = _coverageForGenerated(
    contour: contour,
    excluded: excluded,
    generated: <_GeneratedPlacement>[...accepted, candidate],
  );
  return _coveredLengthPx(after) > _coveredLengthPx(before);
}

BorderLoopCoverageAssessment _coverageForGenerated({
  required BorderRegionContour contour,
  required List<BorderCoverageInterval> excluded,
  required Iterable<_GeneratedPlacement> generated,
}) =>
    assessBorderLoopCoverage(
      perimeterPx: contour.perimeterPx,
      excludedIntervals: excluded,
      projections: <BorderStructuralCoverageProjection>[
        for (final item in generated)
          BorderStructuralCoverageProjection(
            placementId: item.placement.id,
            drawBand: item.placement.drawBand,
            passIndex: item.placement.stableOrderKey.passIndex,
            intervals: projectBorderStructuralMaskOntoEdge(
              metrics: item.primitive.publishedMetrics,
              transform: item.placement.transform,
              topLeftWorldPx: item.placement.topLeftWorldPx,
              edge: item.edge,
            ),
          ),
      ],
      gapTolerancePx: 0,
      maxOverlapPx: contour.perimeterPx,
    );

int _coveredLengthPx(BorderLoopCoverageAssessment assessment) =>
    assessment.coveredIntervals.fold<int>(
      0,
      (total, interval) => total + interval.lengthPx,
    );

bool _spriteOpaqueIntersectsKeepOut({
  required BorderPrimitiveAssetMetrics metrics,
  required BorderSpriteTransform transform,
  required BorderPixelPos topLeftWorldPx,
  required List<bool> keepOutMask,
  required GridSize mapSize,
  required GridSize tileSizePx,
}) {
  if (!keepOutMask.contains(true)) {
    return false;
  }
  final width = metrics.pixelSize.width;
  final height = metrics.pixelSize.height;
  final expectedLength = checkedBorderRleCellCount(
    width: width,
    height: height,
    path: r'$.publishedMetrics.pixelSize',
  );
  var intersects = false;
  visitBorderRleTrueRuns(
    metrics.occupancyMaskRle,
    expectedLength: expectedLength,
    path: r'$.publishedMetrics.occupancyMaskRle',
    visitor: (start, end) {
      if (intersects) {
        return;
      }
      for (var sourceIndex = start;
          sourceIndex < end && !intersects;
          sourceIndex += 1) {
        final sourceX = sourceIndex % width;
        final sourceY = sourceIndex ~/ width;
        final transformed = _transformSourcePixel(
          x: sourceX,
          y: sourceY,
          width: width,
          height: height,
          transform: transform,
        );
        final worldX = topLeftWorldPx.x + transformed.$1;
        final worldY = topLeftWorldPx.y + transformed.$2;
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

void _diagnoseCoverage(
  BorderResolutionRequest request, {
  required List<BorderRegionContour> contours,
  required List<_GeneratedPlacement> generated,
  required List<bool> keepOutMask,
  required BorderGenerationParams params,
  required List<BorderDiagnostic> diagnostics,
}) {
  for (var contourIndex = 0;
      contourIndex < contours.length;
      contourIndex += 1) {
    final contour = contours[contourIndex];
    final excluded = _excludedCoverageIntervals(
      contour,
      keepOutMask: keepOutMask,
      mapWidth: request.mapSize.width,
    );
    final projections = <BorderStructuralCoverageProjection>[];
    for (final item in generated) {
      if (item.contourIndex != contourIndex ||
          item.placement.drawBand != BorderDrawBand.structure ||
          item.placement.stableOrderKey.rank != 0) {
        continue;
      }
      projections.add(
        BorderStructuralCoverageProjection(
          placementId: item.placement.id,
          drawBand: item.placement.drawBand,
          passIndex: item.placement.stableOrderKey.passIndex,
          intervals: projectBorderStructuralMaskOntoEdge(
            metrics: item.primitive.publishedMetrics,
            transform: item.placement.transform,
            topLeftWorldPx: item.placement.topLeftWorldPx,
            edge: item.edge,
          ),
        ),
      );
    }
    final coverage = assessBorderLoopCoverage(
      perimeterPx: contour.perimeterPx,
      excludedIntervals: excluded,
      projections: projections,
      gapTolerancePx: params.gapTolerancePx,
      maxOverlapPx: params.maxOverlapPx,
    );
    if (coverage.hasExcessiveGap) {
      diagnostics.add(_error(
        request,
        code: 'border.resolution.coverage_gap',
        scope: BorderDiagnosticScope.geometry,
        parameters: <String, Object?>{
          'contourIndex': contourIndex,
          'longestGapPx': coverage.longestContiguousGapPx,
          'gapTolerancePx': params.gapTolerancePx,
        },
        action: 'border.action.add_filler_or_increase_gap_tolerance',
      ));
    }
    if (coverage.hasExcessiveOverlap) {
      diagnostics.add(_warning(
        request,
        code: 'border.resolution.coverage_overlap',
        scope: BorderDiagnosticScope.geometry,
        parameters: <String, Object?>{
          'contourIndex': contourIndex,
          'maximumOverlapPx': coverage.maximumPairwiseOverlapPx,
          'maxOverlapPx': params.maxOverlapPx,
        },
        action: 'border.action.reduce_overlap_or_adjust_assets',
      ));
    }
  }
}

void _diagnoseRepetition(
  BorderResolutionRequest request, {
  required List<_GeneratedPlacement> generated,
  required List<BorderDiagnostic> diagnostics,
}) {
  final groups = <(int, int, BorderPrimitiveRole, BorderCardinalDirection, int),
      List<_GeneratedPlacement>>{};
  for (final item in generated) {
    if (item.placement.drawBand != BorderDrawBand.structure) {
      continue;
    }
    groups.putIfAbsent(
      (
        item.contourIndex,
        item.placement.stableOrderKey.passIndex,
        item.primitive.role,
        item.edge.direction,
        item.placement.stableOrderKey.rank,
      ),
      () => <_GeneratedPlacement>[],
    ).add(item);
  }

  var emittedFourIdentical = false;
  var emittedLowVariety = false;
  for (final group in groups.values) {
    group.sort((left, right) {
      final abscissa = left.edge.startAbscissaPx.compareTo(
        right.edge.startAbscissaPx,
      );
      if (abscissa != 0) return abscissa;
      return left.placement.stableOrderKey.ordinalLocal.compareTo(
        right.placement.stableOrderKey.ordinalLocal,
      );
    });
    for (final sequence in _contiguousRepetitionSequences(group)) {
      if (!emittedFourIdentical) {
        for (var index = 0; index + 4 <= sequence.length; index += 1) {
          final window = sequence.skip(index).take(4);
          final id = sequence[index].primitive.id;
          if (window.every(
            (item) =>
                item.eligiblePrimitiveCount >= 2 && item.primitive.id == id,
          )) {
            diagnostics.add(_warning(
              request,
              code: 'border.resolution.repetition_four_identical',
              scope: BorderDiagnosticScope.feature,
              parameters: <String, Object?>{
                'primitiveId': id,
                'role': borderPrimitiveRoleV1WireName(
                  sequence[index].primitive.role,
                ),
                'orientation': borderCardinalDirectionV1WireName(
                  sequence[index].edge.direction,
                ),
                'rank': sequence[index].placement.stableOrderKey.rank,
              },
              action: 'border.action.increase_variation',
            ));
            emittedFourIdentical = true;
            break;
          }
        }
      }
      if (!emittedLowVariety) {
        for (var index = 0; index + 12 <= sequence.length; index += 1) {
          final window = sequence.skip(index).take(12).toList(growable: false);
          if (!window.every((item) => item.eligiblePrimitiveCount >= 3)) {
            continue;
          }
          final used = window.map((item) => item.primitive.id).toSet();
          if (used.length < 3) {
            diagnostics.add(_warning(
              request,
              code: 'border.resolution.repetition_low_window_variety',
              scope: BorderDiagnosticScope.feature,
              parameters: <String, Object?>{
                'distinctPrimitiveCount': used.length,
                'role': borderPrimitiveRoleV1WireName(
                  sequence[index].primitive.role,
                ),
                'orientation': borderCardinalDirectionV1WireName(
                  sequence[index].edge.direction,
                ),
                'rank': sequence[index].placement.stableOrderKey.rank,
              },
              action: 'border.action.increase_variation',
            ));
            emittedLowVariety = true;
            break;
          }
        }
      }
      if (emittedFourIdentical && emittedLowVariety) {
        break;
      }
    }
    if (emittedFourIdentical && emittedLowVariety) {
      break;
    }
  }
}

List<List<_GeneratedPlacement>> _contiguousRepetitionSequences(
  List<_GeneratedPlacement> sortedGroup,
) {
  if (sortedGroup.isEmpty) {
    return const <List<_GeneratedPlacement>>[];
  }
  final sequences = <List<_GeneratedPlacement>>[];
  var current = <_GeneratedPlacement>[sortedGroup.first];
  for (final item in sortedGroup.skip(1)) {
    final previous = current.last;
    final sameEdge = previous.edge.startAbscissaPx == item.edge.startAbscissaPx;
    final adjacentEdge =
        previous.edge.endAbscissaPx == item.edge.startAbscissaPx;
    final previousSite = previous.continuitySiteIndex;
    final itemSite = item.continuitySiteIndex;
    final expectedSite = previousSite == null
        ? null
        : _directionIsForward(previous.edge.direction)
            ? previousSite + 1
            : previousSite - 1;
    final adjacentSite = itemSite != null && itemSite == expectedSite;
    if ((!sameEdge && !adjacentEdge) || !adjacentSite) {
      sequences.add(current);
      current = <_GeneratedPlacement>[];
    }
    current.add(item);
  }
  sequences.add(current);
  return sequences;
}

bool _includeDecoration(
  BorderResolutionRequest request, {
  required BorderRegionContourEdge edge,
  required BorderPrimitiveRole role,
  required int passIndex,
  required int densityPermille,
}) =>
    _passesPermille(
      _decisionRng(
        request,
        edge: edge,
        passIndex: passIndex,
        role: role,
        rank: 0,
        ordinalLocal: 0,
        decision: 'density',
      ),
      densityPermille,
    );

BorderDeterministicRng _decisionRng(
  BorderResolutionRequest request, {
  required BorderRegionContourEdge edge,
  required int passIndex,
  required BorderPrimitiveRole role,
  required int rank,
  required int ordinalLocal,
  required String decision,
}) =>
    BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
      BorderRngKeyComponent.text(request.feature.id),
      BorderRngKeyComponent.signedInt64(
        BorderSignedInt64.fromInt(edge.interiorCell.x),
      ),
      BorderRngKeyComponent.signedInt64(
        BorderSignedInt64.fromInt(edge.interiorCell.y),
      ),
      BorderRngKeyComponent.text(
        borderCardinalDirectionV1WireName(edge.outwardSide),
      ),
      BorderRngKeyComponent.signedInt64(BorderSignedInt64.fromInt(passIndex)),
      BorderRngKeyComponent.text(borderPrimitiveRoleV1WireName(role)),
      BorderRngKeyComponent.signedInt64(BorderSignedInt64.fromInt(rank)),
      BorderRngKeyComponent.signedInt64(
        BorderSignedInt64.fromInt(ordinalLocal),
      ),
      BorderRngKeyComponent.text(decision),
      BorderRngKeyComponent.signedInt64(request.feature.seed),
    ]);

bool _passesPermille(BorderDeterministicRng rng, int permille) =>
    permille >= 1000 || (permille > 0 && rng.nextIndex(1000) < permille);

int _signedJitter(BorderDeterministicRng rng, int maximum) =>
    maximum == 0 ? 0 : rng.nextIndex(maximum * 2 + 1) - maximum;

bool _edgeIsKeptOut(
  BorderRegionContourEdge edge,
  List<bool> keepOutMask,
  int mapWidth,
) =>
    keepOutMask[edge.interiorCell.y * mapWidth + edge.interiorCell.x];

(int, int) _directionVector(BorderCardinalDirection direction) =>
    switch (direction) {
      BorderCardinalDirection.east => (1, 0),
      BorderCardinalDirection.south => (0, 1),
      BorderCardinalDirection.west => (-1, 0),
      BorderCardinalDirection.north => (0, -1),
    };

(int, int) _oppositeDirectionVector(BorderCardinalDirection direction) {
  final vector = _directionVector(direction);
  return (-vector.$1, -vector.$2);
}

BorderResolutionResult _failed(Iterable<BorderDiagnostic> diagnostics) =>
    BorderResolutionResult(
      materialization: null,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    );

BorderDiagnostic _error(
  BorderResolutionRequest request, {
  required String code,
  required BorderDiagnosticScope scope,
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
      cell: cell,
      parameters: parameters,
      suggestedAction: action,
    );

BorderDiagnostic _warning(
  BorderResolutionRequest request, {
  required String code,
  required BorderDiagnosticScope scope,
  Map<String, Object?> parameters = const <String, Object?>{},
  required String action,
}) =>
    BorderDiagnostic(
      code: code,
      severity: BorderDiagnosticSeverity.warning,
      phase: BorderDiagnosticPhase.resolution,
      scope: scope,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      parameters: parameters,
      suggestedAction: action,
    );

final class _GeneratedPlacement {
  const _GeneratedPlacement({
    required this.contourIndex,
    required this.edge,
    required this.primitive,
    required this.placement,
    required this.eligiblePrimitiveCount,
    required this.continuitySiteIndex,
  });

  final int contourIndex;
  final BorderRegionContourEdge edge;
  final BorderPublishedPrimitive primitive;
  final BorderResolvedPlacement placement;
  final int eligiblePrimitiveCount;
  final int? continuitySiteIndex;
}

final class _LocallyEligiblePrimitive {
  const _LocallyEligiblePrimitive({
    required this.primitive,
    required this.transform,
    required this.sprite,
  });

  final BorderPublishedPrimitive primitive;
  final BorderSpriteTransform transform;
  final BorderResolvedSpriteGeometry sprite;
}

final class _DecorativePass {
  const _DecorativePass({
    required this.role,
    required this.drawBand,
    required this.passIndex,
  });

  final BorderPrimitiveRole role;
  final BorderDrawBand drawBand;
  final int passIndex;
}
