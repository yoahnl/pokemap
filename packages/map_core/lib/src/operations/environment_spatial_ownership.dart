import 'dart:convert';

import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import 'narrative_project_fingerprint.dart';

String environmentSpatialPlacementId({
  required String layerId,
  required String areaId,
  required String modelId,
  required GridPos anchor,
}) {
  if (layerId.trim().isEmpty ||
      areaId.trim().isEmpty ||
      modelId.trim().isEmpty ||
      anchor.x < 0 ||
      anchor.y < 0) {
    throw const ValidationException(
      'A spatial Environment placement requires stable resource IDs and a nonnegative anchor cell.',
      code: 'environment.placement_anchor_invalid',
    );
  }
  return 'env3d_${_identityHash([layerId, areaId])}_${anchor.x}_${anchor.y}_${_identityHash([modelId])}';
}

GridPos environmentSpatialPlacementAnchor({
  required String placementId,
  required String layerId,
  required String areaId,
  required String modelId,
}) {
  final match = RegExp(
    r'^env3d_[0-9a-f]{20}_(0|[1-9][0-9]*)_(0|[1-9][0-9]*)_[0-9a-f]{20}$',
  ).firstMatch(placementId);
  final x = match == null ? null : int.tryParse(match.group(1)!);
  final y = match == null ? null : int.tryParse(match.group(2)!);
  if (x == null || y == null) {
    throw const ValidationException(
      'The spatial Environment placement ID does not identify a canonical anchor cell.',
      code: 'environment.placement_anchor_invalid',
    );
  }
  final anchor = GridPos(x: x, y: y);
  if (environmentSpatialPlacementId(
        layerId: layerId,
        areaId: areaId,
        modelId: modelId,
        anchor: anchor,
      ) !=
      placementId) {
    throw const ValidationException(
      'The spatial Environment placement anchor belongs to another zone or model.',
      code: 'environment.placement_anchor_invalid',
    );
  }
  return anchor;
}

String _identityHash(List<String> identities) =>
    computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'identity',
        bytes: utf8.encode(jsonEncode(identities)),
      ),
    ]).substring(7, 27);
