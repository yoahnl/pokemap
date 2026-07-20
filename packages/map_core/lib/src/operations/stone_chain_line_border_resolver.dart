import 'dart:collection';

import 'package:meta/meta.dart' show immutable;

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
import 'border_deterministic_rng.dart';
import 'border_fingerprints.dart';
import 'border_linear_lattice.dart';
import 'border_local_resolution_scope.dart';
import 'border_override_resolution.dart';
import 'border_rle_codec.dart';
import 'border_slot_keys.dart';
import 'border_sprite_geometry.dart';
import 'border_stroke_canonicalization.dart';
import 'stone_chain_contact_metrics.dart';

const Set<BorderPrimitiveRole> _stoneChainRoles = <BorderPrimitiveRole>{
  BorderPrimitiveRole.structureLarge,
  BorderPrimitiveRole.structureMedium,
  BorderPrimitiveRole.filler,
  BorderPrimitiveRole.lineCorner,
  BorderPrimitiveRole.lineCap,
};
const int _maximumSparseDetailDensityPermille = 600;
const int _minimumTwoTierCrossRowInterlockPixels = 8;
const int _maximumTwoTierPlannedNativeVariantsPerNeed = 4;
// The planner samples four native textures per station and at most one rotated
// fallback. At the supported nine-pixel overlap range this caps the transition
// domain at 5 * 19 = 95 candidates while a longer stroke can still use every
// authored texture as its deterministic station subset changes.
const int _maximumTwoTierPlannerCandidatesPerNeed = 95;
const int _maximumTwoTierPlannerTransitionPairsPerNeed =
    _maximumTwoTierPlannerCandidatesPerNeed *
        _maximumTwoTierPlannerCandidatesPerNeed;
const int _maximumPortableJsonInteger = 9007199254740991;
const int _minimumPortableJsonInteger = -9007199254740991;
const int _twoTierRecentPrimitiveMemory = 11;

/// Measurable trace used by publication checks and visual QA.
@immutable
final class StoneChainLineBorderResolutionEvidence {
  const StoneChainLineBorderResolutionEvidence({
    required this.result,
    required this.primaryPlacementCount,
    required this.secondaryPlacementCount,
    required this.maximumGapPx,
    required this.maximumTangentOverlapPx,
    required this.maximumCornerThicknessRatioPermille,
    required this.maximumRepeatedPrimitiveRunLength,
    required this.placementsPerSegmentPermille,
  });

  final BorderResolutionResult result;
  final int primaryPlacementCount;
  final int secondaryPlacementCount;
  final int maximumGapPx;
  final int maximumTangentOverlapPx;
  final int maximumCornerThicknessRatioPermille;
  final int maximumRepeatedPrimitiveRunLength;
  final int placementsPerSegmentPermille;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoneChainLineBorderResolutionEvidence &&
          result == other.result &&
          primaryPlacementCount == other.primaryPlacementCount &&
          secondaryPlacementCount == other.secondaryPlacementCount &&
          maximumGapPx == other.maximumGapPx &&
          maximumTangentOverlapPx == other.maximumTangentOverlapPx &&
          maximumCornerThicknessRatioPermille ==
              other.maximumCornerThicknessRatioPermille &&
          maximumRepeatedPrimitiveRunLength ==
              other.maximumRepeatedPrimitiveRunLength &&
          placementsPerSegmentPermille == other.placementsPerSegmentPermille;

  @override
  int get hashCode => Object.hash(
        result,
        primaryPlacementCount,
        secondaryPlacementCount,
        maximumGapPx,
        maximumTangentOverlapPx,
        maximumCornerThicknessRatioPermille,
        maximumRepeatedPrimitiveRunLength,
        placementsPerSegmentPermille,
      );
}

BorderResolutionResult resolveStoneChainLineBorder(
  BorderResolutionRequest request,
) =>
    resolveStoneChainLineBorderWithEvidence(request).result;

StoneChainLineBorderResolutionEvidence resolveStoneChainLineBorderWithEvidence(
  BorderResolutionRequest request, {
  BorderLocalResolutionScope? localScope,
  BorderLocalResolutionCapture? localCapture,
}) =>
    _resolveStoneChainLineBorderWithEvidence(
      request,
      localScope: localScope,
      localCapture: localCapture,
    );

StoneChainLineBorderResolutionEvidence _resolveStoneChainLineBorderWithEvidence(
  BorderResolutionRequest request, {
  BorderLocalResolutionScope? localScope,
  BorderLocalResolutionCapture? localCapture,
}) {
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
  final parameters = request.feature.paramsOverride ?? definition.defaults;
  if (definition.template != BorderBlueprintTemplate.stoneChainLine) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.template_mismatch',
        scope: BorderDiagnosticScope.blueprint,
        action: 'border.action.select_stone_chain_blueprint',
      ),
    );
  }
  final geometry = request.feature.geometry;
  if (geometry is! BorderStrokeGeometry ||
      geometry.alignment != BorderStrokeAlignment.gridEdges) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.grid_edge_geometry_required',
        scope: BorderDiagnosticScope.geometry,
        action: 'border.action.draw_grid_edge_stroke',
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
  if (parameters.depthRows != 1 && parameters.depthRows != 2) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.stone_chain_depth_rows_invalid',
        scope: BorderDiagnosticScope.blueprint,
        action: 'border.action.use_one_or_two_depth_rows',
      ),
    );
  }

  final primitives = definition.primitives.toList(growable: false)
    ..sort((left, right) => left.id.compareTo(right.id));
  _diagnosePublishedInputs(
    request,
    primitives: primitives,
    diagnostics: diagnostics,
  );
  final primaryPrimitives = primitives
      .where(
        (primitive) =>
            primitive.role == BorderPrimitiveRole.structureLarge &&
            primitive.weight > 0,
      )
      .toList(growable: false);
  if (primaryPrimitives.isEmpty) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.stone_chain_primary_role_missing',
        scope: BorderDiagnosticScope.blueprint,
        action: 'border.action.assign_stone_chain_primary',
      ),
    );
  }
  final usesStrictTwoTierTopology =
      parameters.depthRows >= 2 && _supportsStrictTwoTierTopology(primitives);
  final structuralPrimitives = primitives
      .where(
        (primitive) =>
            primitive.weight > 0 &&
            (primitive.role == BorderPrimitiveRole.structureLarge ||
                primitive.role == BorderPrimitiveRole.structureMedium),
      )
      .toList(growable: false);
  final hasCardinalStructuralPrimitive = structuralPrimitives.any(
    (primitive) =>
        primitive.authoredOrientation != BorderPrimitiveOrientation.legacyAxis,
  );
  final hasPositiveCardinalPrimitive = primitives.any(
    (primitive) =>
        primitive.weight > 0 &&
        primitive.authoredOrientation != BorderPrimitiveOrientation.legacyAxis,
  );
  if (parameters.depthRows == 1 && hasPositiveCardinalPrimitive) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.stone_chain_cardinal_depth_one_unsupported',
        scope: BorderDiagnosticScope.blueprint,
        action: 'border.action.use_two_stone_chain_depth_rows',
      ),
    );
  }
  final requestsCardinalTwoTierTopology =
      parameters.depthRows >= 2 && hasCardinalStructuralPrimitive;
  if (requestsCardinalTwoTierTopology && !usesStrictTwoTierTopology) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.stone_chain_two_tier_catalog_incomplete',
        scope: BorderDiagnosticScope.blueprint,
        parameters: <String, Object?>{
          'hasLipRole': structuralPrimitives.any(
            (primitive) => primitive.role == BorderPrimitiveRole.structureLarge,
          ),
          'hasFaceRole': structuralPrimitives.any(
            (primitive) =>
                primitive.role == BorderPrimitiveRole.structureMedium,
          ),
          'hasLegacyOrientation': structuralPrimitives.any(
            (primitive) =>
                primitive.authoredOrientation ==
                BorderPrimitiveOrientation.legacyAxis,
          ),
          'hasCardinalOrientation': true,
        },
        action: 'border.action.complete_stone_chain_two_tier_catalog',
      ),
    );
  }

  final paths = <_StonePath>[];
  for (final stroke in geometry.strokes) {
    final outside = stroke.points.where(
      (point) =>
          point.x < 0 ||
          point.y < 0 ||
          point.x > request.mapSize.width ||
          point.y > request.mapSize.height,
    );
    if (outside.isNotEmpty) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.stroke_out_of_bounds',
          scope: BorderDiagnosticScope.stroke,
          strokeId: borderStrokeAuthoredIdV1(stroke.id),
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
      final lineage = resolveBorderStrokeLineageIdentityV1(stroke);
      if (!usesStrictTwoTierTopology &&
          !lineage.preserveTraversal &&
          !_sameStroke(stroke, canonical)) {
        diagnostics.add(
          _error(
            request,
            code: 'border.resolution.stroke_not_canonical',
            scope: BorderDiagnosticScope.stroke,
            strokeId: lineage.authoredStrokeId,
            action: 'border.action.redraw_canonical_stroke',
          ),
        );
        continue;
      }
      paths.add(
        _StonePath.fromStroke(
          usesStrictTwoTierTopology && !lineage.preserveTraversal
              ? canonical
              : stroke,
          request.tileSizePx,
        ),
      );
    } on ValidationException {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.stroke_invalid',
          scope: BorderDiagnosticScope.stroke,
          strokeId: borderStrokeAuthoredIdV1(stroke.id),
          action: 'border.action.redraw_valid_stroke',
        ),
      );
    }
  }
  paths.sort((left, right) {
    final byLineage = left.lineageId.compareTo(right.lineageId);
    if (byLineage != 0) return byLineage;
    final byOffset = left.sourceEdgeOffset.compareTo(right.sourceEdgeOffset);
    return byOffset != 0 ? byOffset : left.strokeId.compareTo(right.strokeId);
  });
  if (_hasErrors(diagnostics)) return _failure(diagnostics);
  final primitiveCatalog = _StonePrimitiveCatalog(primitives);

  // Resolver V3 keeps the V2 one-row algorithm intact, including its slot and
  // output golden. The Task 5 straight two-row path also stays byte-stable;
  // only non-straight strict publications enter the Task 6 run/junction plan.
  if (usesStrictTwoTierTopology) {
    if (!_preflightStrictTwoTierPlannerBudget(
      request: request,
      parameters: parameters,
      primitives: primitives,
      diagnostics: diagnostics,
    )) {
      return _failure(diagnostics);
    }
    if (paths.every(_isStraightStonePath)) {
      return _resolveTwoTierStraightRows(
        request: request,
        revision: revision,
        parameters: parameters,
        primitives: primitives,
        paths: paths,
        diagnostics: diagnostics,
        localScope: localScope,
        localCapture: localCapture,
      );
    }
    if (!_preflightStrictTwoTierPlannerCandidateBudget(
      request: request,
      parameters: parameters,
      primitives: primitives,
      diagnostics: diagnostics,
    )) {
      return _failure(diagnostics);
    }
    return _resolveTwoTierTopologyRows(
      request: request,
      revision: revision,
      parameters: parameters,
      primitives: primitives,
      paths: paths,
      diagnostics: diagnostics,
      localScope: localScope,
      localCapture: localCapture,
    );
  }

  final densityFloor = _maximum(
    1,
    _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 2,
  );
  final horizontalStationQuantum = _stoneChainStationQuantum(
    primitives: primaryPrimitives,
    tangentX: 1,
    allowAutoRotation: parameters.allowAutoRotation,
    densityFloor: densityFloor,
    maximumOverlapPx: parameters.maxOverlapPx,
    gapTolerancePx: parameters.gapTolerancePx,
  );
  final verticalStationQuantum = _stoneChainStationQuantum(
    primitives: primaryPrimitives,
    tangentX: 0,
    allowAutoRotation: parameters.allowAutoRotation,
    densityFloor: densityFloor,
    maximumOverlapPx: parameters.maxOverlapPx,
    gapTolerancePx: parameters.gapTolerancePx,
  );
  final normalOffset = _maximum(
    1,
    _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 8,
  );
  final cornerNeeds = <_PlacementNeed>[];
  final capNeeds = <_PlacementNeed>[];
  final straightNeedsByStrokeId = <String, List<_PlacementNeed>>{};
  var edgeCount = 0;
  var latticeStationCount = 0;
  for (final path in paths) {
    edgeCount += path.edges.length;
    for (final need in _specialNeeds(
      request: request,
      path: path,
      normalOffset: normalOffset,
    )) {
      if (need.semanticRole == BorderPrimitiveRole.lineCap) {
        capNeeds.add(need);
      } else {
        cornerNeeds.add(need);
      }
    }
  }
  cornerNeeds.sort(_compareNeeds);
  capNeeds.sort(_compareNeeds);
  final cornerDistancesByPath = <String, List<int>>{};
  for (final corner in cornerNeeds) {
    cornerDistancesByPath
        .putIfAbsent(corner.path.strokeId, () => <int>[])
        .add(corner.distance);
  }
  final specialDistancesByPath = <String, List<int>>{};
  for (final special in <_PlacementNeed>[...cornerNeeds, ...capNeeds]) {
    specialDistancesByPath
        .putIfAbsent(special.path.strokeId, () => <int>[])
        .add(special.distance);
  }
  for (final distances in specialDistancesByPath.values) {
    distances.sort();
  }

  final generated = <_GeneratedStonePlacement>[];
  var collisionIndex = _StoneCollisionIndex(
    bucketSizePx: _maximum(request.tileSizePx.width, request.tileSizePx.height),
  );
  final hasTurnConnectors = primitives.any(
    (primitive) =>
        primitive.role == BorderPrimitiveRole.structureMedium &&
        primitive.weight > 0,
  );
  final previousShortCornerBySlot = <String, _PlacementNeed>{};
  final nextShortCornerBySlot = <String, _PlacementNeed>{};
  final cornersByStroke = <String, List<_PlacementNeed>>{};
  for (final corner in cornerNeeds) {
    cornersByStroke
        .putIfAbsent(corner.path.strokeId, () => <_PlacementNeed>[])
        .add(corner);
  }
  bool sharesOneGridEdge(_PlacementNeed left, _PlacementNeed right) {
    final leftVertex = left.path.points[left.stationOrdinal];
    final rightVertex = right.path.points[right.stationOrdinal];
    return (leftVertex.x - rightVertex.x).abs() +
            (leftVertex.y - rightVertex.y).abs() ==
        1;
  }

  for (final corners in cornersByStroke.values) {
    corners.sort(_compareNeeds);
    for (var index = 0; index < corners.length; index += 1) {
      final current = corners[index];
      if (index > 0 || current.path.closed) {
        final previous = corners[(index - 1 + corners.length) % corners.length];
        if (sharesOneGridEdge(previous, current)) {
          previousShortCornerBySlot[current.slotKey] = previous;
        }
      }
      if (index + 1 < corners.length || current.path.closed) {
        final next = corners[(index + 1) % corners.length];
        if (sharesOneGridEdge(current, next)) {
          nextShortCornerBySlot[current.slotKey] = next;
        }
      }
    }
  }
  final cornerPlacementsBySlot = <String, _GeneratedStonePlacement>{};
  for (final need in cornerNeeds) {
    final placement = _generatePlacement(
      request: request,
      revision: revision,
      need: need,
      primitiveCatalog: primitiveCatalog,
      variationPermille: parameters.variationPermille,
      collisionIndex: collisionIndex,
      maximumOverlapPx: parameters.maxOverlapPx,
      diagnostics: diagnostics,
    );
    if (placement != null) {
      generated.add(placement);
      collisionIndex.add(placement);
      cornerPlacementsBySlot[need.slotKey] = placement;
    } else {
      diagnostics.add(_requiredNodeUnresolvedDiagnostic(request, need));
    }
  }
  if (_hasErrors(diagnostics)) return _failure(diagnostics);

  if (hasTurnConnectors) {
    for (final cornerNeed in cornerNeeds) {
      final corner = cornerPlacementsBySlot[cornerNeed.slotKey];
      if (corner == null) continue;
      final previousShortCorner = previousShortCornerBySlot[cornerNeed.slotKey];
      final nextShortCorner = nextShortCornerBySlot[cornerNeed.slotKey];
      final nextShortCornerPlacement = nextShortCorner == null
          ? null
          : cornerPlacementsBySlot[nextShortCorner.slotKey];
      final previousPrimary = _latestPrimaryBefore(
        generated,
        strokeId: corner.strokeId,
        pathDistance: corner.pathDistance,
      );
      final nearbyPreviousPrimary = previousPrimary != null &&
              corner.pathDistance - previousPrimary.pathDistance <=
                  _maximum(
                    request.tileSizePx.width,
                    request.tileSizePx.height,
                  )
          ? previousPrimary
          : null;
      // A one-cell leg between two turns has room for one connector recipe,
      // not one connector owned by each corner. The preceding corner owns the
      // shared stone; the following corner omits its incoming sibling. This
      // keeps cardinal grid geometry without rendering a three-branch T/L knot.
      final incomingCandidates = previousShortCorner == null
          ? _turnConnectorCandidates(
              request: request,
              revision: revision,
              cornerNeed: cornerNeed,
              corner: corner,
              incoming: true,
              normalOffset: normalOffset,
              primitiveCatalog: primitiveCatalog,
              variationPermille: parameters.variationPermille,
              collisionIndex: collisionIndex,
              maximumOverlapPx: parameters.maxOverlapPx,
              gapTolerancePx: parameters.gapTolerancePx,
              diagnostics: diagnostics,
              adjacentPrimary: nearbyPreviousPrimary,
              avoidedPrimitiveId: nearbyPreviousPrimary?.placement.primitiveId,
            )
          : const <_GeneratedStonePlacement>[];
      final incomingPrimitiveToAvoid = incomingCandidates.isEmpty
          ? null
          : incomingCandidates.first.placement.primitiveId;
      final outgoingCandidates = _turnConnectorCandidates(
        request: request,
        revision: revision,
        cornerNeed: cornerNeed,
        corner: corner,
        incoming: false,
        normalOffset: normalOffset,
        primitiveCatalog: primitiveCatalog,
        variationPermille: parameters.variationPermille,
        collisionIndex: collisionIndex,
        maximumOverlapPx: parameters.maxOverlapPx,
        gapTolerancePx: parameters.gapTolerancePx,
        diagnostics: diagnostics,
        adjacentPrimary: nextShortCornerPlacement,
        avoidedPrimitiveId: incomingPrimitiveToAvoid,
      );
      List<_GeneratedStonePlacement>? selectedConnectors;
      if (incomingCandidates.isEmpty) {
        if (outgoingCandidates.isNotEmpty) {
          selectedConnectors = <_GeneratedStonePlacement>[
            outgoingCandidates.first,
          ];
        }
      } else if (outgoingCandidates.isEmpty) {
        selectedConnectors = <_GeneratedStonePlacement>[
          incomingCandidates.first,
        ];
      } else {
        selectedConnectors = _firstCompatibleTurnConnectorPair(
          incomingCandidates,
          outgoingCandidates,
          maximumOverlapPx: parameters.maxOverlapPx,
        );
        if (selectedConnectors == null && nextShortCorner != null) {
          // The shared short leg has precedence over the optional connector on
          // the free incoming leg. Keeping the outgoing alone preserves the
          // single-owner recipe and lets the straight lattice cover upstream.
          selectedConnectors = <_GeneratedStonePlacement>[
            outgoingCandidates.first,
          ];
        }
      }
      if (selectedConnectors != null) {
        for (final connector in selectedConnectors) {
          generated.add(connector);
          collisionIndex.add(connector);
        }
      }
    }
  }

  for (final capNeed in capNeeds) {
    final placement = _fitReservedCap(
      request: request,
      revision: revision,
      capNeed: capNeed,
      primitiveCatalog: primitiveCatalog,
      variationPermille: parameters.variationPermille,
      collisionIndex: collisionIndex,
      maximumOverlapPx: parameters.maxOverlapPx,
      diagnostics: diagnostics,
    );
    if (placement != null) {
      generated.add(placement);
      collisionIndex.add(placement);
    } else {
      diagnostics.add(_requiredNodeUnresolvedDiagnostic(request, capNeed));
    }
  }
  if (_hasErrors(diagnostics)) return _failure(diagnostics);

  final generatedByStrokeId = <String, List<_GeneratedStonePlacement>>{};
  for (final placement in generated) {
    generatedByStrokeId
        .putIfAbsent(placement.strokeId, () => <_GeneratedStonePlacement>[])
        .add(placement);
  }
  for (final path in paths) {
    final specials = (generatedByStrokeId[path.strokeId] ??
            <_GeneratedStonePlacement>[])
        .toList(growable: true)
      ..sort(_compareGenerated);
    if (path.closed && specials.isNotEmpty) {
      final firstDistance = specials.first.pathDistance;
      final wrappedStart = specials
          .where((placement) => placement.pathDistance == firstDistance)
          .map(
            (placement) => placement.withPathDistance(
              placement.pathDistance + path.totalLengthPx,
            ),
          )
          .toList(growable: false);
      specials
        ..addAll(wrappedStart)
        ..sort(_compareGenerated);
    }
    final previousPlacementTracker = _PreviousPlacementTracker(
      specials,
    );
    final straightRunTracker = _StraightRunTracker();
    final stations = path.latticeStations(
      horizontalQuantumPx: horizontalStationQuantum,
      verticalQuantumPx: verticalStationQuantum,
      maximumOverlapPx: parameters.maxOverlapPx,
    );
    latticeStationCount += stations.length;
    for (var ordinal = 0; ordinal < stations.length; ordinal += 1) {
      final station = stations[ordinal];
      final distance = station.distance;
      final sample = station.sample;
      final need = _stationNeed(
        request: request,
        path: path,
        sample: sample,
        distance: distance,
        ordinal: ordinal,
        role: BorderPrimitiveRole.structureLarge,
        passIndex: 0,
        normalOffset: normalOffset,
      );
      final previous = previousPlacementTracker.latestBefore(distance);
      final nextSpecial = previousPlacementTracker.nextAtOrAfter(distance);
      straightRunTracker.observeBoundary(previous, need);
      final boundaryNext = nextSpecial != null &&
              nextSpecial.pathDistance - need.distance <= densityFloor
          ? nextSpecial
          : null;
      if (previous != null &&
          nextSpecial != null &&
          _opaqueRectGap(
                previous.placement.opaqueWorldBoundsPx,
                nextSpecial.placement.opaqueWorldBoundsPx,
              ) <=
              parameters.gapTolerancePx) {
        continue;
      }
      final avoidedPrimitiveId = straightRunTracker.primitiveToAvoid(need);
      final reservesSpecialNode = _isNearTurn(
        need,
        specialDistancesByPath[path.strokeId] ?? const <int>[],
        radiusPx: densityFloor * 3,
      );
      final tangentJitter = reservesSpecialNode
          ? 0
          : _deterministicTangentJitter(
              request: request,
              revision: revision,
              need: need,
              irregularityPermille: parameters.irregularityPermille,
            );
      var resolvedNeed = tangentJitter == 0
          ? need
          : need.shiftAlongTangent(
              request: request,
              delta: tangentJitter,
            );
      final jitterDiagnostics =
          tangentJitter == 0 ? diagnostics : <BorderDiagnostic>[];
      var placement = _generatePlacement(
        request: request,
        revision: revision,
        need: resolvedNeed,
        primitiveCatalog: primitiveCatalog,
        variationPermille: parameters.variationPermille,
        collisionIndex: collisionIndex,
        maximumOverlapPx: parameters.maxOverlapPx,
        diagnostics: jitterDiagnostics,
        avoidedPrimitiveId: avoidedPrimitiveId,
        previousPrimary: previous,
        nextPrimary: boundaryNext,
        maximumGapPx: parameters.gapTolerancePx,
      );
      if (placement == null && tangentJitter != 0) {
        resolvedNeed = need;
        placement = _generatePlacement(
          request: request,
          revision: revision,
          need: need,
          primitiveCatalog: primitiveCatalog,
          variationPermille: parameters.variationPermille,
          collisionIndex: collisionIndex,
          maximumOverlapPx: parameters.maxOverlapPx,
          diagnostics: diagnostics,
          avoidedPrimitiveId: avoidedPrimitiveId,
          previousPrimary: previous,
          nextPrimary: boundaryNext,
          maximumGapPx: parameters.gapTolerancePx,
        );
      }
      if (placement != null && previous != null) {
        var gap = _opaqueRectGap(
          previous.placement.opaqueWorldBoundsPx,
          placement.placement.opaqueWorldBoundsPx,
        );
        if (gap > parameters.gapTolerancePx) {
          final spanningPlacement = _generatePlacement(
            request: request,
            revision: revision,
            need: need,
            primitiveCatalog: primitiveCatalog,
            variationPermille: parameters.variationPermille,
            collisionIndex: collisionIndex,
            maximumOverlapPx: parameters.maxOverlapPx,
            diagnostics: diagnostics,
            avoidedPrimitiveId: avoidedPrimitiveId,
            preferLongestTangent: true,
            previousPrimary: previous,
            nextPrimary: boundaryNext,
            maximumGapPx: parameters.gapTolerancePx,
          );
          if (spanningPlacement != null) {
            final spanningGap = _opaqueRectGap(
              previous.placement.opaqueWorldBoundsPx,
              spanningPlacement.placement.opaqueWorldBoundsPx,
            );
            if (spanningGap < gap) {
              placement = spanningPlacement;
              gap = spanningGap;
            }
          }
          if (gap > parameters.gapTolerancePx && previous.isSpecial) {
            resolvedNeed = need.shiftAlongTangent(
              request: request,
              delta: parameters.gapTolerancePx - gap,
            );
            placement = _generatePlacement(
              request: request,
              revision: revision,
              need: resolvedNeed,
              primitiveCatalog: primitiveCatalog,
              variationPermille: parameters.variationPermille,
              collisionIndex: collisionIndex,
              maximumOverlapPx: parameters.maxOverlapPx,
              diagnostics: diagnostics,
              avoidedPrimitiveId: avoidedPrimitiveId,
              preferLongestTangent: true,
              previousPrimary: previous,
              nextPrimary: boundaryNext,
              maximumGapPx: parameters.gapTolerancePx,
            );
          }
          if (placement != null &&
              _opaqueRectGap(
                    previous.placement.opaqueWorldBoundsPx,
                    placement.placement.opaqueWorldBoundsPx,
                  ) >
                  parameters.gapTolerancePx &&
              nextSpecial != null &&
              nextSpecial.pathDistance - need.distance <=
                  _maximum(
                    request.tileSizePx.width,
                    request.tileSizePx.height,
                  )) {
            final fitted = _fitLatticeStationNearNeed(
              request: request,
              revision: revision,
              need: need,
              previous: previous,
              next: nextSpecial,
              searchRadiusPx: densityFloor,
              primitiveCatalog: primitiveCatalog,
              variationPermille: parameters.variationPermille,
              collisionIndex: collisionIndex,
              maximumOverlapPx: parameters.maxOverlapPx,
              gapTolerancePx: parameters.gapTolerancePx,
              diagnostics: diagnostics,
              avoidedPrimitiveId: avoidedPrimitiveId,
            );
            if (fitted != null) {
              resolvedNeed = fitted.need;
              placement = fitted.placement;
            }
          }
        }
      }
      if (placement == null && previous != null) {
        final fitted = _fitLatticeStationNearNeed(
          request: request,
          revision: revision,
          need: need,
          previous: previous,
          next: boundaryNext,
          searchRadiusPx: densityFloor,
          primitiveCatalog: primitiveCatalog,
          variationPermille: parameters.variationPermille,
          collisionIndex: collisionIndex,
          maximumOverlapPx: parameters.maxOverlapPx,
          gapTolerancePx: parameters.gapTolerancePx,
          diagnostics: diagnostics,
          avoidedPrimitiveId: avoidedPrimitiveId,
        );
        if (fitted != null) {
          resolvedNeed = fitted.need;
          placement = fitted.placement;
        }
      }
      if (placement == null &&
          previous != null &&
          boundaryNext != null &&
          _opaqueRectGap(
                previous.placement.opaqueWorldBoundsPx,
                boundaryNext.placement.opaqueWorldBoundsPx,
              ) >
              parameters.gapTolerancePx) {
        final bridge = _fitStraightBoundaryPlacement(
          request: request,
          revision: revision,
          path: path,
          previous: previous,
          next: boundaryNext,
          ordinal: ordinal,
          normalOffset: normalOffset,
          primitiveCatalog: primitiveCatalog,
          variationPermille: parameters.variationPermille,
          collisionIndex: collisionIndex,
          maximumOverlapPx: parameters.maxOverlapPx,
          gapTolerancePx: parameters.gapTolerancePx,
          diagnostics: diagnostics,
        );
        if (bridge != null) {
          resolvedNeed = bridge.need;
          placement = bridge.placement;
        }
      }
      if (placement != null && previous != null && nextSpecial != null) {
        var gapToNext = _opaqueRectGap(
          placement.placement.opaqueWorldBoundsPx,
          nextSpecial.placement.opaqueWorldBoundsPx,
        );
        final nearNextSpecial =
            nextSpecial.pathDistance - resolvedNeed.distance <= densityFloor;
        if (gapToNext > parameters.gapTolerancePx && nearNextSpecial) {
          final spanningPlacement = _generatePlacement(
            request: request,
            revision: revision,
            need: resolvedNeed,
            primitiveCatalog: primitiveCatalog,
            variationPermille: parameters.variationPermille,
            collisionIndex: collisionIndex,
            maximumOverlapPx: parameters.maxOverlapPx,
            diagnostics: diagnostics,
            avoidedPrimitiveId: avoidedPrimitiveId,
            preferLongestTangent: true,
            previousPrimary: previous,
            nextPrimary: nextSpecial,
            maximumGapPx: parameters.gapTolerancePx,
          );
          if (spanningPlacement != null &&
              _opaqueRectGap(
                    previous.placement.opaqueWorldBoundsPx,
                    spanningPlacement.placement.opaqueWorldBoundsPx,
                  ) <=
                  parameters.gapTolerancePx) {
            final spanningGapToNext = _opaqueRectGap(
              spanningPlacement.placement.opaqueWorldBoundsPx,
              nextSpecial.placement.opaqueWorldBoundsPx,
            );
            if (spanningGapToNext < gapToNext) {
              placement = spanningPlacement;
              gapToNext = spanningGapToNext;
            }
          }
        }
        if (gapToNext > parameters.gapTolerancePx && nearNextSpecial) {
          final maximumShift = gapToNext - parameters.gapTolerancePx;
          for (var shift = 0; shift <= maximumShift; shift += 1) {
            final shiftedNeed = resolvedNeed.shiftAlongTangent(
              request: request,
              delta: shift,
            );
            final shiftedPlacement = _generatePlacement(
              request: request,
              revision: revision,
              need: shiftedNeed,
              primitiveCatalog: primitiveCatalog,
              variationPermille: parameters.variationPermille,
              collisionIndex: collisionIndex,
              maximumOverlapPx: parameters.maxOverlapPx,
              diagnostics: diagnostics,
              avoidedPrimitiveId: avoidedPrimitiveId,
              preferLongestTangent: true,
              previousPrimary: previous,
              nextPrimary: nextSpecial,
              maximumGapPx: parameters.gapTolerancePx,
            );
            if (shiftedPlacement != null &&
                _opaqueRectGap(
                      previous.placement.opaqueWorldBoundsPx,
                      shiftedPlacement.placement.opaqueWorldBoundsPx,
                    ) <=
                    parameters.gapTolerancePx &&
                _opaqueRectGap(
                      shiftedPlacement.placement.opaqueWorldBoundsPx,
                      nextSpecial.placement.opaqueWorldBoundsPx,
                    ) <=
                    parameters.gapTolerancePx) {
              resolvedNeed = shiftedNeed;
              placement = shiftedPlacement;
              break;
            }
          }
        }
      }
      if (placement != null) {
        straightNeedsByStrokeId
            .putIfAbsent(path.strokeId, () => <_PlacementNeed>[])
            .add(resolvedNeed);
        generated.add(placement);
        generatedByStrokeId
            .putIfAbsent(path.strokeId, () => <_GeneratedStonePlacement>[])
            .add(placement);
        collisionIndex.add(placement);
        previousPlacementTracker.record(placement);
        straightRunTracker.record(placement);
      }
    }
  }
  for (final needs in straightNeedsByStrokeId.values) {
    needs.sort(_compareNeeds);
  }
  if (_hasErrors(diagnostics)) return _failure(diagnostics);

  final prunedFallbackSlots =
      parameters.depthRows == 2 && parameters.detailDensityPermille > 0
          ? _pruneRedundantPrimaryFillers(
              generated: generated,
              primitives: primitives,
              gapTolerancePx: parameters.gapTolerancePx,
            )
          : const <String>{};
  if (prunedFallbackSlots.isNotEmpty) {
    for (final needs in straightNeedsByStrokeId.values) {
      needs.removeWhere((need) => prunedFallbackSlots.contains(need.slotKey));
    }
    collisionIndex = _StoneCollisionIndex(
      bucketSizePx:
          _maximum(request.tileSizePx.width, request.tileSizePx.height),
    );
    for (final placement in generated) {
      collisionIndex.add(placement);
    }
  }

  final repairedPrimaryContinuity = _repairPrimaryContinuity(
    generated: generated,
    gapTolerancePx: parameters.gapTolerancePx,
    maximumOverlapPx: parameters.maxOverlapPx,
    bucketSizePx: _maximum(request.tileSizePx.width, request.tileSizePx.height),
  );
  if (repairedPrimaryContinuity) {
    collisionIndex = _StoneCollisionIndex(
      bucketSizePx:
          _maximum(request.tileSizePx.width, request.tileSizePx.height),
    );
    for (final placement in generated) {
      collisionIndex.add(placement);
    }
  }

  if (parameters.depthRows == 2 && parameters.detailDensityPermille > 0) {
    final role = primitives.any(
      (primitive) =>
          primitive.role == BorderPrimitiveRole.filler && primitive.weight > 0,
    )
        ? BorderPrimitiveRole.filler
        : BorderPrimitiveRole.structureMedium;
    if (primitives.any(
      (primitive) => primitive.role == role && primitive.weight > 0,
    )) {
      final maximumSecondaryExtent = primitives
          .where(
            (primitive) => primitive.role == role && primitive.weight > 0,
          )
          .map(
            (primitive) => _maximum(
              primitive.publishedMetrics.opaqueBounds.width,
              primitive.publishedMetrics.opaqueBounds.height,
            ),
          )
          .reduce(_maximum);
      // Secondary stones form the visible lower face of the same cliff.
      // Keep only a narrow opaque interlock with the primary lip: a half-
      // extent offset hid almost the entire small stone and reduced the coast
      // to a one-pixel fringe. The attachment search below may still pull a
      // short variant inward, so every accepted detail remains connected
      // while exposing a real second stratum.
      final secondaryNormalOffset = _maximum(
        2,
        maximumSecondaryExtent - 5,
      );
      final secondaryNeeds = <_PlacementNeed>[];
      for (final straightNeeds in straightNeedsByStrokeId.values) {
        for (var index = 0; index + 1 < straightNeeds.length; index += 1) {
          final first = straightNeeds[index];
          final second = straightNeeds[index + 1];
          if (first.tangentX != second.tangentX ||
              first.tangentY != second.tangentY) {
            continue;
          }
          bool continuesInSameDirection(_PlacementNeed candidate) =>
              candidate.tangentX == first.tangentX &&
              candidate.tangentY == first.tangentY &&
              (candidate.distance - first.distance).abs() <=
                  _maximum(
                    request.tileSizePx.width,
                    request.tileSizePx.height,
                  );
          final belongsToLongStraightRun = (index > 0 &&
                  continuesInSameDirection(straightNeeds[index - 1])) ||
              (index + 2 < straightNeeds.length &&
                  continuesInSameDirection(straightNeeds[index + 2]));
          final turnDistances =
              cornerDistancesByPath[first.path.strokeId] ?? const <int>[];
          final baseSecondary = first.asSecondaryBetween(
            request: request,
            next: second,
            role: role,
            extraNormalOffset: secondaryNormalOffset,
          );
          final minimumTileExtent = _minimum(
            request.tileSizePx.width,
            request.tileSizePx.height,
          );
          // Long coasts need a readable second stratum in both orientations.
          // The authored stones are wider than they are tall, so an unrotated
          // vertical chain needs twice the normal offset to expose the same
          // amount of rock. Preserve the original shallow offset within half
          // a tile of a turn: pushing perpendicular strata outwards there can
          // make two otherwise valid detail slots collide. One-cell shelves
          // keep the original offset as well. The attachment fitter still
          // reserves at least two opaque pixels of interlock and the detail-
          // row collision budget remains unchanged.
          final orientationDepthBoost = belongsToLongStraightRun &&
                  !_isNearTurn(
                    baseSecondary,
                    turnDistances,
                    radiusPx: minimumTileExtent ~/ 2,
                  )
              ? _maximum(
                  1,
                  minimumTileExtent ~/ (first.tangentX != 0 ? 16 : 8),
                )
              : 0;
          final secondary = orientationDepthBoost == 0
              ? baseSecondary
              : first.asSecondaryBetween(
                  request: request,
                  next: second,
                  role: role,
                  extraNormalOffset:
                      secondaryNormalOffset + orientationDepthBoost,
                );
          if (_isNearTurn(
            secondary,
            turnDistances,
            // Reserve one quarter-tile around a turn. Half a tile erased the
            // lower face on both legs and produced T/L hooks, while the raw
            // gap tolerance still admitted two dark details directly below a
            // one-cell step. Eight pixels on a 32px grid removes that local
            // knot without flattening the neighbouring straight strata.
            radiusPx: _maximum(
              parameters.gapTolerancePx,
              _minimum(
                    request.tileSizePx.width,
                    request.tileSizePx.height,
                  ) ~/
                  4,
            ),
          )) {
            continue;
          }
          secondaryNeeds.add(secondary);
        }
      }
      // The authored density is defined against every visible primary stone,
      // including caps, corners and their connector stones. Discounting those
      // nodes made turn-rich coasts lose their lower face exactly where the
      // cliff silhouette needs to remain readable.
      final primaryCountBeforeOverrides =
          generated.where((placement) => placement.isPrimary).length;
      final authoredSecondaryCount = primaryCountBeforeOverrides *
          parameters.detailDensityPermille ~/
          1000;
      // Special nodes and turn connectors also consume the visual density
      // budget. Cap the detail row before ranking so a corner-rich stroke
      // cannot become denser merely because its line side fits more nodes.
      // An explicit 100% density request remains the authored diagnostic mode
      // where every eligible interval is intentionally populated.
      final densitySecondaryBudget = _maximum(
        0,
        latticeStationCount +
            (edgeCount * _maximumSparseDetailDensityPermille + 999) ~/ 1000 -
            generated.length,
      );
      final selection = _selectSecondaryDensityCandidates(
        request: request,
        revision: revision,
        candidates: secondaryNeeds,
        desiredCount: parameters.detailDensityPermille == 1000
            ? authoredSecondaryCount
            : _minimum(
                authoredSecondaryCount,
                densitySecondaryBudget,
              ),
      );
      final secondaryCollisionIndex = _StoneCollisionIndex(
        bucketSizePx:
            _maximum(request.tileSizePx.width, request.tileSizePx.height),
      );
      // Density chooses stable authored slots before geometry. A transform may
      // alter which sprite fits a slot, but it must never exchange that slot
      // for a later ranked candidate: overrides depend on the same identity
      // surviving auto-rotation ON/OFF.
      for (final secondary
          in selection.rankedCandidates.take(selection.targetCount)) {
        final placement = _generateAttachedFillerPlacement(
          request: request,
          revision: revision,
          need: secondary,
          primitiveCatalog: primitiveCatalog,
          variationPermille: parameters.variationPermille,
          // A depth detail is expected to overlap the primary lip. Its
          // overlap budget applies against other depth details, while the
          // explicit attachment check below governs the cross-row relation.
          collisionIndex: secondaryCollisionIndex,
          maximumOverlapPx: parameters.maxOverlapPx,
          primaryPlacements: generated,
          maximumAttachmentGapPx: role == BorderPrimitiveRole.structureMedium
              ? 0
              : parameters.gapTolerancePx,
          diagnostics: diagnostics,
        );
        if (placement != null) {
          generated.add(placement);
          collisionIndex.add(placement);
          secondaryCollisionIndex.add(placement);
        }
      }
    }
  }
  if (_hasErrors(diagnostics)) return _failure(diagnostics);

  generated.sort(_compareGenerated);
  final openSeam = _widestClosedSeam(
    generated.where((placement) => placement.isPrimary),
  );
  if (openSeam != null && openSeam.gapPx > parameters.gapTolerancePx) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.stone_chain_closed_seam_gap_exceeded',
        scope: BorderDiagnosticScope.stroke,
        strokeId: openSeam.strokeId,
        parameters: <String, Object?>{
          'gapPx': openSeam.gapPx,
          'gapTolerancePx': parameters.gapTolerancePx,
        },
        action: 'border.action.adjust_stone_chain_seam',
      ),
    );
    return _failure(diagnostics);
  }
  final uncoveredPrimary = _widestObservedGap(
    generated.where((placement) => placement.isPrimary).toList(growable: false),
  );
  if (uncoveredPrimary != null &&
      uncoveredPrimary.gapPx > parameters.gapTolerancePx) {
    final previousGroup = generated
        .where(
          (placement) =>
              placement.isPrimary &&
              placement.strokeId == uncoveredPrimary.strokeId &&
              placement.pathDistance == uncoveredPrimary.previousPathDistancePx,
        )
        .toList(growable: false);
    final nextGroup = generated
        .where(
          (placement) =>
              placement.isPrimary &&
              placement.strokeId == uncoveredPrimary.strokeId &&
              placement.pathDistance == uncoveredPrimary.nextPathDistancePx,
        )
        .toList(growable: false);
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.stone_chain_primary_gap_exceeded',
        scope: BorderDiagnosticScope.stroke,
        strokeId: uncoveredPrimary.strokeId,
        parameters: <String, Object?>{
          'gapPx': uncoveredPrimary.gapPx,
          'gapTolerancePx': parameters.gapTolerancePx,
          'previousPathDistancePx': uncoveredPrimary.previousPathDistancePx,
          'nextPathDistancePx': uncoveredPrimary.nextPathDistancePx,
          'previousPrimitiveIds': previousGroup
              .map((placement) => placement.placement.primitiveId)
              .join(','),
          'nextPrimitiveIds': nextGroup
              .map((placement) => placement.placement.primitiveId)
              .join(','),
          'previousOpaqueBounds': previousGroup
              .map((placement) => placement.placement.opaqueWorldBoundsPx)
              .join(','),
          'nextOpaqueBounds': nextGroup
              .map((placement) => placement.placement.opaqueWorldBoundsPx)
              .join(','),
        },
        action: 'border.action.adjust_stone_chain_spacing',
      ),
    );
    return _failure(diagnostics);
  }
  final previousBaseBySlot = <String, BorderResolvedPlacement>{
    if (localScope != null)
      for (final placement in localScope.previousBasePlacements)
        placement.slotKey: placement,
  };
  final retainedSlotKeys = <String>{};
  final basePlacements = <BorderResolvedPlacement>[];
  for (final entry in generated) {
    final previous = previousBaseBySlot[entry.placement.slotKey];
    if (localScope != null &&
        previous != null &&
        localScope.retainsBasePlacement(previous, request.tileSizePx)) {
      retainedSlotKeys.add(previous.slotKey);
      basePlacements.add(previous);
    } else {
      localScope?.recordRecomputedCell(entry.placement.anchorCell);
      basePlacements.add(entry.placement);
    }
  }
  basePlacements.sort(
    (left, right) => left.stableOrderKey.compareTo(right.stableOrderKey),
  );
  localCapture?.recordBase(
    ground: const <BorderResolvedGroundCell>[],
    placements: basePlacements,
  );
  final overrideResolution = resolveBorderOverrides(
    request: request,
    baseGround: const <BorderResolvedGroundCell>[],
    basePlacements: basePlacements,
    alreadyResolvedSlotKeys: retainedSlotKeys,
    previouslyResolvedPlacementsBySlot:
        localScope?.previousResolvedPlacementsBySlot ??
            const <String, BorderResolvedPlacement>{},
    previouslySuppressedSlotKeys:
        localScope?.previousSuppressedPlacementSlotKeys ?? const <String>{},
  );
  diagnostics.addAll(overrideResolution.diagnostics);
  if (_hasErrors(diagnostics)) return _failure(diagnostics);
  final placements = overrideResolution.placements.toList(growable: false)
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
    return _failure(diagnostics);
  }

  final components = computeBorderInputFingerprints(request);
  final materialization = BorderMaterialization(
    receipt: BorderResolutionReceipt(
      resolverVersion: request.resolverVersion,
      blueprintRevision: revision.revision,
      components: components,
      inputFingerprint: computeBorderAggregateInputFingerprint(
        resolverVersion: request.resolverVersion,
        blueprintRevision: revision.revision,
        components: components,
      ),
      outputFingerprint: computeBorderOutputFingerprint(
        ground: const <BorderResolvedGroundCell>[],
        placements: placements,
      ),
    ),
    ground: const <BorderResolvedGroundCell>[],
    placements: placements,
  );
  final generatedBySlotKey = <String, _GeneratedStonePlacement>{
    for (final value in generated) value.placement.slotKey: value,
  };
  final visibleGenerated = <_GeneratedStonePlacement>[
    for (final placement in placements)
      if (generatedBySlotKey[placement.slotKey] case final generated?)
        generated.withPlacement(placement),
  ]..sort(_compareGenerated);
  final primary = visibleGenerated
      .where((value) => value.isPrimary)
      .toList(growable: false);
  final secondaryCount =
      visibleGenerated.where((value) => !value.isPrimary).length;
  return StoneChainLineBorderResolutionEvidence(
    result: BorderResolutionResult(
      materialization: materialization,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    ),
    primaryPlacementCount: primary.length,
    secondaryPlacementCount: secondaryCount,
    maximumGapPx: _maximumObservedGap(primary),
    maximumTangentOverlapPx: _maximumObservedOverlap(
      visibleGenerated,
      bucketSizePx:
          _maximum(request.tileSizePx.width, request.tileSizePx.height),
    ),
    maximumCornerThicknessRatioPermille: _maximumCornerThicknessRatioPermille(
      primary,
      straightPrimitiveIds: <String>{
        for (final primitive in primitives)
          if (primitive.role == BorderPrimitiveRole.structureLarge)
            primitive.id,
      },
    ),
    maximumRepeatedPrimitiveRunLength: _maximumRepeat(primary),
    placementsPerSegmentPermille:
        edgeCount == 0 ? 0 : primary.length * 1000 ~/ edgeCount,
  );
}

bool _isStraightStonePath(_StonePath path) {
  if (path.edges.isEmpty) return false;
  final first = path.edges.first;
  return path.edges.every(
    (edge) =>
        edge.directionX == first.directionX &&
        edge.directionY == first.directionY,
  );
}

bool _supportsStrictTwoTierTopology(
  List<BorderPublishedPrimitive> primitives,
) {
  final structural = primitives
      .where(
        (primitive) =>
            primitive.weight > 0 &&
            (primitive.role == BorderPrimitiveRole.structureLarge ||
                primitive.role == BorderPrimitiveRole.structureMedium),
      )
      .toList(growable: false);
  // V3 publications require explicit structural orientations. Keeping the
  // legacy-axis catalogues on the V2 topology path is the compatibility seam
  // that protects existing depth-two projects while their assets are migrated.
  return structural.any(
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
}

bool _preflightStrictTwoTierPlannerBudget({
  required BorderResolutionRequest request,
  required BorderGenerationParams parameters,
  required List<BorderPublishedPrimitive> primitives,
  required List<BorderDiagnostic> diagnostics,
}) {
  final minimumStructuralTangentSpanPx = primitives
      .where(
        (primitive) =>
            primitive.weight > 0 &&
            (primitive.role == BorderPrimitiveRole.structureLarge ||
                primitive.role == BorderPrimitiveRole.structureMedium),
      )
      .map(_authoredTangentSpanPx)
      .reduce(_minimum);
  // Small individual stones still need enough shift room to bridge grid
  // quantization at caps and right-angle shoulders. Keep the historical
  // half-span ceiling for larger modules, while allowing the bounded V2
  // profile (at most eight pixels and always two pixels of forward span).
  final maximumSupportedOverlapPx = _maximum(
    _maximum(2, minimumStructuralTangentSpanPx ~/ 2),
    _minimum(8, minimumStructuralTangentSpanPx - 2),
  );
  if (parameters.maxOverlapPx <= maximumSupportedOverlapPx) return true;
  diagnostics.add(
    _error(
      request,
      code: 'border.resolution.stone_chain_planner_budget_exceeded',
      scope: BorderDiagnosticScope.feature,
      parameters: <String, Object?>{
        'observedMaximumOverlapPx': parameters.maxOverlapPx,
        'expectedMaximumOverlapPx': maximumSupportedOverlapPx,
        'minimumStructuralTangentSpanPx': minimumStructuralTangentSpanPx,
      },
      action: 'border.action.reduce_stone_overlap',
    ),
  );
  return false;
}

bool _preflightStrictTwoTierPlannerCandidateBudget({
  required BorderResolutionRequest request,
  required BorderGenerationParams parameters,
  required List<BorderPublishedPrimitive> primitives,
  required List<BorderDiagnostic> diagnostics,
}) {
  final shiftCount = 1 + 2 * parameters.maxOverlapPx;
  for (final role in const <BorderPrimitiveRole>[
    BorderPrimitiveRole.structureLarge,
    BorderPrimitiveRole.structureMedium,
  ]) {
    final rolePrimitives = primitives
        .where(
          (primitive) => primitive.role == role && primitive.weight > 0,
        )
        .toList(growable: false);
    for (final desired in BorderCardinalDirection.values) {
      var nativeCandidateCount = 0;
      var hasRotatableNonNative = false;
      for (final primitive in rolePrimitives) {
        final quarterTurns = _quarterTurnsForOrientation(
          authored: primitive.authoredOrientation,
          desired: desired,
          allowAutoRotation: parameters.allowAutoRotation,
          allowedQuarterTurns: primitive.transforms.allowedQuarterTurns,
        );
        if (quarterTurns == null) continue;
        if (quarterTurns == 0) {
          nativeCandidateCount += 1;
        } else {
          // The strict planner admits at most its single deterministic
          // preferred rotated primitive in addition to every native variant.
          hasRotatableNonNative = true;
        }
      }
      final plannedNativeCandidateCount = _minimum(
        nativeCandidateCount,
        _maximumTwoTierPlannedNativeVariantsPerNeed,
      );
      final orientedCandidateCount =
          plannedNativeCandidateCount + (hasRotatableNonNative ? 1 : 0);
      final candidateCount = shiftCount * orientedCandidateCount;
      if (candidateCount <= _maximumTwoTierPlannerCandidatesPerNeed) {
        continue;
      }
      diagnostics.add(
        _error(
          request,
          code:
              'border.resolution.stone_chain_planner_candidate_budget_exceeded',
          scope: BorderDiagnosticScope.blueprint,
          parameters: <String, Object?>{
            'role': borderPrimitiveRoleV1WireName(role),
            'orientation': borderCardinalDirectionV1WireName(desired),
            'shiftCount': shiftCount,
            'nativeCandidateCount': nativeCandidateCount,
            'plannedNativeCandidateCount': plannedNativeCandidateCount,
            'hasPreferredRotatedCandidate': hasRotatableNonNative,
            'observedCandidateCount': candidateCount,
            'expectedMaximumCandidateCount':
                _maximumTwoTierPlannerCandidatesPerNeed,
            'observedTransitionPairCount': candidateCount * candidateCount,
            'expectedMaximumTransitionPairCount':
                _maximumTwoTierPlannerTransitionPairsPerNeed,
          },
          action: 'border.action.reduce_stone_chain_variants',
        ),
      );
      return false;
    }
  }
  return true;
}

StoneChainLineBorderResolutionEvidence _resolveTwoTierStraightRows({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required BorderGenerationParams parameters,
  required List<BorderPublishedPrimitive> primitives,
  required List<_StonePath> paths,
  required List<BorderDiagnostic> diagnostics,
  required BorderLocalResolutionScope? localScope,
  required BorderLocalResolutionCapture? localCapture,
}) {
  final lipPrimitives = primitives
      .where(
        (primitive) =>
            primitive.role == BorderPrimitiveRole.structureLarge &&
            primitive.weight > 0,
      )
      .toList(growable: false);
  final facePrimitives = primitives
      .where(
        (primitive) =>
            primitive.role == BorderPrimitiveRole.structureMedium &&
            primitive.weight > 0,
      )
      .toList(growable: false);
  final fillerPrimitives = primitives
      .where(
        (primitive) =>
            primitive.role == BorderPrimitiveRole.filler &&
            primitive.weight > 0,
      )
      .toList(growable: false);
  final primitiveById = <String, BorderPublishedPrimitive>{
    for (final primitive in primitives) primitive.id: primitive,
  };
  final primitiveCatalog = _StonePrimitiveCatalog(primitives);
  final targetLipOverlapPx = _twoTierTargetOverlapPx(
    primitives: lipPrimitives,
    maximumOverlapPx: parameters.maxOverlapPx,
  );
  final targetFaceOverlapPx = _twoTierTargetOverlapPx(
    primitives: facePrimitives,
    maximumOverlapPx: parameters.maxOverlapPx,
  );
  final lips = <_GeneratedStonePlacement>[];
  final faces = <_GeneratedStonePlacement>[];
  final fillers = <_GeneratedStonePlacement>[];

  for (final path in paths) {
    // A row index owns one canonical path axis. Reusing it across independent
    // horizontal and vertical strokes would feed a foreign tangent into true
    // mask contact metrics and can make the axes non-perpendicular.
    final lipCollisionIndex = _StoneCollisionIndex(
      bucketSizePx:
          _maximum(request.tileSizePx.width, request.tileSizePx.height),
    );
    final faceCollisionIndex = _StoneCollisionIndex(
      bucketSizePx:
          _maximum(request.tileSizePx.width, request.tileSizePx.height),
    );
    final fillerCollisionIndex = _StoneCollisionIndex(
      bucketSizePx:
          _maximum(request.tileSizePx.width, request.tileSizePx.height),
    );
    final lipNeeds = _buildLipNeeds(
      request: request,
      path: path,
      parameters: parameters,
    );
    final materializedPathLips = _materializeTwoTierRow(
      request: request,
      revision: revision,
      needs: lipNeeds,
      primitives: lipPrimitives,
      targetOverlapPx: targetLipOverlapPx,
      collisionIndex: lipCollisionIndex,
      diagnostics: diagnostics,
      gapCode: 'border.resolution.stone_chain_lip_gap',
    );
    if (materializedPathLips == null) return _failure(diagnostics);
    final pathLips = _withTwoTierStraightEndpointSlots(
      request: request,
      path: path,
      placements: materializedPathLips,
      passIndex: 0,
      role: BorderPrimitiveRole.lineCap,
      rank: 0,
    );
    lips.addAll(pathLips);

    // The face owns a separate distance lattice. Lip joints influence only a
    // tie-break that avoids aligned masonry seams; they never create, remove,
    // or rename a face slot.
    final lipJointCoordinates = _twoTierJointCoordinates(pathLips);
    final faceNeeds = _buildFaceNeeds(
      request: request,
      path: path,
      parameters: parameters,
    );
    final materializedPathFaces = _materializeTwoTierRow(
      request: request,
      revision: revision,
      needs: faceNeeds,
      primitives: facePrimitives,
      targetOverlapPx: targetFaceOverlapPx,
      collisionIndex: faceCollisionIndex,
      diagnostics: diagnostics,
      gapCode: 'border.resolution.stone_chain_face_gap',
      forbiddenJointCoordinates: lipJointCoordinates,
    );
    if (materializedPathFaces == null) return _failure(diagnostics);
    final pathFaces = _withTwoTierStraightEndpointSlots(
      request: request,
      path: path,
      placements: materializedPathFaces,
      passIndex: 1,
      role: BorderPrimitiveRole.structureMedium,
      rank: 2,
    );
    faces.addAll(pathFaces);

    _validateTwoTierStraightPath(
      request: request,
      parameters: parameters,
      path: path,
      lips: pathLips,
      faces: pathFaces,
      primitiveById: primitiveById,
      diagnostics: diagnostics,
    );
    if (_hasErrors(diagnostics)) return _failure(diagnostics);

    final pathFillers = _materializeTwoTierFillers(
      request: request,
      revision: revision,
      parameters: parameters,
      lipNeeds: lipNeeds,
      fillerPrimitives: fillerPrimitives,
      primitiveCatalog: primitiveCatalog,
      structuralPlacements: <_GeneratedStonePlacement>[
        ...pathFaces,
        ...pathLips,
      ],
      collisionIndex: fillerCollisionIndex,
      diagnostics: diagnostics,
    );
    fillers.addAll(pathFillers);
    if (_hasErrors(diagnostics)) return _failure(diagnostics);
  }

  // Cross-row overlap is intentional. The independent indexes above enforce
  // overlap budgets within each row; draw bands establish the only ordering
  // relationship between them, with the deep face painted first.
  final generated = <_GeneratedStonePlacement>[
    ...faces,
    ...lips,
    ...fillers,
  ];
  final previousBaseBySlot = <String, BorderResolvedPlacement>{
    if (localScope != null)
      for (final placement in localScope.previousBasePlacements)
        placement.slotKey: placement,
  };
  final retainedSlotKeys = <String>{};
  final basePlacements = <BorderResolvedPlacement>[];
  for (final entry in generated) {
    final previous = previousBaseBySlot[entry.placement.slotKey];
    if (localScope != null &&
        previous != null &&
        localScope.retainsBasePlacement(previous, request.tileSizePx)) {
      retainedSlotKeys.add(previous.slotKey);
      basePlacements.add(previous);
    } else {
      localScope?.recordRecomputedCell(entry.placement.anchorCell);
      basePlacements.add(entry.placement);
    }
  }
  basePlacements.sort(
    (left, right) => left.stableOrderKey.compareTo(right.stableOrderKey),
  );
  localCapture?.recordBase(
    ground: const <BorderResolvedGroundCell>[],
    placements: basePlacements,
  );
  final overrideResolution = resolveBorderOverrides(
    request: request,
    baseGround: const <BorderResolvedGroundCell>[],
    basePlacements: basePlacements,
    alreadyResolvedSlotKeys: retainedSlotKeys,
    previouslyResolvedPlacementsBySlot:
        localScope?.previousResolvedPlacementsBySlot ??
            const <String, BorderResolvedPlacement>{},
    previouslySuppressedSlotKeys:
        localScope?.previousSuppressedPlacementSlotKeys ?? const <String>{},
  );
  diagnostics.addAll(overrideResolution.diagnostics);
  if (_hasErrors(diagnostics)) return _failure(diagnostics);
  final placements = overrideResolution.placements.toList(growable: false)
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
    return _failure(diagnostics);
  }

  final components = computeBorderInputFingerprints(request);
  final materialization = BorderMaterialization(
    receipt: BorderResolutionReceipt(
      resolverVersion: request.resolverVersion,
      blueprintRevision: revision.revision,
      components: components,
      inputFingerprint: computeBorderAggregateInputFingerprint(
        resolverVersion: request.resolverVersion,
        blueprintRevision: revision.revision,
        components: components,
      ),
      outputFingerprint: computeBorderOutputFingerprint(
        ground: const <BorderResolvedGroundCell>[],
        placements: placements,
      ),
    ),
    ground: const <BorderResolvedGroundCell>[],
    placements: placements,
  );
  final generatedBySlotKey = <String, _GeneratedStonePlacement>{
    for (final placement in generated) placement.placement.slotKey: placement,
  };
  final visibleGenerated = <_GeneratedStonePlacement>[
    for (final placement in placements)
      if (generatedBySlotKey[placement.slotKey] case final generated?)
        generated.withPlacement(placement),
  ];
  final visibleLips = visibleGenerated
      .where((placement) => placement.isPrimary)
      .toList(growable: false);
  final edgeCount = paths.fold<int>(
    0,
    (count, path) => count + path.edges.length,
  );
  return StoneChainLineBorderResolutionEvidence(
    result: BorderResolutionResult(
      materialization: materialization,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    ),
    primaryPlacementCount: visibleLips.length,
    secondaryPlacementCount:
        visibleGenerated.where((placement) => !placement.isPrimary).length,
    maximumGapPx: _maximumObservedGap(visibleLips),
    maximumTangentOverlapPx: _maximumObservedOverlap(
      visibleGenerated,
      bucketSizePx:
          _maximum(request.tileSizePx.width, request.tileSizePx.height),
    ),
    maximumCornerThicknessRatioPermille: 0,
    maximumRepeatedPrimitiveRunLength: _maximumRepeat(visibleLips),
    placementsPerSegmentPermille:
        edgeCount == 0 ? 0 : visibleLips.length * 1000 ~/ edgeCount,
  );
}

StoneChainLineBorderResolutionEvidence _resolveTwoTierTopologyRows({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required BorderGenerationParams parameters,
  required List<BorderPublishedPrimitive> primitives,
  required List<_StonePath> paths,
  required List<BorderDiagnostic> diagnostics,
  required BorderLocalResolutionScope? localScope,
  required BorderLocalResolutionCapture? localCapture,
}) {
  final lipPrimitives = primitives
      .where(
        (primitive) =>
            primitive.role == BorderPrimitiveRole.structureLarge &&
            primitive.weight > 0,
      )
      .toList(growable: false);
  final facePrimitives = primitives
      .where(
        (primitive) =>
            primitive.role == BorderPrimitiveRole.structureMedium &&
            primitive.weight > 0,
      )
      .toList(growable: false);
  final fillerPrimitives = primitives
      .where(
        (primitive) =>
            primitive.role == BorderPrimitiveRole.filler &&
            primitive.weight > 0,
      )
      .toList(growable: false);
  final primitiveById = <String, BorderPublishedPrimitive>{
    for (final primitive in primitives) primitive.id: primitive,
  };
  final primitiveCatalog = _StonePrimitiveCatalog(primitives);
  final targetLipOverlapPx = _twoTierTargetOverlapPx(
    primitives: lipPrimitives,
    maximumOverlapPx: parameters.maxOverlapPx,
  );
  final targetFaceOverlapPx = _twoTierTargetOverlapPx(
    primitives: facePrimitives,
    maximumOverlapPx: parameters.maxOverlapPx,
  );
  final structuralQuantumPx = _twoTierStructuralQuantumPx(
    primitives: primitives,
    maximumOverlapPx: parameters.maxOverlapPx,
  );
  final generatedBySlot = <String, _GeneratedStonePlacement>{};
  final allRunRows = <_TwoTierTopologyRunRows>[];
  final straightLips = <_GeneratedStonePlacement>[];
  final topologyLineages = <String>{
    for (final path in paths)
      if (!_isStraightStonePath(path)) path.lineageId,
  };

  for (final path in paths) {
    // Independent straight strokes retain the historical row planner even
    // when another stroke in the feature turns. Fragments of one edited
    // lineage must, however, keep a single planner: switching only the newly
    // straight fragment after an erase would invalidate its distant topology
    // slots and make local regeneration differ from a complete solve.
    if (_isStraightStonePath(path) &&
        !topologyLineages.contains(path.lineageId)) {
      final lipCollisionIndex = _StoneCollisionIndex(
        bucketSizePx:
            _maximum(request.tileSizePx.width, request.tileSizePx.height),
      );
      final faceCollisionIndex = _StoneCollisionIndex(
        bucketSizePx:
            _maximum(request.tileSizePx.width, request.tileSizePx.height),
      );
      final fillerCollisionIndex = _StoneCollisionIndex(
        bucketSizePx:
            _maximum(request.tileSizePx.width, request.tileSizePx.height),
      );
      final lipNeeds = _buildLipNeeds(
        request: request,
        path: path,
        parameters: parameters,
      );
      final materializedPathLips = _materializeTwoTierRow(
        request: request,
        revision: revision,
        needs: lipNeeds,
        primitives: lipPrimitives,
        targetOverlapPx: targetLipOverlapPx,
        collisionIndex: lipCollisionIndex,
        diagnostics: diagnostics,
        gapCode: 'border.resolution.stone_chain_lip_gap',
      );
      if (materializedPathLips == null) return _failure(diagnostics);
      final pathLips = _withTwoTierStraightEndpointSlots(
        request: request,
        path: path,
        placements: materializedPathLips,
        passIndex: 0,
        role: BorderPrimitiveRole.lineCap,
        rank: 0,
      );
      final faceNeeds = _buildFaceNeeds(
        request: request,
        path: path,
        parameters: parameters,
      );
      final materializedPathFaces = _materializeTwoTierRow(
        request: request,
        revision: revision,
        needs: faceNeeds,
        primitives: facePrimitives,
        targetOverlapPx: targetFaceOverlapPx,
        collisionIndex: faceCollisionIndex,
        diagnostics: diagnostics,
        gapCode: 'border.resolution.stone_chain_face_gap',
        forbiddenJointCoordinates: _twoTierJointCoordinates(pathLips),
      );
      if (materializedPathFaces == null) return _failure(diagnostics);
      final pathFaces = _withTwoTierStraightEndpointSlots(
        request: request,
        path: path,
        placements: materializedPathFaces,
        passIndex: 1,
        role: BorderPrimitiveRole.structureMedium,
        rank: 2,
      );
      _validateTwoTierStraightPath(
        request: request,
        parameters: parameters,
        path: path,
        lips: pathLips,
        faces: pathFaces,
        primitiveById: primitiveById,
        diagnostics: diagnostics,
      );
      if (_hasErrors(diagnostics)) return _failure(diagnostics);
      final pathFillers = _materializeTwoTierFillers(
        request: request,
        revision: revision,
        parameters: parameters,
        lipNeeds: lipNeeds,
        fillerPrimitives: fillerPrimitives,
        primitiveCatalog: primitiveCatalog,
        structuralPlacements: <_GeneratedStonePlacement>[
          ...pathFaces,
          ...pathLips,
        ],
        collisionIndex: fillerCollisionIndex,
        diagnostics: diagnostics,
      );
      if (_hasErrors(diagnostics)) return _failure(diagnostics);
      straightLips.addAll(pathLips);
      for (final placement in <_GeneratedStonePlacement>[
        ...pathFaces,
        ...pathLips,
        ...pathFillers,
      ]) {
        generatedBySlot[placement.placement.slotKey] = placement;
      }
      continue;
    }

    final plan = _TwoTierTopologyPlan.build(
      request: request,
      path: path,
    );
    final reservations = _reserveTwoTierTopologyNodes(
      request: request,
      revision: revision,
      parameters: parameters,
      primitives: primitives,
      plan: plan,
      diagnostics: diagnostics,
    );
    if (reservations == null) return _failure(diagnostics);
    for (final placement in reservations.allPlacements) {
      generatedBySlot[placement.placement.slotKey] = placement;
    }

    for (final run in plan.runs) {
      final lipStart = reservations.boundaryItem(
        request: request,
        run: run,
        passIndex: 0,
        atStart: true,
      );
      final lipEnd = reservations.boundaryItem(
        request: request,
        run: run,
        passIndex: 0,
        atStart: false,
      );
      final lipNeeds = _buildTwoTierRunNeeds(
        request: request,
        run: run,
        role: BorderPrimitiveRole.structureLarge,
        passIndex: 0,
        drawBand: BorderDrawBand.structure,
        quantumPx: structuralQuantumPx,
      );
      final runLips = _materializeTwoTierRunRow(
        request: request,
        revision: revision,
        run: run,
        needs: lipNeeds,
        startBoundary: lipStart,
        endBoundary: lipEnd,
        primitives: lipPrimitives,
        targetOverlapPx: targetLipOverlapPx,
        diagnostics: diagnostics,
        gapCode: 'border.resolution.stone_chain_lip_gap',
      );
      if (runLips == null) return _failure(diagnostics);

      final faceStart = reservations.boundaryItem(
        request: request,
        run: run,
        passIndex: 1,
        atStart: true,
      );
      final faceEnd = reservations.boundaryItem(
        request: request,
        run: run,
        passIndex: 1,
        atStart: false,
      );
      final faceNeeds = _buildTwoTierRunNeeds(
        request: request,
        run: run,
        role: BorderPrimitiveRole.structureMedium,
        passIndex: 1,
        drawBand: BorderDrawBand.outerAccent,
        quantumPx: structuralQuantumPx,
      );
      final runFaces = _materializeTwoTierRunRow(
        request: request,
        revision: revision,
        run: run,
        needs: faceNeeds,
        startBoundary: faceStart,
        endBoundary: faceEnd,
        primitives: facePrimitives,
        targetOverlapPx: targetFaceOverlapPx,
        diagnostics: diagnostics,
        gapCode: 'border.resolution.stone_chain_face_gap',
        forbiddenJointCoordinates: _twoTierJointCoordinates(runLips),
        attachmentRow: runLips,
      );
      if (runFaces == null) return _failure(diagnostics);

      final rows = _TwoTierTopologyRunRows(
        run: run,
        lips: runLips,
        faces: runFaces,
      );
      _validateTwoTierTopologyRun(
        request: request,
        parameters: parameters,
        rows: rows,
        primitiveById: primitiveById,
        diagnostics: diagnostics,
      );
      if (_hasErrors(diagnostics)) return _failure(diagnostics);
      allRunRows.add(rows);
      for (final placement in <_GeneratedStonePlacement>[
        ...runFaces,
        ...runLips,
      ]) {
        generatedBySlot[placement.placement.slotKey] = placement;
      }
    }
    _validateTwoTierTopologyJunctions(
      request: request,
      plan: plan,
      reservations: reservations,
      primitiveById: primitiveById,
      diagnostics: diagnostics,
    );
    if (_hasErrors(diagnostics)) return _failure(diagnostics);
  }

  final generated = generatedBySlot.values.toList(growable: false)
    ..sort(_compareGenerated);
  final previousBaseBySlot = <String, BorderResolvedPlacement>{
    if (localScope != null)
      for (final placement in localScope.previousBasePlacements)
        placement.slotKey: placement,
  };
  final retainedSlotKeys = <String>{};
  final basePlacements = <BorderResolvedPlacement>[];
  for (final entry in generated) {
    final previous = previousBaseBySlot[entry.placement.slotKey];
    if (localScope != null &&
        previous != null &&
        localScope.retainsBasePlacement(previous, request.tileSizePx)) {
      retainedSlotKeys.add(previous.slotKey);
      basePlacements.add(previous);
    } else {
      localScope?.recordRecomputedCell(entry.placement.anchorCell);
      basePlacements.add(entry.placement);
    }
  }
  basePlacements.sort(
    (left, right) => left.stableOrderKey.compareTo(right.stableOrderKey),
  );
  localCapture?.recordBase(
    ground: const <BorderResolvedGroundCell>[],
    placements: basePlacements,
  );
  final overrideResolution = resolveBorderOverrides(
    request: request,
    baseGround: const <BorderResolvedGroundCell>[],
    basePlacements: basePlacements,
    alreadyResolvedSlotKeys: retainedSlotKeys,
    previouslyResolvedPlacementsBySlot:
        localScope?.previousResolvedPlacementsBySlot ??
            const <String, BorderResolvedPlacement>{},
    previouslySuppressedSlotKeys:
        localScope?.previousSuppressedPlacementSlotKeys ?? const <String>{},
  );
  diagnostics.addAll(overrideResolution.diagnostics);
  if (_hasErrors(diagnostics)) return _failure(diagnostics);
  final placements = overrideResolution.placements.toList(growable: false)
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
    return _failure(diagnostics);
  }

  final components = computeBorderInputFingerprints(request);
  final materialization = BorderMaterialization(
    receipt: BorderResolutionReceipt(
      resolverVersion: request.resolverVersion,
      blueprintRevision: revision.revision,
      components: components,
      inputFingerprint: computeBorderAggregateInputFingerprint(
        resolverVersion: request.resolverVersion,
        blueprintRevision: revision.revision,
        components: components,
      ),
      outputFingerprint: computeBorderOutputFingerprint(
        ground: const <BorderResolvedGroundCell>[],
        placements: placements,
      ),
    ),
    ground: const <BorderResolvedGroundCell>[],
    placements: placements,
  );
  final visibleGenerated = <_GeneratedStonePlacement>[
    for (final placement in placements)
      if (generatedBySlot[placement.slotKey] case final generated?)
        generated.withPlacement(placement),
  ];
  final visibleLips = visibleGenerated
      .where((placement) => placement.isPrimary)
      .toList(growable: false);
  final edgeCount = paths.fold<int>(
    0,
    (count, path) => count + path.edges.length,
  );
  return StoneChainLineBorderResolutionEvidence(
    result: BorderResolutionResult(
      materialization: materialization,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    ),
    primaryPlacementCount: visibleLips.length,
    secondaryPlacementCount:
        visibleGenerated.where((placement) => !placement.isPrimary).length,
    maximumGapPx: _maximum(
      _maximumTopologyRunGap(allRunRows),
      _maximumObservedGap(straightLips),
    ),
    maximumTangentOverlapPx: _maximumObservedOverlap(
      visibleGenerated,
      bucketSizePx:
          _maximum(request.tileSizePx.width, request.tileSizePx.height),
    ),
    maximumCornerThicknessRatioPermille: 0,
    maximumRepeatedPrimitiveRunLength: _maximumRepeat(visibleLips),
    placementsPerSegmentPermille:
        edgeCount == 0 ? 0 : visibleLips.length * 1000 ~/ edgeCount,
  );
}

_TwoTierTopologyReservations? _reserveTwoTierTopologyNodes({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required BorderGenerationParams parameters,
  required List<BorderPublishedPrimitive> primitives,
  required _TwoTierTopologyPlan plan,
  required List<BorderDiagnostic> diagnostics,
}) {
  final lipItems = <String, _TwoTierRowItem>{};
  final faceItems = <String, _TwoTierRowItem>{};
  final normalOffset = _maximum(
    1,
    _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 8,
  );
  // A perpendicular face starts behind its own lip neck. With narrow
  // individual stones, using the full row offset at a turn leaves that neck
  // diagonally separated from the corner lip. Pull only the two shoulders three
  // pixels toward the vertex; straight rows and their visible depth stay
  // unchanged, while the reserved three-stone turn gains a real alpha seam.
  final turnFaceNormalOffset = _maximum(1, normalOffset - 3);
  // The two semantic shoulders meet at the node. Pushing each one down its
  // leg leaves the outer-side recipe diagonally detached at an inverted turn.
  // Distinct ranks preserve their identities without a tangent displacement.
  const shoulderInset = 0;
  final capInset = _twoTierTopologyCapInsetPx(
    request: request,
    parameters: parameters,
  );

  for (final turn in plan.turns) {
    final lip = _buildTwoTierTopologyNodeNeed(
      request: request,
      path: plan.path,
      vertex: turn.vertex,
      distance: turn.distancePx,
      edge: turn.outgoing,
      tangentOffsetPx: 0,
      normalOffsetPx: normalOffset,
      passIndex: 0,
      role: BorderPrimitiveRole.lineCorner,
      rank: 0,
      stableOrdinal: turn.sourceVertexOrdinal,
      drawBand: BorderDrawBand.structure,
    );
    final incomingFace = _buildTwoTierTopologyNodeNeed(
      request: request,
      path: plan.path,
      vertex: turn.vertex,
      distance: turn.distancePx,
      edge: turn.incoming,
      tangentOffsetPx: -shoulderInset,
      normalOffsetPx: turnFaceNormalOffset,
      passIndex: 1,
      role: BorderPrimitiveRole.structureMedium,
      rank: 0,
      stableOrdinal: turn.sourceVertexOrdinal,
      drawBand: BorderDrawBand.outerAccent,
    );
    final outgoingFace = _buildTwoTierTopologyNodeNeed(
      request: request,
      path: plan.path,
      vertex: turn.vertex,
      distance: turn.distancePx,
      edge: turn.outgoing,
      tangentOffsetPx: shoulderInset,
      normalOffsetPx: turnFaceNormalOffset,
      passIndex: 1,
      role: BorderPrimitiveRole.structureMedium,
      rank: 1,
      stableOrdinal: turn.sourceVertexOrdinal,
      drawBand: BorderDrawBand.outerAccent,
    );
    final reservation = _selectTwoTierTurnReservation(
      request: request,
      revision: revision,
      lipNeed: lip,
      incomingFaceNeed: incomingFace,
      outgoingFaceNeed: outgoingFace,
      primitives: primitives,
      maximumInsetPx: parameters.maxOverlapPx,
    );
    if (reservation == null) {
      for (final need in <_PlacementNeed>[
        lip,
        incomingFace,
        outgoingFace,
      ]) {
        _addTwoTierOrientationDiagnostic(
          request: request,
          need: need,
          diagnostics: diagnostics,
        );
      }
      return null;
    }
    lipItems[lip.slotKey] = reservation.lip;
    faceItems[incomingFace.slotKey] = reservation.incomingFace;
    faceItems[outgoingFace.slotKey] = reservation.outgoingFace;
  }

  for (final endpoint in plan.endpoints) {
    final inwardOffset = endpoint.atStart ? capInset : -capInset;
    final lip = _buildTwoTierTopologyNodeNeed(
      request: request,
      path: plan.path,
      vertex: endpoint.vertex,
      distance: endpoint.distancePx,
      edge: endpoint.edge,
      tangentOffsetPx: inwardOffset,
      normalOffsetPx: normalOffset,
      passIndex: 0,
      role: BorderPrimitiveRole.lineCap,
      rank: 0,
      stableOrdinal: endpoint.edge.generationEdgeIndex,
      drawBand: BorderDrawBand.structure,
    );
    final face = _buildTwoTierTopologyNodeNeed(
      request: request,
      path: plan.path,
      vertex: endpoint.vertex,
      distance: endpoint.distancePx,
      edge: endpoint.edge,
      tangentOffsetPx: inwardOffset,
      normalOffsetPx: normalOffset,
      passIndex: 1,
      role: BorderPrimitiveRole.structureMedium,
      rank: 2,
      stableOrdinal: endpoint.edge.generationEdgeIndex,
      drawBand: BorderDrawBand.outerAccent,
    );
    final reservation = _selectTwoTierEndpointReservation(
      request: request,
      revision: revision,
      lipNeed: lip,
      faceNeed: face,
      primitives: primitives,
      inwardSign: endpoint.atStart ? 1 : -1,
      maximumInsetPx: parameters.maxOverlapPx,
    );
    if (reservation == null) {
      for (final need in <_PlacementNeed>[lip, face]) {
        _addTwoTierOrientationDiagnostic(
          request: request,
          need: need,
          diagnostics: diagnostics,
        );
      }
      return null;
    }
    lipItems[lip.slotKey] = reservation.lip;
    faceItems[face.slotKey] = reservation.face;
  }
  return _TwoTierTopologyReservations(
    plan: plan,
    lipItems: lipItems,
    faceItems: faceItems,
  );
}

_PlacementNeed _buildTwoTierTopologyNodeNeed({
  required BorderResolutionRequest request,
  required _StonePath path,
  required GridPos vertex,
  required int distance,
  required _PathEdge edge,
  required int tangentOffsetPx,
  required int normalOffsetPx,
  required int passIndex,
  required BorderPrimitiveRole role,
  required int rank,
  required int stableOrdinal,
  required BorderDrawBand drawBand,
}) {
  final sideSign = request.feature.lineSide == BorderLineSide.primary ? 1 : -1;
  final normalX = -edge.directionY * sideSign;
  final normalY = edge.directionX * sideSign;
  final target = BorderPixelPos(
    x: vertex.x * request.tileSizePx.width +
        edge.directionX * tangentOffsetPx +
        normalX * normalOffsetPx,
    y: vertex.y * request.tileSizePx.height +
        edge.directionY * tangentOffsetPx +
        normalY * normalOffsetPx,
  );
  return _PlacementNeed(
    featureId: request.feature.id,
    path: path,
    distance: distance,
    stationOrdinal: rank,
    semanticRole: role,
    passIndex: passIndex,
    tangentX: edge.directionX,
    tangentY: edge.directionY,
    normalX: normalX,
    normalY: normalY,
    targetAnchorWorldPx: target,
    anchorCell: _anchorCell(request, target),
    slotKey: buildBorderStoneChainNodeSlotKey(
      featureId: request.feature.id,
      strokeId: path.lineageId,
      vertex: vertex,
      passIndex: passIndex,
      role: role,
      rank: rank,
    ),
    isSpecial: true,
    isPrimary: passIndex == 0,
    drawBand: drawBand,
    stableOrderOrdinal: stableOrdinal,
  );
}

_TwoTierTurnReservation? _selectTwoTierTurnReservation({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed lipNeed,
  required _PlacementNeed incomingFaceNeed,
  required _PlacementNeed outgoingFaceNeed,
  required List<BorderPublishedPrimitive> primitives,
  required int maximumInsetPx,
}) {
  final lipCandidates = _twoTierReservedCandidates(
    request: request,
    revision: revision,
    need: lipNeed,
    candidateRoles: const <BorderPrimitiveRole>[
      BorderPrimitiveRole.lineCorner,
      BorderPrimitiveRole.structureLarge,
    ],
    primitives: primitives,
    tangentDeltas: const <int>[0],
  );
  final shoulderDeltas = _symmetricInsetDeltas(maximumInsetPx);
  final incomingCandidates = _twoTierReservedCandidates(
    request: request,
    revision: revision,
    need: incomingFaceNeed,
    candidateRoles: const <BorderPrimitiveRole>[
      BorderPrimitiveRole.structureMedium,
    ],
    primitives: primitives,
    tangentDeltas: shoulderDeltas,
  );
  final outgoingCandidates = _twoTierReservedCandidates(
    request: request,
    revision: revision,
    need: outgoingFaceNeed,
    candidateRoles: const <BorderPrimitiveRole>[
      BorderPrimitiveRole.structureMedium,
    ],
    primitives: primitives,
    tangentDeltas: shoulderDeltas,
  );
  if (lipCandidates.isEmpty ||
      incomingCandidates.isEmpty ||
      outgoingCandidates.isEmpty) {
    return null;
  }
  final diverseCornerIds = lipCandidates
      .where(
        (candidate) =>
            candidate.primitive.role == BorderPrimitiveRole.lineCorner,
      )
      .map((candidate) => candidate.primitive.id)
      .toSet();
  final diverseFaceIds = incomingCandidates
      .where(
        (candidate) =>
            _twoTierReservedTangentDelta(candidate, incomingFaceNeed) == 0,
      )
      .map((candidate) => candidate.primitive.id)
      .toSet();
  final diversifyTurnRecipe =
      diverseCornerIds.length >= 2 && diverseFaceIds.length >= 6;
  // A six-stone organic catalogue deliberately authors several compact turn
  // recipes. Keep structureLarge only as the legacy emergency fallback; if
  // real corner stones exist, selecting a full lip stone recreates the same
  // bulky staircase module at every one-cell bend.
  final eligibleLipCandidates = diversifyTurnRecipe
      ? lipCandidates
          .where(
            (candidate) =>
                candidate.primitive.role == BorderPrimitiveRole.lineCorner,
          )
          .toList(growable: false)
      : lipCandidates;
  final lipDiversityOrder = diversifyTurnRecipe
      ? _twoTierTurnPrimitiveDiversityOrder(
          request: request,
          revision: revision,
          turnSlotKey: lipNeed.slotKey,
          channel: 'lip',
          candidates: eligibleLipCandidates,
        )
      : const <String, int>{};
  final incomingDiversityOrder = diversifyTurnRecipe
      ? _twoTierTurnPrimitiveDiversityOrder(
          request: request,
          revision: revision,
          turnSlotKey: lipNeed.slotKey,
          channel: 'incoming-face',
          candidates: incomingCandidates,
        )
      : const <String, int>{};
  final outgoingDiversityOrder = diversifyTurnRecipe
      ? _twoTierTurnPrimitiveDiversityOrder(
          request: request,
          revision: revision,
          turnSlotKey: lipNeed.slotKey,
          channel: 'outgoing-face',
          candidates: outgoingCandidates,
        )
      : const <String, int>{};
  final preparedMaskShapes = <(String, int, bool), Set<_TwoTierMaskPixel>>{};
  _TwoTierPreparedMask prepare(_TwoTierReservedCandidate candidate) =>
      _prepareTwoTierPlannedMask(
        placement: candidate.placement,
        primitive: candidate.primitive,
        cache: preparedMaskShapes,
      );
  final lipMasks = <_TwoTierPreparedMask>[
    for (final candidate in lipCandidates) prepare(candidate),
  ];
  final incomingMasks = <_TwoTierPreparedMask>[
    for (final candidate in incomingCandidates) prepare(candidate),
  ];
  final outgoingMasks = <_TwoTierPreparedMask>[
    for (final candidate in outgoingCandidates) prepare(candidate),
  ];
  final shapeIsConnected = <(String, int, bool), bool>{};
  bool candidateShapeIsConnected(
    _TwoTierReservedCandidate candidate,
    _TwoTierPreparedMask mask,
  ) {
    final transform = candidate.placement.placement.transform;
    return shapeIsConnected.putIfAbsent(
      (candidate.primitive.id, transform.quarterTurns, transform.flipX),
      () => _twoTierPreparedMaskComponentCount(mask.pixels) == 1,
    );
  }

  ({
    _TwoTierTurnReservation reservation,
    int minimumSpan,
    int totalSpan,
    int totalShoulderNormalSpan,
    int absoluteShoulderShift,
    int minimumInterlock,
    int interlockShortfall,
    int diversityPenalty,
    String stableKey,
  })? best;
  final connectedShoulderPairs = <(int, int), bool>{};
  for (final lip in eligibleLipCandidates) {
    final lipIndex = lipCandidates.indexOf(lip);
    final lipMask = lipMasks[lipIndex];
    final incomingSpan = _twoTierOpaqueSpanAlong(
      lip,
      tangentX: incomingFaceNeed.tangentX,
    );
    final outgoingSpan = _twoTierOpaqueSpanAlong(
      lip,
      tangentX: outgoingFaceNeed.tangentX,
    );
    final incomingInterlocks = <int>[
      for (final incomingMask in incomingMasks)
        _twoTierPreparedOpaqueIntersectionPixels(lipMask, incomingMask),
    ];
    final outgoingInterlocks = <int>[
      for (final outgoingMask in outgoingMasks)
        _twoTierPreparedOpaqueIntersectionPixels(lipMask, outgoingMask),
    ];
    for (var incomingIndex = 0;
        incomingIndex < incomingCandidates.length;
        incomingIndex += 1) {
      final incoming = incomingCandidates[incomingIndex];
      final incomingInterlock = incomingInterlocks[incomingIndex];
      final incomingDelta =
          _twoTierReservedTangentDelta(incoming, incomingFaceNeed);
      if (incomingInterlock < _minimumTwoTierCrossRowInterlockPixels) {
        continue;
      }
      for (var outgoingIndex = 0;
          outgoingIndex < outgoingCandidates.length;
          outgoingIndex += 1) {
        final outgoing = outgoingCandidates[outgoingIndex];
        final outgoingInterlock = outgoingInterlocks[outgoingIndex];
        final outgoingDelta =
            _twoTierReservedTangentDelta(outgoing, outgoingFaceNeed);
        if (outgoingInterlock < _minimumTwoTierCrossRowInterlockPixels) {
          continue;
        }
        final shouldersConnect = connectedShoulderPairs.putIfAbsent(
          (incomingIndex, outgoingIndex),
          () {
            final incomingMask = incomingMasks[incomingIndex];
            final outgoingMask = outgoingMasks[outgoingIndex];
            if (candidateShapeIsConnected(incoming, incomingMask) &&
                candidateShapeIsConnected(outgoing, outgoingMask)) {
              return _twoTierPreparedMasksTouch(incomingMask, outgoingMask);
            }
            return _twoTierReservedComponentCount(<_TwoTierReservedCandidate>[
                  incoming,
                  outgoing,
                ]) ==
                1;
          },
        );
        if (!shouldersConnect) {
          continue;
        }
        final stableKey = _twoTierTurnReservationStableKey(
          lip: lip,
          incoming: incoming,
          outgoing: outgoing,
          incomingDelta: incomingDelta,
          outgoingDelta: outgoingDelta,
        );
        final candidate = (
          reservation: _TwoTierTurnReservation(
            lip: lip.asRowItem(),
            incomingFace: incoming.asRowItem(),
            outgoingFace: outgoing.asRowItem(),
          ),
          minimumSpan: _minimum(incomingSpan, outgoingSpan),
          totalSpan: incomingSpan + outgoingSpan,
          totalShoulderNormalSpan: _twoTierOpaqueSpanAlong(
                incoming,
                tangentX: incomingFaceNeed.normalX,
              ) +
              _twoTierOpaqueSpanAlong(
                outgoing,
                tangentX: outgoingFaceNeed.normalX,
              ),
          absoluteShoulderShift: incomingDelta.abs() + outgoingDelta.abs(),
          minimumInterlock: _minimum(incomingInterlock, outgoingInterlock),
          interlockShortfall: _maximum(
            0,
            12 - _minimum(incomingInterlock, outgoingInterlock),
          ),
          diversityPenalty: (lipDiversityOrder[lip.primitive.id] ?? 0) +
              (incomingDiversityOrder[incoming.primitive.id] ?? 0) +
              (outgoingDiversityOrder[outgoing.primitive.id] ?? 0),
          stableKey: stableKey,
        );
        final incumbent = best;
        var comparison = -1;
        if (incumbent != null) {
          if (diversifyTurnRecipe) {
            comparison = candidate.absoluteShoulderShift
                .compareTo(incumbent.absoluteShoulderShift);
            if (comparison == 0) {
              comparison = candidate.interlockShortfall
                  .compareTo(incumbent.interlockShortfall);
            }
            if (comparison == 0) {
              comparison = candidate.diversityPenalty
                  .compareTo(incumbent.diversityPenalty);
            }
          } else {
            comparison = candidate.minimumSpan.compareTo(incumbent.minimumSpan);
            if (comparison == 0) {
              comparison = candidate.totalSpan.compareTo(incumbent.totalSpan);
            }
            if (comparison == 0) {
              comparison = candidate.totalShoulderNormalSpan
                  .compareTo(incumbent.totalShoulderNormalSpan);
            }
            if (comparison == 0) {
              comparison = candidate.absoluteShoulderShift
                  .compareTo(incumbent.absoluteShoulderShift);
            }
            if (comparison == 0) {
              // Once the compact geometry is tied, retain the safest alpha
              // interlock before using the stable key as the final tiebreaker.
              comparison = incumbent.minimumInterlock
                  .compareTo(candidate.minimumInterlock);
            }
          }
          if (comparison == 0) {
            comparison = candidate.stableKey.compareTo(incumbent.stableKey);
          }
        }
        if (comparison < 0) {
          best = candidate;
        }
      }
    }
  }
  if (best case final selection?) return selection.reservation;

  // Preserve the historical deterministic failure payload when no bounded
  // alpha-compatible recipe exists. The topology validator owns the stable
  // diagnostic vocabulary.
  return _TwoTierTurnReservation(
    lip: lipCandidates.first.asRowItem(),
    incomingFace: incomingCandidates.first.asRowItem(),
    outgoingFace: outgoingCandidates.first.asRowItem(),
  );
}

int _twoTierOpaqueSpanAlong(
  _TwoTierReservedCandidate candidate, {
  required int tangentX,
}) {
  final bounds = candidate.placement.placement.opaqueWorldBoundsPx;
  return tangentX != 0 ? bounds.width : bounds.height;
}

int _twoTierReservedTangentDelta(
  _TwoTierReservedCandidate candidate,
  _PlacementNeed baseNeed,
) =>
    (candidate.need.targetAnchorWorldPx.x - baseNeed.targetAnchorWorldPx.x) *
        baseNeed.tangentX +
    (candidate.need.targetAnchorWorldPx.y - baseNeed.targetAnchorWorldPx.y) *
        baseNeed.tangentY;

String _twoTierTurnReservationStableKey({
  required _TwoTierReservedCandidate lip,
  required _TwoTierReservedCandidate incoming,
  required _TwoTierReservedCandidate outgoing,
  required int incomingDelta,
  required int outgoingDelta,
}) {
  String candidateKey(_TwoTierReservedCandidate candidate) {
    final transform = candidate.placement.placement.transform;
    return '${candidate.primitive.id}:${transform.quarterTurns}:'
        '${transform.flipX ? 1 : 0}';
  }

  return '${candidateKey(lip)}|${candidateKey(incoming)}@$incomingDelta|'
      '${candidateKey(outgoing)}@$outgoingDelta';
}

Map<String, int> _twoTierTurnPrimitiveDiversityOrder({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required String turnSlotKey,
  required String channel,
  required Iterable<_TwoTierReservedCandidate> candidates,
}) {
  final ids = candidates.map((candidate) => candidate.primitive.id).toSet();
  final ordered = ids.toList(growable: false)
    ..sort((left, right) {
      BigInt rank(String primitiveId) =>
          BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
            const BorderRngKeyComponent.text(
              'stone-chain-turn-primitive-diversity',
            ),
            BorderRngKeyComponent.text(request.blueprintId),
            BorderRngKeyComponent.signedInt64(
              BorderSignedInt64.fromInt(revision.revision),
            ),
            BorderRngKeyComponent.signedInt64(request.feature.seed),
            BorderRngKeyComponent.text(turnSlotKey),
            BorderRngKeyComponent.text(channel),
            BorderRngKeyComponent.text(primitiveId),
          ]).nextUint64();

      final byRank = rank(left).compareTo(rank(right));
      return byRank != 0 ? byRank : left.compareTo(right);
    });
  return <String, int>{
    for (var index = 0; index < ordered.length; index += 1)
      ordered[index]: index,
  };
}

_TwoTierEndpointReservation? _selectTwoTierEndpointReservation({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed lipNeed,
  required _PlacementNeed faceNeed,
  required List<BorderPublishedPrimitive> primitives,
  required int inwardSign,
  required int maximumInsetPx,
}) {
  final lipCandidates = _twoTierReservedCandidates(
    request: request,
    revision: revision,
    need: lipNeed,
    candidateRoles: const <BorderPrimitiveRole>[
      BorderPrimitiveRole.lineCap,
      BorderPrimitiveRole.structureLarge,
    ],
    primitives: primitives,
    tangentDeltas: const <int>[0],
  );
  final faceCandidates = _twoTierReservedCandidates(
    request: request,
    revision: revision,
    need: faceNeed,
    candidateRoles: const <BorderPrimitiveRole>[
      BorderPrimitiveRole.structureMedium,
    ],
    primitives: primitives,
    tangentDeltas: <int>[
      0,
      for (var inset = 1; inset <= maximumInsetPx; inset += 1)
        inwardSign * inset,
    ],
  );
  if (lipCandidates.isEmpty || faceCandidates.isEmpty) return null;
  for (final lip in lipCandidates) {
    for (final face in faceCandidates) {
      if (_twoTierAlphaInterlock(lip, face) >=
          _minimumTwoTierCrossRowInterlockPixels) {
        return _TwoTierEndpointReservation(
          lip: lip.asRowItem(),
          face: face.asRowItem(),
        );
      }
    }
  }
  return _TwoTierEndpointReservation(
    lip: lipCandidates.first.asRowItem(),
    face: faceCandidates.first.asRowItem(),
  );
}

List<_TwoTierReservedCandidate> _twoTierReservedCandidates({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed need,
  required List<BorderPrimitiveRole> candidateRoles,
  required List<BorderPublishedPrimitive> primitives,
  required List<int> tangentDeltas,
}) {
  final desired = _cardinalDirectionForVector(need.normalX, need.normalY);
  final candidates = primitives
      .where(
        (primitive) =>
            primitive.weight > 0 && candidateRoles.contains(primitive.role),
      )
      .toList(growable: false)
    ..sort((left, right) {
      final byRole = candidateRoles
          .indexOf(left.role)
          .compareTo(candidateRoles.indexOf(right.role));
      return byRole != 0 ? byRole : left.id.compareTo(right.id);
    });
  final parameters =
      request.feature.paramsOverride ?? revision.definition.defaults;
  final result = <_TwoTierReservedCandidate>[];
  for (final delta in tangentDeltas) {
    final shiftedNeed = need.offsetAnchorAlongTangent(
      request: request,
      delta: delta,
    );
    for (final primitive in candidates) {
      final quarterTurns = _quarterTurnsForOrientation(
        authored: primitive.authoredOrientation,
        desired: desired,
        allowAutoRotation: parameters.allowAutoRotation,
        allowedQuarterTurns: primitive.transforms.allowedQuarterTurns,
      );
      if (quarterTurns == null) continue;
      final build = _buildPlacement(
        request: request,
        need: shiftedNeed,
        selected: primitive,
        quarterTurns: quarterTurns,
      );
      if (build case _PlacementBuildAccepted(:final placement)) {
        result.add(
          _TwoTierReservedCandidate(
            need: shiftedNeed,
            placement: placement,
            primitive: primitive,
          ),
        );
      }
    }
  }
  return List<_TwoTierReservedCandidate>.unmodifiable(result);
}

List<int> _symmetricInsetDeltas(int maximumInsetPx) => <int>[
      0,
      for (var inset = 1; inset <= maximumInsetPx; inset += 1) ...<int>[
        inset,
        -inset,
      ],
    ];

int _twoTierAlphaInterlock(
  _TwoTierReservedCandidate first,
  _TwoTierReservedCandidate second,
) =>
    measureStoneChainContact(
      first: _twoTierPlacedMask(first.placement, first.primitive),
      second: _twoTierPlacedMask(second.placement, second.primitive),
      tangent: StoneChainAxis(
        dx: first.need.tangentX,
        dy: first.need.tangentY,
      ),
      normal: StoneChainAxis(
        dx: first.need.normalX,
        dy: first.need.normalY,
      ),
    ).opaqueIntersectionPixels;

int _twoTierReservedComponentCount(
  List<_TwoTierReservedCandidate> candidates,
) =>
    measureStoneChainRowContinuity(
      samples: <StoneChainRowSample>[
        for (var index = 0; index < candidates.length; index += 1)
          StoneChainRowSample(
            strokeId: 'reserved:$index',
            slotKey: candidates[index].need.slotKey,
            pathDistancePx: 0,
            closed: false,
            mask: _twoTierPlacedMask(
              candidates[index].placement,
              candidates[index].primitive,
            ),
          ),
      ],
      tangent: StoneChainAxis(dx: 1, dy: 0),
      normal: StoneChainAxis(dx: 0, dy: 1),
    ).connectedComponentCount;

List<_PlacementNeed> _buildTwoTierRunNeeds({
  required BorderResolutionRequest request,
  required _TwoTierRun run,
  required BorderPrimitiveRole role,
  required int passIndex,
  required BorderDrawBand drawBand,
  required int quantumPx,
}) {
  final parameters = request.feature.paramsOverride ??
      request.blueprintRevision!.definition.defaults;
  final capInset = _twoTierTopologyCapInsetPx(
    request: request,
    parameters: parameters,
  );
  final boundaryStartDistance =
      run.startDistancePx + (run.startIsTurn ? 0 : capInset);
  final boundaryEndDistance =
      run.endDistancePx - (run.endIsTurn ? 0 : capInset);
  final effectiveLengthPx =
      _maximum(0, boundaryEndDistance - boundaryStartDistance);
  final baseIntervalCount = _maximum(
    2,
    effectiveLengthPx ~/ quantumPx,
  );
  // The lip keeps the structural cadence while the face owns one fewer
  // interval. Topology nodes already reserve two face shoulders per turn, so
  // this bounded asymmetry keeps the complete two-row recipe balanced.
  // Interpolation uses semantic boundaries only: profile-specific fitting
  // deltas never leak into lineage slots.
  final isTwoEdgeTurnRun =
      run.startIsTurn && run.endIsTurn && run.edges.length == 2;
  final intervalCount = passIndex == 0
      ? (isTwoEdgeTurnRun
          ? _maximum(2, baseIntervalCount - 1)
          : baseIntervalCount)
      : run.isOneCellBetweenTurns
          // Both turn shoulders can sit outside the semantic cell after their
          // corner interlock is fitted. Keep the full cadence on that single
          // edge so compact faces can still satisfy the strict 2 px contacts.
          ? baseIntervalCount
          : _maximum(2, baseIntervalCount - 1);
  final needs = <_PlacementNeed>[];
  for (var index = 1; index < intervalCount; index += 1) {
    final pathDistancePx = boundaryStartDistance +
        (effectiveLengthPx * index + intervalCount ~/ 2) ~/ intervalCount;
    if (pathDistancePx <= run.startDistancePx ||
        pathDistancePx >= run.endDistancePx ||
        needs.any((need) => need.distance == pathDistancePx)) {
      continue;
    }
    needs.add(
      _buildTwoTierLineageNeed(
        request: request,
        run: run,
        pathDistancePx: pathDistancePx,
        passIndex: passIndex,
        role: role,
        rank: 0,
        drawBand: drawBand,
      ),
    );
  }
  return needs;
}

int _twoTierTopologyCapInsetPx({
  required BorderResolutionRequest request,
  required BorderGenerationParams parameters,
}) =>
    _maximum(
      parameters.maxOverlapPx,
      _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 4 + 2,
    );

_PlacementNeed _buildTwoTierLineageNeed({
  required BorderResolutionRequest request,
  required _TwoTierRun run,
  required int pathDistancePx,
  required int passIndex,
  required BorderPrimitiveRole role,
  required int rank,
  required BorderDrawBand drawBand,
  String? rngSlotKey,
}) {
  final path = run.path;
  final sample = path.sampleAtDistance(pathDistancePx);
  final sideSign = request.feature.lineSide == BorderLineSide.primary ? 1 : -1;
  final normalX = -sample.tangentY * sideSign;
  final normalY = sample.tangentX * sideSign;
  final normalOffset = _maximum(
    1,
    _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 8,
  );
  final target = BorderPixelPos(
    x: sample.worldX + normalX * normalOffset,
    y: sample.worldY + normalY * normalOffset,
  );
  final edgeLength = sample.tangentX != 0
      ? request.tileSizePx.width
      : request.tileSizePx.height;
  final canonicalEdgeOffset = _gridPosComesFirst(
    sample.edgeStart,
    sample.edgeEnd,
  )
      ? sample.localOffsetPx
      : edgeLength - sample.localOffsetPx;
  return _PlacementNeed(
    featureId: request.feature.id,
    path: path,
    distance: pathDistancePx,
    stationOrdinal: sample.generationEdgeIndex,
    semanticRole: role,
    passIndex: passIndex,
    tangentX: sample.tangentX,
    tangentY: sample.tangentY,
    normalX: normalX,
    normalY: normalY,
    targetAnchorWorldPx: target,
    anchorCell: _anchorCell(request, target),
    slotKey: buildBorderStoneChainLineageStationSlotKey(
      featureId: request.feature.id,
      strokeId: path.lineageId,
      edgeStart: sample.edgeStart,
      edgeEnd: sample.edgeEnd,
      generationEdgeIndex: sample.generationEdgeIndex,
      canonicalEdgeOffsetPx: canonicalEdgeOffset,
      passIndex: passIndex,
      role: role,
      rank: rank,
    ),
    isSpecial: false,
    isPrimary: passIndex == 0,
    drawBand: drawBand,
    rngSlotKey: rngSlotKey,
    stableOrderOrdinal: sample.generationEdgeIndex,
    slotRunStart: sample.edgeStart,
    slotRunEnd: sample.edgeEnd,
    slotStationOffsetPx: canonicalEdgeOffset,
    slotGenerationEdgeIndex: sample.generationEdgeIndex,
  );
}

List<_GeneratedStonePlacement>? _materializeTwoTierRunRow({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _TwoTierRun run,
  required List<_PlacementNeed> needs,
  required _TwoTierRowItem startBoundary,
  required _TwoTierRowItem endBoundary,
  required List<BorderPublishedPrimitive> primitives,
  required int targetOverlapPx,
  required List<BorderDiagnostic> diagnostics,
  required String gapCode,
  Set<int> forbiddenJointCoordinates = const <int>{},
  List<_GeneratedStonePlacement>? attachmentRow,
}) {
  final probeNeeds = needs.isNotEmpty
      ? needs
      : <_PlacementNeed>[
          _buildTwoTierLineageNeed(
            request: request,
            run: run,
            pathDistancePx: run.startDistancePx + run.lengthPx ~/ 2,
            passIndex: startBoundary.need.passIndex,
            role: startBoundary.need.passIndex == 0
                ? BorderPrimitiveRole.structureLarge
                : BorderPrimitiveRole.structureMedium,
            rank: 0,
            drawBand: startBoundary.need.drawBand,
          ),
        ];
  final preflight = _preflightTwoTierRow(
    request: request,
    needs: probeNeeds,
    primitives: primitives,
    gapCode: gapCode,
    diagnostics: diagnostics,
  );
  if (preflight == null) return null;
  final rowPrimitives =
      preflight.primitives.isEmpty ? primitives : preflight.primitives;
  final primitiveById = <String, BorderPublishedPrimitive>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      primitive.id: primitive,
  };
  final maximumOverlapPx =
      (request.feature.paramsOverride ?? revision.definition.defaults)
          .maxOverlapPx;
  final solved = _solveTwoTierPlannedRunRow(
    request: request,
    revision: revision,
    needs: needs,
    startBoundary: startBoundary,
    endBoundary: endBoundary,
    primitives: rowPrimitives,
    targetOverlapPx: targetOverlapPx,
    maximumOverlapPx: maximumOverlapPx,
    forbiddenJointCoordinates: forbiddenJointCoordinates,
    primitiveById: primitiveById,
    attachmentRow: attachmentRow,
  );
  if (solved == null) {
    final diagnosticNeed = needs.isEmpty ? probeNeeds.first : needs.first;
    _addTwoTierGapDiagnostic(
      request: request,
      need: diagnosticNeed,
      code: gapCode,
      contact: null,
      backfillBudget: 0,
      attemptedBackfills: 0,
      observed: 'no common strict run plan solution',
      diagnostics: diagnostics,
      extraParameters: <String, Object?>{
        'runStart': run.startVertex.toString(),
        'runEnd': run.endVertex.toString(),
        'plannedStationCount': needs.length,
      },
    );
    return null;
  }
  final selectedOpaquePixels = solved.fold<int>(
    0,
    (total, item) =>
        total +
        (preflight.opaquePixelsByPrimitiveId[item.placement.primitiveId] ??
            _twoTierOpaquePixelCount(
              primitiveById[item.placement.primitiveId]!.publishedMetrics,
            )),
  );
  if (solved.length > stoneChainMaximumRowSamples ||
      selectedOpaquePixels > stoneChainMaximumRowOpaquePixels) {
    _addTwoTierGapDiagnostic(
      request: request,
      need: probeNeeds.first,
      code: gapCode,
      contact: null,
      backfillBudget: 0,
      attemptedBackfills: 0,
      observed: 'strict planned row exceeds true-mask limits',
      diagnostics: diagnostics,
      extraParameters: <String, Object?>{
        'preflight': true,
        'observedStationCount': solved.length,
        'expectedMaximumStationCount': stoneChainMaximumRowSamples,
        'observedMinimumOpaquePixels': selectedOpaquePixels,
        'expectedMaximumOpaquePixels': stoneChainMaximumRowOpaquePixels,
      },
    );
    return null;
  }
  return solved;
}

List<_GeneratedStonePlacement>? _solveTwoTierPlannedRunRow({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required List<_PlacementNeed> needs,
  required _TwoTierRowItem startBoundary,
  required _TwoTierRowItem endBoundary,
  required List<BorderPublishedPrimitive> primitives,
  required int targetOverlapPx,
  required int maximumOverlapPx,
  required Set<int> forbiddenJointCoordinates,
  required Map<String, BorderPublishedPrimitive> primitiveById,
  required List<_GeneratedStonePlacement>? attachmentRow,
}) {
  final representativeNeed = needs.isEmpty ? startBoundary.need : needs.first;
  final prioritizeRepetition = _hasExtendedTwoTierNativeVariantSet(
    need: representativeNeed,
    primitives: primitives,
  );
  final preparedMaskShapes = <(String, int, bool), Set<_TwoTierMaskPixel>>{};
  final preparedAttachmentMasks = attachmentRow == null
      ? null
      : <_TwoTierPreparedMask>[
          for (final placement in attachmentRow)
            _prepareTwoTierPlannedMask(
              placement: placement,
              primitive: primitiveById[placement.placement.primitiveId]!,
              cache: preparedMaskShapes,
            ),
        ];
  final startCandidates = _twoTierPlannedBoundaryCandidates(
    request: request,
    boundary: startBoundary,
    primitiveById: primitiveById,
    maximumOverlapPx: maximumOverlapPx,
    preparedMaskShapes: preparedMaskShapes,
    attachmentMasks: preparedAttachmentMasks,
  );
  final endCandidates = _twoTierPlannedBoundaryCandidates(
    request: request,
    boundary: endBoundary,
    primitiveById: primitiveById,
    maximumOverlapPx: maximumOverlapPx,
    preparedMaskShapes: preparedMaskShapes,
    attachmentMasks: preparedAttachmentMasks,
  );
  var currentCandidates = startCandidates;
  var previousCandidates = const <_TwoTierPlannedCandidate>[];
  var states = <_TwoTierPlannedRowState>[
    for (var index = 0; index < startCandidates.length; index += 1)
      _TwoTierPlannedRowState(
        currentItem: startCandidates[index].item,
        currentCandidateIndex: index,
        previousCandidateIndex: -1,
        previous: null,
        cost: _TwoTierPlannedRowCost(
          prioritizeRepetition: prioritizeRepetition,
        ).add(
          shiftCostPx: startCandidates[index].shiftPx,
          overlapDeviation: 0,
          jointAligned: false,
          repeatsPrevious: false,
          repeatedBlockReuses: 0,
          repeatsTwoBack: false,
          repeatsThreeBack: false,
          repeatsFourBack: false,
          authoredWeightPenalty: 0,
          preferred: true,
        ),
      ),
  ];
  for (final need in needs) {
    final preferredShift = prioritizeRepetition
        ? _twoTierPlannedIrregularityShift(
            request: request,
            revision: revision,
            need: need,
            maximumShiftPx: maximumOverlapPx,
          )
        : 0;
    final candidates = _twoTierPlannedCandidates(
      request: request,
      revision: revision,
      need: need,
      primitives: primitives,
      primitiveById: primitiveById,
      maximumShiftPx: maximumOverlapPx,
      attachmentRow: attachmentRow,
      attachmentMasks: preparedAttachmentMasks,
      preparedMaskShapes: preparedMaskShapes,
    );
    if (candidates.isEmpty) return null;
    final adjacent = _twoTierPlannedAdjacentTransitions(
      from: currentCandidates,
      to: candidates,
      targetOverlapPx: targetOverlapPx,
      maximumOverlapPx: maximumOverlapPx,
      forbiddenJointCoordinates: forbiddenJointCoordinates,
    );
    final nonAdjacent = previousCandidates.isEmpty
        ? null
        : _twoTierPlannedNonAdjacentCompatibility(
            from: previousCandidates,
            to: candidates,
            maximumOverlapPx: maximumOverlapPx,
            primitiveById: primitiveById,
          );
    final nextByKey = <int, _TwoTierPlannedRowState>{};
    for (final state in states) {
      for (final candidateIndex in adjacent[state.currentCandidateIndex].keys) {
        final candidate = candidates[candidateIndex];
        if (nonAdjacent != null &&
            !nonAdjacent[state.previousCandidateIndex][candidateIndex]) {
          continue;
        }
        final edge = adjacent[state.currentCandidateIndex][candidateIndex]!;
        final repeatsTwoBack = previousCandidates.isNotEmpty &&
            state.previousCandidateIndex >= 0 &&
            previousCandidates[state.previousCandidateIndex]
                    .item
                    .placement
                    .placement
                    .primitiveId ==
                candidate.item.placement.placement.primitiveId;
        final repeatsThreeBack = _twoTierPlannedHistoryPrimitiveId(
              state,
              distance: 3,
            ) ==
            candidate.item.placement.placement.primitiveId;
        final repeatsFourBack = _twoTierPlannedHistoryPrimitiveId(
              state,
              distance: 4,
            ) ==
            candidate.item.placement.placement.primitiveId;
        final repeatedBlockReuses = _twoTierPlannedRepeatedBlockReuses(
          state,
          candidate.item.placement.placement.primitiveId,
        );
        // With four or more native stones there is enough authored diversity
        // to reject a visible ABAB / ABCABC / ABCDABCD cadence outright. A
        // soft cost is not sufficient because histories that share the same
        // geometric tail can otherwise be merged by the bounded planner.
        if (prioritizeRepetition && repeatedBlockReuses > 0) continue;
        final transition = _TwoTierPlannedRowState(
          currentItem: candidate.item,
          currentCandidateIndex: candidateIndex,
          previousCandidateIndex: state.currentCandidateIndex,
          previous: state,
          cost: state.cost.add(
            shiftCostPx: candidate.shiftPx - preferredShift,
            overlapDeviation: edge.overlapDeviation,
            jointAligned: edge.jointAligned,
            repeatsPrevious: edge.repeatsPrevious,
            repeatedBlockReuses: repeatedBlockReuses,
            repeatsTwoBack: repeatsTwoBack,
            repeatsThreeBack: repeatsThreeBack,
            repeatsFourBack: repeatsFourBack,
            authoredWeightPenalty: candidate.authoredWeightPenalty,
            preferred: candidate.preferred,
          ),
        );
        final key =
            state.currentCandidateIndex * candidates.length + candidateIndex;
        final existing = nextByKey[key];
        if (existing == null || transition.cost.compareTo(existing.cost) < 0) {
          nextByKey[key] = transition;
        }
      }
    }
    // Dart maps preserve insertion order. Candidate and edge domains are
    // themselves total-ordered, so keeping the first equal-cost predecessor
    // is a deterministic induction without sorting or walking full histories.
    states = nextByKey.values.toList(growable: false);
    if (states.isEmpty) return null;
    previousCandidates = currentCandidates;
    currentCandidates = candidates;
  }

  final adjacent = _twoTierPlannedAdjacentTransitions(
    from: currentCandidates,
    to: endCandidates,
    targetOverlapPx: targetOverlapPx,
    maximumOverlapPx: maximumOverlapPx,
    forbiddenJointCoordinates: forbiddenJointCoordinates,
  );
  final nonAdjacent = previousCandidates.isEmpty
      ? null
      : _twoTierPlannedNonAdjacentCompatibility(
          from: previousCandidates,
          to: endCandidates,
          maximumOverlapPx: maximumOverlapPx,
          primitiveById: primitiveById,
        );
  final completedByKey = <int, _TwoTierPlannedRowState>{};
  for (final state in states) {
    for (final candidateIndex in adjacent[state.currentCandidateIndex].keys) {
      if (nonAdjacent != null &&
          !nonAdjacent[state.previousCandidateIndex][candidateIndex]) {
        continue;
      }
      final candidate = endCandidates[candidateIndex];
      final edge = adjacent[state.currentCandidateIndex][candidateIndex]!;
      final repeatsTwoBack = previousCandidates.isNotEmpty &&
          state.previousCandidateIndex >= 0 &&
          previousCandidates[state.previousCandidateIndex]
                  .item
                  .placement
                  .placement
                  .primitiveId ==
              candidate.item.placement.placement.primitiveId;
      final repeatsThreeBack = _twoTierPlannedHistoryPrimitiveId(
            state,
            distance: 3,
          ) ==
          candidate.item.placement.placement.primitiveId;
      final repeatsFourBack = _twoTierPlannedHistoryPrimitiveId(
            state,
            distance: 4,
          ) ==
          candidate.item.placement.placement.primitiveId;
      final repeatedBlockReuses = _twoTierPlannedRepeatedBlockReuses(
        state,
        candidate.item.placement.placement.primitiveId,
      );
      if (prioritizeRepetition && repeatedBlockReuses > 0) continue;
      final completed = _TwoTierPlannedRowState(
        currentItem: candidate.item,
        currentCandidateIndex: candidateIndex,
        previousCandidateIndex: state.currentCandidateIndex,
        previous: state,
        cost: state.cost.add(
          shiftCostPx: candidate.shiftPx,
          overlapDeviation: edge.overlapDeviation,
          jointAligned: edge.jointAligned,
          repeatsPrevious: edge.repeatsPrevious,
          repeatedBlockReuses: repeatedBlockReuses,
          repeatsTwoBack: repeatsTwoBack,
          repeatsThreeBack: repeatsThreeBack,
          repeatsFourBack: repeatsFourBack,
          authoredWeightPenalty: candidate.authoredWeightPenalty,
          preferred: true,
        ),
      );
      final key =
          state.currentCandidateIndex * endCandidates.length + candidateIndex;
      final existing = completedByKey[key];
      if (existing == null || completed.cost.compareTo(existing.cost) < 0) {
        completedByKey[key] = completed;
      }
    }
  }
  final completed = completedByKey.values.toList(growable: false);
  if (completed.isEmpty) return null;
  var best = completed.first;
  for (var index = 1; index < completed.length; index += 1) {
    if (completed[index].cost.compareTo(best.cost) < 0) {
      best = completed[index];
    }
  }
  final reversed = <_GeneratedStonePlacement>[];
  _TwoTierPlannedRowState? state = best;
  while (state != null) {
    reversed.add(state.currentItem.placement);
    state = state.previous;
  }
  return reversed.reversed.toList(growable: false);
}

int _twoTierPlannedIrregularityShift({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed need,
  required int maximumShiftPx,
}) {
  final irregularity =
      (request.feature.paramsOverride ?? revision.definition.defaults)
          .irregularityPermille;
  if (irregularity <= 0 || maximumShiftPx <= 0 || need.isSpecial) return 0;
  final amplitude = _minimum(
    maximumShiftPx,
    _minimum(2, (4 * irregularity + 999) ~/ 1000),
  );
  if (amplitude <= 0) return 0;
  return BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
        const BorderRngKeyComponent.text(
          'two-tier-planned-tangent-irregularity',
        ),
        BorderRngKeyComponent.text(request.blueprintId),
        BorderRngKeyComponent.signedInt64(
          BorderSignedInt64.fromInt(revision.revision),
        ),
        BorderRngKeyComponent.signedInt64(request.feature.seed),
        BorderRngKeyComponent.text(need.deterministicSlotKey),
      ]).nextIndex(amplitude * 2 + 1) -
      amplitude;
}

String? _twoTierPlannedHistoryPrimitiveId(
  _TwoTierPlannedRowState state, {
  required int distance,
}) {
  _TwoTierPlannedRowState? cursor = state;
  for (var step = 1; step < distance; step += 1) {
    cursor = cursor?.previous;
  }
  return cursor?.currentItem.placement.placement.primitiveId;
}

int _twoTierPlannedRepeatedBlockReuses(
  _TwoTierPlannedRowState state,
  String candidatePrimitiveId,
) {
  final reversed = <String>[candidatePrimitiveId];
  _TwoTierPlannedRowState? cursor = state;
  while (cursor != null && reversed.length < 8) {
    reversed.add(cursor.currentItem.placement.placement.primitiveId);
    cursor = cursor.previous;
  }
  final ids = reversed.reversed.toList(growable: false);
  var repeatedBlocks = 0;
  for (var blockLength = 2; blockLength <= 4; blockLength += 1) {
    if (ids.length < blockLength * 2) continue;
    var same = true;
    final firstStart = ids.length - blockLength * 2;
    final secondStart = ids.length - blockLength;
    for (var offset = 0; offset < blockLength; offset += 1) {
      if (ids[firstStart + offset] != ids[secondStart + offset]) {
        same = false;
        break;
      }
    }
    if (same) repeatedBlocks += 1;
  }
  return repeatedBlocks;
}

bool _hasExtendedTwoTierNativeVariantSet({
  required _PlacementNeed need,
  required List<BorderPublishedPrimitive> primitives,
}) {
  final desired = _cardinalDirectionForVector(need.normalX, need.normalY);
  var nativeCandidateCount = 0;
  for (final primitive in primitives) {
    final quarterTurns = _quarterTurnsForOrientation(
      authored: primitive.authoredOrientation,
      desired: desired,
      allowAutoRotation: false,
      allowedQuarterTurns: primitive.transforms.allowedQuarterTurns,
    );
    if (quarterTurns != 0) continue;
    nativeCandidateCount += 1;
    if (nativeCandidateCount >= 4) return true;
  }
  return false;
}

List<Map<int, _TwoTierPlannedEdge>> _twoTierPlannedAdjacentTransitions({
  required List<_TwoTierPlannedCandidate> from,
  required List<_TwoTierPlannedCandidate> to,
  required int targetOverlapPx,
  required int maximumOverlapPx,
  required Set<int> forbiddenJointCoordinates,
}) =>
    <Map<int, _TwoTierPlannedEdge>>[
      for (final first in from)
        <int, _TwoTierPlannedEdge>{
          for (var secondIndex = 0; secondIndex < to.length; secondIndex += 1)
            if (_twoTierPlannedEdge(
              first: first.item,
              second: to[secondIndex].item,
              firstMask: first.preparedMask,
              secondMask: to[secondIndex].preparedMask,
              targetOverlapPx: targetOverlapPx,
              maximumOverlapPx: maximumOverlapPx,
              forbiddenJointCoordinates: forbiddenJointCoordinates,
            )
                case final edge?)
              secondIndex: edge,
        },
    ];

_TwoTierPlannedEdge? _twoTierPlannedEdge({
  required _TwoTierRowItem first,
  required _TwoTierRowItem second,
  required _TwoTierPreparedMask firstMask,
  required _TwoTierPreparedMask secondMask,
  required int targetOverlapPx,
  required int maximumOverlapPx,
  required Set<int> forbiddenJointCoordinates,
}) {
  final firstProjection =
      first.need.targetAnchorWorldPx.x * second.need.tangentX +
          first.need.targetAnchorWorldPx.y * second.need.tangentY;
  final secondProjection =
      second.need.targetAnchorWorldPx.x * second.need.tangentX +
          second.need.targetAnchorWorldPx.y * second.need.tangentY;
  if (secondProjection < firstProjection) return null;
  final contact = _measureTwoTierPlannedBoundsContact(
    first: first.placement.placement.opaqueWorldBoundsPx,
    second: second.placement.placement.opaqueWorldBoundsPx,
    tangentX: second.need.tangentX,
    tangentY: second.need.tangentY,
    normalX: second.need.normalX,
    normalY: second.need.normalY,
  );
  if (!_isValidTwoTierContact(
        contact,
        maximumOverlapPx: maximumOverlapPx,
      ) ||
      !_twoTierPreparedMasksTouch(firstMask, secondMask)) {
    return null;
  }
  return _TwoTierPlannedEdge(
    overlapDeviation: (contact.tangentOverlapPx - targetOverlapPx).abs(),
    jointAligned: _twoTierJointConflictsWithTolerance(
      forbiddenJointCoordinates,
      _twoTierJointCoordinate(first.placement, second.placement),
    ),
    repeatsPrevious: first.placement.placement.primitiveId ==
        second.placement.placement.primitiveId,
  );
}

bool _twoTierJointConflictsWithTolerance(
  Set<int> forbiddenJointCoordinates,
  int jointCoordinate,
) {
  for (var delta = -2; delta <= 2; delta += 1) {
    if (forbiddenJointCoordinates.contains(jointCoordinate + delta)) {
      return true;
    }
  }
  return false;
}

List<List<bool>> _twoTierPlannedNonAdjacentCompatibility({
  required List<_TwoTierPlannedCandidate> from,
  required List<_TwoTierPlannedCandidate> to,
  required int maximumOverlapPx,
  required Map<String, BorderPublishedPrimitive> primitiveById,
}) =>
    <List<bool>>[
      for (final first in from)
        <bool>[
          for (final second in to)
            _twoTierPlannedNonAdjacentPairIsValid(
              first: first.item,
              second: second.item,
              firstMask: first.preparedMask,
              secondMask: second.preparedMask,
              maximumOverlapPx: maximumOverlapPx,
              primitiveById: primitiveById,
            ),
        ],
    ];

bool _twoTierPlannedNonAdjacentPairIsValid({
  required _TwoTierRowItem first,
  required _TwoTierRowItem second,
  required _TwoTierPreparedMask firstMask,
  required _TwoTierPreparedMask secondMask,
  required int maximumOverlapPx,
  required Map<String, BorderPublishedPrimitive> primitiveById,
}) {
  final boundsContact = _measureTwoTierPlannedBoundsContact(
    first: first.placement.placement.opaqueWorldBoundsPx,
    second: second.placement.placement.opaqueWorldBoundsPx,
    tangentX: second.need.tangentX,
    tangentY: second.need.tangentY,
    normalX: second.need.normalX,
    normalY: second.need.normalY,
  );
  if (boundsContact.tangentOverlapPx <= maximumOverlapPx) return true;
  return _twoTierPreparedOpaqueIntersectionPixels(firstMask, secondMask) == 0;
}

StoneChainContactMetrics _measureTwoTierPlannedBoundsContact({
  required BorderPixelRect first,
  required BorderPixelRect second,
  required int tangentX,
  required int tangentY,
  required int normalX,
  required int normalY,
}) {
  final firstTangentMinimum =
      _minimumProjection(first, dx: tangentX, dy: tangentY);
  final firstTangentMaximum =
      _maximumProjection(first, dx: tangentX, dy: tangentY);
  final secondTangentMinimum =
      _minimumProjection(second, dx: tangentX, dy: tangentY);
  final secondTangentMaximum =
      _maximumProjection(second, dx: tangentX, dy: tangentY);
  final firstNormalMinimum =
      _minimumProjection(first, dx: normalX, dy: normalY);
  final firstNormalMaximum =
      _maximumProjection(first, dx: normalX, dy: normalY);
  final secondNormalMinimum =
      _minimumProjection(second, dx: normalX, dy: normalY);
  final secondNormalMaximum =
      _maximumProjection(second, dx: normalX, dy: normalY);
  return StoneChainContactMetrics(
    projectedGapPx: _twoTierPlannedProjectedGap(
      firstTangentMinimum,
      firstTangentMaximum,
      secondTangentMinimum,
      secondTangentMaximum,
    ),
    tangentOverlapPx: _twoTierPlannedProjectedOverlap(
      firstTangentMinimum,
      firstTangentMaximum,
      secondTangentMinimum,
      secondTangentMaximum,
    ),
    normalOverlapPx: _twoTierPlannedProjectedOverlap(
      firstNormalMinimum,
      firstNormalMaximum,
      secondNormalMinimum,
      secondNormalMaximum,
    ),
    opaqueIntersectionPixels: 0,
  );
}

int _twoTierPlannedProjectedGap(
  int firstMinimum,
  int firstMaximum,
  int secondMinimum,
  int secondMaximum,
) {
  if (firstMaximum < secondMinimum) {
    return secondMinimum - firstMaximum - 1;
  }
  if (secondMaximum < firstMinimum) {
    return firstMinimum - secondMaximum - 1;
  }
  return 0;
}

int _twoTierPlannedProjectedOverlap(
  int firstMinimum,
  int firstMaximum,
  int secondMinimum,
  int secondMaximum,
) {
  final start = _maximum(firstMinimum, secondMinimum);
  final end = _minimum(firstMaximum, secondMaximum);
  return end < start ? 0 : end - start + 1;
}

_TwoTierPreparedMask _prepareTwoTierPlannedMask({
  required _GeneratedStonePlacement placement,
  required BorderPublishedPrimitive primitive,
  required Map<(String, int, bool), Set<_TwoTierMaskPixel>> cache,
}) {
  final transform = placement.placement.transform;
  final key = (primitive.id, transform.quarterTurns, transform.flipX);
  final pixels = cache.putIfAbsent(key, () {
    final metrics = primitive.publishedMetrics;
    final width = metrics.pixelSize.width;
    final height = metrics.pixelSize.height;
    final result = <_TwoTierMaskPixel>{};
    visitBorderRleTrueRuns(
      metrics.occupancyMaskRle,
      expectedLength: checkedBorderRleCellCount(
        width: width,
        height: height,
        path: r'$.publishedMetrics.pixelSize',
      ),
      path: r'$.publishedMetrics.occupancyMaskRle',
      visitor: (start, end) {
        for (var index = start; index < end; index += 1) {
          final sourceX = index % width;
          final sourceY = index ~/ width;
          final flippedX = transform.flipX ? width - 1 - sourceX : sourceX;
          result.add(
            switch (transform.quarterTurns) {
              0 => (x: flippedX, y: sourceY),
              1 => (x: height - 1 - sourceY, y: flippedX),
              2 => (
                  x: width - 1 - flippedX,
                  y: height - 1 - sourceY,
                ),
              3 => (x: sourceY, y: width - 1 - flippedX),
              _ => throw const ValidationException(
                  'Border quarterTurns must be between 0 and 3',
                ),
            },
          );
        }
      },
    );
    return Set<_TwoTierMaskPixel>.unmodifiable(result);
  });
  return _TwoTierPreparedMask(
    pixels: pixels,
    topLeftWorldPx: placement.placement.topLeftWorldPx,
    bounds: placement.placement.opaqueWorldBoundsPx,
  );
}

int _twoTierPreparedOpaqueIntersectionPixels(
  _TwoTierPreparedMask first,
  _TwoTierPreparedMask second,
) {
  if (!_twoTierPlannedBoundsIntersect(first.bounds, second.bounds)) return 0;
  final iterateFirst = first.pixels.length <= second.pixels.length;
  final source = iterateFirst ? first : second;
  final target = iterateFirst ? second : first;
  var intersections = 0;
  for (final pixel in source.pixels) {
    final targetPixel = (
      x: source.topLeftWorldPx.x + pixel.x - target.topLeftWorldPx.x,
      y: source.topLeftWorldPx.y + pixel.y - target.topLeftWorldPx.y,
    );
    if (target.pixels.contains(targetPixel)) intersections += 1;
  }
  return intersections;
}

int _twoTierPreparedMaskComponentCount(Set<_TwoTierMaskPixel> pixels) {
  final remaining = Set<_TwoTierMaskPixel>.of(pixels);
  final pending = <_TwoTierMaskPixel>[];
  var components = 0;
  while (remaining.isNotEmpty) {
    components += 1;
    pending.add(remaining.first);
    while (pending.isNotEmpty) {
      final pixel = pending.removeLast();
      if (!remaining.remove(pixel)) continue;
      for (final neighbor in <_TwoTierMaskPixel>[
        (x: pixel.x - 1, y: pixel.y),
        (x: pixel.x + 1, y: pixel.y),
        (x: pixel.x, y: pixel.y - 1),
        (x: pixel.x, y: pixel.y + 1),
      ]) {
        if (remaining.contains(neighbor)) pending.add(neighbor);
      }
    }
  }
  return components;
}

bool _twoTierPreparedMasksTouch(
  _TwoTierPreparedMask first,
  _TwoTierPreparedMask second,
) {
  if (first.bounds.right < second.bounds.x ||
      second.bounds.right < first.bounds.x ||
      first.bounds.bottom < second.bounds.y ||
      second.bounds.bottom < first.bounds.y) {
    return false;
  }
  final iterateFirst = first.pixels.length <= second.pixels.length;
  final source = iterateFirst ? first : second;
  final target = iterateFirst ? second : first;
  for (final pixel in source.pixels) {
    final targetX = source.topLeftWorldPx.x + pixel.x - target.topLeftWorldPx.x;
    final targetY = source.topLeftWorldPx.y + pixel.y - target.topLeftWorldPx.y;
    if (target.pixels.contains((x: targetX, y: targetY)) ||
        target.pixels.contains((x: targetX - 1, y: targetY)) ||
        target.pixels.contains((x: targetX + 1, y: targetY)) ||
        target.pixels.contains((x: targetX, y: targetY - 1)) ||
        target.pixels.contains((x: targetX, y: targetY + 1))) {
      return true;
    }
  }
  return false;
}

bool _twoTierPlannedBoundsIntersect(
  BorderPixelRect first,
  BorderPixelRect second,
) =>
    first.x < second.right &&
    second.x < first.right &&
    first.y < second.bottom &&
    second.y < first.bottom;

List<_TwoTierPlannedCandidate> _twoTierPlannedBoundaryCandidates({
  required BorderResolutionRequest request,
  required _TwoTierRowItem boundary,
  required Map<String, BorderPublishedPrimitive> primitiveById,
  required int maximumOverlapPx,
  required Map<(String, int, bool), Set<_TwoTierMaskPixel>> preparedMaskShapes,
  required List<_TwoTierPreparedMask>? attachmentMasks,
}) {
  final primitive = primitiveById[boundary.placement.placement.primitiveId]!;
  final deltas = _isMovableTwoTierEndpointNeed(boundary.need)
      ? <int>[
          0,
          for (var magnitude = 1;
              magnitude <= maximumOverlapPx;
              magnitude += 1) ...<int>[magnitude, -magnitude],
        ]
      : const <int>[0];
  final result = <_TwoTierPlannedCandidate>[];
  for (final delta in deltas) {
    final need = boundary.need.offsetAnchorAlongTangent(
      request: request,
      delta: delta,
    );
    final build = _buildPlacement(
      request: request,
      need: need,
      selected: primitive,
      quarterTurns: boundary.placement.placement.transform.quarterTurns,
    );
    if (build is! _PlacementBuildAccepted) continue;
    final preparedMask = _prepareTwoTierPlannedMask(
      placement: build.placement,
      primitive: primitive,
      cache: preparedMaskShapes,
    );
    if (attachmentMasks != null &&
        !_twoTierPreparedFaceAttaches(
          face: preparedMask,
          lips: attachmentMasks,
        )) {
      continue;
    }
    result.add(
      _TwoTierPlannedCandidate(
        item: _TwoTierRowItem(need: need, placement: build.placement),
        shiftPx: delta,
        preferred: true,
        authoredWeightPenalty: 0,
        preparedMask: preparedMask,
      ),
    );
  }
  return result;
}

List<_TwoTierPlannedCandidate> _twoTierPlannedCandidates({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed need,
  required List<BorderPublishedPrimitive> primitives,
  required Map<String, BorderPublishedPrimitive> primitiveById,
  required int maximumShiftPx,
  required List<_GeneratedStonePlacement>? attachmentRow,
  required List<_TwoTierPreparedMask>? attachmentMasks,
  required Map<(String, int, bool), Set<_TwoTierMaskPixel>> preparedMaskShapes,
}) {
  final parameters =
      request.feature.paramsOverride ?? revision.definition.defaults;
  final desired = _cardinalDirectionForVector(need.normalX, need.normalY);
  final oriented = <({BorderPublishedPrimitive primitive, int quarterTurns})>[];
  for (final primitive in primitives) {
    final quarterTurns = _quarterTurnsForOrientation(
      authored: primitive.authoredOrientation,
      desired: desired,
      allowAutoRotation: parameters.allowAutoRotation,
      allowedQuarterTurns: primitive.transforms.allowedQuarterTurns,
    );
    if (quarterTurns != null) {
      oriented.add((primitive: primitive, quarterTurns: quarterTurns));
    }
  }
  if (oriented.isEmpty) return const <_TwoTierPlannedCandidate>[];
  final preferred = _choosePrimitive(
    request: request,
    revision: revision,
    slotKey: need.deterministicSlotKey,
    candidates: oriented.map((candidate) => candidate.primitive).toList(),
    variationPermille: parameters.variationPermille,
    avoidedPrimitiveId: null,
  );
  // The native-orientation domain is the complete rotation-off fallback for
  // the shared strict plan. Add only the deterministic preferred rotated
  // candidate: this lets the rotation-on profile exercise rotation without
  // arbitrarily dropping, or exhaustively multiplying, equivalent fallbacks.
  final plannedOriented = _selectTwoTierPlannedOrientedCandidates(
    request: request,
    revision: revision,
    need: need,
    oriented: oriented,
    preferred: preferred,
  );
  final candidates = <_TwoTierPlannedCandidate>[];
  for (final delta in <int>[
    0,
    for (var magnitude = 1;
        magnitude <= maximumShiftPx;
        magnitude += 1) ...<int>[magnitude, -magnitude],
  ]) {
    final shifted = need.offsetAnchorAlongTangent(
      request: request,
      delta: delta,
    );
    for (final orientedPrimitive in plannedOriented) {
      final build = _buildPlacement(
        request: request,
        need: shifted,
        selected: orientedPrimitive.primitive,
        quarterTurns: orientedPrimitive.quarterTurns,
      );
      if (build is! _PlacementBuildAccepted) continue;
      final item = _TwoTierRowItem(
        need: shifted,
        placement: build.placement,
      );
      final preparedMask = _prepareTwoTierPlannedMask(
        placement: build.placement,
        primitive: orientedPrimitive.primitive,
        cache: preparedMaskShapes,
      );
      if (attachmentRow != null &&
          !_twoTierPreparedFaceAttaches(
            face: preparedMask,
            lips: attachmentMasks!,
          )) {
        continue;
      }
      candidates.add(
        _TwoTierPlannedCandidate(
          item: item,
          shiftPx: delta,
          preferred: orientedPrimitive.primitive.id == preferred.id,
          authoredWeightPenalty: 1000 - orientedPrimitive.primitive.weight,
          preparedMask: preparedMask,
        ),
      );
    }
  }
  candidates.sort((left, right) {
    var result = left.shiftPx.abs().compareTo(right.shiftPx.abs());
    if (result != 0) return result;
    result = (left.preferred ? 0 : 1).compareTo(right.preferred ? 0 : 1);
    if (result != 0) return result;
    result = left.item.placement.placement.primitiveId
        .compareTo(right.item.placement.placement.primitiveId);
    if (result != 0) return result;
    result = left.item.placement.placement.transform.quarterTurns.compareTo(
      right.item.placement.placement.transform.quarterTurns,
    );
    return result != 0 ? result : left.shiftPx.compareTo(right.shiftPx);
  });
  return candidates;
}

List<({BorderPublishedPrimitive primitive, int quarterTurns})>
    _selectTwoTierPlannedOrientedCandidates({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed need,
  required List<({BorderPublishedPrimitive primitive, int quarterTurns})>
      oriented,
  required BorderPublishedPrimitive preferred,
}) {
  final native = oriented
      .where((candidate) => candidate.quarterTurns == 0)
      .toList(growable: false);
  final selectedNativeIds = <String>{};
  final preferredIsNative = native.any(
    (candidate) => candidate.primitive.id == preferred.id,
  );
  if (preferredIsNative) selectedNativeIds.add(preferred.id);

  if (native.isNotEmpty) {
    var widest = native.first.primitive;
    for (final candidate in native.skip(1)) {
      final candidateSpan = _authoredTangentSpanPx(candidate.primitive);
      final widestSpan = _authoredTangentSpanPx(widest);
      if (candidateSpan > widestSpan ||
          (candidateSpan == widestSpan &&
              candidate.primitive.id.compareTo(widest.id) < 0)) {
        widest = candidate.primitive;
      }
    }
    // The widest native stone is the topology bridge for compact catalogues.
    // Keep it available even when its deliberately rare weight means it was
    // not the station's preferred texture.
    selectedNativeIds.add(widest.id);
  }

  final rankedNative = native.toList(growable: false)
    ..sort((left, right) {
      BigInt rank(BorderPublishedPrimitive primitive) =>
          BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
            const BorderRngKeyComponent.text(
              'stone-chain-planner-native-subset',
            ),
            BorderRngKeyComponent.text(request.blueprintId),
            BorderRngKeyComponent.signedInt64(
              BorderSignedInt64.fromInt(revision.revision),
            ),
            BorderRngKeyComponent.signedInt64(request.feature.seed),
            BorderRngKeyComponent.text(need.deterministicSlotKey),
            BorderRngKeyComponent.text(primitive.id),
          ]).nextUint64();

      final byRank = rank(left.primitive).compareTo(rank(right.primitive));
      return byRank != 0
          ? byRank
          : left.primitive.id.compareTo(right.primitive.id);
    });
  for (final candidate in rankedNative) {
    if (selectedNativeIds.length >=
        _maximumTwoTierPlannedNativeVariantsPerNeed) {
      break;
    }
    selectedNativeIds.add(candidate.primitive.id);
  }

  return <({BorderPublishedPrimitive primitive, int quarterTurns})>[
    for (final candidate in oriented)
      if ((candidate.quarterTurns == 0 &&
              selectedNativeIds.contains(candidate.primitive.id)) ||
          (candidate.quarterTurns != 0 &&
              candidate.primitive.id == preferred.id))
        candidate,
  ];
}

bool _twoTierPreparedFaceAttaches({
  required _TwoTierPreparedMask face,
  required List<_TwoTierPreparedMask> lips,
}) {
  for (final lip in lips) {
    if (!_twoTierPlannedBoundsIntersect(lip.bounds, face.bounds)) continue;
    if (_twoTierPreparedOpaqueIntersectionPixels(lip, face) >=
        _minimumTwoTierCrossRowInterlockPixels) {
      return true;
    }
  }
  return false;
}

({
  _PlacementNeed need,
  _TwoTierPlacementSelection selection,
}) _selectTwoTierRunPlacement({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed need,
  required List<BorderPublishedPrimitive> primitives,
  required _GeneratedStonePlacement? previous,
  required List<String> recentPrimitiveIds,
  required int targetOverlapPx,
  required int maximumOverlapPx,
  required _StoneCollisionIndex collisionIndex,
  required Set<int> forbiddenJointCoordinates,
  required Map<String, BorderPublishedPrimitive> primitiveById,
}) {
  _TwoTierPlacementSelection? latest;
  ({
    _PlacementNeed need,
    _TwoTierPlacementSelection selection
  })? duplicateFallback;
  for (final delta in <int>[
    0,
    for (var magnitude = 1;
        magnitude <= maximumOverlapPx;
        magnitude += 1) ...<int>[magnitude, -magnitude],
  ]) {
    final shifted = need.offsetAnchorAlongTangent(
      request: request,
      delta: delta,
    );
    final selection = _selectTwoTierRowPlacement(
      request: request,
      revision: revision,
      need: shifted,
      primitives: primitives,
      previous: previous,
      recentPrimitiveIds: recentPrimitiveIds,
      targetOverlapPx: targetOverlapPx,
      maximumOverlapPx: maximumOverlapPx,
      collisionIndex: collisionIndex,
      forbiddenJointCoordinates: forbiddenJointCoordinates,
      primitiveById: primitiveById,
    );
    latest = selection;
    if (selection.placement != null) {
      if (recentPrimitiveIds.contains(
        selection.placement!.placement.primitiveId,
      )) {
        duplicateFallback ??= (need: shifted, selection: selection);
        continue;
      }
      return (need: shifted, selection: selection);
    }
  }
  if (duplicateFallback != null) return duplicateFallback;
  return (need: need, selection: latest!);
}

void _validateTwoTierTopologyRun({
  required BorderResolutionRequest request,
  required BorderGenerationParams parameters,
  required _TwoTierTopologyRunRows rows,
  required Map<String, BorderPublishedPrimitive> primitiveById,
  required List<BorderDiagnostic> diagnostics,
}) {
  final sideSign = request.feature.lineSide == BorderLineSide.primary ? 1 : -1;
  final tangent = StoneChainAxis(
    dx: rows.run.directionX,
    dy: rows.run.directionY,
  );
  final normal = StoneChainAxis(
    dx: -rows.run.directionY * sideSign,
    dy: rows.run.directionX * sideSign,
  );
  void validateRow(
    List<_GeneratedStonePlacement> row,
    String code,
  ) {
    final ordered = row.toList(growable: false);
    final continuity = measureStoneChainRowContinuity(
      samples: <StoneChainRowSample>[
        for (var index = 0; index < ordered.length; index += 1)
          StoneChainRowSample(
            strokeId: rows.run.path.strokeId,
            slotKey: ordered[index].placement.slotKey,
            pathDistancePx: index,
            closed: false,
            mask: _twoTierPlacedMask(
              ordered[index],
              primitiveById[ordered[index].placement.primitiveId]!,
            ),
          ),
      ],
      tangent: tangent,
      normal: normal,
    );
    if (continuity.maximumGapPx == 0 &&
        continuity.connectedComponentCount == 1 &&
        continuity.minimumOverlapPx >= 2 &&
        continuity.maximumOverlapPx <= parameters.maxOverlapPx) {
      return;
    }
    diagnostics.add(
      _error(
        request,
        code: code,
        scope: BorderDiagnosticScope.segment,
        strokeId: rows.run.path.strokeId,
        cell: rows.run.startVertex,
        parameters: <String, Object?>{
          'slotKey': ordered.first.placement.slotKey,
          'runStart': rows.run.startVertex.toString(),
          'runEnd': rows.run.endVertex.toString(),
          'observedGapPx': continuity.maximumGapPx,
          'observedMinimumOverlapPx': continuity.minimumOverlapPx,
          'observedMaximumOverlapPx': continuity.maximumOverlapPx,
          'observedConnectedComponents': continuity.connectedComponentCount,
          'expectedGapPx': 0,
          'expectedMinimumOverlapPx': 2,
          'expectedMaximumOverlapPx': parameters.maxOverlapPx,
          'expectedConnectedComponents': 1,
        },
        action: 'border.action.adjust_stone_chain_row_spacing',
      ),
    );
  }

  validateRow(rows.lips, 'border.resolution.stone_chain_lip_gap');
  validateRow(rows.faces, 'border.resolution.stone_chain_face_gap');
  if (_hasErrors(diagnostics)) return;

  final lipIndex = _StoneCollisionIndex(
    bucketSizePx: _maximum(
      request.tileSizePx.width,
      request.tileSizePx.height,
    ),
  );
  for (final lip in rows.lips) {
    lipIndex.add(lip);
  }
  for (final face in rows.faces) {
    final facePrimitive = primitiveById[face.placement.primitiveId]!;
    final attachedLips = <_GeneratedStonePlacement>[];
    // A face only needs the bounded broad-phase neighborhood of its own run.
    // Scanning the complete lip row here would turn a long coast into O(n²).
    for (final lip in lipIndex.candidatesFor(face)) {
      final contact = measureStoneChainContact(
        first: _twoTierPlacedMask(face, facePrimitive),
        second: _twoTierPlacedMask(
          lip,
          primitiveById[lip.placement.primitiveId]!,
        ),
        tangent: tangent,
        normal: normal,
      );
      if (contact.opaqueIntersectionPixels > 0) attachedLips.add(lip);
    }
    if (attachedLips.isEmpty) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.stone_chain_face_detached',
          scope: BorderDiagnosticScope.segment,
          strokeId: rows.run.path.strokeId,
          cell: face.placement.anchorCell,
          parameters: <String, Object?>{
            'slotKey': face.placement.slotKey,
            'runStart': rows.run.startVertex.toString(),
            'runEnd': rows.run.endVertex.toString(),
            'observed': 0,
            'expected': 1,
          },
          action: 'border.action.move_stone_chain_face_toward_lip',
        ),
      );
      continue;
    }
    final lipFront = attachedLips
        .map(
          (lip) => _maximumProjection(
            lip.placement.opaqueWorldBoundsPx,
            dx: normal.dx,
            dy: normal.dy,
          ),
        )
        .reduce(_maximum);
    final visibleDepthPx = _maximumProjection(
          face.placement.opaqueWorldBoundsPx,
          dx: normal.dx,
          dy: normal.dy,
        ) -
        lipFront;
    if (visibleDepthPx < 12) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.stone_chain_face_depth_insufficient',
          scope: BorderDiagnosticScope.segment,
          strokeId: rows.run.path.strokeId,
          cell: face.placement.anchorCell,
          parameters: <String, Object?>{
            'slotKey': face.placement.slotKey,
            'runStart': rows.run.startVertex.toString(),
            'runEnd': rows.run.endVertex.toString(),
            'observedDepthPx': visibleDepthPx,
            'expectedDepthPx': 12,
          },
          action: 'border.action.publish_deeper_stone_chain_face',
        ),
      );
    }
  }
}

void _validateTwoTierTopologyJunctions({
  required BorderResolutionRequest request,
  required _TwoTierTopologyPlan plan,
  required _TwoTierTopologyReservations reservations,
  required Map<String, BorderPublishedPrimitive> primitiveById,
  required List<BorderDiagnostic> diagnostics,
}) {
  int componentCount(List<_GeneratedStonePlacement> placements) =>
      measureStoneChainRowContinuity(
        samples: <StoneChainRowSample>[
          for (var index = 0; index < placements.length; index += 1)
            StoneChainRowSample(
              strokeId: '${plan.path.strokeId}:junction:$index',
              slotKey: placements[index].placement.slotKey,
              pathDistancePx: 0,
              closed: false,
              mask: _twoTierPlacedMask(
                placements[index],
                primitiveById[placements[index].placement.primitiveId]!,
              ),
            ),
        ],
        tangent: StoneChainAxis(dx: 1, dy: 0),
        normal: StoneChainAxis(dx: 0, dy: 1),
      ).connectedComponentCount;

  for (final turn in plan.turns) {
    final lipSlot = buildBorderStoneChainNodeSlotKey(
      featureId: request.feature.id,
      strokeId: plan.path.lineageId,
      vertex: turn.vertex,
      passIndex: 0,
      role: BorderPrimitiveRole.lineCorner,
      rank: 0,
    );
    final faceSlots = <String>[
      for (final rank in const <int>[0, 1])
        buildBorderStoneChainNodeSlotKey(
          featureId: request.feature.id,
          strokeId: plan.path.lineageId,
          vertex: turn.vertex,
          passIndex: 1,
          role: BorderPrimitiveRole.structureMedium,
          rank: rank,
        ),
    ];
    final lip = reservations.lipItems[lipSlot]!.placement;
    final faces = <_GeneratedStonePlacement>[
      for (final slot in faceSlots) reservations.faceItems[slot]!.placement,
    ];
    final faceComponents = componentCount(faces);
    if (faceComponents != 1) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.stone_chain_face_gap',
          scope: BorderDiagnosticScope.segment,
          strokeId: plan.path.strokeId,
          cell: turn.vertex,
          parameters: <String, Object?>{
            'slotKey': faceSlots.first,
            'observedConnectedComponents': faceComponents,
            'expectedConnectedComponents': 1,
            'junction': turn.vertex.toString(),
          },
          action: 'border.action.adjust_stone_chain_row_spacing',
        ),
      );
      continue;
    }
    final combinedComponents = componentCount(<_GeneratedStonePlacement>[
      lip,
      ...faces,
    ]);
    if (combinedComponents != 1) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.stone_chain_face_detached',
          scope: BorderDiagnosticScope.segment,
          strokeId: plan.path.strokeId,
          cell: turn.vertex,
          parameters: <String, Object?>{
            'slotKey': faceSlots.first,
            'observedConnectedComponents': combinedComponents,
            'expectedConnectedComponents': 1,
            'junction': turn.vertex.toString(),
          },
          action: 'border.action.move_stone_chain_face_toward_lip',
        ),
      );
    }
  }
}

int _maximumTopologyRunGap(List<_TwoTierTopologyRunRows> rows) {
  var maximum = 0;
  for (final runRows in rows) {
    for (final row in <List<_GeneratedStonePlacement>>[
      runRows.lips,
      runRows.faces,
    ]) {
      // Closure emits the linked row in canonical path order. Preserve that
      // O(n) sequence here instead of re-sorting every run for evidence.
      for (var index = 1; index < row.length; index += 1) {
        maximum = _maximum(
          maximum,
          _opaqueRectGap(
            row[index - 1].placement.opaqueWorldBoundsPx,
            row[index].placement.opaqueWorldBoundsPx,
          ),
        );
      }
    }
  }
  return maximum;
}

List<_PlacementNeed> _buildLipNeeds({
  required BorderResolutionRequest request,
  required _StonePath path,
  required BorderGenerationParams parameters,
}) {
  return _buildTwoTierRowNeeds(
    request: request,
    path: path,
    role: BorderPrimitiveRole.structureLarge,
    passIndex: 0,
    drawBand: BorderDrawBand.structure,
    quantumPx: _twoTierStructuralQuantumPx(
      primitives: request.blueprintRevision!.definition.primitives,
      maximumOverlapPx: parameters.maxOverlapPx,
    ),
  );
}

List<_PlacementNeed> _buildFaceNeeds({
  required BorderResolutionRequest request,
  required _StonePath path,
  required BorderGenerationParams parameters,
}) {
  return _buildTwoTierRowNeeds(
    request: request,
    path: path,
    role: BorderPrimitiveRole.structureMedium,
    passIndex: 1,
    drawBand: BorderDrawBand.outerAccent,
    quantumPx: _twoTierStructuralQuantumPx(
      primitives: request.blueprintRevision!.definition.primitives,
      maximumOverlapPx: parameters.maxOverlapPx,
    ),
  );
}

List<_GeneratedStonePlacement> _withTwoTierStraightEndpointSlots({
  required BorderResolutionRequest request,
  required _StonePath path,
  required List<_GeneratedStonePlacement> placements,
  required int passIndex,
  required BorderPrimitiveRole role,
  required int rank,
}) {
  if (path.closed || placements.length < 2) return placements;
  final authoredStartIsCanonical = _gridPosComesFirst(
    path.points.first,
    path.points.last,
  );
  final canonicalStart =
      authoredStartIsCanonical ? path.points.first : path.points.last;
  final canonicalEnd =
      authoredStartIsCanonical ? path.points.last : path.points.first;
  final result = placements.toList(growable: false);
  result[0] = _withTwoTierStraightEndpointSlot(
    request: request,
    path: path,
    placement: result[0],
    vertex: canonicalStart,
    passIndex: passIndex,
    role: role,
    rank: rank,
  );
  result[result.length - 1] = _withTwoTierStraightEndpointSlot(
    request: request,
    path: path,
    placement: result.last,
    vertex: canonicalEnd,
    passIndex: passIndex,
    role: role,
    rank: rank,
  );
  return result;
}

_GeneratedStonePlacement _withTwoTierStraightEndpointSlot({
  required BorderResolutionRequest request,
  required _StonePath path,
  required _GeneratedStonePlacement placement,
  required GridPos vertex,
  required int passIndex,
  required BorderPrimitiveRole role,
  required int rank,
}) {
  final source = placement.placement;
  final slotKey = buildBorderStoneChainNodeSlotKey(
    featureId: request.feature.id,
    strokeId: path.lineageId,
    vertex: vertex,
    passIndex: passIndex,
    role: role,
    rank: rank,
  );
  final order = source.stableOrderKey;
  return _GeneratedStonePlacement(
    placement: BorderResolvedPlacement(
      id: 'border-placement-v1:'
          '${slotKey.substring(borderSlotKeyV1Prefix.length)}',
      slotKey: slotKey,
      primitiveId: source.primitiveId,
      visualSnapshotId: source.visualSnapshotId,
      anchorCell: source.anchorCell,
      topLeftWorldPx: source.topLeftWorldPx,
      opaqueWorldBoundsPx: source.opaqueWorldBoundsPx,
      transform: source.transform,
      drawBand: source.drawBand,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: order.drawBandIndex,
        anchorRowMajor: order.anchorRowMajor,
        passIndex: order.passIndex,
        rank: 0,
        ordinalLocal: order.ordinalLocal,
        slotKey: slotKey,
      ),
    ),
    semanticRole: role,
    strokeId: placement.strokeId,
    pathDistance: placement.pathDistance,
    tangentX: placement.tangentX,
    tangentY: placement.tangentY,
    pathClosed: placement.pathClosed,
    isPrimary: placement.isPrimary,
    isSpecial: true,
  );
}

int _twoTierStructuralQuantumPx({
  required List<BorderPublishedPrimitive> primitives,
  required int maximumOverlapPx,
}) {
  final lipPrimitives = primitives
      .where(
        (primitive) =>
            primitive.role == BorderPrimitiveRole.structureLarge &&
            primitive.weight > 0,
      )
      .toList(growable: false);
  final facePrimitives = primitives
      .where(
        (primitive) =>
            primitive.role == BorderPrimitiveRole.structureMedium &&
            primitive.weight > 0,
      )
      .toList(growable: false);
  if (lipPrimitives.isEmpty || facePrimitives.isEmpty) {
    throw StateError('Two-tier structural cadence requires both rows.');
  }
  // Both rows own independent stations, but a shared geometry-derived cadence
  // keeps their populations comparable. Their opposing phases still stagger
  // the masonry joints, while the larger natural quantum prevents the shorter
  // face sprites from silently creating a denser structural tier.
  return _maximum(
    _twoTierQuantumPx(
      primitives: lipPrimitives,
      maximumOverlapPx: maximumOverlapPx,
    ),
    _twoTierQuantumPx(
      primitives: facePrimitives,
      maximumOverlapPx: maximumOverlapPx,
    ),
  );
}

int _twoTierTargetOverlapPx({
  required List<BorderPublishedPrimitive> primitives,
  required int maximumOverlapPx,
}) {
  final minimumTangentSpanPx =
      primitives.map(_authoredTangentSpanPx).reduce(_minimum);
  return _minimum(
    maximumOverlapPx,
    _maximum(2, minimumTangentSpanPx ~/ 3),
  );
}

int _twoTierQuantumPx({
  required List<BorderPublishedPrimitive> primitives,
  required int maximumOverlapPx,
}) {
  final minimumTangentSpanPx =
      primitives.map(_authoredTangentSpanPx).reduce(_minimum);
  final targetOverlapPx = _minimum(
    maximumOverlapPx,
    _maximum(2, minimumTangentSpanPx ~/ 3),
  );
  return _maximum(1, minimumTangentSpanPx - targetOverlapPx);
}

int _authoredTangentSpanPx(BorderPublishedPrimitive primitive) {
  final bounds = primitive.publishedMetrics.opaqueBounds;
  return switch (primitive.authoredOrientation) {
    BorderPrimitiveOrientation.north ||
    BorderPrimitiveOrientation.south =>
      bounds.width,
    BorderPrimitiveOrientation.east ||
    BorderPrimitiveOrientation.west =>
      bounds.height,
    BorderPrimitiveOrientation.legacyAxis =>
      _maximum(bounds.width, bounds.height),
  };
}

List<_PlacementNeed> _buildTwoTierRowNeeds({
  required BorderResolutionRequest request,
  required _StonePath path,
  required BorderPrimitiveRole role,
  required int passIndex,
  required BorderDrawBand drawBand,
  required int quantumPx,
}) {
  final canonicalDistances = _twoTierCanonicalDistances(
    totalLengthPx: path.totalLengthPx,
    quantumPx: quantumPx,
    closed: path.closed,
    phasePx: passIndex == 0 ? quantumPx ~/ 2 : 0,
  );
  final result = <_PlacementNeed>[];
  for (var index = 0; index < canonicalDistances.length; index += 1) {
    final canonicalDistance = canonicalDistances[index];
    result.add(
      _buildTwoTierDistanceNeed(
        request: request,
        path: path,
        stationOrdinal: index,
        canonicalDistancePx: canonicalDistance,
        passIndex: passIndex,
        role: role,
        rank: 0,
        drawBand: drawBand,
      ),
    );
  }
  result.sort((left, right) {
    final byCanonicalDistance =
        left.stableOrdinal.compareTo(right.stableOrdinal);
    return byCanonicalDistance != 0
        ? byCanonicalDistance
        : left.slotKey.compareTo(right.slotKey);
  });
  return result;
}

_PlacementNeed _buildTwoTierDistanceNeed({
  required BorderResolutionRequest request,
  required _StonePath path,
  required int stationOrdinal,
  required int canonicalDistancePx,
  required int passIndex,
  required BorderPrimitiveRole role,
  required int rank,
  required BorderDrawBand drawBand,
}) {
  final authoredStartIsCanonical = _gridPosComesFirst(
    path.points.first,
    path.points.last,
  );
  final traversalDistance = path.closed || authoredStartIsCanonical
      ? canonicalDistancePx
      : path.totalLengthPx - canonicalDistancePx;
  final sample = path.sampleAtDistance(traversalDistance);
  final tangentX = path.closed || authoredStartIsCanonical
      ? sample.tangentX
      : -sample.tangentX;
  final tangentY = path.closed || authoredStartIsCanonical
      ? sample.tangentY
      : -sample.tangentY;
  final sideSign = request.feature.lineSide == BorderLineSide.primary ? 1 : -1;
  final normalX = -sample.tangentY * sideSign;
  final normalY = sample.tangentX * sideSign;
  final normalOffset = _maximum(
    1,
    _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 8,
  );
  final target = BorderPixelPos(
    x: sample.worldX + normalX * normalOffset,
    y: sample.worldY + normalY * normalOffset,
  );
  return _PlacementNeed(
    featureId: request.feature.id,
    path: path,
    distance: canonicalDistancePx,
    stationOrdinal: stationOrdinal,
    semanticRole: role,
    passIndex: passIndex,
    tangentX: tangentX,
    tangentY: tangentY,
    normalX: normalX,
    normalY: normalY,
    targetAnchorWorldPx: target,
    anchorCell: _anchorCell(request, target),
    slotKey: buildBorderStoneChainDistanceSlotKey(
      featureId: request.feature.id,
      strokeId: path.lineageId,
      runStart: path.points.first,
      runEnd: path.points.last,
      canonicalDistancePx: canonicalDistancePx,
      passIndex: passIndex,
      role: role,
      rank: rank,
    ),
    isSpecial: false,
    isPrimary: passIndex == 0,
    drawBand: drawBand,
    stableOrderOrdinal: canonicalDistancePx,
    slotRunStart: path.points.first,
    slotRunEnd: path.points.last,
    slotStationOffsetPx: canonicalDistancePx,
    slotGenerationEdgeIndex: 0,
  );
}

List<int> _twoTierCanonicalDistances({
  required int totalLengthPx,
  required int quantumPx,
  required bool closed,
  required int phasePx,
}) {
  if (closed) {
    final count = (totalLengthPx + quantumPx - 1) ~/ quantumPx;
    return <int>[
      for (var index = 0; index < count; index += 1)
        (phasePx + (index * totalLengthPx) ~/ count) % totalLengthPx,
    ];
  }
  final result = <int>[
    for (var distance = phasePx;
        distance < totalLengthPx;
        distance += quantumPx)
      distance,
  ];
  if (result.isEmpty && totalLengthPx > 0) result.add(totalLengthPx ~/ 2);
  return result;
}

bool _gridPosComesFirst(GridPos first, GridPos second) =>
    first.y < second.y || (first.y == second.y && first.x <= second.x);

_TwoTierRowPreflight? _preflightTwoTierRow({
  required BorderResolutionRequest request,
  required List<_PlacementNeed> needs,
  required List<BorderPublishedPrimitive> primitives,
  required String gapCode,
  required List<BorderDiagnostic> diagnostics,
}) {
  if (needs.isEmpty) {
    return const _TwoTierRowPreflight(
      primitives: <BorderPublishedPrimitive>[],
      opaquePixelsByPrimitiveId: <String, int>{},
      minimumOpaquePixelsPerPlacement: 0,
    );
  }
  final need = needs.first;
  final parameters = request.feature.paramsOverride ??
      request.blueprintRevision!.definition.defaults;
  final desired = _cardinalDirectionForVector(need.normalX, need.normalY);
  final oriented = <BorderPublishedPrimitive>[];
  final opaquePixelsByPrimitiveId = <String, int>{};
  for (final primitive in primitives) {
    final quarterTurns = _quarterTurnsForOrientation(
      authored: primitive.authoredOrientation,
      desired: desired,
      allowAutoRotation: parameters.allowAutoRotation,
      allowedQuarterTurns: primitive.transforms.allowedQuarterTurns,
    );
    if (quarterTurns == null) continue;
    oriented.add(primitive);
    opaquePixelsByPrimitiveId[primitive.id] =
        _twoTierOpaquePixelCount(primitive.publishedMetrics);
  }
  if (oriented.isEmpty) {
    return _TwoTierRowPreflight(
      primitives: primitives,
      opaquePixelsByPrimitiveId: opaquePixelsByPrimitiveId,
      minimumOpaquePixelsPerPlacement: 0,
    );
  }
  final minimumOpaquePixelsPerPlacement = oriented
      .map((primitive) => opaquePixelsByPrimitiveId[primitive.id]!)
      .reduce(_minimum);
  final minimumRowOpaquePixels = minimumOpaquePixelsPerPlacement * needs.length;
  final exceedsLimits = needs.length > stoneChainMaximumRowSamples ||
      minimumOpaquePixelsPerPlacement > stoneChainMaximumOpaquePixelsPerMask ||
      minimumRowOpaquePixels > stoneChainMaximumRowOpaquePixels;
  if (exceedsLimits) {
    _addTwoTierGapDiagnostic(
      request: request,
      need: need,
      code: gapCode,
      contact: null,
      backfillBudget: (need.path.totalLengthPx + 1) ~/ 2,
      attemptedBackfills: 0,
      observed: 'row exceeds true-mask preflight limits',
      diagnostics: diagnostics,
      extraParameters: <String, Object?>{
        'preflight': true,
        'observedStationCount': needs.length,
        'expectedMaximumStationCount': stoneChainMaximumRowSamples,
        'observedMinimumOpaquePixels': minimumRowOpaquePixels,
        'expectedMaximumOpaquePixels': stoneChainMaximumRowOpaquePixels,
        'observedMinimumOpaquePixelsPerMask': minimumOpaquePixelsPerPlacement,
        'expectedMaximumOpaquePixelsPerMask':
            stoneChainMaximumOpaquePixelsPerMask,
      },
    );
    return null;
  }
  final safePrimitives = oriented
      .where(
        (primitive) =>
            opaquePixelsByPrimitiveId[primitive.id]! <=
            stoneChainMaximumOpaquePixelsPerMask,
      )
      .toList(growable: false);
  return _TwoTierRowPreflight(
    primitives: safePrimitives,
    opaquePixelsByPrimitiveId: opaquePixelsByPrimitiveId,
    minimumOpaquePixelsPerPlacement: minimumOpaquePixelsPerPlacement,
  );
}

int _twoTierOpaquePixelCount(BorderPrimitiveAssetMetrics metrics) {
  var result = 0;
  visitBorderRleTrueRuns(
    metrics.occupancyMaskRle,
    expectedLength: checkedBorderRleCellCount(
      width: metrics.pixelSize.width,
      height: metrics.pixelSize.height,
      path: r'$.publishedMetrics.pixelSize',
    ),
    path: r'$.publishedMetrics.occupancyMaskRle',
    visitor: (start, end) => result += end - start,
  );
  return result;
}

List<_GeneratedStonePlacement>? _materializeTwoTierRow({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required List<_PlacementNeed> needs,
  required List<BorderPublishedPrimitive> primitives,
  required int targetOverlapPx,
  required _StoneCollisionIndex collisionIndex,
  required List<BorderDiagnostic> diagnostics,
  required String gapCode,
  Set<int> forbiddenJointCoordinates = const <int>{},
}) {
  final preflight = _preflightTwoTierRow(
    request: request,
    needs: needs,
    primitives: primitives,
    gapCode: gapCode,
    diagnostics: diagnostics,
  );
  if (preflight == null) return null;
  final rowPrimitives =
      preflight.primitives.isEmpty ? primitives : preflight.primitives;
  final items = <_TwoTierRowItem>[];
  final primitiveById = <String, BorderPublishedPrimitive>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      primitive.id: primitive,
  };
  var selectedOpaquePixels = 0;
  for (final need in needs) {
    final recentPrimitiveIds = items.reversed
        .take(_twoTierRecentPrimitiveMemory)
        .map((item) => item.placement.placement.primitiveId)
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    final selection = _selectTwoTierRowPlacement(
      request: request,
      revision: revision,
      need: need,
      primitives: rowPrimitives,
      previous: items.isEmpty ? null : items.last.placement,
      recentPrimitiveIds: recentPrimitiveIds,
      targetOverlapPx: targetOverlapPx,
      maximumOverlapPx:
          (request.feature.paramsOverride ?? revision.definition.defaults)
              .maxOverlapPx,
      collisionIndex: collisionIndex,
      forbiddenJointCoordinates: forbiddenJointCoordinates,
      primitiveById: primitiveById,
    );
    final selected = selection.placement;
    if (selected == null) {
      if (!selection.hasOrientedCandidate) {
        _addTwoTierOrientationDiagnostic(
          request: request,
          need: need,
          diagnostics: diagnostics,
        );
      } else {
        _addTwoTierGapDiagnostic(
          request: request,
          need: need,
          code: gapCode,
          contact: selection.observedContact,
          backfillBudget: (need.path.totalLengthPx + 1) ~/ 2,
          attemptedBackfills: 0,
          observed: 'no buildable station candidate',
          diagnostics: diagnostics,
        );
      }
      return null;
    }
    selectedOpaquePixels += preflight
            .opaquePixelsByPrimitiveId[selected.placement.primitiveId] ??
        _twoTierOpaquePixelCount(
            primitiveById[selected.placement.primitiveId]!.publishedMetrics);
    if (selectedOpaquePixels > stoneChainMaximumRowOpaquePixels) {
      _addTwoTierGapDiagnostic(
        request: request,
        need: need,
        code: gapCode,
        contact: selection.observedContact,
        backfillBudget: (need.path.totalLengthPx + 1) ~/ 2,
        attemptedBackfills: 0,
        observed: 'selected row exceeds true-mask pixel limit',
        diagnostics: diagnostics,
        extraParameters: <String, Object?>{
          'preflight': true,
          'observedStationCount': items.length + 1,
          'expectedMaximumStationCount': stoneChainMaximumRowSamples,
          'observedMinimumOpaquePixels': selectedOpaquePixels,
          'expectedMaximumOpaquePixels': stoneChainMaximumRowOpaquePixels,
        },
      );
      return null;
    }
    items.add(_TwoTierRowItem(need: need, placement: selected));
    collisionIndex.add(selected);
  }
  return _closeTwoTierRow(
    request: request,
    revision: revision,
    items: items,
    primitives: rowPrimitives,
    targetOverlapPx: targetOverlapPx,
    maximumOverlapPx:
        (request.feature.paramsOverride ?? revision.definition.defaults)
            .maxOverlapPx,
    collisionIndex: collisionIndex,
    forbiddenJointCoordinates: forbiddenJointCoordinates,
    gapCode: gapCode,
    diagnostics: diagnostics,
    initialOpaquePixels: selectedOpaquePixels,
    opaquePixelsByPrimitiveId: preflight.opaquePixelsByPrimitiveId,
    minimumOpaquePixelsPerPlacement: preflight.minimumOpaquePixelsPerPlacement,
  );
}

_TwoTierPlacementSelection _selectTwoTierRowPlacement({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed need,
  required List<BorderPublishedPrimitive> primitives,
  required _GeneratedStonePlacement? previous,
  required List<String> recentPrimitiveIds,
  required int targetOverlapPx,
  required int maximumOverlapPx,
  required _StoneCollisionIndex collisionIndex,
  required Set<int> forbiddenJointCoordinates,
  required Map<String, BorderPublishedPrimitive> primitiveById,
}) {
  final desired = _cardinalDirectionForVector(need.normalX, need.normalY);
  final parameters =
      request.feature.paramsOverride ?? revision.definition.defaults;
  final oriented = <({BorderPublishedPrimitive primitive, int quarterTurns})>[];
  for (final primitive in primitives) {
    final quarterTurns = _quarterTurnsForOrientation(
      authored: primitive.authoredOrientation,
      desired: desired,
      allowAutoRotation: parameters.allowAutoRotation,
      allowedQuarterTurns: primitive.transforms.allowedQuarterTurns,
    );
    if (quarterTurns != null) {
      oriented.add((primitive: primitive, quarterTurns: quarterTurns));
    }
  }
  if (oriented.isEmpty) {
    return const _TwoTierPlacementSelection(
      placement: null,
      hasOrientedCandidate: false,
      observedContact: null,
    );
  }
  final preferred = _choosePrimitive(
    request: request,
    revision: revision,
    slotKey: need.deterministicSlotKey,
    candidates: oriented.map((candidate) => candidate.primitive).toList(),
    variationPermille: parameters.variationPermille,
    avoidedPrimitiveId: previous?.placement.primitiveId,
  );
  final prioritizeRepetition =
      oriented.where((candidate) => candidate.quarterTurns == 0).length >= 4;
  final candidates = <_TwoTierPlacementCandidate>[];
  StoneChainContactMetrics? observedContact;
  for (final candidate in oriented) {
    final build = _buildPlacement(
      request: request,
      need: need,
      selected: candidate.primitive,
      quarterTurns: candidate.quarterTurns,
    );
    if (build is! _PlacementBuildAccepted) continue;
    final placement = build.placement;
    final contact = previous == null
        ? null
        : _measureTwoTierContact(
            first: previous,
            second: placement,
            firstPrimitive:
                request.blueprintRevision!.definition.primitives.firstWhere(
              (primitive) => primitive.id == previous.placement.primitiveId,
            ),
            secondPrimitive: candidate.primitive,
            normalX: need.normalX,
            normalY: need.normalY,
          );
    observedContact = _preferMeasuredTwoTierContact(
      observedContact,
      contact,
      targetOverlapPx: targetOverlapPx,
    );
    if (_exceedsTwoTierMaskOverlapBudget(
      placement: placement,
      primitive: candidate.primitive,
      collisionIndex: collisionIndex,
      primitiveById: primitiveById,
      normalX: need.normalX,
      normalY: need.normalY,
      budget: maximumOverlapPx,
    )) {
      continue;
    }
    final jointCoordinate =
        previous == null ? null : _twoTierJointCoordinate(previous, placement);
    candidates.add(
      _TwoTierPlacementCandidate(
        placement: placement,
        contact: contact,
        jointAligned: jointCoordinate != null &&
            forbiddenJointCoordinates.contains(jointCoordinate),
        preferred: candidate.primitive.id == preferred.id,
        recentReusePenalty: _recentPrimitiveReusePenalty(
          recentPrimitiveIds,
          candidate.primitive.id,
        ),
        repeatedBlockPenalty: _repeatedPrimitiveBlockPenalty(
          recentPrimitiveIds,
          candidate.primitive.id,
        ),
        shiftPx: 0,
      ),
    );
  }
  candidates.sort(
    (left, right) => _compareTwoTierCandidates(
      left,
      right,
      targetOverlapPx: targetOverlapPx,
      maximumOverlapPx: maximumOverlapPx,
      prioritizeRepetition: prioritizeRepetition,
    ),
  );
  if (candidates.isEmpty) {
    return _TwoTierPlacementSelection(
      placement: null,
      hasOrientedCandidate: true,
      observedContact: observedContact,
    );
  }
  final selected = candidates.first;
  return _TwoTierPlacementSelection(
    placement: selected.placement,
    hasOrientedCandidate: true,
    observedContact: selected.contact ?? observedContact,
  );
}

StoneChainContactMetrics? _preferMeasuredTwoTierContact(
  StoneChainContactMetrics? current,
  StoneChainContactMetrics? candidate, {
  required int targetOverlapPx,
}) {
  if (candidate == null) return current;
  if (current == null) return candidate;
  final byGap = candidate.projectedGapPx.compareTo(current.projectedGapPx);
  if (byGap < 0) return candidate;
  if (byGap > 0) return current;
  final candidateDeviation =
      (candidate.tangentOverlapPx - targetOverlapPx).abs();
  final currentDeviation = (current.tangentOverlapPx - targetOverlapPx).abs();
  return candidateDeviation < currentDeviation ? candidate : current;
}

bool _isValidTwoTierContact(
  StoneChainContactMetrics contact, {
  required int maximumOverlapPx,
}) =>
    contact.projectedGapPx == 0 &&
    contact.tangentOverlapPx >= 2 &&
    contact.tangentOverlapPx <= maximumOverlapPx;

List<_GeneratedStonePlacement>? _closeTwoTierRow({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required List<_TwoTierRowItem> items,
  required List<BorderPublishedPrimitive> primitives,
  required int targetOverlapPx,
  required int maximumOverlapPx,
  required _StoneCollisionIndex collisionIndex,
  required Set<int> forbiddenJointCoordinates,
  required String gapCode,
  required List<BorderDiagnostic> diagnostics,
  required int initialOpaquePixels,
  required Map<String, int> opaquePixelsByPrimitiveId,
  required int minimumOpaquePixelsPerPlacement,
  bool? closesSeam,
  int? backfillSpanPx,
  _PlacementNeed Function(int pathDistancePx, int rank)? buildBackfillNeed,
}) {
  if (items.length < 2) {
    return items.map((item) => item.placement).toList(growable: false);
  }
  final primitiveById = <String, BorderPublishedPrimitive>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      primitive.id: primitive,
  };
  final path = items.first.need.path;
  final effectiveClosesSeam = closesSeam ?? path.closed;
  final effectiveBackfillSpanPx = backfillSpanPx ?? path.totalLengthPx;
  final backfillBudget = (effectiveBackfillSpanPx + 1) ~/ 2;
  final remainingSampleCapacity =
      _maximum(0, stoneChainMaximumRowSamples - items.length);
  final remainingOpaqueCapacity =
      _maximum(0, stoneChainMaximumRowOpaquePixels - initialOpaquePixels);
  final opaqueBackfillCapacity = minimumOpaquePixelsPerPlacement <= 0
      ? 0
      : remainingOpaqueCapacity ~/ minimumOpaquePixelsPerPlacement;
  final effectiveBackfillBudget = _minimum(
    backfillBudget,
    _minimum(remainingSampleCapacity, opaqueBackfillCapacity),
  );
  var attemptedBackfills = 0;
  var totalOpaquePixels = initialOpaquePixels;
  final slotKeys = <String>{for (final item in items) item.need.slotKey};
  final nodes = <_TwoTierRowNode>[
    for (final item in items) _TwoTierRowNode(item),
  ];
  for (var index = 1; index < nodes.length; index += 1) {
    nodes[index - 1].next = nodes[index];
    nodes[index].previous = nodes[index - 1];
  }
  final head = nodes.first;
  if (effectiveClosesSeam) {
    head.previous = nodes.last;
    nodes.last.next = head;
  }
  final pendingJoints = Queue<_TwoTierRowNode>();
  pendingJoints.addAll(nodes.skip(1));
  if (effectiveClosesSeam) pendingJoints.add(head);

  while (pendingJoints.isNotEmpty) {
    final secondNode = pendingJoints.removeFirst();
    final firstNode = secondNode.previous;
    if (firstNode == null) continue;
    final first = firstNode.item;
    final second = secondNode.item;
    final contact = _measureTwoTierContact(
      first: first.placement,
      second: second.placement,
      firstPrimitive: primitiveById[first.placement.placement.primitiveId]!,
      secondPrimitive: primitiveById[second.placement.placement.primitiveId]!,
      normalX: second.need.normalX,
      normalY: second.need.normalY,
    );
    if (_isValidTwoTierContact(
      contact,
      maximumOverlapPx: maximumOverlapPx,
    )) {
      continue;
    }

    final shifted =
        second.need.isSpecial && !_isMovableTwoTierEndpointNeed(second.need)
            ? null
            : _shiftTwoTierSecondTowardFirst(
                request: request,
                first: first,
                second: second,
                primitiveById: primitiveById,
                maximumOverlapPx: maximumOverlapPx,
                collisionIndex: collisionIndex,
              );
    if (shifted != null) {
      secondNode.item = shifted;
      continue;
    }

    final shiftedFirst = first.need.isSpecial
        ? null
        : _shiftTwoTierFirstTowardSecond(
            request: request,
            previous: firstNode.previous?.item,
            first: first,
            second: second,
            primitiveById: primitiveById,
            maximumOverlapPx: maximumOverlapPx,
            collisionIndex: collisionIndex,
          );
    if (shiftedFirst != null) {
      firstNode.item = shiftedFirst;
      continue;
    }

    final closesThisSeam = effectiveClosesSeam && identical(secondNode, head);
    final midpointCanonicalDistance = closesThisSeam
        ? ((first.need.distance + second.need.distance + path.totalLengthPx) ~/
                2) %
            path.totalLengthPx
        : (first.need.distance + second.need.distance) ~/ 2;
    final backfillNeed = buildBackfillNeed?.call(
          midpointCanonicalDistance,
          1,
        ) ??
        _buildTwoTierDistanceNeed(
          request: request,
          path: path,
          stationOrdinal: items.length + attemptedBackfills,
          canonicalDistancePx: midpointCanonicalDistance,
          passIndex: second.need.passIndex,
          role: second.need.semanticRole,
          rank: 1,
          drawBand: second.need.drawBand,
        );
    final jointParameters = <String, Object?>{
      'jointStartCanonicalDistancePx': first.need.distance,
      'jointEndCanonicalDistancePx': second.need.distance,
      'midpointCanonicalDistancePx': midpointCanonicalDistance,
    };
    if (midpointCanonicalDistance == first.need.distance ||
        midpointCanonicalDistance == second.need.distance) {
      _addTwoTierGapDiagnostic(
        request: request,
        need: backfillNeed,
        code: gapCode,
        contact: contact,
        backfillBudget: backfillBudget,
        attemptedBackfills: attemptedBackfills,
        observed: 'no distinct canonical midpoint remains',
        diagnostics: diagnostics,
        extraParameters: jointParameters,
      );
      return null;
    }
    if (attemptedBackfills >= effectiveBackfillBudget) {
      _addTwoTierGapDiagnostic(
        request: request,
        need: backfillNeed,
        code: gapCode,
        contact: contact,
        backfillBudget: backfillBudget,
        attemptedBackfills: attemptedBackfills,
        observed: effectiveBackfillBudget < backfillBudget
            ? 'row preflight capacity exhausted before midpoint budget'
            : 'midpoint backfill budget exhausted',
        diagnostics: diagnostics,
        extraParameters: <String, Object?>{
          ...jointParameters,
          'preflight': effectiveBackfillBudget < backfillBudget,
          'effectiveBackfillBudget': effectiveBackfillBudget,
          'expectedMaximumStationCount': stoneChainMaximumRowSamples,
          'expectedMaximumOpaquePixels': stoneChainMaximumRowOpaquePixels,
        },
      );
      return null;
    }
    if (!slotKeys.add(backfillNeed.slotKey)) {
      _addTwoTierGapDiagnostic(
        request: request,
        need: backfillNeed,
        code: gapCode,
        contact: contact,
        backfillBudget: backfillBudget,
        attemptedBackfills: attemptedBackfills,
        observed: 'canonical midpoint was already attempted',
        diagnostics: diagnostics,
        extraParameters: jointParameters,
      );
      return null;
    }
    attemptedBackfills += 1;
    final shiftedSelection = _selectTwoTierRunPlacement(
      request: request,
      revision: revision,
      need: backfillNeed,
      primitives: primitives,
      previous: first.placement,
      recentPrimitiveIds: <String>[
        first.placement.placement.primitiveId,
        second.placement.placement.primitiveId,
      ],
      targetOverlapPx: targetOverlapPx,
      maximumOverlapPx: maximumOverlapPx,
      collisionIndex: collisionIndex,
      forbiddenJointCoordinates: forbiddenJointCoordinates,
      primitiveById: primitiveById,
    );
    var selection = shiftedSelection.selection;
    var resolvedBackfillNeed = shiftedSelection.need;
    var backfill = selection.placement;
    if (backfill == null) {
      final adjusted = _fitTwoTierBackfillByOpeningJoint(
        request: request,
        revision: revision,
        previous: firstNode.previous?.item,
        first: first,
        second: second,
        backfillNeed: backfillNeed,
        primitives: primitives,
        targetOverlapPx: targetOverlapPx,
        maximumOverlapPx: maximumOverlapPx,
        collisionIndex: collisionIndex,
        forbiddenJointCoordinates: forbiddenJointCoordinates,
        primitiveById: primitiveById,
      );
      if (adjusted != null) {
        firstNode.item = adjusted.first;
        resolvedBackfillNeed = adjusted.backfillNeed;
        backfill = adjusted.backfill;
        selection = _TwoTierPlacementSelection(
          placement: backfill,
          hasOrientedCandidate: true,
          observedContact: null,
        );
      }
    }
    if (backfill == null) {
      if (!selection.hasOrientedCandidate) {
        _addTwoTierOrientationDiagnostic(
          request: request,
          need: backfillNeed,
          diagnostics: diagnostics,
        );
      } else {
        _addTwoTierGapDiagnostic(
          request: request,
          need: backfillNeed,
          code: gapCode,
          contact: contact,
          backfillBudget: backfillBudget,
          attemptedBackfills: attemptedBackfills,
          observed: 'no buildable midpoint backfill candidate',
          diagnostics: diagnostics,
          extraParameters: jointParameters,
        );
      }
      return null;
    }
    final backfillOpaquePixels =
        opaquePixelsByPrimitiveId[backfill.placement.primitiveId] ??
            _twoTierOpaquePixelCount(
              primitiveById[backfill.placement.primitiveId]!.publishedMetrics,
            );
    if (totalOpaquePixels + backfillOpaquePixels >
            stoneChainMaximumRowOpaquePixels ||
        items.length + attemptedBackfills > stoneChainMaximumRowSamples) {
      _addTwoTierGapDiagnostic(
        request: request,
        need: backfillNeed,
        code: gapCode,
        contact: contact,
        backfillBudget: backfillBudget,
        attemptedBackfills: attemptedBackfills,
        observed: 'midpoint backfill exceeds true-mask row limits',
        diagnostics: diagnostics,
        extraParameters: <String, Object?>{
          ...jointParameters,
          'preflight': true,
          'observedStationCount': items.length + attemptedBackfills,
          'expectedMaximumStationCount': stoneChainMaximumRowSamples,
          'observedMinimumOpaquePixels':
              totalOpaquePixels + backfillOpaquePixels,
          'expectedMaximumOpaquePixels': stoneChainMaximumRowOpaquePixels,
        },
      );
      return null;
    }
    totalOpaquePixels += backfillOpaquePixels;
    final backfillItem = _TwoTierRowItem(
      need: resolvedBackfillNeed,
      placement: backfill,
    );
    final backfillNode = _TwoTierRowNode(backfillItem)
      ..previous = firstNode
      ..next = secondNode;
    firstNode.next = backfillNode;
    secondNode.previous = backfillNode;
    collisionIndex.add(backfill);
    // Depth-first joint processing keeps each original joint and each of the
    // two joints created by a backfill in the queue at most once.
    pendingJoints.addFirst(secondNode);
    pendingJoints.addFirst(backfillNode);
  }

  final result = <_GeneratedStonePlacement>[];
  _TwoTierRowNode? node = head;
  do {
    result.add(node!.item.placement);
    node = node.next;
  } while (node != null && !identical(node, head));
  return result;
}

bool _isMovableTwoTierEndpointNeed(_PlacementNeed need) =>
    need.semanticRole == BorderPrimitiveRole.lineCap ||
    (need.passIndex == 1 && need.stationOrdinal == 2);

({
  _TwoTierRowItem first,
  _PlacementNeed backfillNeed,
  _GeneratedStonePlacement backfill,
})? _fitTwoTierBackfillByOpeningJoint({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _TwoTierRowItem? previous,
  required _TwoTierRowItem first,
  required _TwoTierRowItem second,
  required _PlacementNeed backfillNeed,
  required List<BorderPublishedPrimitive> primitives,
  required int targetOverlapPx,
  required int maximumOverlapPx,
  required _StoneCollisionIndex collisionIndex,
  required Set<int> forbiddenJointCoordinates,
  required Map<String, BorderPublishedPrimitive> primitiveById,
}) {
  if (first.need.isSpecial) return null;
  final primitive = primitiveById[first.placement.placement.primitiveId]!;
  collisionIndex.remove(first.placement);
  for (var adjustment = 1; adjustment <= maximumOverlapPx; adjustment += 1) {
    final shiftedNeed = first.need.shiftAlongTangent(
      request: request,
      delta: -adjustment,
    );
    final build = _buildPlacement(
      request: request,
      need: shiftedNeed,
      selected: primitive,
      quarterTurns: first.placement.placement.transform.quarterTurns,
    );
    if (build is! _PlacementBuildAccepted) continue;
    final shiftedPlacement = build.placement;
    if (_exceedsTwoTierMaskOverlapBudget(
      placement: shiftedPlacement,
      primitive: primitive,
      collisionIndex: collisionIndex,
      primitiveById: primitiveById,
      normalX: shiftedNeed.normalX,
      normalY: shiftedNeed.normalY,
      budget: maximumOverlapPx,
    )) {
      continue;
    }
    if (previous != null) {
      final previousContact = _measureTwoTierContact(
        first: previous.placement,
        second: shiftedPlacement,
        firstPrimitive:
            primitiveById[previous.placement.placement.primitiveId]!,
        secondPrimitive: primitive,
        normalX: shiftedNeed.normalX,
        normalY: shiftedNeed.normalY,
      );
      if (!_isValidTwoTierContact(
        previousContact,
        maximumOverlapPx: maximumOverlapPx,
      )) {
        continue;
      }
    }
    collisionIndex.add(shiftedPlacement);
    final shiftedSelection = _selectTwoTierRunPlacement(
      request: request,
      revision: revision,
      need: backfillNeed,
      primitives: primitives,
      previous: shiftedPlacement,
      recentPrimitiveIds: <String>[
        shiftedPlacement.placement.primitiveId,
        second.placement.placement.primitiveId,
      ],
      targetOverlapPx: targetOverlapPx,
      maximumOverlapPx: maximumOverlapPx,
      collisionIndex: collisionIndex,
      forbiddenJointCoordinates: forbiddenJointCoordinates,
      primitiveById: primitiveById,
    );
    final candidate = shiftedSelection.selection.placement;
    if (candidate != null) {
      final nextContact = _measureTwoTierContact(
        first: candidate,
        second: second.placement,
        firstPrimitive: primitiveById[candidate.placement.primitiveId]!,
        secondPrimitive: primitiveById[second.placement.placement.primitiveId]!,
        normalX: second.need.normalX,
        normalY: second.need.normalY,
      );
      if (_isValidTwoTierContact(
        nextContact,
        maximumOverlapPx: maximumOverlapPx,
      )) {
        return (
          first: _TwoTierRowItem(
            need: shiftedNeed,
            placement: shiftedPlacement,
          ),
          backfillNeed: shiftedSelection.need,
          backfill: candidate,
        );
      }
    }
    collisionIndex.remove(shiftedPlacement);
  }
  collisionIndex.add(first.placement);
  return null;
}

_TwoTierRowItem? _shiftTwoTierFirstTowardSecond({
  required BorderResolutionRequest request,
  required _TwoTierRowItem? previous,
  required _TwoTierRowItem first,
  required _TwoTierRowItem second,
  required Map<String, BorderPublishedPrimitive> primitiveById,
  required int maximumOverlapPx,
  required _StoneCollisionIndex collisionIndex,
}) {
  final primitive = primitiveById[first.placement.placement.primitiveId]!;
  collisionIndex.remove(first.placement);
  for (var shift = 1; shift <= maximumOverlapPx; shift += 1) {
    final shiftedNeed = first.need.shiftAlongTangent(
      request: request,
      delta: shift,
    );
    final build = _buildPlacement(
      request: request,
      need: shiftedNeed,
      selected: primitive,
      quarterTurns: first.placement.placement.transform.quarterTurns,
    );
    if (build is! _PlacementBuildAccepted) continue;
    final shiftedPlacement = build.placement;
    if (_exceedsTwoTierMaskOverlapBudget(
      placement: shiftedPlacement,
      primitive: primitive,
      collisionIndex: collisionIndex,
      primitiveById: primitiveById,
      normalX: shiftedNeed.normalX,
      normalY: shiftedNeed.normalY,
      budget: maximumOverlapPx,
    )) {
      continue;
    }
    final nextContact = _measureTwoTierContact(
      first: shiftedPlacement,
      second: second.placement,
      firstPrimitive: primitive,
      secondPrimitive: primitiveById[second.placement.placement.primitiveId]!,
      normalX: second.need.normalX,
      normalY: second.need.normalY,
    );
    if (!_isValidTwoTierContact(
      nextContact,
      maximumOverlapPx: maximumOverlapPx,
    )) {
      continue;
    }
    if (previous != null) {
      final previousContact = _measureTwoTierContact(
        first: previous.placement,
        second: shiftedPlacement,
        firstPrimitive:
            primitiveById[previous.placement.placement.primitiveId]!,
        secondPrimitive: primitive,
        normalX: shiftedNeed.normalX,
        normalY: shiftedNeed.normalY,
      );
      if (!_isValidTwoTierContact(
        previousContact,
        maximumOverlapPx: maximumOverlapPx,
      )) {
        continue;
      }
    }
    collisionIndex.add(shiftedPlacement);
    return _TwoTierRowItem(
      need: shiftedNeed,
      placement: shiftedPlacement,
    );
  }
  collisionIndex.add(first.placement);
  return null;
}

_TwoTierRowItem? _shiftTwoTierSecondTowardFirst({
  required BorderResolutionRequest request,
  required _TwoTierRowItem first,
  required _TwoTierRowItem second,
  required Map<String, BorderPublishedPrimitive> primitiveById,
  required int maximumOverlapPx,
  required _StoneCollisionIndex collisionIndex,
}) {
  final primitive = primitiveById[second.placement.placement.primitiveId]!;
  collisionIndex.remove(second.placement);
  for (var shift = 0; shift <= maximumOverlapPx; shift += 1) {
    final shiftedNeed = second.need.shiftAlongTangent(
      request: request,
      delta: -shift,
    );
    final build = _buildPlacement(
      request: request,
      need: shiftedNeed,
      selected: primitive,
      quarterTurns: second.placement.placement.transform.quarterTurns,
    );
    if (build is! _PlacementBuildAccepted) continue;
    final shiftedPlacement = build.placement;
    if (_exceedsTwoTierMaskOverlapBudget(
      placement: shiftedPlacement,
      primitive: primitive,
      collisionIndex: collisionIndex,
      primitiveById: primitiveById,
      normalX: shiftedNeed.normalX,
      normalY: shiftedNeed.normalY,
      budget: maximumOverlapPx,
    )) {
      continue;
    }
    final contact = _measureTwoTierContact(
      first: first.placement,
      second: shiftedPlacement,
      firstPrimitive: primitiveById[first.placement.placement.primitiveId]!,
      secondPrimitive: primitive,
      normalX: shiftedNeed.normalX,
      normalY: shiftedNeed.normalY,
    );
    if (_isValidTwoTierContact(
      contact,
      maximumOverlapPx: maximumOverlapPx,
    )) {
      collisionIndex.add(shiftedPlacement);
      return _TwoTierRowItem(
        need: shiftedNeed,
        placement: shiftedPlacement,
      );
    }
  }
  collisionIndex.add(second.placement);
  return null;
}

void _addTwoTierOrientationDiagnostic({
  required BorderResolutionRequest request,
  required _PlacementNeed need,
  required List<BorderDiagnostic> diagnostics,
}) {
  diagnostics.add(
    _error(
      request,
      code: 'border.resolution.stone_chain_orientation_unavailable',
      scope: BorderDiagnosticScope.segment,
      strokeId: need.path.strokeId,
      cell: need.anchorCell,
      parameters: <String, Object?>{
        'slotKey': need.slotKey,
        'observed': 'no eligible oriented primitive',
        'expected': borderPrimitiveRoleV1WireName(need.semanticRole),
      },
      action: 'border.action.publish_required_stone_chain_orientation',
    ),
  );
}

void _addTwoTierGapDiagnostic({
  required BorderResolutionRequest request,
  required _PlacementNeed need,
  required String code,
  required StoneChainContactMetrics? contact,
  required int backfillBudget,
  required int attemptedBackfills,
  required String observed,
  required List<BorderDiagnostic> diagnostics,
  Map<String, Object?> extraParameters = const <String, Object?>{},
}) {
  diagnostics.add(
    _error(
      request,
      code: code,
      scope: BorderDiagnosticScope.stroke,
      strokeId: need.path.strokeId,
      cell: need.anchorCell,
      parameters: <String, Object?>{
        'slotKey': need.slotKey,
        'observed': observed,
        'observedGapPx': contact?.projectedGapPx ?? 0,
        'observedMinimumOverlapPx': contact?.tangentOverlapPx ?? 0,
        'observedMaximumOverlapPx': contact?.tangentOverlapPx ?? 0,
        'expectedGapPx': 0,
        'expectedMinimumOverlapPx': 2,
        'expectedMaximumOverlapPx': (request.feature.paramsOverride ??
                request.blueprintRevision!.definition.defaults)
            .maxOverlapPx,
        'backfillBudget': backfillBudget,
        'attemptedBackfills': attemptedBackfills,
        ...extraParameters,
      },
      action: 'border.action.adjust_stone_chain_row_spacing',
    ),
  );
}

List<_GeneratedStonePlacement> _materializeTwoTierFillers({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required BorderGenerationParams parameters,
  required List<_PlacementNeed> lipNeeds,
  required List<BorderPublishedPrimitive> fillerPrimitives,
  required _StonePrimitiveCatalog primitiveCatalog,
  required List<_GeneratedStonePlacement> structuralPlacements,
  required _StoneCollisionIndex collisionIndex,
  required List<BorderDiagnostic> diagnostics,
}) {
  if (parameters.detailDensityPermille <= 0 ||
      fillerPrimitives.isEmpty ||
      lipNeeds.length < 2) {
    return const <_GeneratedStonePlacement>[];
  }
  final maximumFillerExtent = fillerPrimitives
      .map(
        (primitive) => _maximum(
          primitive.publishedMetrics.opaqueBounds.width,
          primitive.publishedMetrics.opaqueBounds.height,
        ),
      )
      .reduce(_maximum);
  final fillerNeeds = <_PlacementNeed>[];
  for (var index = 1; index < lipNeeds.length; index += 1) {
    fillerNeeds.add(
      lipNeeds[index - 1].asSecondaryBetween(
        request: request,
        next: lipNeeds[index],
        role: BorderPrimitiveRole.filler,
        extraNormalOffset: _maximum(2, maximumFillerExtent - 5),
      ),
    );
  }
  final selection = _selectSecondaryDensityCandidates(
    request: request,
    revision: revision,
    candidates: fillerNeeds,
    desiredCount: lipNeeds.length * parameters.detailDensityPermille ~/ 1000,
  );
  final result = <_GeneratedStonePlacement>[];
  for (final need in selection.rankedCandidates.take(selection.targetCount)) {
    final placement = _generateAttachedFillerPlacement(
      request: request,
      revision: revision,
      need: need,
      primitiveCatalog: primitiveCatalog,
      variationPermille: parameters.variationPermille,
      collisionIndex: collisionIndex,
      maximumOverlapPx: parameters.maxOverlapPx,
      primaryPlacements: structuralPlacements,
      maximumAttachmentGapPx: parameters.gapTolerancePx,
      diagnostics: diagnostics,
    );
    if (placement == null) continue;
    result.add(placement);
    collisionIndex.add(placement);
  }
  return result;
}

int _compareTwoTierCandidates(
  _TwoTierPlacementCandidate left,
  _TwoTierPlacementCandidate right, {
  required int targetOverlapPx,
  required int maximumOverlapPx,
  required bool prioritizeRepetition,
}) {
  int continuityPenalty(_TwoTierPlacementCandidate candidate) {
    final contact = candidate.contact;
    if (contact == null) return 0;
    return contact.projectedGapPx == 0 &&
            contact.tangentOverlapPx >= 2 &&
            contact.tangentOverlapPx <= maximumOverlapPx
        ? 0
        : 1;
  }

  var result = continuityPenalty(left).compareTo(continuityPenalty(right));
  if (result != 0) return result;
  result = (left.jointAligned ? 1 : 0).compareTo(right.jointAligned ? 1 : 0);
  if (result != 0) return result;
  if (prioritizeRepetition) {
    result = left.recentReusePenalty.compareTo(right.recentReusePenalty);
    if (result != 0) return result;
    result = left.repeatedBlockPenalty.compareTo(right.repeatedBlockPenalty);
    if (result != 0) return result;
    result = (left.preferred ? 0 : 1).compareTo(right.preferred ? 0 : 1);
    if (result != 0) return result;
  }
  final leftDeviation =
      ((left.contact?.tangentOverlapPx ?? targetOverlapPx) - targetOverlapPx)
          .abs();
  final rightDeviation =
      ((right.contact?.tangentOverlapPx ?? targetOverlapPx) - targetOverlapPx)
          .abs();
  result = leftDeviation.compareTo(rightDeviation);
  if (result != 0) return result;
  if (!prioritizeRepetition) {
    result = left.recentReusePenalty.compareTo(right.recentReusePenalty);
    if (result != 0) return result;
    result = left.repeatedBlockPenalty.compareTo(right.repeatedBlockPenalty);
    if (result != 0) return result;
  }
  result = left.shiftPx.compareTo(right.shiftPx);
  if (result != 0) return result;
  if (!prioritizeRepetition) {
    result = (left.preferred ? 0 : 1).compareTo(right.preferred ? 0 : 1);
    if (result != 0) return result;
  }
  return left.placement.placement.primitiveId
      .compareTo(right.placement.placement.primitiveId);
}

int _recentPrimitiveReusePenalty(
  List<String> recentPrimitiveIds,
  String primitiveId,
) {
  final recentPair = recentPrimitiveIds.length <= 2
      ? recentPrimitiveIds
      : recentPrimitiveIds.sublist(recentPrimitiveIds.length - 2);
  final index = recentPair.lastIndexOf(primitiveId);
  return index < 0 ? 0 : index + 1;
}

int _repeatedPrimitiveBlockPenalty(
  List<String> recentPrimitiveIds,
  String primitiveId,
) {
  final sequence = <String>[...recentPrimitiveIds, primitiveId];
  for (var blockLength = 2; blockLength <= 4; blockLength += 1) {
    if (sequence.length < blockLength * 2) continue;
    final start = sequence.length - blockLength * 2;
    var repeats = true;
    for (var index = 0; index < blockLength; index += 1) {
      final expected = sequence[start + index];
      if (sequence[start + blockLength + index] != expected) {
        repeats = false;
        break;
      }
    }
    if (repeats) return 1;
  }
  return 0;
}

int? _quarterTurnsForOrientation({
  required BorderPrimitiveOrientation authored,
  required BorderCardinalDirection desired,
  required bool allowAutoRotation,
  required List<int> allowedQuarterTurns,
}) {
  if (authored == BorderPrimitiveOrientation.legacyAxis) {
    final quarterTurns =
        allowAutoRotation ? borderCardinalDirectionV1Rank(desired) : 0;
    return allowedQuarterTurns.contains(quarterTurns) ? quarterTurns : null;
  }
  final delta =
      (borderCardinalDirectionV1Rank(desired) - _orientationRank(authored)) & 3;
  if (!allowAutoRotation && delta != 0) return null;
  return allowedQuarterTurns.contains(delta) ? delta : null;
}

int _orientationRank(BorderPrimitiveOrientation orientation) =>
    switch (orientation) {
      BorderPrimitiveOrientation.east => 0,
      BorderPrimitiveOrientation.south => 1,
      BorderPrimitiveOrientation.west => 2,
      BorderPrimitiveOrientation.north => 3,
      BorderPrimitiveOrientation.legacyAxis => throw StateError(
          'legacyAxis is handled before cardinal orientation ranking',
        ),
    };

BorderCardinalDirection _cardinalDirectionForVector(int dx, int dy) =>
    switch ((dx, dy)) {
      (1, 0) => BorderCardinalDirection.east,
      (0, 1) => BorderCardinalDirection.south,
      (-1, 0) => BorderCardinalDirection.west,
      (0, -1) => BorderCardinalDirection.north,
      _ => throw StateError('Stone-chain normal must be unit-cardinal'),
    };

StoneChainContactMetrics _measureTwoTierContact({
  required _GeneratedStonePlacement first,
  required _GeneratedStonePlacement second,
  required BorderPublishedPrimitive firstPrimitive,
  required BorderPublishedPrimitive secondPrimitive,
  required int normalX,
  required int normalY,
}) =>
    measureStoneChainContact(
      first: _twoTierPlacedMask(first, firstPrimitive),
      second: _twoTierPlacedMask(second, secondPrimitive),
      tangent: StoneChainAxis(dx: first.tangentX, dy: first.tangentY),
      normal: StoneChainAxis(dx: normalX, dy: normalY),
    );

bool _exceedsTwoTierMaskOverlapBudget({
  required _GeneratedStonePlacement placement,
  required BorderPublishedPrimitive primitive,
  required _StoneCollisionIndex collisionIndex,
  required Map<String, BorderPublishedPrimitive> primitiveById,
  required int normalX,
  required int normalY,
  required int budget,
}) {
  // Bounds only select nearby candidates. The authored occupancy masks own
  // the final overlap decision, so transparent/concave bounds cannot consume
  // a row's collision budget by themselves.
  for (final other in collisionIndex.candidatesFor(placement)) {
    final otherPrimitive = primitiveById[other.placement.primitiveId];
    if (otherPrimitive == null) continue;
    final contact = _measureTwoTierContact(
      first: other,
      second: placement,
      firstPrimitive: otherPrimitive,
      secondPrimitive: primitive,
      normalX: normalX,
      normalY: normalY,
    );
    if (contact.opaqueIntersectionPixels > 0 &&
        contact.tangentOverlapPx > budget) {
      return true;
    }
  }
  return false;
}

StoneChainPlacedMask _twoTierPlacedMask(
  _GeneratedStonePlacement placement,
  BorderPublishedPrimitive primitive,
) =>
    StoneChainPlacedMask(
      metrics: primitive.publishedMetrics,
      transform: placement.placement.transform,
      topLeftWorldPx: placement.placement.topLeftWorldPx,
    );

Set<int> _twoTierJointCoordinates(
  List<_GeneratedStonePlacement> placements,
) =>
    <int>{
      for (var index = 1; index < placements.length; index += 1)
        _twoTierJointCoordinate(placements[index - 1], placements[index]),
    };

int _twoTierJointCoordinate(
  _GeneratedStonePlacement first,
  _GeneratedStonePlacement second,
) {
  final tangentX = first.tangentX;
  final tangentY = first.tangentY;
  final firstBounds = first.placement.opaqueWorldBoundsPx;
  final secondBounds = second.placement.opaqueWorldBoundsPx;
  final firstMaximum = _maximumProjection(
    firstBounds,
    dx: tangentX,
    dy: tangentY,
  );
  final secondMinimum = _minimumProjection(
    secondBounds,
    dx: tangentX,
    dy: tangentY,
  );
  return (firstMaximum + secondMinimum) ~/ 2;
}

int _minimumProjection(
  BorderPixelRect bounds, {
  required int dx,
  required int dy,
}) =>
    <int>[
      bounds.x * dx + bounds.y * dy,
      (bounds.right - 1) * dx + bounds.y * dy,
      bounds.x * dx + (bounds.bottom - 1) * dy,
      (bounds.right - 1) * dx + (bounds.bottom - 1) * dy,
    ].reduce(_minimum);

int _maximumProjection(
  BorderPixelRect bounds, {
  required int dx,
  required int dy,
}) =>
    <int>[
      bounds.x * dx + bounds.y * dy,
      (bounds.right - 1) * dx + bounds.y * dy,
      bounds.x * dx + (bounds.bottom - 1) * dy,
      (bounds.right - 1) * dx + (bounds.bottom - 1) * dy,
    ].reduce(_maximum);

void _validateTwoTierStraightPath({
  required BorderResolutionRequest request,
  required BorderGenerationParams parameters,
  required _StonePath path,
  required List<_GeneratedStonePlacement> lips,
  required List<_GeneratedStonePlacement> faces,
  required Map<String, BorderPublishedPrimitive> primitiveById,
  required List<BorderDiagnostic> diagnostics,
}) {
  if (lips.isEmpty || faces.isEmpty) {
    diagnostics.add(
      _error(
        request,
        code: lips.isEmpty
            ? 'border.resolution.stone_chain_lip_gap'
            : 'border.resolution.stone_chain_face_gap',
        scope: BorderDiagnosticScope.stroke,
        strokeId: path.strokeId,
        parameters: const <String, Object?>{
          'slotKey': '',
          'observed': 0,
          'expected': 1,
        },
        action: 'border.action.publish_complete_stone_chain_row',
      ),
    );
    return;
  }
  final authoredStartIsCanonical = _gridPosComesFirst(
    path.points.first,
    path.points.last,
  );
  final tangentSign = path.closed || authoredStartIsCanonical ? 1 : -1;
  final tangent = StoneChainAxis(
    dx: path.edges.first.directionX * tangentSign,
    dy: path.edges.first.directionY * tangentSign,
  );
  final sideSign = request.feature.lineSide == BorderLineSide.primary ? 1 : -1;
  final normal = StoneChainAxis(
    dx: -path.edges.first.directionY * sideSign,
    dy: path.edges.first.directionX * sideSign,
  );
  void validateRow(
    List<_GeneratedStonePlacement> row,
    String code,
  ) {
    final continuity = measureStoneChainRowContinuity(
      samples: <StoneChainRowSample>[
        for (final placement in row)
          StoneChainRowSample(
            strokeId: path.strokeId,
            slotKey: placement.placement.slotKey,
            pathDistancePx: placement.pathDistance,
            closed: path.closed,
            mask: _twoTierPlacedMask(
              placement,
              primitiveById[placement.placement.primitiveId]!,
            ),
          ),
      ],
      tangent: tangent,
      normal: normal,
    );
    if (continuity.maximumGapPx != 0 ||
        continuity.connectedComponentCount != 1 ||
        continuity.minimumOverlapPx < 2 ||
        continuity.maximumOverlapPx > parameters.maxOverlapPx) {
      diagnostics.add(
        _error(
          request,
          code: code,
          scope: BorderDiagnosticScope.stroke,
          strokeId: path.strokeId,
          parameters: <String, Object?>{
            'slotKey': row.first.placement.slotKey,
            'observedGapPx': continuity.maximumGapPx,
            'observedMinimumOverlapPx': continuity.minimumOverlapPx,
            'observedMaximumOverlapPx': continuity.maximumOverlapPx,
            'observedConnectedComponents': continuity.connectedComponentCount,
            'expectedGapPx': 0,
            'expectedMinimumOverlapPx': 2,
            'expectedMaximumOverlapPx': parameters.maxOverlapPx,
            'expectedConnectedComponents': 1,
          },
          action: 'border.action.adjust_stone_chain_row_spacing',
        ),
      );
    }
  }

  validateRow(lips, 'border.resolution.stone_chain_lip_gap');
  validateRow(faces, 'border.resolution.stone_chain_face_gap');
  if (_hasErrors(diagnostics)) return;

  for (final face in faces) {
    final facePrimitive = primitiveById[face.placement.primitiveId]!;
    final attached = <_GeneratedStonePlacement>[];
    for (final lip in lips) {
      final contact = measureStoneChainContact(
        first: _twoTierPlacedMask(face, facePrimitive),
        second: _twoTierPlacedMask(
          lip,
          primitiveById[lip.placement.primitiveId]!,
        ),
        tangent: tangent,
        normal: normal,
      );
      if (contact.opaqueIntersectionPixels > 0) attached.add(lip);
    }
    if (attached.isEmpty) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.stone_chain_face_detached',
          scope: BorderDiagnosticScope.segment,
          strokeId: path.strokeId,
          parameters: <String, Object?>{
            'slotKey': face.placement.slotKey,
            'observed': 0,
            'expected': 1,
          },
          action: 'border.action.move_stone_chain_face_toward_lip',
        ),
      );
      continue;
    }
    final lipFront = attached
        .map(
          (lip) => _maximumProjection(
            lip.placement.opaqueWorldBoundsPx,
            dx: normal.dx,
            dy: normal.dy,
          ),
        )
        .reduce(_maximum);
    final visibleDepthPx = _maximumProjection(
          face.placement.opaqueWorldBoundsPx,
          dx: normal.dx,
          dy: normal.dy,
        ) -
        lipFront;
    if (visibleDepthPx < 12) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.stone_chain_face_depth_insufficient',
          scope: BorderDiagnosticScope.segment,
          strokeId: path.strokeId,
          parameters: <String, Object?>{
            'slotKey': face.placement.slotKey,
            'observedDepthPx': visibleDepthPx,
            'expectedDepthPx': 12,
          },
          action: 'border.action.publish_deeper_stone_chain_face',
        ),
      );
    }
  }
}

final class _TwoTierTopologyPlan {
  _TwoTierTopologyPlan._({
    required this.request,
    required this.path,
    required this.turns,
    required this.endpoints,
    required this.runs,
  }) : turnByVertex = <GridPos, _TwoTierTurn>{
          for (final turn in turns) turn.vertex: turn,
        };

  factory _TwoTierTopologyPlan.build({
    required BorderResolutionRequest request,
    required _StonePath path,
  }) {
    final turns = <_TwoTierTurn>[];
    final firstTurnIndex = path.closed ? 0 : 1;
    final endTurnIndex =
        path.closed ? path.points.length : path.points.length - 1;
    for (var index = firstTurnIndex; index < endTurnIndex; index += 1) {
      final incoming =
          path.edges[(index - 1 + path.edges.length) % path.edges.length];
      final outgoing = path.edges[index % path.edges.length];
      if (incoming.directionX == outgoing.directionX &&
          incoming.directionY == outgoing.directionY) {
        continue;
      }
      turns.add(
        _TwoTierTurn(
          vertex: path.points[index],
          incoming: incoming,
          outgoing: outgoing,
          distancePx: path.distanceAtVertex(index),
          sourceVertexOrdinal: path.sourceVertexOrdinal(index),
        ),
      );
    }
    final endpoints = path.closed
        ? const <_TwoTierEndpoint>[]
        : <_TwoTierEndpoint>[
            _TwoTierEndpoint(
              vertex: path.points.first,
              edge: path.edges.first,
              distancePx: 0,
              atStart: true,
            ),
            _TwoTierEndpoint(
              vertex: path.points.last,
              edge: path.edges.last,
              distancePx: path.totalLengthPx,
              atStart: false,
            ),
          ];
    final turnVertices = <GridPos>{for (final turn in turns) turn.vertex};
    final runs = <_TwoTierRun>[];
    var startEdge = 0;
    void addRun(int endEdgeExclusive) {
      final edges = path.edges.sublist(startEdge, endEdgeExclusive);
      final first = edges.first;
      final last = edges.last;
      final startVertex = first.start;
      final endVertex = last.end;
      final startTurnSlot = turnVertices.contains(startVertex)
          ? buildBorderStoneChainNodeSlotKey(
              featureId: request.feature.id,
              strokeId: path.lineageId,
              vertex: startVertex,
              passIndex: 0,
              role: BorderPrimitiveRole.lineCorner,
              rank: 0,
            )
          : null;
      final endTurnSlot = turnVertices.contains(endVertex)
          ? buildBorderStoneChainNodeSlotKey(
              featureId: request.feature.id,
              strokeId: path.lineageId,
              vertex: endVertex,
              passIndex: 0,
              role: BorderPrimitiveRole.lineCorner,
              rank: 0,
            )
          : null;
      final owner =
          edges.length == 1 && startTurnSlot != null && endTurnSlot != null
              ? (startTurnSlot.compareTo(endTurnSlot) <= 0
                  ? startTurnSlot
                  : endTurnSlot)
              : null;
      runs.add(
        _TwoTierRun(
          path: path,
          ordinal: runs.length,
          edges: List<_PathEdge>.unmodifiable(edges),
          startVertex: startVertex,
          endVertex: endVertex,
          startDistancePx: first.startDistance,
          endDistancePx: last.startDistance + last.length,
          startIsTurn: startTurnSlot != null,
          endIsTurn: endTurnSlot != null,
          oneCellOwnerTurnSlotKey: owner,
        ),
      );
    }

    for (var index = 1; index < path.edges.length; index += 1) {
      final previous = path.edges[index - 1];
      final current = path.edges[index];
      if (previous.directionX == current.directionX &&
          previous.directionY == current.directionY) {
        continue;
      }
      addRun(index);
      startEdge = index;
    }
    addRun(path.edges.length);
    return _TwoTierTopologyPlan._(
      request: request,
      path: path,
      turns: List<_TwoTierTurn>.unmodifiable(turns),
      endpoints: List<_TwoTierEndpoint>.unmodifiable(endpoints),
      runs: List<_TwoTierRun>.unmodifiable(runs),
    );
  }

  final BorderResolutionRequest request;
  final _StonePath path;
  final List<_TwoTierTurn> turns;
  final List<_TwoTierEndpoint> endpoints;
  final List<_TwoTierRun> runs;
  final Map<GridPos, _TwoTierTurn> turnByVertex;
}

final class _TwoTierTurn {
  const _TwoTierTurn({
    required this.vertex,
    required this.incoming,
    required this.outgoing,
    required this.distancePx,
    required this.sourceVertexOrdinal,
  });

  final GridPos vertex;
  final _PathEdge incoming;
  final _PathEdge outgoing;
  final int distancePx;
  final int sourceVertexOrdinal;
}

final class _TwoTierEndpoint {
  const _TwoTierEndpoint({
    required this.vertex,
    required this.edge,
    required this.distancePx,
    required this.atStart,
  });

  final GridPos vertex;
  final _PathEdge edge;
  final int distancePx;
  final bool atStart;
}

final class _TwoTierRun {
  const _TwoTierRun({
    required this.path,
    required this.ordinal,
    required this.edges,
    required this.startVertex,
    required this.endVertex,
    required this.startDistancePx,
    required this.endDistancePx,
    required this.startIsTurn,
    required this.endIsTurn,
    required this.oneCellOwnerTurnSlotKey,
  });

  final _StonePath path;
  final int ordinal;
  final List<_PathEdge> edges;
  final GridPos startVertex;
  final GridPos endVertex;
  final int startDistancePx;
  final int endDistancePx;
  final bool startIsTurn;
  final bool endIsTurn;

  /// Canonical owner for a one-edge run between two turns.
  final String? oneCellOwnerTurnSlotKey;

  int get directionX => edges.first.directionX;
  int get directionY => edges.first.directionY;
  int get lengthPx => endDistancePx - startDistancePx;
  bool get isOneCellBetweenTurns => oneCellOwnerTurnSlotKey != null;
}

final class _TwoTierReservedCandidate {
  const _TwoTierReservedCandidate({
    required this.need,
    required this.placement,
    required this.primitive,
  });

  final _PlacementNeed need;
  final _GeneratedStonePlacement placement;
  final BorderPublishedPrimitive primitive;

  _TwoTierRowItem asRowItem() => _TwoTierRowItem(
        need: need,
        placement: placement,
      );
}

final class _TwoTierTurnReservation {
  const _TwoTierTurnReservation({
    required this.lip,
    required this.incomingFace,
    required this.outgoingFace,
  });

  final _TwoTierRowItem lip;
  final _TwoTierRowItem incomingFace;
  final _TwoTierRowItem outgoingFace;
}

final class _TwoTierEndpointReservation {
  const _TwoTierEndpointReservation({
    required this.lip,
    required this.face,
  });

  final _TwoTierRowItem lip;
  final _TwoTierRowItem face;
}

final class _TwoTierTopologyReservations {
  const _TwoTierTopologyReservations({
    required this.plan,
    required this.lipItems,
    required this.faceItems,
  });

  final _TwoTierTopologyPlan plan;
  final Map<String, _TwoTierRowItem> lipItems;
  final Map<String, _TwoTierRowItem> faceItems;

  Iterable<_GeneratedStonePlacement> get allPlacements sync* {
    for (final item in lipItems.values) {
      yield item.placement;
    }
    for (final item in faceItems.values) {
      yield item.placement;
    }
  }

  _TwoTierRowItem boundaryItem({
    required BorderResolutionRequest request,
    required _TwoTierRun run,
    required int passIndex,
    required bool atStart,
  }) {
    final vertex = atStart ? run.startVertex : run.endVertex;
    final turn = plan.turnByVertex[vertex];
    final role = passIndex == 0
        ? (turn == null
            ? BorderPrimitiveRole.lineCap
            : BorderPrimitiveRole.lineCorner)
        : BorderPrimitiveRole.structureMedium;
    final rank = passIndex == 0
        ? 0
        : turn == null
            ? 2
            : atStart
                ? 1
                : 0;
    final slotKey = buildBorderStoneChainNodeSlotKey(
      featureId: request.feature.id,
      strokeId: run.path.lineageId,
      vertex: vertex,
      passIndex: passIndex,
      role: role,
      rank: rank,
    );
    final source = (passIndex == 0 ? lipItems : faceItems)[slotKey]!;
    final sideSign =
        request.feature.lineSide == BorderLineSide.primary ? 1 : -1;
    final normalX = -run.directionY * sideSign;
    final normalY = run.directionX * sideSign;
    final baseDistance = atStart ? run.startDistancePx : run.endDistancePx;
    final vertexWorldX = vertex.x * request.tileSizePx.width;
    final vertexWorldY = vertex.y * request.tileSizePx.height;
    final distance = baseDistance +
        (source.need.targetAnchorWorldPx.x - vertexWorldX) * run.directionX +
        (source.need.targetAnchorWorldPx.y - vertexWorldY) * run.directionY;
    return _TwoTierRowItem(
      need: source.need.withTopologyRunAxes(
        tangentX: run.directionX,
        tangentY: run.directionY,
        normalX: normalX,
        normalY: normalY,
        distance: distance,
      ),
      placement: source.placement.withTopologyRunAxes(
        tangentX: run.directionX,
        tangentY: run.directionY,
        pathDistance: distance,
      ),
    );
  }
}

final class _TwoTierTopologyRunRows {
  const _TwoTierTopologyRunRows({
    required this.run,
    required this.lips,
    required this.faces,
  });

  final _TwoTierRun run;
  final List<_GeneratedStonePlacement> lips;
  final List<_GeneratedStonePlacement> faces;
}

final class _TwoTierPlacementSelection {
  const _TwoTierPlacementSelection({
    required this.placement,
    required this.hasOrientedCandidate,
    required this.observedContact,
  });

  final _GeneratedStonePlacement? placement;
  final bool hasOrientedCandidate;
  final StoneChainContactMetrics? observedContact;
}

final class _TwoTierRowPreflight {
  const _TwoTierRowPreflight({
    required this.primitives,
    required this.opaquePixelsByPrimitiveId,
    required this.minimumOpaquePixelsPerPlacement,
  });

  final List<BorderPublishedPrimitive> primitives;
  final Map<String, int> opaquePixelsByPrimitiveId;
  final int minimumOpaquePixelsPerPlacement;
}

final class _TwoTierRowItem {
  const _TwoTierRowItem({required this.need, required this.placement});

  final _PlacementNeed need;
  final _GeneratedStonePlacement placement;
}

final class _TwoTierRowNode {
  _TwoTierRowNode(this.item);

  _TwoTierRowItem item;
  _TwoTierRowNode? previous;
  _TwoTierRowNode? next;
}

final class _TwoTierPlacementCandidate {
  const _TwoTierPlacementCandidate({
    required this.placement,
    required this.contact,
    required this.jointAligned,
    required this.preferred,
    required this.recentReusePenalty,
    required this.repeatedBlockPenalty,
    required this.shiftPx,
  });

  final _GeneratedStonePlacement placement;
  final StoneChainContactMetrics? contact;
  final bool jointAligned;
  final bool preferred;
  final int recentReusePenalty;
  final int repeatedBlockPenalty;
  final int shiftPx;
}

final class _TwoTierPlannedCandidate {
  const _TwoTierPlannedCandidate({
    required this.item,
    required this.shiftPx,
    required this.preferred,
    required this.authoredWeightPenalty,
    required this.preparedMask,
  });

  final _TwoTierRowItem item;
  final int shiftPx;
  final bool preferred;
  final int authoredWeightPenalty;
  final _TwoTierPreparedMask preparedMask;
}

final class _TwoTierPlannedRowState {
  const _TwoTierPlannedRowState({
    required this.currentItem,
    required this.currentCandidateIndex,
    required this.previousCandidateIndex,
    required this.previous,
    required this.cost,
  });

  final _TwoTierRowItem currentItem;
  final int currentCandidateIndex;
  final int previousCandidateIndex;
  final _TwoTierPlannedRowState? previous;
  final _TwoTierPlannedRowCost cost;
}

final class _TwoTierPlannedEdge {
  const _TwoTierPlannedEdge({
    required this.overlapDeviation,
    required this.jointAligned,
    required this.repeatsPrevious,
  });

  final int overlapDeviation;
  final bool jointAligned;
  final bool repeatsPrevious;
}

final class _TwoTierPreparedMask {
  const _TwoTierPreparedMask({
    required this.pixels,
    required this.topLeftWorldPx,
    required this.bounds,
  });

  final Set<_TwoTierMaskPixel> pixels;
  final BorderPixelPos topLeftWorldPx;
  final BorderPixelRect bounds;
}

typedef _TwoTierMaskPixel = ({int x, int y});

final class _TwoTierPlannedRowCost
    implements Comparable<_TwoTierPlannedRowCost> {
  const _TwoTierPlannedRowCost({
    required this.prioritizeRepetition,
    this.shiftPreferenceDeviation = 0,
    this.overlapDeviation = 0,
    this.alignedJoints = 0,
    this.repeatedPrimitives = 0,
    this.repeatedBlockReuses = 0,
    this.shortCycleReuses = 0,
    this.threeBackReuses = 0,
    this.fourBackReuses = 0,
    this.authoredWeightPenalty = 0,
    this.nonPreferredPrimitives = 0,
  });

  final bool prioritizeRepetition;
  final int shiftPreferenceDeviation;
  final int overlapDeviation;
  final int alignedJoints;
  final int repeatedPrimitives;
  final int repeatedBlockReuses;
  final int shortCycleReuses;
  final int threeBackReuses;
  final int fourBackReuses;
  final int authoredWeightPenalty;
  final int nonPreferredPrimitives;

  _TwoTierPlannedRowCost add({
    required int shiftCostPx,
    required int overlapDeviation,
    required bool jointAligned,
    required bool repeatsPrevious,
    required int repeatedBlockReuses,
    required bool repeatsTwoBack,
    required bool repeatsThreeBack,
    required bool repeatsFourBack,
    required int authoredWeightPenalty,
    required bool preferred,
  }) =>
      _TwoTierPlannedRowCost(
        prioritizeRepetition: prioritizeRepetition,
        shiftPreferenceDeviation: shiftPreferenceDeviation + shiftCostPx.abs(),
        overlapDeviation: this.overlapDeviation + overlapDeviation,
        alignedJoints: alignedJoints + (jointAligned ? 1 : 0),
        repeatedPrimitives: repeatedPrimitives + (repeatsPrevious ? 1 : 0),
        repeatedBlockReuses: this.repeatedBlockReuses + repeatedBlockReuses,
        shortCycleReuses: shortCycleReuses + (repeatsTwoBack ? 1 : 0),
        threeBackReuses: threeBackReuses + (repeatsThreeBack ? 1 : 0),
        fourBackReuses: fourBackReuses + (repeatsFourBack ? 1 : 0),
        authoredWeightPenalty:
            this.authoredWeightPenalty + authoredWeightPenalty,
        nonPreferredPrimitives: nonPreferredPrimitives + (preferred ? 0 : 1),
      );

  @override
  int compareTo(_TwoTierPlannedRowCost other) {
    assert(prioritizeRepetition == other.prioritizeRepetition);
    var result = alignedJoints.compareTo(other.alignedJoints);
    if (result != 0) return result;
    if (prioritizeRepetition) {
      result = repeatedPrimitives.compareTo(other.repeatedPrimitives);
      if (result != 0) return result;
      result = repeatedBlockReuses.compareTo(other.repeatedBlockReuses);
      if (result != 0) return result;
      result = shortCycleReuses.compareTo(other.shortCycleReuses);
      if (result != 0) return result;
      result = fourBackReuses.compareTo(other.fourBackReuses);
      if (result != 0) return result;
      result = threeBackReuses.compareTo(other.threeBackReuses);
      if (result != 0) return result;
      result = authoredWeightPenalty.compareTo(other.authoredWeightPenalty);
      if (result != 0) return result;
      result = nonPreferredPrimitives.compareTo(other.nonPreferredPrimitives);
      if (result != 0) return result;
    }
    result = shiftPreferenceDeviation.compareTo(
      other.shiftPreferenceDeviation,
    );
    if (result != 0) return result;
    result = overlapDeviation.compareTo(other.overlapDeviation);
    if (result != 0) return result;
    if (!prioritizeRepetition) {
      result = shortCycleReuses.compareTo(other.shortCycleReuses);
      if (result != 0) return result;
      result = repeatedPrimitives.compareTo(other.repeatedPrimitives);
      if (result != 0) return result;
      result = repeatedBlockReuses.compareTo(other.repeatedBlockReuses);
      if (result != 0) return result;
      result = fourBackReuses.compareTo(other.fourBackReuses);
      if (result != 0) return result;
      result = threeBackReuses.compareTo(other.threeBackReuses);
      if (result != 0) return result;
      result = authoredWeightPenalty.compareTo(other.authoredWeightPenalty);
      if (result != 0) return result;
    }
    return prioritizeRepetition
        ? 0
        : nonPreferredPrimitives.compareTo(other.nonPreferredPrimitives);
  }
}

List<_PlacementNeed> _specialNeeds({
  required BorderResolutionRequest request,
  required _StonePath path,
  required int normalOffset,
}) {
  final result = <_PlacementNeed>[];
  final parameters = request.feature.paramsOverride ??
      request.blueprintRevision!.definition.defaults;
  final capInset = _maximum(
    parameters.maxOverlapPx,
    _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 4 + 2,
  );
  if (!path.closed) {
    final first = path.edges.first;
    result.add(
      _nodeNeed(
        request: request,
        path: path,
        vertex: path.points.first,
        distance: 0,
        tangentX: first.directionX,
        tangentY: first.directionY,
        normalX: -first.directionY,
        normalY: first.directionX,
        role: BorderPrimitiveRole.lineCap,
        rank: 0,
        normalOffset: normalOffset,
        tangentOffset: capInset,
      ),
    );
    final last = path.edges.last;
    result.add(
      _nodeNeed(
        request: request,
        path: path,
        vertex: path.points.last,
        distance: path.totalLengthPx,
        tangentX: last.directionX,
        tangentY: last.directionY,
        normalX: -last.directionY,
        normalY: last.directionX,
        role: BorderPrimitiveRole.lineCap,
        rank: 1,
        normalOffset: normalOffset,
        tangentOffset: -capInset,
      ),
    );
  }

  final firstIndex = path.closed ? 0 : 1;
  final endExclusive =
      path.closed ? path.points.length : path.points.length - 1;
  for (var index = firstIndex; index < endExclusive; index += 1) {
    final incoming =
        path.edges[(index - 1 + path.edges.length) % path.edges.length];
    final outgoing = path.edges[index % path.edges.length];
    if (incoming.directionX == outgoing.directionX &&
        incoming.directionY == outgoing.directionY) {
      continue;
    }
    result.add(
      _nodeNeed(
        request: request,
        path: path,
        vertex: path.points[index],
        distance: path.distanceAtVertex(index),
        tangentX: outgoing.directionX,
        tangentY: outgoing.directionY,
        normalX: _clampUnit(-incoming.directionY - outgoing.directionY),
        normalY: _clampUnit(incoming.directionX + outgoing.directionX),
        role: BorderPrimitiveRole.lineCorner,
        rank: index,
        slotRank: path.sourceVertexOrdinal(index),
        normalOffset: normalOffset,
        tangentOffset: 0,
      ),
    );
  }
  return result;
}

_GeneratedStonePlacement? _fitReservedCap({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed capNeed,
  required _StonePrimitiveCatalog primitiveCatalog,
  required int variationPermille,
  required _StoneCollisionIndex collisionIndex,
  required int maximumOverlapPx,
  required List<BorderDiagnostic> diagnostics,
}) {
  final outwardSign = capNeed.distance == 0 ? -1 : 1;
  final maximumShift = _minimum(
        request.tileSizePx.width,
        request.tileSizePx.height,
      ) ~/
      2;
  for (var shift = 0; shift <= maximumShift; shift += 1) {
    final need = capNeed.offsetAnchorAlongTangent(
      request: request,
      delta: outwardSign * shift,
    );
    final placement = _generatePlacement(
      request: request,
      revision: revision,
      need: need,
      primitiveCatalog: primitiveCatalog,
      variationPermille: variationPermille,
      collisionIndex: collisionIndex,
      maximumOverlapPx: maximumOverlapPx,
      diagnostics: diagnostics,
    );
    if (placement != null) return placement;
  }
  return null;
}

({
  _PlacementNeed need,
  _GeneratedStonePlacement placement,
})? _fitStraightBoundaryPlacement({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _StonePath path,
  required _GeneratedStonePlacement previous,
  required _GeneratedStonePlacement next,
  required int ordinal,
  required int normalOffset,
  required _StonePrimitiveCatalog primitiveCatalog,
  required int variationPermille,
  required _StoneCollisionIndex collisionIndex,
  required int maximumOverlapPx,
  required int gapTolerancePx,
  required List<BorderDiagnostic> diagnostics,
}) {
  final maximumSearch = _maximum(
    request.tileSizePx.width,
    request.tileSizePx.height,
  );
  final startDistance = _maximum(
    previous.pathDistance + 1,
    next.pathDistance - maximumSearch,
  );
  final endDistance = next.pathDistance - 1;
  for (var distance = startDistance; distance <= endDistance; distance += 1) {
    final sample = path.sampleAtDistance(distance);
    final need = _stationNeed(
      request: request,
      path: path,
      sample: sample,
      distance: distance,
      ordinal: ordinal,
      role: BorderPrimitiveRole.structureLarge,
      passIndex: 0,
      normalOffset: normalOffset,
    );
    final placement = _generatePlacement(
      request: request,
      revision: revision,
      need: need,
      primitiveCatalog: primitiveCatalog,
      variationPermille: variationPermille,
      collisionIndex: collisionIndex,
      maximumOverlapPx: maximumOverlapPx,
      diagnostics: diagnostics,
      previousPrimary: previous,
      nextPrimary: next,
      maximumGapPx: gapTolerancePx,
    );
    if (placement != null &&
        _opaqueRectGap(
              previous.placement.opaqueWorldBoundsPx,
              placement.placement.opaqueWorldBoundsPx,
            ) <=
            gapTolerancePx &&
        _opaqueRectGap(
              placement.placement.opaqueWorldBoundsPx,
              next.placement.opaqueWorldBoundsPx,
            ) <=
            gapTolerancePx) {
      return (need: need, placement: placement);
    }
  }
  return null;
}

({
  _PlacementNeed need,
  _GeneratedStonePlacement placement,
})? _fitLatticeStationNearNeed({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed need,
  required _GeneratedStonePlacement previous,
  required _GeneratedStonePlacement? next,
  required int searchRadiusPx,
  required _StonePrimitiveCatalog primitiveCatalog,
  required int variationPermille,
  required _StoneCollisionIndex collisionIndex,
  required int maximumOverlapPx,
  required int gapTolerancePx,
  required List<BorderDiagnostic> diagnostics,
  String? avoidedPrimitiveId,
}) {
  for (var magnitude = 1; magnitude <= searchRadiusPx; magnitude += 1) {
    final deltas = next == null
        ? <int>[magnitude, -magnitude]
        : <int>[-magnitude, magnitude];
    for (final delta in deltas) {
      final shiftedNeed = need.shiftAlongTangent(
        request: request,
        delta: delta,
      );
      if (shiftedNeed.distance == need.distance ||
          shiftedNeed.distance >= need.path.totalLengthPx) {
        continue;
      }
      final candidate = _generatePlacement(
        request: request,
        revision: revision,
        need: shiftedNeed,
        primitiveCatalog: primitiveCatalog,
        variationPermille: variationPermille,
        collisionIndex: collisionIndex,
        maximumOverlapPx: maximumOverlapPx,
        diagnostics: diagnostics,
        avoidedPrimitiveId: avoidedPrimitiveId,
        preferLongestTangent: true,
        previousPrimary: previous,
        nextPrimary: next,
        maximumGapPx: gapTolerancePx,
      );
      if (candidate == null ||
          _opaqueRectGap(
                previous.placement.opaqueWorldBoundsPx,
                candidate.placement.opaqueWorldBoundsPx,
              ) >
              gapTolerancePx ||
          (next != null &&
              _opaqueRectGap(
                    candidate.placement.opaqueWorldBoundsPx,
                    next.placement.opaqueWorldBoundsPx,
                  ) >
                  gapTolerancePx)) {
        continue;
      }
      return (need: shiftedNeed, placement: candidate);
    }
  }
  return null;
}

List<_GeneratedStonePlacement> _turnConnectorCandidates({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed cornerNeed,
  required _GeneratedStonePlacement corner,
  required bool incoming,
  required int normalOffset,
  required _StonePrimitiveCatalog primitiveCatalog,
  required int variationPermille,
  required _StoneCollisionIndex collisionIndex,
  required int maximumOverlapPx,
  required int gapTolerancePx,
  required List<BorderDiagnostic> diagnostics,
  _GeneratedStonePlacement? adjacentPrimary,
  String? avoidedPrimitiveId,
}) {
  final result = <_GeneratedStonePlacement>[];
  final maximumOffset = _maximum(
    request.tileSizePx.width,
    request.tileSizePx.height,
  );
  final isSharedShortLeg = !incoming && adjacentPrimary != null;
  final maximumNormalAdjustment = _maximum(
    isSharedShortLeg ? 4 : 1,
    _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 16,
  );
  final normalAdjustments = isSharedShortLeg
      ? <int>[
          // A one-cell step needs a visible bow, but a three- or four-pixel
          // displacement makes the middle stone read as a detached pebble at
          // 100% editor zoom. Keep the connector inside a shallow two-pixel
          // arc so its opaque body remains visually tied to both corners.
          for (final adjustment in const <int>[1, 2, 0])
            if (adjustment <= maximumNormalAdjustment) adjustment,
          for (var magnitude = 1;
              magnitude <= maximumNormalAdjustment;
              magnitude += 1)
            -magnitude,
        ]
      : <int>[
          0,
          for (var magnitude = 1;
              magnitude <= maximumNormalAdjustment;
              magnitude += 1) ...<int>[
            -magnitude,
            magnitude,
          ],
        ];
  // Prefer the farthest still-connected stone so each connector actually
  // occupies its leg instead of both siblings clustering at the vertex.
  for (var offset = maximumOffset; offset >= 0; offset -= 1) {
    final baseNeed = _turnConnectorNeed(
      request: request,
      cornerNeed: cornerNeed,
      incoming: incoming,
      offset: offset,
      normalOffset: normalOffset,
    );
    for (final adjustment in normalAdjustments) {
      final need = baseNeed.shiftAlongNormal(
        request: request,
        delta: adjustment,
      );
      final placement = _generatePlacement(
        request: request,
        revision: revision,
        need: need,
        primitiveCatalog: primitiveCatalog,
        variationPermille: variationPermille,
        collisionIndex: collisionIndex,
        maximumOverlapPx: maximumOverlapPx,
        diagnostics: diagnostics,
        avoidedPrimitiveId: avoidedPrimitiveId,
        previousPrimary: incoming ? adjacentPrimary : corner,
        nextPrimary: incoming ? corner : adjacentPrimary,
        maximumGapPx: gapTolerancePx,
      );
      if (placement == null) continue;
      // Adjacent corner recipes can meet on a one-cell zigzag. Do not let an
      // incoming connector cross behind the outgoing connector already
      // reserved by the previous corner in traversal order.
      if (incoming &&
          adjacentPrimary != null &&
          placement.pathDistance < adjacentPrimary.pathDistance) {
        continue;
      }
      final connectorBounds = placement.placement.opaqueWorldBoundsPx;
      if (_opaqueRectGap(
            corner.placement.opaqueWorldBoundsPx,
            connectorBounds,
          ) <=
          gapTolerancePx) {
        result.add(placement);
      }
    }
  }
  return result;
}

_GeneratedStonePlacement? _latestPrimaryBefore(
  Iterable<_GeneratedStonePlacement> placements, {
  required String strokeId,
  required int pathDistance,
}) {
  _GeneratedStonePlacement? latest;
  for (final placement in placements) {
    if (!placement.isPrimary ||
        placement.strokeId != strokeId ||
        placement.pathDistance >= pathDistance) {
      continue;
    }
    if (latest == null || placement.pathDistance > latest.pathDistance) {
      latest = placement;
    }
  }
  return latest;
}

List<_GeneratedStonePlacement>? _firstCompatibleTurnConnectorPair(
  List<_GeneratedStonePlacement> incoming,
  List<_GeneratedStonePlacement> outgoing, {
  required int maximumOverlapPx,
}) {
  for (final first in incoming) {
    for (final second in outgoing) {
      if (_tangentOverlap(first, second) <= maximumOverlapPx) {
        return <_GeneratedStonePlacement>[first, second];
      }
    }
  }
  return null;
}

_PlacementNeed _turnConnectorNeed({
  required BorderResolutionRequest request,
  required _PlacementNeed cornerNeed,
  required bool incoming,
  required int offset,
  required int normalOffset,
}) {
  final path = cornerNeed.path;
  final vertexIndex = cornerNeed.stationOrdinal;
  final edge = incoming
      ? path.edges[(vertexIndex - 1 + path.edges.length) % path.edges.length]
      : path.edges[vertexIndex % path.edges.length];
  final vertex = path.points[vertexIndex];
  final alongSign = incoming ? -1 : 1;
  final sideSign = request.feature.lineSide == BorderLineSide.primary ? 1 : -1;
  final normalX = -edge.directionY * sideSign;
  final normalY = edge.directionX * sideSign;
  var distance = cornerNeed.distance + alongSign * offset;
  if (path.closed) {
    distance %= path.totalLengthPx;
  } else {
    distance = distance.clamp(0, path.totalLengthPx);
  }
  final target = BorderPixelPos(
    x: vertex.x * request.tileSizePx.width +
        edge.directionX * alongSign * offset +
        normalX * normalOffset,
    y: vertex.y * request.tileSizePx.height +
        edge.directionY * alongSign * offset +
        normalY * normalOffset,
  );
  final rank = cornerNeed.stableOrdinal * 2 + (incoming ? 0 : 1);
  return _PlacementNeed(
    featureId: request.feature.id,
    path: path,
    distance: distance,
    stationOrdinal: rank,
    semanticRole: BorderPrimitiveRole.structureMedium,
    passIndex: 0,
    tangentX: edge.directionX,
    tangentY: edge.directionY,
    normalX: normalX,
    normalY: normalY,
    targetAnchorWorldPx: target,
    anchorCell: _anchorCell(request, target),
    slotKey: buildBorderStoneChainNodeSlotKey(
      featureId: request.feature.id,
      strokeId: path.lineageId,
      vertex: vertex,
      passIndex: 0,
      role: BorderPrimitiveRole.structureMedium,
      rank: rank,
    ),
    isSpecial: true,
    isPrimary: true,
  );
}

_PlacementNeed _nodeNeed({
  required BorderResolutionRequest request,
  required _StonePath path,
  required GridPos vertex,
  required int distance,
  required int tangentX,
  required int tangentY,
  required int normalX,
  required int normalY,
  required BorderPrimitiveRole role,
  required int rank,
  int? slotRank,
  required int normalOffset,
  required int tangentOffset,
}) {
  final identityRank = slotRank ?? rank;
  final sideSign = request.feature.lineSide == BorderLineSide.primary ? 1 : -1;
  final target = BorderPixelPos(
    x: vertex.x * request.tileSizePx.width +
        tangentX * tangentOffset +
        normalX * normalOffset * sideSign,
    y: vertex.y * request.tileSizePx.height +
        tangentY * tangentOffset +
        normalY * normalOffset * sideSign,
  );
  return _PlacementNeed(
    featureId: request.feature.id,
    path: path,
    distance: distance,
    stationOrdinal: rank,
    semanticRole: role,
    passIndex: 0,
    tangentX: tangentX,
    tangentY: tangentY,
    normalX: normalX * sideSign,
    normalY: normalY * sideSign,
    targetAnchorWorldPx: target,
    anchorCell: _anchorCell(request, target),
    slotKey: buildBorderStoneChainNodeSlotKey(
      featureId: request.feature.id,
      strokeId: path.lineageId,
      vertex: vertex,
      passIndex: 0,
      role: role,
      rank: identityRank,
    ),
    isSpecial: true,
    isPrimary: true,
    stableOrderOrdinal: identityRank,
  );
}

_PlacementNeed _stationNeed({
  required BorderResolutionRequest request,
  required _StonePath path,
  required _PathSample sample,
  required int distance,
  required int ordinal,
  required BorderPrimitiveRole role,
  required int passIndex,
  required int normalOffset,
}) {
  final sideSign = request.feature.lineSide == BorderLineSide.primary ? 1 : -1;
  final normalX = -sample.tangentY * sideSign;
  final normalY = sample.tangentX * sideSign;
  final target = BorderPixelPos(
    x: sample.worldX + normalX * normalOffset,
    y: sample.worldY + normalY * normalOffset,
  );
  return _PlacementNeed(
    featureId: request.feature.id,
    path: path,
    distance: distance,
    stationOrdinal: ordinal,
    semanticRole: role,
    passIndex: passIndex,
    tangentX: sample.tangentX,
    tangentY: sample.tangentY,
    normalX: normalX,
    normalY: normalY,
    targetAnchorWorldPx: target,
    anchorCell: _anchorCell(request, target),
    slotKey: buildBorderStoneChainStationSlotKey(
      featureId: request.feature.id,
      strokeId: path.lineageId,
      runStart: sample.edgeStart,
      runEnd: sample.edgeEnd,
      stationOrdinal: sample.localOffsetPx,
      passIndex: passIndex,
      role: role,
      rank: sample.generationEdgeIndex,
    ),
    isSpecial: false,
    isPrimary: passIndex == 0,
    stableOrderOrdinal: sample.generationEdgeIndex,
    slotRunStart: sample.edgeStart,
    slotRunEnd: sample.edgeEnd,
    slotStationOffsetPx: sample.localOffsetPx,
    slotGenerationEdgeIndex: sample.generationEdgeIndex,
  );
}

_GeneratedStonePlacement? _generateAttachedFillerPlacement({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed need,
  required _StonePrimitiveCatalog primitiveCatalog,
  required int variationPermille,
  required _StoneCollisionIndex collisionIndex,
  required int maximumOverlapPx,
  required List<_GeneratedStonePlacement> primaryPlacements,
  required int maximumAttachmentGapPx,
  required List<BorderDiagnostic> diagnostics,
}) {
  final maximumInwardShift = need.semanticRole ==
          BorderPrimitiveRole.structureMedium
      ? _maximum(
          5,
          _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 4,
        )
      : _maximum(
          3,
          _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 4,
        );
  // Preserve the original 0..5 deterministic preference even when the
  // attachment search has to reach farther inward. Deriving the preferred
  // offset from the full search radius would reshuffle every existing detail
  // whenever that safety radius changes, despite their stable slot keys.
  final preferredInwardShiftLimit = _minimum(5, maximumInwardShift);
  final preferredInwardShift =
      BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
    BorderRngKeyComponent.text(
      need.semanticRole == BorderPrimitiveRole.filler
          ? 'stone-chain-filler-attachment-depth'
          : 'stone-chain-detail-attachment-depth',
    ),
    BorderRngKeyComponent.text(request.blueprintId),
    BorderRngKeyComponent.signedInt64(
      BorderSignedInt64.fromInt(revision.revision),
    ),
    BorderRngKeyComponent.signedInt64(request.feature.seed),
    BorderRngKeyComponent.text(need.deterministicSlotKey),
  ]).nextIndex(preferredInwardShiftLimit + 1);
  final inwardShifts = <int>[preferredInwardShift];
  for (var distance = 1; distance <= maximumInwardShift; distance += 1) {
    final deeper = preferredInwardShift + distance;
    if (deeper <= maximumInwardShift) inwardShifts.add(deeper);
    final shallower = preferredInwardShift - distance;
    if (shallower >= 0) inwardShifts.add(shallower);
  }
  final maximumTangentShift = _maximum(
    (request.feature.paramsOverride ?? revision.definition.defaults)
        .gapTolerancePx,
    _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 4,
  );
  // The depth row is sparse by design. A +/-2px midpoint phase still forms a
  // conspicuous metronomic cadence once the editor scales sprites; allow the
  // authored gap tolerance plus one pixel so adjacent details visibly stagger
  // while the attachment test below continues to guarantee contact.
  final preferredTangentLimit = _minimum(5, maximumTangentShift + 1);
  final preferredTangentShift =
      BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
            const BorderRngKeyComponent.text(
                'stone-chain-detail-tangent-phase'),
            BorderRngKeyComponent.text(request.blueprintId),
            BorderRngKeyComponent.signedInt64(
              BorderSignedInt64.fromInt(revision.revision),
            ),
            BorderRngKeyComponent.signedInt64(request.feature.seed),
            BorderRngKeyComponent.text(need.deterministicSlotKey),
          ]).nextIndex(preferredTangentLimit * 2 + 1) -
          preferredTangentLimit;
  final tangentShifts = <int>[preferredTangentShift];
  for (var distance = 1; distance <= preferredTangentLimit * 2; distance += 1) {
    final deeper = preferredTangentShift + distance;
    if (deeper <= preferredTangentLimit) tangentShifts.add(deeper);
    final shallower = preferredTangentShift - distance;
    if (shallower >= -preferredTangentLimit) tangentShifts.add(shallower);
  }
  for (var distance = preferredTangentLimit + 1;
      distance <= maximumTangentShift;
      distance += 1) {
    tangentShifts
      ..add(-distance)
      ..add(distance);
  }
  for (final inwardShift in inwardShifts) {
    for (final tangentShift in tangentShifts) {
      final placement = _generatePlacement(
        request: request,
        revision: revision,
        need: need
            .shiftAlongNormal(
              request: request,
              delta: -inwardShift,
            )
            .shiftAlongTangent(
              request: request,
              delta: tangentShift,
            ),
        primitiveCatalog: primitiveCatalog,
        variationPermille: variationPermille,
        collisionIndex: collisionIndex,
        maximumOverlapPx: maximumOverlapPx,
        diagnostics: <BorderDiagnostic>[],
      );
      if (placement != null) {
        final attached =
            primaryPlacements.where((candidate) => candidate.isPrimary).any(
          (candidate) {
            final detailBounds = placement.placement.opaqueWorldBoundsPx;
            final primaryBounds = candidate.placement.opaqueWorldBoundsPx;
            if (_opaqueRectGap(detailBounds, primaryBounds) >
                maximumAttachmentGapPx) {
              return false;
            }
            if (need.semanticRole != BorderPrimitiveRole.structureMedium) {
              return true;
            }
            final normalOverlap = need.tangentX != 0
                ? _positiveOverlap(
                    detailBounds.y,
                    detailBounds.bottom,
                    primaryBounds.y,
                    primaryBounds.bottom,
                  )
                : _positiveOverlap(
                    detailBounds.x,
                    detailBounds.right,
                    primaryBounds.x,
                    primaryBounds.right,
                  );
            final tangentOverlap = need.tangentX != 0
                ? _positiveOverlap(
                    detailBounds.x,
                    detailBounds.right,
                    primaryBounds.x,
                    primaryBounds.right,
                  )
                : _positiveOverlap(
                    detailBounds.y,
                    detailBounds.bottom,
                    primaryBounds.y,
                    primaryBounds.bottom,
                  );
            return normalOverlap >= 2 && tangentOverlap > 0;
          },
        );
        if (attached) return placement;
      }
    }
  }
  // Preserve the actionable transform diagnostic when no attached detail can
  // be built. The second row is optional, so a detached fallback must not be
  // emitted merely to satisfy the authored density quota.
  _generatePlacement(
    request: request,
    revision: revision,
    need: need.shiftAlongNormal(request: request, delta: -1),
    primitiveCatalog: primitiveCatalog,
    variationPermille: variationPermille,
    collisionIndex: collisionIndex,
    maximumOverlapPx: maximumOverlapPx,
    diagnostics: diagnostics,
  );
  return null;
}

_GeneratedStonePlacement? _generatePlacement({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed need,
  required _StonePrimitiveCatalog primitiveCatalog,
  required int variationPermille,
  required _StoneCollisionIndex collisionIndex,
  required int maximumOverlapPx,
  required List<BorderDiagnostic> diagnostics,
  String? avoidedPrimitiveId,
  bool preferLongestTangent = false,
  _GeneratedStonePlacement? previousPrimary,
  _GeneratedStonePlacement? nextPrimary,
  int? maximumGapPx,
}) {
  final parameters =
      request.feature.paramsOverride ?? revision.definition.defaults;
  final allowAutoRotation = parameters.allowAutoRotation;
  final effectiveNeed = need.shiftAlongNormal(
    request: request,
    delta: _deterministicNormalJitter(
      request: request,
      revision: revision,
      need: need,
      irregularityPermille: parameters.irregularityPermille,
    ),
  );
  final roleOrder =
      need.isSpecial && need.semanticRole == BorderPrimitiveRole.structureMedium
          ? const <BorderPrimitiveRole>[
              BorderPrimitiveRole.structureMedium,
              BorderPrimitiveRole.filler,
            ]
          : switch (need.semanticRole) {
              BorderPrimitiveRole.lineCorner => const <BorderPrimitiveRole>[
                  BorderPrimitiveRole.lineCorner,
                  BorderPrimitiveRole.structureLarge,
                ],
              BorderPrimitiveRole.lineCap => const <BorderPrimitiveRole>[
                  BorderPrimitiveRole.lineCap,
                  BorderPrimitiveRole.structureLarge,
                ],
              BorderPrimitiveRole.structureLarge => const <BorderPrimitiveRole>[
                  BorderPrimitiveRole.structureLarge,
                  BorderPrimitiveRole.structureMedium,
                  BorderPrimitiveRole.filler,
                ],
              _ => <BorderPrimitiveRole>[need.semanticRole],
            };
  final canChooseVerticalOrientation = allowAutoRotation &&
      need.passIndex == 0 &&
      !need.isSpecial &&
      need.tangentX == 0;
  final preferredQuarterTurns = canChooseVerticalOrientation ? 1 : 0;
  final quarterTurnAttempts =
      canChooseVerticalOrientation ? const <int>[1, 0] : const <int>[0];
  final stationQuantum = _maximum(
    1,
    _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 2,
  );
  final effectiveGapTolerance = maximumGapPx ?? parameters.gapTolerancePx;
  var hadTransformCandidate = false;
  for (final quarterTurns in quarterTurnAttempts) {
    for (final role in roleOrder) {
      final indexedCandidates = primitiveCatalog.candidates(
        role: role,
        quarterTurns: quarterTurns,
      );
      final candidates = quarterTurns == 1 &&
              need.isPrimary &&
              !need.isSpecial &&
              need.tangentX == 0
          ? indexedCandidates
              .where(
                (primitive) => !_rotatedPrimaryNeedsNativeContinuityFallback(
                  primitive: primitive,
                  need: need,
                  quarterTurns: quarterTurns,
                  stationQuantum: stationQuantum,
                  gapTolerancePx: effectiveGapTolerance,
                ),
              )
              .toList(growable: false)
          : indexedCandidates;
      if (candidates.isEmpty) continue;
      hadTransformCandidate = true;
      final eligibleCandidates = avoidedPrimitiveId != null &&
              candidates.any((candidate) => candidate.id != avoidedPrimitiveId)
          ? candidates
              .where((candidate) => candidate.id != avoidedPrimitiveId)
              .toList(growable: false)
          : candidates;
      final prefersSmallest =
          need.semanticRole == BorderPrimitiveRole.lineCap &&
              role == BorderPrimitiveRole.structureLarge;
      final prefersLongestConnector = preferLongestTangent ||
          (need.semanticRole == BorderPrimitiveRole.structureLarge &&
              role != BorderPrimitiveRole.structureLarge);
      late final List<BorderPublishedPrimitive> attempts;
      if (prefersSmallest) {
        attempts = eligibleCandidates.toList(growable: false)
          ..sort(_compareOpaqueAreaThenId);
      } else if (prefersLongestConnector) {
        attempts = eligibleCandidates.toList(growable: false)
          ..sort(
            (left, right) => _compareTangentExtentDescending(
              left,
              right,
              tangentX: need.tangentX,
              quarterTurns: quarterTurns,
            ),
          );
      } else if (variationPermille == 0) {
        attempts = eligibleCandidates;
      } else {
        final preferred = _choosePrimitive(
          request: request,
          revision: revision,
          slotKey: need.deterministicSlotKey,
          candidates: eligibleCandidates,
          variationPermille: variationPermille,
          avoidedPrimitiveId: avoidedPrimitiveId,
        );
        final remainingCandidates = eligibleCandidates
            .where((candidate) => candidate.id != preferred.id)
            .toList(growable: false);
        if (remainingCandidates.length > 1) {
          final indexById = <String, int>{
            for (var index = 0; index < eligibleCandidates.length; index += 1)
              eligibleCandidates[index].id: index,
          };
          final start = need.candidateOrderOrdinal % eligibleCandidates.length;
          remainingCandidates.sort((left, right) {
            final leftDistance =
                (indexById[left.id]! - start) % eligibleCandidates.length;
            final rightDistance =
                (indexById[right.id]! - start) % eligibleCandidates.length;
            final byDistance = leftDistance.compareTo(rightDistance);
            return byDistance != 0 ? byDistance : left.id.compareTo(right.id);
          });
        }
        attempts = <BorderPublishedPrimitive>[
          preferred,
          ...remainingCandidates,
        ];
      }
      candidateAttempts:
      for (final selected in attempts) {
        final candidateBounds = primitiveCatalog.opaqueWorldBounds(
          primitive: selected,
          quarterTurns: quarterTurns,
          targetAnchorWorldPx: effectiveNeed.targetAnchorWorldPx,
        );
        if (!_rectIntersectsCanvas(
          candidateBounds,
          width: request.mapSize.width * request.tileSizePx.width,
          height: request.mapSize.height * request.tileSizePx.height,
        )) {
          continue candidateAttempts;
        }
        if (maximumGapPx != null &&
            ((previousPrimary != null &&
                    _opaqueRectGap(
                          previousPrimary.placement.opaqueWorldBoundsPx,
                          candidateBounds,
                        ) >
                        maximumGapPx) ||
                (nextPrimary != null &&
                    _opaqueRectGap(
                          candidateBounds,
                          nextPrimary.placement.opaqueWorldBoundsPx,
                        ) >
                        maximumGapPx))) {
          continue candidateAttempts;
        }
        if (_exceedsOverlapBudgetForBounds(
          bounds: candidateBounds,
          tangentX: effectiveNeed.tangentX,
          collisionIndex: collisionIndex,
          budget: maximumOverlapPx,
        )) {
          continue candidateAttempts;
        }
        final build = _buildPlacement(
          request: request,
          need: effectiveNeed,
          selected: selected,
          quarterTurns: quarterTurns,
        );
        switch (build) {
          case _PlacementBuildAccepted(:final placement):
            return placement;
          case _PlacementBuildRejected():
            continue candidateAttempts;
        }
      }
    }
  }
  if (avoidedPrimitiveId != null) {
    // Repetition avoidance is a preference, not an eligibility rule. Retry
    // without it only after every other role and transform has failed, so a
    // constrained run stays continuous without sacrificing normal variety.
    return _generatePlacement(
      request: request,
      revision: revision,
      need: need,
      primitiveCatalog: primitiveCatalog,
      variationPermille: variationPermille,
      collisionIndex: collisionIndex,
      maximumOverlapPx: maximumOverlapPx,
      diagnostics: diagnostics,
      preferLongestTangent: preferLongestTangent,
      previousPrimary: previousPrimary,
      nextPrimary: nextPrimary,
      maximumGapPx: maximumGapPx,
    );
  }
  if (!hadTransformCandidate) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.stone_chain_transform_unavailable',
        scope: BorderDiagnosticScope.segment,
        strokeId: need.path.strokeId,
        cell: need.anchorCell,
        parameters: <String, Object?>{
          'role': borderPrimitiveRoleV1WireName(need.semanticRole),
          'quarterTurns': preferredQuarterTurns,
        },
        action: 'border.action.allow_required_stone_chain_transform',
      ),
    );
  }
  return null;
}

_PlacementBuildResult _buildPlacement({
  required BorderResolutionRequest request,
  required _PlacementNeed need,
  required BorderPublishedPrimitive selected,
  required int quarterTurns,
}) {
  final transform = BorderSpriteTransform(
    quarterTurns: quarterTurns,
    flipX: false,
  );
  final sprite = resolveBorderSpriteGeometry(
    metrics: selected.publishedMetrics,
    sourceAnchorPx: selected.anchorPx,
    transform: transform,
    targetAnchorWorldPx: need.targetAnchorWorldPx,
  );
  final canvas = GridSize(
    width: request.mapSize.width * request.tileSizePx.width,
    height: request.mapSize.height * request.tileSizePx.height,
  );
  if (!borderPixelRectIntersectsCanvas(
    rect: sprite.opaqueWorldBoundsPx,
    canvasSizePx: canvas,
  )) {
    return const _PlacementBuildRejected(
      _PlacementBuildRejection.outsideCanvas,
    );
  }
  return _PlacementBuildAccepted(
    _GeneratedStonePlacement(
      placement: BorderResolvedPlacement(
        id: 'border-placement-v1:'
            '${need.slotKey.substring(borderSlotKeyV1Prefix.length)}',
        slotKey: need.slotKey,
        primitiveId: selected.id,
        visualSnapshotId: selected.visualSnapshotId,
        anchorCell: need.anchorCell,
        topLeftWorldPx: sprite.topLeftWorldPx,
        opaqueWorldBoundsPx: sprite.opaqueWorldBoundsPx,
        transform: transform,
        drawBand: need.drawBand,
        stableOrderKey: buildBorderStableOrderKey(
          drawBand: need.drawBand,
          mapWidth: request.mapSize.width,
          anchorCell: need.anchorCell,
          passIndex: need.passIndex,
          rank: need.isSpecial ? 0 : 1,
          ordinalLocal: need.stableOrdinal,
          slotKey: need.slotKey,
        ),
      ),
      semanticRole: need.semanticRole,
      strokeId: need.path.strokeId,
      pathDistance: need.distance,
      tangentX: need.tangentX,
      tangentY: need.tangentY,
      pathClosed: need.path.closed,
      isPrimary: need.isPrimary,
      isSpecial: need.isSpecial,
    ),
  );
}

int _compareOpaqueAreaThenId(
  BorderPublishedPrimitive left,
  BorderPublishedPrimitive right,
) {
  final leftBounds = left.publishedMetrics.opaqueBounds;
  final rightBounds = right.publishedMetrics.opaqueBounds;
  final byArea = (leftBounds.width * leftBounds.height)
      .compareTo(rightBounds.width * rightBounds.height);
  return byArea != 0 ? byArea : left.id.compareTo(right.id);
}

bool _rotatedPrimaryNeedsNativeContinuityFallback({
  required BorderPublishedPrimitive primitive,
  required _PlacementNeed need,
  required int quarterTurns,
  required int stationQuantum,
  required int gapTolerancePx,
}) {
  if (quarterTurns != 1 ||
      !need.isPrimary ||
      need.isSpecial ||
      need.tangentX != 0 ||
      !primitive.transforms.allowedQuarterTurns.contains(0)) {
    return false;
  }
  final bounds = primitive.publishedMetrics.opaqueBounds;
  final rotatedTangentExtent = bounds.width;
  final nativeTangentExtent = bounds.height;
  return rotatedTangentExtent + gapTolerancePx < stationQuantum &&
      nativeTangentExtent + gapTolerancePx >= stationQuantum;
}

int _compareTangentExtentDescending(
  BorderPublishedPrimitive left,
  BorderPublishedPrimitive right, {
  required int tangentX,
  required int quarterTurns,
}) {
  int extent(BorderPublishedPrimitive primitive) {
    final bounds = primitive.publishedMetrics.opaqueBounds;
    final transformedWidth = quarterTurns.isEven ? bounds.width : bounds.height;
    final transformedHeight =
        quarterTurns.isEven ? bounds.height : bounds.width;
    return tangentX != 0 ? transformedWidth : transformedHeight;
  }

  final byExtent = extent(right).compareTo(extent(left));
  return byExtent != 0 ? byExtent : _compareOpaqueAreaThenId(left, right);
}

int _stoneChainStationQuantum({
  required List<BorderPublishedPrimitive> primitives,
  required int tangentX,
  required bool allowAutoRotation,
  required int densityFloor,
  required int maximumOverlapPx,
  required int gapTolerancePx,
}) {
  var maximumTangentExtent = 1;
  for (final primitive in primitives) {
    final bounds = primitive.publishedMetrics.opaqueBounds;
    if (tangentX != 0) {
      maximumTangentExtent = _maximum(maximumTangentExtent, bounds.width);
      continue;
    }
    maximumTangentExtent = _maximum(maximumTangentExtent, bounds.height);
    if (allowAutoRotation &&
        primitive.transforms.allowedQuarterTurns.contains(1)) {
      maximumTangentExtent = _maximum(maximumTangentExtent, bounds.width);
    }
  }
  if (maximumTangentExtent + gapTolerancePx >= densityFloor) {
    return densityFloor;
  }
  return _maximum(1, maximumTangentExtent - maximumOverlapPx);
}

BorderPublishedPrimitive _choosePrimitive({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required String slotKey,
  required List<BorderPublishedPrimitive> candidates,
  required int variationPermille,
  String? avoidedPrimitiveId,
}) {
  final selectable = variationPermille > 0 &&
          avoidedPrimitiveId != null &&
          candidates.length > 1
      ? candidates
          .where((candidate) => candidate.id != avoidedPrimitiveId)
          .toList(growable: false)
      : candidates;
  if (variationPermille == 0 || selectable.length == 1) {
    return selectable.first;
  }
  final rng = BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
    const BorderRngKeyComponent.text('stone-chain-primitive'),
    BorderRngKeyComponent.text(request.blueprintId),
    BorderRngKeyComponent.signedInt64(
      BorderSignedInt64.fromInt(revision.revision),
    ),
    BorderRngKeyComponent.signedInt64(request.feature.seed),
    BorderRngKeyComponent.text(slotKey),
  ]);
  if (variationPermille < 1000 && rng.nextIndex(1000) >= variationPermille) {
    return selectable.first;
  }
  return chooseBorderWeightedCandidate(
    rng,
    <BorderWeightedCandidate<BorderPublishedPrimitive>>[
      for (final candidate in selectable)
        BorderWeightedCandidate<BorderPublishedPrimitive>(
          id: candidate.id,
          value: candidate,
          weight: candidate.weight,
        ),
    ],
  )!
      .value;
}

int _deterministicTangentJitter({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed need,
  required int irregularityPermille,
}) {
  if (irregularityPermille <= 0 ||
      !need.isPrimary ||
      need.isSpecial ||
      need.semanticRole != BorderPrimitiveRole.structureLarge) {
    return 0;
  }
  // A moderate authored profile (Selbrume uses 280/1000) must reach the
  // second pixel occasionally; one source pixel is only three display pixels
  // in the editor and leaves long coast runs visually metronomic.
  final amplitude = _minimum(2, (4 * irregularityPermille + 999) ~/ 1000);
  return BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
        const BorderRngKeyComponent.text('stone-chain-tangent-jitter'),
        BorderRngKeyComponent.text(request.blueprintId),
        BorderRngKeyComponent.signedInt64(
          BorderSignedInt64.fromInt(revision.revision),
        ),
        BorderRngKeyComponent.signedInt64(request.feature.seed),
        BorderRngKeyComponent.text(need.deterministicSlotKey),
      ]).nextIndex(amplitude * 2 + 1) -
      amplitude;
}

int _deterministicNormalJitter({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required _PlacementNeed need,
  required int irregularityPermille,
}) {
  if (irregularityPermille <= 0) return 0;
  final maximumAtFullIrregularity = _maximum(
    1,
    _minimum(request.tileSizePx.width, request.tileSizePx.height) ~/ 16,
  );
  final amplitude =
      (maximumAtFullIrregularity * irregularityPermille + 999) ~/ 1000;
  return BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
        const BorderRngKeyComponent.text('stone-chain-normal-jitter'),
        BorderRngKeyComponent.text(request.blueprintId),
        BorderRngKeyComponent.signedInt64(
          BorderSignedInt64.fromInt(revision.revision),
        ),
        BorderRngKeyComponent.signedInt64(request.feature.seed),
        BorderRngKeyComponent.text(need.deterministicSlotKey),
      ]).nextIndex(amplitude * 2 + 1) -
      amplitude;
}

bool _isNearTurn(
  _PlacementNeed need,
  List<int> sortedTurnDistances, {
  required int radiusPx,
}) {
  if (sortedTurnDistances.isEmpty) return false;
  var low = 0;
  var high = sortedTurnDistances.length;
  while (low < high) {
    final middle = low + (high - low) ~/ 2;
    if (sortedTurnDistances[middle] < need.distance) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  bool isNear(int turnDistance) {
    final direct = (turnDistance - need.distance).abs();
    if (direct <= radiusPx) return true;
    return need.path.closed && need.path.totalLengthPx - direct <= radiusPx;
  }

  if (low < sortedTurnDistances.length && isNear(sortedTurnDistances[low])) {
    return true;
  }
  if (low > 0 && isNear(sortedTurnDistances[low - 1])) return true;
  if (need.path.closed && isNear(sortedTurnDistances.first)) return true;
  return need.path.closed && isNear(sortedTurnDistances.last);
}

_SecondaryDensitySelection _selectSecondaryDensityCandidates({
  required BorderResolutionRequest request,
  required BorderBlueprintRevision revision,
  required List<_PlacementNeed> candidates,
  required int desiredCount,
}) {
  final targetCount = desiredCount.clamp(0, candidates.length);
  if (targetCount <= 0) {
    return const _SecondaryDensitySelection(
      targetCount: 0,
      rankedCandidates: <_PlacementNeed>[],
    );
  }
  final ranksBySlotKey = <String, int>{
    for (final candidate in candidates)
      candidate.slotKey: BorderDeterministicRng.fromComponents(
        <BorderRngKeyComponent>[
          const BorderRngKeyComponent.text('stone-chain-secondary-density'),
          BorderRngKeyComponent.text(request.blueprintId),
          BorderRngKeyComponent.signedInt64(
            BorderSignedInt64.fromInt(revision.revision),
          ),
          BorderRngKeyComponent.signedInt64(request.feature.seed),
          BorderRngKeyComponent.text(candidate.deterministicSlotKey),
        ],
      ).nextIndex(0x7fffffff),
  };
  final ranked = candidates.toList(growable: false)
    ..sort((left, right) {
      final byRank = ranksBySlotKey[left.slotKey]!.compareTo(
        ranksBySlotKey[right.slotKey]!,
      );
      return byRank != 0 ? byRank : left.slotKey.compareTo(right.slotKey);
    });
  return _SecondaryDensitySelection(
    targetCount: targetCount,
    rankedCandidates: ranked,
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
    if (!_stoneChainRoles.contains(primitive.role)) {
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
    if (!_anchorInside(primitive.anchorPx, metrics.pixelSize) ||
        !_anchorInside(metrics.defaultAnchorPx, metrics.pixelSize)) {
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
    if (!_snapshotMatches(
      request.visualSnapshotById(primitive.visualSnapshotId),
      metrics.pixelSize,
    )) {
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

bool _exceedsOverlapBudgetForBounds({
  required BorderPixelRect bounds,
  required int tangentX,
  required _StoneCollisionIndex collisionIndex,
  required int budget,
}) {
  for (final other in collisionIndex.candidatesForBounds(bounds)) {
    if (_tangentOverlapWithBounds(
          firstBounds: bounds,
          firstTangentX: tangentX,
          second: other,
        ) >
        budget) {
      return true;
    }
  }
  return false;
}

int _tangentOverlap(
  _GeneratedStonePlacement first,
  _GeneratedStonePlacement second,
) =>
    _tangentOverlapWithBounds(
      firstBounds: first.placement.opaqueWorldBoundsPx,
      firstTangentX: first.tangentX,
      second: second,
    );

int _tangentOverlapWithBounds({
  required BorderPixelRect firstBounds,
  required int firstTangentX,
  required _GeneratedStonePlacement second,
}) {
  final a = firstBounds;
  final b = second.placement.opaqueWorldBoundsPx;
  if (!_rectanglesIntersect(a, b)) return 0;
  final overlapX = _maximum(0, _minimum(a.right, b.right) - _maximum(a.x, b.x));
  final overlapY =
      _maximum(0, _minimum(a.bottom, b.bottom) - _maximum(a.y, b.y));
  if ((firstTangentX != 0) != (second.tangentX != 0)) {
    return _minimum(overlapX, overlapY);
  }
  if (firstTangentX != 0) {
    return overlapX;
  }
  return overlapY;
}

int _maximumObservedOverlap(
  List<_GeneratedStonePlacement> placements, {
  required int bucketSizePx,
}) {
  var result = 0;
  final collisionIndex = _StoneCollisionIndex(bucketSizePx: bucketSizePx);
  for (final placement in placements) {
    for (final other in collisionIndex.candidatesFor(placement)) {
      if (placement.placement.stableOrderKey.passIndex !=
          other.placement.stableOrderKey.passIndex) {
        continue;
      }
      result = _maximum(result, _tangentOverlap(placement, other));
    }
    collisionIndex.add(placement);
  }
  return result;
}

int _opaqueRectGap(BorderPixelRect a, BorderPixelRect b) {
  final gapX = _maximum(
    0,
    _maximum(a.x, b.x) - _minimum(a.right, b.right),
  );
  final gapY = _maximum(
    0,
    _maximum(a.y, b.y) - _minimum(a.bottom, b.bottom),
  );
  return _maximum(gapX, gapY);
}

int _maximumObservedGap(List<_GeneratedStonePlacement> placements) {
  return _widestObservedGap(placements)?.gapPx ?? 0;
}

({
  String strokeId,
  int gapPx,
  int previousPathDistancePx,
  int nextPathDistancePx,
})? _widestObservedGap(
  List<_GeneratedStonePlacement> placements,
) {
  ({
    String strokeId,
    int gapPx,
    int previousPathDistancePx,
    int nextPathDistancePx,
  })? widest;
  final groupsByStroke =
      <String, SplayTreeMap<int, List<_GeneratedStonePlacement>>>{};
  void record(
    String strokeId,
    int gapPx,
    int previousPathDistancePx,
    int nextPathDistancePx,
  ) {
    if (widest == null || gapPx > widest!.gapPx) {
      widest = (
        strokeId: strokeId,
        gapPx: gapPx,
        previousPathDistancePx: previousPathDistancePx,
        nextPathDistancePx: nextPathDistancePx,
      );
    }
  }

  for (final placement in placements) {
    // A corner and its zero-offset connectors share one path station. Their
    // slot-hash order is not a traversal order, so treat them as one connected
    // recipe node and measure continuity between successive nodes.
    groupsByStroke
        .putIfAbsent(
          placement.strokeId,
          () => SplayTreeMap<int, List<_GeneratedStonePlacement>>(),
        )
        .putIfAbsent(
          placement.pathDistance,
          () => <_GeneratedStonePlacement>[],
        )
        .add(placement);
  }
  for (final entry in groupsByStroke.entries) {
    final groups = entry.value.values.toList(growable: false);
    for (var index = 1; index < groups.length; index += 1) {
      record(
        entry.key,
        _minimumOpaqueGapBetween(groups[index - 1], groups[index]),
        groups[index - 1].first.pathDistance,
        groups[index].first.pathDistance,
      );
    }
    if (groups.length > 1 && groups.first.first.pathClosed) {
      record(
        entry.key,
        _minimumOpaqueGapBetween(groups.last, groups.first),
        groups.last.first.pathDistance,
        groups.first.first.pathDistance,
      );
    }
  }
  return widest;
}

int _minimumOpaqueGapBetween(
  List<_GeneratedStonePlacement> first,
  List<_GeneratedStonePlacement> second,
) {
  var minimum = 0x7fffffff;
  for (final left in first) {
    for (final right in second) {
      minimum = _minimum(
        minimum,
        _opaqueRectGap(
          left.placement.opaqueWorldBoundsPx,
          right.placement.opaqueWorldBoundsPx,
        ),
      );
    }
  }
  return minimum;
}

({String strokeId, int gapPx})? _widestClosedSeam(
  Iterable<_GeneratedStonePlacement> placements,
) {
  final groupsByStroke =
      <String, SplayTreeMap<int, List<_GeneratedStonePlacement>>>{};
  for (final placement in placements) {
    if (!placement.pathClosed) continue;
    groupsByStroke
        .putIfAbsent(
          placement.strokeId,
          () => SplayTreeMap<int, List<_GeneratedStonePlacement>>(),
        )
        .putIfAbsent(
          placement.pathDistance,
          () => <_GeneratedStonePlacement>[],
        )
        .add(placement);
  }
  ({String strokeId, int gapPx})? widest;
  for (final entry in groupsByStroke.entries) {
    final groups = entry.value.values.toList(growable: false);
    if (groups.length < 2) continue;
    final gap = _minimumOpaqueGapBetween(groups.last, groups.first);
    if (widest == null || gap > widest.gapPx) {
      widest = (strokeId: entry.key, gapPx: gap);
    }
  }
  return widest;
}

int _maximumCornerThicknessRatioPermille(
  List<_GeneratedStonePlacement> placements, {
  required Set<String> straightPrimitiveIds,
}) {
  int thickness(_GeneratedStonePlacement placement) {
    final bounds = placement.placement.opaqueWorldBoundsPx;
    return _minimum(bounds.width, bounds.height);
  }

  final straightThicknesses = placements
      .where(
        (placement) =>
            straightPrimitiveIds.contains(placement.placement.primitiveId),
      )
      .map(thickness)
      .toList(growable: false)
    ..sort();
  final cornerThicknesses = placements
      .where(
        (placement) => placement.semanticRole == BorderPrimitiveRole.lineCorner,
      )
      .map(thickness)
      .toList(growable: false);
  if (straightThicknesses.isEmpty || cornerThicknesses.isEmpty) return 0;
  final middle = straightThicknesses.length ~/ 2;
  final median = straightThicknesses.length.isOdd
      ? straightThicknesses[middle]
      : (straightThicknesses[middle - 1] + straightThicknesses[middle]) ~/ 2;
  final maximumCorner = cornerThicknesses.reduce(_maximum);
  return maximumCorner * 1000 ~/ median;
}

int _maximumRepeat(List<_GeneratedStonePlacement> placements) {
  if (placements.isEmpty) return 0;
  var maximum = 1;
  var current = 1;
  for (var index = 1; index < placements.length; index += 1) {
    if (placements[index].placement.primitiveId ==
        placements[index - 1].placement.primitiveId) {
      current += 1;
      maximum = _maximum(maximum, current);
    } else {
      current = 1;
    }
  }
  return maximum;
}

Set<String> _pruneRedundantPrimaryFillers({
  required List<_GeneratedStonePlacement> generated,
  required List<BorderPublishedPrimitive> primitives,
  required int gapTolerancePx,
}) {
  final rolesByPrimitiveId = <String, BorderPrimitiveRole>{
    for (final primitive in primitives) primitive.id: primitive.role,
  };
  final ordered = generated
      .where((placement) => placement.isPrimary)
      .toList(growable: true)
    ..sort(_compareGenerated);
  final removedSlotKeys = <String>{};
  var index = 1;
  while (index + 1 < ordered.length) {
    final previous = ordered[index - 1];
    final current = ordered[index];
    final next = ordered[index + 1];
    final isRedundantFiller = !current.isSpecial &&
        rolesByPrimitiveId[current.placement.primitiveId] ==
            BorderPrimitiveRole.filler &&
        previous.strokeId == current.strokeId &&
        next.strokeId == current.strokeId &&
        previous.tangentX == current.tangentX &&
        previous.tangentY == current.tangentY &&
        next.tangentX == current.tangentX &&
        next.tangentY == current.tangentY &&
        _opaqueRectGap(
              previous.placement.opaqueWorldBoundsPx,
              next.placement.opaqueWorldBoundsPx,
            ) <=
            gapTolerancePx;
    if (!isRedundantFiller) {
      index += 1;
      continue;
    }
    removedSlotKeys.add(current.placement.slotKey);
    ordered.removeAt(index);
  }
  if (removedSlotKeys.isNotEmpty) {
    generated.removeWhere(
      (placement) => removedSlotKeys.contains(placement.placement.slotKey),
    );
  }
  return removedSlotKeys;
}

/// Tucks a sparse primary recipe by the minimum whole-pixel delta required to
/// meet the authored gap contract. Turn connectors are reserved before the
/// straight lattice, so a later station can occasionally end one pixel beyond
/// the connector's continuity budget even though both placements were valid
/// against the neighbours known when they were generated.
///
/// The repair never changes slots, density, transforms or primitive choice. A
/// candidate is accepted only when it reduces the targeted gap without
/// increasing the global maximum gap or exceeding the authored overlap budget.
bool _repairPrimaryContinuity({
  required List<_GeneratedStonePlacement> generated,
  required int gapTolerancePx,
  required int maximumOverlapPx,
  required int bucketSizePx,
}) {
  var changed = false;
  final maximumAttempts = generated.length * 2;
  for (var attempt = 0; attempt < maximumAttempts; attempt += 1) {
    final primary = generated
        .where((placement) => placement.isPrimary)
        .toList(growable: false);
    final widest = _widestObservedGap(primary);
    if (widest == null || widest.gapPx <= gapTolerancePx) return changed;

    final previousGroup = primary
        .where(
          (placement) =>
              placement.strokeId == widest.strokeId &&
              placement.pathDistance == widest.previousPathDistancePx,
        )
        .toList(growable: false);
    final nextGroup = primary
        .where(
          (placement) =>
              placement.strokeId == widest.strokeId &&
              placement.pathDistance == widest.nextPathDistancePx,
        )
        .toList(growable: false);
    if (previousGroup.isEmpty || nextGroup.isEmpty) return changed;

    final closest = _closestOpaquePair(previousGroup, nextGroup);
    final previousDelta = _tuckDelta(
      source: closest.previous.placement.opaqueWorldBoundsPx,
      target: closest.next.placement.opaqueWorldBoundsPx,
      gapTolerancePx: gapTolerancePx,
    );
    final nextDelta = _tuckDelta(
      source: closest.next.placement.opaqueWorldBoundsPx,
      target: closest.previous.placement.opaqueWorldBoundsPx,
      gapTolerancePx: gapTolerancePx,
    );
    final moves = nextGroup.any((placement) => placement.isSpecial)
        ? <({List<_GeneratedStonePlacement> group, int dx, int dy})>[
            (group: nextGroup, dx: nextDelta.$1, dy: nextDelta.$2),
            (
              group: previousGroup,
              dx: previousDelta.$1,
              dy: previousDelta.$2,
            ),
          ]
        : <({List<_GeneratedStonePlacement> group, int dx, int dy})>[
            (
              group: previousGroup,
              dx: previousDelta.$1,
              dy: previousDelta.$2,
            ),
            (group: nextGroup, dx: nextDelta.$1, dy: nextDelta.$2),
          ];

    var repaired = false;
    for (final move in moves) {
      if (move.dx == 0 && move.dy == 0) continue;
      final movedSlots = <String>{
        for (final placement in move.group) placement.placement.slotKey,
      };
      final candidate = <_GeneratedStonePlacement>[
        for (final placement in generated)
          if (movedSlots.contains(placement.placement.slotKey))
            _translateGeneratedPlacement(
              placement,
              dx: move.dx,
              dy: move.dy,
            )
          else
            placement,
      ];
      final candidatePrimary = candidate
          .where((placement) => placement.isPrimary)
          .toList(growable: false);
      final candidateWidest = _widestObservedGap(candidatePrimary);
      if (candidateWidest != null && candidateWidest.gapPx > widest.gapPx) {
        continue;
      }
      if (_maximumObservedOverlap(
            candidatePrimary,
            bucketSizePx: bucketSizePx,
          ) >
          maximumOverlapPx) {
        continue;
      }
      final candidatePrevious = candidatePrimary
          .where(
            (placement) =>
                placement.strokeId == widest.strokeId &&
                placement.pathDistance == widest.previousPathDistancePx,
          )
          .toList(growable: false);
      final candidateNext = candidatePrimary
          .where(
            (placement) =>
                placement.strokeId == widest.strokeId &&
                placement.pathDistance == widest.nextPathDistancePx,
          )
          .toList(growable: false);
      if (_minimumOpaqueGapBetween(candidatePrevious, candidateNext) >
          gapTolerancePx) {
        continue;
      }
      generated
        ..clear()
        ..addAll(candidate);
      changed = true;
      repaired = true;
      break;
    }
    if (!repaired) return changed;
  }
  return changed;
}

({
  _GeneratedStonePlacement previous,
  _GeneratedStonePlacement next,
}) _closestOpaquePair(
  List<_GeneratedStonePlacement> previous,
  List<_GeneratedStonePlacement> next,
) {
  var bestPrevious = previous.first;
  var bestNext = next.first;
  var bestGap = _opaqueRectGap(
    bestPrevious.placement.opaqueWorldBoundsPx,
    bestNext.placement.opaqueWorldBoundsPx,
  );
  for (final left in previous) {
    for (final right in next) {
      final gap = _opaqueRectGap(
        left.placement.opaqueWorldBoundsPx,
        right.placement.opaqueWorldBoundsPx,
      );
      if (gap < bestGap) {
        bestPrevious = left;
        bestNext = right;
        bestGap = gap;
      }
    }
  }
  return (previous: bestPrevious, next: bestNext);
}

(int, int) _tuckDelta({
  required BorderPixelRect source,
  required BorderPixelRect target,
  required int gapTolerancePx,
}) {
  var dx = 0;
  if (source.right <= target.x) {
    dx = _maximum(0, target.x - source.right - gapTolerancePx);
  } else if (target.right <= source.x) {
    dx = -_maximum(0, source.x - target.right - gapTolerancePx);
  }
  var dy = 0;
  if (source.bottom <= target.y) {
    dy = _maximum(0, target.y - source.bottom - gapTolerancePx);
  } else if (target.bottom <= source.y) {
    dy = -_maximum(0, source.y - target.bottom - gapTolerancePx);
  }
  return (dx, dy);
}

_GeneratedStonePlacement _translateGeneratedPlacement(
  _GeneratedStonePlacement source, {
  required int dx,
  required int dy,
}) {
  final placement = source.placement;
  final bounds = placement.opaqueWorldBoundsPx;
  return source.withPlacement(
    BorderResolvedPlacement(
      id: placement.id,
      slotKey: placement.slotKey,
      primitiveId: placement.primitiveId,
      visualSnapshotId: placement.visualSnapshotId,
      anchorCell: placement.anchorCell,
      topLeftWorldPx: BorderPixelPos(
        x: placement.topLeftWorldPx.x + dx,
        y: placement.topLeftWorldPx.y + dy,
      ),
      opaqueWorldBoundsPx: BorderPixelRect(
        x: bounds.x + dx,
        y: bounds.y + dy,
        width: bounds.width,
        height: bounds.height,
      ),
      transform: placement.transform,
      drawBand: placement.drawBand,
      stableOrderKey: placement.stableOrderKey,
    ),
  );
}

GridPos _anchorCell(BorderResolutionRequest request, BorderPixelPos target) {
  final x = (target.x ~/ request.tileSizePx.width)
      .clamp(0, request.mapSize.width - 1);
  final y = (target.y ~/ request.tileSizePx.height)
      .clamp(0, request.mapSize.height - 1);
  return GridPos(x: x, y: y);
}

int _compareNeeds(_PlacementNeed left, _PlacementNeed right) {
  var result = left.path.lineageId.compareTo(right.path.lineageId);
  if (result != 0) return result;
  result = left.distance.compareTo(right.distance);
  if (result != 0) return result;
  if (left.isSpecial != right.isSpecial) return left.isSpecial ? -1 : 1;
  return left.slotKey.compareTo(right.slotKey);
}

int _compareGenerated(
  _GeneratedStonePlacement left,
  _GeneratedStonePlacement right,
) {
  var result = left.strokeId.compareTo(right.strokeId);
  if (result != 0) return result;
  result = left.pathDistance.compareTo(right.pathDistance);
  if (result != 0) return result;
  return left.placement.slotKey.compareTo(right.placement.slotKey);
}

bool _sameStroke(BorderStroke first, BorderStroke second) {
  if (first.id != second.id ||
      first.closed != second.closed ||
      first.points.length != second.points.length) {
    return false;
  }
  for (var index = 0; index < first.points.length; index += 1) {
    if (first.points[index] != second.points[index]) return false;
  }
  return true;
}

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

bool _rectanglesIntersect(BorderPixelRect first, BorderPixelRect second) =>
    first.x < second.right &&
    first.right > second.x &&
    first.y < second.bottom &&
    first.bottom > second.y;

bool _rectIntersectsCanvas(
  BorderPixelRect rect, {
  required int width,
  required int height,
}) {
  if (!_isPortableInteger(width) || !_isPortableInteger(height)) {
    return borderPixelRectIntersectsCanvas(
      rect: rect,
      canvasSizePx: GridSize(width: width, height: height),
    );
  }
  return rect.x < width && rect.right > 0 && rect.y < height && rect.bottom > 0;
}

bool _isPortableInteger(int value) =>
    value >= _minimumPortableJsonInteger &&
    value <= _maximumPortableJsonInteger;

bool _portableSumExists(int left, int right) {
  if (!_isPortableInteger(left) || !_isPortableInteger(right)) return false;
  if (right > 0) return left <= _maximumPortableJsonInteger - right;
  if (right < 0) return left >= _minimumPortableJsonInteger - right;
  return true;
}

int _clampUnit(int value) => value < -1 ? -1 : (value > 1 ? 1 : value);
int _minimum(int left, int right) => left < right ? left : right;
int _maximum(int left, int right) => left > right ? left : right;

int _positiveOverlap(
  int firstStart,
  int firstEnd,
  int secondStart,
  int secondEnd,
) =>
    _maximum(
      0,
      _minimum(firstEnd, secondEnd) - _maximum(firstStart, secondStart),
    );

bool _hasErrors(List<BorderDiagnostic> diagnostics) => diagnostics.any(
      (diagnostic) => diagnostic.severity == BorderDiagnosticSeverity.error,
    );

StoneChainLineBorderResolutionEvidence _failure(
  List<BorderDiagnostic> diagnostics,
) =>
    StoneChainLineBorderResolutionEvidence(
      result: BorderResolutionResult(
        materialization: null,
        diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
      ),
      primaryPlacementCount: 0,
      secondaryPlacementCount: 0,
      maximumGapPx: 0,
      maximumTangentOverlapPx: 0,
      maximumCornerThicknessRatioPermille: 0,
      maximumRepeatedPrimitiveRunLength: 0,
      placementsPerSegmentPermille: 0,
    );

BorderDiagnostic _error(
  BorderResolutionRequest request, {
  required String code,
  required BorderDiagnosticScope scope,
  String? strokeId,
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
      cell: cell,
      parameters: parameters,
      suggestedAction: action,
    );

BorderDiagnostic _requiredNodeUnresolvedDiagnostic(
  BorderResolutionRequest request,
  _PlacementNeed need,
) =>
    _error(
      request,
      code: 'border.resolution.stone_chain_required_node_unresolved',
      scope: BorderDiagnosticScope.segment,
      strokeId: need.path.strokeId,
      cell: need.anchorCell,
      parameters: <String, Object?>{
        'role': borderPrimitiveRoleV1WireName(need.semanticRole),
      },
      action: 'border.action.reduce_stone_node_overlap',
    );

final class _StonePath {
  _StonePath._({
    required this.strokeId,
    required this.lineageId,
    required this.sourceEdgeOffset,
    required this.wrapLength,
    required this.points,
    required this.closed,
    required this.edges,
    required this.vertexDistances,
    required this.totalLengthPx,
    required this.tileSizePx,
  });

  factory _StonePath.fromStroke(BorderStroke stroke, GridSize tileSizePx) {
    final lineage = resolveBorderStrokeLineageIdentityV1(stroke);
    final edges = <_PathEdge>[];
    final distances = <int>[0];
    var total = 0;
    final edgeCount = stroke.points.length - 1 + (stroke.closed ? 1 : 0);
    for (var index = 0; index < edgeCount; index += 1) {
      final start = stroke.points[index];
      final end = index + 1 < stroke.points.length
          ? stroke.points[index + 1]
          : stroke.points.first;
      final dx = end.x - start.x;
      final dy = end.y - start.y;
      if ((dx.abs() + dy.abs()) != 1) {
        throw const ValidationException(
          'Stone-chain strokes require unit cardinal edges',
        );
      }
      final length = dx != 0 ? tileSizePx.width : tileSizePx.height;
      edges.add(
        _PathEdge(
          start: start,
          end: end,
          startDistance: total,
          length: length,
          directionX: dx,
          directionY: dy,
          generationEdgeIndex: lineage.wrapLength == null
              ? lineage.sourceEdgeOffset + index
              : (lineage.sourceEdgeOffset + index) % lineage.wrapLength!,
        ),
      );
      total += length;
      if (index + 1 < stroke.points.length) distances.add(total);
    }
    return _StonePath._(
      strokeId: lineage.authoredStrokeId,
      lineageId: lineage.lineageNamespace,
      sourceEdgeOffset: lineage.sourceEdgeOffset,
      wrapLength: lineage.wrapLength,
      points: stroke.points,
      closed: stroke.closed,
      edges: edges,
      vertexDistances: distances,
      totalLengthPx: total,
      tileSizePx: tileSizePx,
    );
  }

  final String strokeId;
  final String lineageId;
  final int sourceEdgeOffset;
  final int? wrapLength;
  final List<GridPos> points;
  final bool closed;
  final List<_PathEdge> edges;
  final List<int> vertexDistances;
  final int totalLengthPx;
  final GridSize tileSizePx;

  int distanceAtVertex(int index) => vertexDistances[index];

  int sourceVertexOrdinal(int localIndex) {
    final ordinal = sourceEdgeOffset + localIndex;
    final sourceWrapLength = wrapLength;
    return sourceWrapLength == null ? ordinal : ordinal % sourceWrapLength;
  }

  _StonePathCursor cursor() => _StonePathCursor(this);

  _PathSample sampleAtDistance(int distance) {
    var normalized = distance;
    if (closed && totalLengthPx > 0) normalized %= totalLengthPx;
    var low = 0;
    var high = edges.length;
    while (low < high) {
      final middle = low + (high - low) ~/ 2;
      if (edges[middle].startDistance <= normalized) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final edge = edges[_maximum(0, low - 1)];
    final local = (normalized - edge.startDistance).clamp(0, edge.length);
    return _PathSample(
      worldX: edge.start.x * tileSizePx.width + edge.directionX * local,
      worldY: edge.start.y * tileSizePx.height + edge.directionY * local,
      tangentX: edge.directionX,
      tangentY: edge.directionY,
      edgeStart: edge.start,
      edgeEnd: edge.end,
      generationEdgeIndex: edge.generationEdgeIndex,
      localOffsetPx: local,
    );
  }

  List<_PathLatticeStation> latticeStations({
    required int horizontalQuantumPx,
    required int verticalQuantumPx,
    required int maximumOverlapPx,
  }) {
    assert(horizontalQuantumPx > 0);
    assert(verticalQuantumPx > 0);
    final stations = <_PathLatticeStation>[];
    for (final edge in edges) {
      final quantumPx =
          edge.directionX != 0 ? horizontalQuantumPx : verticalQuantumPx;
      final phasePx = _maximum(0, quantumPx - maximumOverlapPx);
      for (var local = phasePx; local < edge.length; local += quantumPx) {
        stations.add(
          _PathLatticeStation(
            distance: edge.startDistance + local,
            sample: _PathSample(
              worldX: edge.start.x * tileSizePx.width + edge.directionX * local,
              worldY:
                  edge.start.y * tileSizePx.height + edge.directionY * local,
              tangentX: edge.directionX,
              tangentY: edge.directionY,
              edgeStart: edge.start,
              edgeEnd: edge.end,
              generationEdgeIndex: edge.generationEdgeIndex,
              localOffsetPx: local,
            ),
          ),
        );
      }
    }
    return stations;
  }
}

final class _PathLatticeStation {
  const _PathLatticeStation({
    required this.distance,
    required this.sample,
  });

  final int distance;
  final _PathSample sample;
}

final class _StonePathCursor {
  _StonePathCursor(this.path);

  final _StonePath path;
  var _edgeIndex = 0;

  _PathSample sample(int distance) {
    var normalized = distance;
    if (path.closed && path.totalLengthPx > 0) {
      normalized %= path.totalLengthPx;
    }
    if (normalized < path.edges[_edgeIndex].startDistance) _edgeIndex = 0;
    while (_edgeIndex + 1 < path.edges.length &&
        normalized >= path.edges[_edgeIndex + 1].startDistance) {
      _edgeIndex += 1;
    }
    final edge = path.edges[_edgeIndex];
    final local = (normalized - edge.startDistance).clamp(0, edge.length);
    return _PathSample(
      worldX: edge.start.x * path.tileSizePx.width + edge.directionX * local,
      worldY: edge.start.y * path.tileSizePx.height + edge.directionY * local,
      tangentX: edge.directionX,
      tangentY: edge.directionY,
      edgeStart: edge.start,
      edgeEnd: edge.end,
      generationEdgeIndex: edge.generationEdgeIndex,
      localOffsetPx: local,
    );
  }
}

final class _PathEdge {
  const _PathEdge({
    required this.start,
    required this.end,
    required this.startDistance,
    required this.length,
    required this.directionX,
    required this.directionY,
    required this.generationEdgeIndex,
  });

  final GridPos start;
  final GridPos end;
  final int startDistance;
  final int length;
  final int directionX;
  final int directionY;
  final int generationEdgeIndex;
}

final class _PathSample {
  const _PathSample({
    required this.worldX,
    required this.worldY,
    required this.tangentX,
    required this.tangentY,
    required this.edgeStart,
    required this.edgeEnd,
    required this.generationEdgeIndex,
    required this.localOffsetPx,
  });

  final int worldX;
  final int worldY;
  final int tangentX;
  final int tangentY;
  final GridPos edgeStart;
  final GridPos edgeEnd;
  final int generationEdgeIndex;
  final int localOffsetPx;
}

final class _SecondaryDensitySelection {
  const _SecondaryDensitySelection({
    required this.targetCount,
    required this.rankedCandidates,
  });

  final int targetCount;
  final List<_PlacementNeed> rankedCandidates;
}

enum _PlacementBuildRejection { outsideCanvas }

sealed class _PlacementBuildResult {
  const _PlacementBuildResult();
}

final class _PlacementBuildAccepted extends _PlacementBuildResult {
  const _PlacementBuildAccepted(this.placement);

  final _GeneratedStonePlacement placement;
}

final class _PlacementBuildRejected extends _PlacementBuildResult {
  const _PlacementBuildRejected(this.reason);

  final _PlacementBuildRejection reason;
}

final class _PreviousPlacementTracker {
  _PreviousPlacementTracker(this._specials);

  final List<_GeneratedStonePlacement> _specials;
  var _specialIndex = 0;
  _GeneratedStonePlacement? _latest;

  _GeneratedStonePlacement? latestBefore(int distance) {
    while (_specialIndex < _specials.length &&
        _specials[_specialIndex].pathDistance < distance) {
      record(_specials[_specialIndex]);
      _specialIndex += 1;
    }
    return _latest;
  }

  _GeneratedStonePlacement? nextAtOrAfter(int distance) {
    while (_specialIndex < _specials.length &&
        _specials[_specialIndex].pathDistance < distance) {
      record(_specials[_specialIndex]);
      _specialIndex += 1;
    }
    return _specialIndex < _specials.length ? _specials[_specialIndex] : null;
  }

  void record(_GeneratedStonePlacement placement) {
    if (_latest == null || placement.pathDistance > _latest!.pathDistance) {
      _latest = placement;
    }
  }
}

final class _StraightRunTracker {
  _GeneratedStonePlacement? _latest;
  _GeneratedStonePlacement? _previous;

  String? primitiveToAvoid(_PlacementNeed need) {
    final latest = _latest;
    final previous = _previous;
    if (latest == null ||
        previous == null ||
        latest.tangentX != need.tangentX ||
        latest.tangentY != need.tangentY ||
        previous.tangentX != need.tangentX ||
        previous.tangentY != need.tangentY ||
        latest.placement.primitiveId != previous.placement.primitiveId) {
      return null;
    }
    return latest.placement.primitiveId;
  }

  void observeBoundary(
    _GeneratedStonePlacement? placement,
    _PlacementNeed need,
  ) {
    if (placement == null ||
        !placement.isSpecial ||
        placement.strokeId != need.path.strokeId ||
        placement.tangentX != need.tangentX ||
        placement.tangentY != need.tangentY ||
        _latest?.placement.slotKey == placement.placement.slotKey) {
      return;
    }
    record(placement);
  }

  void record(_GeneratedStonePlacement placement) {
    _previous = _latest;
    _latest = placement;
  }
}

final class _StonePrimitiveCatalog {
  _StonePrimitiveCatalog(List<BorderPublishedPrimitive> sortedPrimitives) {
    for (final primitive in sortedPrimitives) {
      if (primitive.weight <= 0) continue;
      for (final quarterTurns in primitive.transforms.allowedQuarterTurns) {
        _candidates.putIfAbsent(
          (primitive.role, quarterTurns),
          () => <BorderPublishedPrimitive>[],
        ).add(primitive);
        final relative = resolveBorderSpriteGeometry(
          metrics: primitive.publishedMetrics,
          sourceAnchorPx: primitive.anchorPx,
          transform: BorderSpriteTransform(
            quarterTurns: quarterTurns,
            flipX: false,
          ),
          targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
        );
        _relativeOpaqueBounds[(primitive.id, quarterTurns)] =
            relative.opaqueWorldBoundsPx;
      }
    }
  }

  final Map<(BorderPrimitiveRole, int), List<BorderPublishedPrimitive>>
      _candidates =
      <(BorderPrimitiveRole, int), List<BorderPublishedPrimitive>>{};
  final Map<(String, int), BorderPixelRect> _relativeOpaqueBounds =
      <(String, int), BorderPixelRect>{};

  List<BorderPublishedPrimitive> candidates({
    required BorderPrimitiveRole role,
    required int quarterTurns,
  }) =>
      _candidates[(role, quarterTurns)] ?? const <BorderPublishedPrimitive>[];

  BorderPixelRect opaqueWorldBounds({
    required BorderPublishedPrimitive primitive,
    required int quarterTurns,
    required BorderPixelPos targetAnchorWorldPx,
  }) {
    final relative = _relativeOpaqueBounds[(primitive.id, quarterTurns)]!;
    final canTranslateExactly =
        _portableSumExists(relative.x, targetAnchorWorldPx.x) &&
            _portableSumExists(relative.y, targetAnchorWorldPx.y) &&
            _portableSumExists(
              relative.x + targetAnchorWorldPx.x,
              relative.width,
            ) &&
            _portableSumExists(
              relative.y + targetAnchorWorldPx.y,
              relative.height,
            );
    if (!canTranslateExactly) {
      return resolveBorderSpriteGeometry(
        metrics: primitive.publishedMetrics,
        sourceAnchorPx: primitive.anchorPx,
        transform: BorderSpriteTransform(
          quarterTurns: quarterTurns,
          flipX: false,
        ),
        targetAnchorWorldPx: targetAnchorWorldPx,
      ).opaqueWorldBoundsPx;
    }
    return BorderPixelRect(
      x: relative.x + targetAnchorWorldPx.x,
      y: relative.y + targetAnchorWorldPx.y,
      width: relative.width,
      height: relative.height,
    );
  }
}

final class _StoneCollisionIndex {
  _StoneCollisionIndex({required this.bucketSizePx}) : assert(bucketSizePx > 0);

  final int bucketSizePx;
  final Map<_StoneCollisionBucket, List<_GeneratedStonePlacement>> _buckets =
      <_StoneCollisionBucket, List<_GeneratedStonePlacement>>{};

  Iterable<_GeneratedStonePlacement> candidatesFor(
    _GeneratedStonePlacement placement,
  ) =>
      candidatesForBounds(placement.placement.opaqueWorldBoundsPx);

  Iterable<_GeneratedStonePlacement> candidatesForBounds(
    BorderPixelRect bounds,
  ) sync* {
    final seen = HashSet<_GeneratedStonePlacement>.identity();
    for (final bucket in _bucketsForBounds(bounds)) {
      for (final candidate
          in _buckets[bucket] ?? const <_GeneratedStonePlacement>[]) {
        if (seen.add(candidate)) yield candidate;
      }
    }
  }

  void add(_GeneratedStonePlacement placement) {
    for (final bucket
        in _bucketsForBounds(placement.placement.opaqueWorldBoundsPx)) {
      _buckets
          .putIfAbsent(bucket, () => <_GeneratedStonePlacement>[])
          .add(placement);
    }
  }

  void remove(_GeneratedStonePlacement placement) {
    for (final bucket
        in _bucketsForBounds(placement.placement.opaqueWorldBoundsPx)) {
      final placements = _buckets[bucket];
      if (placements == null) continue;
      placements.removeWhere((candidate) => identical(candidate, placement));
      if (placements.isEmpty) _buckets.remove(bucket);
    }
  }

  Iterable<_StoneCollisionBucket> _bucketsForBounds(
    BorderPixelRect bounds,
  ) sync* {
    final startX = _floorDivide(bounds.x, bucketSizePx);
    final endX = _floorDivide(bounds.right - 1, bucketSizePx);
    final startY = _floorDivide(bounds.y, bucketSizePx);
    final endY = _floorDivide(bounds.bottom - 1, bucketSizePx);
    for (var y = startY; y <= endY; y += 1) {
      for (var x = startX; x <= endX; x += 1) {
        yield _StoneCollisionBucket(
          x: x,
          y: y,
        );
      }
    }
  }
}

@immutable
final class _StoneCollisionBucket {
  const _StoneCollisionBucket({
    required this.x,
    required this.y,
  });

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is _StoneCollisionBucket && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

int _floorDivide(int value, int divisor) {
  final truncated = value ~/ divisor;
  return value < 0 && value % divisor != 0 ? truncated - 1 : truncated;
}

final class _PlacementNeed {
  const _PlacementNeed({
    required this.featureId,
    required this.path,
    required this.distance,
    required this.stationOrdinal,
    required this.semanticRole,
    required this.passIndex,
    required this.tangentX,
    required this.tangentY,
    required this.normalX,
    required this.normalY,
    required this.targetAnchorWorldPx,
    required this.anchorCell,
    required this.slotKey,
    required this.isSpecial,
    required this.isPrimary,
    this.drawBand = BorderDrawBand.structure,
    this.rngSlotKey,
    this.stableOrderOrdinal,
    this.slotRunStart,
    this.slotRunEnd,
    this.slotStationOffsetPx,
    this.slotGenerationEdgeIndex,
  });

  final String featureId;
  final _StonePath path;
  final int distance;
  final int stationOrdinal;
  final BorderPrimitiveRole semanticRole;
  final int passIndex;
  final int tangentX;
  final int tangentY;
  final int normalX;
  final int normalY;
  final BorderPixelPos targetAnchorWorldPx;
  final GridPos anchorCell;
  final String slotKey;
  final bool isSpecial;
  final bool isPrimary;
  final BorderDrawBand drawBand;
  final String? rngSlotKey;
  final int? stableOrderOrdinal;
  final GridPos? slotRunStart;
  final GridPos? slotRunEnd;
  final int? slotStationOffsetPx;
  final int? slotGenerationEdgeIndex;

  String get deterministicSlotKey => rngSlotKey ?? slotKey;
  int get stableOrdinal => stableOrderOrdinal ?? stationOrdinal;
  int get candidateOrderOrdinal =>
      (slotGenerationEdgeIndex ?? stationOrdinal) + (slotStationOffsetPx ?? 0);

  _PlacementNeed withTopologyRunAxes({
    required int tangentX,
    required int tangentY,
    required int normalX,
    required int normalY,
    required int distance,
  }) =>
      _PlacementNeed(
        featureId: featureId,
        path: path,
        distance: distance,
        stationOrdinal: stationOrdinal,
        semanticRole: semanticRole,
        passIndex: passIndex,
        tangentX: tangentX,
        tangentY: tangentY,
        normalX: normalX,
        normalY: normalY,
        targetAnchorWorldPx: targetAnchorWorldPx,
        anchorCell: anchorCell,
        slotKey: slotKey,
        isSpecial: isSpecial,
        isPrimary: isPrimary,
        drawBand: drawBand,
        rngSlotKey: rngSlotKey,
        stableOrderOrdinal: stableOrderOrdinal,
        slotRunStart: slotRunStart,
        slotRunEnd: slotRunEnd,
        slotStationOffsetPx: slotStationOffsetPx,
        slotGenerationEdgeIndex: slotGenerationEdgeIndex,
      );

  _PlacementNeed offsetAnchorAlongTangent({
    required BorderResolutionRequest request,
    required int delta,
  }) {
    final target = BorderPixelPos(
      x: targetAnchorWorldPx.x + tangentX * delta,
      y: targetAnchorWorldPx.y + tangentY * delta,
    );
    return _PlacementNeed(
      featureId: featureId,
      path: path,
      distance: distance,
      stationOrdinal: stationOrdinal,
      semanticRole: semanticRole,
      passIndex: passIndex,
      tangentX: tangentX,
      tangentY: tangentY,
      normalX: normalX,
      normalY: normalY,
      targetAnchorWorldPx: target,
      anchorCell: _anchorCell(request, target),
      slotKey: slotKey,
      isSpecial: isSpecial,
      isPrimary: isPrimary,
      drawBand: drawBand,
      rngSlotKey: rngSlotKey,
      stableOrderOrdinal: stableOrderOrdinal,
      slotRunStart: slotRunStart,
      slotRunEnd: slotRunEnd,
      slotStationOffsetPx: slotStationOffsetPx,
      slotGenerationEdgeIndex: slotGenerationEdgeIndex,
    );
  }

  _PlacementNeed shiftAlongNormal({
    required BorderResolutionRequest request,
    required int delta,
  }) {
    if (delta == 0) return this;
    final target = BorderPixelPos(
      x: targetAnchorWorldPx.x + normalX * delta,
      y: targetAnchorWorldPx.y + normalY * delta,
    );
    return _PlacementNeed(
      featureId: featureId,
      path: path,
      distance: distance,
      stationOrdinal: stationOrdinal,
      semanticRole: semanticRole,
      passIndex: passIndex,
      tangentX: tangentX,
      tangentY: tangentY,
      normalX: normalX,
      normalY: normalY,
      targetAnchorWorldPx: target,
      anchorCell: _anchorCell(request, target),
      slotKey: slotKey,
      isSpecial: isSpecial,
      isPrimary: isPrimary,
      drawBand: drawBand,
      rngSlotKey: rngSlotKey,
      stableOrderOrdinal: stableOrderOrdinal,
      slotRunStart: slotRunStart,
      slotRunEnd: slotRunEnd,
      slotStationOffsetPx: slotStationOffsetPx,
      slotGenerationEdgeIndex: slotGenerationEdgeIndex,
    );
  }

  _PlacementNeed shiftAlongTangent({
    required BorderResolutionRequest request,
    required int delta,
  }) {
    final shiftedDistance = _maximum(0, distance + delta);
    final appliedDelta = shiftedDistance - distance;
    final target = BorderPixelPos(
      x: targetAnchorWorldPx.x + tangentX * appliedDelta,
      y: targetAnchorWorldPx.y + tangentY * appliedDelta,
    );
    return _PlacementNeed(
      featureId: featureId,
      path: path,
      distance: shiftedDistance,
      stationOrdinal: stationOrdinal,
      semanticRole: semanticRole,
      passIndex: passIndex,
      tangentX: tangentX,
      tangentY: tangentY,
      normalX: normalX,
      normalY: normalY,
      targetAnchorWorldPx: target,
      anchorCell: _anchorCell(request, target),
      slotKey: slotKey,
      isSpecial: isSpecial,
      isPrimary: isPrimary,
      drawBand: drawBand,
      rngSlotKey: rngSlotKey,
      stableOrderOrdinal: stableOrderOrdinal,
      slotRunStart: slotRunStart,
      slotRunEnd: slotRunEnd,
      slotStationOffsetPx: slotStationOffsetPx,
      slotGenerationEdgeIndex: slotGenerationEdgeIndex,
    );
  }

  _PlacementNeed asSecondaryBetween({
    required BorderResolutionRequest request,
    required _PlacementNeed next,
    required BorderPrimitiveRole role,
    required int extraNormalOffset,
  }) {
    final secondaryDistance = (distance + next.distance) ~/ 2;
    final tangentOffset = secondaryDistance - distance;
    final sourceOffset = slotStationOffsetPx;
    final sourceRunStart = slotRunStart;
    final sourceRunEnd = slotRunEnd;
    final sourceEdgeIndex = slotGenerationEdgeIndex;
    final nextSourceOffset = next.slotStationOffsetPx;
    final nextSourceEdgeIndex = next.slotGenerationEdgeIndex;
    if (sourceOffset == null ||
        sourceRunStart == null ||
        sourceRunEnd == null ||
        sourceEdgeIndex == null ||
        nextSourceOffset == null ||
        nextSourceEdgeIndex == null) {
      throw StateError('Secondary stone requires a station source identity');
    }
    final sourceEdgeLength =
        (sourceRunEnd.x - sourceRunStart.x).abs() * path.tileSizePx.width +
            (sourceRunEnd.y - sourceRunStart.y).abs() * path.tileSizePx.height;
    final stableSecondaryOffset = sourceEdgeIndex == nextSourceEdgeIndex
        ? (sourceOffset + nextSourceOffset) ~/ 2
        : sourceOffset +
            (sourceEdgeLength - sourceOffset + nextSourceOffset) ~/ 2;
    final target = BorderPixelPos(
      x: targetAnchorWorldPx.x +
          tangentX * tangentOffset +
          normalX * extraNormalOffset,
      y: targetAnchorWorldPx.y +
          tangentY * tangentOffset +
          normalY * extraNormalOffset,
    );
    return _PlacementNeed(
      featureId: featureId,
      path: path,
      distance: secondaryDistance,
      stationOrdinal: stationOrdinal,
      semanticRole: role,
      passIndex: 1,
      tangentX: tangentX,
      tangentY: tangentY,
      normalX: normalX,
      normalY: normalY,
      targetAnchorWorldPx: target,
      anchorCell: _anchorCell(request, target),
      slotKey: buildBorderStoneChainStationSlotKey(
        featureId: featureId,
        strokeId: path.lineageId,
        runStart: sourceRunStart,
        runEnd: sourceRunEnd,
        stationOrdinal: stableSecondaryOffset,
        passIndex: 1,
        role: role,
        rank: sourceEdgeIndex,
      ),
      isSpecial: false,
      isPrimary: false,
      drawBand: drawBand,
      stableOrderOrdinal: sourceEdgeIndex,
      slotRunStart: sourceRunStart,
      slotRunEnd: sourceRunEnd,
      slotStationOffsetPx: stableSecondaryOffset,
      slotGenerationEdgeIndex: sourceEdgeIndex,
    );
  }
}

final class _GeneratedStonePlacement {
  const _GeneratedStonePlacement({
    required this.placement,
    required this.semanticRole,
    required this.strokeId,
    required this.pathDistance,
    required this.tangentX,
    required this.tangentY,
    required this.pathClosed,
    required this.isPrimary,
    required this.isSpecial,
  });

  final BorderResolvedPlacement placement;
  final BorderPrimitiveRole semanticRole;
  final String strokeId;
  final int pathDistance;
  final int tangentX;
  final int tangentY;
  final bool pathClosed;
  final bool isPrimary;
  final bool isSpecial;

  _GeneratedStonePlacement withPlacement(BorderResolvedPlacement value) =>
      _GeneratedStonePlacement(
        placement: value,
        semanticRole: semanticRole,
        strokeId: strokeId,
        pathDistance: pathDistance,
        tangentX: tangentX,
        tangentY: tangentY,
        pathClosed: pathClosed,
        isPrimary: isPrimary,
        isSpecial: isSpecial,
      );

  _GeneratedStonePlacement withPathDistance(int value) =>
      _GeneratedStonePlacement(
        placement: placement,
        semanticRole: semanticRole,
        strokeId: strokeId,
        pathDistance: value,
        tangentX: tangentX,
        tangentY: tangentY,
        pathClosed: pathClosed,
        isPrimary: isPrimary,
        isSpecial: isSpecial,
      );

  _GeneratedStonePlacement withTopologyRunAxes({
    required int tangentX,
    required int tangentY,
    required int pathDistance,
  }) =>
      _GeneratedStonePlacement(
        placement: placement,
        semanticRole: semanticRole,
        strokeId: strokeId,
        pathDistance: pathDistance,
        tangentX: tangentX,
        tangentY: tangentY,
        pathClosed: false,
        isPrimary: isPrimary,
        isSpecial: isSpecial,
      );
}
