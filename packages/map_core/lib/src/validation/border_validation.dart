import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/geometry.dart';
import '../models/project_manifest.dart';
import '../operations/border_materialization_freshness.dart';
import '../operations/border_rle_codec.dart';

enum BorderBlueprintValidationPurpose {
  authoring,
  publication,
  resolution,
}

enum BorderFeatureValidationPurpose {
  authoring,
  resolution,
  playExport,
}

/// Diagnoses recoverable draft and published-blueprint problems.
BorderDiagnosticsReport diagnoseBorderBlueprint(
  BorderBlueprintRecord record, {
  required ProjectManifest project,
  required BorderBlueprintValidationPurpose purpose,
  required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
}) {
  final diagnostics = <BorderDiagnostic>[];
  final phase = _blueprintPhase(purpose);
  if (purpose != BorderBlueprintValidationPurpose.resolution) {
    final draft = record.draft.definition;
    _diagnoseDuplicatePrimitiveIds(
      draft.primitives,
      idOf: (primitive) => primitive.id,
      blueprintId: record.id,
      phase: phase,
      diagnostics: diagnostics,
    );
    final elementIds = <String>{
      for (final element in project.elements) element.id
    };
    for (final primitive in draft.primitives) {
      if (!elementIds.contains(primitive.sourceElementId)) {
        diagnostics.add(_diagnostic(
          code: 'border.blueprint.source_element_missing',
          severity: BorderDiagnosticSeverity.error,
          phase: phase,
          scope: BorderDiagnosticScope.primitive,
          blueprintId: record.id,
          parameters: <String, Object?>{
            'primitiveId': primitive.id,
            'sourceElementId': primitive.sourceElementId,
          },
          action: 'border.action.select_existing_source_element',
        ));
      }
      _diagnoseMetrics(
        primitiveId: primitive.id,
        metrics: primitive.currentMetrics,
        anchorX: primitive.anchorPx.x,
        anchorY: primitive.anchorPx.y,
        blueprintId: record.id,
        phase: phase,
        diagnostics: diagnostics,
      );
    }
    final ground = draft.ground;
    if (ground != null &&
        project.surfaceCatalog.presetById(ground.sourceSurfacePresetId) ==
            null) {
      diagnostics.add(_diagnostic(
        code: 'border.blueprint.source_surface_preset_missing',
        severity: BorderDiagnosticSeverity.error,
        phase: phase,
        scope: BorderDiagnosticScope.blueprint,
        blueprintId: record.id,
        parameters: <String, Object?>{
          'sourceSurfacePresetId': ground.sourceSurfacePresetId,
        },
        action: 'border.action.select_existing_surface_preset',
      ));
    }
  }

  final published = record.latestPublished;
  if (published == null) {
    if (purpose == BorderBlueprintValidationPurpose.resolution) {
      diagnostics.add(_diagnostic(
        code: 'border.blueprint.not_published',
        severity: BorderDiagnosticSeverity.error,
        phase: phase,
        scope: BorderDiagnosticScope.blueprint,
        blueprintId: record.id,
        action: 'border.action.publish_blueprint',
      ));
    }
  } else {
    final definition = published.definition;
    _diagnoseDuplicatePrimitiveIds(
      definition.primitives,
      idOf: (primitive) => primitive.id,
      blueprintId: record.id,
      phase: phase,
      diagnostics: diagnostics,
    );
    for (final primitive in definition.primitives) {
      _diagnoseMetrics(
        primitiveId: primitive.id,
        metrics: primitive.publishedMetrics,
        anchorX: primitive.anchorPx.x,
        anchorY: primitive.anchorPx.y,
        blueprintId: record.id,
        phase: phase,
        diagnostics: diagnostics,
      );
    }
    final ground = definition.ground;
    final referencedSnapshotIds = <String>{
      for (final primitive in definition.primitives) primitive.visualSnapshotId,
      if (ground != null) ...ground.visualSnapshotIdsByRole.values,
    }.toList(growable: false)
      ..sort();
    for (final id in referencedSnapshotIds) {
      _diagnoseSnapshotReference(
        id,
        available: project.borderCatalog.visualSnapshots,
        integrity: snapshotIntegrity,
        blueprintId: record.id,
        phase: phase,
        diagnostics: diagnostics,
      );
    }
  }
  return BorderDiagnosticsReport(diagnostics: diagnostics);
}

/// Diagnoses feature intent, references, persisted output, and freshness.
BorderDiagnosticsReport diagnoseBorderFeature(
  BorderResolutionRequest request, {
  required BorderMaterialization? materialization,
  required BorderFeatureValidationPurpose purpose,
  required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
}) {
  final diagnostics = <BorderDiagnostic>[];
  final phase = _featurePhase(purpose);
  final revision = request.blueprintRevision;
  if (revision == null) {
    diagnostics.add(_diagnostic(
      code: 'border.feature.blueprint_unavailable',
      severity: purpose == BorderFeatureValidationPurpose.resolution
          ? BorderDiagnosticSeverity.error
          : BorderDiagnosticSeverity.warning,
      phase: phase,
      scope: BorderDiagnosticScope.feature,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      action: 'border.action.relink_published_blueprint',
    ));
  }

  _diagnoseFeatureGeometry(
    request,
    purpose: purpose,
    phase: phase,
    diagnostics: diagnostics,
  );
  if (revision != null) {
    _diagnoseFeatureReferences(
      request,
      purpose: purpose,
      snapshotIntegrity: snapshotIntegrity,
      phase: phase,
      diagnostics: diagnostics,
    );
  }
  _diagnoseMaterialization(
    request,
    materialization: materialization,
    purpose: purpose,
    snapshotIntegrity: snapshotIntegrity,
    phase: phase,
    diagnostics: diagnostics,
  );
  return BorderDiagnosticsReport(diagnostics: diagnostics);
}

void _diagnoseFeatureGeometry(
  BorderResolutionRequest request, {
  required BorderFeatureValidationPurpose purpose,
  required BorderDiagnosticPhase phase,
  required List<BorderDiagnostic> diagnostics,
}) {
  final geometry = request.feature.geometry;
  final template = request.blueprintRevision?.definition.template;
  final expectsRegion = switch (template) {
    null || BorderBlueprintTemplate.organicEdge => true,
    BorderBlueprintTemplate.masonryLine ||
    BorderBlueprintTemplate.postAndRailLine ||
    BorderBlueprintTemplate.connectedLine =>
      false,
  };
  final intentErrorSeverity =
      purpose == BorderFeatureValidationPurpose.playExport
          ? BorderDiagnosticSeverity.warning
          : BorderDiagnosticSeverity.error;
  final compatible = template == null ||
      (expectsRegion && geometry is BorderRegionGeometry) ||
      (!expectsRegion && geometry is BorderStrokeGeometry);
  if (!compatible) {
    diagnostics.add(_diagnostic(
      code: 'border.feature.geometry_template_mismatch',
      severity: intentErrorSeverity,
      phase: phase,
      scope: BorderDiagnosticScope.geometry,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      parameters: <String, Object?>{'template': template.name},
      action: 'border.action.redraw_compatible_geometry',
    ));
  }

  var empty = false;
  switch (geometry) {
    case BorderRegionGeometry(:final width, :final height, :final cells):
      if (width != request.mapSize.width || height != request.mapSize.height) {
        diagnostics.add(_diagnostic(
          code: 'border.feature.region_size_mismatch',
          severity: intentErrorSeverity,
          phase: phase,
          scope: BorderDiagnosticScope.geometry,
          blueprintId: request.blueprintId,
          featureId: request.feature.id,
          parameters: <String, Object?>{
            'regionWidth': width,
            'regionHeight': height,
            'mapWidth': request.mapSize.width,
            'mapHeight': request.mapSize.height,
          },
          action: 'border.action.resize_region_to_map',
        ));
      }
      empty = !cells.contains(true);
    case BorderStrokeGeometry(:final strokes):
      empty = strokes.isEmpty;
      for (final stroke in strokes) {
        for (var index = 0; index < stroke.points.length; index += 1) {
          final point = stroke.points[index];
          if (!_cellInside(point, request.mapSize)) {
            diagnostics.add(_diagnostic(
              code: 'border.feature.stroke_cell_out_of_bounds',
              severity: intentErrorSeverity,
              phase: phase,
              scope: BorderDiagnosticScope.segment,
              blueprintId: request.blueprintId,
              featureId: request.feature.id,
              cell: point,
              strokeId: stroke.id,
              segmentIndex: index,
              action: 'border.action.clip_stroke_to_map',
            ));
          }
        }
      }
  }
  if (empty) {
    diagnostics.add(_diagnostic(
      code: 'border.feature.geometry_empty',
      severity: purpose == BorderFeatureValidationPurpose.authoring ||
              purpose == BorderFeatureValidationPurpose.playExport
          ? BorderDiagnosticSeverity.warning
          : BorderDiagnosticSeverity.error,
      phase: phase,
      scope: BorderDiagnosticScope.geometry,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      action: 'border.action.draw_nonempty_geometry',
    ));
  }
  for (final keepOut in request.feature.keepOutRegions) {
    if (keepOut.region.width != request.mapSize.width ||
        keepOut.region.height != request.mapSize.height) {
      diagnostics.add(_diagnostic(
        code: 'border.feature.keep_out_size_mismatch',
        severity: intentErrorSeverity,
        phase: phase,
        scope: BorderDiagnosticScope.geometry,
        blueprintId: request.blueprintId,
        featureId: request.feature.id,
        parameters: <String, Object?>{
          'keepOutId': keepOut.id,
          'regionWidth': keepOut.region.width,
          'regionHeight': keepOut.region.height,
          'mapWidth': request.mapSize.width,
          'mapHeight': request.mapSize.height,
        },
        action: 'border.action.resize_keep_out_to_map',
      ));
    }
  }
}

void _diagnoseFeatureReferences(
  BorderResolutionRequest request, {
  required BorderFeatureValidationPurpose purpose,
  required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
  required BorderDiagnosticPhase phase,
  required List<BorderDiagnostic> diagnostics,
}) {
  final definition = request.blueprintRevision!.definition;
  final currentInputErrorSeverity =
      purpose == BorderFeatureValidationPurpose.playExport
          ? BorderDiagnosticSeverity.warning
          : BorderDiagnosticSeverity.error;
  final primitiveIds = <String>{};
  for (final primitive in definition.primitives) {
    if (!primitiveIds.add(primitive.id)) {
      diagnostics.add(_diagnostic(
        code: 'border.blueprint.duplicate_primitive_id',
        severity: currentInputErrorSeverity,
        phase: phase,
        scope: BorderDiagnosticScope.primitive,
        blueprintId: request.blueprintId,
        featureId: request.feature.id,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.assign_unique_primitive_ids',
      ));
    }
  }
  if (purpose != BorderFeatureValidationPurpose.playExport) {
    final referenced = <String>{
      for (final primitive in definition.primitives) primitive.visualSnapshotId,
    };
    final ground = definition.ground;
    if (ground != null) {
      referenced.addAll(ground.visualSnapshotIdsByRole.values);
    }
    for (final id in referenced) {
      if (!_snapshotIsValid(
        id,
        available: request.visualSnapshots,
        integrity: snapshotIntegrity,
      )) {
        diagnostics.add(_diagnostic(
          code: 'border.blueprint.visual_snapshot_invalid',
          severity: BorderDiagnosticSeverity.error,
          phase: phase,
          scope: BorderDiagnosticScope.visualSnapshot,
          blueprintId: request.blueprintId,
          featureId: request.feature.id,
          parameters: <String, Object?>{'snapshotId': id},
          action: 'border.action.restore_or_republish_snapshot',
        ));
      }
    }
  }
  for (final override in request.feature.overrides) {
    final replacement = override.replacementPrimitiveId;
    final locked = override.lockedPlacement;
    if ((replacement != null && !primitiveIds.contains(replacement)) ||
        (locked != null && !primitiveIds.contains(locked.primitiveId))) {
      diagnostics.add(_diagnostic(
        code: 'border.feature.override_primitive_missing',
        severity: BorderDiagnosticSeverity.warning,
        phase: phase,
        scope: BorderDiagnosticScope.slot,
        blueprintId: request.blueprintId,
        featureId: request.feature.id,
        slotKey: override.slotKey,
        action: 'border.action.remove_or_retarget_override',
      ));
    }
    if (locked != null &&
        !_snapshotIsValid(
          locked.visualSnapshotId,
          available: request.visualSnapshots,
          integrity: snapshotIntegrity,
        )) {
      diagnostics.add(_diagnostic(
        code: 'border.feature.override_snapshot_missing_or_corrupt',
        severity: currentInputErrorSeverity,
        phase: phase,
        scope: BorderDiagnosticScope.slot,
        blueprintId: request.blueprintId,
        featureId: request.feature.id,
        slotKey: override.slotKey,
        parameters: <String, Object?>{
          'snapshotId': locked.visualSnapshotId,
        },
        action: 'border.action.restore_or_remove_locked_override',
      ));
    }
  }
}

void _diagnoseMaterialization(
  BorderResolutionRequest request, {
  required BorderMaterialization? materialization,
  required BorderFeatureValidationPurpose purpose,
  required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
  required BorderDiagnosticPhase phase,
  required List<BorderDiagnostic> diagnostics,
}) {
  if (materialization == null) {
    diagnostics.add(_diagnostic(
      code: 'border.materialization.missing',
      severity: purpose == BorderFeatureValidationPurpose.playExport
          ? BorderDiagnosticSeverity.error
          : BorderDiagnosticSeverity.info,
      phase: phase,
      scope: BorderDiagnosticScope.materialization,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      action: 'border.action.preview_and_apply_materialization',
    ));
    return;
  }

  final inspection = inspectBorderMaterializationFreshness(
    request,
    materialization: materialization,
    snapshotIntegrity: snapshotIntegrity,
  );
  final freshness = inspection.freshness;
  if (inspection.receiptInputFingerprintValid != true) {
    diagnostics.add(_diagnostic(
      code: 'border.materialization.receipt_input_fingerprint_invalid',
      severity: BorderDiagnosticSeverity.error,
      phase: phase,
      scope: BorderDiagnosticScope.materialization,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      action: 'border.action.regenerate_materialization',
    ));
  }
  if (inspection.outputFingerprintValid != true) {
    diagnostics.add(_diagnostic(
      code: 'border.materialization.output_fingerprint_invalid',
      severity: BorderDiagnosticSeverity.error,
      phase: phase,
      scope: BorderDiagnosticScope.materialization,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      action: 'border.action.restore_or_regenerate_materialization',
    ));
  }

  final outputSnapshots = <String>{};
  for (final cell in materialization.ground) {
    outputSnapshots.add(cell.visualSnapshotId);
    if (!_cellInside(GridPos(x: cell.x, y: cell.y), request.mapSize)) {
      diagnostics.add(_diagnostic(
        code: 'border.materialization.ground_cell_out_of_bounds',
        severity: BorderDiagnosticSeverity.error,
        phase: phase,
        scope: BorderDiagnosticScope.groundCell,
        blueprintId: request.blueprintId,
        featureId: request.feature.id,
        cell: GridPos(x: cell.x, y: cell.y),
        action: 'border.action.regenerate_materialization',
      ));
    }
  }
  final canvasWidth = BigInt.from(request.mapSize.width) *
      BigInt.from(request.tileSizePx.width);
  final canvasHeight = BigInt.from(request.mapSize.height) *
      BigInt.from(request.tileSizePx.height);
  for (final placement in materialization.placements) {
    outputSnapshots.add(placement.visualSnapshotId);
    if (!_cellInside(placement.anchorCell, request.mapSize)) {
      diagnostics.add(_diagnostic(
        code: 'border.materialization.anchor_out_of_bounds',
        severity: BorderDiagnosticSeverity.error,
        phase: phase,
        scope: BorderDiagnosticScope.placement,
        blueprintId: request.blueprintId,
        featureId: request.feature.id,
        slotKey: placement.slotKey,
        cell: placement.anchorCell,
        action: 'border.action.regenerate_materialization',
      ));
    }
    final expectedRowMajor = BigInt.from(placement.anchorCell.y) *
            BigInt.from(request.mapSize.width) +
        BigInt.from(placement.anchorCell.x);
    if (BigInt.from(placement.stableOrderKey.anchorRowMajor) !=
        expectedRowMajor) {
      diagnostics.add(_diagnostic(
        code: 'border.materialization.anchor_row_major_invalid',
        severity: BorderDiagnosticSeverity.error,
        phase: phase,
        scope: BorderDiagnosticScope.placement,
        blueprintId: request.blueprintId,
        featureId: request.feature.id,
        slotKey: placement.slotKey,
        action: 'border.action.regenerate_materialization',
      ));
    }
    final bounds = placement.opaqueWorldBoundsPx;
    if (!_rectIntersectsCanvas(
      bounds.x,
      bounds.y,
      bounds.width,
      bounds.height,
      canvasWidth,
      canvasHeight,
    )) {
      diagnostics.add(_diagnostic(
        code: 'border.materialization.opaque_bounds_outside_canvas',
        severity: BorderDiagnosticSeverity.error,
        phase: phase,
        scope: BorderDiagnosticScope.placement,
        blueprintId: request.blueprintId,
        featureId: request.feature.id,
        slotKey: placement.slotKey,
        action: 'border.action.regenerate_materialization',
      ));
    }
  }
  for (final id in outputSnapshots) {
    if (!_snapshotIsValid(
      id,
      available: request.visualSnapshots,
      integrity: snapshotIntegrity,
    )) {
      diagnostics.add(_diagnostic(
        code: 'border.materialization.snapshot_missing_or_corrupt',
        severity: BorderDiagnosticSeverity.error,
        phase: phase,
        scope: BorderDiagnosticScope.visualSnapshot,
        blueprintId: request.blueprintId,
        featureId: request.feature.id,
        parameters: <String, Object?>{'snapshotId': id},
        action: 'border.action.restore_snapshot',
      ));
    }
  }

  if (freshness.state == BorderMaterializationState.stale) {
    diagnostics.add(_diagnostic(
      code: 'border.materialization.stale',
      severity: BorderDiagnosticSeverity.warning,
      phase: BorderDiagnosticPhase.freshness,
      scope: BorderDiagnosticScope.materialization,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      parameters: <String, Object?>{
        'reasons': <Object?>[
          for (final reason in freshness.reasons) reason.name
        ],
      },
      action: 'border.action.preview_regeneration',
    ));
  } else if (freshness.state == BorderMaterializationState.invalid &&
      !diagnostics.any((diagnostic) =>
          diagnostic.severity == BorderDiagnosticSeverity.error &&
          diagnostic.scope == BorderDiagnosticScope.materialization)) {
    diagnostics.add(_diagnostic(
      code: 'border.materialization.invalid',
      severity: BorderDiagnosticSeverity.error,
      phase: BorderDiagnosticPhase.freshness,
      scope: BorderDiagnosticScope.materialization,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      action: 'border.action.regenerate_materialization',
    ));
  }
  if (freshness.reasons.contains(BorderStalenessReason.blueprintMissing)) {
    diagnostics.add(_diagnostic(
      code: 'border.materialization.blueprint_missing',
      severity: BorderDiagnosticSeverity.warning,
      phase: BorderDiagnosticPhase.freshness,
      scope: BorderDiagnosticScope.materialization,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      action: 'border.action.relink_published_blueprint',
    ));
  }
  if (freshness.reasons.contains(BorderStalenessReason.blueprintNewer)) {
    diagnostics.add(_diagnostic(
      code: 'border.materialization.blueprint_newer',
      severity: BorderDiagnosticSeverity.warning,
      phase: BorderDiagnosticPhase.freshness,
      scope: BorderDiagnosticScope.materialization,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      action: 'border.action.compare_blueprint_update',
    ));
  }
}

void _diagnoseDuplicatePrimitiveIds<T>(
  List<T> primitives, {
  required String Function(T primitive) idOf,
  required String blueprintId,
  required BorderDiagnosticPhase phase,
  required List<BorderDiagnostic> diagnostics,
}) {
  final seen = <String>{};
  for (final primitive in primitives) {
    final id = idOf(primitive);
    if (!seen.add(id)) {
      diagnostics.add(_diagnostic(
        code: 'border.blueprint.duplicate_primitive_id',
        severity: BorderDiagnosticSeverity.error,
        phase: phase,
        scope: BorderDiagnosticScope.primitive,
        blueprintId: blueprintId,
        parameters: <String, Object?>{'primitiveId': id},
        action: 'border.action.assign_unique_primitive_ids',
      ));
    }
  }
}

void _diagnoseMetrics({
  required String primitiveId,
  required BorderPrimitiveAssetMetrics metrics,
  required int anchorX,
  required int anchorY,
  required String blueprintId,
  required BorderDiagnosticPhase phase,
  required List<BorderDiagnostic> diagnostics,
}) {
  final anchorInvalid = anchorX < 0 ||
      anchorY < 0 ||
      anchorX >= metrics.pixelSize.width ||
      anchorY >= metrics.pixelSize.height ||
      metrics.defaultAnchorPx.x < 0 ||
      metrics.defaultAnchorPx.y < 0 ||
      metrics.defaultAnchorPx.x >= metrics.pixelSize.width ||
      metrics.defaultAnchorPx.y >= metrics.pixelSize.height;
  if (anchorInvalid) {
    diagnostics.add(_diagnostic(
      code: 'border.blueprint.anchor_outside_asset',
      severity: BorderDiagnosticSeverity.error,
      phase: phase,
      scope: BorderDiagnosticScope.primitive,
      blueprintId: blueprintId,
      parameters: <String, Object?>{'primitiveId': primitiveId},
      action: 'border.action.place_anchor_inside_asset',
    ));
  }
  bool? occupancyHasTrue;
  try {
    final expectedLength = checkedBorderRleCellCount(
      width: metrics.pixelSize.width,
      height: metrics.pixelSize.height,
      path: r'$.publishedMetrics.pixelSize',
    );
    occupancyHasTrue = borderRleMaskHasTrue(
      metrics.occupancyMaskRle,
      expectedLength: expectedLength,
      path: r'$.publishedMetrics.occupancyMaskRle',
    );
  } on FormatException {
    diagnostics.add(_diagnostic(
      code: 'border.blueprint.occupancy_mask_invalid',
      severity: BorderDiagnosticSeverity.error,
      phase: phase,
      scope: BorderDiagnosticScope.primitive,
      blueprintId: blueprintId,
      parameters: <String, Object?>{'primitiveId': primitiveId},
      action: 'border.action.reanalyze_asset_occupancy',
    ));
  }
  if (occupancyHasTrue == false) {
    diagnostics.add(_diagnostic(
      code: 'border.blueprint.occupancy_mask_empty',
      severity: BorderDiagnosticSeverity.error,
      phase: phase,
      scope: BorderDiagnosticScope.primitive,
      blueprintId: blueprintId,
      parameters: <String, Object?>{'primitiveId': primitiveId},
      action: 'border.action.choose_nonempty_asset',
    ));
  }
}

void _diagnoseSnapshotReference(
  String id, {
  required List<BorderVisualSnapshot> available,
  required Map<String, BorderVisualSnapshotIntegrity> integrity,
  required String blueprintId,
  required BorderDiagnosticPhase phase,
  required List<BorderDiagnostic> diagnostics,
}) {
  final exists = available.any((snapshot) => snapshot.id == id);
  if (!exists) {
    diagnostics.add(_diagnostic(
      code: 'border.blueprint.visual_snapshot_missing',
      severity: BorderDiagnosticSeverity.error,
      phase: phase,
      scope: BorderDiagnosticScope.visualSnapshot,
      blueprintId: blueprintId,
      parameters: <String, Object?>{'snapshotId': id},
      action: 'border.action.restore_or_republish_snapshot',
    ));
  } else if (!_snapshotIsValid(
    id,
    available: available,
    integrity: integrity,
  )) {
    diagnostics.add(_diagnostic(
      code: 'border.blueprint.visual_snapshot_invalid',
      severity: BorderDiagnosticSeverity.error,
      phase: phase,
      scope: BorderDiagnosticScope.visualSnapshot,
      blueprintId: blueprintId,
      parameters: <String, Object?>{'snapshotId': id},
      action: 'border.action.restore_or_republish_snapshot',
    ));
  }
}

bool _snapshotIsValid(
  String id, {
  required List<BorderVisualSnapshot> available,
  required Map<String, BorderVisualSnapshotIntegrity> integrity,
}) {
  if (!available.any((snapshot) => snapshot.id == id)) return false;
  final status = integrity[id];
  return status != null && status.snapshotId == id && status.isValid;
}

bool _cellInside(GridPos point, GridSize size) =>
    point.x >= 0 &&
    point.y >= 0 &&
    point.x < size.width &&
    point.y < size.height;

bool _rectIntersectsCanvas(
  int x,
  int y,
  int width,
  int height,
  BigInt canvasWidth,
  BigInt canvasHeight,
) {
  final left = BigInt.from(x);
  final top = BigInt.from(y);
  return left < canvasWidth &&
      top < canvasHeight &&
      left + BigInt.from(width) > BigInt.zero &&
      top + BigInt.from(height) > BigInt.zero;
}

BorderDiagnosticPhase _blueprintPhase(
  BorderBlueprintValidationPurpose purpose,
) =>
    switch (purpose) {
      BorderBlueprintValidationPurpose.authoring =>
        BorderDiagnosticPhase.authoring,
      BorderBlueprintValidationPurpose.publication =>
        BorderDiagnosticPhase.publication,
      BorderBlueprintValidationPurpose.resolution =>
        BorderDiagnosticPhase.resolution,
    };

BorderDiagnosticPhase _featurePhase(BorderFeatureValidationPurpose purpose) =>
    switch (purpose) {
      BorderFeatureValidationPurpose.authoring =>
        BorderDiagnosticPhase.authoring,
      BorderFeatureValidationPurpose.resolution =>
        BorderDiagnosticPhase.resolution,
      BorderFeatureValidationPurpose.playExport =>
        BorderDiagnosticPhase.playExport,
    };

BorderDiagnostic _diagnostic({
  required String code,
  required BorderDiagnosticSeverity severity,
  required BorderDiagnosticPhase phase,
  required BorderDiagnosticScope scope,
  String? blueprintId,
  String? featureId,
  String? slotKey,
  GridPos? cell,
  String? strokeId,
  int? segmentIndex,
  Map<String, Object?> parameters = const <String, Object?>{},
  required String action,
}) =>
    BorderDiagnostic(
      code: code,
      severity: severity,
      phase: phase,
      scope: scope,
      blueprintId: blueprintId,
      featureId: featureId,
      slotKey: slotKey,
      cell: cell,
      strokeId: strokeId,
      segmentIndex: segmentIndex,
      parameters: parameters,
      suggestedAction: action,
    );
