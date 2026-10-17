import 'package:map_authoring/map_authoring_api.dart';

import 'resource_port.dart';

typedef PickResourcePack = Future<String?> Function();
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
