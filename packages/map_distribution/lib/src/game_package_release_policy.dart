import 'package:pub_semver/pub_semver.dart';

import 'semver_precedence.dart';

enum GamePackageActivationMode { install, update, rollback, repair }

enum GamePackageReleaseDecision { accept, acceptWithWarning, reject }

final class GamePackageReleaseIdentity {
  const GamePackageReleaseIdentity({
    required this.gameId,
    required this.gameVersion,
    required this.treeSha256,
  });

  final String gameId;
  final Version gameVersion;
  final String treeSha256;
}

final class GamePackageReleaseResult {
  const GamePackageReleaseResult.accept()
      : decision = GamePackageReleaseDecision.accept,
        code = null;

  const GamePackageReleaseResult.acceptWithWarning({required this.code})
      : decision = GamePackageReleaseDecision.acceptWithWarning;

  const GamePackageReleaseResult.reject({required this.code})
      : decision = GamePackageReleaseDecision.reject;

  final GamePackageReleaseDecision decision;
  final String? code;

  @override
  bool operator ==(Object other) =>
      other is GamePackageReleaseResult &&
      decision == other.decision &&
      code == other.code;

  @override
  int get hashCode => Object.hash(decision, code);
}

final class GamePackageReleasePolicy {
  const GamePackageReleasePolicy();

  GamePackageReleaseResult evaluate({
    required GamePackageReleaseIdentity installed,
    required GamePackageReleaseIdentity candidate,
    required GamePackageActivationMode mode,
    bool compatibleSaveSnapshotAvailable = false,
  }) {
    if (installed.gameId != candidate.gameId) {
      return const GamePackageReleaseResult.reject(
        code: 'gameIdentityMismatch',
      );
    }
    final precedence = compareSemverPrecedence(
      candidate.gameVersion,
      installed.gameVersion,
    );
    if (precedence == 0 && installed.treeSha256 != candidate.treeSha256) {
      return const GamePackageReleaseResult.reject(code: 'releaseConflict');
    }
    return switch (mode) {
      GamePackageActivationMode.install =>
        const GamePackageReleaseResult.accept(),
      GamePackageActivationMode.update => precedence <= 0
          ? const GamePackageReleaseResult.reject(code: 'notAnUpdate')
          : const GamePackageReleaseResult.accept(),
      GamePackageActivationMode.rollback => precedence >= 0
          ? const GamePackageReleaseResult.reject(code: 'notARollback')
          : compatibleSaveSnapshotAvailable
              ? const GamePackageReleaseResult.acceptWithWarning(
                  code: 'rollbackConfirmationRequired',
                )
              : const GamePackageReleaseResult.reject(
                  code: 'rollbackSaveSnapshotUnavailable',
                ),
      GamePackageActivationMode.repair =>
        candidate.gameVersion == installed.gameVersion &&
                candidate.treeSha256 == installed.treeSha256
            ? const GamePackageReleaseResult.accept()
            : const GamePackageReleaseResult.reject(
                code: 'repairIdentityMismatch',
              ),
    };
  }
}
