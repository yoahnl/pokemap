import 'dart:collection';

import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import 'border_fingerprints.dart';
import 'border_rle_codec.dart';
import 'border_template_capabilities.dart';

/// Explicit stable order for Border V1 staleness reasons.
const List<BorderStalenessReason> borderStalenessReasonV1Order =
    <BorderStalenessReason>[
  BorderStalenessReason.blueprintNewer,
  BorderStalenessReason.blueprintMissing,
  BorderStalenessReason.geometryOrSeedChanged,
  BorderStalenessReason.parametersChanged,
  BorderStalenessReason.overridesChanged,
  BorderStalenessReason.keepOutRegionsChanged,
  BorderStalenessReason.mapContextChanged,
  BorderStalenessReason.resolverNewer,
  BorderStalenessReason.visualSnapshotMissingOrCorrupt,
  BorderStalenessReason.outputAltered,
];

/// Derives persisted-output freshness without reading source assets or files.
BorderMaterializationFreshness assessBorderMaterializationFreshness(
  BorderResolutionRequest currentRequest, {
  required BorderMaterialization? materialization,
  required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
}) =>
    inspectBorderMaterializationFreshness(
      currentRequest,
      materialization: materialization,
      snapshotIntegrity: snapshotIntegrity,
    ).freshness;

/// One-pass freshness result plus the two persisted fingerprint checks.
///
/// Diagnostics consume this richer view so large output lists are not hashed
/// again merely to select a more precise error code.
typedef BorderMaterializationFreshnessInspection = ({
  BorderMaterializationFreshness freshness,
  bool? receiptInputFingerprintValid,
  bool? outputFingerprintValid,
});

BorderMaterializationFreshnessInspection inspectBorderMaterializationFreshness(
  BorderResolutionRequest currentRequest, {
  required BorderMaterialization? materialization,
  required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
}) {
  final currentFingerprints = _computeCurrentFingerprints(currentRequest);
  final canRegenerate = _canRegenerate(
    currentRequest,
    materialization: materialization,
    snapshotIntegrity: snapshotIntegrity,
    currentComponents: currentFingerprints.full,
  );
  if (materialization == null) {
    return (
      freshness: BorderMaterializationFreshness(
        state: BorderMaterializationState.unmaterialized,
        reasons: const <BorderStalenessReason>{},
        isRenderable: false,
        canRegenerate: canRegenerate,
      ),
      receiptInputFingerprintValid: null,
      outputFingerprintValid: null,
    );
  }

  final reasons = <BorderStalenessReason>{};
  var intrinsicallyInvalid = false;
  final receipt = materialization.receipt;

  String? receiptAggregate;
  try {
    receiptAggregate = computeBorderAggregateInputFingerprint(
      resolverVersion: receipt.resolverVersion,
      blueprintRevision: receipt.blueprintRevision,
      components: receipt.components,
    );
  } on FormatException {
    receiptAggregate = null;
  } on ValidationException {
    receiptAggregate = null;
  }
  final receiptInputFingerprintValid =
      receiptAggregate != null && receipt.inputFingerprint == receiptAggregate;
  if (!receiptInputFingerprintValid) {
    intrinsicallyInvalid = true;
  }

  String? expectedOutput;
  try {
    expectedOutput = computeBorderOutputFingerprint(
      ground: materialization.ground,
      placements: materialization.placements,
    );
  } on FormatException {
    expectedOutput = null;
  } on ValidationException {
    expectedOutput = null;
  }
  final outputFingerprintValid =
      expectedOutput != null && receipt.outputFingerprint == expectedOutput;
  if (!outputFingerprintValid) {
    reasons.add(BorderStalenessReason.outputAltered);
    intrinsicallyInvalid = true;
  }

  final outputSnapshotIds = _materializedSnapshotIds(materialization);
  if (!_snapshotReferencesAreValid(
    outputSnapshotIds,
    snapshots: currentRequest.visualSnapshots,
    snapshotIntegrity: snapshotIntegrity,
  )) {
    reasons.add(BorderStalenessReason.visualSnapshotMissingOrCorrupt);
    intrinsicallyInvalid = true;
  }
  if (!_materializationStructureIsValid(currentRequest, materialization)) {
    intrinsicallyInvalid = true;
  }

  final currentRevision = currentRequest.blueprintRevision;
  if (currentRevision == null) {
    reasons.add(BorderStalenessReason.blueprintMissing);
  } else if (currentRevision.revision < receipt.blueprintRevision) {
    intrinsicallyInvalid = true;
  } else {
    final sameRevision = currentRevision.revision == receipt.blueprintRevision;
    if (!sameRevision) {
      reasons.add(BorderStalenessReason.blueprintNewer);
    }
    final currentGenerationSnapshotsValid =
        _generationSnapshotReferencesAreValid(
      currentRequest,
      snapshotIntegrity,
    );
    if (!currentGenerationSnapshotsValid) {
      reasons.add(BorderStalenessReason.visualSnapshotMissingOrCorrupt);
    }

    final currentNonVisualComponents = currentFingerprints.nonVisual;
    var nonVisualComponentsUnchanged = false;
    if (currentNonVisualComponents != null) {
      if (sameRevision &&
          currentNonVisualComponents.blueprint !=
              receipt.components.blueprint) {
        intrinsicallyInvalid = true;
      }
      if (currentNonVisualComponents.geometryAndSeed !=
          receipt.components.geometryAndSeed) {
        reasons.add(BorderStalenessReason.geometryOrSeedChanged);
      }
      if (currentNonVisualComponents.parameters !=
          receipt.components.parameters) {
        reasons.add(BorderStalenessReason.parametersChanged);
      }
      if (currentNonVisualComponents.overrides !=
          receipt.components.overrides) {
        reasons.add(BorderStalenessReason.overridesChanged);
      }
      if (currentNonVisualComponents.keepOutRegions !=
          receipt.components.keepOutRegions) {
        reasons.add(BorderStalenessReason.keepOutRegionsChanged);
      }
      if (currentNonVisualComponents.mapContext !=
          receipt.components.mapContext) {
        reasons.add(BorderStalenessReason.mapContextChanged);
      }
      nonVisualComponentsUnchanged = currentNonVisualComponents.blueprint ==
              receipt.components.blueprint &&
          currentNonVisualComponents.geometryAndSeed ==
              receipt.components.geometryAndSeed &&
          currentNonVisualComponents.parameters ==
              receipt.components.parameters &&
          currentNonVisualComponents.overrides ==
              receipt.components.overrides &&
          currentNonVisualComponents.keepOutRegions ==
              receipt.components.keepOutRegions &&
          currentNonVisualComponents.mapContext ==
              receipt.components.mapContext;
    }

    final currentComponents = currentFingerprints.full;
    if (currentComponents != null) {
      if (sameRevision &&
          currentComponents.visualSnapshots !=
              receipt.components.visualSnapshots &&
          nonVisualComponentsUnchanged &&
          currentGenerationSnapshotsValid) {
        intrinsicallyInvalid = true;
      }
    } else if (sameRevision) {
      if (currentNonVisualComponents == null ||
          (currentGenerationSnapshotsValid && reasons.isEmpty)) {
        // At the same immutable revision, an unexplained hashing failure is
        // corruption. Missing current-input snapshots are different: they
        // prevent regeneration but do not invalidate an independent old
        // output whose own snapshots were checked above.
        intrinsicallyInvalid = true;
      }
    }
  }

  if (currentRequest.resolverVersion < receipt.resolverVersion) {
    intrinsicallyInvalid = true;
  } else if (currentRequest.resolverVersion > receipt.resolverVersion) {
    reasons.add(BorderStalenessReason.resolverNewer);
  }

  final orderedReasons = LinkedHashSet<BorderStalenessReason>.from(
    borderStalenessReasonV1Order.where(reasons.contains),
  );
  if (intrinsicallyInvalid) {
    return (
      freshness: BorderMaterializationFreshness(
        state: BorderMaterializationState.invalid,
        reasons: orderedReasons,
        isRenderable: false,
        canRegenerate: canRegenerate,
      ),
      receiptInputFingerprintValid: receiptInputFingerprintValid,
      outputFingerprintValid: outputFingerprintValid,
    );
  }
  if (orderedReasons.isNotEmpty) {
    return (
      freshness: BorderMaterializationFreshness(
        state: BorderMaterializationState.stale,
        reasons: orderedReasons,
        isRenderable: true,
        canRegenerate: canRegenerate,
      ),
      receiptInputFingerprintValid: receiptInputFingerprintValid,
      outputFingerprintValid: outputFingerprintValid,
    );
  }
  return (
    freshness: BorderMaterializationFreshness(
      state: BorderMaterializationState.fresh,
      reasons: const <BorderStalenessReason>{},
      isRenderable: true,
      canRegenerate: canRegenerate,
    ),
    receiptInputFingerprintValid: receiptInputFingerprintValid,
    outputFingerprintValid: outputFingerprintValid,
  );
}

bool _canRegenerate(
  BorderResolutionRequest request, {
  required BorderMaterialization? materialization,
  required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
  required BorderInputFingerprints? currentComponents,
}) {
  final revision = request.blueprintRevision;
  if (revision == null ||
      (materialization != null &&
          request.resolverVersion < materialization.receipt.resolverVersion) ||
      (materialization != null &&
          revision.revision < materialization.receipt.blueprintRevision)) {
    return false;
  }
  if (!_geometryIsCompatibleAndUsable(request)) {
    return false;
  }
  if (!_publishedDefinitionIsValid(
    revision.definition,
    snapshots: request.visualSnapshots,
    snapshotIntegrity: snapshotIntegrity,
  )) {
    return false;
  }
  if (!_overrideReferencesAreValid(request, snapshotIntegrity)) {
    return false;
  }
  if (currentComponents == null) {
    return false;
  }
  return true;
}

({
  BorderNonVisualInputFingerprints? nonVisual,
  BorderInputFingerprints? full,
}) _computeCurrentFingerprints(BorderResolutionRequest request) {
  BorderNonVisualInputFingerprints nonVisual;
  try {
    nonVisual = computeBorderNonVisualInputFingerprints(request);
  } on FormatException {
    return (nonVisual: null, full: null);
  } on ValidationException {
    return (nonVisual: null, full: null);
  }

  try {
    final visualSnapshots =
        computeBorderVisualSnapshotsInputFingerprint(request);
    return (
      nonVisual: nonVisual,
      full: BorderInputFingerprints(
        blueprint: nonVisual.blueprint,
        geometryAndSeed: nonVisual.geometryAndSeed,
        parameters: nonVisual.parameters,
        overrides: nonVisual.overrides,
        keepOutRegions: nonVisual.keepOutRegions,
        mapContext: nonVisual.mapContext,
        visualSnapshots: visualSnapshots,
      ),
    );
  } on FormatException {
    return (nonVisual: nonVisual, full: null);
  } on ValidationException {
    return (nonVisual: nonVisual, full: null);
  }
}

bool _geometryIsCompatibleAndUsable(BorderResolutionRequest request) {
  final geometry = request.feature.geometry;
  final template = request.blueprintRevision!.definition.template;
  if (template == BorderBlueprintTemplate.organicEdge) {
    if (geometry is! BorderRegionGeometry ||
        geometry.width != request.mapSize.width ||
        geometry.height != request.mapSize.height ||
        !geometry.cells.contains(true)) {
      return false;
    }
  } else {
    if (geometry is! BorderStrokeGeometry ||
        geometry.strokes.isEmpty ||
        geometry.alignment != borderTemplateStrokeAlignment(template)) {
      return false;
    }
    final includesOuterVertices =
        geometry.alignment == BorderStrokeAlignment.gridEdges;
    for (final stroke in geometry.strokes) {
      if (stroke.points.any(
        (point) => !_strokePointIsInsideMap(
          point.x,
          point.y,
          request.mapSize.width,
          request.mapSize.height,
          includesOuterVertices: includesOuterVertices,
        ),
      )) {
        return false;
      }
    }
  }
  for (final keepOut in request.feature.keepOutRegions) {
    if (keepOut.region.width != request.mapSize.width ||
        keepOut.region.height != request.mapSize.height) {
      return false;
    }
  }
  return true;
}

bool _publishedDefinitionIsValid(
  BorderBlueprintPublishedDefinition definition, {
  required List<BorderVisualSnapshot> snapshots,
  required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
}) {
  final primitiveIds = <String>{};
  final snapshotIds = <String>{};
  for (final primitive in definition.primitives) {
    if (!primitiveIds.add(primitive.id) ||
        !_metricsAreValid(primitive.publishedMetrics) ||
        !_anchorIsInside(primitive.anchorPx, primitive.publishedMetrics)) {
      return false;
    }
    snapshotIds.add(primitive.visualSnapshotId);
  }
  final ground = definition.ground;
  if (ground != null) {
    snapshotIds.addAll(ground.visualSnapshotIdsByRole.values);
  }
  return _snapshotReferencesAreValid(
    snapshotIds,
    snapshots: snapshots,
    snapshotIntegrity: snapshotIntegrity,
  );
}

bool _metricsAreValid(BorderPrimitiveAssetMetrics metrics) {
  try {
    final expectedLength = checkedBorderRleCellCount(
      width: metrics.pixelSize.width,
      height: metrics.pixelSize.height,
      path: r'$.publishedMetrics.pixelSize',
    );
    return borderRleMaskHasTrue(
          metrics.occupancyMaskRle,
          expectedLength: expectedLength,
          path: r'$.publishedMetrics.occupancyMaskRle',
        ) &&
        _pixelPositionIsInside(
          metrics.defaultAnchorPx,
          metrics.pixelSize.width,
          metrics.pixelSize.height,
        );
  } on FormatException {
    return false;
  }
}

bool _anchorIsInside(
  BorderPixelPos anchor,
  BorderPrimitiveAssetMetrics metrics,
) =>
    _pixelPositionIsInside(
      anchor,
      metrics.pixelSize.width,
      metrics.pixelSize.height,
    );

bool _pixelPositionIsInside(
  BorderPixelPos position,
  int width,
  int height,
) =>
    position.x >= 0 &&
    position.y >= 0 &&
    position.x < width &&
    position.y < height;

bool _overrideReferencesAreValid(
  BorderResolutionRequest request,
  Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
) {
  final revision = request.blueprintRevision;
  if (revision == null) return false;
  final primitivesById = <String, BorderPublishedPrimitive>{
    for (final primitive in revision.definition.primitives)
      primitive.id: primitive,
  };
  final snapshots = <String, BorderVisualSnapshot>{
    for (final snapshot in request.visualSnapshots) snapshot.id: snapshot,
  };
  for (final override in request.feature.overrides) {
    final replacement = override.replacementPrimitiveId;
    final locked = override.lockedPlacement;
    if (replacement != null && !primitivesById.containsKey(replacement)) {
      return false;
    }
    final lockedPrimitive =
        locked == null ? null : primitivesById[locked.primitiveId];
    if (locked != null &&
        (lockedPrimitive == null ||
            locked.visualSnapshotId != lockedPrimitive.visualSnapshotId ||
            !snapshots.containsKey(locked.visualSnapshotId) ||
            snapshotIntegrity[locked.visualSnapshotId]?.snapshotId !=
                locked.visualSnapshotId ||
            snapshotIntegrity[locked.visualSnapshotId]?.isValid != true)) {
      return false;
    }
  }
  return true;
}

bool _generationSnapshotReferencesAreValid(
  BorderResolutionRequest request,
  Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
) {
  final revision = request.blueprintRevision;
  if (revision == null) {
    return false;
  }
  final ids = <String>{
    for (final primitive in revision.definition.primitives)
      primitive.visualSnapshotId,
  };
  final ground = revision.definition.ground;
  if (ground != null) {
    ids.addAll(ground.visualSnapshotIdsByRole.values);
  }
  for (final override in request.feature.overrides) {
    final locked = override.lockedPlacement;
    if (locked != null) {
      ids.add(locked.visualSnapshotId);
    }
  }
  return _snapshotReferencesAreValid(
    ids,
    snapshots: request.visualSnapshots,
    snapshotIntegrity: snapshotIntegrity,
  );
}

bool _snapshotReferencesAreValid(
  Iterable<String> ids, {
  required List<BorderVisualSnapshot> snapshots,
  required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
}) {
  final available = <String>{for (final snapshot in snapshots) snapshot.id};
  for (final id in ids) {
    final integrity = snapshotIntegrity[id];
    if (!available.contains(id) ||
        integrity == null ||
        integrity.snapshotId != id ||
        !integrity.isValid) {
      return false;
    }
  }
  return true;
}

Set<String> _materializedSnapshotIds(BorderMaterialization materialization) =>
    <String>{
      for (final cell in materialization.ground) cell.visualSnapshotId,
      for (final placement in materialization.placements)
        placement.visualSnapshotId,
    };

bool _materializationStructureIsValid(
  BorderResolutionRequest request,
  BorderMaterialization materialization,
) {
  for (final cell in materialization.ground) {
    if (!_cellIsInsideMap(
      cell.x,
      cell.y,
      request.mapSize.width,
      request.mapSize.height,
    )) {
      return false;
    }
  }
  final canvasWidth = BigInt.from(request.mapSize.width) *
      BigInt.from(request.tileSizePx.width);
  final canvasHeight = BigInt.from(request.mapSize.height) *
      BigInt.from(request.tileSizePx.height);
  for (final placement in materialization.placements) {
    if (!_cellIsInsideMap(
          placement.anchorCell.x,
          placement.anchorCell.y,
          request.mapSize.width,
          request.mapSize.height,
        ) ||
        BigInt.from(placement.stableOrderKey.anchorRowMajor) !=
            BigInt.from(placement.anchorCell.y) *
                    BigInt.from(request.mapSize.width) +
                BigInt.from(placement.anchorCell.x) ||
        !_rectIntersectsCanvas(
          placement.opaqueWorldBoundsPx.x,
          placement.opaqueWorldBoundsPx.y,
          placement.opaqueWorldBoundsPx.width,
          placement.opaqueWorldBoundsPx.height,
          canvasWidth,
          canvasHeight,
        )) {
      return false;
    }
  }
  return true;
}

bool _cellIsInsideMap(int x, int y, int width, int height) =>
    x >= 0 && y >= 0 && x < width && y < height;

bool _strokePointIsInsideMap(
  int x,
  int y,
  int width,
  int height, {
  required bool includesOuterVertices,
}) =>
    x >= 0 &&
    y >= 0 &&
    (includesOuterVertices ? x <= width : x < width) &&
    (includesOuterVertices ? y <= height : y < height);

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
