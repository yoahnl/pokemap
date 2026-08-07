import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/library/data/repositories/game_library_repository_impl.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
import 'package:pokemap_hub/core/ports/game_installation_ports.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_transaction.dart';
import 'package:pokemap_hub/features/installation/data/repositories/install_failures.dart';
import 'package:pokemap_hub/features/installation/data/repositories/install_staging.dart';
import 'package:pokemap_hub/features/installation/domain/services/install_compatibility_rules.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_game_verifier.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library_read.dart';
import 'package:pokemap_hub/features/installation/domain/repositories/game_installation_repository_interface.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_result.dart';

final class GamePackageInstaller
    implements GameInstallationRepositoryInterface {
  GamePackageInstaller({
    required this.supportRoot,
    required this.inspector,
    required this.availableDiskBytes,
    required this.loadSmoke,
    required this.prepareSavesForUpdate,
    this.loadSmokeTimeout = const Duration(seconds: 30),
    this.libraryStore,
    this.faultHook,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final Directory supportRoot;
  final GamePackageInspector inspector;
  final HubAvailableDiskBytes availableDiskBytes;
  final GamePackageLoadSmoke loadSmoke;
  final PrepareGameSavesForUpdate prepareSavesForUpdate;
  final Duration loadSmokeTimeout;
  final GameLibraryStore? libraryStore;
  final GameInstallFaultHook? faultHook;
  final DateTime Function() now;
  final Random _random = Random.secure();
  Future<void> _mutationTail = Future<void>.value();

  GameLibraryStore get _library =>
      libraryStore ?? GameLibraryStore(supportRoot: supportRoot);

  InstallStaging get _staging =>
      InstallStaging(supportRoot: supportRoot, inspector: inspector, random: _random);

  GameCurrentPointerStore get _currentPointers =>
      GameCurrentPointerStore(supportRoot: supportRoot);

  @override
  Future<GameInstallationResult> install(
    File packageFile, {
    required GamePackageInstallSource source,
    GamePackageActivationMode mode = GamePackageActivationMode.install,
    GameInstallCancellationToken? cancellationToken,
    GameInstallProgressListener? onProgress,
  }) =>
      _withMutationLock(
        () => _installLocked(
          packageFile,
          source: source,
          mode: mode,
          cancellationToken:
              cancellationToken ?? GameInstallCancellationToken(),
          onProgress: onProgress,
        ),
      );

  @override
  Future<InstalledGamePointer> readCurrent(String gameId) =>
      _currentPointers.read(gameId);

  Future<List<GameInstallationRecovery>> recover({
    GameInstallProgressListener? onProgress,
  }) =>
      _withMutationLock(() => _recoverLocked(onProgress: onProgress));

  @override
  Future<GameLibrary> rebuildLibrary() =>
      _withMutationLock(_rebuildLibraryLocked);

  Future<GameInstallationResult> _installLocked(
    File packageFile, {
    required GamePackageInstallSource source,
    required GamePackageActivationMode mode,
    required GameInstallCancellationToken cancellationToken,
    required GameInstallProgressListener? onProgress,
  }) async {
    await _recoverLocked(onProgress: onProgress);
    var stage = GameInstallStage.inspecting;
    Directory? transactionRoot;
    GameInstallationTransaction? transaction;
    var promotionStarted = false;
    GamePackageInspectionResult initialInspection;
    try {
      emitInstallProgress(onProgress, stage: stage);
      initialInspection = await _staging.inspect(packageFile);
    } on GamePackageFormatException catch (error, stackTrace) {
      throw formatFailure(error, stage, null, null, stackTrace);
    } on Object catch (error, stackTrace) {
      throw installFailure(
        GameInstallationErrorCode.integrityFailed,
        stage,
        retryable: true,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    final manifest = initialInspection.manifest;
    final gameId = manifest.gameId;
    final gameVersion = manifest.gameVersion.toString();
    try {
      stage = GameInstallStage.checkingCompatibility;
      emitInstallProgress(
        onProgress,
        stage: stage,
        gameId: gameId,
        gameVersion: gameVersion,
      );
      final compatibility = initialInspection.compatibility;
      if (compatibility == null ||
          compatibility.decision == GamePackageCompatibilityDecision.reject ||
          (source == GamePackageInstallSource.publicCatalog &&
              initialInspection.signatureStatus !=
                  PackageSignatureStatus.verified)) {
        throw installFailure(
          GameInstallationErrorCode.incompatible,
          stage,
          gameId: gameId,
          gameVersion: gameVersion,
        );
      }

      final libraryRead = await _library.load();
      final installedGame = libraryRead.library.game(gameId);
      final candidate = GamePackageReleaseIdentity(
        gameId: gameId,
        gameVersion: manifest.gameVersion,
        treeSha256: manifest.content.treeSha256,
      );
      var activate =
          installedGame == null || mode != GamePackageActivationMode.install;
      if (installedGame != null) {
        final current = installedGame.current;
        InstalledGameVersion? existingCandidate;
        for (final version in installedGame.versions) {
          if (version.gameVersion == candidate.gameVersion) {
            existingCandidate = version;
            break;
          }
        }
        if (existingCandidate != null &&
            existingCandidate.treeSha256 != candidate.treeSha256) {
          throw installFailure(
            GameInstallationErrorCode.releaseConflict,
            stage,
            gameId: gameId,
            gameVersion: gameVersion,
          );
        }
        if (existingCandidate != null &&
            (mode == GamePackageActivationMode.install ||
                existingCandidate.pointer == current)) {
          final verification = await const InstalledGameVerifier().verify(
            supportRoot: supportRoot,
            gameId: gameId,
            pointer: existingCandidate.pointer,
            receiptFileName: existingCandidate.receiptFileName,
          );
          if (verification.isHealthy) {
            emitInstallProgress(
              onProgress,
              stage: GameInstallStage.completed,
              gameId: gameId,
              gameVersion: gameVersion,
              cancellable: false,
            );
            return GameInstallationResult(
              game: installedGame,
              receipt: verification.receipt!,
              alreadyInstalled: true,
            );
          }
        }
        final release = const GamePackageReleasePolicy().evaluate(
          installed: GamePackageReleaseIdentity(
            gameId: installedGame.gameId,
            gameVersion: installedGame.current.gameVersion,
            treeSha256: installedGame.current.treeSha256,
          ),
          candidate: candidate,
          mode: mode,
        );
        if (release.decision == GamePackageReleaseDecision.reject) {
          throw releaseFailure(
            release.code,
            stage,
            gameId,
            gameVersion,
          );
        }
        if (mode == GamePackageActivationMode.install) {
          activate = false;
        }
      }

      stage = GameInstallStage.checkingStorage;
      emitInstallProgress(
        onProgress,
        stage: stage,
        gameId: gameId,
        gameVersion: gameVersion,
      );
      throwIfCancelled(cancellationToken, stage, gameId, gameVersion);
      final requiredBytes = max(
        536870912,
        initialInspection.receipt.archiveBytes * 5 ~/ 2,
      );
      if (await availableDiskBytes(supportRoot) < requiredBytes) {
        throw installFailure(
          GameInstallationErrorCode.insufficientDisk,
          stage,
          gameId: gameId,
          gameVersion: gameVersion,
          retryable: true,
        );
      }

      stage = GameInstallStage.snapshotting;
      emitInstallProgress(
        onProgress,
        stage: stage,
        gameId: gameId,
        gameVersion: gameVersion,
        totalBytes: initialInspection.receipt.archiveBytes,
      );
      transactionRoot = await _staging.createTransactionRoot();
      final snapshot = File(p.join(transactionRoot.path, 'package.snapshot'));
      await _staging.copyPackageSnapshot(
        packageFile,
        snapshot,
        cancellationToken: cancellationToken,
        gameId: gameId,
        gameVersion: gameVersion,
        onProgress: onProgress,
        totalBytes: initialInspection.receipt.archiveBytes,
      );
      final snapshotInspection = await _staging.inspect(snapshot);
      if (!sameInspection(
        initialInspection.receipt,
        snapshotInspection.receipt,
      )) {
        throw installFailure(
          GameInstallationErrorCode.sourceChanged,
          stage,
          gameId: gameId,
          gameVersion: gameVersion,
        );
      }
      final receiptFileName =
          '$gameVersion-${manifest.content.treeSha256}.json';
      transaction = GameInstallationTransaction(
        id: p.basename(transactionRoot.path),
        state: GameInstallationTransactionState.snapshotReady,
        mode: mode,
        activate: activate,
        gameId: gameId,
        gameVersion: gameVersion,
        treeSha256: manifest.content.treeSha256,
        receiptFileName: receiptFileName,
        source: source,
        createdAt: now().toUtc(),
      );
      await _writeJournal(transactionRoot, transaction);
      await _fault(GameInstallFaultStage.afterSnapshotInspected);

      stage = GameInstallStage.extracting;
      final stagedVersion =
          Directory(p.join(transactionRoot.path, 'staged-version'));
      await _staging.extractSnapshot(
        snapshot,
        stagedVersion,
        snapshotInspection,
        cancellationToken: cancellationToken,
        onProgress: onProgress,
      );
      transaction = transaction.withState(
        GameInstallationTransactionState.extracted,
      );
      await _writeJournal(transactionRoot, transaction);
      await _fault(GameInstallFaultStage.afterExtraction);

      stage = GameInstallStage.verifying;
      emitInstallProgress(
        onProgress,
        stage: stage,
        gameId: gameId,
        gameVersion: gameVersion,
        totalFiles: manifest.content.fileCount,
        totalBytes: manifest.content.totalBytes,
      );
      await _verifyStaged(stagedVersion, manifest);

      stage = GameInstallStage.validatingProject;
      emitInstallProgress(
        onProgress,
        stage: stage,
        gameId: gameId,
        gameVersion: gameVersion,
      );
      GamePackageProjectValidator(inspector.policy).validate(
        manifest,
        await File(
          p.join(stagedVersion.path, 'project', 'project.json'),
        ).readAsBytes(),
        payloadPaths: manifest.content.files.map((entry) => entry.path).toSet(),
      );

      stage = GameInstallStage.smokeLoading;
      emitInstallProgress(
        onProgress,
        stage: stage,
        gameId: gameId,
        gameVersion: gameVersion,
      );
      try {
        await loadSmoke(
          stagedVersion,
          manifest,
        ).timeout(loadSmokeTimeout);
      } on Object {
        throw installFailure(
          GameInstallationErrorCode.smokeFailed,
          stage,
          gameId: gameId,
          gameVersion: gameVersion,
          retryable: true,
        );
      }

      if (installedGame != null && mode == GamePackageActivationMode.update) {
        stage = GameInstallStage.preparingSaves;
        emitInstallProgress(
          onProgress,
          stage: stage,
          gameId: gameId,
          gameVersion: gameVersion,
        );
        try {
          await prepareSavesForUpdate(installedGame.current, manifest);
        } on Object {
          throw installFailure(
            GameInstallationErrorCode.savePreparationFailed,
            stage,
            gameId: gameId,
            gameVersion: gameVersion,
            retryable: true,
          );
        }
      }

      final receipt = GamePackageInstallReceipt(
        receiptFormat: 1,
        securityPolicyVersion: snapshotInspection.receipt.securityPolicyVersion,
        gameId: gameId,
        gameVersion: manifest.gameVersion,
        treeSha256: manifest.content.treeSha256,
        manifestSha256: snapshotInspection.receipt.manifestSha256,
        packageSha256: snapshotInspection.receipt.packageSha256,
        validatedAt: now().toUtc(),
        installedAt: now().toUtc(),
        source: source,
        signatureStatus: snapshotInspection.signatureStatus,
        validation: GamePackageInstallValidation(
          compatibility:
              compatibility.decision == GamePackageCompatibilityDecision.migrate
                  ? GamePackageInstallCompatibility.migrate
                  : GamePackageInstallCompatibility.accept,
        ),
      );
      final receiptBytes =
          const GamePackageInstallReceiptCodec().encodeCanonicalUtf8(receipt);
      await _writeFlushed(
        File(p.join(transactionRoot.path, 'receipt.json')),
        receiptBytes,
      );
      transaction = transaction.withState(
        GameInstallationTransactionState.readyToPromote,
      );
      await _writeJournal(transactionRoot, transaction);

      throwIfCancelled(cancellationToken, stage, gameId, gameVersion);
      stage = GameInstallStage.promoting;
      emitInstallProgress(
        onProgress,
        stage: stage,
        gameId: gameId,
        gameVersion: gameVersion,
        cancellable: false,
      );
      await _fault(GameInstallFaultStage.beforeVersionPromotion);
      promotionStarted = true;
      final target = Directory(
        p.join(
          supportRoot.path,
          'games',
          gameId,
          'versions',
          gameVersion,
        ),
      );
      await target.parent.create(recursive: true);
      if (await target.exists()) {
        if (mode != GamePackageActivationMode.repair) {
          throw installFailure(
            GameInstallationErrorCode.releaseConflict,
            stage,
            gameId: gameId,
            gameVersion: gameVersion,
          );
        }
        transaction = transaction.withState(
          GameInstallationTransactionState.repairBackupMoved,
        );
        await _writeJournal(transactionRoot, transaction);
        await target.rename(
          p.join(transactionRoot.path, 'replaced-version'),
        );
      }
      await stagedVersion.rename(target.path);
      transaction = transaction.withState(
        GameInstallationTransactionState.versionPromoted,
      );
      await _writeJournal(transactionRoot, transaction);
      await _fault(GameInstallFaultStage.afterVersionPromoted);

      final receipts = Directory(
        p.join(supportRoot.path, 'games', gameId, 'install-receipts'),
      );
      await receipts.create(recursive: true);
      final finalReceipt = File(p.join(receipts.path, receiptFileName));
      if (await finalReceipt.exists()) {
        if (mode != GamePackageActivationMode.repair) {
          throw installFailure(
            GameInstallationErrorCode.releaseConflict,
            stage,
            gameId: gameId,
            gameVersion: gameVersion,
          );
        }
        await finalReceipt.rename(
          p.join(transactionRoot.path, 'replaced-receipt.json'),
        );
      }
      await File(p.join(transactionRoot.path, 'receipt.json'))
          .rename(finalReceipt.path);
      transaction = transaction.withState(
        GameInstallationTransactionState.receiptPromoted,
      );
      await _writeJournal(transactionRoot, transaction);
      await _fault(GameInstallFaultStage.afterReceiptPromoted);

      final pointer = InstalledGamePointer(
        gameVersion: manifest.gameVersion,
        treeSha256: manifest.content.treeSha256,
      );
      if (activate) {
        await _currentPointers.write(gameId, pointer);
      }
      transaction = transaction.withState(
        GameInstallationTransactionState.currentUpdated,
      );
      await _writeJournal(transactionRoot, transaction);
      await _fault(GameInstallFaultStage.afterCurrentUpdated);

      stage = GameInstallStage.updatingLibrary;
      emitInstallProgress(
        onProgress,
        stage: stage,
        gameId: gameId,
        gameVersion: gameVersion,
        cancellable: false,
      );
      final published = await _publishLibrary(
        manifest: manifest,
        receipt: receipt,
        receiptFileName: receiptFileName,
        activate: activate,
      );
      transaction = transaction.withState(
        GameInstallationTransactionState.libraryUpdated,
      );
      await _writeJournal(transactionRoot, transaction);
      await _fault(GameInstallFaultStage.afterLibraryUpdated);
      await transactionRoot.delete(recursive: true);
      transactionRoot = null;
      emitInstallProgress(
        onProgress,
        stage: GameInstallStage.completed,
        gameId: gameId,
        gameVersion: gameVersion,
        cancellable: false,
      );
      return GameInstallationResult(
        game: published,
        receipt: receipt,
        alreadyInstalled: false,
      );
    } on GameInstallationException catch (error) {
      if (!promotionStarted &&
          transactionRoot != null &&
          await transactionRoot.exists()) {
        await transactionRoot.delete(recursive: true);
      }
      if (error.diagnostic.code == GameInstallationErrorCode.cancelled) {
        emitInstallProgress(
          onProgress,
          stage: GameInstallStage.cancelled,
          gameId: gameId,
          gameVersion: gameVersion,
          cancellable: false,
        );
      }
      rethrow;
    } on GamePackageFormatException catch (error, stackTrace) {
      if (!promotionStarted &&
          transactionRoot != null &&
          await transactionRoot.exists()) {
        await transactionRoot.delete(recursive: true);
      }
      throw formatFailure(
        error,
        stage,
        gameId,
        gameVersion,
        stackTrace,
      );
    } on Object catch (error, stackTrace) {
      if (!promotionStarted &&
          transactionRoot != null &&
          await transactionRoot.exists()) {
        await transactionRoot.delete(recursive: true);
      }
      throw installFailure(
        promotionStarted
            ? GameInstallationErrorCode.storageFailure
            : GameInstallationErrorCode.extractionFailed,
        stage,
        gameId: gameId,
        gameVersion: gameVersion,
        retryable: true,
        repairSuggested: promotionStarted,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<GameInstallationRecovery>> _recoverLocked({
    GameInstallProgressListener? onProgress,
  }) async {
    final result = <GameInstallationRecovery>[];
    final transactions = Directory(
      p.join(supportRoot.path, 'games', '.transactions'),
    );
    if (!await transactions.exists()) {
      return _recoverLibraryIfNeeded(result);
    }
    emitInstallProgress(
      onProgress,
      stage: GameInstallStage.recovering,
      cancellable: false,
    );
    final entries = await transactions.list(followLinks: false).toList()
      ..sort((left, right) => left.path.compareTo(right.path));
    for (final entity in entries) {
      if (entity is! Directory ||
          p.basename(entity.path).contains('.quarantine.')) {
        continue;
      }
      late GameInstallationTransaction transaction;
      try {
        transaction = GameInstallationTransactionCodec.decode(
          await File(p.join(entity.path, 'journal.json')).readAsBytes(),
        );
        if (transaction.id != p.basename(entity.path)) {
          throw const FormatException(
            'Transaction identity does not match its directory.',
          );
        }
      } on Object {
        await _quarantineTransaction(entity);
        result.add(
          const GameInstallationRecovery(
            code: GameInstallationRecoveryCode.transactionQuarantined,
          ),
        );
        continue;
      }
      if (transaction.state ==
          GameInstallationTransactionState.repairBackupMoved) {
        final versionRoot = Directory(
          p.join(
            supportRoot.path,
            'games',
            transaction.gameId,
            'versions',
            transaction.gameVersion,
          ),
        );
        final backup = Directory(p.join(entity.path, 'replaced-version'));
        if (await backup.exists() && !await versionRoot.exists()) {
          await backup.rename(versionRoot.path);
        } else if (await backup.exists() && await versionRoot.exists()) {
          try {
            final manifest = const GamePackageManifestCodec().decodeUtf8(
              await File(
                p.join(versionRoot.path, 'game-manifest.json'),
              ).readAsBytes(),
            );
            if (manifest.gameId == transaction.gameId &&
                manifest.gameVersion.toString() == transaction.gameVersion &&
                manifest.content.treeSha256 == transaction.treeSha256) {
              transaction = transaction.withState(
                GameInstallationTransactionState.versionPromoted,
              );
              await _writeJournal(entity, transaction);
            } else {
              await versionRoot.delete(recursive: true);
              await backup.rename(versionRoot.path);
            }
          } on Object {
            await versionRoot.delete(recursive: true);
            await backup.rename(versionRoot.path);
          }
        }
        if (transaction.state !=
            GameInstallationTransactionState.versionPromoted) {
          await entity.delete(recursive: true);
          result.add(
            GameInstallationRecovery(
              code: GameInstallationRecoveryCode.abandonedStagingRemoved,
              gameId: transaction.gameId,
              gameVersion: transaction.gameVersion,
            ),
          );
          continue;
        }
      }
      if (transaction.state.index <
          GameInstallationTransactionState.versionPromoted.index) {
        await entity.delete(recursive: true);
        result.add(
          GameInstallationRecovery(
            code: GameInstallationRecoveryCode.abandonedStagingRemoved,
            gameId: transaction.gameId,
            gameVersion: transaction.gameVersion,
          ),
        );
        continue;
      }
      try {
        final versionRoot = Directory(
          p.join(
            supportRoot.path,
            'games',
            transaction.gameId,
            'versions',
            transaction.gameVersion,
          ),
        );
        final manifest = const GamePackageManifestCodec().decodeUtf8(
          await File(
            p.join(versionRoot.path, 'game-manifest.json'),
          ).readAsBytes(),
        );
        final receiptDirectory = Directory(
          p.join(
            supportRoot.path,
            'games',
            transaction.gameId,
            'install-receipts',
          ),
        );
        await receiptDirectory.create(recursive: true);
        final finalReceipt = File(
          p.join(receiptDirectory.path, transaction.receiptFileName),
        );
        if (!await finalReceipt.exists()) {
          final pending = File(p.join(entity.path, 'receipt.json'));
          await pending.rename(finalReceipt.path);
        }
        final receipt = const GamePackageInstallReceiptCodec().decodeUtf8(
          await finalReceipt.readAsBytes(),
        );
        final pointer = InstalledGamePointer(
          gameVersion: Version.parse(transaction.gameVersion),
          treeSha256: transaction.treeSha256,
        );
        if (transaction.activate) {
          await _currentPointers.write(transaction.gameId, pointer);
        }
        await _publishLibrary(
          manifest: manifest,
          receipt: receipt,
          receiptFileName: transaction.receiptFileName,
          activate: transaction.activate,
        );
        await entity.delete(recursive: true);
        result.add(
          GameInstallationRecovery(
            code: GameInstallationRecoveryCode.promotionCompleted,
            gameId: transaction.gameId,
            gameVersion: transaction.gameVersion,
          ),
        );
      } on Object {
        await _quarantineTransaction(entity);
        result.add(
          GameInstallationRecovery(
            code: GameInstallationRecoveryCode.transactionQuarantined,
            gameId: transaction.gameId,
            gameVersion: transaction.gameVersion,
          ),
        );
      }
    }
    return _recoverLibraryIfNeeded(result);
  }

  Future<void> _quarantineTransaction(Directory transaction) async {
    if (!await transaction.exists()) return;
    final quarantine = Directory(
      '${transaction.path}.quarantine.'
      '${DateTime.now().microsecondsSinceEpoch}',
    );
    await transaction.rename(quarantine.path);
  }

  Future<List<GameInstallationRecovery>> _recoverLibraryIfNeeded(
    List<GameInstallationRecovery> result,
  ) async {
    final read = await _library.load();
    if (read.source == GameLibrarySource.current && read.diagnostics.isEmpty) {
      return result;
    }
    final gamesRoot = Directory(p.join(supportRoot.path, 'games'));
    if (!await gamesRoot.exists()) return result;
    final hasInstalledGame = !await gamesRoot
        .list(followLinks: false)
        .where(
          (entity) =>
              entity is Directory &&
              !p.basename(entity.path).startsWith('.') &&
              File(p.join(entity.path, 'current.json')).existsSync(),
        )
        .isEmpty;
    if (!hasInstalledGame) return result;
    await _rebuildLibraryLocked();
    result.add(
      const GameInstallationRecovery(
        code: GameInstallationRecoveryCode.libraryRebuilt,
      ),
    );
    return result;
  }

  Future<GameLibrary> _rebuildLibraryLocked() async {
    final previous = await _library.load();
    final gamesRoot = Directory(p.join(supportRoot.path, 'games'));
    final games = <InstalledGame>[];
    if (await gamesRoot.exists()) {
      final gameDirectories = await gamesRoot
          .list(followLinks: false)
          .where(
            (entity) =>
                entity is Directory && !p.basename(entity.path).startsWith('.'),
          )
          .cast<Directory>()
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));
      for (final gameDirectory in gameDirectories) {
        final gameId = p.basename(gameDirectory.path);
        InstalledGamePointer current;
        try {
          current = await _currentPointers.read(gameId);
        } on Object {
          continue;
        }
        final receiptDirectory = Directory(
          p.join(gameDirectory.path, 'install-receipts'),
        );
        if (!await receiptDirectory.exists()) continue;
        final versions = <InstalledGameVersion>[];
        final manifests = <InstalledGamePointer, GamePackageManifest>{};
        final receiptFiles = await receiptDirectory
            .list(followLinks: false)
            .where((entity) => entity is File)
            .cast<File>()
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
        for (final receiptFile in receiptFiles) {
          try {
            final receipt = const GamePackageInstallReceiptCodec().decodeUtf8(
              await receiptFile.readAsBytes(),
            );
            if (receipt.gameId != gameId) continue;
            final pointer = InstalledGamePointer(
              gameVersion: receipt.gameVersion,
              treeSha256: receipt.treeSha256,
            );
            final verification = await const InstalledGameVerifier().verify(
              supportRoot: supportRoot,
              gameId: gameId,
              pointer: pointer,
              receiptFileName: p.basename(receiptFile.path),
            );
            if (!verification.isHealthy ||
                versions.any(
                  (version) => version.gameVersion == receipt.gameVersion,
                )) {
              continue;
            }
            versions.add(
              InstalledGameVersion(
                gameVersion: receipt.gameVersion,
                treeSha256: receipt.treeSha256,
                installedAt: receipt.installedAt,
                receiptFileName: p.basename(receiptFile.path),
                source: receipt.source,
                signatureStatus: receipt.signatureStatus,
              ),
            );
            manifests[pointer] = verification.manifest!;
          } on Object {
            continue;
          }
        }
        final currentManifest = manifests[current];
        if (currentManifest == null) continue;
        games.add(
          InstalledGame(
            gameId: gameId,
            title: currentManifest.title,
            description: currentManifest.description,
            authorName: currentManifest.author.name,
            publisherName: currentManifest.publisher?.name,
            defaultLocale: currentManifest.locales.defaultLocale,
            supportedLocales: currentManifest.locales.supported,
            branding: installedBrandingOf(currentManifest.branding),
            current: current,
            versions: versions,
          ),
        );
      }
    }
    final rebuilt = GameLibrary(
      revision: previous.library.revision + 1,
      updatedAt: now().toUtc(),
      games: games,
    );
    await _library.save(rebuilt);
    return rebuilt;
  }


  Future<void> _verifyStaged(
    Directory root,
    GamePackageManifest manifest,
  ) async {
    final manifestFile = File(p.join(root.path, 'game-manifest.json'));
    final decoded = const GamePackageManifestCodec().decodeUtf8(
      await manifestFile.readAsBytes(),
    );
    if (decoded.gameId != manifest.gameId ||
        decoded.gameVersion != manifest.gameVersion ||
        decoded.content.treeSha256 != manifest.content.treeSha256) {
      throw const FormatException('Staged manifest changed.');
    }
    final expected = <String>{
      'game-manifest.json',
      ...manifest.content.files.map((entry) => entry.path),
    };
    final actual = <String>{};
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type == FileSystemEntityType.directory) continue;
      if (type != FileSystemEntityType.file) {
        throw const FormatException('Staging contains a special entry.');
      }
      actual.add(
        p.posix.joinAll(p.split(p.relative(entity.path, from: root.path))),
      );
    }
    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw const FormatException('Staging inventory differs.');
    }
    for (final entry in manifest.content.files) {
      final file = File(
        p.joinAll(<String>[root.path, ...p.posix.split(entry.path)]),
      );
      if (await file.length() != entry.size ||
          (await sha256.bind(file.openRead()).first).toString() !=
              entry.sha256) {
        throw const FormatException('Staged payload digest differs.');
      }
    }
  }

  Future<InstalledGame> _publishLibrary({
    required GamePackageManifest manifest,
    required GamePackageInstallReceipt receipt,
    required String receiptFileName,
    required bool activate,
  }) async {
    final read = await _library.load();
    final existing = read.library.game(manifest.gameId);
    final installedVersion = InstalledGameVersion(
      gameVersion: manifest.gameVersion,
      treeSha256: manifest.content.treeSha256,
      installedAt: receipt.installedAt,
      receiptFileName: receiptFileName,
      source: receipt.source,
      signatureStatus: receipt.signatureStatus,
    );
    final versions = <InstalledGameVersion>[
      if (existing != null)
        ...existing.versions.where(
          (version) => version.gameVersion != manifest.gameVersion,
        ),
      installedVersion,
    ];
    final pointer = existing == null || activate
        ? installedVersion.pointer
        : existing.current;
    final useCandidateMetadata = existing == null || activate;
    final game = InstalledGame(
      gameId: manifest.gameId,
      title: useCandidateMetadata ? manifest.title : existing.title,
      description:
          useCandidateMetadata ? manifest.description : existing.description,
      authorName:
          useCandidateMetadata ? manifest.author.name : existing.authorName,
      publisherName: useCandidateMetadata
          ? manifest.publisher?.name
          : existing.publisherName,
      defaultLocale: useCandidateMetadata
          ? manifest.locales.defaultLocale
          : existing.defaultLocale,
      supportedLocales: useCandidateMetadata
          ? manifest.locales.supported
          : existing.supportedLocales,
      branding: useCandidateMetadata
          ? installedBrandingOf(manifest.branding)
          : existing.branding,
      current: pointer,
      versions: versions,
    );
    final updated = read.library.replaceGame(game, updatedAt: now().toUtc());
    await _library.save(updated);
    return game;
  }

  Future<void> _writeJournal(
    Directory transactionRoot,
    GameInstallationTransaction transaction,
  ) async {
    final current = File(p.join(transactionRoot.path, 'journal.json'));
    final temporary = File(p.join(transactionRoot.path, 'journal.json.tmp'));
    await _writeFlushed(
      temporary,
      GameInstallationTransactionCodec.encode(transaction),
    );
    GameInstallationTransactionCodec.decode(await temporary.readAsBytes());
    await temporary.rename(current.path);
  }

  Future<void> _writeFlushed(File file, List<int> bytes) async {
    final output = await file.open(mode: FileMode.writeOnly);
    try {
      await output.writeFrom(bytes);
      await output.flush();
    } finally {
      await output.close();
    }
  }

  Future<void> _fault(GameInstallFaultStage stage) async {
    final hook = faultHook;
    if (hook != null) await hook(stage);
  }

  Future<T> _withMutationLock<T>(Future<T> Function() operation) {
    final previous = _mutationTail;
    final release = Completer<void>();
    _mutationTail = release.future;
    return () async {
      await previous;
      RandomAccessFile? handle;
      try {
        await _assertSafeSupportRoot();
        final games = Directory(p.join(supportRoot.path, 'games'));
        await games.create(recursive: true);
        final lock = File(p.join(games.path, '.mutation.lock'));
        handle = await lock.open(mode: FileMode.append);
        await handle.lock(FileLock.exclusive);
        return await operation();
      } finally {
        if (handle != null) {
          try {
            await handle.unlock();
          } on Object {
            // The OS releases the advisory lock when the handle closes.
          }
          await handle.close();
        }
        release.complete();
      }
    }();
  }

  Future<void> _assertSafeSupportRoot() async {
    final type = await FileSystemEntity.type(
      supportRoot.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.link ||
        (type != FileSystemEntityType.notFound &&
            type != FileSystemEntityType.directory)) {
      throw installFailure(
        GameInstallationErrorCode.unsafePath,
        GameInstallStage.inspecting,
      );
    }
    if (type == FileSystemEntityType.notFound) {
      await supportRoot.create(recursive: true);
    }
  }
}
