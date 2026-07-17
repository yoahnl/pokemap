import '../exceptions/map_exceptions.dart';
import '../models/border_diagnostics.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_layer.dart';
import '../models/border_materialization.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import 'border_fingerprints.dart';
import 'border_linear_lattice.dart';
import 'border_rle_codec.dart';

const int _maximumPortableInteger = 9007199254740991;
typedef _ResizeStrokeRun = ({List<GridPos> points, int sourceStartIndex});

/// Atomic result of resizing one persisted Border layer content value.
final class BorderLayerResizeResult {
  factory BorderLayerResizeResult({
    required BorderLayerContent? content,
    required BorderDiagnosticsReport diagnosticReport,
    required bool canApply,
  }) {
    final hasErrors = diagnosticReport.hasErrors;
    if ((content == null) != hasErrors) {
      throw const ValidationException(
        'BorderLayerResizeResult.content must be null exactly when errors '
        'exist',
      );
    }
    if (canApply != !hasErrors) {
      throw const ValidationException(
        'BorderLayerResizeResult.canApply must be true exactly when no '
        'errors exist',
      );
    }
    return BorderLayerResizeResult._(
      content: content,
      diagnosticReport: diagnosticReport,
      canApply: canApply,
    );
  }

  const BorderLayerResizeResult._({
    required this.content,
    required this.diagnosticReport,
    required this.canApply,
  });

  final BorderLayerContent? content;
  final BorderDiagnosticsReport diagnosticReport;
  final bool canApply;
}

/// Resizes authored Border content against a top-left anchored map canvas.
///
/// Region masks and keep-outs are cropped or padded. Linear strokes are clipped
/// into independent canonical open fragments without resolving or regenerating
/// Border output.
BorderLayerResizeResult resizeBorderLayerContent({
  required BorderLayerContent content,
  required GridSize oldMapSize,
  required GridSize newMapSize,
  required GridSize tileSizePx,
  String? layerId,
}) {
  final diagnostics = <BorderDiagnostic>[];
  _validateResizeSizes(
    oldMapSize: oldMapSize,
    newMapSize: newMapSize,
    tileSizePx: tileSizePx,
    layerId: layerId,
    diagnostics: diagnostics,
  );
  if (_hasErrors(diagnostics)) {
    return _rejectedResult(diagnostics);
  }

  if (oldMapSize == newMapSize) {
    return BorderLayerResizeResult(
      content: content,
      diagnosticReport: const BorderDiagnosticsReport.empty(),
      canApply: true,
    );
  }

  for (final feature in content.features) {
    _preflightFeature(
      feature: feature,
      oldMapSize: oldMapSize,
      layerId: layerId,
      diagnostics: diagnostics,
    );
  }
  if (_hasErrors(diagnostics)) {
    return _rejectedResult(diagnostics);
  }

  final resizedFeatures = <BorderFeature>[
    for (final feature in content.features)
      _resizeFeature(
        feature: feature,
        oldMapSize: oldMapSize,
        newMapSize: newMapSize,
        tileSizePx: tileSizePx,
        layerId: layerId,
        diagnostics: diagnostics,
      ),
  ];
  final report = BorderDiagnosticsReport(diagnostics: diagnostics);
  return BorderLayerResizeResult(
    content: BorderLayerContent(
      formatVersion: content.formatVersion,
      features: resizedFeatures,
    ),
    diagnosticReport: report,
    canApply: true,
  );
}

void _validateResizeSizes({
  required GridSize oldMapSize,
  required GridSize newMapSize,
  required GridSize tileSizePx,
  required String? layerId,
  required List<BorderDiagnostic> diagnostics,
}) {
  _validateMapSize(
    size: oldMapSize,
    name: 'old',
    layerId: layerId,
    diagnostics: diagnostics,
  );
  _validateMapSize(
    size: newMapSize,
    name: 'new',
    layerId: layerId,
    diagnostics: diagnostics,
  );
  if (tileSizePx.width <= 0 || tileSizePx.height <= 0) {
    diagnostics.add(
      _diagnostic(
        code: 'invalid_tile_size',
        severity: BorderDiagnosticSeverity.error,
        scope: BorderDiagnosticScope.geometry,
        layerId: layerId,
        parameters: <String, Object?>{
          'width': tileSizePx.width.toString(),
          'height': tileSizePx.height.toString(),
        },
        suggestedAction: 'border.resize.use_positive_tile_size',
      ),
    );
  } else if (!_isPortableInteger(tileSizePx.width) ||
      !_isPortableInteger(tileSizePx.height)) {
    diagnostics.add(
      _diagnostic(
        code: 'tile_size_exceeds_portable_integer_range',
        severity: BorderDiagnosticSeverity.error,
        scope: BorderDiagnosticScope.geometry,
        layerId: layerId,
        parameters: <String, Object?>{
          'width': tileSizePx.width.toString(),
          'height': tileSizePx.height.toString(),
        },
        suggestedAction: 'border.resize.use_portable_tile_size',
      ),
    );
  }
}

void _validateMapSize({
  required GridSize size,
  required String name,
  required String? layerId,
  required List<BorderDiagnostic> diagnostics,
}) {
  try {
    checkedBorderRleCellCount(
      width: size.width,
      height: size.height,
      path: r'$.' '${name}MapSize',
    );
  } on FormatException {
    diagnostics.add(
      _diagnostic(
        code: '${name}_map_size_out_of_border_rle_bounds',
        severity: BorderDiagnosticSeverity.error,
        scope: BorderDiagnosticScope.geometry,
        layerId: layerId,
        parameters: <String, Object?>{
          'width': size.width.toString(),
          'height': size.height.toString(),
          'maximumDimension': borderRleMaxDimension,
          'maximumDecodedCells': borderRleMaxDecodedCells,
        },
        suggestedAction: 'border.resize.use_supported_map_size',
      ),
    );
  }
}

void _preflightFeature({
  required BorderFeature feature,
  required GridSize oldMapSize,
  required String? layerId,
  required List<BorderDiagnostic> diagnostics,
}) {
  switch (feature.geometry) {
    case final BorderRegionGeometry region:
      if (!_matchesSize(region, oldMapSize)) {
        diagnostics.add(
          _diagnostic(
            code: 'region_size_mismatch',
            severity: BorderDiagnosticSeverity.error,
            scope: BorderDiagnosticScope.geometry,
            layerId: layerId,
            featureId: feature.id,
            parameters: <String, Object?>{
              'actualWidth': region.width,
              'actualHeight': region.height,
              'expectedWidth': oldMapSize.width,
              'expectedHeight': oldMapSize.height,
            },
            suggestedAction: 'border.resize.repair_region_size',
          ),
        );
      }
    case BorderStrokeGeometry():
      break;
  }

  for (final keepOut in feature.keepOutRegions) {
    if (!_matchesSize(keepOut.region, oldMapSize)) {
      diagnostics.add(
        _diagnostic(
          code: 'keep_out_region_size_mismatch',
          severity: BorderDiagnosticSeverity.error,
          scope: BorderDiagnosticScope.geometry,
          layerId: layerId,
          featureId: feature.id,
          parameters: <String, Object?>{
            'keepOutId': keepOut.id,
            'actualWidth': keepOut.region.width,
            'actualHeight': keepOut.region.height,
            'expectedWidth': oldMapSize.width,
            'expectedHeight': oldMapSize.height,
          },
          suggestedAction: 'border.resize.repair_keep_out_region_size',
        ),
      );
    }
  }

  final materialization = feature.materialization;
  if (materialization == null) {
    return;
  }
  String computedFingerprint;
  try {
    computedFingerprint = computeBorderOutputFingerprint(
      ground: materialization.ground,
      placements: materialization.placements,
    );
  } on ValidationException {
    diagnostics.add(
      _diagnostic(
        code: 'materialization_output_fingerprint_invalid',
        severity: BorderDiagnosticSeverity.error,
        scope: BorderDiagnosticScope.materialization,
        layerId: layerId,
        featureId: feature.id,
        parameters: const <String, Object?>{
          'reason': 'output_cannot_be_canonically_hashed',
        },
        suggestedAction: 'border.resize.regenerate_materialization',
      ),
    );
    return;
  }
  if (computedFingerprint != materialization.receipt.outputFingerprint) {
    diagnostics.add(
      _diagnostic(
        code: 'materialization_output_fingerprint_mismatch',
        severity: BorderDiagnosticSeverity.error,
        scope: BorderDiagnosticScope.materialization,
        layerId: layerId,
        featureId: feature.id,
        parameters: <String, Object?>{
          'computedFingerprint': computedFingerprint,
          'receiptFingerprint': materialization.receipt.outputFingerprint,
        },
        suggestedAction: 'border.resize.regenerate_materialization',
      ),
    );
  }
}

BorderFeature _resizeFeature({
  required BorderFeature feature,
  required GridSize oldMapSize,
  required GridSize newMapSize,
  required GridSize tileSizePx,
  required String? layerId,
  required List<BorderDiagnostic> diagnostics,
}) {
  final resizedGeometry = switch (feature.geometry) {
    final BorderRegionGeometry region => _resizeRegion(
        region: region,
        oldMapSize: oldMapSize,
        newMapSize: newMapSize,
        layerId: layerId,
        featureId: feature.id,
        keepOutId: null,
        diagnostics: diagnostics,
      ),
    final BorderStrokeGeometry geometry => _resizeStrokeGeometry(
        geometry: geometry,
        newMapSize: newMapSize,
        layerId: layerId,
        featureId: feature.id,
        diagnostics: diagnostics,
      ),
  };
  final resizedKeepOutRegions = <BorderKeepOutRegion>[
    for (final keepOut in feature.keepOutRegions)
      BorderKeepOutRegion(
        id: keepOut.id,
        region: _resizeRegion(
          region: keepOut.region,
          oldMapSize: oldMapSize,
          newMapSize: newMapSize,
          layerId: layerId,
          featureId: feature.id,
          keepOutId: keepOut.id,
          diagnostics: diagnostics,
        ),
      ),
  ];
  final resizedMaterialization = _resizeMaterialization(
    materialization: feature.materialization,
    newMapSize: newMapSize,
    tileSizePx: tileSizePx,
    layerId: layerId,
    featureId: feature.id,
    diagnostics: diagnostics,
  );
  return BorderFeature(
    id: feature.id,
    name: feature.name,
    blueprintId: feature.blueprintId,
    seed: feature.seed,
    geometry: resizedGeometry,
    lineSide: feature.lineSide,
    paramsOverride: feature.paramsOverride,
    overrides: feature.overrides,
    keepOutRegions: resizedKeepOutRegions,
    materialization: resizedMaterialization,
  );
}

BorderStrokeGeometry _resizeStrokeGeometry({
  required BorderStrokeGeometry geometry,
  required GridSize newMapSize,
  required String? layerId,
  required String featureId,
  required List<BorderDiagnostic> diagnostics,
}) {
  final usedIds = <String>{
    for (final stroke in geometry.strokes) borderStrokeAuthoredIdV1(stroke.id),
  };
  final resized = <BorderStroke>[];
  var changed = false;

  for (final stroke in geometry.strokes) {
    final sourceIdentity = resolveBorderStrokeLineageIdentityV1(stroke);
    final clippedPoints = stroke.points
        .where((point) => !_containsCell(newMapSize, point.x, point.y))
        .toList(growable: false);
    if (clippedPoints.isEmpty) {
      resized.add(stroke);
      continue;
    }

    changed = true;
    final firstClippedCell = clippedPoints.first;
    diagnostics.add(
      _diagnostic(
        code: 'stroke_points_clipped',
        severity: BorderDiagnosticSeverity.warning,
        scope: BorderDiagnosticScope.stroke,
        layerId: layerId,
        featureId: featureId,
        strokeId: sourceIdentity.authoredStrokeId,
        cell: firstClippedCell,
        parameters: <String, Object?>{
          'clippedPointCount': clippedPoints.length,
          'newMapWidth': newMapSize.width,
          'newMapHeight': newMapSize.height,
        },
        suggestedAction: 'border.resize.review_clipped_stroke',
      ),
    );

    final runs = stroke.closed
        ? _splitClippedClosedStroke(stroke.points, newMapSize)
        : _splitClippedOpenStroke(stroke.points, newMapSize);
    var retainedFragmentCount = 0;
    var removedFragmentCount = 0;
    GridPos? firstRemovedFragmentCell;
    for (final run in runs) {
      if (run.points.length < 2) {
        removedFragmentCount += 1;
        firstRemovedFragmentCell ??= run.points.first;
        continue;
      }
      retainedFragmentCount += 1;
      final authoredFragmentId = retainedFragmentCount == 1
          ? sourceIdentity.authoredStrokeId
          : _nextResizeFragmentId(
              sourceIdentity.authoredStrokeId,
              ordinal: retainedFragmentCount,
              usedIds: usedIds,
            );
      usedIds.add(authoredFragmentId);
      resized.add(
        buildBorderTraversalPreservedFragmentV1(
          sourceStroke: stroke,
          authoredStrokeId: authoredFragmentId,
          sourceStartIndex: run.sourceStartIndex,
          orderedPoints: run.points,
        ),
      );
    }

    if (removedFragmentCount > 0) {
      diagnostics.add(
        _diagnostic(
          code: 'stroke_fragment_too_short',
          severity: BorderDiagnosticSeverity.warning,
          scope: BorderDiagnosticScope.stroke,
          layerId: layerId,
          featureId: featureId,
          strokeId: sourceIdentity.authoredStrokeId,
          cell: firstRemovedFragmentCell ?? firstClippedCell,
          parameters: <String, Object?>{
            'removedFragmentCount': removedFragmentCount,
            'minimumPointCount': 2,
          },
          suggestedAction: 'border.resize.review_removed_stroke_fragment',
        ),
      );
    }
    if (retainedFragmentCount > 1) {
      diagnostics.add(
        _diagnostic(
          code: 'stroke_split',
          severity: BorderDiagnosticSeverity.info,
          scope: BorderDiagnosticScope.stroke,
          layerId: layerId,
          featureId: featureId,
          strokeId: sourceIdentity.authoredStrokeId,
          cell: firstClippedCell,
          parameters: <String, Object?>{
            'retainedFragmentCount': retainedFragmentCount,
          },
          suggestedAction: 'border.resize.review_split_stroke',
        ),
      );
    }
    if (stroke.closed && retainedFragmentCount > 0) {
      diagnostics.add(
        _diagnostic(
          code: 'stroke_closed_to_open',
          severity: BorderDiagnosticSeverity.warning,
          scope: BorderDiagnosticScope.stroke,
          layerId: layerId,
          featureId: featureId,
          strokeId: sourceIdentity.authoredStrokeId,
          cell: firstClippedCell,
          parameters: <String, Object?>{
            'retainedFragmentCount': retainedFragmentCount,
          },
          suggestedAction: 'border.resize.review_opened_stroke',
        ),
      );
    }
  }

  return changed ? BorderStrokeGeometry(strokes: resized) : geometry;
}

List<_ResizeStrokeRun> _splitClippedOpenStroke(
  List<GridPos> points,
  GridSize newMapSize,
) {
  final runs = <_ResizeStrokeRun>[];
  var current = <GridPos>[];
  int? currentStartIndex;
  for (var index = 0; index < points.length; index += 1) {
    final point = points[index];
    if (!_containsCell(newMapSize, point.x, point.y)) {
      if (current.isNotEmpty) {
        runs.add((points: current, sourceStartIndex: currentStartIndex!));
      }
      current = <GridPos>[];
      currentStartIndex = null;
    } else {
      currentStartIndex ??= index;
      current.add(point);
    }
  }
  if (current.isNotEmpty) {
    runs.add((points: current, sourceStartIndex: currentStartIndex!));
  }
  return runs;
}

List<_ResizeStrokeRun> _splitClippedClosedStroke(
  List<GridPos> points,
  GridSize newMapSize,
) {
  final firstClipped = points.indexWhere(
    (point) => !_containsCell(newMapSize, point.x, point.y),
  );
  final runs = <_ResizeStrokeRun>[];
  var current = <GridPos>[];
  int? currentStartIndex;
  for (var offset = 1; offset <= points.length; offset += 1) {
    final sourceIndex = (firstClipped + offset) % points.length;
    final point = points[sourceIndex];
    if (!_containsCell(newMapSize, point.x, point.y)) {
      if (current.isNotEmpty) {
        runs.add((points: current, sourceStartIndex: currentStartIndex!));
      }
      current = <GridPos>[];
      currentStartIndex = null;
    } else {
      currentStartIndex ??= sourceIndex;
      current.add(point);
    }
  }
  if (current.isNotEmpty) {
    runs.add((points: current, sourceStartIndex: currentStartIndex!));
  }
  return runs;
}

String _nextResizeFragmentId(
  String sourceId, {
  required int ordinal,
  required Set<String> usedIds,
}) {
  var suffix = ordinal;
  while (true) {
    final candidate = '${sourceId}__fragment_$suffix';
    if (!usedIds.contains(candidate)) return candidate;
    suffix += 1;
  }
}

BorderRegionGeometry _resizeRegion({
  required BorderRegionGeometry region,
  required GridSize oldMapSize,
  required GridSize newMapSize,
  required String? layerId,
  required String featureId,
  required String? keepOutId,
  required List<BorderDiagnostic> diagnostics,
}) {
  final resized = List<bool>.filled(
    newMapSize.width * newMapSize.height,
    false,
    growable: false,
  );
  final copyWidth =
      oldMapSize.width < newMapSize.width ? oldMapSize.width : newMapSize.width;
  final copyHeight = oldMapSize.height < newMapSize.height
      ? oldMapSize.height
      : newMapSize.height;
  for (var y = 0; y < copyHeight; y += 1) {
    final oldRow = y * oldMapSize.width;
    final newRow = y * newMapSize.width;
    for (var x = 0; x < copyWidth; x += 1) {
      resized[newRow + x] = region.cells[oldRow + x];
    }
  }

  var clippedTrueCount = 0;
  GridPos? firstClippedCell;
  for (var y = 0; y < oldMapSize.height; y += 1) {
    final oldRow = y * oldMapSize.width;
    for (var x = 0; x < oldMapSize.width; x += 1) {
      if ((x >= newMapSize.width || y >= newMapSize.height) &&
          region.cells[oldRow + x]) {
        clippedTrueCount += 1;
        firstClippedCell ??= GridPos(x: x, y: y);
      }
    }
  }
  if (clippedTrueCount > 0) {
    diagnostics.add(
      _diagnostic(
        code:
            keepOutId == null ? 'region_cell_clipped' : 'keep_out_cell_clipped',
        severity: BorderDiagnosticSeverity.warning,
        scope: BorderDiagnosticScope.geometry,
        layerId: layerId,
        featureId: featureId,
        cell: firstClippedCell,
        parameters: <String, Object?>{
          if (keepOutId != null) 'keepOutId': keepOutId,
          'clippedTrueCellCount': clippedTrueCount,
        },
        suggestedAction: 'border.resize.review_clipped_cells',
      ),
    );
  }

  final copiedCellCount = copyWidth * copyHeight;
  final paddedCellCount = resized.length - copiedCellCount;
  if (paddedCellCount > 0) {
    final firstPaddedCell = newMapSize.width > oldMapSize.width
        ? GridPos(x: oldMapSize.width, y: 0)
        : GridPos(x: 0, y: oldMapSize.height);
    diagnostics.add(
      _diagnostic(
        code: keepOutId == null
            ? 'region_padding_added'
            : 'keep_out_padding_added',
        severity: BorderDiagnosticSeverity.info,
        scope: BorderDiagnosticScope.geometry,
        layerId: layerId,
        featureId: featureId,
        cell: firstPaddedCell,
        parameters: <String, Object?>{
          if (keepOutId != null) 'keepOutId': keepOutId,
          'paddedFalseCellCount': paddedCellCount,
        },
        suggestedAction: 'border.resize.review_padded_cells',
      ),
    );
  }

  return BorderRegionGeometry(
    width: newMapSize.width,
    height: newMapSize.height,
    cells: resized,
  );
}

BorderMaterialization? _resizeMaterialization({
  required BorderMaterialization? materialization,
  required GridSize newMapSize,
  required GridSize tileSizePx,
  required String? layerId,
  required String featureId,
  required List<BorderDiagnostic> diagnostics,
}) {
  if (materialization == null) {
    return null;
  }

  final retainedGround = <BorderResolvedGroundCell>[];
  for (final groundCell in materialization.ground) {
    if (_containsCell(newMapSize, groundCell.x, groundCell.y)) {
      retainedGround.add(groundCell);
    } else {
      diagnostics.add(
        _diagnostic(
          code: 'ground_cell_out_of_bounds',
          severity: BorderDiagnosticSeverity.warning,
          scope: BorderDiagnosticScope.groundCell,
          layerId: layerId,
          featureId: featureId,
          cell: GridPos(x: groundCell.x, y: groundCell.y),
          parameters: const <String, Object?>{},
          suggestedAction: 'border.resize.review_culled_ground',
        ),
      );
    }
  }

  final canvasWidth =
      BigInt.from(newMapSize.width) * BigInt.from(tileSizePx.width);
  final canvasHeight =
      BigInt.from(newMapSize.height) * BigInt.from(tileSizePx.height);
  final retainedPlacements = <BorderResolvedPlacement>[];
  for (final placement in materialization.placements) {
    if (!_containsCell(
      newMapSize,
      placement.anchorCell.x,
      placement.anchorCell.y,
    )) {
      diagnostics.add(
        _diagnostic(
          code: 'placement_anchor_out_of_bounds',
          severity: BorderDiagnosticSeverity.warning,
          scope: BorderDiagnosticScope.placement,
          layerId: layerId,
          featureId: featureId,
          slotKey: placement.slotKey,
          cell: placement.anchorCell,
          parameters: <String, Object?>{'placementId': placement.id},
          suggestedAction: 'border.resize.review_culled_placement_anchor',
        ),
      );
      continue;
    }
    if (!_intersectsCanvas(
      placement.opaqueWorldBoundsPx,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    )) {
      diagnostics.add(
        _diagnostic(
          code: 'placement_bounds_out_of_bounds',
          severity: BorderDiagnosticSeverity.warning,
          scope: BorderDiagnosticScope.placement,
          layerId: layerId,
          featureId: featureId,
          slotKey: placement.slotKey,
          cell: placement.anchorCell,
          parameters: <String, Object?>{'placementId': placement.id},
          suggestedAction: 'border.resize.review_culled_placement_bounds',
        ),
      );
      continue;
    }
    retainedPlacements.add(placement);
  }

  final outputUnchanged =
      retainedGround.length == materialization.ground.length &&
          retainedPlacements.length == materialization.placements.length;
  if (outputUnchanged) {
    return materialization;
  }
  if (retainedGround.isEmpty && retainedPlacements.isEmpty) {
    return null;
  }

  final sourceReceipt = materialization.receipt;
  final receipt = BorderResolutionReceipt(
    resolverVersion: sourceReceipt.resolverVersion,
    blueprintRevision: sourceReceipt.blueprintRevision,
    components: sourceReceipt.components,
    inputFingerprint: sourceReceipt.inputFingerprint,
    outputFingerprint: computeBorderOutputFingerprint(
      ground: retainedGround,
      placements: retainedPlacements,
    ),
  );
  return BorderMaterialization(
    receipt: receipt,
    ground: retainedGround,
    placements: retainedPlacements,
  );
}

bool _intersectsCanvas(
  BorderPixelRect rect, {
  required BigInt canvasWidth,
  required BigInt canvasHeight,
}) {
  final left = BigInt.from(rect.x);
  final top = BigInt.from(rect.y);
  final right = left + BigInt.from(rect.width);
  final bottom = top + BigInt.from(rect.height);
  return left < canvasWidth &&
      right > BigInt.zero &&
      top < canvasHeight &&
      bottom > BigInt.zero;
}

bool _matchesSize(BorderRegionGeometry region, GridSize size) =>
    region.width == size.width && region.height == size.height;

bool _containsCell(GridSize size, int x, int y) =>
    x >= 0 && y >= 0 && x < size.width && y < size.height;

bool _isPortableInteger(int value) =>
    value >= -_maximumPortableInteger && value <= _maximumPortableInteger;

bool _hasErrors(Iterable<BorderDiagnostic> diagnostics) => diagnostics.any(
      (diagnostic) => diagnostic.severity == BorderDiagnosticSeverity.error,
    );

BorderLayerResizeResult _rejectedResult(
  Iterable<BorderDiagnostic> diagnostics,
) =>
    BorderLayerResizeResult(
      content: null,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
      canApply: false,
    );

BorderDiagnostic _diagnostic({
  required String code,
  required BorderDiagnosticSeverity severity,
  required BorderDiagnosticScope scope,
  required String? layerId,
  String? featureId,
  String? slotKey,
  GridPos? cell,
  String? strokeId,
  required Map<String, Object?> parameters,
  required String suggestedAction,
}) =>
    BorderDiagnostic(
      code: code,
      severity: severity,
      phase: BorderDiagnosticPhase.resize,
      scope: scope,
      featureId: featureId,
      slotKey: slotKey,
      cell: cell,
      strokeId: strokeId,
      parameters: <String, Object?>{
        'layerId': layerId,
        ...parameters,
      },
      suggestedAction: suggestedAction,
    );
