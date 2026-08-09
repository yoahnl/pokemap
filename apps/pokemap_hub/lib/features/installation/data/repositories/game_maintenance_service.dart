import 'dart:async';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/library/data/repositories/game_library_repository_impl.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
import 'package:pokemap_hub/core/ports/game_installation_ports.dart';
import 'package:pokemap_hub/features/installation/domain/repositories/game_installation_repository_interface.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_game_verifier.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_result.dart';

final class GameMaintenanceService {
  GameMaintenanceService({
    required this.supportRoot,
    required this.installer,
    this.restoreSavesForRollback,
    this.libraryStore,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final Directory supportRoot;
  final GameInstallationRepositoryInterface installer;
  final RestoreGameSavesForRollback? restoreSavesForRollback;
  final GameLibraryStore? libraryStore;
  final DateTime Function() now;
  Future<void> _mutationTail = Future<void>.value();

  GameLibraryStore get _library =>
      libraryStore ?? GameLibraryStore(supportRoot: supportRoot);

  GameCurrentPointerStore get _currentPointers =>
      GameCurrentPointerStore(supportRoot: supportRoot);

  Future<GameInstallationResult> repair(
    File packageFile, {
    required GamePackageInstallSource source,
    GameInstallProgressListener? onProgress,
  }) =>
      installer.install(
        packageFile,
        source: source,
        mode: GamePackageActivationMode.repair,
        onProgress: onProgress,
      );

  Future<InstalledGame> rollback({
    required String gameId,
    required Version targetVersion,
    required bool confirmed,
    required bool compatibleSaveSnapshotAvailable,
  }) =>
      _withMutationLock(() async {
        final read = await _library.load();
        final game = read.library.game(gameId);
        if (game == null) {
          throw _failure(
            GameInstallationErrorCode.notInstalled,
            gameId,
            targetVersion.toString(),
          );
        }
        final target = _findVersion(game, targetVersion);
        if (target == null) {
          throw _failure(
            GameInstallationErrorCode.notInstalled,
            gameId,
            targetVersion.toString(),
          );
        }
        if (!confirmed) {
          throw _failure(
            GameInstallationErrorCode.rollbackConfirmationRequired,
            gameId,
            targetVersion.toString(),
          );
        }
        final release = const GamePackageReleasePolicy().evaluate(
          installed: GamePackageReleaseIdentity(
            gameId: gameId,
            gameVersion: game.current.gameVersion,
            treeSha256: game.current.treeSha256,
          ),
          candidate: GamePackageReleaseIdentity(
            gameId: gameId,
            gameVersion: target.gameVersion,
            treeSha256: target.treeSha256,
          ),
          mode: GamePackageActivationMode.rollback,
          compatibleSaveSnapshotAvailable: compatibleSaveSnapshotAvailable,
        );
        if (release.decision == GamePackageReleaseDecision.reject) {
          throw _failure(
            release.code == 'rollbackSaveSnapshotUnavailable'
                ? GameInstallationErrorCode.rollbackSnapshotUnavailable
                : GameInstallationErrorCode.notInstalled,
            gameId,
            targetVersion.toString(),
          );
        }
        final verification = await const InstalledGameVerifier().verify(
          supportRoot: supportRoot,
          gameId: gameId,
          pointer: target.pointer,
          receiptFileName: target.receiptFileName,
        );
        if (!verification.isHealthy) {
          throw _failure(
            GameInstallationErrorCode.installationCorrupt,
            gameId,
            targetVersion.toString(),
            repairSuggested: true,
          );
        }
        final restore = restoreSavesForRollback;
        if (restore != null) {
          try {
            await restore(gameId, target.pointer);
          } on Object {
            throw _failure(
              GameInstallationErrorCode.savePreparationFailed,
              gameId,
              targetVersion.toString(),
              retryable: true,
            );
          }
        }
        await _currentPointers.write(gameId, target.pointer);
        final updatedGame = _withManifestMetadata(
          game,
          verification.manifest!,
          current: target.pointer,
          versions: game.versions,
        );
        await _library.save(
          read.library.replaceGame(updatedGame, updatedAt: now().toUtc()),
        );
        return updatedGame;
      });

  Future<InstalledGame?> uninstallVersion({
    required String gameId,
    required Version gameVersion,
    Version? fallbackVersion,
  }) =>
      _withMutationLock(() async {
        final read = await _library.load();
        final game = read.library.game(gameId);
        final target = game == null ? null : _findVersion(game, gameVersion);
        if (game == null || target == null) {
          throw _failure(
            GameInstallationErrorCode.notInstalled,
            gameId,
            gameVersion.toString(),
          );
        }
        final remaining = game.versions
            .where((version) => version.gameVersion != gameVersion)
            .toList();
        InstalledGameVersion? fallback;
        GamePackageManifest? fallbackManifest;
        if (game.current == target.pointer && remaining.isNotEmpty) {
          if (fallbackVersion == null) {
            throw _failure(
              GameInstallationErrorCode.uninstallFallbackRequired,
              gameId,
              gameVersion.toString(),
            );
          }
          fallback = _findVersionIn(remaining, fallbackVersion);
          if (fallback == null) {
            throw _failure(
              GameInstallationErrorCode.notInstalled,
              gameId,
              fallbackVersion.toString(),
            );
          }
          final verification = await const InstalledGameVerifier().verify(
            supportRoot: supportRoot,
            gameId: gameId,
            pointer: fallback.pointer,
            receiptFileName: fallback.receiptFileName,
          );
          if (!verification.isHealthy) {
            throw _failure(
              GameInstallationErrorCode.installationCorrupt,
              gameId,
              fallbackVersion.toString(),
              repairSuggested: true,
            );
          }
          fallbackManifest = verification.manifest;
        }
        final trash = Directory(
          p.join(
            supportRoot.path,
            'games',
            '.trash',
            'uninstall-${now().microsecondsSinceEpoch}',
          ),
        );
        await trash.create(recursive: true);
        final versionRoot = Directory(
          p.join(
            supportRoot.path,
            'games',
            gameId,
            'versions',
            gameVersion.toString(),
          ),
        );
        final receipt = File(
          p.join(
            supportRoot.path,
            'games',
            gameId,
            'install-receipts',
            target.receiptFileName,
          ),
        );
        final trashedVersion = Directory(p.join(trash.path, 'version'));
        final trashedReceipt = File(p.join(trash.path, 'receipt.json'));
        await versionRoot.rename(trashedVersion.path);
        if (await receipt.exists()) await receipt.rename(trashedReceipt.path);
        try {
          InstalledGame? updatedGame;
          if (remaining.isEmpty) {
            await _currentPointers.delete(gameId);
            await _library.save(
              read.library.removeGame(gameId, updatedAt: now().toUtc()),
            );
          } else {
            final current = game.current == target.pointer
                ? fallback!.pointer
                : game.current;
            if (game.current == target.pointer) {
              await _currentPointers.write(gameId, current);
            }
            updatedGame = fallbackManifest == null
                ? game.copyWith(current: current, versions: remaining)
                : _withManifestMetadata(
                    game,
                    fallbackManifest,
                    current: current,
                    versions: remaining,
                  );
            await _library.save(
              read.library.replaceGame(
                updatedGame,
                updatedAt: now().toUtc(),
              ),
            );
          }
          await trash.delete(recursive: true);
          return updatedGame;
        } on Object {
          if (!await versionRoot.exists() && await trashedVersion.exists()) {
            await trashedVersion.rename(versionRoot.path);
          }
          if (!await receipt.exists() && await trashedReceipt.exists()) {
            await receipt.parent.create(recursive: true);
            await trashedReceipt.rename(receipt.path);
          }
          rethrow;
        }
      });

  Future<void> uninstallGame(String gameId) => _withMutationLock(() async {
        final read = await _library.load();
        if (read.library.game(gameId) == null) {
          throw _failure(
            GameInstallationErrorCode.notInstalled,
            gameId,
            null,
          );
        }
        final gameRoot = Directory(p.join(supportRoot.path, 'games', gameId));
        if (await FileSystemEntity.type(
              gameRoot.path,
              followLinks: false,
            ) !=
            FileSystemEntityType.directory) {
          throw _failure(
            GameInstallationErrorCode.unsafePath,
            gameId,
            null,
          );
        }
        final trashRoot = Directory(
          p.join(
            supportRoot.path,
            'games',
            '.trash',
            'game-${now().microsecondsSinceEpoch}',
          ),
        );
        await trashRoot.parent.create(recursive: true);
        await gameRoot.rename(trashRoot.path);
        try {
          await _library.save(
            read.library.removeGame(gameId, updatedAt: now().toUtc()),
          );
          await trashRoot.delete(recursive: true);
        } on Object {
          if (!await gameRoot.exists() && await trashRoot.exists()) {
            await trashRoot.rename(gameRoot.path);
          }
          rethrow;
        }
      });

  InstalledGameVersion? _findVersion(
    InstalledGame game,
    Version version,
  ) =>
      _findVersionIn(game.versions, version);

  InstalledGameVersion? _findVersionIn(
    List<InstalledGameVersion> versions,
    Version version,
  ) {
    for (final candidate in versions) {
      if (candidate.gameVersion == version) return candidate;
    }
    return null;
  }

  InstalledGame _withManifestMetadata(
    InstalledGame existing,
    GamePackageManifest manifest, {
    required InstalledGamePointer current,
    required List<InstalledGameVersion> versions,
  }) =>
      InstalledGame(
        gameId: existing.gameId,
        title: manifest.title,
        description: manifest.description,
        authorName: manifest.author.name,
        publisherName: manifest.publisher?.name,
        defaultLocale: manifest.locales.defaultLocale,
        supportedLocales: manifest.locales.supported,
        branding: manifest.branding == null
            ? null
            : InstalledGameBranding(
                icon: manifest.branding!.icon,
                cover: manifest.branding!.cover,
                hero: manifest.branding!.hero,
                accentColor: manifest.branding!.accentColor,
                titleMusic: manifest.branding!.titleMusic,
                layoutVariant: manifest.branding!.layoutVariant,
              ),
        current: current,
        versions: versions,
      );

  GameInstallationException _failure(
    GameInstallationErrorCode code,
    String? gameId,
    String? gameVersion, {
    bool retryable = false,
    bool repairSuggested = false,
  }) =>
      GameInstallationException(
        GameInstallationDiagnostic(
          code: code,
          stage: GameInstallStage.updatingLibrary,
          gameId: gameId,
          gameVersion: gameVersion,
          retryable: retryable,
          repairSuggested: repairSuggested,
        ),
      );

  Future<T> _withMutationLock<T>(Future<T> Function() operation) {
    final previous = _mutationTail;
    final release = Completer<void>();
    _mutationTail = release.future;
    return () async {
      await previous;
      RandomAccessFile? handle;
      try {
        final games = Directory(p.join(supportRoot.path, 'games'));
        await games.create(recursive: true);
        handle = await File(p.join(games.path, '.mutation.lock'))
            .open(mode: FileMode.append);
        await handle.lock(FileLock.exclusive);
        return await operation();
      } finally {
        if (handle != null) {
          try {
            await handle.unlock();
          } on Object {
            // Closing releases advisory locks on every supported platform.
          }
          await handle.close();
        }
        release.complete();
      }
    }();
  }
}
