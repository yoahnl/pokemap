import 'package:map_distribution/map_distribution.dart';

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';

/// Outcomes the installer reports back: a completed install, and what a
/// crash-recovery pass did on startup.
final class GameInstallationResult {
  const GameInstallationResult({
    required this.game,
    required this.receipt,
    required this.alreadyInstalled,
  });

  final InstalledGame game;
  final GamePackageInstallReceipt receipt;
  final bool alreadyInstalled;
}

enum GameInstallationRecoveryCode {
  abandonedStagingRemoved,
  promotionCompleted,
  transactionQuarantined,
  libraryRebuilt,
}

final class GameInstallationRecovery {
  const GameInstallationRecovery({
    required this.code,
    this.gameId,
    this.gameVersion,
  });

  final GameInstallationRecoveryCode code;
  final String? gameId;
  final String? gameVersion;
}
