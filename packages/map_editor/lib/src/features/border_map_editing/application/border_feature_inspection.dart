import 'package:map_core/map_core.dart';

/// Optional transient proposal to inspect instead of the persisted feature.
///
/// The value contains no callbacks or mutable editor state. Supplying it lets
/// Marionette prove a preview's geometry and resolved output before Apply.
final class BorderFeatureInspectionPreview {
  const BorderFeatureInspectionPreview({
    required this.layerId,
    required this.feature,
    this.materialization,
  });

  final String layerId;
  final BorderFeature feature;
  final BorderMaterialization? materialization;
}

/// Builds a JSON-safe, read-only report for one persisted Border feature.
///
/// This helper deliberately accepts immutable domain values and performs no
/// authoring action. It is shared by the Marionette service extension and its
/// regression tests so live visual checks can also verify the persisted
/// geometry and materialization contract.
Map<String, Object?> inspectBorderFeature({
  required MapData? map,
  required ProjectManifest? project,
  String? layerId,
  String? featureId,
  BorderFeatureInspectionPreview? preview,
}) {
  final requestedLayerId = _stableOptionalId(layerId);
  final requestedFeatureId = _stableOptionalId(featureId);
  final match = _findFeature(
    map: map,
    layerId: requestedLayerId,
    featureId: requestedFeatureId,
  );
  if (match == null || project == null) {
    return <String, Object?>{
      'ok': false,
      'error': map == null || project == null
          ? 'No active map or project.'
          : 'Border feature not found.',
      if (requestedLayerId != null) 'layerId': requestedLayerId,
      if (requestedFeatureId != null) 'featureId': requestedFeatureId,
    };
  }

  final layer = match.layer;
  final matchingPreview =
      preview?.layerId == layer.id && preview?.feature.id == match.feature.id
          ? preview
          : null;
  final feature = matchingPreview?.feature ?? match.feature;
  final record = project.borderCatalog.recordById(feature.blueprintId);
  final published = record?.latestPublished;
  final template =
      published?.definition.template ?? record?.draft.definition.template;
  final primitives = <_InspectionPrimitive>[
    if (published != null)
      for (final primitive in published.definition.primitives)
        _InspectionPrimitive(
          id: primitive.id,
          role: primitive.role,
          authoredOrientation: primitive.authoredOrientation,
          metrics: primitive.publishedMetrics,
        )
    else if (record != null)
      for (final primitive in record.draft.definition.primitives)
        _InspectionPrimitive(
          id: primitive.id,
          role: primitive.role,
          authoredOrientation: primitive.authoredOrientation,
          metrics: primitive.currentMetrics,
        ),
  ]..sort((left, right) => left.id.compareTo(right.id));
  final primitivesById = <String, _InspectionPrimitive>{
    for (final primitive in primitives) primitive.id: primitive,
  };
  final materialization =
      matchingPreview?.materialization ?? feature.materialization;
  final placements =
      materialization?.placements ?? const <BorderResolvedPlacement>[];
  final roleCounts = <String, int>{};
  for (final placement in placements) {
    final role = primitivesById[placement.primitiveId]?.role;
    final roleName =
        role == null ? 'unknown' : borderPrimitiveRoleV1WireName(role);
    roleCounts.update(roleName, (count) => count + 1, ifAbsent: () => 1);
  }

  final geometry = feature.geometry;
  final stoneChainMeasurement =
      template == BorderBlueprintTemplate.stoneChainLine &&
              geometry is BorderStrokeGeometry
          ? _measureStoneChainInspection(
              featureId: feature.id,
              placements: placements,
              primitivesById: primitivesById,
              geometry: geometry,
              lineSide: feature.lineSide,
            )
          : const _StoneChainInspectionMeasurement.empty();
  return <String, Object?>{
    'ok': true,
    'source': matchingPreview == null ? 'persisted' : 'preview',
    'mapId': map!.id,
    'layerId': layer.id,
    'layerName': layer.name,
    'layerVisible': layer.isVisible,
    'layerOpacity': layer.opacity,
    'layerFormatVersion': layer.content.formatVersion,
    'featureId': feature.id,
    'featureName': feature.name,
    'blueprintId': feature.blueprintId,
    'publishedRevision': published?.revision,
    'template':
        template == null ? null : borderBlueprintTemplateV1WireName(template),
    'alignment': geometry is BorderStrokeGeometry
        ? borderStrokeAlignmentV1WireName(geometry.alignment)
        : null,
    'side': feature.lineSide.name,
    'points': _geometryPoints(geometry),
    'roles': <String, Object?>{
      for (final entry in roleCounts.entries) entry.key: entry.value,
    },
    'lipCount': stoneChainMeasurement.lipCount,
    'faceCount': stoneChainMeasurement.faceCount,
    'completeTurnFacePairCount':
        stoneChainMeasurement.completeTurnFacePairCount,
    'logicalFaceCount': stoneChainMeasurement.logicalFaceCount,
    'topologyNormalizedFaceLipRatioPermille':
        stoneChainMeasurement.topologyNormalizedFaceLipRatioPermille,
    'lipMaximumGapPx': stoneChainMeasurement.lipMaximumGapPx,
    'faceMaximumGapPx': stoneChainMeasurement.faceMaximumGapPx,
    'minimumCrossRowInterlockPixels':
        stoneChainMeasurement.minimumCrossRowInterlockPixels,
    'medianVisibleFaceDepthPx': stoneChainMeasurement.medianVisibleFaceDepthPx,
    'alignedJointRatioPermille':
        stoneChainMeasurement.alignedJointRatioPermille,
    'orientations': <Object?>[
      for (final primitive in primitives)
        <String, Object?>{
          'primitiveId': primitive.id,
          'role': borderPrimitiveRoleV1WireName(primitive.role),
          'authoredOrientation': primitive.authoredOrientation.name,
        },
    ],
    'transforms': <Object?>[
      for (final placement in placements)
        <String, Object?>{
          'slotKey': placement.slotKey,
          'primitiveId': placement.primitiveId,
          'role': primitivesById[placement.primitiveId] == null
              ? 'unknown'
              : borderPrimitiveRoleV1WireName(
                  primitivesById[placement.primitiveId]!.role,
                ),
          'authoredOrientation':
              primitivesById[placement.primitiveId]?.authoredOrientation.name,
          'effectiveOrientation': _effectiveOrientationName(
            primitivesById[placement.primitiveId]?.authoredOrientation,
            placement.transform.quarterTurns,
          ),
          'quarterTurns': placement.transform.quarterTurns,
          'flipX': placement.transform.flipX,
          'anchor': <String, int>{
            'x': placement.anchorCell.x,
            'y': placement.anchorCell.y,
          },
        },
    ],
    'placementCount': placements.length,
    'groundCount': materialization?.ground.length ?? 0,
    'outputFingerprint': materialization?.receipt.outputFingerprint,
  };
}

String? _stableOptionalId(String? value) {
  final stable = value?.trim();
  return stable == null || stable.isEmpty ? null : stable;
}

_BorderFeatureMatch? _findFeature({
  required MapData? map,
  required String? layerId,
  required String? featureId,
}) {
  if (map == null) {
    return null;
  }
  for (final candidate in map.layers.whereType<BorderLayer>()) {
    if (layerId != null && candidate.id != layerId) {
      continue;
    }
    if (featureId != null) {
      final feature = candidate.content.featureById(featureId);
      if (feature != null) {
        return _BorderFeatureMatch(layer: candidate, feature: feature);
      }
      if (layerId != null) {
        return null;
      }
      continue;
    }
    if (candidate.content.features.isNotEmpty) {
      return _BorderFeatureMatch(
        layer: candidate,
        feature: candidate.content.features.first,
      );
    }
  }
  return null;
}

List<Object?> _geometryPoints(BorderFeatureGeometry geometry) =>
    switch (geometry) {
      BorderStrokeGeometry() => <Object?>[
          for (final stroke in geometry.strokes)
            <String, Object?>{
              'strokeId': stroke.id,
              'closed': stroke.closed,
              'vertices': <Object?>[
                for (final point in stroke.points)
                  <String, int>{'x': point.x, 'y': point.y},
              ],
            },
        ],
      BorderRegionGeometry() => <Object?>[],
    };

_StoneChainInspectionMeasurement _measureStoneChainInspection({
  required String featureId,
  required List<BorderResolvedPlacement> placements,
  required Map<String, _InspectionPrimitive> primitivesById,
  required BorderStrokeGeometry geometry,
  required BorderLineSide lineSide,
}) {
  final topologicalRuns = _stoneChainTopologicalRuns(
    geometry: geometry,
    lineSide: lineSide,
  );
  final turnFaceRuns = _stoneChainTurnFaceRuns(
    featureId: featureId,
    geometry: geometry,
    lineSide: lineSide,
    runs: topologicalRuns,
  );
  var lipCount = 0;
  var faceCount = 0;
  final measurable = <_StoneChainInspectionPlacement>[];
  for (final placement in placements) {
    final primitive = primitivesById[placement.primitiveId];
    if (primitive == null) continue;
    final row = switch (primitive.role) {
      BorderPrimitiveRole.structureLarge ||
      BorderPrimitiveRole.lineCorner ||
      BorderPrimitiveRole.lineCap =>
        _StoneChainInspectionRow.lip,
      BorderPrimitiveRole.structureMedium => _StoneChainInspectionRow.face,
      _ => null,
    };
    if (row == null) continue;
    if (row == _StoneChainInspectionRow.lip) {
      lipCount += 1;
    } else {
      faceCount += 1;
    }
    final axes = _stoneChainAxesFor(
      primitive.authoredOrientation,
      placement.transform.quarterTurns,
    );
    if (axes == null) continue;
    final station = GridPos(
      x: placement.anchorCell.x + (axes.normal.dx < 0 ? 1 : 0),
      y: placement.anchorCell.y + (axes.normal.dy < 0 ? 1 : 0),
    );
    final topologicalRun = _stoneChainTopologicalRunFor(
      runs: topologicalRuns,
      station: station,
      normal: axes.normal,
      isTurnFace: turnFaceRuns.containsKey(placement.slotKey),
      turnRunKey: turnFaceRuns[placement.slotKey],
    );
    final runKey = topologicalRun?.key ??
        (
          strokeId: 'unassigned:${placement.slotKey}',
          ordinal: 0,
          normalDx: axes.normal.dx,
          normalDy: axes.normal.dy,
        );
    measurable.add(
      _StoneChainInspectionPlacement(
        placement: placement,
        primitive: primitive,
        row: row,
        runKey: runKey,
        normal: axes.normal,
        tangent: axes.tangent,
      ),
    );
  }
  final lips = measurable
      .where((placement) => placement.row == _StoneChainInspectionRow.lip)
      .toList(growable: false);
  final faces = measurable
      .where((placement) => placement.row == _StoneChainInspectionRow.face)
      .toList(growable: false);
  final lipRuns = _stoneChainInspectionRuns(lips);
  final faceRunByPlacement =
      <_StoneChainInspectionPlacement, _StoneChainInspectionRunKey>{
    for (final entry in _stoneChainInspectionRuns(faces).entries)
      for (final placement in entry.value) placement: entry.key,
  };

  final visibleDepths = <int>[];
  final interlocks = <int>[];
  for (final face in faces) {
    final candidates = lips
        .where((lip) => lip.strokeId == face.strokeId)
        .toList(growable: false);
    var bestInterlock = 0;
    for (final lip in candidates) {
      final contact = measureStoneChainContact(
        first: lip.mask,
        second: face.mask,
        tangent: face.tangent,
        normal: face.normal,
      );
      if (contact.opaqueIntersectionPixels > bestInterlock) {
        bestInterlock = contact.opaqueIntersectionPixels;
      }
    }
    interlocks.add(bestInterlock);
    final faceFront = _maximumBoundsProjection(
      face.placement.opaqueWorldBoundsPx,
      face.normal,
    );
    int? lipFront;
    final faceRun = faceRunByPlacement[face];
    final depthCandidates = faceRun == null
        ? candidates.where(
            (lip) =>
                lip.normal.dx == face.normal.dx &&
                lip.normal.dy == face.normal.dy,
          )
        : lipRuns[faceRun] ?? const <_StoneChainInspectionPlacement>[];
    for (final lip in depthCandidates) {
      final candidateFront = _maximumBoundsProjection(
        lip.placement.opaqueWorldBoundsPx,
        face.normal,
      );
      if (lipFront == null || candidateFront > lipFront) {
        lipFront = candidateFront;
      }
    }
    final visibleDepth = faceFront - (lipFront ?? faceFront);
    visibleDepths.add(visibleDepth > 0 ? visibleDepth : 0);
  }
  visibleDepths.sort();
  final completeTurnFacePairCount = _completeTurnFacePairCount(
    featureId: featureId,
    geometry: geometry,
    placementSlotKeys: <String>{
      for (final placement in placements) placement.slotKey,
    },
  );
  final logicalFaceCount = _maximumInt(
    0,
    faceCount - completeTurnFacePairCount,
  );

  return _StoneChainInspectionMeasurement(
    lipCount: lipCount,
    faceCount: faceCount,
    completeTurnFacePairCount: completeTurnFacePairCount,
    logicalFaceCount: logicalFaceCount,
    topologyNormalizedFaceLipRatioPermille:
        lipCount == 0 ? 0 : logicalFaceCount * 1000 ~/ lipCount,
    lipMaximumGapPx: _measureStoneChainRowGap(lips),
    faceMaximumGapPx: _measureStoneChainRowGap(faces),
    minimumCrossRowInterlockPixels:
        interlocks.isEmpty ? 0 : interlocks.reduce(_minimumInt),
    medianVisibleFaceDepthPx: _integerMedian(visibleDepths),
    alignedJointRatioPermille: _alignedJointRatioPermille(
      lips: lips,
      faces: faces,
    ),
  );
}

int _measureStoneChainRowGap(
  List<_StoneChainInspectionPlacement> placements,
) {
  final runs = _stoneChainInspectionRuns(placements);
  var maximumGap = 0;
  for (final run in runs.values) {
    final ordered = run.toList(growable: false)
      ..sort((left, right) {
        final byProjection = _minimumBoundsProjection(
          left.placement.opaqueWorldBoundsPx,
          left.tangent,
        ).compareTo(
          _minimumBoundsProjection(
            right.placement.opaqueWorldBoundsPx,
            right.tangent,
          ),
        );
        return byProjection != 0
            ? byProjection
            : left.placement.slotKey.compareTo(right.placement.slotKey);
      });
    final continuity = measureStoneChainRowContinuity(
      samples: <StoneChainRowSample>[
        for (var index = 0; index < ordered.length; index += 1)
          StoneChainRowSample(
            strokeId: ordered.first.strokeId,
            slotKey: ordered[index].placement.slotKey,
            pathDistancePx: index,
            closed: false,
            mask: ordered[index].mask,
          ),
      ],
      tangent: ordered.first.tangent,
      normal: ordered.first.normal,
    );
    if (continuity.maximumGapPx > maximumGap) {
      maximumGap = continuity.maximumGapPx;
    }
  }
  return maximumGap;
}

int _alignedJointRatioPermille({
  required List<_StoneChainInspectionPlacement> lips,
  required List<_StoneChainInspectionPlacement> faces,
}) {
  final lipJointsByRun = _stoneChainJointCoordinatesByRun(lips);
  final faceJointsByRun = _stoneChainJointCoordinatesByRun(faces);
  var aligned = 0;
  var totalFaceJoints = 0;
  for (final entry in faceJointsByRun.entries) {
    totalFaceJoints += entry.value.length;
    final lipJoints = lipJointsByRun[entry.key] ?? const <int>{};
    aligned += entry.value
        .where(
          (faceJoint) => lipJoints.any(
            (lipJoint) => (faceJoint - lipJoint).abs() <= 2,
          ),
        )
        .length;
  }
  return totalFaceJoints == 0 ? 0 : (aligned * 1000) ~/ totalFaceJoints;
}

Map<_StoneChainInspectionRunKey, Set<int>> _stoneChainJointCoordinatesByRun(
  List<_StoneChainInspectionPlacement> placements,
) {
  final runs = _stoneChainInspectionRuns(placements);
  return <_StoneChainInspectionRunKey, Set<int>>{
    for (final entry in runs.entries)
      entry.key: _stoneChainJointCoordinates(entry.value),
  };
}

Map<_StoneChainInspectionRunKey, List<_StoneChainInspectionPlacement>>
    _stoneChainInspectionRuns(
  List<_StoneChainInspectionPlacement> placements,
) {
  final runs =
      <_StoneChainInspectionRunKey, List<_StoneChainInspectionPlacement>>{};
  for (final placement in placements) {
    (runs[placement.runKey] ??= <_StoneChainInspectionPlacement>[]).add(
      placement,
    );
  }
  return runs;
}

List<_StoneChainTopologicalRun> _stoneChainTopologicalRuns({
  required BorderStrokeGeometry geometry,
  required BorderLineSide lineSide,
}) {
  final sideSign = lineSide == BorderLineSide.primary ? 1 : -1;
  final runs = <_StoneChainTopologicalRun>[];
  for (final stroke in geometry.strokes) {
    final edges = <_StoneChainTopologicalEdge>[];
    final edgeCount =
        stroke.closed ? stroke.points.length : stroke.points.length - 1;
    for (var index = 0; index < edgeCount; index += 1) {
      final start = stroke.points[index];
      final end = stroke.points[(index + 1) % stroke.points.length];
      final tangent = StoneChainAxis(
        dx: end.x - start.x,
        dy: end.y - start.y,
      );
      edges.add(
        _StoneChainTopologicalEdge(
          start: start,
          end: end,
          normal: StoneChainAxis(
            dx: -tangent.dy * sideSign,
            dy: tangent.dx * sideSign,
          ),
        ),
      );
    }
    final edgeGroups = <List<_StoneChainTopologicalEdge>>[];
    for (final edge in edges) {
      if (edgeGroups.isEmpty ||
          !_sameAxis(edgeGroups.last.first.normal, edge.normal)) {
        edgeGroups.add(<_StoneChainTopologicalEdge>[edge]);
      } else {
        edgeGroups.last.add(edge);
      }
    }
    if (stroke.closed &&
        edgeGroups.length > 1 &&
        _sameAxis(
            edgeGroups.first.first.normal, edgeGroups.last.first.normal)) {
      edgeGroups.first.insertAll(0, edgeGroups.removeLast());
    }
    for (var ordinal = 0; ordinal < edgeGroups.length; ordinal += 1) {
      final group = edgeGroups[ordinal];
      runs.add(
        _StoneChainTopologicalRun(
          key: (
            strokeId: stroke.id,
            ordinal: ordinal,
            normalDx: group.first.normal.dx,
            normalDy: group.first.normal.dy,
          ),
          normal: group.first.normal,
          stations: <GridPos>{
            for (final edge in group) edge.start,
            for (final edge in group) edge.end,
          },
        ),
      );
    }
  }
  return runs;
}

_StoneChainTopologicalRun? _stoneChainTopologicalRunFor({
  required List<_StoneChainTopologicalRun> runs,
  required GridPos station,
  required StoneChainAxis normal,
  required bool isTurnFace,
  required _StoneChainInspectionRunKey? turnRunKey,
}) {
  for (final run in runs) {
    if (_sameAxis(run.normal, normal) && run.stations.contains(station)) {
      return run;
    }
  }

  if (!isTurnFace || turnRunKey == null) return null;

  // Turn-face slots encode the vertex and pass: rank zero designates the
  // incoming run, rank one the outgoing run. This remains unambiguous even
  // when the shoulder cell is equally close to parallel neighbours. Still
  // require a real one-cell shoulder so malformed placement metadata cannot
  // turn a detached face into interlock.
  for (final run in runs) {
    if (run.key == turnRunKey &&
        _sameAxis(run.normal, normal) &&
        _isOneTangentCellFromRun(
          station: station,
          run: run,
        )) {
      return run;
    }
  }
  return null;
}

Map<String, _StoneChainInspectionRunKey?> _stoneChainTurnFaceRuns({
  required String featureId,
  required BorderStrokeGeometry geometry,
  required BorderLineSide lineSide,
  required List<_StoneChainTopologicalRun> runs,
}) {
  final result = <String, _StoneChainInspectionRunKey?>{};
  final sideSign = lineSide == BorderLineSide.primary ? 1 : -1;
  for (final stroke in geometry.strokes) {
    final firstTurnIndex = stroke.closed ? 0 : 1;
    final endTurnIndex =
        stroke.closed ? stroke.points.length : stroke.points.length - 1;
    for (var index = firstTurnIndex; index < endTurnIndex; index += 1) {
      final previous = stroke
          .points[(index - 1 + stroke.points.length) % stroke.points.length];
      final vertex = stroke.points[index];
      final next = stroke.points[(index + 1) % stroke.points.length];
      final incoming = StoneChainAxis(
        dx: vertex.x - previous.x,
        dy: vertex.y - previous.y,
      );
      final outgoing = StoneChainAxis(
        dx: next.x - vertex.x,
        dy: next.y - vertex.y,
      );
      if (_sameAxis(incoming, outgoing)) continue;
      void registerTurnFaceRun({
        required StoneChainAxis tangent,
        required GridPos edgeStart,
        required GridPos edgeEnd,
        required int rank,
      }) {
        final normal = StoneChainAxis(
          dx: -tangent.dy * sideSign,
          dy: tangent.dx * sideSign,
        );
        final candidates = runs
            .where(
              (run) =>
                  run.key.strokeId == stroke.id &&
                  _sameAxis(run.normal, normal) &&
                  run.stations.contains(edgeStart) &&
                  run.stations.contains(edgeEnd),
            )
            .toList(growable: false);
        final slotKey = buildBorderStoneChainNodeSlotKey(
          featureId: featureId,
          strokeId: borderStrokeLineageNamespaceV1(stroke.id),
          vertex: vertex,
          passIndex: 1,
          role: BorderPrimitiveRole.structureMedium,
          rank: rank,
        );
        result[slotKey] = candidates.length == 1 ? candidates.single.key : null;
      }

      registerTurnFaceRun(
        tangent: incoming,
        edgeStart: previous,
        edgeEnd: vertex,
        rank: 0,
      );
      registerTurnFaceRun(
        tangent: outgoing,
        edgeStart: vertex,
        edgeEnd: next,
        rank: 1,
      );
    }
  }
  return result;
}

int _completeTurnFacePairCount({
  required String featureId,
  required BorderStrokeGeometry geometry,
  required Set<String> placementSlotKeys,
}) {
  var count = 0;
  for (final stroke in geometry.strokes) {
    final firstTurnIndex = stroke.closed ? 0 : 1;
    final endTurnIndex =
        stroke.closed ? stroke.points.length : stroke.points.length - 1;
    for (var index = firstTurnIndex; index < endTurnIndex; index += 1) {
      final previous = stroke
          .points[(index - 1 + stroke.points.length) % stroke.points.length];
      final vertex = stroke.points[index];
      final next = stroke.points[(index + 1) % stroke.points.length];
      final incomingX = vertex.x - previous.x;
      final incomingY = vertex.y - previous.y;
      final outgoingX = next.x - vertex.x;
      final outgoingY = next.y - vertex.y;
      if (incomingX == outgoingX && incomingY == outgoingY) continue;
      bool hasShoulder(int rank) => placementSlotKeys.contains(
            buildBorderStoneChainNodeSlotKey(
              featureId: featureId,
              strokeId: borderStrokeLineageNamespaceV1(stroke.id),
              vertex: vertex,
              passIndex: 1,
              role: BorderPrimitiveRole.structureMedium,
              rank: rank,
            ),
          );
      if (hasShoulder(0) && hasShoulder(1)) count += 1;
    }
  }
  return count;
}

bool _isOneTangentCellFromRun({
  required GridPos station,
  required _StoneChainTopologicalRun run,
}) =>
    run.stations.any((candidate) {
      final dx = station.x - candidate.x;
      final dy = station.y - candidate.y;
      return dx.abs() + dy.abs() == 1 &&
          dx * run.normal.dx + dy * run.normal.dy == 0;
    });

bool _sameAxis(StoneChainAxis left, StoneChainAxis right) =>
    left.dx == right.dx && left.dy == right.dy;

Set<int> _stoneChainJointCoordinates(
  List<_StoneChainInspectionPlacement> placements,
) {
  final ordered = placements.toList(growable: false)
    ..sort((left, right) {
      final byProjection = _minimumBoundsProjection(
        left.placement.opaqueWorldBoundsPx,
        left.tangent,
      ).compareTo(
        _minimumBoundsProjection(
          right.placement.opaqueWorldBoundsPx,
          right.tangent,
        ),
      );
      return byProjection != 0
          ? byProjection
          : left.placement.slotKey.compareTo(right.placement.slotKey);
    });
  return <int>{
    for (var index = 1; index < ordered.length; index += 1)
      (_maximumBoundsProjection(
                ordered[index - 1].placement.opaqueWorldBoundsPx,
                ordered[index - 1].tangent,
              ) +
              _minimumBoundsProjection(
                ordered[index].placement.opaqueWorldBoundsPx,
                ordered[index].tangent,
              )) ~/
          2,
  };
}

({StoneChainAxis normal, StoneChainAxis tangent})? _stoneChainAxesFor(
  BorderPrimitiveOrientation authored,
  int quarterTurns,
) {
  if (authored == BorderPrimitiveOrientation.legacyAxis) return null;
  return switch ((_orientationRank(authored) + quarterTurns) % 4) {
    0 => (
        normal: StoneChainAxis(dx: 1, dy: 0),
        tangent: StoneChainAxis(dx: 0, dy: -1),
      ),
    1 => (
        normal: StoneChainAxis(dx: 0, dy: 1),
        tangent: StoneChainAxis(dx: 1, dy: 0),
      ),
    2 => (
        normal: StoneChainAxis(dx: -1, dy: 0),
        tangent: StoneChainAxis(dx: 0, dy: 1),
      ),
    3 => (
        normal: StoneChainAxis(dx: 0, dy: -1),
        tangent: StoneChainAxis(dx: -1, dy: 0),
      ),
    _ => throw StateError('unreachable'),
  };
}

String? _effectiveOrientationName(
  BorderPrimitiveOrientation? authored,
  int quarterTurns,
) {
  if (authored == null || authored == BorderPrimitiveOrientation.legacyAxis) {
    return authored?.name;
  }
  return switch ((_orientationRank(authored) + quarterTurns) % 4) {
    0 => BorderPrimitiveOrientation.east.name,
    1 => BorderPrimitiveOrientation.south.name,
    2 => BorderPrimitiveOrientation.west.name,
    3 => BorderPrimitiveOrientation.north.name,
    _ => throw StateError('unreachable'),
  };
}

int _orientationRank(BorderPrimitiveOrientation orientation) =>
    switch (orientation) {
      BorderPrimitiveOrientation.east => 0,
      BorderPrimitiveOrientation.south => 1,
      BorderPrimitiveOrientation.west => 2,
      BorderPrimitiveOrientation.north => 3,
      BorderPrimitiveOrientation.legacyAxis =>
        throw ArgumentError.value(orientation, 'orientation'),
    };

int _minimumBoundsProjection(BorderPixelRect bounds, StoneChainAxis axis) =>
    _boundsProjections(bounds, axis).reduce(_minimumInt);

int _maximumBoundsProjection(BorderPixelRect bounds, StoneChainAxis axis) =>
    _boundsProjections(bounds, axis).reduce(_maximumInt);

List<int> _boundsProjections(BorderPixelRect bounds, StoneChainAxis axis) =>
    <int>[
      bounds.x * axis.dx + bounds.y * axis.dy,
      (bounds.right - 1) * axis.dx + bounds.y * axis.dy,
      bounds.x * axis.dx + (bounds.bottom - 1) * axis.dy,
      (bounds.right - 1) * axis.dx + (bounds.bottom - 1) * axis.dy,
    ];

int _minimumInt(int left, int right) => left < right ? left : right;

int _maximumInt(int left, int right) => left > right ? left : right;

int _integerMedian(List<int> sortedValues) {
  if (sortedValues.isEmpty) return 0;
  final middle = sortedValues.length ~/ 2;
  return sortedValues.length.isOdd
      ? sortedValues[middle]
      : (sortedValues[middle - 1] + sortedValues[middle]) ~/ 2;
}

enum _StoneChainInspectionRow { lip, face }

typedef _StoneChainInspectionRunKey = ({
  String strokeId,
  int ordinal,
  int normalDx,
  int normalDy,
});

final class _StoneChainTopologicalEdge {
  const _StoneChainTopologicalEdge({
    required this.start,
    required this.end,
    required this.normal,
  });

  final GridPos start;
  final GridPos end;
  final StoneChainAxis normal;
}

final class _StoneChainTopologicalRun {
  _StoneChainTopologicalRun({
    required this.key,
    required this.normal,
    required Set<GridPos> stations,
  }) : stations = Set<GridPos>.unmodifiable(stations);

  final _StoneChainInspectionRunKey key;
  final StoneChainAxis normal;
  final Set<GridPos> stations;
}

final class _InspectionPrimitive {
  const _InspectionPrimitive({
    required this.id,
    required this.role,
    required this.authoredOrientation,
    required this.metrics,
  });

  final String id;
  final BorderPrimitiveRole role;
  final BorderPrimitiveOrientation authoredOrientation;
  final BorderPrimitiveAssetMetrics metrics;
}

final class _StoneChainInspectionPlacement {
  const _StoneChainInspectionPlacement({
    required this.placement,
    required this.primitive,
    required this.row,
    required this.runKey,
    required this.normal,
    required this.tangent,
  });

  final BorderResolvedPlacement placement;
  final _InspectionPrimitive primitive;
  final _StoneChainInspectionRow row;
  final _StoneChainInspectionRunKey runKey;
  final StoneChainAxis normal;
  final StoneChainAxis tangent;

  String get strokeId => runKey.strokeId;

  StoneChainPlacedMask get mask => StoneChainPlacedMask(
        metrics: primitive.metrics,
        transform: placement.transform,
        topLeftWorldPx: placement.topLeftWorldPx,
      );
}

final class _StoneChainInspectionMeasurement {
  const _StoneChainInspectionMeasurement({
    required this.lipCount,
    required this.faceCount,
    required this.completeTurnFacePairCount,
    required this.logicalFaceCount,
    required this.topologyNormalizedFaceLipRatioPermille,
    required this.lipMaximumGapPx,
    required this.faceMaximumGapPx,
    required this.minimumCrossRowInterlockPixels,
    required this.medianVisibleFaceDepthPx,
    required this.alignedJointRatioPermille,
  });

  const _StoneChainInspectionMeasurement.empty()
      : lipCount = 0,
        faceCount = 0,
        completeTurnFacePairCount = 0,
        logicalFaceCount = 0,
        topologyNormalizedFaceLipRatioPermille = 0,
        lipMaximumGapPx = 0,
        faceMaximumGapPx = 0,
        minimumCrossRowInterlockPixels = 0,
        medianVisibleFaceDepthPx = 0,
        alignedJointRatioPermille = 0;

  final int lipCount;
  final int faceCount;
  final int completeTurnFacePairCount;
  final int logicalFaceCount;
  final int topologyNormalizedFaceLipRatioPermille;
  final int lipMaximumGapPx;
  final int faceMaximumGapPx;
  final int minimumCrossRowInterlockPixels;
  final int medianVisibleFaceDepthPx;
  final int alignedJointRatioPermille;
}

final class _BorderFeatureMatch {
  const _BorderFeatureMatch({required this.layer, required this.feature});

  final BorderLayer layer;
  final BorderFeature feature;
}
