import 'package:map_distribution/map_distribution.dart';

import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';

/// Failure construction for the installer.
///
/// Every code and stage here is asserted by `test/install/`; changing one
/// changes the diagnostic the Hub shows the player. Extracted from
/// [GamePackageInstaller] unchanged so the orchestrator keeps flow only.

GameInstallationException installFailure(
  GameInstallationErrorCode code,
  GameInstallStage stage, {
  String? gameId,
  String? gameVersion,
  bool retryable = false,
  bool repairSuggested = false,
  Object? cause,
  StackTrace? stackTrace,
}) =>
    GameInstallationException(
      GameInstallationDiagnostic(
        code: code,
        stage: stage,
        gameId: gameId,
        gameVersion: gameVersion,
        retryable: retryable,
        repairSuggested: repairSuggested,
      ),
      cause: cause,
      stackTrace: stackTrace,
    );

GameInstallationException formatFailure(
  GamePackageFormatException error,
  GameInstallStage stage, [
  String? gameId,
  String? gameVersion,
  StackTrace? stackTrace,
]) {
  final code = switch (error.code) {
    'releaseConflict' => GameInstallationErrorCode.releaseConflict,
    'hubTooOld' ||
    'runtimeApiUnsupported' ||
    'capabilityUnsupported' ||
    'projectFormatUnsupported' ||
    'saveFormatUnsupported' =>
      GameInstallationErrorCode.incompatible,
    _ => GameInstallationErrorCode.integrityFailed,
  };
  return installFailure(
    code,
    stage,
    gameId: gameId,
    gameVersion: gameVersion,
    retryable: code != GameInstallationErrorCode.integrityFailed,
    cause: error,
    stackTrace: stackTrace,
  );
}

GameInstallationException releaseFailure(
  String? code,
  GameInstallStage stage,
  String gameId,
  String gameVersion,
) =>
    installFailure(
      switch (code) {
        'releaseConflict' => GameInstallationErrorCode.releaseConflict,
        'notAnUpdate' => GameInstallationErrorCode.notAnUpdate,
        'repairIdentityMismatch' =>
          GameInstallationErrorCode.repairIdentityMismatch,
        _ => GameInstallationErrorCode.incompatible,
      },
      stage,
      gameId: gameId,
      gameVersion: gameVersion,
    );

/// Aborts the current stage when the caller cancelled the install.
void throwIfCancelled(
  GameInstallCancellationToken token,
  GameInstallStage stage,
  String gameId,
  String gameVersion,
) {
  if (!token.isCancelled) return;
  throw installFailure(
    GameInstallationErrorCode.cancelled,
    stage,
    gameId: gameId,
    gameVersion: gameVersion,
    retryable: true,
  );
}

/// Publishes one progress frame to the caller's listener, if any.
void emitInstallProgress(
  GameInstallProgressListener? listener, {
  required GameInstallStage stage,
  String? gameId,
  String? gameVersion,
  int completedFiles = 0,
  int totalFiles = 0,
  int completedBytes = 0,
  int totalBytes = 0,
  bool cancellable = true,
}) {
  listener?.call(
    GameInstallProgress(
      stage: stage,
      completedFiles: completedFiles,
      totalFiles: totalFiles,
      completedBytes: completedBytes,
      totalBytes: totalBytes,
      cancellable: cancellable,
    ),
  );
}
