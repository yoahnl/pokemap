import 'dart:io';

import 'package:map_distribution/map_distribution.dart';

import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_result.dart';
import 'package:pokemap_hub/features/installation/domain/repositories/game_installation_repository_interface.dart';

/// Installs a package the player picked from local storage.
///
/// Pins the install source so callers cannot silently install from an
/// untrusted origin.
final class InstallGamePackageUseCase {
  const InstallGamePackageUseCase(this._repository);

  final GameInstallationRepositoryInterface _repository;

  Future<GameInstallationResult> call(
    File packageFile, {
    GameInstallCancellationToken? cancellationToken,
    GameInstallProgressListener? onProgress,
  }) {
    return _repository.install(
      packageFile,
      source: GamePackageInstallSource.localFile,
      mode: GamePackageActivationMode.update,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
  }
}
