enum GameInstallStage {
  inspecting,
  checkingCompatibility,
  checkingStorage,
  snapshotting,
  extracting,
  verifying,
  validatingProject,
  smokeLoading,
  preparingSaves,
  promoting,
  updatingLibrary,
  completed,
  cancelled,
  recovering,
}

enum GameInstallationErrorCode {
  cancelled,
  incompatible,
  insufficientDisk,
  sourceChanged,
  releaseConflict,
  notAnUpdate,
  alreadyInstalled,
  extractionFailed,
  integrityFailed,
  smokeFailed,
  savePreparationFailed,
  unsafePath,
  storageFailure,
  operationInProgress,
  notInstalled,
  currentPointerCorrupt,
  receiptMissing,
  installationCorrupt,
  repairIdentityMismatch,
  rollbackConfirmationRequired,
  rollbackSnapshotUnavailable,
  uninstallFallbackRequired,
}

final class GameInstallationDiagnostic {
  const GameInstallationDiagnostic({
    required this.code,
    required this.stage,
    this.gameId,
    this.gameVersion,
    required this.retryable,
    required this.repairSuggested,
  });

  final GameInstallationErrorCode code;
  final GameInstallStage stage;
  final String? gameId;
  final String? gameVersion;
  final bool retryable;
  final bool repairSuggested;

  Map<String, Object?> toJson() => <String, Object?>{
        'code': code.name,
        'stage': stage.name,
        if (gameId != null) 'gameId': gameId,
        if (gameVersion != null) 'gameVersion': gameVersion,
        'retryable': retryable,
        'repairSuggested': repairSuggested,
      };
}

final class GameInstallationException implements Exception {
  const GameInstallationException(this.diagnostic);

  final GameInstallationDiagnostic diagnostic;

  @override
  String toString() => 'GameInstallationException(${diagnostic.code.name} at '
      '${diagnostic.stage.name})';
}

final class GameInstallProgress {
  const GameInstallProgress({
    required this.stage,
    required this.completedFiles,
    required this.totalFiles,
    required this.completedBytes,
    required this.totalBytes,
    required this.cancellable,
  });

  final GameInstallStage stage;
  final int completedFiles;
  final int totalFiles;
  final int completedBytes;
  final int totalBytes;
  final bool cancellable;
}

typedef GameInstallProgressListener = void Function(
  GameInstallProgress progress,
);

final class GameInstallCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

enum GameInstallFaultStage {
  afterSnapshotInspected,
  afterExtraction,
  beforeVersionPromotion,
  afterVersionPromoted,
  afterReceiptPromoted,
  afterCurrentUpdated,
  afterLibraryUpdated,
}

typedef GameInstallFaultHook = Future<void> Function(
  GameInstallFaultStage stage,
);
