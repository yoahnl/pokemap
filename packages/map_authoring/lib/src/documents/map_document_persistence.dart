import 'dart:convert';

import 'package:map_core/map_core.dart';

List<int> encodeMapDocumentBytes(MapData map) {
  return utf8.encode(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
}

String mapDocumentRevisionFor(MapData map) {
  return narrativeEventBytesFingerprint(encodeMapDocumentBytes(map));
}

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
