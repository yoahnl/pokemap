import 'dart:io';

import 'package:map_distribution/map_distribution.dart';

import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_result.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';

/// Installs, inspects and rebuilds the installed-game catalogue.
///
/// `dart:io` here is an accepted exception to domain purity: `File` is the real
/// input of a local package install, and hiding it behind a bytes port would
/// change the behaviour the installer's 27 tests pin down. Allowlisted in the
/// lot 23 dependency guards.
abstract interface class GameInstallationRepositoryInterface {
  Future<GameInstallationResult> install(
    File packageFile, {
    required GamePackageInstallSource source,
    GamePackageActivationMode mode = GamePackageActivationMode.install,
    GameInstallCancellationToken? cancellationToken,
    GameInstallProgressListener? onProgress,
  });

  Future<InstalledGamePointer> readCurrent(String gameId);

  Future<GameLibrary> rebuildLibrary();
}
