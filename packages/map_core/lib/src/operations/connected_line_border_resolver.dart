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

/// Per-node evidence retained by tests and publication gallery inspection.
@immutable
final class ConnectedLineNodeResolutionEvidence {
  const ConnectedLineNodeResolutionEvidence({
    required this.strokeId,
    required this.nodeIndex,
    required this.cell,
    required this.role,
    required this.transform,
    required this.slotKey,
  });

  final String strokeId;
  final int nodeIndex;
  final GridPos cell;
  final BorderPrimitiveRole role;
  final BorderSpriteTransform transform;
  final String slotKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectedLineNodeResolutionEvidence &&
          strokeId == other.strokeId &&
          nodeIndex == other.nodeIndex &&
          cell == other.cell &&
          role == other.role &&
          transform == other.transform &&
          slotKey == other.slotKey;

  @override
  int get hashCode =>
      Object.hash(strokeId, nodeIndex, cell, role, transform, slotKey);
}

/// Connected-line result plus the canonical topology selected at every node.
@immutable
final class ConnectedLineBorderResolutionEvidence {
  ConnectedLineBorderResolutionEvidence({
    required this.result,
    required List<ConnectedLineNodeResolutionEvidence> nodes,
  }) : _nodes = List<ConnectedLineNodeResolutionEvidence>.unmodifiable(nodes);

  final BorderResolutionResult result;
  final List<ConnectedLineNodeResolutionEvidence> _nodes;

  List<ConnectedLineNodeResolutionEvidence> get nodes => _nodes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectedLineBorderResolutionEvidence &&
          result == other.result &&
          _listsEqual(_nodes, other._nodes);

  @override
  int get hashCode => Object.hash(result, Object.hashAll(_nodes));
}

/// Resolves one grid-snapped cap/straight/corner kit.
BorderResolutionResult resolveConnectedLineBorder(
  BorderResolutionRequest request,
) =>
    resolveConnectedLineBorderWithEvidence(request).result;

/// Resolves one connected line while exposing its canonical node topology.
ConnectedLineBorderResolutionEvidence resolveConnectedLineBorderWithEvidence(
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
  final params = request.feature.paramsOverride ?? definition.defaults;
  if (definition.template != BorderBlueprintTemplate.connectedLine) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.template_mismatch',
        scope: BorderDiagnosticScope.blueprint,
        parameters: <String, Object?>{'template': definition.template.name},
        action: 'border.action.select_connected_line_blueprint',
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
    final authoredStrokeId = borderStrokeAuthoredIdV1(stroke.id);
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
          strokeId: authoredStrokeId,
          cell: outside.first,
          action: 'border.action.move_stroke_inside_map',
        ),
      );
      continue;
    }
    try {
      final lineage = resolveBorderStrokeLineageIdentityV1(stroke);
      final canonical = canonicalizeBorderStrokeV1(
        id: stroke.id,
        sampledPoints: stroke.points,
        closed: stroke.closed,
      );
      if (!lineage.preserveTraversal && !_sameStroke(stroke, canonical)) {
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
          strokeId: authoredStrokeId,
          action: 'border.action.redraw_valid_stroke',
        ),
      );
    }
  }

  final primitives = definition.primitives.toList(growable: false)
    ..sort((left, right) => left.id.compareTo(right.id));
  _diagnosePublishedInputs(
    request,
    primitives: primitives,
    diagnostics: diagnostics,
  );
  _diagnoseRequiredRoles(request, primitives, diagnostics);

  final nodeNeeds = <_NodeNeed>[];
  for (final lattice in lattices) {
    for (final node in lattice.nodes) {
      try {
        final role = _roleForNode(node);
        final primaryQuarterTurns =
            params.allowAutoRotation ? _primaryQuarterTurns(node, role) : 0;
        final transform = _composeLineSide(
          role: role,
          primaryQuarterTurns: primaryQuarterTurns,
          lineSide: request.feature.lineSide,
          allowAutoRotation: params.allowAutoRotation,
        );
        final candidates = _eligibleCandidates(
          primitives,
          role: role,
          transform: transform,
        );
        if (candidates.isEmpty) {
          diagnostics.add(
            _error(
              request,
              code: 'border.resolution.connected_line_transform_unavailable',
              scope: BorderDiagnosticScope.segment,
              strokeId: lattice.strokeId,
              segmentIndex: node.index,
              cell: node.cell,
              parameters: <String, Object?>{
                'role': borderPrimitiveRoleV1WireName(role),
                'quarterTurns': transform.quarterTurns,
                'flipX': transform.flipX,
              },
              action: 'border.action.allow_required_connected_line_transform',
            ),
          );
        }
        nodeNeeds.add(
          _NodeNeed(
            lattice: lattice,
            node: node,
            role: role,
            transform: transform,
            candidates: candidates,
          ),
        );
      } on ValidationException {
        diagnostics.add(
          _error(
            request,
            code: 'border.resolution.connected_line_topology_invalid',
            scope: BorderDiagnosticScope.segment,
            strokeId: lattice.strokeId,
            segmentIndex: node.index,
            cell: node.cell,
            action: 'border.action.redraw_valid_stroke',
          ),
        );
      }
    }
  }
  if (_hasErrors(diagnostics)) {
    return _failure(diagnostics);
  }

  final generated = localScope == null
      ? <_GeneratedNodePlacement>[]
      : _rebuildRetainedPlacements(
          request: request,
          scope: localScope,
          needs: nodeNeeds,
          primitives: primitives,
        );
  final retainedSlotKeys = <String>{
    if (localScope != null)
      for (final entry in generated) entry.placement.slotKey,
  };
  final evidence = <ConnectedLineNodeResolutionEvidence>[];
  for (final need in nodeNeeds) {
    final slotKey = _slotKey(request, need);
    evidence.add(
      ConnectedLineNodeResolutionEvidence(
        strokeId: need.lattice.strokeId,
        nodeIndex: need.node.index,
        cell: need.node.cell,
        role: need.role,
        transform: need.transform,
        slotKey: slotKey,
      ),
    );
    if (localScope != null &&
        !localScope.recomputesCell(need.node.cell, request.tileSizePx)) {
      continue;
    }
    localScope?.recordRecomputedCell(need.node.cell);
    final selected = _choosePrimitive(
      request,
      revision: revision,
      slotKey: slotKey,
      candidates: need.candidates,
      variationPermille: params.variationPermille,
    );
    final sprite = resolveBorderSpriteGeometry(
      metrics: selected.publishedMetrics,
      sourceAnchorPx: selected.anchorPx,
      transform: need.transform,
      targetAnchorWorldPx: _cellCenterWorldPx(request, need.node.cell),
    );
    final canvas = GridSize(
      width: request.mapSize.width * request.tileSizePx.width,
      height: request.mapSize.height * request.tileSizePx.height,
    );
    if (!borderPixelRectIntersectsCanvas(
      rect: sprite.opaqueWorldBoundsPx,
      canvasSizePx: canvas,
    )) {
      continue;
    }
    generated.add(
      _GeneratedNodePlacement(
        strokeId: need.lattice.strokeId,
        nodeIndex: need.node.index,
        primitive: selected,
        placement: BorderResolvedPlacement(
          id: 'border-placement-v1:${slotKey.substring(borderSlotKeyV1Prefix.length)}',
          slotKey: slotKey,
          primitiveId: selected.id,
          visualSnapshotId: selected.visualSnapshotId,
          anchorCell: need.node.cell,
          topLeftWorldPx: sprite.topLeftWorldPx,
          opaqueWorldBoundsPx: sprite.opaqueWorldBoundsPx,
          transform: need.transform,
          drawBand: BorderDrawBand.structure,
          stableOrderKey: buildBorderStableOrderKey(
            drawBand: BorderDrawBand.structure,
            mapWidth: request.mapSize.width,
            anchorCell: need.node.cell,
            passIndex: 0,
            rank: 0,
            ordinalLocal: 0,
            slotKey: slotKey,
          ),
        ),
      ),
    );
  }

  final baseGenerated = List<_GeneratedNodePlacement>.of(generated);
  localCapture?.recordBase(
    ground: const <BorderResolvedGroundCell>[],
    placements: baseGenerated.map((entry) => entry.placement),
  );
  final overrideResolution = resolveBorderOverrides(
    request: request,
    baseGround: const <BorderResolvedGroundCell>[],
    basePlacements: baseGenerated.map((entry) => entry.placement),
    alreadyResolvedSlotKeys: retainedSlotKeys,
    previouslyResolvedPlacementsBySlot:
        localScope?.previousResolvedPlacementsBySlot ??
            const <String, BorderResolvedPlacement>{},
    previouslySuppressedSlotKeys:
        localScope?.previousSuppressedPlacementSlotKeys ?? const <String>{},
  );
  diagnostics.addAll(overrideResolution.diagnostics);
  if (_hasErrors(diagnostics)) {
    return ConnectedLineBorderResolutionEvidence(
      result: _failed(diagnostics),
      nodes: evidence,
    );
  }
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
    return ConnectedLineBorderResolutionEvidence(
      result: _failed(diagnostics),
      nodes: evidence,
    );
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
  return ConnectedLineBorderResolutionEvidence(
    result: BorderResolutionResult(
      materialization: materialization,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    ),
    nodes: evidence,
  );
}

void _diagnoseRequiredRoles(
  BorderResolutionRequest request,
  List<BorderPublishedPrimitive> primitives,
  List<BorderDiagnostic> diagnostics,
) {
  for (final (role, code, action) in <(BorderPrimitiveRole, String, String)>[
    (
      BorderPrimitiveRole.lineCap,
      'border.resolution.connected_line_cap_role_missing',
      'border.action.assign_connected_line_cap',
    ),
    (
      BorderPrimitiveRole.lineStraight,
      'border.resolution.connected_line_straight_role_missing',
      'border.action.assign_connected_line_straight',
    ),
    (
      BorderPrimitiveRole.lineCorner,
      'border.resolution.connected_line_corner_role_missing',
      'border.action.assign_connected_line_corner',
    ),
  ]) {
    if (!primitives.any(
      (primitive) => primitive.role == role && primitive.weight > 0,
    )) {
      diagnostics.add(
        _error(
          request,
          code: code,
          scope: BorderDiagnosticScope.blueprint,
          parameters: <String, Object?>{
            'role': borderPrimitiveRoleV1WireName(role),
          },
          action: action,
        ),
      );
    }
  }
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
    if (!_connectedLineRoleAllowed(primitive.role)) {
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

BorderPrimitiveRole _roleForNode(BorderLinearNodeNeed node) =>
    switch (node.kind) {
      BorderLinearNodeKind.endpoint => BorderPrimitiveRole.lineCap,
      BorderLinearNodeKind.straight => BorderPrimitiveRole.lineStraight,
      BorderLinearNodeKind.corner => BorderPrimitiveRole.lineCorner,
    };

int _primaryQuarterTurns(
  BorderLinearNodeNeed node,
  BorderPrimitiveRole role,
) {
  final connections = <BorderCardinalDirection>{
    if (node.incomingDirection case final incoming?) _opposite(incoming),
    if (node.outgoingDirection case final outgoing?) outgoing,
  };
  if (role == BorderPrimitiveRole.lineCap && connections.length == 1) {
    return borderCardinalDirectionV1Rank(connections.single);
  }
  if (role == BorderPrimitiveRole.lineStraight && connections.length == 2) {
    if (connections.contains(BorderCardinalDirection.east) &&
        connections.contains(BorderCardinalDirection.west)) {
      return 0;
    }
    if (connections.contains(BorderCardinalDirection.north) &&
        connections.contains(BorderCardinalDirection.south)) {
      return 1;
    }
  }
  if (role == BorderPrimitiveRole.lineCorner && connections.length == 2) {
    final west = connections.contains(BorderCardinalDirection.west);
    final east = connections.contains(BorderCardinalDirection.east);
    final north = connections.contains(BorderCardinalDirection.north);
    final south = connections.contains(BorderCardinalDirection.south);
    if (west && south) return 0;
    if (west && north) return 1;
    if (east && north) return 2;
    if (east && south) return 3;
  }
  throw const ValidationException(
    'Connected-line node connectivity does not match its role',
  );
}

BorderSpriteTransform _composeLineSide({
  required BorderPrimitiveRole role,
  required int primaryQuarterTurns,
  required BorderLineSide lineSide,
  required bool allowAutoRotation,
}) {
  if (lineSide == BorderLineSide.primary) {
    return BorderSpriteTransform(
      quarterTurns: primaryQuarterTurns,
      flipX: false,
    );
  }
  final rotationDelta = !allowAutoRotation
      ? 0
      : role == BorderPrimitiveRole.lineCap ||
              role == BorderPrimitiveRole.lineStraight
          ? 2
          : role == BorderPrimitiveRole.lineCorner
              ? 1
              : 0;
  return BorderSpriteTransform(
    quarterTurns: (primaryQuarterTurns + rotationDelta) % 4,
    flipX: true,
  );
}

List<BorderPublishedPrimitive> _eligibleCandidates(
  Iterable<BorderPublishedPrimitive> primitives, {
  required BorderPrimitiveRole role,
  required BorderSpriteTransform transform,
}) =>
    primitives
        .where(
          (primitive) =>
              primitive.role == role &&
              primitive.weight > 0 &&
              primitive.transforms.allowedQuarterTurns
                  .contains(transform.quarterTurns) &&
              (!transform.flipX || primitive.transforms.allowFlipX),
        )
        .toList(growable: false)
      ..sort((left, right) => left.id.compareTo(right.id));

BorderPublishedPrimitive _choosePrimitive(
  BorderResolutionRequest request, {
  required BorderBlueprintRevision revision,
  required String slotKey,
  required List<BorderPublishedPrimitive> candidates,
  required int variationPermille,
}) {
  if (variationPermille == 0 || candidates.length == 1) {
    return candidates.first;
  }
  final passesVariationGate = BorderDeterministicRng.fromComponents(
        <BorderRngKeyComponent>[
          const BorderRngKeyComponent.text(
            'connected-line-variation-gate',
          ),
          BorderRngKeyComponent.text(request.blueprintId),
          BorderRngKeyComponent.signedInt64(
            BorderSignedInt64.fromInt(revision.revision),
          ),
          BorderRngKeyComponent.signedInt64(request.feature.seed),
          BorderRngKeyComponent.text(slotKey),
        ],
      ).nextIndex(1000) <
      variationPermille;
  if (!passesVariationGate) {
    return candidates.first;
  }
  return chooseBorderWeightedCandidate(
    BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
      const BorderRngKeyComponent.text('connected-line-primitive'),
      BorderRngKeyComponent.text(request.blueprintId),
      BorderRngKeyComponent.signedInt64(
        BorderSignedInt64.fromInt(revision.revision),
      ),
      BorderRngKeyComponent.signedInt64(request.feature.seed),
      BorderRngKeyComponent.text(slotKey),
    ]),
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

String _slotKey(BorderResolutionRequest request, _NodeNeed need) =>
    buildBorderConnectedLineNodeSlotKey(
      featureId: request.feature.id,
      strokeId: need.lattice.lineageNamespace,
      cell: need.node.cell,
      passIndex: 0,
      role: need.role,
      rank: 0,
      ordinalLocal: 0,
    );

List<_GeneratedNodePlacement> _rebuildRetainedPlacements({
  required BorderResolutionRequest request,
  required BorderLocalResolutionScope scope,
  required List<_NodeNeed> needs,
  required List<BorderPublishedPrimitive> primitives,
}) {
  final needByCell = <GridPos, _NodeNeed>{
    for (final need in needs) need.node.cell: need,
  };
  final primitiveById = <String, BorderPublishedPrimitive>{
    for (final primitive in primitives) primitive.id: primitive,
  };
  final retained = <_GeneratedNodePlacement>[];
  for (final placement in scope.previousBasePlacements) {
    final need = needByCell[placement.anchorCell];
    final primitive = primitiveById[placement.primitiveId];
    if (need == null ||
        primitive == null ||
        !scope.retainsBasePlacement(placement, request.tileSizePx)) {
      continue;
    }
    retained.add(
      _GeneratedNodePlacement(
        strokeId: need.lattice.strokeId,
        nodeIndex: need.node.index,
        primitive: primitive,
        placement: placement,
      ),
    );
  }
  return retained;
}

BorderPixelPos _cellCenterWorldPx(
  BorderResolutionRequest request,
  GridPos cell,
) =>
    BorderPixelPos(
      x: cell.x * request.tileSizePx.width + request.tileSizePx.width ~/ 2,
      y: cell.y * request.tileSizePx.height + request.tileSizePx.height ~/ 2,
    );

BorderCardinalDirection _opposite(BorderCardinalDirection direction) =>
    switch (direction) {
      BorderCardinalDirection.east => BorderCardinalDirection.west,
      BorderCardinalDirection.south => BorderCardinalDirection.north,
      BorderCardinalDirection.west => BorderCardinalDirection.east,
      BorderCardinalDirection.north => BorderCardinalDirection.south,
    };

bool _connectedLineRoleAllowed(BorderPrimitiveRole role) =>
    role == BorderPrimitiveRole.lineCap ||
    role == BorderPrimitiveRole.lineStraight ||
    role == BorderPrimitiveRole.lineCorner;

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

bool _sameStroke(BorderStroke left, BorderStroke right) =>
    left.id == right.id &&
    left.closed == right.closed &&
    _listsEqual(left.points, right.points);

bool _hasErrors(List<BorderDiagnostic> diagnostics) => diagnostics.any(
      (diagnostic) => diagnostic.severity == BorderDiagnosticSeverity.error,
    );

ConnectedLineBorderResolutionEvidence _failure(
  List<BorderDiagnostic> diagnostics,
) =>
    ConnectedLineBorderResolutionEvidence(
      result: _failed(diagnostics),
      nodes: const <ConnectedLineNodeResolutionEvidence>[],
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

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

final class _NodeNeed {
  const _NodeNeed({
    required this.lattice,
    required this.node,
    required this.role,
    required this.transform,
    required this.candidates,
  });

  final BorderLinearStrokeLattice lattice;
  final BorderLinearNodeNeed node;
  final BorderPrimitiveRole role;
  final BorderSpriteTransform transform;
  final List<BorderPublishedPrimitive> candidates;
}

final class _GeneratedNodePlacement {
  const _GeneratedNodePlacement({
    required this.strokeId,
    required this.nodeIndex,
    required this.primitive,
    required this.placement,
  });

  final String strokeId;
  final int nodeIndex;
  final BorderPublishedPrimitive primitive;
  final BorderResolvedPlacement placement;
}
