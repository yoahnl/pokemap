import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:map_core/map_core.dart';

enum BorderPreviewPhase {
  idle,
  drawing,
  resolved,
  invalid,
  applying,
}

/// Identity and immutable-catalog snapshot that owns one transient preview.
///
/// IDs and feature fingerprints are deliberately insufficient here: two open
/// projects may contain byte-identical maps with the same IDs. Object identity
/// prevents a proposal created in one editor document from leaking into the
/// other, while the catalog fingerprint invalidates previews after publication
/// changes without retaining a mutable catalog lookup.
@immutable
final class BorderPreviewContext {
  const BorderPreviewContext({
    required this.projectRootPath,
    required this.activeMapPath,
    required this.projectIdentity,
    required this.mapIdentity,
    required this.borderCatalogFingerprint,
  });

  final String projectRootPath;
  final String activeMapPath;
  final Object projectIdentity;
  final Object mapIdentity;
  final String borderCatalogFingerprint;

  bool matches(BorderPreviewContext other) =>
      projectRootPath == other.projectRootPath &&
      activeMapPath == other.activeMapPath &&
      identical(projectIdentity, other.projectIdentity) &&
      identical(mapIdentity, other.mapIdentity) &&
      borderCatalogFingerprint == other.borderCatalogFingerprint;
}

BorderPreviewContext createEditorBorderPreviewContext({
  required String projectRootPath,
  required String activeMapPath,
  required ProjectManifest project,
  required MapData map,
}) =>
    BorderPreviewContext(
      projectRootPath: projectRootPath.trim(),
      activeMapPath: activeMapPath.trim(),
      projectIdentity: project,
      mapIdentity: map,
      borderCatalogFingerprint: sha256
          .convert(
            utf8.encode(
              jsonEncode(encodeProjectBorderCatalogJson(project.borderCatalog)),
            ),
          )
          .toString(),
    );

/// Immutable, non-persisted proposal owned by one World Maps preview.
@immutable
final class BorderPreviewTransaction {
  const BorderPreviewTransaction({
    required this.context,
    required this.mapId,
    required this.mapSize,
    required this.layerId,
    required this.featureId,
    required this.baseFeatureFingerprint,
    required this.proposedFeature,
    required this.variationOrdinal,
    this.request,
    this.result,
  });

  final BorderPreviewContext context;
  final String mapId;
  final GridSize mapSize;
  final String layerId;
  final String featureId;
  final String baseFeatureFingerprint;
  final BorderFeature proposedFeature;
  final int variationOrdinal;
  final BorderResolutionRequest? request;
  final BorderResolutionResult? result;

  BorderPreviewTransaction withDraftFeature(
    BorderFeature feature, {
    int? variationOrdinal,
  }) =>
      BorderPreviewTransaction(
        context: context,
        mapId: mapId,
        mapSize: mapSize,
        layerId: layerId,
        featureId: featureId,
        baseFeatureFingerprint: baseFeatureFingerprint,
        proposedFeature: feature,
        variationOrdinal: variationOrdinal ?? this.variationOrdinal,
      );

  BorderPreviewTransaction withResolution({
    required BorderFeature feature,
    required BorderResolutionRequest request,
    required BorderResolutionResult result,
    int? variationOrdinal,
  }) =>
      BorderPreviewTransaction(
        context: context,
        mapId: mapId,
        mapSize: mapSize,
        layerId: layerId,
        featureId: featureId,
        baseFeatureFingerprint: baseFeatureFingerprint,
        proposedFeature: feature,
        variationOrdinal: variationOrdinal ?? this.variationOrdinal,
        request: request,
        result: result,
      );
}

@immutable
final class BorderPreviewState {
  const BorderPreviewState({required this.phase, this.transaction});

  const BorderPreviewState.idle()
      : phase = BorderPreviewPhase.idle,
        transaction = null;

  final BorderPreviewPhase phase;
  final BorderPreviewTransaction? transaction;

  bool get hasPendingPreview => transaction != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPreviewState &&
          phase == other.phase &&
          identical(transaction, other.transaction);

  @override
  int get hashCode => Object.hash(phase, identityHashCode(transaction));
}

@immutable
final class BorderPreviewApplyOutcome {
  const BorderPreviewApplyOutcome({
    required this.map,
    required this.applied,
  });

  final MapData map;
  final bool applied;
}

typedef BorderFeatureResolver = BorderResolutionResult Function(
  BorderResolutionRequest request,
);

typedef BorderPreviewMapApplier = MapData Function({
  required MapData map,
  required BorderPreviewTransaction transaction,
});
