import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_ground_footprint.dart';
import '../models/border_ground_surface.dart';
import '../models/smart_tile.dart';
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
import 'border_feature_update_operations.dart';
import 'border_fingerprints.dart';
import 'border_layer_operations.dart';
import 'border_linear_lattice.dart';
import 'border_region_contours.dart';
import 'border_resolver.dart';
import 'narrative_event_canonical_json.dart';
import 'spatial_border_resolution_context.dart';

final class SpatialBorderResolutionResult {
  SpatialBorderResolutionResult({
    required this.mapId,
    required this.layerId,
    required this.featureId,
    required this.result,
    required List<SpatialModelInstance> modelInstances,
    this.sourceContext,
  }) : modelInstances = List.unmodifiable(modelInstances);
  final String mapId, layerId, featureId;
  final BorderResolutionResult result;
  final List<SpatialModelInstance> modelInstances;
  final SpatialBorderResolutionContext? sourceContext;
}

typedef _SpatialBorderNode = ({
  int index,
  GridPos cell,
  BorderLinearNodeKind kind,
  BorderCardinalDirection? incomingDirection,
  BorderCardinalDirection? outgoingDirection,
  GridPos? terrainCell,
});

typedef _SpatialFaceProbe = ({
  String slotKey,
  GridPos cell,
  GridPos landCell,
  GridPos outsideCell,
  SpatialModelInstance instance,
  ProjectModel3dEntry model,
  Model3dVector3 anchor,
});

final class SpatialBorderGroundReplacement {
  const SpatialBorderGroundReplacement({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.lowerHeight,
    required this.upperHeight,
    this.footprints = const [],
  });

  final double left, top, right, bottom, lowerHeight, upperHeight;
  final List<BorderGroundFootprint> footprints;

  bool contains(double x, double z) {
    if (x <= left || x >= right || z <= top || z >= bottom) return false;
    if (footprints.isEmpty) return true;
    return footprints.any((footprint) => footprint.contains(x, z));
  }

  @override
  bool operator ==(Object other) =>
      other is SpatialBorderGroundReplacement &&
      left == other.left &&
      top == other.top &&
      right == other.right &&
      bottom == other.bottom &&
      lowerHeight == other.lowerHeight &&
      upperHeight == other.upperHeight &&
      footprints.length == other.footprints.length &&
      Iterable<int>.generate(
        footprints.length,
      ).every((index) => footprints[index] == other.footprints[index]);

  @override
  int get hashCode => Object.hash(
    left,
    top,
    right,
    bottom,
    lowerHeight,
    upperHeight,
    Object.hashAll(footprints),
  );
}

typedef SpatialBorderGroundReplacementIndex =
    Map<(int, int), List<SpatialBorderGroundReplacement>>;

Set<(int, int)> resolveSpatialBorderGroundMaskCells({
  required ProjectManifest manifest,
  required MapData map,
  bool Function(String layerId)? includeLayer,
}) => Set.unmodifiable({
  for (final cells in resolveSpatialBorderGroundMaskCellsByLayer(
    manifest: manifest,
    map: map,
    includeLayer: includeLayer,
  ).values)
    ...cells,
});

Map<String, Set<(int, int)>> resolveSpatialBorderGroundMaskCellsByLayer({
  required ProjectManifest manifest,
  required MapData map,
  bool Function(String layerId)? includeLayer,
}) => resolveSpatialBorderGroundMaskCellsByLayerInContext(
  manifest: manifest,
  context: SpatialBorderResolutionContext.fromMap(map),
  includeLayer: includeLayer,
);


Map<String, Set<(int, int)>> resolveSpatialBorderGroundMaskCellsByLayerInContext({
  required ProjectManifest manifest,
  required SpatialBorderResolutionContext context,
  bool Function(String layerId)? includeLayer,
  bool Function(String instanceId)? includeInstance,
}) {
  if (!context.isSpatial) return const {};
  final instances = {
    for (final instance in context.instances) instance.id: instance,
  };
  final models = {for (final model in manifest.models3d) model.id: model};
  final result = <String, Set<(int, int)>>{};
  for (final layer in context.layers.whereType<BorderLayer>()) {
    if (!layer.isVisible ||
        layer.opacity <= 0 ||
        includeLayer?.call(layer.id) == false) {
      continue;
    }
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
            primitives[placement.primitiveId]?.sourceModelId !=
                instance.modelId;
      })) {
        continue;
      }
      for (final placement in applied.spatialPlacements) {
        if (includeInstance?.call(placement.instanceId) == false) continue;
        final instance = instances[placement.instanceId]!;
        final model = models[instance.modelId]!;
        final anchor =
            primitives[placement.primitiveId]!.anchorWorld ?? model.pivot;
        final scale = model.scale * instance.scale;
        final angle = instance.rotationDegrees * math.pi / 180;
        final dx = (anchor.x - model.pivot.x) * scale;
        final dz = (anchor.z - model.pivot.z) * scale;
        final x =
            (instance.position.x + math.cos(angle) * dx + math.sin(angle) * dz)
                .floor();
        final z =
            (instance.position.z - math.sin(angle) * dx + math.cos(angle) * dz)
                .floor();
        if (x >= 0 && z >= 0 && x < context.size.width && z < context.size.height) {
          result.putIfAbsent(layer.id, () => {}).add((x, z));
        }
      }
    }
  }
  return Map.unmodifiable({
    for (final entry in result.entries)
      entry.key: Set<(int, int)>.unmodifiable(entry.value),
  });
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
  bool Function(String layerId)? includeLayer,
}) => List.unmodifiable(
  resolveSpatialBorderGroundReplacementsByLayer(
    manifest: manifest,
    map: map,
    includeLayer: includeLayer,
  ).values.expand((entries) => entries),
);

Map<String, List<SpatialBorderGroundReplacement>>
resolveSpatialBorderGroundReplacementsByLayer({
  required ProjectManifest manifest,
  required MapData map,
  bool Function(String layerId)? includeLayer,
}) => resolveSpatialBorderGroundReplacementsByLayerInContext(
  manifest: manifest,
  context: SpatialBorderResolutionContext.fromMap(map),
  includeLayer: includeLayer,
);


Map<String, List<SpatialBorderGroundReplacement>>
resolveSpatialBorderGroundReplacementsByLayerInContext({
  required ProjectManifest manifest,
  required SpatialBorderResolutionContext context,
  bool Function(String layerId)? includeLayer,
  bool Function(String instanceId)? includeInstance,
}) {
  if (!context.isSpatial) return const {};
  final instances = {
    for (final instance in context.instances) instance.id: instance,
  };
  final models = {for (final model in manifest.models3d) model.id: model};
  final result = <String, List<SpatialBorderGroundReplacement>>{};
  for (final layer in context.layers.whereType<BorderLayer>()) {
    if (!layer.isVisible ||
        layer.opacity <= 0 ||
        includeLayer?.call(layer.id) == false) {
      continue;
    }
    for (final feature in layer.content.features) {
      final publication = manifest.borderCatalog
          .recordById(feature.blueprintId)
          ?.latestPublished;
      final applied = feature.materialization;
      final primitives = {
        for (final primitive
            in publication?.definition.primitives ??
                <BorderPublishedPrimitive>[])
          primitive.id: primitive,
      };
      if (publication?.definition.replacesGround != true ||
          applied == null ||
          !applied.targetsSpatialScene ||
          applied.receipt.blueprintRevision != publication!.revision ||
          applied.spatialPlacements.any(
            (placement) =>
                !instances.containsKey(placement.instanceId) ||
                !models.containsKey(instances[placement.instanceId]!.modelId) ||
                primitives[placement.primitiveId]?.sourceModelId !=
                    instances[placement.instanceId]!.modelId,
          )) {
        continue;
      }
      for (final placement in applied.spatialPlacements) {
        if (includeInstance?.call(placement.instanceId) == false) continue;
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
        final footprints = [
          for (final footprint
              in primitives[placement.primitiveId]!.groundFootprints)
            BorderGroundFootprint(
              points: [
                for (final point in footprint.points)
                  BorderGroundPoint(
                    x:
                        instance.position.x +
                        math.cos(angle) * (point.x - model.pivot.x) * scale +
                        math.sin(angle) * (point.z - model.pivot.z) * scale,
                    z:
                        instance.position.z -
                        math.sin(angle) * (point.x - model.pivot.x) * scale +
                        math.cos(angle) * (point.z - model.pivot.z) * scale,
                  ),
              ],
            ),
        ];
        result
            .putIfAbsent(layer.id, () => [])
            .add(
              SpatialBorderGroundReplacement(
                left: left,
                top: top,
                right: right,
                bottom: bottom,
                footprints: List.unmodifiable(footprints),
                lowerHeight:
                    instance.position.y +
                    (bounds.min.y +
                            publication.definition.groundBaseOffset -
                            model.pivot.y) *
                        scale,
                upperHeight:
                    instance.position.y +
                    (bounds.max.y - model.pivot.y) * scale,
              ),
            );
      }
    }
  }
  return Map.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<SpatialBorderGroundReplacement>.unmodifiable(entry.value),
  });
}

final class SpatialBorderGroundSurface {
  SpatialBorderGroundSurface({
    required this.layerId,
    required this.sourceSmartTilePresetId,
    required this.materialId,
    required this.height,
    required this.opacity,
    this.gradientX = 0,
    this.gradientZ = 0,
    required List<BorderGroundFootprint> footprints,
  }) : footprints = List.unmodifiable(footprints);

  final String layerId;
  final String sourceSmartTilePresetId;
  final String materialId;
  final double height;
  final double opacity;
  final double gradientX;
  final double gradientZ;
  final List<BorderGroundFootprint> footprints;

  double heightAt(double x, double z) => height + gradientX * x + gradientZ * z;
}

List<SpatialBorderGroundSurface> resolveSpatialBorderGroundSurfaces({
  required ProjectManifest manifest,
  required MapData map,
  bool Function(String layerId)? includeLayer,
}) => resolveSpatialBorderGroundSurfacesInContext(
  manifest: manifest,
  context: SpatialBorderResolutionContext.fromMap(map),
  includeLayer: includeLayer,
);


List<SpatialBorderGroundSurface> resolveSpatialBorderGroundSurfacesInContext({
  required ProjectManifest manifest,
  required SpatialBorderResolutionContext context,
  bool Function(String layerId)? includeLayer,
  bool Function(String instanceId)? includeInstance,
}) {
  if (!context.isSpatial) return const [];
  final instances = {
    for (final instance in context.instances) instance.id: instance,
  };
  final models = {for (final model in manifest.models3d) model.id: model};
  final result = <SpatialBorderGroundSurface>[];
  final ordered = context.paintsFirstLayerInFront
      ? context.layers.reversed
      : context.layers;
  for (final layer in ordered.whereType<BorderLayer>()) {
    if (!layer.isVisible ||
        layer.opacity <= 0 ||
        includeLayer?.call(layer.id) == false) {
      continue;
    }
    for (final feature in layer.content.features) {
      final published = manifest.borderCatalog
          .recordById(feature.blueprintId)
          ?.latestPublished;
      final applied = feature.materialization;
      if (published == null ||
          applied == null ||
          !applied.targetsSpatialScene ||
          applied.receipt.blueprintRevision != published.revision) {
        continue;
      }
      final primitives = {
        for (final primitive in published.definition.primitives)
          primitive.id: primitive,
      };
      if (applied.spatialPlacements.any(
        (placement) =>
            !instances.containsKey(placement.instanceId) ||
            !models.containsKey(instances[placement.instanceId]!.modelId) ||
            primitives[placement.primitiveId]?.sourceModelId !=
                instances[placement.instanceId]!.modelId,
      )) {
        continue;
      }
      for (final placement in applied.spatialPlacements) {
        if (includeInstance?.call(placement.instanceId) == false) continue;
        final instance = instances[placement.instanceId]!;
        final model = models[instance.modelId]!;
        final scale = model.scale * instance.scale;
        final angle = instance.rotationDegrees * math.pi / 180;
        for (final surface
            in primitives[placement.primitiveId]!.groundSurfaces) {
          final gradientX =
              surface.gradientX * math.cos(angle) +
              surface.gradientZ * math.sin(angle);
          final gradientZ =
              -surface.gradientX * math.sin(angle) +
              surface.gradientZ * math.cos(angle);
          result.add(
            SpatialBorderGroundSurface(
              layerId: layer.id,
              sourceSmartTilePresetId: surface.sourceSmartTilePresetId,
              materialId: surface.materialId,
              height:
                  instance.position.y +
                  (surface.height +
                          surface.gradientX * model.pivot.x +
                          surface.gradientZ * model.pivot.z -
                          model.pivot.y) *
                      scale -
                  gradientX * instance.position.x -
                  gradientZ * instance.position.z,
              gradientX: gradientX,
              gradientZ: gradientZ,
              opacity: layer.opacity,
              footprints: [
                for (final footprint in surface.footprints)
                  BorderGroundFootprint(
                    points: [
                      for (final point in footprint.points)
                        BorderGroundPoint(
                          x:
                              instance.position.x +
                              math.cos(angle) *
                                  (point.x - model.pivot.x) *
                                  scale +
                              math.sin(angle) *
                                  (point.z - model.pivot.z) *
                                  scale,
                          z:
                              instance.position.z -
                              math.sin(angle) *
                                  (point.x - model.pivot.x) *
                                  scale +
                              math.cos(angle) *
                                  (point.z - model.pivot.z) *
                                  scale,
                        ),
                    ],
                  ),
              ],
            ),
          );
        }
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

List<String> validateBorderGroundSurfaceSources({
  required BorderGroundSurface surface,
  required ProjectManifest manifest,
}) {
  final errors = <String>[];
  final preset = manifest.smartTileCatalog.presets
      .where((preset) => preset.id == surface.sourceSmartTilePresetId)
      .firstOrNull;
  final material = manifest.smartTileCatalog.materials
      .where((material) => material.id == surface.materialId)
      .firstOrNull;
  if (preset == null || preset.usage != SmartTileUsage.terrain) {
    errors.add('border.spatial.ground_surface_preset_invalid');
  } else {
    if (!preset.allowedMaterialIds.contains(surface.materialId)) {
      errors.add('border.spatial.ground_surface_material_not_allowed');
    }
    if (preset.topology != SmartTileTopology.uniform ||
        preset.rules.isEmpty ||
        preset.rules.any(
          (rule) => rule.candidates.any(
            (candidate) => candidate.parts.any(
              (part) =>
                  part.source is SmartTileModel3dSource ||
                  part.channel != SmartTileRenderChannel.ground ||
                  part.footprintWidth != 1 ||
                  part.footprintHeight != 1 ||
                  part.offsetX != 0 ||
                  part.offsetY != 0 ||
                  part.anchorX != 0 ||
                  part.anchorY != 0 ||
                  part.spatialHeightOffset != 0 ||
                  !part.spatialFollowTerrain ||
                  part.spatialClip != null,
            ),
          ),
        )) {
      errors.add('border.spatial.ground_surface_raster_terrain_required');
    }
  }
  if (material == null || material.isEmpty) {
    errors.add('border.spatial.ground_surface_material_missing');
  }
  return errors;
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
    if (model != null &&
        primitive.groundFootprints.any(
          (footprint) => footprint.points.any(
            (point) =>
                point.x < model.inspection.bounds.min.x - 1e-6 ||
                point.x > model.inspection.bounds.max.x + 1e-6 ||
                point.z < model.inspection.bounds.min.z - 1e-6 ||
                point.z > model.inspection.bounds.max.z + 1e-6,
          ),
        )) {
      error(
        'border.spatial.ground_footprint_outside_model',
        primitiveId: primitive.id,
      );
    }
    for (final surface in primitive.groundSurfaces) {
      for (final code in validateBorderGroundSurfaceSources(
        surface: surface,
        manifest: manifest,
      )) {
        error(code, primitiveId: primitive.id);
      }
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
  if (definition.sequenceLength > 1) {
    final phases = definition.primitives.map((p) => p.sequenceIndex).toSet();
    if (phases.length != definition.sequenceLength) {
      error('border.spatial.sequence_phase_missing');
    }
    for (final phase in phases) {
      if (!definition.straightOnly &&
          !definition.primitives.any(
            (primitive) =>
                primitive.sequenceIndex == phase &&
                primitive.role == BorderPrimitiveRole.lineCorner,
          )) {
        error('border.spatial.sequence_corner_missing');
      }
      for (final role in [
        BorderPrimitiveRole.lineStraight,
        BorderPrimitiveRole.lineCap,
        if (!definition.straightOnly) BorderPrimitiveRole.lineCorner,
      ]) {
        final requiredTurns =
            role == BorderPrimitiveRole.lineStraight &&
                !definition.followContourDirection
            ? [0, 1]
            : [0, 1, 2, 3];
        final cornerTurns =
            role == BorderPrimitiveRole.lineCorner &&
                definition.followContourDirection
            ? BorderCornerTurn.values.cast<BorderCornerTurn?>()
            : <BorderCornerTurn?>[null];
        for (final cornerTurn in cornerTurns) {
          for (final target in requiredTurns) {
            final covered = definition.primitives.any((primitive) {
              if (primitive.sequenceIndex != phase ||
                  primitive.role != role ||
                  cornerTurn != null && primitive.cornerTurn != cornerTurn) {
                return false;
              }
              final authored = switch (primitive.authoredOrientation) {
                BorderPrimitiveOrientation.legacyAxis ||
                BorderPrimitiveOrientation.east => 0,
                BorderPrimitiveOrientation.south => 1,
                BorderPrimitiveOrientation.west => 2,
                BorderPrimitiveOrientation.north => 3,
              };
              final turns = (target - authored + 4) % 4;
              return (definition.defaults.allowAutoRotation || turns == 0) &&
                  primitive.transforms.allowedQuarterTurns.contains(turns);
            });
            if (!covered) error('border.spatial.sequence_orientation_missing');
          }
        }
      }
    }
  }
  if (definition.followContourDirection && !definition.straightOnly) {
    for (var phase = 0; phase < definition.sequenceLength; phase++) {
      final turns = definition.primitives
          .where(
            (primitive) =>
                primitive.role == BorderPrimitiveRole.lineCorner &&
                primitive.sequenceIndex == phase,
          )
          .map((primitive) => primitive.cornerTurn)
          .toSet();
      if (turns.contains(null) || !turns.containsAll(BorderCornerTurn.values)) {
        error('border.spatial.corner_turn_missing');
      }
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
}) => resolveSpatialBorderFeatureInContext(
  manifest: manifest,
  context: SpatialBorderResolutionContext.fromMap(map),
  layerId: layerId,
  featureId: featureId,
  resolverVersion: resolverVersion,
);

SpatialBorderResolutionResult resolveSpatialBorderFeatureInContext({
  required ProjectManifest manifest,
  required SpatialBorderResolutionContext context,
  required String layerId,
  required String featureId,
  int resolverVersion = borderResolverVersion,
}) {
  final layer = context.layers
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
  if (!context.isSpatial) {
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
    sourceContext: context,
    mapId: context.mapId,
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
      <
        ({
          String lineageNamespace,
          int sourceEdgeOffset,
          bool closed,
          List<_SpatialBorderNode> nodes,
        })
      >[];
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
        sourceEdgeOffset: lattice.sourceEdgeOffset,
        closed: stroke.closed,
        nodes: [
          for (final node in lattice.nodes)
            (
              index: node.index,
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
    if (geometry.width != context.size.width ||
        geometry.height != context.size.height) {
      error('border.spatial.region_size_mismatch');
    }
    for (final contour in extractCanonicalBorderRegionContours(
      region: geometry,
      tileSizePx: const GridSize(width: 1, height: 1),
    )) {
      chains.add((
        lineageNamespace: 'region',
        sourceEdgeOffset: 0,
        closed: true,
        nodes: [
          for (var index = 0; index < contour.edges.length; index++)
            (
              index: index,
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
    if (keepOut.region.width != context.size.width ||
        keepOut.region.height != context.size.height) {
      error('border.spatial.keep_out_size_mismatch');
    }
  }
  final allOwned = <String>{};
  final instanceIds = context.instances.map((instance) => instance.id).toSet();
  for (final candidateLayer in context.layers) {
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
  final reservedSlots = <String>{};
  final faceProbes = <_SpatialFaceProbe>[];
  final overridesBySlot = {
    for (final override in feature.overrides) override.slotKey: override,
  };
  for (final chain in chains) {
    final chainSlots = <int, String>{};
    final wideCorners = <int, int>{};
    for (final node in chain.nodes) {
      final sequenceIndex =
          ((BigInt.from(chain.sourceEdgeOffset) + BigInt.from(node.index)) %
                  BigInt.from(definition.sequenceLength))
              .toInt();
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
      final slotKey = _spatialSlotKey(layerId, featureId, lineage, node.cell);
      chainSlots[node.index] = slotKey;
      if (!slots.add(slotKey)) {
        error('border.spatial.slot_identity_conflict', slotKey: slotKey);
        continue;
      }
      final override = overridesBySlot[slotKey];
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
            primitive.sequenceIndex == sequenceIndex &&
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
            context.mapId,
          ) ||
          !manifest.resourceLibraryCatalog.availableForMap(
            'borderBlueprint',
            feature.blueprintId,
            context.mapId,
          )) {
        error('border.spatial.resource_scope_conflict', slotKey: slotKey);
        continue;
      }
      final id =
          'border3d_${_hash([context.mapId, layerId, featureId, slotKey]).substring(7, 39)}';
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
              context.worldHeightAt(
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
        final locked = context.instances
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
          instance.position.x >= context.size.width ||
          instance.position.z >= context.size.height) {
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
      if (terrainCell != null) {
        faceProbes.add((
          slotKey: slotKey,
          cell: node.cell,
          landCell: terrainCell,
          outsideCell: _strokeOutsideCell(
            node,
            alignment: alignment,
            landCell: terrainCell,
          ),
          instance: instance,
          model: model,
          anchor: anchor,
        ));
      }
      if (primitive.cornerJoinCells > 0) {
        wideCorners[node.index] = primitive.cornerJoinCells;
      }
    }
    final reservations = <int, int>{};
    for (final entry in wideCorners.entries) {
      for (var distance = 1; distance <= entry.value; distance++) {
        for (final direction in [-1, 1]) {
          var index = entry.key + direction * distance;
          if (chain.closed) index %= chain.nodes.length;
          if (index < 0 ||
              index >= chain.nodes.length ||
              chain.nodes[index].kind != BorderLinearNodeKind.straight ||
              reservations.containsKey(index)) {
            error(
              'border.spatial.corner_join_conflict',
              slotKey: chainSlots[entry.key],
            );
            continue;
          }
          reservations[index] = entry.key;
          final slotKey = chainSlots[index]!;
          if (overridesBySlot[slotKey] case final override?
              when !override.suppressed) {
            error(
              'border.spatial.corner_join_override_conflict',
              slotKey: slotKey,
            );
          }
          reservedSlots.add(slotKey);
        }
      }
    }
  }
  final reservedInstances = {
    for (final placement in placements)
      if (reservedSlots.contains(placement.slotKey)) placement.instanceId,
  };
  placements.removeWhere(
    (placement) => reservedSlots.contains(placement.slotKey),
  );
  instances.removeWhere((instance) => reservedInstances.contains(instance.id));
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
  diagnostics.addAll(
    _spatialBorderFaceGroundDiagnostics(
      context: context,
      blueprintId: feature.blueprintId,
      featureId: featureId,
      probes: faceProbes.where(
        (probe) => !reservedSlots.contains(probe.slotKey),
      ),
    ),
  );
  if (context.instances.length -
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
  final terrainContext = context.fingerprintContext();
  final components = BorderInputFingerprints(
    blueprint: _hash(
      encodeBorderBlueprintRevisionJson(
        revision,
        formatVersion: manifest.borderCatalog.formatVersion,
      ),
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
        for (final instance in context.instances)
          if (feature.overrides.any(
            (override) => override.lockedInstanceId == instance.id,
          ))
            instance.toJson(),
      ],
    }),
    keepOutRegions: _hash(featureJson['keepOutRegions']),
    mapContext: _hash(terrainContext),
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
    sourceContext: context,
    mapId: context.mapId,
    layerId: layerId,
    featureId: featureId,
    result: BorderResolutionResult(
      materialization: materialization,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    ),
    modelInstances: instances,
  );
}

Set<String> resolveSpatialBorderFeatureBaseSlotKeys({
  required ProjectManifest manifest,
  required MapData map,
  required String layerId,
  required String featureId,
}) {
  final feature = map.layers
      .whereType<BorderLayer>()
      .where((layer) => layer.id == layerId)
      .firstOrNull
      ?.content
      .featureById(featureId);
  final definition = manifest.borderCatalog
      .recordById(feature?.blueprintId ?? '')
      ?.latestPublished
      ?.definition;
  if (feature == null ||
      definition == null ||
      !definition.isSpatial ||
      map.spatialScene == null ||
      map.version != ProjectVersion.v9) {
    throw const ValidationException(
      'A published spatial Border feature is required',
    );
  }
  if (feature.geometry case final BorderRegionGeometry region
      when region.width != map.size.width || region.height != map.size.height) {
    throw const ValidationException(
      'The spatial Border region size must match the map',
    );
  }
  final diagnostics = validateSpatialBorderFeatureGeometry(
    blueprintId: feature.blueprintId,
    featureId: featureId,
    definition: definition,
    geometry: feature.geometry,
  );
  if (diagnostics.hasErrors) {
    throw const ValidationException('The spatial Border geometry is invalid');
  }
  return Set.unmodifiable(
    _translatedSpatialSlotKeys(
      feature.geometry,
      layerId: layerId,
      featureId: featureId,
      directed: definition.followContourDirection,
      dx: 0,
      dz: 0,
    ).keys,
  );
}

MapData moveSpatialBorderFeature(
  MapData map, {
  required ProjectManifest manifest,
  required String layerId,
  required String featureId,
  required BorderFeatureGeometry geometry,
  required int dx,
  required int dz,
}) {
  final feature = map.layers
      .whereType<BorderLayer>()
      .where((layer) => layer.id == layerId)
      .firstOrNull
      ?.content
      .featureById(featureId);
  if (map.spatialScene == null || feature == null) {
    throw const ValidationException('A spatial Border feature is required');
  }
  final updated = updateBorderFeatureGeometry(
    map,
    layerId: layerId,
    featureId: featureId,
    geometry: geometry,
  );
  if (feature.overrides.isEmpty || (dx == 0 && dz == 0)) return updated;
  if (feature.overrides.any((override) => override.locked)) {
    throw const ValidationException(
      'Unlock spatial Border slots before moving the feature',
    );
  }
  final definition = manifest.borderCatalog
      .recordById(feature.blueprintId)
      ?.latestPublished
      ?.definition;
  if (definition == null) {
    throw const ValidationException(
      'The spatial Border blueprint is unavailable',
    );
  }
  final translatedKeys = _translatedSpatialSlotKeys(
    feature.geometry,
    layerId: layerId,
    featureId: featureId,
    directed: definition.followContourDirection,
    dx: dx,
    dz: dz,
  );
  final availableKeys = _translatedSpatialSlotKeys(
    geometry,
    layerId: layerId,
    featureId: featureId,
    directed: definition.followContourDirection,
    dx: 0,
    dz: 0,
  ).keys.toSet();
  final source = resolveSpatialBorderFeature(
    manifest: manifest,
    map: map,
    layerId: layerId,
    featureId: featureId,
  );
  if (!source.result.canApply) {
    throw const ValidationException(
      'Resolve spatial Border corrections before moving the feature',
    );
  }
  final selectedPrimitives = {
    for (final placement in source.result.materialization!.spatialPlacements)
      placement.slotKey: placement.primitiveId,
  };
  final overrides = <BorderSlotOverride>[];
  for (final override in feature.overrides) {
    final key = translatedKeys[override.slotKey];
    if (key == null || !availableKeys.contains(key)) {
      throw const ValidationException(
        'A spatial Border override cannot follow this translation',
      );
    }
    overrides.add(
      BorderSlotOverride(
        slotKey: key,
        variationSalt: override.variationSalt,
        suppressed: override.suppressed,
        locked: false,
        replacementPrimitiveId: override.suppressed
            ? null
            : override.replacementPrimitiveId ??
                  selectedPrimitives[override.slotKey],
        offsetDeltaPx: override.offsetDeltaPx,
        transformOverride: override.transformOverride,
      ),
    );
  }
  return updateBorderFeatureOverrides(
    updated,
    layerId: layerId,
    featureId: featureId,
    overrides: overrides,
  );
}

String _spatialSlotKey(
  String layerId,
  String featureId,
  List<Object?> lineage,
  GridPos cell,
) =>
    'border3d-slot:${_hash([layerId, featureId, ...lineage, cell.x, cell.y]).substring(7)}';

Map<String, String> _translatedSpatialSlotKeys(
  BorderFeatureGeometry geometry, {
  required String layerId,
  required String featureId,
  required bool directed,
  required int dx,
  required int dz,
}) {
  final keys = <String, String>{};
  void add(List<Object?> lineage, GridPos cell) {
    keys[_spatialSlotKey(layerId, featureId, lineage, cell)] = _spatialSlotKey(
      layerId,
      featureId,
      lineage,
      GridPos(x: cell.x + dx, y: cell.y + dz),
    );
  }

  switch (geometry) {
    case BorderStrokeGeometry geometry:
      for (final stroke in geometry.strokes) {
        final lattice = buildBorderLinearLatticeV1(
          stroke: stroke,
          tileSizePx: const GridSize(width: 1, height: 1),
          preserveTraversal: directed,
        );
        for (final node in lattice.nodes) {
          add([lattice.lineageNamespace], node.cell);
        }
      }
    case BorderRegionGeometry geometry:
      for (final contour in extractCanonicalBorderRegionContours(
        region: geometry,
        tileSizePx: const GridSize(width: 1, height: 1),
      )) {
        for (var index = 0; index < contour.edges.length; index++) {
          add([
            'region',
            contour
                .edges[(index + contour.edges.length - 1) %
                    contour.edges.length]
                .direction
                .name,
            contour.edges[index].direction.name,
          ], contour.edges[index].startVertex);
        }
      }
  }
  return keys;
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

GridPos _strokeOutsideCell(
  _SpatialBorderNode node, {
  required BorderStrokeAlignment alignment,
  required GridPos landCell,
}) {
  if (alignment == BorderStrokeAlignment.cellCenters) {
    return GridPos(
      x: 2 * node.cell.x - landCell.x,
      y: 2 * node.cell.y - landCell.y,
    );
  }
  final (dx, dz) = switch (node.outgoingDirection ?? node.incomingDirection!) {
    BorderCardinalDirection.east => (0, 1),
    BorderCardinalDirection.south => (-1, 0),
    BorderCardinalDirection.west => (0, -1),
    BorderCardinalDirection.north => (1, 0),
  };
  return GridPos(x: landCell.x - dx, y: landCell.y - dz);
}

List<BorderDiagnostic> _spatialBorderFaceGroundDiagnostics({
  required SpatialBorderResolutionContext context,
  required String blueprintId,
  required String featureId,
  required Iterable<_SpatialFaceProbe> probes,
}) {
  final groundModeledAt = context.groundModeledAt;
  if (groundModeledAt == null) return const [];
  bool inside(GridPos cell) =>
      cell.x >= 0 &&
      cell.y >= 0 &&
      cell.x < context.size.width &&
      cell.y < context.size.height;
  final diagnostics = <BorderDiagnostic>[];
  for (final probe in probes) {
    if (!inside(probe.landCell) || !inside(probe.outsideCell)) continue;
    final model = probe.model;
    final bounds = model.inspection.bounds;
    final scale = model.scale * probe.instance.scale;
    final span = (bounds.max.y - bounds.min.y) * scale;
    final faceHeight = (probe.anchor.y - bounds.min.y) * scale;
    final headroom = (bounds.max.y - probe.anchor.y) * scale;
    if (span <= 0 || faceHeight < span * .75 || headroom < -span * .25) {
      continue;
    }
    final crown =
        probe.instance.position.y + (probe.anchor.y - model.pivot.y) * scale;
    final base = crown - faceHeight;
    final land = context.worldHeightAt(
      probe.landCell.x + .5,
      probe.landCell.y + .5,
    );
    final outside = context.worldHeightAt(
      probe.outsideCell.x + .5,
      probe.outsideCell.y + .5,
    );
    final landIsUpper = land >= outside;
    final upper = landIsUpper ? land : outside;
    final lower = landIsUpper ? outside : land;
    final upperCell = landIsUpper ? probe.landCell : probe.outsideCell;
    final lowerCell = landIsUpper ? probe.outsideCell : probe.landCell;
    final tolerance = faceHeight * .25;
    for (final (code, measured, expected, below, groundCell, action) in [
      (
        'border.spatial.face_crown_mismatch',
        crown,
        upper,
        tolerance,
        upperCell,
        'border.action.align_contour_with_upper_ground',
      ),
      (
        'border.spatial.face_base_mismatch',
        base,
        lower,
        faceHeight * .5,
        lowerCell,
        'border.action.support_lower_ground',
      ),
    ]) {
      if ((measured >= expected
              ? measured - expected <= tolerance + .000001
              : expected - measured <= below + .000001) ||
          !groundModeledAt(groundCell.x + .5, groundCell.y + .5)) {
        continue;
      }
      diagnostics.add(
        BorderDiagnostic(
          code: code,
          severity: BorderDiagnosticSeverity.warning,
          phase: BorderDiagnosticPhase.resolution,
          scope: BorderDiagnosticScope.slot,
          blueprintId: blueprintId,
          featureId: featureId,
          slotKey: probe.slotKey,
          cell: probe.cell,
          parameters: {
            'crownHeight': crown,
            'baseHeight': base,
            'upperGroundHeight': upper,
            'lowerGroundHeight': lower,
            'tolerance': measured >= expected ? tolerance : below,
            'landCell': {'x': probe.landCell.x, 'y': probe.landCell.y},
            'outsideCell': {
              'x': probe.outsideCell.x,
              'y': probe.outsideCell.y,
            },
          },
          suggestedAction: action,
        ),
      );
    }
  }
  return diagnostics;
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
  if (definition.sequenceLength > 1) return false;
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
