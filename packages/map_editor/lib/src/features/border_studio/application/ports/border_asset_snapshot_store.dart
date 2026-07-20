import '../border_asset_snapshot_service.dart';

enum BorderAssetSnapshotStoreErrorCode {
  invalidProjectRoot,
  invalidStage,
  duplicateRelativePath,
  missingStagedFile,
  stagedHashMismatch,
  corruptedExistingSnapshot,
  ioFailure,
}

final class BorderAssetSnapshotStoreException implements Exception {
  const BorderAssetSnapshotStoreException({
    required this.code,
    required this.userMessage,
    this.relativePath,
    this.cause,
  });

  final BorderAssetSnapshotStoreErrorCode code;
  final String userMessage;
  final String? relativePath;
  final Object? cause;

  @override
  String toString() {
    final path = relativePath == null ? '' : ' ($relativePath)';
    return 'BorderAssetSnapshotStoreException.${code.name}$path: '
        '$userMessage';
  }
}

enum BorderSnapshotStoreOperation {
  stageWrite,
  finalizeMove,
}

final class BorderStagedSnapshotFile {
  const BorderStagedSnapshotFile({
    required this.relativePath,
    required this.contentSha256,
  });

  final String relativePath;
  final String contentSha256;
}

final class BorderAssetSnapshotStage {
  BorderAssetSnapshotStage({
    required this.id,
    required List<BorderStagedSnapshotFile> files,
  }) : files = List<BorderStagedSnapshotFile>.unmodifiable(files);

  final String id;
  final List<BorderStagedSnapshotFile> files;

  String get stagingRelativeDirectory => 'assets/borders/.staging/$id';
}

final class BorderAssetSnapshotFinalizeResult {
  BorderAssetSnapshotFinalizeResult({
    required List<String> createdRelativePaths,
    required List<String> deduplicatedRelativePaths,
  })  : createdRelativePaths = List<String>.unmodifiable(
          createdRelativePaths,
        ),
        deduplicatedRelativePaths = List<String>.unmodifiable(
          deduplicatedRelativePaths,
        );

  final List<String> createdRelativePaths;
  final List<String> deduplicatedRelativePaths;
}

abstract interface class BorderAssetSnapshotStore {
  Future<BorderAssetSnapshotStage> stage(
    List<BorderSnapshotFilePayload> files,
  );

  Future<BorderAssetSnapshotFinalizeResult> finalize(
    BorderAssetSnapshotStage stage,
  );

  Future<void> discard(BorderAssetSnapshotStage stage);
}
