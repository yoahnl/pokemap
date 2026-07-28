import 'dart:convert';

import 'package:map_core/map_core.dart';

/// Encodes the exact bytes owned by the revisioned map-document boundary.
///
/// DS-03 persistence and DS-05 lifecycle journals must share this function:
/// two independently formatted representations of the same [MapData] would
/// produce different revisions and make deterministic recovery impossible.
List<int> encodeMapDocumentBytes(MapData map) {
  return utf8.encode(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
}

/// Predicts the durable revision produced by [encodeMapDocumentBytes].
String mapDocumentRevisionFor(MapData map) {
  return narrativeEventBytesFingerprint(encodeMapDocumentBytes(map));
}

/// The disk state that must still be true when a map write commits.
///
/// This is deliberately byte-revision based: rebuilding an equivalent
/// [MapData] object must never manufacture permission to overwrite bytes that
/// were loaded by another process.
sealed class MapDocumentWritePrecondition {
  const MapDocumentWritePrecondition();

  const factory MapDocumentWritePrecondition.absent() = MapDocumentMustBeAbsent;

  factory MapDocumentWritePrecondition.revision(String revision) =
      MapDocumentMustMatchRevision;
}

final class MapDocumentMustBeAbsent extends MapDocumentWritePrecondition {
  const MapDocumentMustBeAbsent();
}

final class MapDocumentMustMatchRevision extends MapDocumentWritePrecondition {
  MapDocumentMustMatchRevision(String revision)
      : revision = requireMapDocumentRevision(revision);

  final String revision;
}

/// A validated map paired with the SHA-256 fingerprint of its exact disk bytes.
final class RevisionedMapDocument {
  RevisionedMapDocument({
    required this.map,
    required String revision,
  }) : revision = requireMapDocumentRevision(revision);

  final MapData map;
  final String revision;
}

enum MapDocumentRecoveryStatus {
  clear,
  discardedIncompleteWrite,
  completedInterruptedWrite,
  cleanedCommittedWrite,
}

/// Product-facing result of inspecting and resolving one interrupted write.
final class MapDocumentRecoveryResult {
  MapDocumentRecoveryResult({
    required this.status,
    required this.targetPath,
    String? revision,
  }) : revision =
            revision == null ? null : requireMapDocumentRevision(revision);

  final MapDocumentRecoveryStatus status;
  final String targetPath;
  final String? revision;
}

String requireMapDocumentRevision(String revision) {
  final normalized = revision.trim();
  if (!_mapDocumentRevisionPattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      revision,
      'revision',
      'must be a lowercase SHA-256 byte fingerprint',
    );
  }
  return normalized;
}

final RegExp _mapDocumentRevisionPattern = RegExp(
  r'^sha256:[0-9a-f]{64}$',
);
