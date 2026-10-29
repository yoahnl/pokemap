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
    this.modelInstances = const [],
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
  final List<SpatialModelInstance> modelInstances;
  bool get isSpatial => result.materialization?.targetsSpatialScene == true;
  late final String fingerprint;

  static const maximumWarningPreviewCount = 128;

  List<Map<String, Object?>> get warningPreview => [
        for (final diagnostic in result.diagnostics)
          if (diagnostic.severity == BorderDiagnosticSeverity.warning)
            {
              'layerId': layerId,
              'featureId': featureId,
              'code': diagnostic.code,
              if (diagnostic.slotKey != null) 'slotKey': diagnostic.slotKey,
              if (diagnostic.cell case final cell?)
                'cell': {'x': cell.x, 'y': cell.y},
              if (diagnostic.parameters.isNotEmpty)
                'parameters': diagnostic.parameters,
              'suggestedAction': diagnostic.suggestedAction,
            },
      ];

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
        'placementCount': (result.materialization?.placements.length ?? 0) +
            modelInstances.length,
        'visualKind': isSpatial ? 'model3d' : 'element',
        'groundCellCount': result.materialization?.ground.length ?? 0,
        'inputFingerprint':
            result.materialization?.receipt.inputFingerprint ?? '',
        'outputFingerprint':
            result.materialization?.receipt.outputFingerprint ?? '',
        if (isSpatial)
          'modelInstances':
              modelInstances.map((instance) => instance.toJson()).toList(),
      };

  Map<String, Object?> toJson() => {
        ..._payload(),
        'fingerprint': fingerprint,
      };
}

/// Pure adapter over the canonical Border operations owned by `map_core`.
final class BorderActions {
  const BorderActions();

  MapData setForeground(MapData map, {
    required String layerId,
    required bool renderInForeground,
  }) => setBorderLayerForeground(map,
      layerId: layerId, renderInForeground: renderInForeground);

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor('border_layer.set_foreground', 'Place Border props in front of actors while keeping their ground behind'),
    _descriptor('border_layer.stroke_add', 'Add a Border feature stroke'),
    _descriptor('border_layer.stroke_update', 'Update a Border feature stroke'),
    _descriptor('border_layer.stroke_delete', 'Delete a Border feature stroke'),
    _descriptor('border_layer.stroke_erase', 'Erase local Border stroke cells and rematerialize atomically'),
    _descriptor('border_layer.region_fill', 'Fill a Border region mask'),
    _descriptor('border_layer.region_clear', 'Clear a Border region mask'),
    _descriptor('border_layer.feature_create', 'Create a Border feature with an optional line side'),
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
    _descriptor('border_layer.feature_set_replacement', 'Replace a generated Border slot primitive'),
    _descriptor('border_layer.feature_set_offset', 'Set a generated Border slot pixel offset'),
    _descriptor('border_layer.feature_set_transform', 'Set a generated Border slot transform'),
    _descriptor('border_layer.feature_set_suppressed', 'Set generated Border slot suppression'),
    _descriptor('border_layer.feature_clear_slot_override', 'Restore a generated Border slot'),
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

  MapData eraseStroke({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required String featureId,
    required List<GridPos> sampledPoints,
  }) {
    final feature = _feature(_borderLayer(map, layerId), featureId);
    final geometry = feature.geometry;
    if (geometry is! BorderStrokeGeometry) {
      throw semanticFailure('border.stroke_geometry_required',
          'Local stroke erasure requires a linear Border feature.');
    }
    if (sampledPoints.isEmpty || sampledPoints.length > 4096) {
      throw semanticFailure('border.stroke_erase_points_invalid',
          'Local stroke erasure requires between 1 and 4096 points.');
    }
    final edge = geometry.alignment == BorderStrokeAlignment.gridEdges ? 1 : 0;
    if (sampledPoints.any((point) => point.x < 0 || point.y < 0 ||
        point.x >= map.size.width + edge || point.y >= map.size.height + edge)) {
      throw semanticFailure('border.stroke_erase_outside_map',
          'Local stroke erasure must remain inside the Border lattice.');
    }
    final definition = manifest.borderCatalog
        .recordById(feature.blueprintId)
        ?.latestPublished
        ?.definition;
    final erased = editStroke(geometry, mode: BorderStrokeEditingMode.erase,
        sampledPoints: sampledPoints,
        preserveTraversal: definition == null || definition.sequenceLength == 1 ||
            definition.followContourDirection);
    if (erased == geometry) return map;
    if (erased.strokes.isEmpty) {
      return removeBorderFeature(map, layerId: layerId, featureId: featureId);
    }
    final revision = requirePublishedBlueprint(manifest, feature.blueprintId);
    if (!manifest.resourceLibraryCatalog.availableForMap(
        'borderBlueprint', feature.blueprintId, map.id) ||
        revision.definition.primitives.any((primitive) =>
            !manifest.resourceLibraryCatalog.availableForMap(
                primitive.sourceModelId == null ? 'element' : 'model3d',
                primitive.sourceModelId ?? primitive.sourceElementId!, map.id))) {
      throw semanticFailure('border.source_unavailable',
          'The Border or one of its visual sources is unavailable in this map.');
    }
    if (revision.definition.isSpatial != (map.spatialScene != null)) {
      throw semanticFailure('border.dimension_mismatch',
          'The Border visual sources do not match the map dimension.');
    }
    if (map.spatialScene != null) {
      var proposed = updateBorderFeatureGeometry(map, layerId: layerId,
          featureId: featureId, geometry: erased);
      var resolved = resolveSpatialBorderFeature(manifest: manifest,
          map: proposed, layerId: layerId, featureId: featureId);
      final removedSlots = resolved.result.diagnostics
          .where((issue) => issue.code == 'border.spatial.override_slot_missing')
          .map((issue) => issue.slotKey).toSet();
      if (removedSlots.isNotEmpty) {
        proposed = updateBorderFeatureOverrides(proposed, layerId: layerId,
            featureId: featureId, overrides: feature.overrides
                .where((override) => !removedSlots.contains(override.slotKey)).toList());
        resolved = resolveSpatialBorderFeature(manifest: manifest,
            map: proposed, layerId: layerId, featureId: featureId);
      }
      if (!resolved.result.canApply) {
        throw semanticFailure('border.stroke_erase_resolution_failed',
            'Border diagnostics prevent atomic local erasure.',
            details: {'diagnostics': resolved.result.diagnostics.map((issue) => issue.code).toList()});
      }
      return applySpatialBorderFeaturePreview(proposed, manifest: manifest,
          proposedResult: resolved);
    }
    var proposed = updateBorderFeatureGeometry(map, layerId: layerId,
        featureId: featureId, geometry: erased);
    var changed = _feature(_borderLayer(proposed, layerId), featureId);
    BorderResolutionRequest requestFor(BorderFeature value) => BorderResolutionRequest(mapSize: map.size,
        tileSizePx: GridSize(width: manifest.settings.tileWidth,
            height: manifest.settings.tileHeight), blueprintId: feature.blueprintId,
        blueprintRevision: revision, feature: value,
        visualSnapshots: manifest.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion);
    var request = requestFor(changed);
    var resolved = resolveBorderFeature(request);
    final removedSlots = resolved.diagnostics
        .where((issue) => issue.code == 'border.resolution.override_orphaned')
        .map((issue) => issue.slotKey).toSet();
    if (removedSlots.isNotEmpty) {
      proposed = updateBorderFeatureOverrides(proposed, layerId: layerId,
          featureId: featureId, overrides: feature.overrides
              .where((override) => !removedSlots.contains(override.slotKey)).toList());
      changed = _feature(_borderLayer(proposed, layerId), featureId);
      request = requestFor(changed);
      resolved = resolveBorderFeature(request);
    }
    if (!resolved.canApply) {
      throw semanticFailure('border.stroke_erase_resolution_failed',
          'Border diagnostics prevent atomic local erasure.',
          details: {'diagnostics': resolved.diagnostics.map((issue) => issue.code).toList()});
    }
    return applyBorderFeaturePreview(proposed, expectedMapId: map.id,
        layerId: layerId, featureId: featureId,
        expectedBaseFeatureFingerprint: computeBorderFeatureEditFingerprint(changed),
        proposedRequest: request, proposedResult: resolved);
  }

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
    bool preserveTraversal = true,
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
      preserveTraversal: preserveTraversal,
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

  BorderBlueprintRevision _requirePlaceableBlueprint(
      ProjectManifest manifest, String blueprintId) {
    final revision = requirePublishedBlueprint(manifest, blueprintId);
    if (manifest.borderCatalog.recordById(blueprintId)!.isDeprecated) {
      throw semanticFailure('border.blueprint_deprecated',
          'This Border blueprint is unavailable for new placements.', details: {
        'blueprintId': blueprintId
      }, remediation: const [
        'Reactivate the blueprint before placing new features.'
      ]);
    }
    return revision;
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
    if (revision.definition.isSpatial != (map.spatialScene != null)) {
      throw semanticFailure('border.visual_dimension_mismatch',
          'The Border blueprint must match the map dimension.');
    }
    if (revision.definition.isSpatial) {
      final resolved = resolveSpatialBorderFeature(
          manifest: manifest,
          map: map,
          layerId: layerId,
          featureId: featureId,
          resolverVersion: resolverVersion);
      return BorderPreviewArtifact(
          mapId: map.id,
          layerId: layerId,
          featureId: featureId,
          projectRevision: projectRevision,
          seed: feature.seed.toString(),
          blueprintId: feature.blueprintId,
          blueprintRevision: revision.revision,
          resolverVersion: resolverVersion,
          result: resolved.result,
          modelInstances: resolved.modelInstances);
    }
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
  }) {
    if (map.spatialScene != null) {
      throw semanticFailure('border.spatial.relink_unsupported',
          'Native Border features require their current blueprint. Edit its model kit and regenerate, or create a feature with another blueprint.');
    }
    return prepareBorderFeatureRelink(
      map: map,
      layerId: layerId,
      featureId: featureId,
      targetBlueprintId: targetBlueprintId,
      targetBlueprintRevision:
          _requirePlaceableBlueprint(manifest, targetBlueprintId),
      visualSnapshots: manifest.borderCatalog.visualSnapshots,
      tileSizePx: tileSizePx,
      resolverVersion: resolverVersion,
    );
  }

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
      'border_layer.set_foreground' => const {'layerId', 'renderInForeground'},
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
      'border_layer.stroke_erase' => const {'layerId', 'featureId', 'points'},
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
          'lineSide',
          'spatialOffsetWorld',
        },
      'border_layer.feature_update' => const {
          'layerId',
          'featureId',
          'name',
          'seed',
          'lineSide',
          'paramsOverride',
          'spatialOffsetWorld',
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
      'border_layer.feature_set_replacement' => const {'layerId', 'featureId', 'slotKey', 'primitiveId'},
      'border_layer.feature_set_offset' => const {'layerId', 'featureId', 'slotKey', 'offsetDeltaPx'},
      'border_layer.feature_set_transform' => const {'layerId', 'featureId', 'slotKey', 'transformOverride'},
      'border_layer.feature_set_suppressed' => const {'layerId', 'featureId', 'slotKey', 'suppressed'},
      'border_layer.feature_clear_slot_override' => const {'layerId', 'featureId', 'slotKey'},
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
      case 'border_layer.set_foreground':
        updated = setForeground(context.map,
            layerId: layerId,
            renderInForeground: parameters.boolean('renderInForeground'));
      case 'border_layer.stroke_erase':
        updated = eraseStroke(manifest: context.manifest, map: context.map,
            layerId: layerId, featureId: parameters.string('featureId'),
            sampledPoints: _points(parameters.list('points')));
        if (identical(updated, context.map)) {
          throw semanticFailure('map.no_change', 'The Border erasure touches no stroke cells.');
        }
        final changed = _borderLayer(updated, layerId).content.featureById(parameters.string('featureId'));
        extraPreview['strokeCount'] = changed?.geometry is BorderStrokeGeometry
            ? (changed!.geometry as BorderStrokeGeometry).strokes.length : 0;
        extraPreview['featureRemoved'] = changed == null;
      case 'border_layer.stroke_add':
      case 'border_layer.stroke_update':
        final featureId = parameters.string('featureId');
        final layer = _borderLayer(context.map, layerId);
        final feature = _feature(layer, featureId);
        if (actionId == 'border_layer.stroke_add') {
          _requirePlaceableBlueprint(context.manifest, feature.blueprintId);
        }
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
        if (actionId == 'border_layer.region_fill') {
          _requirePlaceableBlueprint(context.manifest, feature.blueprintId);
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
        final revision = _requirePlaceableBlueprint(
          context.manifest,
          blueprintId,
        );
        final geometry = _geometry(parameters.object('geometry'));
        final lineSide = parameters.contains('lineSide')
            ? _lineSide(parameters.string('lineSide'))
            : BorderLineSide.primary;
        _requireSequenceSide(revision.definition, lineSide);
        if (revision.definition.isSpatial !=
            (context.map.spatialScene != null)) {
          throw semanticFailure('border.visual_dimension_mismatch',
              'The Border blueprint must match the map dimension.');
        }
        if (!revision.definition.isSpatial &&
            borderGeometryFamily(geometry) !=
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
            lineSide: lineSide,
            spatialOffsetWorld: _spatialOffsetWorld(parameters, context.map),
            overrides: const [],
            keepOutRegions: const [],
          ),
          template: revision.definition.isSpatial
              ? null
              : revision.definition.template,
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
        _requireSequenceSide(
            context.manifest.borderCatalog.recordById(feature.blueprintId)
                ?.latestPublished?.definition,
            lineSide == null ? feature.lineSide : _lineSide(lineSide));
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
            spatialOffsetWorld: _spatialOffsetWorld(parameters, context.map),
            replaceSpatialOffset: parameters.contains('spatialOffsetWorld'),
            paramsOverride: clear ? null : params,
            replaceParams: clear || parameters.contains('paramsOverride'),
          ),
        );
      case 'border_layer.feature_move':
        final featureId = parameters.string('featureId');
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        final dx = parameters.integer('dx');
        final dy = parameters.integer('dy');
        final geometry = _translateGeometry(feature.geometry,
            dx: dx, dy: dy, mapSize: context.map.size);
        updated = context.map.spatialScene == null
            ? updateBorderFeatureGeometry(context.map,
                layerId: layerId, featureId: featureId, geometry: geometry)
            : moveSpatialBorderFeature(context.map, manifest: context.manifest,
                layerId: layerId, featureId: featureId, geometry: geometry, dx: dx, dz: dy);
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
          lockedInstanceId: current?.lockedInstanceId,
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
      case 'border_layer.feature_set_replacement':
      case 'border_layer.feature_set_offset':
      case 'border_layer.feature_set_transform':
      case 'border_layer.feature_set_suppressed':
      case 'border_layer.feature_clear_slot_override':
        updated = _setSlotOverride(context.manifest, context.map,
            layerId: layerId, featureId: parameters.string('featureId'),
            slotKey: parameters.string('slotKey'), actionId: actionId,
            parameters: parameters);
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
          tileSizePx: context.map.spatialScene == null
              ? _tileSize(parameters)
              : GridSize(
                  width: context.manifest.settings.tileWidth,
                  height: context.manifest.settings.tileHeight),
          resolverVersion: parameters.contains('resolverVersion')
              ? parameters.integer('resolverVersion')
              : borderResolverVersion,
        );
        if (!artifact.result.canApply) {
          throw semanticFailure(
            'border.materialization_failed',
            'Border resolution diagnostics prevent materialization.',
            details: {
              'diagnosticCount': artifact.result.diagnostics.length,
              'errorCount': artifact.result.diagnosticReport.errorCount,
              'diagnostics': [
                for (final diagnostic in artifact.result.diagnostics)
                  {
                    'code': diagnostic.code,
                    'severity': diagnostic.severity.name,
                    if (diagnostic.blueprintId != null)
                      'blueprintId': diagnostic.blueprintId,
                    if (diagnostic.featureId != null)
                      'featureId': diagnostic.featureId,
                    'suggestedAction': diagnostic.suggestedAction,
                  }
              ],
            },
          );
        }
        final warnings = artifact.warningPreview;
        extraPreview['warningCount'] = warnings.length;
        extraPreview['warnings'] = warnings
            .take(BorderPreviewArtifact.maximumWarningPreviewCount)
            .toList();
        if (warnings.length > BorderPreviewArtifact.maximumWarningPreviewCount) {
          extraPreview['warningsTruncated'] = true;
        }
        if (artifact.isSpatial) {
          updated = applySpatialBorderFeaturePreview(context.map,
              manifest: context.manifest,
              proposedResult: SpatialBorderResolutionResult(
                  mapId: context.map.id,
                  layerId: layerId,
                  featureId: featureId,
                  result: artifact.result,
                  modelInstances: artifact.modelInstances));
          extraPreview['borderPreview'] = artifact.toJson();
          changedItems = artifact.modelInstances.length;
          break;
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
        if (context.map.spatialScene != null) {
          throw semanticFailure('border.spatial.use_spatial_resize',
              'Resize the spatial terrain through the spatial map operation.');
        }
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

    if (updated.spatialScene != null && parameters.contains('featureId')) {
      final feature = _borderLayer(updated, layerId).content.featureById(
          parameters.string('featureId'));
      if (feature != null) {
        final revision = requirePublishedBlueprint(context.manifest, feature.blueprintId);
        final geometryDiagnostics = validateSpatialBorderFeatureGeometry(
            blueprintId: feature.blueprintId, featureId: feature.id,
            definition: revision.definition, geometry: feature.geometry);
        if (geometryDiagnostics.hasErrors) {
          final diagnostic = geometryDiagnostics.diagnostics.firstWhere(
              (value) => value.severity == BorderDiagnosticSeverity.error);
          throw semanticFailure(diagnostic.code,
              diagnostic.code == 'border.spatial.ground_mask_cell_centers_required'
                  ? 'Ground masking requires a cell-centered Border stroke.'
                  : 'This Border profile accepts straight strokes only.',
              details: {'blueprintId': feature.blueprintId, 'featureId': feature.id});
        }
        if (feature.spatialOffsetWorld != null) {
          final resolved = resolveSpatialBorderFeature(manifest: context.manifest,
              map: updated, layerId: layerId, featureId: feature.id);
          if (resolved.result.diagnosticReport.hasErrors) {
            throw semanticFailure('border.spatial.offset_invalid',
                'The spatial Border offset must produce valid native placements.',
                details: {'diagnostics': resolved.result.diagnostics.map((value) => value.code).toList()});
          }
        }
      }
    }
    for (final layer in updated.layers.whereType<BorderLayer>()) {
      for (final feature in layer.content.features) {
        final revision = context.manifest.borderCatalog
            .recordById(feature.blueprintId)
            ?.latestPublished;
        if (revision?.definition.template !=
                BorderBlueprintTemplate.horizontalFacade ||
            feature.geometry is! BorderStrokeGeometry ||
            (feature.geometry as BorderStrokeGeometry).strokes.isEmpty) {
          continue;
        }
        final result = resolveBorderFeature(BorderResolutionRequest(
          mapSize: updated.size,
          tileSizePx: GridSize(
              width: context.manifest.settings.tileWidth,
              height: context.manifest.settings.tileHeight),
          blueprintId: feature.blueprintId,
          blueprintRevision: revision,
          feature: feature,
          visualSnapshots: context.manifest.borderCatalog.visualSnapshots,
          resolverVersion: borderResolverVersion,
        ));
        if (!result.canApply) {
          throw semanticFailure('border.horizontal_facade_invalid',
              'Horizontal facades require open horizontal strokes without rotation or mirroring.',
              details: {
                'diagnostics': result.diagnostics.map((d) => d.code).toList()
              });
        }
      }
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
    AuthoringActionDescriptor(
        id: id,
        version: 1,
        summary: summary,
        inputSchemaId: 'schema.$id.input.v1',
        outputSchemaId: 'schema.map.semantic_mutation.output.v1',
        riskLevel: AuthoringRiskLevel.low,
        resourceKinds: const [
          'map',
          'borderBlueprint',
          'model3d',
          'element'
        ],
        requiredPermissions: const [
          AuthoringPermission.projectWrite
        ],
        guarantees: const [
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable
        ],
        extensions: {
          if (id == 'border_layer.set_foreground') 'inputSchema': {
            'type': 'object', 'additionalProperties': false,
            'required': ['mapId', 'layerId', 'renderInForeground'],
            'properties': {
              for (final key in ['mapId', 'layerId'])
                key: const {'type': 'string', 'minLength': 1},
              'renderInForeground': const {'type': 'boolean'},
            },
          },
          if (_slotOverrideField(id) != null || id == 'border_layer.feature_clear_slot_override')
            'inputSchema': _slotOverrideInputSchema(id),
          'semanticIds': true,
          'rawTilesetRequired': false,
          'visualKinds': id == 'border_layer.feature_set_offset' || id == 'border_layer.set_foreground'
              ? const ['element'] : const ['element', 'model3d'],
          if (id == 'border_layer.stroke_erase') 'inputSchema': {
            'type': 'object', 'additionalProperties': false,
            'required': ['mapId', 'layerId', 'featureId', 'points'],
            'properties': {
              for (final key in ['mapId', 'layerId', 'featureId'])
                key: const {'type': 'string', 'minLength': 1},
              'points': const {'type': 'array', 'minItems': 1, 'maxItems': 4096,
                'items': {'type': 'object', 'additionalProperties': false,
                  'required': ['x', 'y'], 'properties': {
                    'x': {'type': 'integer', 'minimum': 0},
                    'y': {'type': 'integer', 'minimum': 0}}}},
            },
          },
          if (id == 'border_layer.feature_create' || id == 'border_layer.feature_update')
            'inputSchema': _featureInputSchema(id == 'border_layer.feature_create'),
        });

String? _slotOverrideField(String id) => switch (id) {
  'border_layer.feature_set_replacement' => 'primitiveId',
  'border_layer.feature_set_offset' => 'offsetDeltaPx',
  'border_layer.feature_set_transform' => 'transformOverride',
  'border_layer.feature_set_suppressed' => 'suppressed',
  _ => null,
};

Map<String, Object?> _slotOverrideInputSchema(String id) {
  final field = _slotOverrideField(id);
  return {
    'type': 'object', 'additionalProperties': false,
    'required': ['mapId', 'layerId', 'featureId', 'slotKey', if (field != null) field],
    'properties': {
      for (final key in ['mapId', 'layerId', 'featureId', 'slotKey'])
        key: const {'type': 'string', 'minLength': 1},
      if (field == 'primitiveId') field!: const {'type': ['string', 'null'], 'minLength': 1},
      if (field == 'suppressed') field!: const {'type': 'boolean'},
      if (field == 'offsetDeltaPx') field!: const {'anyOf': [
        {'type': 'null'},
        {'type': 'object', 'additionalProperties': false, 'required': ['x', 'y'],
          'properties': {'x': {'type': 'integer'}, 'y': {'type': 'integer'}}},
      ]},
      if (field == 'transformOverride') field!: const {'anyOf': [
        {'type': 'null'},
        {'type': 'object', 'additionalProperties': false, 'required': ['quarterTurns', 'flipX'],
          'properties': {'quarterTurns': {'type': 'integer', 'minimum': 0, 'maximum': 3},
            'flipX': {'type': 'boolean'}}},
      ]},
    },
  };
}

Map<String, Object?> _featureInputSchema(bool create) => {
  'type': 'object',
  'additionalProperties': false,
  'required': ['mapId', 'layerId', 'featureId', if (create) ...['name', 'blueprintId', 'seed', 'geometry']],
  'properties': {
    'mapId': const {'type': 'string', 'minLength': 1},
    'layerId': const {'type': 'string', 'minLength': 1},
    'featureId': const {'type': 'string', 'minLength': 1},
    'name': const {'type': 'string', 'minLength': 1},
    'seed': const {'type': ['string', 'integer']},
    'lineSide': const {'type': 'string', 'enum': ['primary', 'inverted'], 'default': 'primary'},
    'spatialOffsetWorld': const {'anyOf': [
      {'type': 'null'},
      {'type': 'object', 'additionalProperties': false, 'required': ['x', 'y', 'z'],
        'properties': {'x': {'type': 'number'}, 'y': {'type': 'number'}, 'z': {'type': 'number'}}},
    ]},
    if (create) 'blueprintId': const {'type': 'string', 'minLength': 1},
    if (create) 'geometry': const {'type': 'object'},
    if (!create) 'paramsOverride': const {'type': 'object'},
    if (!create) 'clearParamsOverride': const {'type': 'boolean'},
  },
};

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
  Model3dVector3? spatialOffsetWorld,
  bool replaceSpatialOffset = false,
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
      spatialOffsetWorld: replaceSpatialOffset ? spatialOffsetWorld : feature.spatialOffsetWorld,
      paramsOverride: replaceParams ? paramsOverride : feature.paramsOverride,
      overrides: overrides ?? feature.overrides,
      keepOutRegions: keepOutRegions ?? feature.keepOutRegions,
      materialization: clearMaterialization &&
              feature.materialization?.targetsSpatialScene != true
          ? null
          : materialization ?? feature.materialization,
    );

Model3dVector3? _spatialOffsetWorld(SemanticParameters parameters, MapData map) {
  if (!parameters.contains('spatialOffsetWorld')) return null;
  if (map.spatialScene == null) {
    throw semanticFailure('border.spatial.map_required', 'A spatial Border offset requires a 3D map.');
  }
  if (parameters.value('spatialOffsetWorld') == null) return null;
  final value = parameters.object('spatialOffsetWorld');
  if (value.length != 3 || !const {'x', 'y', 'z'}.every(value.containsKey) ||
      value.values.any((item) => item is! num || !item.isFinite)) {
    throw invalidSemanticField('spatialOffsetWorld', 'a finite {x, y, z} world offset');
  }
  return Model3dVector3.fromJson(value);
}

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

void _requireSequenceSide(
  BorderBlueprintPublishedDefinition? definition,
  BorderLineSide lineSide,
) {
  if (definition != null && definition.sequenceLength > 1 &&
      lineSide != BorderLineSide.primary) {
    throw semanticFailure('border.spatial.line_side_inversion_unsupported',
        'A cyclic spatial Border requires its authored primary side.');
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
        final lineage = resolveBorderStrokeLineageIdentityV1(stroke);
        final id = lineage.preserveTraversal
            ? buildBorderPreservedStrokeIdV1(
                authoredStrokeId: lineage.authoredStrokeId,
                sourceEdgeOffset: lineage.sourceEdgeOffset,
                wrapLength: lineage.wrapLength,
                orderedPoints: points)
            : stroke.id;
        strokes.add(
          BorderStroke(id: id, points: points, closed: stroke.closed),
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

MapData _setSlotOverride(ProjectManifest manifest, MapData map, {
  required String layerId, required String featureId, required String slotKey,
  required String actionId, required SemanticParameters parameters,
}) {
  final feature = _feature(_borderLayer(map, layerId), featureId);
  final revision = const BorderActions().requirePublishedBlueprint(manifest, feature.blueprintId);
  final spatial = revision.definition.isSpatial && map.spatialScene != null;
  if (revision.definition.isSpatial != (map.spatialScene != null) ||
      spatial && actionId == 'border_layer.feature_set_offset') {
    throw semanticFailure('border.spatial.sprite_override_unsupported',
        'Pixel slot corrections require a planar Border feature.');
  }
  final tileSize = GridSize(width: manifest.settings.tileWidth, height: manifest.settings.tileHeight);
  BorderResolutionRequest requestFor(BorderFeature value) => BorderResolutionRequest(
      mapSize: map.size, tileSizePx: tileSize, blueprintId: feature.blueprintId,
      blueprintRevision: revision, feature: value,
      visualSnapshots: manifest.borderCatalog.visualSnapshots,
      resolverVersion: borderResolverVersion);
  final baseFeature = _copyFeature(feature, overrides: const [], keepOutRegions: const []);
  Set<String> slots;
  try {
    if (spatial) {
      final baseMap = upsertBorderFeature(map, layerId: layerId, feature: baseFeature);
      slots = resolveSpatialBorderFeatureBaseSlotKeys(
          manifest: manifest, map: baseMap,
          layerId: layerId, featureId: featureId);
    } else {
      slots = resolveBorderFeatureBaseSlotKeys(requestFor(baseFeature));
    }
  } on ValidationException catch (error) {
    throw semanticFailure('border.slot_generation_failed', error.toString());
  }
  if (!slots.contains(slotKey)) {
    throw semanticFailure('border.slot_missing', 'The requested generated Border slot does not exist.',
        details: {'slotKey': slotKey});
  }
  final overrides = List<BorderSlotOverride>.from(feature.overrides);
  final index = overrides.indexWhere((value) => value.slotKey == slotKey);
  final current = index < 0 ? null : overrides[index];
  if (current?.locked == true) {
    throw semanticFailure('border.slot_locked', 'Unlock the Border slot before changing its corrections.',
        details: {'slotKey': slotKey});
  }
  final clear = actionId == 'border_layer.feature_clear_slot_override';
  final field = _slotOverrideField(actionId);
  if (field != null && !parameters.contains(field)) {
    throw invalidSemanticField(field, 'an explicitly provided value or null');
  }
  final suppression = field == 'suppressed' ? parameters.boolean('suppressed') : current?.suppressed ?? false;
  if (!clear && suppression && field != 'suppressed') {
    throw semanticFailure('border.slot_suppressed', 'Restore the Border slot before changing its corrections.',
        details: {'slotKey': slotKey});
  }
  final offset = field == 'offsetDeltaPx' && parameters.value(field!) != null
      ? SemanticParameters(parameters.object(field), allowed: const {'x', 'y'}) : null;
  final transform = field == 'transformOverride' && parameters.value(field!) != null
      ? SemanticParameters(parameters.object(field), allowed: const {'quarterTurns', 'flipX'}) : null;
  final turns = transform?.integer('quarterTurns');
  if (turns != null && (turns < 0 || turns > 3)) {
    throw invalidSemanticField('quarterTurns', 'an integer between zero and three');
  }
  if (spatial && transform?.boolean('flipX') == true) {
    throw semanticFailure('border.spatial.sprite_override_unsupported',
        'Spatial Border corrections do not support sprite mirroring.');
  }
  final replacement = BorderSlotOverride(
      slotKey: slotKey, variationSalt: current?.variationSalt ?? BorderSignedInt64.zero,
      suppressed: suppression, locked: false,
      replacementPrimitiveId: suppression ? null : field == 'primitiveId'
          ? parameters.optionalString('primitiveId') : current?.replacementPrimitiveId,
      offsetDeltaPx: suppression ? null : field == 'offsetDeltaPx'
          ? offset == null ? null : BorderPixelOffset(x: offset.integer('x'), y: offset.integer('y'))
          : current?.offsetDeltaPx,
      transformOverride: suppression ? null : field == 'transformOverride'
          ? transform == null ? null : BorderSpriteTransform(quarterTurns: turns!, flipX: transform.boolean('flipX'))
          : current?.transformOverride);
  if (clear) {
    if (index >= 0) overrides.removeAt(index);
  } else if (index < 0) {
    overrides.add(replacement);
  } else {
    overrides[index] = replacement;
  }
  if (spatial || !clear) {
    final corrected = spatial
        ? _copyFeature(feature, keepOutRegions: const [], overrides: overrides)
        : _copyFeature(baseFeature, overrides: [replacement]);
    final diagnostics = spatial
        ? resolveSpatialBorderFeature(manifest: manifest,
            map: upsertBorderFeature(map, layerId: layerId, feature: corrected),
            layerId: layerId, featureId: featureId).result.diagnostics
        : resolveBorderFeature(requestFor(corrected)).diagnostics;
    final errors = diagnostics.where((issue) => issue.severity == BorderDiagnosticSeverity.error &&
        (spatial || issue.code.startsWith('border.resolution.override_'))).toList();
    if (errors.isNotEmpty) {
      throw semanticFailure(errors.first.code, 'The requested Border slot correction is invalid.',
          details: {'slotKey': slotKey, 'diagnostics': errors.map((issue) => issue.code).toList()});
    }
  }
  return updateBorderFeatureOverrides(map, layerId: layerId, featureId: featureId, overrides: overrides);
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
    final spatialPlacement = feature.materialization?.spatialPlacements
        .where((value) => value.slotKey == slotKey)
        .firstOrNull;
    if (placement == null && spatialPlacement == null) {
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
      lockedInstanceId: spatialPlacement?.instanceId,
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
