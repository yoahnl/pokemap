import 'dart:async';

import 'package:map_distribution/map_distribution.dart';

final class FileBackedPayloadException implements Exception {
  const FileBackedPayloadException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'FileBackedPayloadException($code): $message';
}

final class FileBackedPayloadScope {
  const FileBackedPayloadScope(
      {required this.sessionId, required this.projectId});
  final String sessionId;
  final String projectId;
  @override
  bool operator ==(Object other) =>
      other is FileBackedPayloadScope &&
      other.sessionId == sessionId &&
      other.projectId == projectId;
  @override
  int get hashCode => Object.hash(sessionId, projectId);
}

enum FileBackedPayloadPurpose { owner, plan, job, history, recovery }

final class StoredFilePayload {
  const StoredFilePayload(
      {required this.handle,
      required this.byteLength,
      required this.rawSha256});
  final String handle;
  final int byteLength;
  final String rawSha256;
}

final class FileBackedPayloadLease {
  const FileBackedPayloadLease(
      {required this.leaseId, required this.payload, required this.purpose});
  final String leaseId;
  final StoredFilePayload payload;
  final FileBackedPayloadPurpose purpose;
}

abstract interface class FileBackedPayloadStore {
  Future<FileBackedPayloadLease> stage({
    required FileBackedPayloadScope scope,
    required Stream<List<int>> chunks,
    required int byteLength,
    String? expectedRawSha256,
    void Function()? checkCancelled,
  });
  Future<FileBackedPayloadLease> retain({
    required FileBackedPayloadScope scope,
    required String handle,
    FileBackedPayloadPurpose purpose = FileBackedPayloadPurpose.owner,
  });
  Future<bool> release(
      {required FileBackedPayloadScope scope, required String leaseId});
  Future<T> withSource<T>({
    required FileBackedPayloadScope scope,
    required String handle,
    required FutureOr<T> Function(RandomAccessPackageSource source) read,
  });
  Future<void> collectExpired();
}
