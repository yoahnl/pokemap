import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_geometry.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/border_materialization.dart';
import '../models/border_signed_int64.dart';
import '../models/geometry.dart';
import 'border_deterministic_rng.dart';
import 'border_fingerprints.dart';
import 'border_linear_lattice.dart';
import 'border_local_resolution_scope.dart';
import 'border_override_resolution.dart';
import 'border_rle_codec.dart';
import 'border_slot_keys.dart';
import 'border_sprite_geometry.dart';

final class LedgeLineEdgePlacementEvidence {
  const LedgeLineEdgePlacementEvidence({
    required this.strokeId,
    required this.edgeStart,
    required this.edgeEnd,
    required this.physicalNormal,
    required this.expectedCarrierCell,
    required this.finalPlacement,
  });
  final String strokeId;
  final GridPos edgeStart;
  final GridPos edgeEnd;
  final BorderCardinalDirection physicalNormal;
  final GridPos expectedCarrierCell;
  final BorderResolvedPlacement finalPlacement;
}

final class LedgeLineBorderResolutionEvidence {
  LedgeLineBorderResolutionEvidence({
    required this.result,
    required List<LedgeLineEdgePlacementEvidence> edges,
  }) : edges = List.unmodifiable(edges);
  final BorderResolutionResult result;
  final List<LedgeLineEdgePlacementEvidence> edges;
}

BorderResolutionResult resolveLedgeLineBorder(
  BorderResolutionRequest request,
) => resolveLedgeLineBorderWithEvidence(request).result;

LedgeLineBorderResolutionEvidence resolveLedgeLineBorderWithEvidence(
  BorderResolutionRequest request, {
  BorderLocalResolutionScope? localScope,
  BorderLocalResolutionCapture? localCapture,
}) {
  final diagnostics = <BorderDiagnostic>[];
  void error(String code, {String? slotKey, GridPos? cell}) => diagnostics.add(
    BorderDiagnostic(
      code: code,
      severity: BorderDiagnosticSeverity.error,
      phase: BorderDiagnosticPhase.resolution,
      scope: slotKey == null
          ? BorderDiagnosticScope.feature
          : BorderDiagnosticScope.slot,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      slotKey: slotKey,
      cell: cell,
      suggestedAction: 'border.action.resolve_preview_again',
    ),
  );
  LedgeLineBorderResolutionEvidence failed() =>
      LedgeLineBorderResolutionEvidence(
        result: BorderResolutionResult(
          materialization: null,
          diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
        ),
        edges: const [],
      );
  final revision = request.blueprintRevision;
  if (revision == null) {
    error('border.resolution.blueprint_unavailable');
    return failed();
  }
  final definition = revision.definition;
  final parameters = request.feature.paramsOverride ?? definition.defaults;
  final geometry = request.feature.geometry;
  if (definition.template != BorderBlueprintTemplate.ledgeLine) {
    error('border.resolution.template_mismatch');
  }
  if (definition.isSpatial || request.feature.spatialOffsetWorld != null) {
    error('border.resolution.ledge_2d_required');
  }
  if (definition.ground != null) {
    error('border.resolution.linear_ground_not_supported');
  }
  if (parameters.depthRows != 1 ||
      parameters.irregularityPermille != 0 ||
      parameters.detailDensityPermille != 0 ||
      parameters.allowAutoRotation ||
      parameters.gapTolerancePx != 0 ||
      parameters.maxOverlapPx != 0) {
    error('border.resolution.ledge_parameters_invalid');
  }
  if (geometry is! BorderStrokeGeometry ||
      geometry.alignment != BorderStrokeAlignment.gridEdges ||
      geometry.strokes.isEmpty) {
    error('border.resolution.ledge_grid_edges_required');
    return failed();
  }
  final maximum = BigInt.parse('9007199254740991');
  if (BigInt.from(request.mapSize.width) *
              BigInt.from(request.tileSizePx.width) >
          maximum ||
      BigInt.from(request.mapSize.height) *
              BigInt.from(request.tileSizePx.height) >
          maximum) {
    error('border.resolution.canvas_integer_range_invalid');
    return failed();
  }
  final primitives = <String, BorderPublishedPrimitive>{};
  for (final primitive in definition.primitives) {
    if (primitives.containsKey(primitive.id)) {
      error('border.resolution.duplicate_primitive_id');
    }
    primitives[primitive.id] = primitive;
    if (!_nativePrimitive(primitive, request)) {
      error('border.resolution.ledge_primitive_invalid');
    }
    final snapshot = request.visualSnapshotById(primitive.visualSnapshotId);
    if (snapshot == null ||
        snapshot.frames.isEmpty ||
        snapshot.frames.any(
          (frame) =>
              frame.sourceRectPx.width != request.tileSizePx.width ||
              frame.sourceRectPx.height != request.tileSizePx.height,
        )) {
      error('border.resolution.visual_snapshot_invalid');
    }
    try {
      final length = checkedBorderRleCellCount(
        width: primitive.publishedMetrics.pixelSize.width,
        height: primitive.publishedMetrics.pixelSize.height,
        path: r'$.publishedMetrics',
      );
      if (!borderRleMaskHasTrue(
        primitive.publishedMetrics.occupancyMaskRle,
        expectedLength: length,
        path: r'$.occupancyMaskRle',
      )) {
        error('border.resolution.occupancy_empty');
      }
      resolveBorderSpriteGeometry(
        metrics: primitive.publishedMetrics,
        sourceAnchorPx: primitive.anchorPx,
        transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
        targetAnchorWorldPx: primitive.anchorPx,
      );
    } on FormatException {
      error('border.resolution.occupancy_invalid');
    } on ValidationException {
      error('border.resolution.ledge_primitive_invalid');
    }
  }
  final needs = <String, _EdgeNeed>{};
  final occupiedEdges = <(GridPos, GridPos)>{};
  final occupiedCarriers = <GridPos>{};
  for (final stroke in geometry.strokes) {
    if (stroke.points.any(
      (p) =>
          p.x < 0 ||
          p.y < 0 ||
          p.x > request.mapSize.width ||
          p.y > request.mapSize.height,
    )) {
      error('border.resolution.stroke_out_of_bounds');
      continue;
    }
    try {
      final lattice = buildBorderLinearLatticeV1(
        stroke: stroke,
        tileSizePx: request.tileSizePx,
      );
      for (final edge in lattice.edges) {
        final start = edge.startCell;
        final end = edge.endCell;
        final normal = _physicalNormal(
          edge.direction,
          request.feature.lineSide,
        );
        final carrier = _carrierCell(start, end, normal);
        if (carrier.x < 0 ||
            carrier.y < 0 ||
            carrier.x >= request.mapSize.width ||
            carrier.y >= request.mapSize.height) {
          error('border.resolution.ledge_carrier_out_of_bounds', cell: carrier);
          continue;
        }
        if (!occupiedCarriers.add(carrier)) {
          error('border.resolution.ledge_carrier_ambiguous', cell: carrier);
          continue;
        }
        final sorted = start.y < end.y || (start.y == end.y && start.x < end.x)
            ? (start, end)
            : (end, start);
        if (!occupiedEdges.add(sorted)) {
          error('border.resolution.ledge_duplicate_edge');
          continue;
        }
        final slot = buildBorderLineSlotKey(
          featureId: request.feature.id,
          strokeId: lattice.lineageNamespace,
          edgeStart: start,
          edgeEnd: end,
          passIndex: 0,
          role: BorderPrimitiveRole.structureLarge,
          rank: 0,
          ordinalLocal: 0,
        );
        final candidates =
            primitives.values
                .where(
                  (p) =>
                      p.authoredOrientation.name == normal.name &&
                      _nativePrimitive(p, request),
                )
                .toList()
              ..sort((a, b) => a.id.compareTo(b.id));
        if (candidates.isEmpty) {
          error('border.resolution.ledge_orientation_missing', slotKey: slot);
        }
        if (needs.containsKey(slot)) {
          error('border.resolution.ledge_duplicate_slot', slotKey: slot);
        }
        needs[slot] = _EdgeNeed(
          lattice.strokeId,
          start,
          end,
          normal,
          carrier,
          candidates,
        );
      }
    } on ValidationException {
      error('border.resolution.stroke_invalid');
    }
  }
  if (diagnostics.any((d) => d.severity == BorderDiagnosticSeverity.error)) {
    return failed();
  }
  final previous = <String, BorderResolvedPlacement>{
    for (final p
        in localScope?.previousBasePlacements ??
            const <BorderResolvedPlacement>[])
      p.slotKey: p,
  };
  final retained = <String>{};
  final base = <BorderResolvedPlacement>[];
  for (final entry in needs.entries) {
    final need = entry.value;
    final old = previous[entry.key];
    if (localScope != null &&
        !localScope.recomputesCell(need.carrier, request.tileSizePx) &&
        old != null &&
        localScope.retainsBasePlacement(old, request.tileSizePx)) {
      base.add(old);
      retained.add(entry.key);
      continue;
    }
    localScope?.recordRecomputedCell(need.carrier);
    final primitive = _choose(
      request,
      entry.key,
      need.candidates,
      parameters.variationPermille,
    );
    final origin = BorderPixelPos(
      x: need.carrier.x * request.tileSizePx.width,
      y: need.carrier.y * request.tileSizePx.height,
    );
    final sprite = resolveBorderSpriteGeometry(
      metrics: primitive.publishedMetrics,
      sourceAnchorPx: primitive.anchorPx,
      transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
      targetAnchorWorldPx: BorderPixelPos(
        x: origin.x + primitive.anchorPx.x,
        y: origin.y + primitive.anchorPx.y,
      ),
    );
    base.add(
      BorderResolvedPlacement(
        id: 'border-placement-v1:${entry.key.substring(borderSlotKeyV1Prefix.length)}',
        slotKey: entry.key,
        primitiveId: primitive.id,
        visualSnapshotId: primitive.visualSnapshotId,
        anchorCell: need.carrier,
        topLeftWorldPx: sprite.topLeftWorldPx,
        opaqueWorldBoundsPx: sprite.opaqueWorldBoundsPx,
        transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
        drawBand: BorderDrawBand.structure,
        stableOrderKey: buildBorderStableOrderKey(
          drawBand: BorderDrawBand.structure,
          mapWidth: request.mapSize.width,
          anchorCell: need.carrier,
          passIndex: 0,
          rank: 0,
          ordinalLocal: 0,
          slotKey: entry.key,
        ),
      ),
    );
  }
  base.sort((a, b) => a.stableOrderKey.compareTo(b.stableOrderKey));
  localCapture?.recordBase(ground: const [], placements: base);
  final overrides = resolveBorderOverrides(
    request: request,
    baseGround: const [],
    basePlacements: base,
    alreadyResolvedSlotKeys: retained,
    previouslyResolvedPlacementsBySlot:
        localScope?.previousResolvedPlacementsBySlot ?? const {},
    previouslySuppressedSlotKeys:
        localScope?.previousSuppressedPlacementSlotKeys ?? const {},
  );
  diagnostics.addAll(overrides.diagnostics);
  final evidence = <LedgeLineEdgePlacementEvidence>[];
  final placements = overrides.placements.toList()
    ..sort((a, b) => a.stableOrderKey.compareTo(b.stableOrderKey));
  for (final placement in placements) {
    final need = needs[placement.slotKey];
    final primitive = primitives[placement.primitiveId];
    if (need == null ||
        primitive == null ||
        !_nativePrimitive(primitive, request) ||
        primitive.authoredOrientation.name != need.normal.name ||
        placement.transform.quarterTurns != 0 ||
        placement.transform.flipX ||
        placement.anchorCell != need.carrier ||
        placement.topLeftWorldPx !=
            BorderPixelPos(
              x: need.carrier.x * request.tileSizePx.width,
              y: need.carrier.y * request.tileSizePx.height,
            ) ||
        placement.drawBand != BorderDrawBand.structure) {
      error(
        'border.resolution.ledge_final_placement_invalid',
        slotKey: placement.slotKey,
      );
      continue;
    }
    evidence.add(
      LedgeLineEdgePlacementEvidence(
        strokeId: need.strokeId,
        edgeStart: need.start,
        edgeEnd: need.end,
        physicalNormal: need.normal,
        expectedCarrierCell: need.carrier,
        finalPlacement: placement,
      ),
    );
  }
  if (diagnostics.any((d) => d.severity == BorderDiagnosticSeverity.error)) {
    return failed();
  }
  if (placements.isEmpty) {
    error('border.resolution.materialization_empty');
    return failed();
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
        ground: const [],
        placements: placements,
      ),
    ),
    ground: const [],
    placements: placements,
  );
  return LedgeLineBorderResolutionEvidence(
    result: BorderResolutionResult(
      materialization: materialization,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    ),
    edges: evidence,
  );
}

bool _nativePrimitive(
  BorderPublishedPrimitive primitive,
  BorderResolutionRequest request,
) =>
    primitive.weight > 0 &&
    primitive.role == BorderPrimitiveRole.structureLarge &&
    primitive.sourceElementId != null &&
    primitive.sourceModelId == null &&
    primitive.authoredOrientation != BorderPrimitiveOrientation.legacyAxis &&
    primitive.publishedMetrics.pixelSize == request.tileSizePx &&
    !primitive.transforms.allowFlipX &&
    primitive.transforms.allowedQuarterTurns.length == 1 &&
    primitive.transforms.allowedQuarterTurns.single == 0;
BorderPublishedPrimitive _choose(
  BorderResolutionRequest request,
  String slot,
  List<BorderPublishedPrimitive> candidates,
  int variation,
) {
  if (candidates.length == 1 || variation == 0) return candidates.first;
  final rng = BorderDeterministicRng.fromComponents([
    const BorderRngKeyComponent.text('ledge-line-native-variant'),
    BorderRngKeyComponent.text(request.blueprintId),
    BorderRngKeyComponent.signedInt64(
      BorderSignedInt64.fromInt(request.blueprintRevision!.revision),
    ),
    BorderRngKeyComponent.signedInt64(request.feature.seed),
    BorderRngKeyComponent.text(slot),
  ]);
  if (rng.nextIndex(1000) >= variation) return candidates.first;
  return chooseBorderWeightedCandidate(rng, [
    for (final p in candidates)
      BorderWeightedCandidate(id: p.id, value: p, weight: p.weight),
  ])!.value;
}

final class _EdgeNeed {
  const _EdgeNeed(
    this.strokeId,
    this.start,
    this.end,
    this.normal,
    this.carrier,
    this.candidates,
  );
  final String strokeId;
  final GridPos start;
  final GridPos end;
  final BorderCardinalDirection normal;
  final GridPos carrier;
  final List<BorderPublishedPrimitive> candidates;
}

bool ledgeLineNativePlacementGeometryMatches(
  BorderResolutionRequest request,
  BorderMaterialization materialization,
) {
  final definition = request.blueprintRevision?.definition;
  final geometry = request.feature.geometry;
  if (definition == null ||
      definition.template != BorderBlueprintTemplate.ledgeLine ||
      definition.isSpatial ||
      geometry is! BorderStrokeGeometry ||
      geometry.alignment != BorderStrokeAlignment.gridEdges ||
      geometry.strokes.isEmpty ||
      materialization.ground.isNotEmpty) {
    return false;
  }
  final params = request.feature.paramsOverride ?? definition.defaults;
  if (params.depthRows != 1 ||
      params.allowAutoRotation ||
      params.irregularityPermille != 0 ||
      params.detailDensityPermille != 0 ||
      params.gapTolerancePx != 0 ||
      params.maxOverlapPx != 0) {
    return false;
  }
  final primitives = {for (final p in definition.primitives) p.id: p};
  final needs = <String, ({BorderCardinalDirection normal, GridPos carrier})>{};
  final carriers = <GridPos>{};
  try {
    for (final stroke in geometry.strokes) {
      final lattice = buildBorderLinearLatticeV1(
        stroke: stroke,
        tileSizePx: request.tileSizePx,
      );
      for (final edge in lattice.edges) {
        final normal = _physicalNormal(
          edge.direction,
          request.feature.lineSide,
        );
        final carrier = _carrierCell(edge.startCell, edge.endCell, normal);
        if (carrier.x < 0 ||
            carrier.y < 0 ||
            carrier.x >= request.mapSize.width ||
            carrier.y >= request.mapSize.height) {
          return false;
        }
        final slot = buildBorderLineSlotKey(
          featureId: request.feature.id,
          strokeId: lattice.lineageNamespace,
          edgeStart: edge.startCell,
          edgeEnd: edge.endCell,
          passIndex: 0,
          role: BorderPrimitiveRole.structureLarge,
          rank: 0,
          ordinalLocal: 0,
        );
        if (needs.containsKey(slot) || !carriers.add(carrier)) {
          return false;
        }
        needs[slot] = (normal: normal, carrier: carrier);
      }
    }
    for (final placement in materialization.placements) {
      final need = needs[placement.slotKey];
      final primitive = primitives[placement.primitiveId];
      if (need == null ||
          primitive == null ||
          !_nativePrimitive(primitive, request) ||
          primitive.authoredOrientation.name != need.normal.name ||
          placement.anchorCell != need.carrier ||
          placement.transform.quarterTurns != 0 ||
          placement.transform.flipX ||
          placement.drawBand != BorderDrawBand.structure ||
          placement.visualSnapshotId != primitive.visualSnapshotId ||
          placement.id !=
              'border-placement-v1:${placement.slotKey.substring(borderSlotKeyV1Prefix.length)}' ||
          placement.stableOrderKey !=
              buildBorderStableOrderKey(
                drawBand: BorderDrawBand.structure,
                mapWidth: request.mapSize.width,
                anchorCell: need.carrier,
                passIndex: 0,
                rank: 0,
                ordinalLocal: 0,
                slotKey: placement.slotKey,
              )) {
        return false;
      }
      final origin = BorderPixelPos(
        x: need.carrier.x * request.tileSizePx.width,
        y: need.carrier.y * request.tileSizePx.height,
      );
      final sprite = resolveBorderSpriteGeometry(
        metrics: primitive.publishedMetrics,
        sourceAnchorPx: primitive.anchorPx,
        transform: placement.transform,
        targetAnchorWorldPx: BorderPixelPos(
          x: origin.x + primitive.anchorPx.x,
          y: origin.y + primitive.anchorPx.y,
        ),
      );
      if (placement.topLeftWorldPx != origin ||
          placement.opaqueWorldBoundsPx != sprite.opaqueWorldBoundsPx) {
        return false;
      }
    }
    return true;
  } on ValidationException {
    return false;
  } on FormatException {
    return false;
  }
}

BorderCardinalDirection _physicalNormal(
  BorderCardinalDirection tangent,
  BorderLineSide side,
) =>
    BorderCardinalDirection.values[(borderCardinalDirectionV1Rank(tangent) +
            (side == BorderLineSide.primary ? 1 : 3)) %
        4];

GridPos _carrierCell(
  GridPos start,
  GridPos end,
  BorderCardinalDirection normal,
) => GridPos(
  x:
      (start.x < end.x ? start.x : end.x) -
      (normal == BorderCardinalDirection.west ? 1 : 0),
  y:
      (start.y < end.y ? start.y : end.y) -
      (normal == BorderCardinalDirection.north ? 1 : 0),
);
