import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

/// Canonical Border resolution preview bound to map revision and feature seed.
final class BorderPreviewArtifact {
  BorderPreviewArtifact({
    required this.mapId,
    required this.layerId,
    required this.featureId,
    required this.projectRevision,
    required this.seed,
    required this.blueprintId,
    required this.blueprintRevision,
    required this.resolverVersion,
    required this.result,
  }) {
    fingerprint = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'border-preview.json',
        bytes: utf8.encode(jsonEncode(_payload())),
      ),
    ]);
  }

  final String mapId;
  final String layerId;
  final String featureId;
  final String projectRevision;
  final String seed;
  final String blueprintId;
  final int blueprintRevision;
  final int resolverVersion;
  final BorderResolutionResult result;
  late final String fingerprint;

  Map<String, Object?> _payload() => {
        'schema': 'pokemap.border-preview.v1',
        'mapId': mapId,
        'layerId': layerId,
        'featureId': featureId,
        'projectRevision': projectRevision,
        'seed': seed,
        'blueprintId': blueprintId,
        'blueprintRevision': blueprintRevision,
        'resolverVersion': resolverVersion,
        'status': result.status.name,
        'diagnosticCount': result.diagnostics.length,
        'errorCount': result.diagnosticReport.errorCount,
        'warningCount': result.diagnosticReport.warningCount,
        'placementCount': result.materialization?.placements.length ?? 0,
        'groundCellCount': result.materialization?.ground.length ?? 0,
        'inputFingerprint':
            result.materialization?.receipt.inputFingerprint ?? '',
        'outputFingerprint':
            result.materialization?.receipt.outputFingerprint ?? '',
      };

  Map<String, Object?> toJson() => {
        ..._payload(),
        'fingerprint': fingerprint,
      };
}

/// Pure adapter over the canonical Border operations owned by `map_core`.
final class BorderActions {
  const BorderActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor('border_layer.stroke_add', 'Add a Border feature stroke'),
    _descriptor('border_layer.stroke_update', 'Update a Border feature stroke'),
    _descriptor('border_layer.stroke_delete', 'Delete a Border feature stroke'),
    _descriptor('border_layer.region_fill', 'Fill a Border region mask'),
    _descriptor('border_layer.region_clear', 'Clear a Border region mask'),
    _descriptor('border_layer.feature_create', 'Create a Border feature'),
    _descriptor('border_layer.feature_update', 'Update a Border feature'),
    _descriptor('border_layer.feature_move', 'Move Border feature geometry'),
    _descriptor('border_layer.feature_reorder', 'Reorder a Border feature'),
    _descriptor('border_layer.feature_delete', 'Delete a Border feature'),
    _descriptor(
      'border_layer.feature_set_blueprint',
      'Relink a Border feature to a published blueprint',
    ),
    _descriptor(
      'border_layer.feature_set_variation',
      'Set a deterministic Border slot variation',
    ),
    _descriptor('border_layer.feature_lock', 'Lock a resolved Border slot'),
    _descriptor('border_layer.feature_unlock', 'Unlock a Border slot'),
    _descriptor(
      'border_layer.feature_set_keep_out',
      'Replace Border feature keep-out regions',
    ),
    _descriptor(
      'border_layer.relink_apply',
      'Apply a revision-checked Border blueprint relink',
    ),
    _descriptor(
      'border_layer.materialize_apply',
      'Resolve and persist Border materialization',
    ),
    _descriptor(
      'border_layer.resize_apply',
      'Resize a map and every Border layer atomically',
    ),
  ]);

  BorderBlueprintRevision requirePublishedBlueprint(
    ProjectManifest manifest,
    String blueprintId,
  ) {
    final record = manifest.borderCatalog.recordById(blueprintId);
    if (record == null) {
      throw semanticFailure(
        'border.blueprint_missing',
        'The requested Border blueprint does not exist.',
        details: {'blueprintId': blueprintId},
      );
    }
    final published = record.latestPublished;
    if (published == null) {
      throw semanticFailure(
        'border.blueprint_not_published',
        'A Border feature can only use a published blueprint revision.',
        details: {'blueprintId': blueprintId},
        remediation: const [
          'Resolve publication readiness diagnostics and publish the blueprint.',
        ],
      );
    }
    return published;
  }

  BorderStrokeGeometry editStroke(
    BorderStrokeGeometry base, {
    required BorderStrokeEditingMode mode,
    required List<GridPos> sampledPoints,
  }) {
    if (sampledPoints.isEmpty) {
      throw semanticFailure(
        'border.stroke_points_empty',
        'A Border stroke edit needs at least one sampled point.',
      );
    }
    var draft = BorderStrokeEditingDraft.begin(
      baseGeometry: base,
      mode: mode,
      pointerDown: sampledPoints.first,
    );
    for (final point in sampledPoints.skip(1)) {
      draft = draft.sample(point);
    }
    final geometry = draft.previewGeometry;
    if (geometry == null) {
      throw semanticFailure(
        'border.stroke_too_short',
        'A drawn Border stroke must cover at least two cells.',
      );
    }
    return geometry;
  }

  BorderPreviewArtifact preview({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required String featureId,
    required String projectRevision,
    required GridSize tileSizePx,
    required int resolverVersion,
  }) {
    _stableText(projectRevision, 'projectRevision');
    final feature = _feature(_borderLayer(map, layerId), featureId);
    final revision = requirePublishedBlueprint(manifest, feature.blueprintId);
    final request = BorderResolutionRequest(
      mapSize: map.size,
      tileSizePx: tileSizePx,
      blueprintId: feature.blueprintId,
      blueprintRevision: revision,
      feature: feature,
      visualSnapshots: manifest.borderCatalog.visualSnapshots,
      resolverVersion: resolverVersion,
    );
    final result = resolveBorderFeature(request);
    return BorderPreviewArtifact(
      mapId: map.id,
      layerId: layerId,
      featureId: featureId,
      projectRevision: projectRevision,
      seed: feature.seed.toString(),
      blueprintId: feature.blueprintId,
      blueprintRevision: revision.revision,
      resolverVersion: resolverVersion,
      result: result,
    );
  }

  BorderDiagnosticsReport diagnostics({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required String featureId,
    required String projectRevision,
    required GridSize tileSizePx,
    required int resolverVersion,
  }) =>
      preview(
        manifest: manifest,
        map: map,
        layerId: layerId,
        featureId: featureId,
        projectRevision: projectRevision,
        tileSizePx: tileSizePx,
        resolverVersion: resolverVersion,
      ).result.diagnosticReport;

  BorderFeatureRelinkPreview planRelink({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required String featureId,
    required String targetBlueprintId,
    required GridSize tileSizePx,
    required int resolverVersion,
  }) =>
      prepareBorderFeatureRelink(
        map: map,
        layerId: layerId,
        featureId: featureId,
        targetBlueprintId: targetBlueprintId,
        targetBlueprintRevision:
            requirePublishedBlueprint(manifest, targetBlueprintId),
        visualSnapshots: manifest.borderCatalog.visualSnapshots,
        tileSizePx: tileSizePx,
        resolverVersion: resolverVersion,
      );

  MapResizeWithBorderDiagnosticsResult planResize({
    required MapData map,
    required int width,
    required int height,
    required GridSize tileSizePx,
  }) =>
      resizeMapDataWithBorderDiagnostics(
        map,
        width: width,
        height: height,
        tileSizePx: tileSizePx,
      );

  BorderPublicationReadinessResult publicationReadiness({
    required String blueprintId,
    required BorderBlueprintPublishedDefinition definition,
    required int resolverVersion,
    required ProjectManifest project,
    required List<BorderVisualSnapshot> visualSnapshots,
    required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
    required BorderPublicationGalleryReport canonicalGalleryReport,
  }) =>
      assessBorderPublicationReadiness(
        blueprintId: blueprintId,
        definition: definition,
        resolverVersion: resolverVersion,
        project: project,
        visualSnapshots: visualSnapshots,
        snapshotIntegrity: snapshotIntegrity,
        canonicalGalleryReport: canonicalGalleryReport,
      );

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final actionId = planning.request.actionId;
    final allowed = switch (actionId) {
      'border_layer.stroke_add' || 'border_layer.stroke_update' => const {
          'layerId',
          'featureId',
          'strokeId',
          'points',
          'closed',
        },
      'border_layer.stroke_delete' => const {
          'layerId',
          'featureId',
          'strokeId',
        },
      'border_layer.region_fill' || 'border_layer.region_clear' => const {
          'layerId',
          'featureId',
          'x',
          'y',
          'width',
          'height',
        },
      'border_layer.feature_create' => const {
          'layerId',
          'featureId',
          'name',
          'blueprintId',
          'seed',
          'geometry',
        },
      'border_layer.feature_update' => const {
          'layerId',
          'featureId',
          'name',
          'seed',
          'lineSide',
          'paramsOverride',
          'clearParamsOverride',
        },
      'border_layer.feature_move' => const {
          'layerId',
          'featureId',
          'dx',
          'dy',
        },
      'border_layer.feature_reorder' => const {
          'layerId',
          'featureId',
          'newIndex',
        },
      'border_layer.feature_delete' => const {'layerId', 'featureId'},
      'border_layer.feature_set_blueprint' ||
      'border_layer.relink_apply' =>
        const {
          'layerId',
          'featureId',
          'targetBlueprintId',
          'tileWidthPx',
          'tileHeightPx',
          'resolverVersion',
          'confirmFamilyReset',
        },
      'border_layer.feature_set_variation' => const {
          'layerId',
          'featureId',
          'slotKey',
          'variationSalt',
        },
      'border_layer.feature_lock' || 'border_layer.feature_unlock' => const {
          'layerId',
          'featureId',
          'slotKey',
        },
      'border_layer.feature_set_keep_out' => const {
          'layerId',
          'featureId',
          'regions',
        },
      'border_layer.materialize_apply' => const {
          'layerId',
          'featureId',
          'tileWidthPx',
          'tileHeightPx',
          'resolverVersion',
        },
      'border_layer.resize_apply' => const {
          'layerId',
          'width',
          'height',
          'tileWidthPx',
          'tileHeightPx',
        },
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested Border action is unsupported.',
          details: {'actionId': actionId},
        ),
    };
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: allowed,
    );
    final parameters = context.parameters;
    final layerId = parameters.string('layerId');
    late MapData updated;
    var changedItems = 1;
    final extraPreview = <String, Object?>{};

    switch (actionId) {
      case 'border_layer.stroke_add':
      case 'border_layer.stroke_update':
        final featureId = parameters.string('featureId');
        final layer = _borderLayer(context.map, layerId);
        final feature = _feature(layer, featureId);
        final geometry = feature.geometry;
        if (geometry is! BorderStrokeGeometry) {
          throw semanticFailure(
            'border.geometry_kind_mismatch',
            'Stroke actions require linear Border geometry.',
          );
        }
        final stroke = BorderStroke(
          id: parameters.string('strokeId'),
          points: _points(parameters.list('points')),
          closed: parameters.contains('closed') && parameters.boolean('closed'),
        );
        final index = geometry.strokes
            .indexWhere((candidate) => candidate.id == stroke.id);
        if (actionId == 'border_layer.stroke_add' && index >= 0) {
          throw semanticFailure(
            'border.stroke_exists',
            'A Border stroke already uses this ID.',
          );
        }
        if (actionId == 'border_layer.stroke_update' && index < 0) {
          throw semanticFailure(
            'border.stroke_missing',
            'The requested Border stroke does not exist.',
          );
        }
        final strokes = List<BorderStroke>.from(geometry.strokes);
        if (index < 0) {
          strokes.add(stroke);
        } else {
          strokes[index] = stroke;
        }
        updated = updateBorderFeatureGeometry(
          context.map,
          layerId: layerId,
          featureId: featureId,
          geometry: BorderStrokeGeometry(
            strokes: strokes,
            alignment: geometry.alignment,
          ),
        );
      case 'border_layer.stroke_delete':
        final featureId = parameters.string('featureId');
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        final geometry = feature.geometry;
        if (geometry is! BorderStrokeGeometry) {
          throw semanticFailure(
            'border.geometry_kind_mismatch',
            'Stroke actions require linear Border geometry.',
          );
        }
        final strokeId = parameters.string('strokeId');
        if (!geometry.strokes.any((value) => value.id == strokeId)) {
          throw semanticFailure(
            'border.stroke_missing',
            'The requested Border stroke does not exist.',
          );
        }
        updated = updateBorderFeatureGeometry(
          context.map,
          layerId: layerId,
          featureId: featureId,
          geometry: BorderStrokeGeometry(
            strokes: [
              for (final stroke in geometry.strokes)
                if (stroke.id != strokeId) stroke,
            ],
            alignment: geometry.alignment,
          ),
        );
      case 'border_layer.region_fill':
      case 'border_layer.region_clear':
        final featureId = parameters.string('featureId');
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        final geometry = feature.geometry;
        if (geometry is! BorderRegionGeometry) {
          throw semanticFailure(
            'border.geometry_kind_mismatch',
            'Region actions require region Border geometry.',
          );
        }
        final region = _regionParameters(parameters, context.map.size);
        final cells = List<bool>.from(geometry.cells);
        for (var y = region.y; y < region.bottom; y++) {
          for (var x = region.x; x < region.right; x++) {
            cells[y * geometry.width + x] =
                actionId == 'border_layer.region_fill';
          }
        }
        updated = updateBorderFeatureGeometry(
          context.map,
          layerId: layerId,
          featureId: featureId,
          geometry: BorderRegionGeometry(
            width: geometry.width,
            height: geometry.height,
            cells: cells,
          ),
        );
        changedItems = region.width * region.height;
      case 'border_layer.feature_create':
        final blueprintId = parameters.string('blueprintId');
        final featureId = parameters.string('featureId');
        if (_borderLayer(context.map, layerId).content.featureById(featureId) !=
            null) {
          throw semanticFailure(
            'border.feature_exists',
            'A Border feature already uses this ID.',
            details: {'featureId': featureId},
          );
        }
        final revision = requirePublishedBlueprint(
          context.manifest,
          blueprintId,
        );
        final geometry = _geometry(parameters.object('geometry'));
        if (borderGeometryFamily(geometry) !=
            borderTemplateGeometryFamily(revision.definition.template)) {
          throw semanticFailure(
            'border.geometry_kind_mismatch',
            'The Border geometry is incompatible with the blueprint template.',
          );
        }
        updated = upsertBorderFeature(
          context.map,
          layerId: layerId,
          feature: BorderFeature(
            id: featureId,
            name: parameters.string('name'),
            blueprintId: blueprintId,
            seed: _seed(parameters.value('seed')),
            geometry: geometry,
            overrides: const [],
            keepOutRegions: const [],
          ),
          template: revision.definition.template,
        );
      case 'border_layer.feature_update':
        final featureId = parameters.string('featureId');
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        final clear = parameters.contains('clearParamsOverride') &&
            parameters.boolean('clearParamsOverride');
        final params = parameters.contains('paramsOverride')
            ? _generationParams(parameters.object('paramsOverride'))
            : feature.paramsOverride;
        final lineSide = parameters.optionalString('lineSide');
        updated = upsertBorderFeature(
          context.map,
          layerId: layerId,
          feature: _copyFeature(
            feature,
            name: parameters.optionalString('name'),
            seed: parameters.contains('seed')
                ? _seed(parameters.value('seed'))
                : null,
            lineSide: lineSide == null ? null : _lineSide(lineSide),
            paramsOverride: clear ? null : params,
            replaceParams: clear || parameters.contains('paramsOverride'),
          ),
        );
      case 'border_layer.feature_move':
        final featureId = parameters.string('featureId');
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        updated = updateBorderFeatureGeometry(
          context.map,
          layerId: layerId,
          featureId: featureId,
          geometry: _translateGeometry(
            feature.geometry,
            dx: parameters.integer('dx'),
            dy: parameters.integer('dy'),
            mapSize: context.map.size,
          ),
        );
      case 'border_layer.feature_reorder':
        updated = reorderBorderFeature(
          context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
          newIndex: parameters.integer('newIndex'),
        );
      case 'border_layer.feature_delete':
        updated = removeBorderFeature(
          context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
        );
      case 'border_layer.feature_set_blueprint':
      case 'border_layer.relink_apply':
        final relink = planRelink(
          manifest: context.manifest,
          map: context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
          targetBlueprintId: parameters.string('targetBlueprintId'),
          tileSizePx: _tileSize(parameters),
          resolverVersion: parameters.integer('resolverVersion'),
        );
        if (relink.kind == BorderRelinkKind.requiresFamilyReset) {
          if (!parameters.contains('confirmFamilyReset') ||
              !parameters.boolean('confirmFamilyReset')) {
            throw semanticFailure(
              'border.relink_confirmation_required',
              'Changing Border geometry family requires explicit confirmation.',
              details: {
                'losses': relink.losses.map((value) => value.name).toList(),
              },
            );
          }
          updated = applyBorderFeatureFamilyReset(
            context.map,
            preview: relink,
          );
        } else {
          if (relink.proposedResult?.canApply != true) {
            throw semanticFailure(
              'border.relink_resolution_failed',
              'The target Border blueprint cannot resolve this feature.',
              details: {
                'diagnosticCount':
                    relink.proposedResult?.diagnostics.length ?? 0,
              },
            );
          }
          updated = applyBorderFeatureRelinkPreview(
            context.map,
            preview: relink,
          );
        }
        extraPreview['relinkKind'] = relink.kind.name;
        extraPreview['losses'] =
            relink.losses.map((value) => value.name).toList();
      case 'border_layer.feature_set_variation':
        final featureId = parameters.string('featureId');
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        final slotKey = parameters.string('slotKey');
        final salt = _seed(parameters.value('variationSalt'));
        final overrides = List<BorderSlotOverride>.from(feature.overrides);
        final index = overrides.indexWhere((value) => value.slotKey == slotKey);
        final current = index < 0 ? null : overrides[index];
        final replacement = BorderSlotOverride(
          slotKey: slotKey,
          variationSalt: salt,
          suppressed: current?.suppressed ?? false,
          locked: current?.locked ?? false,
          lockedPlacement: current?.lockedPlacement,
          replacementPrimitiveId: current?.replacementPrimitiveId,
          offsetDeltaPx: current?.offsetDeltaPx,
          transformOverride: current?.transformOverride,
        );
        if (index < 0) {
          overrides.add(replacement);
        } else {
          overrides[index] = replacement;
        }
        updated = updateBorderFeatureOverrides(
          context.map,
          layerId: layerId,
          featureId: featureId,
          overrides: overrides,
        );
      case 'border_layer.feature_lock':
        updated = _setSlotLock(
          context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
          slotKey: parameters.string('slotKey'),
          locked: true,
        );
      case 'border_layer.feature_unlock':
        updated = _setSlotLock(
          context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
          slotKey: parameters.string('slotKey'),
          locked: false,
        );
      case 'border_layer.feature_set_keep_out':
        updated = updateBorderFeatureKeepOutRegions(
          context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
          keepOutRegions: _keepOutRegions(parameters.list('regions')),
        );
      case 'border_layer.materialize_apply':
        final featureId = parameters.string('featureId');
        final artifact = preview(
          manifest: context.manifest,
          map: context.map,
          layerId: layerId,
          featureId: featureId,
          projectRevision: context.resource.revision!,
          tileSizePx: _tileSize(parameters),
          resolverVersion: parameters.integer('resolverVersion'),
        );
        if (!artifact.result.canApply) {
          throw semanticFailure(
            'border.materialization_failed',
            'Border resolution diagnostics prevent materialization.',
            details: {
              'diagnosticCount': artifact.result.diagnostics.length,
              'errorCount': artifact.result.diagnosticReport.errorCount,
            },
          );
        }
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        final revision = requirePublishedBlueprint(
          context.manifest,
          feature.blueprintId,
        );
        final request = BorderResolutionRequest(
          mapSize: context.map.size,
          tileSizePx: _tileSize(parameters),
          blueprintId: feature.blueprintId,
          blueprintRevision: revision,
          feature: feature,
          visualSnapshots: context.manifest.borderCatalog.visualSnapshots,
          resolverVersion: parameters.integer('resolverVersion'),
        );
        updated = applyBorderFeaturePreview(
          context.map,
          expectedMapId: context.map.id,
          layerId: layerId,
          featureId: featureId,
          expectedBaseFeatureFingerprint:
              computeBorderFeatureEditFingerprint(feature),
          proposedRequest: request,
          proposedResult: artifact.result,
        );
        extraPreview['borderPreview'] = artifact.toJson();
        changedItems = artifact.result.materialization!.placements.length +
            artifact.result.materialization!.ground.length;
      case 'border_layer.resize_apply':
        final result = planResize(
          map: context.map,
          width: parameters.integer('width'),
          height: parameters.integer('height'),
          tileSizePx: _tileSize(parameters),
        );
        if (!result.canApply || result.map == null) {
          throw semanticFailure(
            'border.resize_failed',
            'Border diagnostics prevent the requested map resize.',
            details: {
              'diagnosticCount': result.diagnosticReport.diagnosticCount,
              'errorCount': result.diagnosticReport.errorCount,
            },
          );
        }
        updated = result.map!;
        changedItems = updated.size.width * updated.size.height;
        extraPreview['diagnosticCount'] =
            result.diagnosticReport.diagnosticCount;
      default:
        throw StateError('unreachable Border action');
    }

    return context.draftMap(
      after: updated,
      operation: actionId,
      changedItems: changedItems,
      layerId: layerId,
      preview: extraPreview,
    );
  }
}

AuthoringActionDescriptor _descriptor(String id, String summary) =>
    semanticActionDescriptor(id, summary);

BorderLayer _borderLayer(MapData map, String layerId) {
  final layer =
      map.layers.where((candidate) => candidate.id == layerId).firstOrNull;
  if (layer is! BorderLayer) {
    throw semanticFailure(
      'border.layer_missing',
      'The requested layer is missing or is not a Border layer.',
      details: {'layerId': layerId},
    );
  }
  return layer;
}

BorderFeature _feature(BorderLayer layer, String featureId) {
  final feature = layer.content.featureById(featureId);
  if (feature == null) {
    throw semanticFailure(
      'border.feature_missing',
      'The requested Border feature does not exist.',
      details: {'layerId': layer.id, 'featureId': featureId},
    );
  }
  return feature;
}

BorderFeature _copyFeature(
  BorderFeature feature, {
  String? name,
  BorderSignedInt64? seed,
  BorderFeatureGeometry? geometry,
  BorderLineSide? lineSide,
  BorderGenerationParams? paramsOverride,
  bool replaceParams = false,
  List<BorderSlotOverride>? overrides,
  List<BorderKeepOutRegion>? keepOutRegions,
  BorderMaterialization? materialization,
  bool clearMaterialization = true,
}) =>
    BorderFeature(
      id: feature.id,
      name: name ?? feature.name,
      blueprintId: feature.blueprintId,
      seed: seed ?? feature.seed,
      geometry: geometry ?? feature.geometry,
      lineSide: lineSide ?? feature.lineSide,
      paramsOverride: replaceParams ? paramsOverride : feature.paramsOverride,
      overrides: overrides ?? feature.overrides,
      keepOutRegions: keepOutRegions ?? feature.keepOutRegions,
      materialization: clearMaterialization
          ? null
          : materialization ?? feature.materialization,
    );

BorderSignedInt64 _seed(Object? value) {
  try {
    return switch (value) {
      int value => BorderSignedInt64.fromInt(value),
      String value => BorderSignedInt64.parse(value),
      _ => throw const FormatException(),
    };
  } on Object {
    throw semanticFailure(
      'border.seed_invalid',
      'A Border seed must be an integer or canonical signed 64-bit string.',
    );
  }
}

BorderLineSide _lineSide(String value) => switch (value) {
      'primary' => BorderLineSide.primary,
      'inverted' => BorderLineSide.inverted,
      _ => throw invalidSemanticField(
          'lineSide',
          '"primary" or "inverted"',
        ),
    };

GridSize _tileSize(SemanticParameters parameters) {
  final size = GridSize(
    width: parameters.integer('tileWidthPx'),
    height: parameters.integer('tileHeightPx'),
  );
  if (size.width <= 0 || size.height <= 0) {
    throw semanticFailure(
      'border.tile_size_invalid',
      'Border tile pixel dimensions must be positive.',
    );
  }
  return size;
}

List<GridPos> _points(List<Object?> values) {
  final points = <GridPos>[];
  for (var index = 0; index < values.length; index++) {
    final value = values[index];
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw invalidSemanticField('points[$index]', 'an {x, y} object');
    }
    final point = Map<String, Object?>.from(value);
    if (point.keys.any((key) => key != 'x' && key != 'y') ||
        point['x'] is! int ||
        point['y'] is! int) {
      throw invalidSemanticField('points[$index]', 'integer x and y fields');
    }
    points.add(GridPos(x: point['x']! as int, y: point['y']! as int));
  }
  return points;
}

BorderFeatureGeometry _geometry(Map<String, Object?> value) {
  final kind = value['kind'];
  switch (kind) {
    case 'region':
      final width = value['width'];
      final height = value['height'];
      final cells = value['cells'];
      if (width is! int || height is! int || cells is! List) {
        throw invalidSemanticField(
          'geometry',
          'region width, height and boolean cells',
        );
      }
      if (cells.any((cell) => cell is! bool)) {
        throw invalidSemanticField('geometry.cells', 'booleans');
      }
      return BorderRegionGeometry(
        width: width,
        height: height,
        cells: cells.cast<bool>(),
      );
    case 'stroke':
      final rawStrokes = value['strokes'];
      if (rawStrokes is! List) {
        throw invalidSemanticField('geometry.strokes', 'a list');
      }
      final alignment = switch (value['alignment']) {
        null || 'cellCenters' => BorderStrokeAlignment.cellCenters,
        'gridEdges' => BorderStrokeAlignment.gridEdges,
        _ => throw invalidSemanticField(
            'geometry.alignment',
            '"cellCenters" or "gridEdges"',
          ),
      };
      return BorderStrokeGeometry(
        alignment: alignment,
        strokes: [
          for (var index = 0; index < rawStrokes.length; index++)
            _stroke(rawStrokes[index], index),
        ],
      );
    default:
      throw invalidSemanticField('geometry.kind', '"region" or "stroke"');
  }
}

BorderStroke _stroke(Object? raw, int index) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw invalidSemanticField('geometry.strokes[$index]', 'an object');
  }
  final value = Map<String, Object?>.from(raw);
  final id = value['id'];
  final points = value['points'];
  final closed = value['closed'] ?? false;
  if (id is! String || points is! List || closed is! bool) {
    throw invalidSemanticField(
      'geometry.strokes[$index]',
      'id, points and optional closed fields',
    );
  }
  return BorderStroke(
    id: id,
    points: _points(List<Object?>.from(points)),
    closed: closed,
  );
}

BorderGenerationParams _generationParams(Map<String, Object?> value) {
  const allowed = {
    'irregularityPermille',
    'detailDensityPermille',
    'variationPermille',
    'maxOverlapPx',
    'gapTolerancePx',
    'depthRows',
    'allowAutoRotation',
  };
  if (value.keys.any((key) => !allowed.contains(key))) {
    throw invalidSemanticField(
      'paramsOverride',
      'only canonical Border generation fields',
    );
  }
  int field(String key) {
    final raw = value[key];
    if (raw is! int) {
      throw invalidSemanticField('paramsOverride.$key', 'an integer');
    }
    return raw;
  }

  final rotation = value['allowAutoRotation'];
  if (rotation != null && rotation is! bool) {
    throw invalidSemanticField(
      'paramsOverride.allowAutoRotation',
      'a boolean',
    );
  }
  return BorderGenerationParams(
    irregularityPermille: field('irregularityPermille'),
    detailDensityPermille: field('detailDensityPermille'),
    variationPermille: field('variationPermille'),
    maxOverlapPx: field('maxOverlapPx'),
    gapTolerancePx: field('gapTolerancePx'),
    depthRows: field('depthRows'),
    allowAutoRotation: rotation as bool? ?? true,
  );
}

_BorderEditRegion _regionParameters(
  SemanticParameters parameters,
  GridSize size,
) {
  final region = _BorderEditRegion(
    x: parameters.integer('x'),
    y: parameters.integer('y'),
    width: parameters.integer('width'),
    height: parameters.integer('height'),
  );
  if (region.x < 0 ||
      region.y < 0 ||
      region.width <= 0 ||
      region.height <= 0 ||
      region.right > size.width ||
      region.bottom > size.height) {
    throw semanticFailure(
      'border.region_out_of_bounds',
      'The Border edit region is outside map bounds.',
    );
  }
  return region;
}

final class _BorderEditRegion {
  const _BorderEditRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  int get right => x + width;
  int get bottom => y + height;
}

BorderFeatureGeometry _translateGeometry(
  BorderFeatureGeometry geometry, {
  required int dx,
  required int dy,
  required GridSize mapSize,
}) {
  switch (geometry) {
    case BorderStrokeGeometry geometry:
      final strokes = <BorderStroke>[];
      for (final stroke in geometry.strokes) {
        final points = [
          for (final point in stroke.points)
            GridPos(x: point.x + dx, y: point.y + dy),
        ];
        if (points.any(
          (point) =>
              point.x < 0 ||
              point.y < 0 ||
              point.x >= mapSize.width ||
              point.y >= mapSize.height,
        )) {
          throw semanticFailure(
            'border.feature_out_of_bounds',
            'Moving the Border feature would leave map bounds.',
          );
        }
        strokes.add(
          BorderStroke(id: stroke.id, points: points, closed: stroke.closed),
        );
      }
      return BorderStrokeGeometry(
        strokes: strokes,
        alignment: geometry.alignment,
      );
    case BorderRegionGeometry geometry:
      final cells = List<bool>.filled(geometry.width * geometry.height, false);
      for (var y = 0; y < geometry.height; y++) {
        for (var x = 0; x < geometry.width; x++) {
          if (!geometry.cells[y * geometry.width + x]) continue;
          final targetX = x + dx;
          final targetY = y + dy;
          if (targetX < 0 ||
              targetY < 0 ||
              targetX >= geometry.width ||
              targetY >= geometry.height) {
            throw semanticFailure(
              'border.feature_out_of_bounds',
              'Moving the Border feature would leave map bounds.',
            );
          }
          cells[targetY * geometry.width + targetX] = true;
        }
      }
      return BorderRegionGeometry(
        width: geometry.width,
        height: geometry.height,
        cells: cells,
      );
  }
}

List<BorderKeepOutRegion> _keepOutRegions(List<Object?> values) => [
      for (var index = 0; index < values.length; index++)
        _keepOutRegion(values[index], index),
    ];

BorderKeepOutRegion _keepOutRegion(Object? raw, int index) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw invalidSemanticField('regions[$index]', 'an object');
  }
  final value = Map<String, Object?>.from(raw);
  final id = value['id'];
  final region = value['region'];
  if (id is! String || region is! Map) {
    throw invalidSemanticField('regions[$index]', 'id and region fields');
  }
  final geometry = _geometry({
    'kind': 'region',
    ...Map<String, Object?>.from(region),
  });
  return BorderKeepOutRegion(
    id: id,
    region: geometry as BorderRegionGeometry,
  );
}

MapData _setSlotLock(
  MapData map, {
  required String layerId,
  required String featureId,
  required String slotKey,
  required bool locked,
}) {
  final feature = _feature(_borderLayer(map, layerId), featureId);
  final overrides = List<BorderSlotOverride>.from(feature.overrides);
  final overrideIndex =
      overrides.indexWhere((value) => value.slotKey == slotKey);
  final current = overrideIndex < 0 ? null : overrides[overrideIndex];
  if (locked) {
    final placement = feature.materialization?.placements
        .where((value) => value.slotKey == slotKey)
        .firstOrNull;
    if (placement == null) {
      throw semanticFailure(
        'border.slot_not_resolved',
        'A Border slot must be materialized before it can be locked.',
        details: {'slotKey': slotKey},
      );
    }
    final replacement = BorderSlotOverride(
      slotKey: slotKey,
      variationSalt: current?.variationSalt ?? BorderSignedInt64.zero,
      suppressed: false,
      locked: true,
      lockedPlacement: placement,
      replacementPrimitiveId: current?.replacementPrimitiveId,
      offsetDeltaPx: current?.offsetDeltaPx,
      transformOverride: current?.transformOverride,
    );
    if (overrideIndex < 0) {
      overrides.add(replacement);
    } else {
      overrides[overrideIndex] = replacement;
    }
  } else {
    if (current == null || !current.locked) {
      throw semanticFailure(
        'border.slot_not_locked',
        'The requested Border slot is not locked.',
        details: {'slotKey': slotKey},
      );
    }
    final hasOtherOverride = current.variationSalt != BorderSignedInt64.zero ||
        current.replacementPrimitiveId != null ||
        current.offsetDeltaPx != null ||
        current.transformOverride != null;
    if (!hasOtherOverride) {
      overrides.removeAt(overrideIndex);
    } else {
      overrides[overrideIndex] = BorderSlotOverride(
        slotKey: slotKey,
        variationSalt: current.variationSalt,
        suppressed: false,
        locked: false,
        replacementPrimitiveId: current.replacementPrimitiveId,
        offsetDeltaPx: current.offsetDeltaPx,
        transformOverride: current.transformOverride,
      );
    }
  }
  return updateBorderFeatureOverrides(
    map,
    layerId: layerId,
    featureId: featureId,
    overrides: overrides,
  );
}

void _stableText(String value, String field) {
  if (value.isEmpty || value.trim() != value) {
    throw semanticFailure(
      'border.request_invalid',
      '$field must be a nonblank trimmed string.',
    );
  }
}
