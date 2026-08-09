import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/features/installation/application/use_cases/install_game_package_use_case.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_result.dart';
import 'package:pokemap_hub/features/installation/domain/repositories/game_installation_repository_interface.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:test/test.dart';

void main() {
  test('activates a newer package selected from local storage', () async {
    final repository = _RecordingInstallationRepository();

    await expectLater(
      InstallGamePackageUseCase(repository)(File('selected.avelunegame')),
      throwsStateError,
    );

    expect(repository.mode, GamePackageActivationMode.update);
    expect(repository.source, GamePackageInstallSource.localFile);
  });
}

final class _RecordingInstallationRepository
    implements GameInstallationRepositoryInterface {
  GamePackageActivationMode? mode;
  GamePackageInstallSource? source;

  @override
  Future<GameInstallationResult> install(
    File packageFile, {
    required GamePackageInstallSource source,
    GamePackageActivationMode mode = GamePackageActivationMode.install,
    GameInstallCancellationToken? cancellationToken,
    GameInstallProgressListener? onProgress,
  }) async {
    this.mode = mode;
    this.source = source;
    throw StateError('stop after recording');
  }

  @override
  Future<InstalledGamePointer> readCurrent(String gameId) =>
      throw UnimplementedError();

  @override
  Future<GameLibrary> rebuildLibrary() => throw UnimplementedError();
}
