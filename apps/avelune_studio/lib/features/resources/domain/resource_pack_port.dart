import 'dart:convert';

import 'package:map_authoring/map_authoring_api.dart';

import 'resource_port.dart';

typedef PickResourcePack = Future<String?> Function();
typedef PickResourcePackLicenses = Future<List<String>?> Function();
typedef ResourcePackJobMonitor = Future<Map<String, Object?>> Function(
  Map<String, Object?> start,
);

abstract interface class ResourcePackPort {
  String get sessionId;
  Future<void> authorizeSource(String path);
  Future<String> captureRevision();
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]);
  Future<Map<String, Object?>> query(AuthoringQueryRequest request);
  Future<List<int>> readExportPayloadChunk(
    String payloadRef,
    int offset,
    int length,
  );
  Future<ResourceMutationReceipt> applyImport({
    required String preparedHandle,
    required String expectedRevision,
    required String operationId,
    required ResourcePackJobMonitor monitor,
  });
  Future<ResourceMutationReceipt> rereadApplied();
  Future<void> reconcile(ResourceMutationReceipt receipt);
  Future<void> dispose();
}

final class ResourcePackCommittedFailure implements Exception {
  const ResourcePackCommittedFailure(this.receiptId, this.cause);
  final String receiptId;
  final Object cause;
  @override
  String toString() => 'Import terminé — relire la bibliothèque. $cause';
}

abstract interface class ResourcePackExportSink {
  Future<ResourcePackPublication> reconcilePublication(String token);
  Future<ResourcePackPublication> publish({
    required String suggestedName,
    required int byteLength,
    required String rawSha256,
    required Future<List<int>> Function(int offset, int length) readChunk,
    required bool Function() isCancelled,
    required void Function() enterFinalization,
  });
}

final class ResourcePackPublication {
  const ResourcePackPublication.published(String this.path, {this.warning})
    : published = true,
      pendingToken = null;
  const ResourcePackPublication.cancelled({this.warning})
    : path = null,
      pendingToken = null,
      published = false;
  const ResourcePackPublication.pending(
    String this.pendingToken, {
    this.warning,
  }) : path = null,
       published = false;
  final bool published;
  final String? path, warning, pendingToken;
}

final class ResourcePackLicenseDocument {
  const ResourcePackLicenseDocument({
    required this.handle,
    required this.label,
    required this.rawSha256,
    required this.byteLength,
  });
  final String handle, label, rawSha256;
  final int byteLength;
}

final class ResourcePackLocalDraft {
  const ResourcePackLocalDraft({
    required this.kind,
    required this.id,
    required this.label,
    required this.signature,
    this.saving = false,
  });
  final String kind, id, label, signature;
  final bool saving;
}

final class ResourcePackBorderDraft {
  const ResourcePackBorderDraft({
    required this.request,
    required this.dirty,
    required this.saving,
  });
  final BorderCreationRequest request;
  final bool dirty, saving;
  String get signature => jsonEncode({
    'name': request.name,
    'capElementId': request.capElementId,
    'straightElementId': request.straightElementId,
    'cornerElementId': request.cornerElementId,
    'capModelId': request.capModelId,
    'straightModelId': request.straightModelId,
    'cornerModelId': request.cornerModelId,
    'innerCornerModelId': request.innerCornerModelId,
    'primitiveModelIds': request.primitiveModelIds,
    'primitiveModelSettings': {
      for (final e in request.primitiveModelSettings.entries)
        e.key: [
          e.value.animationIndex,
          e.value.animationLoop,
          e.value.animationSpeed,
          e.value.blocksMovement,
        ],
    },
    'straightOnly': request.straightOnly,
    'followContourDirection': request.followContourDirection,
    'replacesGround': request.replacesGround,
    'masksGroundCells': request.masksGroundCells,
    'groundBaseOffset': request.groundBaseOffset,
    'jumpSide': request.jumpSide?.name,
    'dirty': dirty,
    'saving': saving,
  });
}
