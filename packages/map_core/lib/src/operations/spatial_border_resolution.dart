import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';
import '../models/project_model3d.dart';
import 'border_blueprint_json_codec.dart';
import 'border_feature_json_codec.dart';
import 'border_fingerprints.dart';
import 'border_layer_operations.dart';
import 'border_linear_lattice.dart';
import 'border_region_contours.dart';
import 'border_resolver.dart';
import 'narrative_event_canonical_json.dart';

final class SpatialBorderResolutionResult {
  SpatialBorderResolutionResult({
    required this.mapId,
    required this.layerId,
    required this.featureId,
    required this.result,
    required List<SpatialModelInstance> modelInstances,
  }) : modelInstances = List.unmodifiable(modelInstances);
  final String mapId, layerId, featureId;
  final BorderResolutionResult result;
  final List<SpatialModelInstance> modelInstances;
}

typedef _SpatialBorderNode = ({
  GridPos cell,
  BorderLinearNodeKind kind,
  BorderCardinalDirection? incomingDirection,
  BorderCardinalDirection? outgoingDirection,
  GridPos? terrainCell,
});

typedef SpatialBorderGroundReplacement = ({
  double left,
  double top,
  double right,
  double bottom,
  double lowerHeight,
  double upperHeight,
});

typedef SpatialBorderGroundReplacementIndex =
    Map<(int, int), List<SpatialBorderGroundReplacement>>;

Set<(int, int)> resolveSpatialBorderGroundMaskCells({
  required ProjectManifest manifest,
  required MapData map,
}) {
  final scene = map.spatialScene;
  if (scene == null) return const {};
  final instances = {
    for (final instance in scene.instances) instance.id: instance,
  };
  final models = {for (final model in manifest.models3d) model.id: model};
  final result = <(int, int)>{};
  for (final layer in map.layers.whereType<BorderLayer>()) {
    if (!layer.isVisible || layer.opacity <= 0) continue;
    for (final feature in layer.content.features) {
      final publication = manifest.borderCatalog
          .recordById(feature.blueprintId)
          ?.latestPublished;
      final applied = feature.materialization;
      final geometry = feature.geometry;
      if (publication?.definition.masksGroundCells != true ||
          applied == null ||
          !applied.targetsSpatialScene ||
          applied.receipt.blueprintRevision != publication!.revision ||
          geometry is! BorderStrokeGeometry ||
          geometry.alignment != BorderStrokeAlignment.cellCenters) {
        continue;
      }
      final primitives = {
        for (final primitive in publication.definition.primitives)
          primitive.id: primitive,
      };
      if (applied.spatialPlacements.any((placement) {
        final instance = instances[placement.instanceId];
        return instance == null ||
            !models.containsKey(instance.modelId) ||
            primitives[placement.primitiveId]?.sourceModelId != instance.modelId;
      })) {
        continue;
      }
      for (final placement in applied.spatialPlacements) {
        final instance = instances[placement.instanceId]!;
        final model = models[instance.modelId]!;
        final anchor = primitives[placement.primitiveId]!.anchorWorld ?? model.pivot;
        final scale = model.scale * instance.scale;
        final angle = instance.rotationDegrees * math.pi / 180;
        final dx = (anchor.x - model.pivot.x) * scale;
        final dz = (anchor.z - model.pivot.z) * scale;
        final x = (instance.position.x + math.cos(angle) * dx + math.sin(angle) * dz).floor();
        final z = (instance.position.z - math.sin(angle) * dx + math.cos(angle) * dz).floor();
        if (x >= 0 && z >= 0 && x < scene.width && z < scene.depth) {
          result.add((x, z));
        }
      }
    }
  }
  return Set.unmodifiable(result);
}

SpatialBorderGroundReplacementIndex indexSpatialBorderGroundReplacements({
  required MapSpatialScene scene,
  required List<SpatialBorderGroundReplacement> replacements,
}) {
  final result = <(int, int), List<SpatialBorderGroundReplacement>>{};
  for (final replacement in replacements) {
    final left = math.max(0, replacement.left.floor());
    final top = math.max(0, replacement.top.floor());
    final right = math.min(scene.width, replacement.right.ceil());
    final bottom = math.min(scene.depth, replacement.bottom.ceil());
    for (var z = top; z < bottom; z++) {
      for (var x = left; x < right; x++) {
        result.putIfAbsent((x, z), () => []).add(replacement);
      }
    }
  }
  return Map.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<SpatialBorderGroundReplacement>.unmodifiable(entry.value),
  });
}

List<SpatialBorderGroundReplacement> resolveSpatialBorderGroundReplacements({
  required ProjectManifest manifest,
  required MapData map,
}) {
  final scene = map.spatialScene;
  if (scene == null) return const [];
  final instances = {
    for (final instance in scene.instances) instance.id: instance,
  };
  final models = {for (final model in manifest.models3d) model.id: model};
  final result = <SpatialBorderGroundReplacement>[];
  for (final layer in map.layers.whereType<BorderLayer>()) {
    if (!layer.isVisible || layer.opacity <= 0) continue;
    for (final feature in layer.content.features) {
      final publication = manifest.borderCatalog
          .recordById(feature.blueprintId)
          ?.latestPublished;
      final applied = feature.materialization;
      if (publication?.definition.replacesGround != true ||
          applied == null ||
          !applied.targetsSpatialScene ||
          applied.receipt.blueprintRevision != publication!.revision ||
          applied.spatialPlacements.any(
            (placement) =>
                !instances.containsKey(placement.instanceId) ||
                !models.containsKey(instances[placement.instanceId]!.modelId),
          )) {
        continue;
      }
      for (final placement in applied.spatialPlacements) {
        final instance = instances[placement.instanceId]!;
        final model = models[instance.modelId]!;
        final bounds = model.inspection.bounds;
        final scale = model.scale * instance.scale;
        final angle = instance.rotationDegrees * math.pi / 180;
        final xs = <double>[], zs = <double>[];
        for (final x in [bounds.min.x, bounds.max.x]) {
          for (final z in [bounds.min.z, bounds.max.z]) {
            final dx = (x - model.pivot.x) * scale;
            final dz = (z - model.pivot.z) * scale;
            xs.add(
              instance.position.x + math.cos(angle) * dx + math.sin(angle) * dz,
            );
            zs.add(
              instance.position.z - math.sin(angle) * dx + math.cos(angle) * dz,
            );
          }
        }
        final left = xs.reduce(math.min), right = xs.reduce(math.max);
        final top = zs.reduce(math.min), bottom = zs.reduce(math.max);
        if (right - left <= .000001 || bottom - top <= .000001) continue;
        result.add((
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          lowerHeight:
              instance.position.y +
              (bounds.min.y +
                      publication.definition.groundBaseOffset -
                      model.pivot.y) *
                  scale,
          upperHeight:
              instance.position.y + (bounds.max.y - model.pivot.y) * scale,
        ));
      }
    }
  }
  return List.unmodifiable(result);
}

BorderDiagnosticsReport diagnoseSpatialBorderFeature({
  required ProjectManifest manifest,
  required MapData map,
  required String layerId,
  required String featureId,
  bool requireMaterialization = false,
}) {
  final resolved = resolveSpatialBorderFeature(
    manifest: manifest,
    map: map,
    layerId: layerId,
    featureId: featureId,
  );
  final feature = map.layers
      .whereType<BorderLayer>()
      .firstWhere((layer) => layer.id == layerId)
      .content
      .featureById(featureId)!;
  final diagnostics = [...resolved.result.diagnostics];
  if (resolved.result.diagnosticReport.hasErrors) {
    return BorderDiagnosticsReport(diagnostics: diagnostics);
  }
  final materialization = feature.materialization;
  if (materialization == null || !materialization.targetsSpatialScene) {
    diagnostics.add(
      BorderDiagnostic(
        code: 'border.materialization.missing',
        severity: requireMaterialization
            ? BorderDiagnosticSeverity.error
            : BorderDiagnosticSeverity.info,
        phase: BorderDiagnosticPhase.materialization,
        scope: BorderDiagnosticScope.feature,
        blueprintId: feature.blueprintId,
        featureId: feature.id,
        suggestedAction: 'border.action.preview_and_apply_materialization',
      ),
    );
  } else if (resolved.result.materialization != materialization ||
      !_sameInstances(
        resolved.modelInstances,
        materialization.spatialPlacements
            .map(
              (placement) => map.spatialScene!.instances.firstWhere(
                (instance) => instance.id == placement.instanceId,
              ),
            )
            .toList(),
      )) {
    diagnostics.add(
      BorderDiagnostic(
        code: 'border.spatial.materialization_stale',
        severity: BorderDiagnosticSeverity.warning,
        phase: BorderDiagnosticPhase.freshness,
        scope: BorderDiagnosticScope.materialization,
        blueprintId: feature.blueprintId,
        featureId: feature.id,
        suggestedAction: 'border.action.regenerate_materialization',
      ),
    );
  }
  return BorderDiagnosticsReport(diagnostics: diagnostics);
}

BorderDiagnosticsReport validateSpatialBorderBlueprint({
  required String blueprintId,
  required BorderBlueprintPublishedDefinition definition,
  required ProjectManifest manifest,
}) {
  final diagnostics = <BorderDiagnostic>[];
  void error(String code, {String? primitiveId}) => diagnostics.add(
    BorderDiagnostic(
      code: code,
      severity: BorderDiagnosticSeverity.error,
      phase: BorderDiagnosticPhase.publication,
      scope: BorderDiagnosticScope.blueprint,
      blueprintId: blueprintId,
      parameters: {'primitiveId': ?primitiveId},
      suggestedAction: 'border.action.configure_native_model_primitives',
    ),
  );
  if (!definition.isSpatial ||
      definition.template != BorderBlueprintTemplate.connectedLine) {
    error('border.spatial.connected_line_required');
  }
  final ids = <String>{};
  final roles = <BorderPrimitiveRole>{};
  for (final primitive in definition.primitives) {
    if (!ids.add(primitive.id)) {
      error('border.spatial.primitive_id_duplicate', primitiveId: primitive.id);
    }
    final model = manifest.models3d
        .where((model) => model.id == primitive.sourceModelId)
        .firstOrNull;
    if (model == null) {
      error('border.spatial.source_model_missing', primitiveId: primitive.id);
    } else if (primitive.animationIndex != null &&
        !model.inspection.animations.any(
          (clip) => clip.index == primitive.animationIndex,
        )) {
      error('border.spatial.animation_missing', primitiveId: primitive.id);
    }
    if (!const {
      BorderPrimitiveRole.lineCap,
      BorderPrimitiveRole.lineStraight,
      BorderPrimitiveRole.lineCorner,
    }.contains(primitive.role)) {
      error('border.spatial.role_unsupported', primitiveId: primitive.id);
    }
    if (primitive.transforms.allowFlipX) {
      error('border.spatial.flip_unsupported', primitiveId: primitive.id);
    }
    roles.add(primitive.role);
  }
  if (!roles.containsAll(const {
        BorderPrimitiveRole.lineCap,
        BorderPrimitiveRole.lineStraight,
      }) ||
      (!definition.straightOnly &&
          !roles.contains(BorderPrimitiveRole.lineCorner))) {
    error('border.spatial.required_roles_missing');
  }
  if (definition.followContourDirection && !definition.straightOnly) {
    final turns = definition.primitives
        .where((primitive) => primitive.role == BorderPrimitiveRole.lineCorner)
        .map((primitive) => primitive.cornerTurn)
        .toSet();
    if (turns.contains(null) || !turns.containsAll(BorderCornerTurn.values)) {
      error('border.spatial.corner_turn_missing');
    }
  }
  return BorderDiagnosticsReport(diagnostics: diagnostics);
}

BorderDiagnosticsReport validateSpatialBorderFeatureGeometry({
  required String blueprintId,
  required String featureId,
  required BorderBlueprintPublishedDefinition definition,
  required BorderFeatureGeometry geometry,
}) {
  final isStraight = switch (geometry) {
    BorderStrokeGeometry() => geometry.strokes.every(
      (stroke) =>
          !stroke.closed &&
          (stroke.points.every((point) => point.x == stroke.points.first.x) ||
              stroke.points.every((point) => point.y == stroke.points.first.y)),
    ),
    BorderRegionGeometry() => !geometry.cells.any((cell) => cell),
  };
  return BorderDiagnosticsReport(
    diagnostics: [
      if (definition.masksGroundCells &&
          (geometry is! BorderStrokeGeometry ||
              geometry.alignment != BorderStrokeAlignment.cellCenters))
        BorderDiagnostic(
          code: 'border.spatial.ground_mask_cell_centers_required',
          severity: BorderDiagnosticSeverity.error,
          phase: BorderDiagnosticPhase.resolution,
          scope: BorderDiagnosticScope.feature,
          blueprintId: blueprintId,
          featureId: featureId,
          suggestedAction: 'border.action.draw_cell_centered_strokes',
        ),
      if (definition.straightOnly && !isStraight)
        BorderDiagnostic(
          code: 'border.spatial.straight_only_geometry_required',
          severity: BorderDiagnosticSeverity.error,
          phase: BorderDiagnosticPhase.resolution,
          scope: BorderDiagnosticScope.feature,
          blueprintId: blueprintId,
          featureId: featureId,
          suggestedAction: 'border.action.draw_straight_strokes',
        ),
    ],
  );
}

SpatialBorderResolutionResult resolveSpatialBorderFeature({
  required ProjectManifest manifest,
  required MapData map,
  required String layerId,
  required String featureId,
  int resolverVersion = borderResolverVersion,
}) {
  final layer = map.layers
      .whereType<BorderLayer>()
      .where((layer) => layer.id == layerId)
      .firstOrNull;
  final feature = layer?.content.featureById(featureId);
  if (feature == null) {
    throw const ValidationException('Spatial Border feature is missing');
  }
  final revision = manifest.borderCatalog
      .recordById(feature.blueprintId)
      ?.latestPublished;
  final diagnostics = <BorderDiagnostic>[];
  void error(
    String code, {
    String? slotKey,
    String suggestedAction = 'border.action.configure_native_model_primitives',
  }) => diagnostics.add(
    BorderDiagnostic(
      code: code,
      severity: BorderDiagnosticSeverity.error,
      phase: BorderDiagnosticPhase.resolution,
      scope: BorderDiagnosticScope.feature,
      blueprintId: feature.blueprintId,
      featureId: featureId,
      slotKey: slotKey,
      suggestedAction: suggestedAction,
    ),
  );
  if (map.version != ProjectVersion.v9 || map.spatialScene == null) {
    error('border.spatial.map_required');
  }
  if (feature.lineSide == BorderLineSide.inverted &&
      (revision == null ||
          !_supportsRepeatedUnitInversion(
            revision.definition,
            feature.geometry,
            manifest,
          ))) {
    error(
      'border.spatial.line_side_inversion_unsupported',
      suggestedAction: 'border.action.use_primary_line_side',
    );
  }
  if (resolverVersion != borderResolverVersion) {
    error('border.spatial.resolver_version_unsupported');
  }
  if (revision == null) {
    error('border.feature.blueprint_unavailable');
  }
  if (revision != null) {
    diagnostics.addAll(
      validateSpatialBorderBlueprint(
        blueprintId: feature.blueprintId,
        definition: revision.definition,
        manifest: manifest,
      ).diagnostics,
    );
  }
  final placements = <BorderSpatialPlacement>[];
  final instances = <SpatialModelInstance>[];
  SpatialBorderResolutionResult failed() => SpatialBorderResolutionResult(
    mapId: map.id,
    layerId: layerId,
    featureId: featureId,
    result: BorderResolutionResult(
      materialization: null,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    ),
    modelInstances: const [],
  );
  if (diagnostics.any(
    (diagnostic) => diagnostic.severity == BorderDiagnosticSeverity.error,
  )) {
    return failed();
  }
  final scene = map.spatialScene!;
  final definition = revision!.definition;
  final params = feature.paramsOverride ?? definition.defaults;
  final geometry = feature.geometry;
  final geometryDiagnostics = validateSpatialBorderFeatureGeometry(
    blueprintId: feature.blueprintId,
    featureId: featureId,
    definition: definition,
    geometry: geometry,
  );
  diagnostics.addAll(geometryDiagnostics.diagnostics);
  if (geometryDiagnostics.hasErrors) return failed();
  final chains =
      <({String lineageNamespace, List<_SpatialBorderNode> nodes})>[];
  final alignment = geometry is BorderStrokeGeometry
      ? geometry.alignment
      : BorderStrokeAlignment.gridEdges;
  if (geometry is BorderStrokeGeometry) {
    for (final stroke in geometry.strokes) {
      final lattice = buildBorderLinearLatticeV1(
        stroke: stroke,
        tileSizePx: const GridSize(width: 1, height: 1),
        preserveTraversal: definition.followContourDirection,
      );
      chains.add((
        lineageNamespace: lattice.lineageNamespace,
        nodes: [
          for (final node in lattice.nodes)
            (
              cell: node.cell,
              kind: node.kind,
              incomingDirection: node.incomingDirection,
              outgoingDirection: node.outgoingDirection,
              terrainCell: definition.followContourDirection
                  ? _strokeLandCell(node, alignment: alignment)
                  : null,
            ),
        ],
      ));
    }
  } else if (geometry is BorderRegionGeometry) {
    if (geometry.width != map.size.width ||
        geometry.height != map.size.height) {
      error('border.spatial.region_size_mismatch');
    }
    for (final contour in extractCanonicalBorderRegionContours(
      region: geometry,
      tileSizePx: const GridSize(width: 1, height: 1),
    )) {
      chains.add((
        lineageNamespace: 'region',
        nodes: [
          for (var index = 0; index < contour.edges.length; index++)
            (
              cell: contour.edges[index].startVertex,
              kind:
                  contour
                          .edges[(index + contour.edges.length - 1) %
                              contour.edges.length]
                          .direction ==
                      contour.edges[index].direction
                  ? BorderLinearNodeKind.straight
                  : BorderLinearNodeKind.corner,
              incomingDirection: contour
                  .edges[(index + contour.edges.length - 1) %
                      contour.edges.length]
                  .direction,
              outgoingDirection: contour.edges[index].direction,
              terrainCell: contour.edges[index].interiorCell,
            ),
        ],
      ));
    }
  }
  for (final keepOut in feature.keepOutRegions) {
    if (keepOut.region.width != map.size.width ||
        keepOut.region.height != map.size.height) {
      error('border.spatial.keep_out_size_mismatch');
    }
  }
  final allOwned = <String>{};
  final instanceIds = scene.instances.map((instance) => instance.id).toSet();
  for (final candidateLayer in map.layers) {
    final owned = switch (candidateLayer) {
      BorderLayer() => candidateLayer.content.features.expand(
        (candidate) => candidate.generatedPlacementIds,
      ),
      EnvironmentLayer() => candidateLayer.content.areas.expand(
        (area) => area.generatedPlacementIds,
      ),
      _ => const <String>[],
    };
    for (final id in owned) {
      if (!instanceIds.contains(id) || !allOwned.add(id)) {
        error('border.spatial.ownership_invalid');
      }
    }
  }
  final slots = <String>{};
  for (final chain in chains) {
    for (final node in chain.nodes) {
      final role = switch (node.kind) {
        BorderLinearNodeKind.endpoint => BorderPrimitiveRole.lineCap,
        BorderLinearNodeKind.straight => BorderPrimitiveRole.lineStraight,
        BorderLinearNodeKind.corner => BorderPrimitiveRole.lineCorner,
      };
      final lineage = geometry is BorderRegionGeometry
          ? [
              'region',
              node.incomingDirection?.name,
              node.outgoingDirection?.name,
            ]
          : [chain.lineageNamespace];
      final slotKey =
          'border3d-slot:${_hash([layerId, featureId, ...lineage, node.cell.x, node.cell.y]).substring(7)}';
      if (!slots.add(slotKey)) {
        error('border.spatial.slot_identity_conflict', slotKey: slotKey);
        continue;
      }
      final override = feature.overrides
          .where((override) => override.slotKey == slotKey)
          .firstOrNull;
      if (override?.suppressed == true) continue;
      if (override?.lockedPlacement != null ||
          override?.offsetDeltaPx != null ||
          override?.transformOverride?.flipX == true) {
        error('border.spatial.sprite_override_unsupported', slotKey: slotKey);
        continue;
      }
      final targetTurns =
          (_nodeTurns(node, role, directed: definition.followContourDirection) +
              (feature.lineSide == BorderLineSide.inverted ? 2 : 0)) %
          4;
      final candidates = <({BorderPublishedPrimitive primitive, int turns})>[];
      final cornerTurn = role == BorderPrimitiveRole.lineCorner
          ? (borderCardinalDirectionV1Rank(node.outgoingDirection!) -
                            borderCardinalDirectionV1Rank(
                              node.incomingDirection!,
                            ) +
                            4) %
                        4 ==
                    1
                ? BorderCornerTurn.right
                : BorderCornerTurn.left
          : null;
      for (final primitive in definition.primitives.where(
        (primitive) =>
            primitive.role == role &&
            (!definition.followContourDirection ||
                role != BorderPrimitiveRole.lineCorner ||
                primitive.cornerTurn == cornerTurn),
      )) {
        if (override?.replacementPrimitiveId != null &&
            primitive.id != override!.replacementPrimitiveId) {
          continue;
        }
        final authoredTurns = switch (primitive.authoredOrientation) {
          BorderPrimitiveOrientation.legacyAxis ||
          BorderPrimitiveOrientation.east => 0,
          BorderPrimitiveOrientation.south => 1,
          BorderPrimitiveOrientation.west => 2,
          BorderPrimitiveOrientation.north => 3,
        };
        final turns =
            override?.transformOverride?.quarterTurns ??
            (targetTurns - authoredTurns + 4) % 4;
        if ((!params.allowAutoRotation && turns != 0) ||
            !primitive.transforms.allowedQuarterTurns.contains(turns)) {
          continue;
        }
        candidates.add((primitive: primitive, turns: turns));
      }
      candidates.sort(
        (left, right) => left.primitive.id.compareTo(right.primitive.id),
      );
      if (candidates.isEmpty) {
        error('border.spatial.orientation_missing', slotKey: slotKey);
        continue;
      }
      final total = candidates.fold(
        0,
        (sum, candidate) => sum + candidate.primitive.weight,
      );
      var selected = candidates.first;
      final variationKey = [
        feature.seed.toString(),
        slotKey,
        override?.variationSalt.toString() ?? '0',
      ];
      final varies =
          params.variationPermille > 0 &&
          BigInt.parse(
                    _hash([...variationKey, 'gate']).substring(7),
                    radix: 16,
                  ) %
                  BigInt.from(1000) <
              BigInt.from(params.variationPermille);
      if (varies) {
        var choice =
            BigInt.parse(
              _hash([...variationKey, 'choice']).substring(7),
              radix: 16,
            ) %
            BigInt.from(total);
        for (final candidate in candidates) {
          if (choice < BigInt.from(candidate.primitive.weight)) {
            selected = candidate;
            break;
          }
          choice -= BigInt.from(candidate.primitive.weight);
        }
      }
      final primitive = selected.primitive;
      final model = manifest.models3d.firstWhere(
        (model) => model.id == primitive.sourceModelId,
      );
      if (!manifest.resourceLibraryCatalog.availableForMap(
            'model3d',
            model.id,
            map.id,
          ) ||
          !manifest.resourceLibraryCatalog.availableForMap(
            'borderBlueprint',
            feature.blueprintId,
            map.id,
          )) {
        error('border.spatial.resource_scope_conflict', slotKey: slotKey);
        continue;
      }
      final id =
          'border3d_${_hash([map.id, layerId, featureId, slotKey]).substring(7, 39)}';
      final angle = -selected.turns * math.pi / 2;
      final anchor = primitive.anchorWorld ?? model.pivot;
      final dx = (anchor.x - model.pivot.x) * model.scale;
      final dz = (anchor.z - model.pivot.z) * model.scale;
      final offset = alignment == BorderStrokeAlignment.cellCenters ? .5 : 0.0;
      final spatialOffset = feature.spatialOffsetWorld ?? Model3dVector3.zero;
      final terrainCell = definition.followContourDirection
          ? node.terrainCell
          : null;
      final x =
          node.cell.x +
          offset -
          math.cos(angle) * dx -
          math.sin(angle) * dz +
          spatialOffset.x;
      final z =
          node.cell.y +
          offset +
          math.sin(angle) * dx -
          math.cos(angle) * dz +
          spatialOffset.z;
      var instance = SpatialModelInstance(
        id: id,
        modelId: model.id,
        position: Model3dVector3(
          x: x,
          y:
              scene.worldHeightAt(
                terrainCell == null ? node.cell.x + offset : terrainCell.x + .5,
                terrainCell == null ? node.cell.y + offset : terrainCell.y + .5,
              ) -
              (anchor.y - model.pivot.y) * model.scale +
              spatialOffset.y,
          z: z,
        ),
        rotationDegrees: -selected.turns * 90.0,
        animationIndex: primitive.animationIndex,
        animationLoop: primitive.animationLoop,
        animationSpeed: primitive.animationSpeed,
        blocksMovement: primitive.blocksMovement,
      );
      if (override?.lockedInstanceId != null) {
        final locked = scene.instances
            .where((instance) => instance.id == override!.lockedInstanceId)
            .firstOrNull;
        final ownedSlot = feature.materialization?.spatialPlacements
            .where(
              (placement) =>
                  placement.slotKey == slotKey &&
                  placement.instanceId == override!.lockedInstanceId,
            )
            .firstOrNull;
        if (locked == null || ownedSlot == null || locked.modelId != model.id) {
          error('border.spatial.locked_instance_invalid', slotKey: slotKey);
          continue;
        }
        instance = locked;
      }
      if (instance.position.x < 0 ||
          instance.position.z < 0 ||
          instance.position.x >= scene.width ||
          instance.position.z >= scene.depth) {
        error('border.spatial.anchor_outside_map', slotKey: slotKey);
        continue;
      }
      if (_intersectsKeepOut(instance, model, feature.keepOutRegions)) continue;
      if (instanceIds.contains(instance.id) &&
          !feature.generatedPlacementIds.contains(instance.id)) {
        error('border.spatial.instance_identity_conflict', slotKey: slotKey);
        continue;
      }
      placements.add(
        BorderSpatialPlacement(
          slotKey: slotKey,
          primitiveId: primitive.id,
          instanceId: instance.id,
        ),
      );
      instances.add(instance);
    }
  }
  for (final override in feature.overrides) {
    if (!slots.contains(override.slotKey)) {
      error('border.spatial.override_slot_missing', slotKey: override.slotKey);
    }
  }
  if (diagnostics.any(
    (diagnostic) => diagnostic.severity == BorderDiagnosticSeverity.error,
  )) {
    return failed();
  }
  if (scene.instances.length -
          feature.generatedPlacementIds.length +
          instances.length >
      10000) {
    error('border.spatial.instance_limit');
    return failed();
  }
  final featureJson = encodeBorderFeatureJson(feature, formatVersion: 4)
    ..remove('materialization');
  final relevantModels =
      manifest.models3d
          .where(
            (model) => definition.primitives.any(
              (primitive) => primitive.sourceModelId == model.id,
            ),
          )
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  final context = {
    'mapId': map.id,
    'mapVersion': map.version.name,
    'mapSize': map.size.toJson(),
    'width': scene.width,
    'depth': scene.depth,
    'heightLevels': scene.heightLevels,
    'levelHeight': scene.levelHeight,
    'ramps': scene.navigation.ramps.map((ramp) => ramp.toJson()).toList(),
    'tileWidth': manifest.settings.tileWidth,
    'tileHeight': manifest.settings.tileHeight,
  };
  final components = BorderInputFingerprints(
    blueprint: _hash(
      encodeBorderBlueprintRevisionJson(revision, formatVersion: 6),
    ),
    geometryAndSeed: _hash({
      'geometry': featureJson['geometry'],
      'seed': feature.seed.toString(),
    }),
    parameters: _hash({
      'defaults': encodeBorderGenerationParamsJson(params, formatVersion: 5),
      'lineSide': feature.lineSide.name,
      'spatialOffsetWorld': feature.spatialOffsetWorld?.toJson(),
    }),
    overrides: _hash({
      'overrides': featureJson['overrides'],
      'lockedInstances': [
        for (final instance in scene.instances)
          if (feature.overrides.any(
            (override) => override.lockedInstanceId == instance.id,
          ))
            instance.toJson(),
      ],
    }),
    keepOutRegions: _hash(featureJson['keepOutRegions']),
    mapContext: _hash(context),
    visualSnapshots: _hash({
      'models': relevantModels.map((model) => model.toJson()).toList(),
    }),
  );
  final materialization = BorderMaterialization(
    receipt: BorderResolutionReceipt(
      resolverVersion: resolverVersion,
      blueprintRevision: revision.revision,
      components: components,
      inputFingerprint: computeBorderAggregateInputFingerprint(
        resolverVersion: resolverVersion,
        blueprintRevision: revision.revision,
        components: components,
      ),
      outputFingerprint: _hash({
        'placements': [
          for (final placement in placements)
            {
              'slotKey': placement.slotKey,
              'primitiveId': placement.primitiveId,
              'instanceId': placement.instanceId,
            },
        ],
        'instances': instances.map((instance) => instance.toJson()).toList(),
      }),
    ),
    ground: const [],
    placements: const [],
    targetsSpatialScene: true,
    spatialPlacements: placements,
  );
  return SpatialBorderResolutionResult(
    mapId: map.id,
    layerId: layerId,
    featureId: featureId,
    result: BorderResolutionResult(
      materialization: materialization,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    ),
    modelInstances: instances,
  );
}

GridPos _strokeLandCell(
  BorderLinearNodeNeed node, {
  required BorderStrokeAlignment alignment,
}) {
  if (alignment == BorderStrokeAlignment.cellCenters) {
    (int, int) rightSide(BorderCardinalDirection direction) =>
        switch (direction) {
          BorderCardinalDirection.east => (0, 1),
          BorderCardinalDirection.south => (-1, 0),
          BorderCardinalDirection.west => (0, -1),
          BorderCardinalDirection.north => (1, 0),
        };
    final (dx, dz) = rightSide(
      node.outgoingDirection ?? node.incomingDirection!,
    );
    final (incomingX, incomingZ) = node.kind == BorderLinearNodeKind.corner
        ? rightSide(node.incomingDirection!)
        : (0, 0);
    return GridPos(
      x: node.cell.x + dx + incomingX,
      y: node.cell.y + dz + incomingZ,
    );
  }
  final direction = node.outgoingDirection ?? node.incomingDirection!;
  final isEnd = node.outgoingDirection == null;
  final (dx, dz) = switch (direction) {
    BorderCardinalDirection.east => (isEnd ? -1 : 0, 0),
    BorderCardinalDirection.south => (-1, isEnd ? -1 : 0),
    BorderCardinalDirection.west => (isEnd ? 0 : -1, -1),
    BorderCardinalDirection.north => (0, isEnd ? 0 : -1),
  };
  return GridPos(x: node.cell.x + dx, y: node.cell.y + dz);
}

MapData applySpatialBorderFeaturePreview(
  MapData map, {
  required ProjectManifest manifest,
  required SpatialBorderResolutionResult proposedResult,
}) {
  if (map.id != proposedResult.mapId || !proposedResult.result.canApply) {
    return map;
  }
  final canonical = resolveSpatialBorderFeature(
    manifest: manifest,
    map: map,
    layerId: proposedResult.layerId,
    featureId: proposedResult.featureId,
    resolverVersion:
        proposedResult.result.materialization!.receipt.resolverVersion,
  );
  if (canonical.result != proposedResult.result ||
      !_sameInstances(
        canonical.modelInstances,
        proposedResult.modelInstances,
      )) {
    throw const ValidationException(
      'Spatial Border preview is stale or noncanonical',
    );
  }
  final layer = map.layers.whereType<BorderLayer>().firstWhere(
    (layer) => layer.id == proposedResult.layerId,
  );
  final feature = layer.content.featureById(proposedResult.featureId)!;
  final scene = map.spatialScene!;
  final replacement = BorderFeature(
    id: feature.id,
    name: feature.name,
    blueprintId: feature.blueprintId,
    seed: feature.seed,
    geometry: feature.geometry,
    lineSide: feature.lineSide,
    spatialOffsetWorld: feature.spatialOffsetWorld,
    paramsOverride: feature.paramsOverride,
    overrides: feature.overrides,
    keepOutRegions: feature.keepOutRegions,
    materialization: canonical.result.materialization,
  );
  return upsertBorderFeature(
    map.copyWith(
      spatialScene: scene.copyWith(
        instances: [
          ...scene.instances.where(
            (instance) => !feature.generatedPlacementIds.contains(instance.id),
          ),
          ...canonical.modelInstances,
        ],
      ),
    ),
    layerId: layer.id,
    feature: replacement,
  );
}

String _hash(Object? value) => 'sha256:${narrativeEventCanonicalSha256(value)}';

bool _sameInstances(
  List<SpatialModelInstance> a,
  List<SpatialModelInstance> b,
) =>
    a.length == b.length &&
    Iterable<int>.generate(a.length).every((index) => a[index] == b[index]);

bool _supportsRepeatedUnitInversion(
  BorderBlueprintPublishedDefinition definition,
  BorderFeatureGeometry geometry,
  ProjectManifest manifest,
) {
  if (definition.template != BorderBlueprintTemplate.connectedLine ||
      !definition.straightOnly ||
      geometry is! BorderStrokeGeometry ||
      geometry.strokes.isEmpty ||
      !geometry.strokes.every(
        (stroke) =>
            !stroke.closed &&
            (stroke.points.every((point) => point.x == stroke.points.first.x) ||
                stroke.points.every(
                  (point) => point.y == stroke.points.first.y,
                )),
      )) {
    return false;
  }
  final primitives = definition.primitives;
  final caps = primitives
      .where((primitive) => primitive.role == BorderPrimitiveRole.lineCap)
      .toList();
  if (primitives.length != 3 ||
      caps.length != 2 ||
      primitives
              .where(
                (primitive) =>
                    primitive.role == BorderPrimitiveRole.lineStraight,
              )
              .length !=
          1) {
    return false;
  }
  final model = manifest.models3d
      .where((model) => model.id == primitives.first.sourceModelId)
      .firstOrNull;
  if (model == null) return false;
  final anchor = primitives.first.anchorWorld ?? model.pivot;
  if (primitives.any(
    (primitive) =>
        primitive.sourceModelId != model.id ||
        (primitive.anchorWorld ?? model.pivot) != anchor ||
        primitive.transforms.allowFlipX,
  )) {
    return false;
  }
  int orientation(BorderPrimitiveOrientation value) => switch (value) {
    BorderPrimitiveOrientation.legacyAxis ||
    BorderPrimitiveOrientation.east => 0,
    BorderPrimitiveOrientation.south => 1,
    BorderPrimitiveOrientation.west => 2,
    BorderPrimitiveOrientation.north => 3,
  };
  return (orientation(caps.first.authoredOrientation) -
              orientation(caps.last.authoredOrientation) +
              4) %
          4 ==
      2;
}

int _nodeTurns(
  _SpatialBorderNode node,
  BorderPrimitiveRole role, {
  bool directed = false,
}) {
  if (directed) {
    return borderCardinalDirectionV1Rank(
      role == BorderPrimitiveRole.lineCorner
          ? node.incomingDirection!
          : node.outgoingDirection ?? node.incomingDirection!,
    );
  }
  BorderCardinalDirection opposite(BorderCardinalDirection direction) =>
      switch (direction) {
        BorderCardinalDirection.east => BorderCardinalDirection.west,
        BorderCardinalDirection.south => BorderCardinalDirection.north,
        BorderCardinalDirection.west => BorderCardinalDirection.east,
        BorderCardinalDirection.north => BorderCardinalDirection.south,
      };
  final connections = {
    if (node.incomingDirection != null) opposite(node.incomingDirection!),
    if (node.outgoingDirection != null) node.outgoingDirection!,
  };
  if (role == BorderPrimitiveRole.lineCap) {
    return borderCardinalDirectionV1Rank(connections.single);
  }
  if (role == BorderPrimitiveRole.lineStraight) {
    return connections.contains(BorderCardinalDirection.east) ? 0 : 1;
  }
  if (connections.contains(BorderCardinalDirection.west)) {
    return connections.contains(BorderCardinalDirection.south) ? 0 : 1;
  }
  return connections.contains(BorderCardinalDirection.north) ? 2 : 3;
}

bool _intersectsKeepOut(
  SpatialModelInstance instance,
  ProjectModel3dEntry model,
  List<BorderKeepOutRegion> keepOuts,
) {
  if (keepOuts.isEmpty) return false;
  final bounds = model.collisionBounds ?? model.inspection.bounds;
  final angle = instance.rotationDegrees * math.pi / 180;
  final cos = math.cos(angle),
      sin = math.sin(angle),
      scale = model.scale * instance.scale;
  final corners = [
    for (final point in [
      (bounds.min.x, bounds.min.z),
      (bounds.max.x, bounds.min.z),
      (bounds.max.x, bounds.max.z),
      (bounds.min.x, bounds.max.z),
    ])
      (
        x:
            instance.position.x +
            cos * (point.$1 - model.pivot.x) * scale +
            sin * (point.$2 - model.pivot.z) * scale,
        z:
            instance.position.z -
            sin * (point.$1 - model.pivot.x) * scale +
            cos * (point.$2 - model.pivot.z) * scale,
      ),
  ];
  final minX = corners.map((point) => point.x).reduce(math.min),
      maxX = corners.map((point) => point.x).reduce(math.max);
  final minZ = corners.map((point) => point.z).reduce(math.min),
      maxZ = corners.map((point) => point.z).reduce(math.max);
  for (final keepOut in keepOuts) {
    for (
      var z = minZ.floor().clamp(0, keepOut.region.height - 1);
      z < maxZ.ceil().clamp(0, keepOut.region.height);
      z++
    ) {
      for (
        var x = minX.floor().clamp(0, keepOut.region.width - 1);
        x < maxX.ceil().clamp(0, keepOut.region.width);
        x++
      ) {
        if (keepOut.region.cells[z * keepOut.region.width + x]) return true;
      }
    }
  }
  return false;
}
